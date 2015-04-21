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
           rs232_tx    : out  STD_LOGIC);
end log_pins;

architecture Behavioral of log_pins is
   signal current_inputs        : std_logic_vector(probe_len-1 downto 0)     := (others => '0');
   signal last_sent             : std_logic_vector(probe_len-1 downto 0)     := (others => '0');
   signal last_changed             : std_logic_vector(probe_len-1 downto 0)     := (others => '0');
   signal nchanges : unsigned(7 downto 0)              := (others => '0');
   constant clocks_ticks_per_baud : unsigned(div_len-1 downto 0)             := to_unsigned(clk_freq/baud_rate,div_len);
   signal count                 : unsigned(div_len-1 downto 0)             := (others => '0');
	constant ts_len : integer := 32;
--	constant ts_len : integer := 16;
--	constant ts_len : integer := 4;		--simulate 4 bytes=32 bits binary
--	constant ts_len : integer := 0;
   signal message               : std_logic_vector(10*(ts_len+probe_len+2)-1 downto 0):= (others => '1');
	constant nbits_to_send : integer := 12;
--   signal bits_to_send          : unsigned(nbits_to_send-1 downto 0)              := to_unsigned(message'high,nbits_to_send);
   signal bits_to_send          : unsigned(nbits_to_send-1 downto 0)              := (others => '0');
--   signal startup               : std_logic                         := '1';	-- this one works but lower freq
--   signal nstartup               : std_logic                         := '0';	-- this one works but lower freq
--   signal nstartup               : std_logic;											-- this one leads to better freq, but startup doesn't work (no update at reset)
	
	signal timestamp : unsigned(ts_len-1 downto 0) := (others => '0');
	signal timestamp_buf : unsigned(ts_len-1 downto 0) := (others => '0');
begin
  -- The TX output is the LSB of the message buffer
  rs232_tx <= message(0);

	process(clk32)
   begin
      if rising_edge(clk32) then
			timestamp <= timestamp + 1;
		end if;
	end process;
	clk_proc: process(clk32)
   begin
      if rising_edge(clk32) then
			if current_inputs /= last_changed then
				last_changed <= current_inputs;
				nchanges <= nchanges+1;
			end if;
           -- are we sending bits?
           if bits_to_send /= 0 then
                if count = clocks_ticks_per_baud-1 then
                    -- Move on to the next bit
                    message      <= '1' & message(message'high downto 1);
                    bits_to_send <= bits_to_send - 1;
                    count        <= (others => '0');
                else
                    count <= count+1;
                end if;
           else
               -- Are the inputs still the same as last time?
--               if current_inputs /= last_sent or nstartup = '0' then
               if current_inputs /= last_sent or timestamp_buf = 0 then
						nchanges <= (others => '0');
--						timestamp <= (others => '0');
--               if current_inputs /= last_sent or startup = '1' then
                 for i in 0 to timestamp_buf'length-1 loop
                     if timestamp_buf(i) = '1' then
                        message((timestamp_buf'length-1-i)*10+9 downto (timestamp_buf'length-1-i)*10) <= "1001100010"; -- ASCII '1'
                     else
                        message((timestamp_buf'length-1-i)*10+9 downto (timestamp_buf'length-1-i)*10) <= "1001100000"; -- ASCII '0'
                     end if;
                  end loop;
                 for i in 0 to probe_len-1 loop
                     if current_inputs(probe_len-1-i) = '1' then
                        message((ts_len+i)*10+9 downto (ts_len+i)*10) <= "1001100010"; -- ASCII '1'
                     else
                        message((ts_len+i)*10+9 downto (ts_len+i)*10) <= "1001100000"; -- ASCII '0'
                     end if;
                  end loop;
--                  message(message'length-11 downto message'length-20) <= "1000010100"; -- ASCII 10, new Line.
--                  message(message'length-1 downto message'length-10) <= "1000011010"; -- ASCII 13, new Line.
                  bits_to_send <= to_unsigned(message'high,bits_to_send'length);
                  last_sent    <= current_inputs;
                  count        <= (others => '0');
--                  nstartup      <= '1';
--                  startup      <= '0';
               end if;
					timestamp_buf <= timestamp;
           end if;
           -- A single stage of clock synchronization - most likely not enough!
           current_inputs <= test_probes;
        end if;
     end process;
end Behavioral;
