library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity TriALU is 
port(
   Clock : in std_logic;
	ALU_Operation: in std_logic_vector(4 downto 0);-- ALU Operations
   Data_in_out_ControlUnit : inout std_logic_vector(23 downto 0):="ZZZZZZZZZZZZZZZZZZZZZZZZ";-- from and to Control unit
	Vector_Length : in std_logic:='0';
	Carry_Out : out std_logic:='0';
	Flags : out std_logic_vector(9 downto 0):="ZZZZZZZZZZ"; 
	Enable : in std_logic:='Z';
	Reset : in std_logic:='Z';
	Complete : Buffer std_logic:='0'
);
end entity;

architecture Behave of TriALU is 

signal Accumulator : std_logic_vector(8 downto 0):="000000000"; -- out
signal Register_A : std_logic_vector(7 downto 0):="00000000";
signal Register_B : std_logic_vector(7 downto 0):="00000000";
signal Feedback : std_logic_vector(7 downto 0):="00000000";
signal Limit : std_logic_vector(7 downto 0):="00000000";
signal Error : std_logic:='0';

signal Operations : std_logic_vector(3 downto 0):="0000";
signal Logic_Operations : std_logic:='0';
signal Shift_Operations : std_logic_vector(1 downto 0):="00"; 
signal Variables : std_logic_vector(2 downto 0):="000";
signal Signs : std_logic_vector(2 downto 0):="000";
signal Division_Over_Operation : std_logic := '0';
signal Destinations : std_logic_vector(3 downto 0):="0000";
signal Feedback_Operation : std_logic_vector(1 downto 0):="00";
signal Modes : std_logic_vector(1 downto 0):="00"; -- 00 normal dtat tramsfer , 01 flip flop (A,B)  

signal Minus : std_logic_vector(7 downto 0):="11111111";  

