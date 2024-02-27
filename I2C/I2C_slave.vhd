library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity i2c_slave is
    port (
        sda : inout std_logic;
        clk : in std_logic;
        scl : inout std_logic;
        rst : in std_logic;
        data_out : out std_logic_vector(7 downto 0);
        data_in : in std_logic_vector(7 downto 0)
    );
end i2c_slave;

architecture behavioral of i2c_slave is
type FSM is (IDLE , ADDR , READWRITE , TRANSMISSION , RECEIVE , RESPONSE ,STOP);
type DATA_STABLE is (STEADY , TRANSIENT);
type DINOUT_FSM is(DIN , DOUT);
signal STATE_I2C : FSM;
signal STATE_TRANSMISSION , STATE_RESPONSE : DATA_STABLE;
signal INOUT_FSM : DINOUT_FSM;
signal bit_cnt ,tb: integer range 0 to 8;
signal rw  , start , div_clk: std_logic;
signal reg_addr , addr_final , receive_data : std_logic_vector(7 downto 0);
signal test_int : std_logic_vector(7 downto 0);
signal slave_addr   : std_logic_vector(7 downto 0) ;
signal sda_out , sda_in , out_en: std_logic;
component divider is
    generic(
            divisor1       :integer:=1500_00
    );
    port(
            rst,clk_in        : in std_logic;
            div_clk : out std_logic
    );
end component;
begin
div : divider 
    port map(
        rst => rst,
        clk_in => clk,
        div_clk => div_clk
    );
--@@@@@@@@@@@@@@@@@@@@@________FSM_____@@@@@@@@@@@@@@@@@@@@@@@@@@
I2C_FSM_PROCESS : process (rst , scl , bit_cnt , STATE_I2C , sda , start , rw  , reg_addr , test_int)
begin
    if rst = '1' then
        STATE_I2C <= IDLE;
    elsif rising_edge(div_clk)then
        if scl = '1' then
            case STATE_I2C is
                when IDLE => 
                    if start = '1' then
                        STATE_I2C <= ADDR;
                    elsif start = '0' then
                        STATE_I2C <= IDLE;
                    end if;
                when ADDR =>     
                    if bit_cnt = 0 then
                        STATE_I2C <= READWRITE;
                    else
                        STATE_I2C <= ADDR;
                    end if;
                when READWRITE => STATE_I2C <= RESPONSE;
                when TRANSMISSION =>
                    if bit_cnt = 0 then 
                        case STATE_TRANSMISSION is
                            when STEADY => STATE_I2C <= RESPONSE;
                            when TRANSIENT => STATE_I2C <= TRANSMISSION;
                        end case;
                    end if;                
                when RECEIVE =>         
                        if bit_cnt = 0 then
                            STATE_I2C <= RESPONSE;                    
                        else
                            STATE_I2C <= RECEIVE;
                        end if;
                when RESPONSE =>
                    if to_integer(unsigned(addr_final)) = to_integer(unsigned(slave_addr)) then
                        if rw = '0' then        --rw = '1' master trans. => slave receive
                            if sda_in = '1' then
                                STATE_I2C <= STOP;
                            else
                                STATE_I2C <= TRANSMISSION;
                            end if;
                        else
                            STATE_I2C <= RECEIVE;
                        end if;
                    else
                        STATE_I2C <= STOP;
                    end if;
                when STOP => STATE_I2C <= IDLE;
                when others => NULL;
            end case;
        end if;
    end if;
end process;
DATA_FSM : process(rst , clk , STATE_I2C , STATE_TRANSMISSION )
begin
    if rst = '1'then
        STATE_TRANSMISSION <= TRANSIENT;
        STATE_RESPONSE     <= TRANSIENT;
    elsif rising_edge(div_clk)then
        case STATE_I2C is                    
            when TRANSMISSION =>
                case STATE_TRANSMISSION is
                    when STEADY    => STATE_TRANSMISSION <= TRANSIENT;
                    when TRANSIENT => STATE_TRANSMISSION <= STEADY;
                end case;
             when RESPONSE =>
                case STATE_RESPONSE is
                    when STEADY    => STATE_RESPONSE <= TRANSIENT;
                    when TRANSIENT => STATE_RESPONSE <= STEADY; 
                end case;                     
             when others => NULL;
         end case;
    end if;
end process;
INOUT_FSM_process : process(clk , rst , INOUT_FSM)
begin
    if rst = '1' then
        INOUT_FSM <= DIN;
    elsif rising_edge(div_clk)then
        case INOUT_FSM is
            when DIN =>
                if out_en = '1' then
                    INOUT_FSM <= DOUT;
                else
                    INOUT_FSM <= DIN;
                end if;
            when DOUT =>
                if out_en = '1' then
                    INOUT_FSM <= DOUT;
                else
                    INOUT_FSM <= DIN;
                end if;            
        end case;
    end if;
end process;
--@@@@@@@@@@@@@@@@@@@@@________FSM_____@@@@@@@@@@@@@@@@@@@@@@@@@@

--@@@@@@@@@@@@@@@@@@@@@________ACT_____@@@@@@@@@@@@@@@@@@@@@@@@@@

in_out_process : process(clk , rst)
begin
    if rst = '1' then
        sda <= '1';
    else
        case INOUT_FSM is
            when DIN  => sda <= 'Z';
            when DOUT => sda <= sda_out;
        end case;
    end if;
end process;

Din_process : process(clk , rst)
begin
    if rst = '1' then
        sda_in <= '1';       
    else
        case INOUT_FSM is
            when DIN  => sda_in <= sda;
            when DOUT => sda_in <= 'Z';
        end case;
    end if;
