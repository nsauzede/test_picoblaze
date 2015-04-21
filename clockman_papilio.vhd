----------------------------------------------------------------------------------
-- clockman.vhd
--
-- Author: Michael "Mr. Sump" Poppitz
--
-- Details: http://www.sump.org/projects/analyzer/
--
-- This is only a wrapper for Xilinx' DCM component so it doesn't
-- have to go in the main code and can be replaced more easily.
--
-- Creates clk0 with 100MHz.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity clockman is
	generic(
		PERIOD : real := 31.25;			--period of input clock
		PREDIV : real := 2.0;			--as FX output is double-rate, predivide by 2
		DIV : integer := 2;
		MULT : integer := 3
	);
	port(
			clkin : in std_logic;		-- clock input
			clk0 : out std_logic			-- double clock rate output
	);
end clockman;

architecture behavioral of clockman is

	signal clkin1, clkfb, clkfbbuf, realclk0 : std_logic;

begin
	-- DCM: Digital Clock Manager Circuit for Virtex-II/II-Pro and Spartan-3/3E
	-- Xilinx HDL Language Template version 8.1i
	
	  clkin2_inst: BUFG
    port map (
      I =>  clkin,
      O =>  clkin1
    );

	DCM_baseClock : DCM
	generic map(
		CLKDV_DIVIDE => PREDIV, --  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
									--     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
		CLKFX_DIVIDE => DIV,   --  Can be any integer from 1 to 32
		CLKFX_MULTIPLY => MULT, --  Can be any integer from 2 to 32
		CLKIN_DIVIDE_BY_2 => FALSE, --  TRUE/FALSE to enable CLKIN divide by two feature
		CLKIN_PERIOD => PERIOD,          --  Specify period of input clock
		CLKOUT_PHASE_SHIFT => "NONE", --  Specify phase shift of NONE, FIXED or VARIABLE
		CLK_FEEDBACK => "1X",         --  Specify clock feedback of NONE, 1X or 2X
		DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", --  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
															--     an integer from 0 to 15
		DFS_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for frequency synthesis
		DLL_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for DLL
		DUTY_CYCLE_CORRECTION => TRUE, --  Duty cycle correction, TRUE or FALSE
		FACTORY_JF => X"C080",          --  FACTORY JF Values
		PHASE_SHIFT => 0,        --  Amount of fixed phase shift from -255 to 255
		STARTUP_WAIT => TRUE --  Delay configuration DONE until DCM LOCK, TRUE/FALSE
	)
	port map(
		CLKIN => clkin1,   -- Clock input (from IBUFG, BUFG or DCM)
		PSCLK => '0',   -- Dynamic phase adjust clock input
		PSEN => '0',     -- Dynamic phase adjust enable input
		PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
		RST => '0',       -- DCM asynchronous reset input
		CLK2X => open,
		CLKFX => realclk0,
		CLK0 => clkfb,
		CLKFB => clkfbbuf
	);

	-- clkfb is run through a BUFG only to shut up ISE 8.1
	BUFG_clkfb : BUFG
	port map(
		O => clkfbbuf,     -- Clock buffer output
		I => clkfb         -- Clock buffer input
	);

	clk0 <= realclk0;

end behavioral;

