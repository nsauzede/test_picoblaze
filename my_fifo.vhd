----------------------------------------------------------------------------------
-- Engineer:  Mike Field <hamster@snap.net.nz> 
-- 
-- Create Date:    21:33:42 09/25/2014 
--
-- Module Name:    my_fifo - Behavioral 
-- Description: A 32 x 9 FIFO using inferred storage -this time shift register based
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
use IEEE.NUMERIC_STD.ALL;

entity my_fifo is
	generic(
		ptr_len : integer := 5;
		fifo_len : integer := 9;
		fifo_depth : integer := 32
	);
    Port ( clk   : in  STD_LOGIC;
           wr    : in  STD_LOGIC;
           din   : in  STD_LOGIC_VECTOR(fifo_len-1 downto 0);
           empty : out STD_LOGIC;
           full  : out STD_LOGIC;
           rd    : in  STD_LOGIC;
           dout  : out STD_LOGIC_VECTOR(fifo_len-1 downto 0));
end my_fifo;

architecture Behavioral of my_fifo is
   signal i_full  : std_logic := '0';
   signal i_empty : std_logic := '1';
   
   type mem_array is array(fifo_depth-1 downto 0) of std_logic_vector(fifo_len-1 downto 0);
   signal memory : mem_array;
   
   signal rd_ptr : unsigned(ptr_len-1 downto 0) := (others => '0');
   
begin
    full  <= i_full;
    empty <= i_empty;

clk_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rd = '1' and i_empty = '0' then
               dout <= memory(to_integer(rd_ptr));
            end if;
            
            if wr = '1' and i_full = '0' then
                memory(fifo_depth-1 downto 1) <= memory(fifo_depth-2 downto 0);
                memory(0) <= din;
            end if;
            
            if rd = '1' and i_empty = '0' then
                -- The read is actionable
                if wr = '0' or i_full = '1' then
                    -- no write this cycle, so decrement the  
                    -- pointer or mark the fifo as empty
                    if rd_ptr = 0 then
                        i_empty <= '1'; -- fifo is now empty
                    else
                        rd_ptr <= rd_ptr - 1;
                    end if;
                    i_full <= '0';  -- can no longer be full
                end if;
            elsif wr = '1' and i_full = '0' then
                -- the just write is actionable
                if rd_ptr = 30 then
                    i_full <= '1';
                else
                    i_full <= '0';
                end if;
                
                if i_empty = '0' then
                    rd_ptr <= rd_ptr + 1;
                end if;
                i_empty <= '0';
            end if;
        end if;
    end process;
end Behavioral;
