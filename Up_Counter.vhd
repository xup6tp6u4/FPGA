----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/08/22 02:14:43
-- Design Name: 
-- Module Name: Up_Counter - Behavioral
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
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Up_Counter is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           counter : out STD_LOGIC_VECTOR (3 downto 0));
end Up_Counter;

architecture Behavioral of Up_Counter is
    signal counter_up: std_logic_vector(3 downto 0);
begin
--up counter
process(clk,reset)
begin
    if(reset='1') then
      counter_up <=(others=>'0');
      else
           if clk'event and clk = '1' and counter_up = "1001" then
              counter_up <= "0000";
        else
           if clk'event and clk = '1' then
              counter_up <= counter_up + '1';
        end if;        
      end if;
    end if;
end process;
    counter <= counter_up;
end Behavioral;
