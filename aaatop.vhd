----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:45:19 12/19/2010 
-- Design Name: 
-- Module Name:    aaatop - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity aaatop is
Port (
	rx : in  STD_LOGIC;
	tx : inout  STD_LOGIC;
	W1A : inout  STD_LOGIC_VECTOR (15 downto 0);
	W1B : inout  STD_LOGIC_VECTOR (15 downto 0);
	W2C : inout  STD_LOGIC_VECTOR (15 downto 0);

--	flash_sclk : out STD_LOGIC;
--	flash_cs   : out STD_LOGIC;
--	flash_so   : in  STD_LOGIC;
--	flash_si   : out STD_LOGIC;

	clk : in  STD_LOGIC);
end aaatop;

architecture Behavioral of aaatop is
signal interrupt : std_logic;
--signal cnt_16_x_baud : integer range 0 to 127 := 0;
--signal cnt_16_x_baud : unsigned(1 downto 0) := "00";
signal en_16_x_baud : std_logic := '0';
signal read_buffer : std_logic;
signal write_buffer : std_logic;
signal buffer_full : std_logic;
signal in_port_uart : std_logic_vector(7 downto 0) := (others => '0');

signal address : std_logic_vector(9 downto 0);
signal instruction : std_logic_vector(17 downto 0);
signal port_id : std_logic_vector(7 downto 0);
signal write_strobe : std_logic;
signal out_port : std_logic_vector(7 downto 0);
signal read_strobe : std_logic;
signal in_port : std_logic_vector(7 downto 0) := (others => '0');
signal reset : std_logic;
signal proc_reset : std_logic;
signal hard_reset : std_logic;

signal clk2 : std_logic;

signal buttons : STD_LOGIC_VECTOR (3 downto 0) := x"a";
signal leds : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
signal slave_out : STD_LOGIC_VECTOR (7 downto 0);
signal slave_in : STD_LOGIC_VECTOR (7 downto 0);

	signal spi_clk : std_logic := '1';
	signal spi_csn : std_logic := '1';
	signal spi_mosi : std_logic := '1';
	signal spi_miso : std_logic := '1';
	signal spi : std_logic_vector(3 downto 0) := (others => '1');
	signal spimaster0_cs : std_logic := '0';
   SIGNAL wspi         : std_logic := '0';
signal master_out : std_logic_vector(7 downto 0);

signal test_probes : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
constant freq : integer := 48000000;
constant div_len : integer := 5;		-- 48M/3M=16=0x10 => 5 bits required
constant baud : integer := 3000000;		-- ok 3M
signal tx1 : std_logic;
signal tx2 : std_logic;
begin
	log0: entity work.log_pins
	 generic map(
		baud_rate => baud,
		div_len => div_len,
		clk_freq => freq,
		probe_len => test_probes'length
	)
	Port map( clk32 => clk2,
		test_probes => test_probes,
		rs232_tx => tx2,
		reset => hard_reset);
--	test_probes <= x"0" & spi_clk & spi_csn & spi_mosi & spi_miso;
	spi <= spi_clk & spi_csn & spi_mosi & spi_miso;
	test_probes <= x"0" & spi;

------------------------------
	w1a(15) <= tx2;		-- tx2 is probe uart out
	tx <= tx1;			-- tx1 is picoblaze uart out
------------------------------
--	w1a(15) <= tx1;	-- tx1 is picoblaze uart out
--	tx <= tx2;			-- tx2 is probe uart out

	w1a(3 downto 0) <= spi;
	
--DCM freq => synthesis freq
--32 => 100
--48 => 66;56		-- ok for uart=3Mbps
--50 => 64
--64 => 50
--96 => 33

--	clk2 <= clk;
--	Inst_dcm: entity work.clkgen PORT MAP(
--		CLKIN_IN => clk,
--		CLKFX_OUT => clk2,
----		CLK2X_OUT => clk2,
----		CLKIN_IBUFG_OUT => open,
--		CLK0_OUT => open
--	);
	clock0: entity work.clockman
	generic map(
		DIV => 2,
		MULT => 3
	)
	port map(
			clkin => clk,
			clk0 => clk2
	);
	hard_reset <= buttons(0);
	reset <= proc_reset or hard_reset;
	pico0: entity work.kcpsm3
    Port map(
		address => address,
		instruction => instruction,
		port_id => port_id,
		write_strobe => write_strobe,
		out_port => out_port,
		read_strobe => read_strobe,
		in_port => in_port,
		interrupt => interrupt,
		interrupt_ack => open,
		reset => reset,
		clk => clk2
	);
--	in_port <= in_port_uart when port_id=x"80" else "0000000" & buffer_full;
	inputs : process(clk2)
	begin
		if rising_edge(clk2) then
			case port_id(7 downto 4) is
				when x"f" => in_port <= master_out;
