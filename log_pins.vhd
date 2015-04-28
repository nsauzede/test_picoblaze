---------------------------------------------
-- Log_pins.vhd - Logging the start of 11 pins
--                to a PC over RS232
--
-- Author: Mike Field <hamster@snap.net.nz>
-- Nicolas Sauzede <nsauzede@laposte.net> : added generic
-----------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity log_pins is
	generic(
		probe_len : integer := 11;
		div_len : integer := 12;			-- 32M/9600~=3333.33=0xd05 => 12 bits required
		baud_rate : integer := 9600;
		clk_freq : integer := 32000000
	);
    Port ( clk32       : in  STD_LOGIC;
           test_probes : in  STD_LOGIC_VECTOR (probe_len-1 downto 0);
           rs232_tx    : out  STD_LOGIC;
			  reset : in std_logic);
end log_pins;

architecture Behavioral of log_pins is
	constant ts_len : integer := 32;

	constant ptr_len : integer := 5;
--	constant fifo_len : integer := 9;
--	constant fifo_len : integer := 10*(ts_len+probe_len)/8;
	constant fifo_len : integer := ts_len+probe_len;
	constant fifo_depth : integer := 32;
--	constant fifo_depth : integer := 16;
	signal wr    : STD_LOGIC := '0';
	signal wr_r    : STD_LOGIC := '0';
	signal din   : STD_LOGIC_VECTOR(fifo_len-1 downto 0);
	signal empty : STD_LOGIC;
	signal full  : STD_LOGIC;
	signal rd    : STD_LOGIC := '0';
	signal rd_r    : STD_LOGIC := '0';
	signal dout  : STD_LOGIC_VECTOR(fifo_len-1 downto 0);

   signal current_inputs        : std_logic_vector(probe_len-1 downto 0)     := (others => '1');
--   signal last_sent             : std_logic_vector(probe_len-1 downto 0)     := (others => '1');
   signal last_changed             : std_logic_vector(probe_len-1 downto 0)     := (others => '1');
   signal nchanges : unsigned(7 downto 0)              := (others => '0');
   signal nchanges_max : unsigned(7 downto 0)              := (others => '0');
   constant clocks_ticks_per_baud : unsigned(div_len-1 downto 0)             := to_unsigned(clk_freq/baud_rate,div_len);
   signal count                 : unsigned(div_len-1 downto 0)             := (others => '0');
	type message_array_t is array(7 downto 0) of std_logic_vector(10*(ts_len+probe_len)/8-1 downto 0);
--   signal fifo : message_array_t;
   signal message               : std_logic_vector(10*(ts_len+probe_len)/8-1 downto 0):= (others => '1');
	constant nbits_to_send : integer := 12;
   signal bits_to_send          : unsigned(nbits_to_send-1 downto 0)              := (others => '0');
	signal timestamp : unsigned(ts_len-1 downto 0) := (others => '0');
	signal timestamp_buf : unsigned(ts_len-1 downto 0) := (others => '1');
--	signal startup : std_logic := '1';
begin
	rs232_tx <= message(0);
--	rs232_tx <= '1' when startup='1' else message(0);
	process(clk32)
   begin
      if rising_edge(clk32) then
			if reset='1' then
				timestamp <= (others => '0');
			else
			
--			startup <= '0';
			timestamp <= timestamp + 1;
			end if;
		end if;
	end process;
	clk_proc: process(clk32)
	begin
      if rising_edge(clk32) then
			if reset='1' then
				current_inputs <= (others => '1');
				last_changed <= (others => '1');
				nchanges <= (others => '0');
				nchanges_max <= (others => '0');
				bits_to_send <= (others => '0');
				count <= (others => '0');
				wr <= '0';
				wr_r <= '0';
			else

		if nchanges > nchanges_max then
			nchanges_max <= nchanges;
		end if;
			wr <= '0';
			if wr_r='1' then
				if full='0' then
					wr <= '1';
					wr_r <= '0';
				end if;
			end if;
			if current_inputs /= last_changed then
				timestamp_buf <= timestamp;
				last_changed <= current_inputs;
				nchanges <= nchanges+1;
				for i in 0 to timestamp'length/8-1 loop
--					din((timestamp'length/8-1-i)*10+9 downto (timestamp'length/8-1-i)*10) <= "1" & std_logic_vector(timestamp((i+1)*8-1 downto i*8)) & "0";
--					din((timestamp'length/8-1-i)*8+7 downto (timestamp'length/8-1-i)*8) <= std_logic_vector(timestamp((i+1)*8-1 downto i*8));
					din((probe_len/8+i)*8+7 downto (probe_len/8+i)*8) <= std_logic_vector(timestamp((i+1)*8-1 downto i*8));
				end loop;
				for i in 0 to probe_len/8-1 loop
--					din((ts_len/8+i)*10+9 downto (ts_len/8+i)*10) <= "1" & current_inputs((i+1)*8-1 downto i*8) & "0";
--					din((ts_len/8+i)*8+7 downto (ts_len/8+i)*8) <= current_inputs((i+1)*8-1 downto i*8);
--					din((probe_len/8-1-i)*8+7 downto (probe_len/8-1-i)*8) <= current_inputs((i+1)*8-1 downto i*8);
					din(i*8+7 downto i*8) <= current_inputs((i+1)*8-1 downto i*8);
				end loop;
				wr_r <= '1';
			end if;
			rd <= '0';
			rd_r <= '0';
			if bits_to_send /= 0 then
				if count = clocks_ticks_per_baud-1 then
					message      <= '1' & message(message'high downto 1);
					bits_to_send <= bits_to_send - 1;
					count        <= (others => '0');
				else
					count <= count+1;
				end if;
			else
				if empty='0' then
					if rd='0' and rd_r='0' then
						rd <= '1';
					else
						rd_r <= '1';
					end if;
				end if;
				if rd_r='1' then
					nchanges <= (others => '0');
					bits_to_send <= to_unsigned(message'length,bits_to_send'length);
					for i in 0 to dout'length/8-1 loop
						message((dout'length/8-1-i)*10+9 downto (dout'length/8-1-i)*10) <= "1" & std_logic_vector(dout((i+1)*8-1 downto i*8)) & "0";
--						message(i*10+9 downto i*10) <= "1" & std_logic_vector(dout((i+1)*8-1 downto i*8)) & "0";
					end loop;
--					last_sent    <= current_inputs;
					count        <= (others => '0');
				end if;

--				timestamp_buf <= timestamp;
--				if current_inputs /= last_sent then
--					nchanges <= (others => '0');
--					for i in 0 to timestamp'length/8-1 loop
--						message((timestamp'length/8-1-i)*10+9 downto (timestamp'length/8-1-i)*10) <= "1" & std_logic_vector(timestamp((i+1)*8-1 downto i*8)) & "0";
--					end loop;
--					for i in 0 to probe_len/8-1 loop
--						message((ts_len/8+i)*10+9 downto (ts_len/8+i)*10) <= "1" & current_inputs((i+1)*8-1 downto i*8) & "0";
--					end loop;
--					bits_to_send <= to_unsigned(message'length,bits_to_send'length);
--					last_sent    <= current_inputs;
--					count        <= (others => '0');
--				end if;
			end if;
			current_inputs <= test_probes;
			end if;
		end if;
	end process;
	
	fifo0: entity work.my_fifo
		generic map(
			ptr_len => ptr_len,
			fifo_len => fifo_len,
			fifo_depth => fifo_depth
		)
		Port map( clk => clk32,
			wr => wr,
			din => din,
			empty => empty,
			full => full,
			rd => rd,
			dout => dout,
			reset => reset
		);
end Behavioral;
