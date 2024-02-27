----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/02/27 13:52:05
-- Design Name: 
-- Module Name: divider - Behavioral
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
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity divider is
Port (      clk_in   : in STD_LOGIC;
           rst   : in STD_LOGIC;
           div_clk : out STD_LOGIC);
end divider;

architecture Behavioral of divider is
signal divcnt: std_logic_vector(23 downto 0);
begin
div:process(clk_in,rst)
 begin
    if rst = '1' then
        divcnt <= (others => '0');
    elsif clk_in'event and clk_in='1' then
        divcnt <= divcnt + '1';
    end if;        
 end process;
    div_clk <= divcnt(20);

end Behavioral;
