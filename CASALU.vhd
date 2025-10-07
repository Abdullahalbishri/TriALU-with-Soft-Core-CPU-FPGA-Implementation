library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity CASALU is -- Dynamic configurable cascade alus
port(
   Clock : in std_logic;
   Data_in_out_ControlUnit : inout std_logic_vector(15 downto 0):="ZZZZZZZZZZZZZZZZ";-- from and to Control unit
	Carry_Out : out std_logic:='0';
	Flags : out std_logic_vector(5 downto 0):="ZZZZZZ"; 
	Enable : in std_logic:='Z';
	Reset : in std_logic:='Z'
);
end entity;

architecture Behave of CASALU is 

signal Accumulator : std_logic_vector(8 downto 0):="000000000"; -- out
signal Register_A : std_logic_vector(7 downto 0):="00000000";
signal Register_B : std_logic_vector(7 downto 0):="00000000";
signal Register_C : std_logic_vector(7 downto 0):="00000000";
signal Register_D : std_logic_vector(7 downto 0):="00000000";
signal Error : std_logic:='0';

signal Sequence : std_logic_vector(1 downto 0):="00";
signal Operation_1 : std_logic_vector(1 downto 0):="00";
signal Destination_1 : std_logic_vector(1 downto 0):="00";
signal Operation_2 : std_logic_vector(1 downto 0):="00";
signal Destination_2 : std_logic_vector(1 downto 0):="00";
signal Operation_3 : std_logic_vector(1 downto 0):="00";
signal Destination_3 : std_logic_vector(1 downto 0):="00";
signal Variables : std_logic_vector(4 downto 0):="00000";
signal Signs : std_logic_vector(4 downto 0):="00000";

signal PU1_2 : std_logic_vector(7 downto 0):="00000000"; -- to processing unit 2
signal PU1_3 : std_logic_vector(7 downto 0):="00000000"; -- to processing unit 3
signal FD1 : std_logic_vector(7 downto 0):="00000000";  -- feedback 1
signal Result1 : std_logic_vector(8 downto 0):="000000000"; -- Result pu1
signal PU2_1 : std_logic_vector(7 downto 0):="00000000"; 
signal PU2_3 : std_logic_vector(7 downto 0):="00000000";
signal FD2 : std_logic_vector(7 downto 0):="00000000";  
signal Result2 : std_logic_vector(8 downto 0):="000000000"; -- Result pu2
signal PU3_1 : std_logic_vector(7 downto 0):="00000000"; 
signal PU3_2 : std_logic_vector(7 downto 0):="00000000";
signal FD3 : std_logic_vector(7 downto 0):="00000000";  
signal Result3 : std_logic_vector(8 downto 0):="000000000"; -- Result pu3

