library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_control is
    Port (
 	destination : in  STD_LOGIC_VECTOR(1 downto 0); 
        data_in     : in  STD_LOGIC_VECTOR(7 downto 0); 
        CLK   : in  STD_LOGIC; 
        CS    : out STD_LOGIC; 
        S_OUT : out STD_LOGIC;  
	S_CLK : out STD_LOGIC
    );
end spi_control;

architecture Behavioral of spi_control is
    signal count_clk : integer range 0 to 3 := 0;
    signal clk_out : STD_LOGIC := '0'; 

    type state_type is (S0, S1, S2, S3, S4);
    signal current_state, next_state : state_type;
    signal cs_internal : STD_LOGIC := '1';
    signal rise : STD_LOGIC := '0'; 

    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); 
    signal cycle_count : integer := 0;                                 
    signal max_cycles : integer := 0; 

begin

    CS <= cs_internal;
    S_CLK <= clk_out;  
    

    CLOCK_DIVIDER: process(CLK)
    begin
        if rising_edge(CLK) then
            if count_clk < 3 then
                count_clk <= count_clk + 1; 
            else
                count_clk <= 0; 
                clk_out <= not clk_out; 
            end if;
        end if;
    end process;


    FSM_STATE_CHANGE: process(clk_out)
    begin
        if rising_edge(clk_out) then
            current_state <= next_state; 
        end if;
    end process;

	CS_CONTROL: process(current_state, clk_out)
	begin
	    if falling_edge(clk_out) then
		if current_state = S1 then
		    cs_internal <= '0';
		elsif (current_state = S3 and cycle_count = max_cycles - 1)  then
		    cs_internal <= '1';
		end if;
	    end if;
	end process;

    MAX_CYCLES_CONTROL: process(destination)
    begin 
      max_cycles <= (to_integer(unsigned(destination)) + 1) * 8; 
    end process;

    S_OUT_CONTROL:process(shift_reg)
    begin 
      S_OUT <= shift_reg(0); 
    end process;

    process(current_state, clk_out)
    begin
        if(rising_edge(clk_out)) then
		case current_state is
		    when S0 =>
                        shift_reg <= data_in;
                        next_state <= S1;

		    when S1 =>
		         next_state <= S3;

		    when S3 =>                        
		        shift_reg <= '0' & shift_reg(7 downto 1);       
		                      
		        if cycle_count = max_cycles - 1 then
		            next_state <= S0;
                            cycle_count <= 0;                          
		        else 
                            next_state <= S3;
                            cycle_count <= cycle_count + 1;  
                        end if;

		    when others =>
		        next_state <= S0;
		end case;
        end if;
    end process;

end Behavioral;