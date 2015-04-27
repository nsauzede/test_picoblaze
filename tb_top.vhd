--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:03:19 03/25/2015
-- Design Name:   
-- Module Name:   C:/nico/perso/hack/hackerspace/fpga/nico/test_picoblaze/tb_top.vhd
-- Project Name:  test_picoblaze
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: aaatop
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_top IS
END tb_top;
 
ARCHITECTURE behavior OF tb_top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT aaatop
    PORT(
         rx : IN  std_logic;
         tx : INOUT  std_logic;
         W1A : INOUT  std_logic_vector(15 downto 0);
         W1B : INOUT  std_logic_vector(15 downto 0);
         W2C : INOUT  std_logic_vector(15 downto 0);
         clk : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rx : std_logic := '0';
   signal clk : std_logic := '0';

	--BiDirs
   signal tx : std_logic;
   signal W1A : std_logic_vector(15 downto 0) := (others => '0');
   signal W1B : std_logic_vector(15 downto 0) := (others => '0');
   signal W2C : std_logic_vector(15 downto 0) := (others => '0');

   -- Clock period definitions
   constant clk_period : time := 31.25 ns;
 
   signal rx2 : std_logic := '0';
   signal clk2 : std_logic := '0';
	signal read_buffer : std_logic;
	signal in_port_uart : std_logic_vector(7 downto 0);
   constant clk2_period : time := 20.832 ns;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: aaatop PORT MAP (
          rx => rx,
          tx => tx,
          W1A => W1A,
          W1B => W1B,
          W2C => W2C,
          clk => clk
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   clk2_process :process
   begin
		clk2 <= '0';
		wait for clk2_period/2;
		clk2 <= '1';
		wait for clk2_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;
	w1b(7) <= '0';	-- buttons
	w1b(5) <= '1';
	w1b(3) <= '0';
	w1b(1) <= '1';
	rx2 <= w1a(0);
	uart_rx0: entity work.uart_rx
    Port map(
		serial_in => tx,
		data_out => in_port_uart,
		read_buffer => read_buffer,
		reset_buffer => '0',
		en_16_x_baud => '1',
		buffer_data_present => read_buffer,
		buffer_full => open,
		buffer_half_full => open,
		clk => clk2
	);

END;
