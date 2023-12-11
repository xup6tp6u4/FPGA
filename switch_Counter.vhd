----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/08/30 22:01:33
-- Design Name: 
-- Module Name: switch_Counter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity switch_Counter is
Port (     clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           switch : in STD_LOGIC;
           count : out STD_LOGIC_VECTOR(3 downto 0));
end switch_Counter;

architecture Behavioral of switch_Counter is
    signal counter_value : STD_LOGIC_VECTOR(3 downto 0);
begin
    process(clk, reset,switch)
    begin
        if reset = '1' then
            counter_value <= (others => '0');
            
        elsif clk'event and clk = '1' then
			if switch = '1'then --up
			    counter_value <= (others => '0');
				if counter_value < 9 then
					counter_value <= counter_value + '1';
				else
					counter_value <= (others => '0');
				end if;  
			else --down
			        counter_value <= "1001";
			    	if counter_value > 0 then
					counter_value <= counter_value - '1';
				else
					counter_value <= "1001";	
				end if;			
			end if;  
		end if;  
    end process;

    count <= counter_value;

end Behavioral;