signal Steps : std_logic_vector(2 downto 0):="001";  
signal Operation_Counter: IEEE.NUMERIC_STD.unsigned(2 downto 0) := (others => '0');
signal Minus : std_logic_vector(7 downto 0):="11111111";  
begin

	Sequence <= Data_in_out_ControlUnit(15 downto 14);
	Operation_1 <= Data_in_out_ControlUnit(13 downto 12);
	Destination_1 <= Data_in_out_ControlUnit(11 downto 10);
	Operation_2 <= Data_in_out_ControlUnit(9 downto 8);
	Destination_2 <= Data_in_out_ControlUnit(7 downto 6);
	Operation_3 <= Data_in_out_ControlUnit(5 downto 4);
	Destination_3 <= Data_in_out_ControlUnit(3 downto 2);
	Variables <= Data_in_out_ControlUnit(9 downto 5);
	Signs <= Data_in_out_ControlUnit(4 downto 0);
	
	process(Clock)
	begin
   
	if rising_edge(Clock) then
	if Reset = '0' then
	Data_in_out_ControlUnit <= "ZZZZZZZZZZZZZZZZ";
	Register_A <= "00000000";
   Register_B <= "00000000";
	Register_C <= "00000000";
   Register_D <= "00000000";
	Accumulator <= "000000000";
   Error <= '0';------------------------------------
   PU1_2 <= "00000000"; -- to processing unit 2
   PU1_3 <= "00000000"; -- to processing unit 3
   FD1 <= "00000000";  -- feedback 1
   Result1 <= "000000000"; -- Result pu1
   PU2_1 <= "00000000";
   PU2_3 <= "00000000";
   FD2 <= "00000000";
   Result2 <= "000000000";-- Result pu2
   PU3_1 <= "00000000"; 
   PU3_2 <= "00000000";
   FD3 <= "00000000";  
   Result3 <= "000000000"; -- Result pu3
	----------------------------------------
	Steps <= "001";
	Operation_Counter <= (others=>'0');	
	
	elsif Enable = '1' then
	Error <= '0'; 
	Steps(2 downto 1) <= Sequence;
	
	            case Sequence is			 
			      when "00" => -- PU1 operations 
					
		               case Operation_1 is		
							when "00" => -- Math op------------         operation matrix 0 +  1 -
							     case Destination_1 is
								  when "00" =>
                          -- (v*-1 + not v*1)* x
								  PU1_2 <= ext((ext((("0000000"&Signs(0))*Minus),8)+("0000000"&not(Signs(0)))) * ext((("0000000"&Variables(0))*Register_A),8),8) + ext((ext((("0000000"&Signs(1))*Minus),8)+("0000000"&not(Signs(1)))) * ext((("0000000"&Variables(1))*Register_B),8),8) + ext((ext((("0000000"&Signs(2))*Minus),8)+("0000000"&not(Signs(2)))) * ext((("0000000"&Variables(2))*FD1),8),8) + ext((ext((("0000000"&Signs(3))*Minus),8)+("0000000"&not(Signs(3)))) * ext((("0000000"&Variables(3))*PU2_1),8),8) + ext((ext((("0000000"&Signs(4))*Minus),8)+("0000000"&not(Signs(4)))) * ext((("0000000"&Variables(4))*PU3_1),8),8); 
								  when "01" =>
								  FD1 <= ext((ext((("0000000"&Signs(0))*Minus),8)+("0000000"&not(Signs(0)))) * ext((("0000000"&Variables(0))*Register_A),8),8) + ext((ext((("0000000"&Signs(1))*Minus),8)+("0000000"&not(Signs(1)))) * ext((("0000000"&Variables(1))*Register_B),8),8) + ext((ext((("0000000"&Signs(2))*Minus),8)+("0000000"&not(Signs(2)))) * ext((("0000000"&Variables(2))*FD1),8),8) + ext((ext((("0000000"&Signs(3))*Minus),8)+("0000000"&not(Signs(3)))) * ext((("0000000"&Variables(3))*PU2_1),8),8) + ext((ext((("0000000"&Signs(4))*Minus),8)+("0000000"&not(Signs(4)))) * ext((("0000000"&Variables(4))*PU3_1),8),8);
								  when "10" =>
								  Accumulator <= ext((ext((("0000000"&Signs(0))*Minus),8)+("0000000"&not(Signs(0)))) * ext((("0000000"&Variables(0))*Register_A),8),9) + ext((ext((("0000000"&Signs(1))*Minus),8)+("0000000"&not(Signs(1)))) * ext((("0000000"&Variables(1))*Register_B),8),9) + ext((ext((("0000000"&Signs(2))*Minus),8)+("0000000"&not(Signs(2)))) * ext((("0000000"&Variables(2))*FD1),8),9) + ext((ext((("0000000"&Signs(3))*Minus),8)+("0000000"&not(Signs(3)))) * ext((("0000000"&Variables(3))*PU2_1),8),9) + ext((ext((("0000000"&Signs(4))*Minus),8)+("0000000"&not(Signs(4)))) * ext((("0000000"&Variables(4))*PU3_1),8),9);
								  when "11" =>
								  PU1_2 <= ext((ext((("0000000"&Signs(0))*Minus),8)+("0000000"&not(Signs(0)))) * ext((("0000000"&Variables(0))*Register_A),8),8) + ext((ext((("0000000"&Signs(1))*Minus),8)+("0000000"&not(Signs(1)))) * ext((("0000000"&Variables(1))*Register_B),8),8) + ext((ext((("0000000"&Signs(2))*Minus),8)+("0000000"&not(Signs(2)))) * ext((("0000000"&Variables(2))*FD1),8),8) + ext((ext((("0000000"&Signs(3))*Minus),8)+("0000000"&not(Signs(3)))) * ext((("0000000"&Variables(3))*PU2_1),8),8) + ext((ext((("0000000"&Signs(4))*Minus),8)+("0000000"&not(Signs(4)))) * ext((("0000000"&Variables(4))*PU3_1),8),8);-- FD1 feedback to processing unit 2
								  PU1_3 <= ext((ext((("0000000"&Signs(0))*Minus),8)+("0000000"&not(Signs(0)))) * ext((("0000000"&Variables(0))*Register_A),8),8) + ext((ext((("0000000"&Signs(1))*Minus),8)+("0000000"&not(Signs(1)))) * ext((("0000000"&Variables(1))*Register_B),8),8) + ext((ext((("0000000"&Signs(2))*Minus),8)+("0000000"&not(Signs(2)))) * ext((("0000000"&Variables(2))*FD1),8),8) + ext((ext((("0000000"&Signs(3))*Minus),8)+("0000000"&not(Signs(3)))) * ext((("0000000"&Variables(3))*PU2_1),8),8) + ext((ext((("0000000"&Signs(4))*Minus),8)+("0000000"&not(Signs(4)))) * ext((("0000000"&Variables(4))*PU3_1),8),8);-- FD1 feedback to processing unit 3
							     when others =>
					           end case; 
							Result1 <= ext((ext((("0000000"&Signs(0))*Minus),8)+("0000000"&not(Signs(0)))) * ext((("0000000"&Variables(0))*Register_A),8),9) + ext((ext((("0000000"&Signs(1))*Minus),8)+("0000000"&not(Signs(1)))) * ext((("0000000"&Variables(1))*Register_B),8),9) + ext((ext((("0000000"&Signs(2))*Minus),8)+("0000000"&not(Signs(2)))) * ext((("0000000"&Variables(2))*FD1),8),9) + ext((ext((("0000000"&Signs(3))*Minus),8)+("0000000"&not(Signs(3)))) * ext((("0000000"&Variables(3))*PU2_1),8),9) + ext((ext((("0000000"&Signs(4))*Minus),8)+("0000000"&not(Signs(4)))) * ext((("0000000"&Variables(4))*PU3_1),8),9); -- for check
							
							when "01" => ----------------           Register_A fworword
							     case Destination_1 is
								  when "00" =>                   
								  PU1_2 <= Register_A;
								  when "01" =>
								  FD1 <= Register_A;
								  when "10" =>
								  Accumulator <= ext(Register_A,9);
								  when "11" =>
								  PU1_2 <= Register_A;
								  PU1_3 <= Register_A;
							     when others =>
					           end case; 
							
							when "10" => ----------------           Result1 forward 
							     case Destination_1 is
								  when "00" =>                   
								  PU1_2 <= ext(Result1,8);
								  when "01" =>
								  FD1 <= ext(Result1,8);
								  when "10" =>
								  Accumulator <= Result1;
								  when "11" =>
								  PU1_2 <= ext(Result1,8);
								  PU1_3 <= ext(Result1,8);
							     when others =>
					           end case; 
							when others =>
					      end case; 							  
							
               when others => ----------------------- Cascade operations ---------------------  ex 1110110111010000	, 0000111100000000 				
					
					  if Operation_Counter < 3  then	
					   Operation_Counter <= Operation_Counter+1;
						
					    if Steps(0) = '1'  then		
					      case Operation_1 is		
               	   when "00" =>  -- Add							
							     case Destination_1 is
								  when "00" =>
								  PU1_2 <= Register_A + Register_B + FD1 + PU2_1 + PU3_1;-- PU1 go to processing unit 2 								
								  when "01" =>
								  FD1 <= Register_A + Register_B + FD1 + PU2_1 + PU3_1;-- FD1 feedback to processing unit 1
								  when "10" =>
								  Accumulator <= ext((Register_A + Register_B + FD1 + PU2_1 + PU3_1),9);-- go to output
								  when "11" =>
								  PU1_2 <= Register_A + Register_B + FD1 + PU2_1 + PU3_1;-- FD1 feedback to processing unit 2
								  PU1_3 <= Register_A + Register_B + FD1 + PU2_1 + PU3_1;-- FD1 feedback to processing unit 3
							     when others =>
					           end case; 
							Result1 <= ext((Register_A + Register_B + FD1 + PU2_1 + PU3_1),9);
							
				         when "01" =>  -- Sub							
							     case Destination_1 is
								  when "00" =>
								  PU1_2 <= Register_A - Register_B - FD1 - PU2_1 - PU3_1;-- PU1 go to processing unit 2 								
								  when "01" =>
								  FD1 <= Register_A - Register_B - FD1 - PU2_1 - PU3_1;-- FD1 feedback to processing unit 1
								  when "10" =>
								  Accumulator <= ext((Register_A - Register_B - FD1 - PU2_1 - PU3_1),9);-- go to output
								  when "11" =>
								  PU1_2 <= Register_A - Register_B - FD1 - PU2_1 - PU3_1;-- FD1 feedback to processing unit 2
								  PU1_3 <= Register_A - Register_B - FD1 - PU2_1 - PU3_1;-- FD1 feedback to processing unit 3
							     when others =>
					           end case; 
							Result1 <= ext((Register_A - Register_B - FD1 - PU2_1 - PU3_1),9);
							 
				          when "10" =>  -- A forward 							
							     case Destination_1 is
								  when "00" =>
								  PU1_2 <= Register_A;-- PU1 go to processing unit 2 								
								  when "01" =>
								  FD1 <= Register_A;-- FD1 feedback to processing unit 1
								  when "10" =>
								  Accumulator <= ext((Register_A),9);-- go to output
								  when "11" =>
								  PU1_2 <= Register_A;-- FD1 feedback to processing unit 2
								  PU1_3 <= Register_A;-- FD1 feedback to processing unit 3
							     when others =>
					           end case; 						
							
							  when "11" =>  -- Result1 forward 							
							     case Destination_1 is
								  when "00" =>
								  PU1_2 <= ext(Result3,8);
								  when "01" =>
								  FD1 <= ext(Result3,8);
								  when "10" =>
								  Accumulator <= Result3;-- go to output
								  when "11" =>
								  PU1_3 <= ext(Result3,8);
							     when others =>
					           end case;						
							when others =>
					      end case;
						 Steps(0) <= '0';
						 end if;
					  
					  ------------------------------------ PU2 ---------------------------
				       if Steps(1) = '1' and Steps(0) /= '1'  then		
					      case Operation_2 is		
               	   when "00" =>  -- Add							
							     case Destination_2 is
								  when "00" =>
								  PU2_3 <= Register_C + FD2 + PU1_2 + PU3_2;
								  when "01" =>
								  FD2 <= Register_C + FD2 + PU1_2 + PU3_2;
								  when "10" =>
								  Accumulator <= ext((Register_C + FD2 + PU1_2 + PU3_2),9);-- go to output
								  when "11" =>
								  PU2_1 <= Register_C + FD2 + PU1_2 + PU3_2;
							     when others =>
					           end case;  
							Result2 <= ext((Register_C + FD2 + PU1_2 + PU3_2),9);
							
				         when "01" =>  -- Sub							
							     case Destination_2 is
								  when "00" =>
								  PU2_3 <= PU1_2 - Register_C - FD2 - PU3_2;
								  when "01" =>
								  FD2 <= Register_C - FD2 - PU1_2 - PU3_2;
								  when "10" =>
								  Accumulator <= ext((Register_C - FD2 - PU1_2 - PU3_2),9);-- go to output
								  when "11" =>
								  PU2_1 <=  PU1_2 - PU3_2 - Register_C - FD2;
							     when others =>
					           end case;			
							 Result2 <= ext((Register_C - FD2 - PU1_2 - PU3_2),9);
							 
				          when "10" =>  -- C forward 							
							     case Destination_2 is
								  when "00" =>
								  PU2_3 <= Register_C;
								  when "01" =>
								  FD2 <= Register_C;
								  when "10" =>
								  Accumulator <= ext(Register_C,9);-- go to output
								  when "11" =>
								  PU2_1 <= Register_C;
							     when others =>
					           end case;						
							
							  when "11" =>  -- Result2 forward 							
							     case Destination_2 is
								  when "00" =>
								  PU2_3 <= ext(Result2,8);
								  when "01" =>
								  FD2 <= ext(Result2,8);
								  when "10" =>
								  Accumulator <= Result2;-- go to output
								  when "11" =>
								  PU2_1 <= ext(Result2,8);
							     when others =>
					           end case;						
							when others =>
					      end case;
						 Steps(1) <= '0';
						 Steps(2) <= '1';
						 end if;
						 
						 -----------------------------------PU3-------------------------------------------
						 if Steps(2) = '1' and Steps(0) /= '1'  then		
					      case Operation_3 is		
               	   when "00" =>  -- Add							
							     case Destination_3 is
								  when "00" =>
								  PU3_1 <= Register_D + FD3 + PU1_3 + PU3_2;
								  when "01" =>
								  FD3 <= Register_D + FD3 + PU1_3 + PU3_2;
								  when "10" =>
								  Accumulator <= ext((Register_D + FD3 + PU1_3 + PU3_2),9);-- go to output
								  when "11" =>
								  PU3_2 <= Register_D + FD3 + PU1_3 + PU3_2;
							     when others =>
					           end case;  
							Result3 <= ext((Register_D + FD3 + PU1_3 + PU3_2),9);
							
				         when "01" =>  -- Sub							
							     case Destination_3 is
								  when "00" =>
								  PU3_1 <=  PU1_3 - Register_D - FD3 - PU3_2;
								  when "01" =>
								  FD3 <= Register_D - FD3 - PU1_3 - PU3_2;
								  when "10" =>
								  Accumulator <= ext((Register_D - FD3 - PU1_3 - PU3_2),9);-- go to output
								  when "11" =>
								  PU3_2 <= FD3 - PU1_3 - PU3_2 - Register_D;
							     when others =>
					           end case;  
							Result3 <= ext((Register_D - FD3 - PU1_3 - PU3_2),9);
							
				          when "10" =>  -- D forward 							
							     case Destination_3 is
								  when "00" =>
								  PU3_1 <= Register_D;
								  when "01" =>
								  FD3 <= Register_D;
								  when "10" =>
								  Accumulator <= ext((Register_D),9);-- go to output
								  when "11" =>
								  PU3_2 <= Register_D;
							     when others =>
					           end case;  
							--Result3 <= Register_D;					
							
							  when "11" =>  -- Result3 forward 							
							     case Destination_3 is
								  when "00" =>
								  PU3_1 <= ext(Result3,8);
								  when "01" =>
								  FD3 <= ext(Result3,8);
								  when "10" =>
								  Accumulator <= Result3;-- go to output
								  when "11" =>
								  PU3_2 <= ext(Result3,8);
							     when others =>
					           end case;  					
							when others =>
					      end case;
						 Steps(1) <= '1';
						 Steps(2) <= '0';
						 end if;
						 
					 end if;
					end case;
             
	else
	Data_in_out_ControlUnit <= (others=>'Z');		
   Operation_Counter <= (others=>'0');	
	Steps <= "001";	
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