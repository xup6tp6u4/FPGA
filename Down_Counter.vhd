----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/08/24 03:26:43
-- Design Name: 
-- Module Name: Down_Counter - Behavioral
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

entity Down_Counter is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           counter : out STD_LOGIC_VECTOR (3 downto 0));
end Down_Counter;

architecture Behavioral of down_Counter is
    signal counter_down: std_logic_vector(3 downto 0);
begin
--down counter
process(clk,reset)
begin
    if(reset='1') then
      counter_down <="1001";
      else
           if clk'event and clk = '1' and counter_down = "0000" then
              counter_down <= "1001";
        else
           if clk'event and clk = '1' then
              counter_down <= counter_down - '1';
        end if;        
      end if;
    end if;
end process;
    counter <= counter_down;
end Behavioral;
