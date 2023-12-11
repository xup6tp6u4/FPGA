--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:08:38 11/08/2023
-- Design Name:   
-- Module Name:   C:/Xilinx/user/ppISE/pp_tb.vhd
-- Project Name:  ppISE
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pp
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
 
ENTITY pp_tb IS
END pp_tb;
 
ARCHITECTURE behavior OF pp_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT pp
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         swL : IN  std_logic;
         swR : IN  std_logic;
         LED : OUT  std_logic_vector(7 downto 0);
         L7seg : OUT  std_logic_vector(6 downto 0);
         R7seg : OUT  std_logic_vector(6 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal swL : std_logic := '0';
   signal swR : std_logic := '0';

 	--Outputs
   signal LED : std_logic_vector(7 downto 0);
   signal L7seg : std_logic_vector(6 downto 0);
   signal R7seg : std_logic_vector(6 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pp PORT MAP (
          clk => clk,
          rst => rst,
          swL => swL,
          swR => swR,
          LED => LED,
          L7seg => L7seg,
          R7seg => R7seg
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      rst <='0';
      wait for 100 ns;	
      rst <= '1';
      wait for clk_period*16;
      swR <= '1';
      wait for 100ns;
      swR <= '0';

      wait for clk_period*12;
      swL <= '1';
      wait for 100ns;
      swL <= '0'; --580ns
      
      wait for 215ns;
      swR <= '1'; --@795ns
      wait for 115ns;
      swR <= '0';

      -- insert stimulus here 

      wait;
   end process;

END;