signal Stack_Pointer: IEEE.NUMERIC_STD.unsigned(1 downto 0) := (others => '0');
begin

	Operations <= Data_in_out_ControlUnit(15 downto 12);
	Logic_Operations <= Data_in_out_ControlUnit(17);
	Shift_Operations <= Data_in_out_ControlUnit(19 downto 18);
	Variables <= Data_in_out_ControlUnit(11 downto 9);
	Signs <= Data_in_out_ControlUnit(8 downto 6);
	Division_Over_Operation <= Data_in_out_ControlUnit(16);
	Destinations <= Data_in_out_ControlUnit(5 downto 2);
	Feedback_Operation <= Data_in_out_ControlUnit(1 downto 0);
	Limit <= Data_in_out_ControlUnit(15 downto 8);
	
	
	process(Clock)
	 variable Variable1 : std_logic_vector(7 downto 0):="00000000";
	 variable Variable2 : std_logic_vector(7 downto 0):="00000000";
	 variable Variable3 : std_logic_vector(7 downto 0):="00000000";
	 variable Result1 : std_logic_vector(8 downto 0):="000000000";
	 variable Result2 : std_logic_vector(8 downto 0):="000000000";
	 variable Switcher : std_logic :='0';
	begin
   
	if rising_edge(Clock) then
	 if Reset = '0' then
	 Data_in_out_ControlUnit <= "ZZZZZZZZZZZZZZZZZZZZZZZZ";
	 Register_A <= "00000000";
    Register_B <= "00000000";
	 Accumulator <= "000000000";
	 Feedback <= "00000000";
    Error <= '0';------------------------------------	
	 Complete <= '0';
	 Flags(8 downto 6) <= "000";
	 Stack_Pointer <= "00";
	 elsif Enable = '1' and Complete = '0' then
	 Error <= '0'; 
	  
	 case ALU_Operation is			 
			when "00000" => -- Operation  Parallel processing MIMD
			     if signs(0)='1' then -- Signs 
				     variable1 := ext((Register_A*Minus),8);
				  else 
				     variable1 := Register_A;
				  end if;
				  if signs(1)='1' then
				     variable2 := ext((Register_B*Minus),8);
				  else 
				     variable2 := Register_B;
				  end if;
				  if signs(2)='1' then
				     if Variables = "100" then -- use Accumulator with a and b registers
					  variable3 := ext((Accumulator*Minus),8);
					  else
				     variable3 := ext((Feedback*Minus),8);
					  end if;
				  else 
				     if Variables = "100" then -- use Accumulator with a and b registers
					  variable3 := ext(Accumulator,8);
					  else
				     variable3 := Feedback;
					  end if;
				  end if;
				  
			if Variables /= "100" then -- use Accumulator with a and b registers
				  if Variables(0)='0' then -- Variables 
				     variable1 := "00000000";
				  end if;
				  if Variables(1)='0' then
				     variable2 := "00000000";
				  end if;
				  if Variables(2)='0' then
				     variable3 := "00000000";
				  end if;
			end if;
				  
				  
				if Logic_Operations = '0' then
 				  if Operations(1 downto 0) = "00" then -- Operations 1 Arithmetic ----------------------------------     
						 if Variables(0)='0' then 
						 Result1 := ext(variable2,9);
						 end if;
						 if Variables(1)='0' then 
						 Result1 := ext(variable1,9);
						 end if;
              end if;
				  
              if Operations(1 downto 0) =  "01" then  -- Addition 1
						 Result1 := ext(variable1 + variable2,9) ;
				  end if;
				  
				  if Operations(1 downto 0) =  "10" then -- multiplication 1
						 Result1 := ext(variable1 * variable2,9);
				  end if;
				  
				  if Operations(1 downto 0) = "11" then  -- division 1
				       if variable2 /= "00000000" then
						 Result1 := ext(std_logic_vector(IEEE.NUMERIC_STD.unsigned(variable1) / IEEE.NUMERIC_STD.unsigned(variable2)),9);
						 else
						 Error <= '1';
						 end if;
				  end if;
				  
			   elsif Logic_Operations = '1' then
				  if Operations(1 downto 0) = "00" then -- Operations 1 logic ----------------------------------     
						 Result1 := ext(variable1 AND variable2,9); --AND
				  
              elsif Operations(1 downto 0) =  "01" then  
						 Result1 := ext(variable1 XOR variable2,9); -- XOR
				 
				  
				  elsif Operations(1 downto 0) =  "10" then 
						 Result1 := ext(variable1 OR variable2,9); -- OR 
						 			  
				  
				  elsif Operations(1 downto 0) = "11" then  
						 Result1 := ext(variable1 NAND variable2,9); -- NOT					 
				  end if;
				 end if;
				
				  
				  if Operations(3 downto 2) = "00" then-- Operations 2 --------------------------------------	no v3		       
						 Result2 := Result1;
				  end if;
				  
				  if Operations(3 downto 2) =  "01" then  -- Addition 2
						 Result2 := Result1 + variable3 ;
				  end if;
				  
				  if Operations(3 downto 2) = "10" then -- multiplication 2
						 Result2 := ext(Result1 * variable3,9);
				  end if;
				  
				  if Operations(3 downto 2) = "11" then -- division 2
				     
					    if Division_Over_Operation = '0' then 
						    if variable3 /= "00000000" then
						    Result2 := ext(std_logic_vector(IEEE.NUMERIC_STD.unsigned(Result1) / IEEE.NUMERIC_STD.unsigned(variable3)),9);
							 else
					       Error <= '1';
					       end if;
						 elsif Division_Over_Operation = '1' then
						       if Result1 /= "00000000" then
						       Result2 := ext(std_logic_vector(IEEE.NUMERIC_STD.unsigned(variable3) / IEEE.NUMERIC_STD.unsigned(Result1)),9);
						       else
					          Error <= '1';
					          end if;
						 end if;
					  
				  end if;
			 
				  
				  -- Destination---------------------------------------
				  if Destinations(0) = '1' then
				     Accumulator <= Result2;
				  end if;
				  if Destinations(1) = '1' then
				     Feedback <= ext(Result2,8);
				  end if;
				  if Destinations(2) = '1' then
				     Register_A <= ext(Result2,8);
				  end if;
				  if Destinations(3) = '1' then
				     Register_B <= ext(Result2,8);
				  end if;
				  
				  case Shift_Operations is
				       when "00" => -- no shift
						 when "01" => 
						      Register_A <=  std_logic_vector(shift_right(IEEE.NUMERIC_STD.unsigned(Register_A),1)); -- shift right
						 when "10" =>
						      Register_A <=  std_logic_vector(shift_left(IEEE.NUMERIC_STD.unsigned(Register_A),1)); -- shift left
						 when others => 
				  end case;
				  
				  case Modes is 
				       when "01" => -- switch the result between A and B in every math operation
				             if Switcher = '0' then
					          Register_A <= ext(Result2,8);
					          elsif Switcher = '1' then
					          Register_B <= ext(Result2,8);
					        	 end if;
				             Switcher := not Switcher;
								 Complete <= '1';
						 when "10" => -- continues, normal mode
						       if Feedback = "00000001" then
								 Complete <= '1';
								 else
								 Complete <= '0';
								 end if;
								 Switcher := '0';
						 when "11" => -- continues, switch the result between A and B in every math operation 
				             if Switcher = '0' then
					          Register_A <= ext(Result2,8);
					          elsif Switcher = '1' then
					          Register_B <= ext(Result2,8);
					        	 end if;
				             Switcher := not Switcher;
						       if Feedback = "00000001" then
								 Complete <= '1';
								 else
								 Complete <= '0';
								 end if;
						  when others => -- reseting
						       Switcher := '0'; 
								 Complete <= '1';
				  end case;
				  
				  case Feedback_Operation(1 downto 0) is -- Feedback Operations -------------------------------------------------
				       when "00" => -- No oprations
						 when "01" => -- --
	                     Feedback <= Feedback - 1;
						 when "10" => -- ++
						      Feedback <= Feedback + 1;
						 when "11" => -- Zeros
						      Feedback <= "00000000";
						 when others =>
	           end case;
				  
				  
			when "00001" => -- Load value to corresponding register and set mods----------------------------------------------------------------------------------
				  if Data_in_out_ControlUnit(9 downto 8) = "00" then
	               Register_A <= Data_in_out_ControlUnit(7 downto 0);
	           elsif Data_in_out_ControlUnit(9 downto 8) = "01" then
                  Register_B <= Data_in_out_ControlUnit(7 downto 0);
				  elsif Data_in_out_ControlUnit(9 downto 8) = "10" then
					   Feedback <= Data_in_out_ControlUnit(7 downto 0);
				  elsif Data_in_out_ControlUnit(9 downto 8) = "11" then	
				      Accumulator(7 downto 0) <= Data_in_out_ControlUnit(7 downto 0);
				  end if; 
			     Modes <= Data_in_out_ControlUnit(11 downto 10); 
				  Complete <= '1';
			when "00010" => -- Feedback flags
			      if Feedback = Limit then
					   Flags(6) <= '1';
						else
						Flags(6) <= '0';
					end if;
					
					if Feedback < Limit then
					   Flags(7) <= '1';
						else
						Flags(7) <= '0';
					end if;
					
					if Feedback > Limit then
					   Flags(8) <= '1';
						else
						Flags(8) <= '0';
					end if;
					Complete <= '1';
			when "00011" => 
			     Data_in_out_ControlUnit(7 downto 0) <= Accumulator(7 downto 0);
				  Complete <= '1';
				  
			 --TRIALU Accumulator structure ------------------------------------------------------------------------	  
			when "00100" =>
			     Accumulator <= ext(Accumulator(7 downto 0) + Register_A,9); 
			when "00101" =>  
			     Accumulator <= ext(Accumulator(7 downto 0) - Register_A,9); 
			when "00110" =>  
			     Accumulator <= ext(Accumulator(7 downto 0) and Register_A,9); 
			when "00111" =>  
			     Accumulator <= ext(Accumulator(7 downto 0) or Register_A,9); 
			when "01100" => 
			     Accumulator <= ext(Accumulator(7 downto 0) + Register_B,9); 
			when "01101" =>  
			     Accumulator <= ext(Accumulator(7 downto 0) - Register_B,9); 
			when "01110" =>  
			     Accumulator <= ext(Accumulator(7 downto 0) and Register_B,9); 
			when "01111" =>  
			     Accumulator <= ext(Accumulator(7 downto 0) or Register_B,9); 
			
         --Vector processing SIMD -----------------------------------------------------------------------		
			when "10000" => -- Add values
			    if Vector_Length = '0' then
				 Register_A <= Register_A + Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B + Data_in_out_ControlUnit(15 downto 8);
				 else
				 Register_A <= Register_A + Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B + Data_in_out_ControlUnit(15 downto 8);
				 Feedback   <= Feedback + Data_in_out_ControlUnit(7 downto 0);
				 end if;
				 
			when "10001" =>  -- Add value
			    if Vector_Length = '0' then
				 Register_A <= Register_A + Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B + Data_in_out_ControlUnit(23 downto 16);
				 else
				 Register_A <= Register_A + Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B + Data_in_out_ControlUnit(23 downto 16);
				 Feedback   <= Feedback + Data_in_out_ControlUnit(23 downto 16);
				 end if;
				 
			when "10010" => -- Greater values
	           if Register_A >= Register_B and Register_A >= Feedback then
                 Accumulator <= ext(Register_A,9);
                 elsif Register_B >= Register_A and Register_B >= Feedback then
                 Accumulator <= ext(Register_B,9);
                 else
                 Accumulator <= ext(Feedback,9);
              end if;
				 
			when "10011" => -- Smaller value
			     if Register_A <= Register_B and Register_A <= Feedback then
                 Accumulator <= ext(Register_A,9);
                 elsif Register_B <= Register_A and Register_B <= Feedback then
                 Accumulator <= ext(Register_B,9);
                 else
                 Accumulator <= ext(Feedback,9);
              end if;
				 
			when "11000" => -- Xor values
			    if Vector_Length = '0' then
				 Register_A <= Register_A xor Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B xor Data_in_out_ControlUnit(15 downto 8);
				 else
				 Register_A <= Register_A xor Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B xor Data_in_out_ControlUnit(15 downto 8);
				 Feedback   <= Feedback xor Data_in_out_ControlUnit(7 downto 0);
				 end if;
			when "11001" => -- Xor value
	          if Vector_Length = '0' then
				 Register_A <= Register_A xor Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B xor Data_in_out_ControlUnit(23 downto 16);
				 else
				 Register_A <= Register_A xor Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Register_B xor Data_in_out_ControlUnit(23 downto 16);
				 Feedback   <= Feedback xor Data_in_out_ControlUnit(23 downto 16);
				 end if;		
				 
			when "11010" => -- load values
			    if Vector_Length = '0' then
				 Register_A <= Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Data_in_out_ControlUnit(15 downto 8);
				 else
				 Register_A <= Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Data_in_out_ControlUnit(15 downto 8);
				 Feedback   <= Data_in_out_ControlUnit(7 downto 0);
				 end if;
				 
			when "11011" => -- load value
			    if Vector_Length = '0' then
				 Register_A <= Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Data_in_out_ControlUnit(23 downto 16);
				 else
				 Register_A <= Data_in_out_ControlUnit(23 downto 16);
				 Register_B <= Data_in_out_ControlUnit(23 downto 16);
				 Feedback   <= Data_in_out_ControlUnit(23 downto 16);
				 end if;	
				 
			--TRIALU Stack structure ------------------------------------------------------------------------	  
			when "10100" => -- Push
			     case Stack_Pointer is
		             when "00" => 
						 Register_A <= Data_in_out_ControlUnit(7 downto 0);
						 Stack_Pointer <= Stack_Pointer + 1;
	              	 when "01" => 
						 Register_B <= Data_in_out_ControlUnit(7 downto 0);
						 Stack_Pointer <= Stack_Pointer + 1;
		             when "10" => 
						 Feedback <= Data_in_out_ControlUnit(7 downto 0);
						 Stack_Pointer <= Stack_Pointer + 1;
		             when others => 
						 report "Stack overflow" severity failure;
						 Flags(9) <= '1';
	           end case;
			    
			when "10101" => -- Pop 
			     if Stack_Pointer >= 0 then
			        case Stack_Pointer is
		             when "01" => 
						 Stack_Pointer <= Stack_Pointer - 1;
						 Accumulator(7 downto 0 ) <= Register_A;
	              	 when "10" => 
						 Stack_Pointer <= Stack_Pointer - 1;
						 Accumulator(7 downto 0 ) <= Register_B;
		             when "11" => 
						 Stack_Pointer <= Stack_Pointer - 1;
						 Accumulator(7 downto 0 ) <= Feedback;
		             when others => 
	           end case;
				  else 
				  report "Stack underflow" severity failure;
				  end if;
				  
			when "10110" =>  -- +
			     case Stack_Pointer is
		             when "01" => 
						 Register_A <= Register_A + Register_A;
	              	 when "10" => 
						 Register_A <= Register_A + Register_B;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when "11" => 
						 Register_B <= Register_B + Feedback;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when others => 
						 report "Stack underflow" severity failure;
	           end case;
			when "10111" => -- - 
			     case Stack_Pointer is
		             when "01" => 
						 Register_A <= Register_A - Register_A;
	              	 when "10" => 
						 Register_A <= Register_A - Register_B;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when "11" => 
						 Register_B <= Register_B - Feedback;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when others => 
						 report "Stack underflow" severity failure;
	           end case;
			when "11100" => -- * 
			     case Stack_Pointer is
		             when "01" => 
						 Register_A <= ext(Register_A * Register_A,8);
	              	 when "10" => 
						 Register_A <= ext(Register_A * Register_B,8);
						 Stack_Pointer <= Stack_Pointer - 1;
		             when "11" => 
						 Register_B <= ext(Register_B * Feedback,8);
						 Stack_Pointer <= Stack_Pointer - 1;
		             when others => 
						 report "Stack underflow" severity failure;
	           end case;
			when "11101" => -- /
			     case Stack_Pointer is
		             when "01" => 
						 if Register_A /= "00000000" then
						 Register_A <= std_logic_vector(IEEE.NUMERIC_STD.unsigned(Register_A) / IEEE.NUMERIC_STD.unsigned(Register_A));
					    else
					    Error <= '1';	
		             end if;	
						 
	              	 when "10" => 
						 if Register_B /= "00000000" then
						 Register_A <= std_logic_vector(IEEE.NUMERIC_STD.unsigned(Register_A) / IEEE.NUMERIC_STD.unsigned(Register_B));
						 Stack_Pointer <= Stack_Pointer - 1;
					    else
					    Error <= '1';
                   end if;
						 
		             when "11" => 
						 if Feedback /= "00000000" then
						 Register_B <= std_logic_vector(IEEE.NUMERIC_STD.unsigned(Register_B) / IEEE.NUMERIC_STD.unsigned(Feedback));
						 Stack_Pointer <= Stack_Pointer - 1;
					    else
					    Error <= '1';
                   end if;
						 
		             when others => 
						 report "Stack underflow" severity failure;
	           end case;
			when "11110" =>  -- AND
			     case Stack_Pointer is
		             when "01" => 
						 Register_A <= Register_A and Register_A;
	              	 when "10" => 
						 Register_A <= Register_A and Register_B;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when "11" => 
						 Register_B <= Register_B and Feedback;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when others => 
						 report "Stack underflow" severity failure;
	           end case;
			when "11111" =>  -- OR
			     case Stack_Pointer is
		             when "01" => 
						 Register_A <= Register_A or Register_A;
	              	 when "10" => 
						 Register_A <= Register_A or Register_B;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when "11" => 
						 Register_B <= Register_B or Feedback;
						 Stack_Pointer <= Stack_Pointer - 1;
		             when others => 
						 report "Stack underflow" severity failure;
	           end case;
			
			when others =>
	 end case;
            
	 else
	 Data_in_out_ControlUnit <= (others=>'Z');
	 Complete <= '0';
	 end if;
	end if;
	end process;
	
	process(Clock)   -- Flags process
	begin
	
	if rising_edge(Clock) then
	if Reset = '0' then
	Carry_Out <= '0';
	Flags(5 downto 0) <= "000000";
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