--				when x"f" => in_port <= x"fe";
				when x"8" =>
					case port_id(3 downto 0) is
						when x"0" => in_port <= in_port_uart;
							read_buffer <= read_strobe;
						when x"1" => in_port <= "0000000" & buffer_full;
						when others =>	in_port <= (others => '1');
					end case;
				when others =>	in_port <= (others => '1');
			end case;
		end if;
	end process;

	outputs : process(clk2)
	begin
		if rising_edge(clk2) then
			if port_id(7 downto 3)="11110" then	-- spi selected with port 0xF? (with ?=[0-4])
				spimaster0_cs <= '1';
			else
				spimaster0_cs <= '0';
			end if;
--			if port_id=x"80" then
--				write_buffer <= write_strobe;
--			else
--				write_buffer <= '0';
--			end if;
		end if;
	end process;

--	read_buffer <= read_strobe;
	write_buffer <= write_strobe when port_id=x"80" else '0';
	en_16_x_baud <= '1';
--	process(clk2) begin
--		if rising_edge(clk2) then
--			en_16_x_baud <= not en_16_x_baud;
--		end if;
--	end process;
--	process(clk2) begin
--		if rising_edge(clk2) then
--			if cnt_16_x_baud=0 then
--				en_16_x_baud <= '1';
--			else
--				en_16_x_baud <= '0';
--			end if;
--			cnt_16_x_baud <= cnt_16_x_baud + 1;
--		end if;
--	end process;
--	en_16_x_baud <= cnt_16_x_baud(1);
	uart_rx0: entity work.uart_rx
    Port map(
		serial_in => rx,
		data_out => in_port_uart,
		read_buffer => read_buffer,
		reset_buffer => '0',
--		en_16_x_baud => '1',
		en_16_x_baud => en_16_x_baud,
		buffer_data_present => interrupt,
		buffer_full => open,
		buffer_half_full => open,
--		clk => en_16_x_baud
		clk => clk2
	);
	uart_tx0: entity work.uart_tx
    Port map(
		data_in => out_port,
		write_buffer => write_buffer,
		reset_buffer => '0',
--		en_16_x_baud => '1',
		en_16_x_baud => en_16_x_baud,
		serial_out => tx1,
		buffer_full => buffer_full,
		buffer_half_full => open,
--		clk => en_16_x_baud
		clk => clk2
	);
--	rom0: entity work.ProgramROM
	rom0: entity work.rom				-- use this in simulation
    Port map(
		address => address,
		instruction => instruction,
		proc_reset => proc_reset,
		clk => clk2
	);
	butled0: entity work.wingbutled
	Port map(
		io => w1b(7 downto 0),
		buttons => buttons,
		leds => leds
	);
	wspi <= write_strobe;
--	spimaster0_cs <= '1' when port_id(7 downto 3)="11110" else '0';	-- spi selected with port 0xF? (with ?=[0-4])
	spi_master0 : entity work.spi_master
	port map (
		clk => clk2,
		reset => reset,
		cpu_address => port_id(2 downto 0),
		cpu_wait => open,
		data_in => out_port,
		data_out => master_out,
		enable => spimaster0_cs,
		req_read => '0',
		req_write => wspi,

--spi_slave
		slave_cs => spi_csn,
		slave_clk => spi_clk,
		slave_mosi => spi_mosi,
		slave_miso => spi_miso

--flash
--		slave_cs => flash_cs,
--		slave_clk => flash_sclk,
--		slave_mosi => flash_si,
--		slave_miso => flash_so

--open
--		slave_cs => open,
--		slave_clk => open,
--		slave_mosi => open,
--		slave_miso => 'Z'

	);
	-- uncomment spi_slave0 to loopback spi_master
--	spi_slave0 : entity work.spi_slave
--	Port map( 
--		clk => clk2,
--		SCK => spi_clk,
--		MOSI => spi_mosi,
--		MISO => spi_miso,
--		SSEL => spi_csn,
--		in_port => slave_in,
--		out_port => slave_out
--	);
	leds <= slave_out(3 downto 0);
--	slave_in <= x"5" & buttons;
--	slave_in <= x"55";
	slave_in <= x"62";
--	w1a(0) <= spi_miso when spi_csn='0' else 'Z';
--	spi_mosi <= w1a(1);
--	spi_clk <= w1a(2);
--	spi_csn <= w1a(3);

	--microSDwing
--0 not used in SPI
--1 MISO
--2 SCK
--3 MOSI
--4 CSN
--	w2c(9) <= 'Z';
	spi_miso <= w2c(9);
	w2c(10) <= spi_clk;
	w2c(11) <= spi_mosi;
	w2c(12) <= spi_csn;

	w2c(7) <= '0';
	w2c(6) <= spi_csn;
	w2c(4) <= spi_mosi;
	w2c(2) <= spi_clk;
	w2c(0) <= spi_miso;

end Behavioral;
