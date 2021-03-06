----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:14:59 08/17/2011 
-- Design Name: 
-- Module Name:    spi_vhdl - Behavioral 
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

entity spi_slave is
    Port ( 
	clk : in std_logic;
	SCK : in std_logic;			--MODE3
	MOSI : in std_logic;
	MISO : out std_logic;
	SSEL : in std_logic;
	out_port : out std_logic_vector(7 downto 0);
	in_port : in std_logic_vector(7 downto 0)
	 );
end spi_slave;

architecture Behavioral of spi_slave is
signal SCKr : std_logic_vector(2 downto 0);
signal SCK_risingedge : std_logic;
signal SCK_fallingedge : std_logic;
signal SSELr : std_logic_vector(2 downto 0);
signal SSEL_active : std_logic;
signal SSEL_startmessage : std_logic;
signal SSEL_endmessage : std_logic;
signal MOSIr : std_logic_vector(1 downto 0);
signal MOSI_data : std_logic;
signal bitcnt : unsigned(2 downto 0);
signal byte_received : std_logic;
signal byte_data_received : std_logic_vector(7 downto 0);
signal rin_port : std_logic_vector(7 downto 0);
signal rout_port : std_logic_vector(7 downto 0) := (others => '1');
signal byte_data_sent : std_logic_vector(7 downto 0) := (others => '1');
--signal byte_data_sent_r : std_logic_vector(7 downto 0) := (others => '1');
signal cnt : unsigned(7 downto 0);
begin
	process(clk)
	begin
		if rising_edge(clk) then
			SCKr <= SCKr(1 downto 0) & SCK;
		end if;
	end process;
	SCK_risingedge <= '1' when SCKr(2 downto 1) = "01" else '0';
	SCK_fallingedge <= '1' when SCKr(2 downto 1) = "10" else '0';

	process(clk)
	begin
		if rising_edge(clk) then
			SSELr <= SSELr(1 downto 0) & SSEL;
		end if;
	end process;
	SSEL_active <= not SSELr(1);
	SSEL_startmessage <= '1' when SSELr(2 downto 1) = "10" else '0';
	SSEL_endmessage <= '1' when SSELr(2 downto 1) = "01" else '0';

	process(clk)
	begin
		if rising_edge(clk) then
			MOSIr <= MOSIr(0) & MOSI;
		end if;
	end process;
	MOSI_data <= MOSIr(1);

	process(clk)
	begin
		if rising_edge(clk) then
			if SSEL_active='0' then
				bitcnt <= "000";
			else
				if SCK_risingedge='1' then
					bitcnt <= bitcnt+1;
					byte_data_received <= byte_data_received(6 downto 0) & MOSI_data;
				end if;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if SSEL_active='1' and SCK_risingedge='1' and bitcnt="111" then
				byte_received <= '1';
			else
				byte_received <= '0';
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if byte_received='1' then
				rout_port <= byte_data_received;
			end if;
		end if;
	end process;
	out_port <= rout_port;

	process(clk)
	begin
		if rising_edge(clk) then
			if SSEL_startmessage='1' then
				cnt <= cnt+1;
			end if;
		end if;
	end process;
	process(clk)
	begin
		if rising_edge(clk) then
			if SSEL_active='0' then
--				byte_data_sent_r <= in_port;
				byte_data_sent <= in_port;
			else
--				byte_data_sent <= byte_data_sent_r;
				if SCK_risingedge='1' then
					byte_data_sent <= byte_data_sent(6 downto 0) & '0';
				end if;
			end if;
		end if;
	end process;
--	MISO <= byte_data_sent(7);
	MISO <= byte_data_sent(7) when SSEL_active='1' else 'Z';		--KO : 'Z' triggers noise log_pins detection
end Behavioral;