end process;

out_en_process : process(rst , clk)
begin
    if rst = '1' then
        out_en <= '0';
    else
        case STATE_I2C is
            when TRANSMISSION => out_en <= '1';
            when RESPONSE =>
                if to_integer(unsigned(addr_final)) /= to_integer(unsigned(slave_addr)) then
                    out_en <= '1';
                else
                    if rw = '0' then
                        out_en <= '0';
                    else
                        out_en <= '1';
                    end if;
                end if;
            when others => out_en <= '0';        
        end case;
    end if;
end process;

START_sig_process : process (rst , clk , sda , scl)
begin
    if rst = '1' then
        start <= '0';
    else
        case STATE_I2C is
            when IDLE =>
                if scl = '1' and sda = '0' then
                    start <= '1';
                end if;
            when others => start <= '0';
        end case;
    end if;
end process;

SDA_out_ACT :process (rst , scl , STATE_I2C , bit_cnt , sda ,rw ,reg_addr )
begin
    if rst = '1'then
        sda_out <= '1';
    else
        case STATE_I2C is
                when TRANSMISSION => 
                    case STATE_TRANSMISSION is
                        when TRANSIENT => sda_out <= data_in(bit_cnt);
                        when STEADY => sda_out <= sda_out;
                    end case; 
                when RESPONSE =>   
                    if to_integer(unsigned(addr_final)) = to_integer(unsigned(slave_addr)) then
                        if rw = '1' then    --rw = 1 =>slave read
                            sda_out <= '0';
                        else
                            sda_out <= 'Z';
                        end if;
                    else
                        sda_out <= '1';
                    end if;
                when others => sda_out <= 'Z';
        end case;
    end if;
end process;
SDA_in_process : process(rst,clk)
begin
    if rst = '1' then
        receive_data <= (others => '0');
    elsif rising_edge(div_clk)then
        case STATE_I2C is
            when RECEIVE => receive_data(bit_cnt) <= sda_in;
            when others => receive_data <= (others => '0');
        end case;
    end if;
end process;
addr_process : process(rst , clk)
begin
    if rst = '1' then
        slave_addr <= (others => '0');
        reg_addr <= (others =>'0');
        addr_final <= (others => '0');
    elsif rising_edge(div_clk)then
        case STATE_I2C is
            when IDLE => slave_addr <= data_in; 
            when ADDR => reg_addr(bit_cnt) <= sda_in;                        
                if bit_cnt = 0 then
                    addr_final <= reg_addr;
                end if;
            when others => reg_addr <= (others => '0');
        end case;
    end if;
end process;

rw_process : process(rst , scl,STATE_I2C,sda)
begin
    if rst = '1' then
        rw <= '0';
    elsif rising_edge(div_clk)then
        if STATE_I2C = READWRITE then
            if sda = '1' then
                rw <= '1';
            else
                rw <= '0';
            end if;
        end if;
    end if;
end process;
SCL_ACT : process(rst , clk)
begin
    if rst = '1'then
        scl <= '1';
    else
        case STATE_I2C is
            when TRANSMISSION =>
                case STATE_TRANSMISSION is
                    when STEADY    => scl <= '1';
                    when TRANSIENT => scl <= '0';
                end case;
            when RESPONSE =>                   
                if rw = '0' then
                    case STATE_RESPONSE is
                        when STEADY    => scl <= '1';
                        when TRANSIENT => scl <= '0';
                    end case;
                else
                    scl <= 'Z';
                end if;
            when others => scl <= 'Z';
        end case;
    end if;
end process;
--@@@@@@@@@@@@@@@@@@@@@________ACT_____@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@________COUNTER_____@@@@@@@@@@@@@@@@@@@@@@@
COUNTER : process(rst , scl , STATE_I2C , bit_cnt)
begin
    if rst = '1' then
        bit_cnt <= 8;
    elsif (STATE_I2C = ADDR or STATE_I2C = TRANSMISSION or STATE_I2C = RECEIVE )then
        if falling_edge(scl) then
            if bit_cnt > 0 then
                bit_cnt <= bit_cnt - 1;
            else
                bit_cnt <= 8;
            end if;
        end if;
    elsif (STATE_I2C /= ADDR and STATE_I2C /= TRANSMISSION and STATE_I2C /= RECEIVE )then
        bit_cnt <= 8;            
    end if; 
end process;
--@@@@@@@@@@@@@@@@@@@@@________COUNTER_____@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@________LED__________@@@@@@@@@@@@@@@@@@@@@@@
test_act : process(rst , clk)
begin
    if rst = '1' then
        data_out <= (others => '0');
    else
        case STATE_I2C is
            when IDLE => data_out <= "00000001";         
            when ADDR => data_out<= reg_addr;              
            when TRANSMISSION =>
                case bit_cnt is
                    when 0 => data_out <= "00000001";
                    when 1 => data_out <= "00000010";
                    when 2 => data_out <= "00000100";
                    when 3 => data_out <= "00001000";
                    when 4 => data_out <= "00010000";
                    when 5 => data_out <= "00100000";
                    when 6 => data_out <= "01000000";
                    when 7 => data_out <= "10000000";
                    when others => data_out <= (others => '0');
                end case;
            when RECEIVE => data_out <= receive_data;
            when others => data_out <= (others => '0');       
        end case;
    end if;
end process;
--@@@@@@@@@@@@@@@@@@@@@________LED__________@@@@@@@@@@@@@@@@@@@@@@@
end architecture;