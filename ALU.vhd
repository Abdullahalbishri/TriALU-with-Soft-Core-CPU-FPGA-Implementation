library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ALU is
port(
   Clock : in std_logic;
   ALU_Operation: in std_logic_vector(2 downto 0);-- ALU Operations
   Data_in_out_ControlUnit : inout std_logic_vector(15 downto 0):="ZZZZZZZZZZZZZZZZ";-- from and to Control unit
	Carry_Out : out std_logic:='0';
	Flags : out std_logic_vector(5 downto 0):="ZZZZZZ"; 
	Enable : in std_logic:='Z';
	Reset : in std_logic:='Z'
);
end entity;

architecture Behave of ALU is 

signal Accumulator : std_logic_vector(8 downto 0):="000000000";
signal Register_A : std_logic_vector(7 downto 0):="00000000";
signal Register_B : std_logic_vector(7 downto 0):="00000000";
signal Error : std_logic:='0';
begin
	
	
	process(Clock)
	begin
   
	if rising_edge(Clock) then
	if Reset = '0' then
	Data_in_out_ControlUnit <= "ZZZZZZZZZZZZZZZZ";
	Register_A <= "00000000";
   Register_B <= "00000000";
	Accumulator <= "000000000";
   Error <= '0';
	elsif Enable = '1' then
	Error <= '0'; 
					
	            case ALU_Operation is			 
			      when "000" => -- ADDI      
               Accumulator <= ext(Data_in_out_ControlUnit(15 downto 8),9) + ext(Data_in_out_ControlUnit(7 downto 0),9);	-- BUG !!!
					
               when "001" => -- SUBI
               Accumulator <= ext(Data_in_out_ControlUnit(15 downto 8),9) - ext(Data_in_out_ControlUnit(7 downto 0),9);	
					
					when "010" => -- MOV load value to corresponding register
					   if Data_in_out_ControlUnit(1 downto 0) = "00" then
	               Register_A <= Data_in_out_ControlUnit(15 downto 8);
	               elsif Data_in_out_ControlUnit(1 downto 0) = "01" then
                  Register_B <= Data_in_out_ControlUnit(15 downto 8);
						elsif Data_in_out_ControlUnit(1 downto 0) = "10" then
					   Accumulator <= ext(Data_in_out_ControlUnit(15 downto 8),9);
					   end if;
					
					when "011" => -- LDA load value from address to specific register 
					   if Data_in_out_ControlUnit(1 downto 0) = "00" then
	               Register_A <= Data_in_out_ControlUnit(15 downto 8);
	               elsif Data_in_out_ControlUnit(1 downto 0) = "01" then
                  Register_B <= Data_in_out_ControlUnit(15 downto 8);
					   elsif Data_in_out_ControlUnit(1 downto 0) = "10" then
					   Accumulator <= ext(Data_in_out_ControlUnit(15 downto 8),9);
					   end if;
					
				   when "100" => 
					
					    case Data_in_out_ControlUnit(3 downto 0) is	
						 
		             --Arithmetic operations-------------------------------------------------				 
					    when "0000" => -- ADR add current registers values A+B
						 Accumulator <= ext(Register_A,9) + ext(Register_B,9);
					
					    when "0001" => -- SUR Sub current registers values A-B
					    Accumulator <= ext(Register_A,9) - ext(Register_B,9);
					
				       when "0010" => -- MUL multiple current registers values A*B
				     	 Accumulator <= ext(ext(Register_A,9) * ext(Register_B,9),9);
					
					    when "0011" => -- DIV Sub Divide registers values A/B using shift to right  , check if b is zero to send error flag
						 if Register_B = "00000000" then
						 Error <= '1';
						 else
					    Accumulator <=  std_logic_vector(shift_right(IEEE.NUMERIC_STD.unsigned(ext(Register_A,9)),IEEE.NUMERIC_STD.to_integer(IEEE.NUMERIC_STD.unsigned(Register_B)-1)));
						 end if;
						 -----------------------------------------------------------------------------
						 
						 --Logic operations-----------------------------------------------------------
						 when "0100" => -- AND  current registers values A and B
				     	 Accumulator <= ext(Register_A,9) AND ext(Register_B,9);
						 
						 when "0101" => -- OR  current registers values A or B
				     	 Accumulator <= ext(Register_A,9) OR ext(Register_B,9);
						 
						 when "0110" => -- XOR  current registers values A xor B
				     	 Accumulator <= ext(Register_A,9) XOR ext(Register_B,9);
						 
						 when "0111" => -- NOT  current register value A
				     	 Accumulator <= NOT ext(Register_A,9);						 
						 ------------------------------------------------------------------------------
						 
						 --Register A manipulations----------------------------------------------------
						 when "1000" => -- Increment  current register value A
						 Accumulator <= ext(Register_A,9) + 1;	
						 
						 when "1001" => -- Decrement  current register value A
						 Accumulator <= ext(Register_A,9) - 1;	
						 
						 when "1010" => -- Shift to right  current register value A
						 Accumulator <= ext('0' & Register_A(7 downto 1),9);	

						 when "1011" => -- Shift to lift  current register value A
						 Accumulator <= ext(Register_A(6 downto 0) & '0',9);	                      
						 
						  --Register B manipulations----------------------------------------------------
						 when "1100" => -- Increment  current register value B
						 Accumulator <= ext(Register_B,9) + 1;	                                
						 
						 when "1101" => -- Decrement  current register value B
						 Accumulator <= ext(Register_B,9) - 1;	                              
						 
						 when "1110" => -- Shift to right  current register value B
						 Accumulator <= ext('0' & Register_B(7 downto 1),9);	           

						 when "1111" => -- Shift to lift  current register value B
						 Accumulator <= ext(Register_B(6 downto 0) & '0',9);	             
					    when others =>
					    end case;
						 
					when "101" => 
					Data_in_out_ControlUnit(7 downto 0) <= Accumulator(7 downto 0);
               when others =>
					end case;
             
	else
	Data_in_out_ControlUnit <= (others=>'Z');				
	end if;
	end if;
	end process;
	
	process(Clock)   -- Flags process
	begin
	
	if rising_edge(Clock) then
	if Reset = '0' then
	Carry_Out <= '0';
	Flags <= "000000";
	else
	
	   Flags(5) <= Error; -- division by zero
		Carry_Out <= Accumulator(8); -- Carry
		if Register_A > Register_B then
	   Flags(4) <= '1';
		else
		Flags(4) <= '0';
	   end if;
		
	   if Register_A < Register_B then
	   Flags(3) <= '1';
		else
		Flags(3) <= '0';
	   end if;
	
	   if Register_A > Accumulator then
	   Flags(2) <= '1';
		else
		Flags(2) <= '0';
		end if;
		
	   if Register_A < Accumulator then
	   Flags(1) <= '1';
		else
		Flags(1) <= '0';
	   end if;
	
   if Accumulator(7 downto 0) = "00000000" then
   Flags(0) <= '1'; -- Zero flag
	else
   Flags(0) <= '0';
	end if;
	end if; 
	end if;
	end process;
	
	
end Behave;