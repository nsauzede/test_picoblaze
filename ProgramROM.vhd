library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity ProgramROM is
	port (clk			: in	std_logic;
         proc_reset : out std_logic;
			address		: in	std_logic_vector(9 downto 0);
			instruction	: out	std_logic_vector(17 downto 0));
end ProgramROM;

architecture Arch of ProgramROM is
begin
proc_reset <= '0';
ram_1024_x_18 : RAMB16_S18
port map(DI		=> "0000000000000000",
			DIP	=> "00",
			EN		=> '1',
			WE		=> '0',
			SSR	=> '0',
			CLK	=> clk,
			ADDR	=> address,
			DO		=> instruction(15 downto 0),
			DOP	=> instruction(17 downto 16)); 

end Arch;
