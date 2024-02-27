library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity I2C_master is Port ( 
    clk     : in std_logic;
    rst     : in std_logic;
    en   : in std_logic;
    rw   : in std_logic;    
    addr_in : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(7 downto 0);  --要傳給slave的數據 
    data_out : out std_logic_vector(7 downto 0);--slave傳回來的數據     
    sda     : inout std_logic;
    scl     : inout std_logic);
end I2C_master;

architecture Behavioral of I2C_master is

type FSM is (IDLE , START,  ADDR , READWRITE , TRANSMISSION , RECEIVE , RESPONSE , STOP);
type DATA_STABLE is (STEADY , TRANSIENT);
type DINOUT_FSM is(DIN , DOUT);

signal STATE_I2C : FSM;
signal STATE_START , STATE_ADDR , STATE_READWRITE , STATE_TRANSMISSION ,STATE_RECEIVE ,STATE_RESPONSE,STATE_STOP: DATA_STABLE;
signal INOUT_FSM : DINOUT_FSM;
signal bit_cnt : integer range 0 to 8;
signal div_clk: std_logic;
signal  rw_sig ,sda_out , sda_in , out_en: std_logic;
signal receive_data: std_logic_vector(7 downto 0);
--constant addr_in : std_logic_vector(7 downto 0) := "10101010";
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

I2C_FSM_PROCESS : process (rst , clk , bit_cnt , STATE_I2C , en ,sda , rw , rw_sig , STATE_TRANSMISSION ,STATE_RECEIVE , STATE_ADDR )
begin
    if rst = '1' then
        STATE_I2C <= IDLE;
    elsif rising_edge(div_clk) then
        if scl = '1' then
            case STATE_I2C is
                when IDLE =>
                    if en = '1' then
                        STATE_I2C <= START;
                    else
                        STATE_I2C <= IDLE;
                    end if;
                when START =>
                    case STATE_START is 
                        when STEADY => STATE_I2C <= ADDR; 
                        when others => STATE_I2C <= START;
                    end case;                
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
                when RESPONSE =>            -- ack => sda = '0'    ;     nack => sda = '1' 
                    if sda_in = '0' then
                        if rw_sig = '0' then    --rw = '1'  master write
                            STATE_I2C <= RECEIVE;
                        else
                            STATE_I2C <= TRANSMISSION;                        
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
DATA_FSM : process(rst , clk , STATE_I2C , STATE_START , STATE_ADDR , STATE_READWRITE , STATE_TRANSMISSION , STATE_RECEIVE , STATE_RESPONSE )
begin
    if rst = '1'then
        STATE_ADDR         <= TRANSIENT;
        STATE_START        <= TRANSIENT;
        STATE_TRANSMISSION <= TRANSIENT;
        STATE_RESPONSE     <= TRANSIENT;
        STATE_READWRITE    <= TRANSIENT;
    elsif rising_edge(div_clk)then
        case STATE_I2C is
            when START => 
                case STATE_START is
                    when STEADY    => STATE_START <= TRANSIENT;
                    when TRANSIENT => STATE_START <= STEADY;               
                end case;        
            when ADDR => 
                case STATE_ADDR is
                    when STEADY    => STATE_ADDR <= TRANSIENT;
                    when TRANSIENT => STATE_ADDR <= STEADY;                      
                end case;
            when READWRITE =>
                case STATE_READWRITE is
                    when STEADY    => STATE_READWRITE <= TRANSIENT;
                    when TRANSIENT => STATE_READWRITE <= STEADY;                      
                end case;                
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
        INOUT_FSM <= DOUT;
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
        out_en <= '1';
    else
        case STATE_I2C is
            when RESPONSE =>
                if rw_sig = '1' then
                    out_en <= '0';
                else
                    out_en <= '1';
                end if;
            when RECEIVE => out_en <= '0';
            when others => out_en <= '1';        
        end case;
    end if;
end process;

SDA_out_ACT :process (rst , clk , STATE_I2C  , bit_cnt , STATE_START , STATE_ADDR , STATE_READWRITE ,  STATE_TRANSMISSION , STATE_RECEIVE , STATE_RESPONSE , STATE_STOP , rw ,sda , rw_sig)
begin
    if rst = '1'then
        sda_out <= '1';
    else
        case STATE_I2C is
            when IDLE  => sda_out <= '1';
            when START =>
                case STATE_START is
                    when STEADY => sda_out <= '0';
                    when others => NULL;
                end case;
            when ADDR =>
                case STATE_ADDR is
                    when TRANSIENT => sda_out <= data_in(bit_cnt);
                    when STEADY => sda_out <= sda_out;
                end case;
            when READWRITE =>       -- rw = '1' => read , rw = '0' => write
                case STATE_READWRITE is
                    when TRANSIENT =>
                        if rw = '1' then
                            sda_out <= '1';
                        else
                            sda_out <= '0';
                        end if;                    
                    when STEADY => sda_out <= sda_out;
                end case;                  
            when TRANSMISSION =>
                case STATE_TRANSMISSION is
                    when TRANSIENT => sda_out <= data_in(bit_cnt);
                    when STEADY => sda_out <= sda_out;
                end case;         
            when RESPONSE =>               
                if rw_sig = '0' then
                    sda_out <= '0';
                else
                    sda_out <= 'Z';
                end if;  
            when STOP   => 
                case STATE_STOP is
                    when STEADY => sda_out <= '1';
                    when TRANSIENT => sda_out <= '0'; 
                end case;               
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
rw_process : process(rst , scl,STATE_I2C,sda)
begin
    if rst = '1' then
        rw_sig <= '0';
    elsif rising_edge(div_clk)then
        if STATE_I2C = READWRITE then
            if rw = '1' then
                rw_sig <= '1';
            else
                rw_sig <= '0';
            end if;
        else
            NULL;
        end if;
    end if;
end process;
SCL_ACT : process(rst , clk , STATE_I2C , STATE_ADDR , STATE_TRANSMISSION , STATE_READWRITE , STATE_RECEIVE , STATE_RESPONSE , STATE_STOP, div_clk)
begin
    if rst = '1'then
        scl <= '1';
    else
        case STATE_I2C is
            when IDLE => scl <= '1';
            when START => scl <= '1';          
            when ADDR =>
                case STATE_ADDR is
                    when STEADY    => scl <= '1';
                    when TRANSIENT => scl <= '0';
                end case;
            when TRANSMISSION =>
                case STATE_TRANSMISSION is
                    when STEADY    => scl <= '1';
                    when TRANSIENT => scl <= '0';
                end case;
            when READWRITE =>
                case STATE_READWRITE is
                    when STEADY    => scl <= '1';
                    when TRANSIENT => scl <= '0';
                end case;                
            when RECEIVE => scl <= 'Z';
            when RESPONSE =>
                if rw = '1' then
                    case STATE_RESPONSE is
                        when STEADY    => scl <= '1';
                        when TRANSIENT => scl <= '0';
                    end case;
                else
                    scl <= 'Z';
                end if;         
            when others => NULL;
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
            when ADDR => 
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
end Behavioral;