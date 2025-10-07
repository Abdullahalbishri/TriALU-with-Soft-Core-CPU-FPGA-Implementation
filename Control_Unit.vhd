library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;

entity Control_Unit is
 generic (
    Address_Bus_Size : integer  := 7;
	 Board_frequency : integer :=  27e6     -- 50MHz oscillator for altera DE2 board
  );
Port ( 
Clock: in std_logic;
Reset: in std_logic:='Z';
Control_Flags : out std_logic_vector(5 downto 0):="101000";
--control flags
-- Empty Stack bit[5],carry bit[4], program counter =0 bit[3], Halt bit[2], stackoverflow error bit[1], division by zero bit[0]

--Memory Handling
Request_Address: out std_logic_vector(Address_Bus_Size downto 0):="ZZZZZZZZ";-- Memory Address
Data_in_out_Memory : inout std_logic_vector(31 downto 0):="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";-- from and to Memory
Memory_Control : out std_logic:='Z';  -- 1 for read 0 for write
Memory_Enable : out std_logic:='Z';
--IO Handling
IRQ : in std_logic;

--ALU Handling 
ALU_Operation: out std_logic_vector(2 downto 0):="ZZZ";-- ALU Operations
Data_in_out_ALU : inout std_logic_vector(15 downto 0):="ZZZZZZZZZZZZZZZZ";-- from and to ALU
ALU_Enable : out std_logic:='Z';
ALU_Carry_Out : in std_logic;
ALU_Flags : in std_logic_vector(5 downto 0);
-- ALU flags
--  division by zero bit[5], A>B bit4, A<B bit3, A > Acc bit2, A < Acc bit1, zero flags bit0

--TriALU Handling 
TriALU_Operation: out std_logic_vector(4 downto 0):="ZZZZZ";-- ALU Operations
Data_in_out_TriALU : inout std_logic_vector(23 downto 0):="ZZZZZZZZZZZZZZZZZZZZZZZZ";-- from and to ALU
TRIALU_Vector_Length : out std_logic:='0';
TriALU_Enable : out std_logic:='Z';
TriALU_Carry_Out : in std_logic;
TriALU_Flags : in std_logic_vector(9 downto 0);
TriALU_Complete : in std_logic
-- TriALU flags
--Sackoverflow bit[9], FeedBack > limit bit[8], FeedBack < limit bit[7], FeedBack = limit bit[6], division by zero bit[5], A>B bit4, A<B bit3, A > Acc bit2, A < Acc bit1, zero flags bit0
);
end Control_Unit;

architecture Behavioral of Control_Unit is
-----------------------------------------------STACK-----------------------------------------------
type Stack is array(0 to 8) of std_logic_vector(Address_Bus_Size+8 downto 0);  -- stck contains address and accumulator value before CALL
signal Call_Stack : Stack := (others=>(others=>'0'));-- use it when jump to save current program counter location and accumulator value
signal Returned_Address_Accumulator : std_logic_vector(Address_Bus_Size+8 downto 0) :=(others => '0');
signal Stack_Pointer : integer range 0 to 8 := 0;
----------------------------------------------------------------------------------------------------
--------------------------------------------CONTROL-------------------------------------------------
signal Program_Counter: std_logic_vector(Address_Bus_Size downto 0):=(others => '0');
signal Memory_Address_Register: std_logic_vector(Address_Bus_Size downto 0):=(others => '0');     --         8bit     256 Addresss
signal Memory_Buffer_Register: std_logic_vector(27 downto 0):="0000000000000000000000000000";
signal Instruction_Register: std_logic_vector(3 downto 0):="0000";

type t_State is (Fetch, Decode, Fetch_Operand, Execute, Store);
signal Control_State : t_State:=Fetch;

--Control State counter
signal Fetch_Counter: unsigned(1 downto 0) := (others => '0');
--signal Decode_Counter: unsigned(1 downto 0) := (others => '0');
signal Store_Counter: unsigned(1 downto 0) := (others => '0');
signal Execute_Counter: unsigned(1 downto 0) := (others => '0');
signal Fetch_Operand_Counter: unsigned(1 downto 0) := (others => '0');
signal ALU_Operation_Counter: unsigned(1 downto 0) := (others => '0');
signal TriALU_Operation_Counter: unsigned(1 downto 0) := (others => '0');

signal HALT_Counter: unsigned(63 downto 0) := (others => '0');-- 64 bits to hold big frequancy value ----------------------------!
signal Total_Halt_Time: unsigned(63 downto 0) := (others => '0');

signal Register_Select : std_logic_vector(1 downto 0):="ZZ";
---------------------------------------------------------------------------------------------------

----------------------------------------Interrupts  H/S----------------------------------------------
signal Software_INT_Mask : std_logic_vector(5 downto 0):="000000"; -- Software Interrupts mask  which can be disabled or enabled. "Hardware interrupt INTR can't be disable"
--TriALU stackoverflow bit[5], carry bit[4], program counter =0 bit[3], Halt bit[2], stackoverflow error bit[1], division by zero bit[0]
type Vector_Table is array(0 to 6) of std_logic_vector(Address_Bus_Size downto 0);  -- Vector table 
signal Interrupts_Vector_Table : Vector_Table := ("01100000","01011000","01010000","01001000","00111000","10000000","11000000");-- change the value when you change the memory size-----------------------------------!!!!!!!!
----division by zero 0----stackoverflow 1----Halt 2----program counter 3----carry bit 4 Non vectored----5 Hardware interrupt INTR vectored 6----TriALU stackoverflow ---------------
------------------------------------------------------------------------------------------------------------------------------------
begin	
	
Control_Process:process(Clock)-----------------------------------COONTROL PROCESS--------------------------------------------------------------------------------------

procedure Emergency_Push(signal Address_Accumulator : in std_logic_vector(Address_Bus_Size+8 downto 0)) is  -- Push Address inside address stack in Emergency situation!!!
begin
Call_Stack(8)(Address_Bus_Size+8 downto 0) <= Address_Accumulator;
Stack_Pointer <= 8;
end procedure Emergency_Push;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
procedure Push_Address_Accumulator(signal Address_Accumulator : in std_logic_vector(Address_Bus_Size+8 downto 0)) is  -- Push Address inside address stack 
begin
if stack_Pointer <= 7 then 
Call_Stack(Stack_Pointer)(Address_Bus_Size+8 downto 0) <= Address_Accumulator;
Stack_Pointer <= Stack_Pointer + 1;
Control_Flags(1) <= '0'; --Stackoverflow flag
Control_Flags(5) <= '0'; --Empty stack flag
else -- ERROR stackoverflow
Control_Flags(1) <= '1';-- stackoverflow error flag
    if Software_INT_Mask(1) = '1' then
	 Emergency_Push(Address_Accumulator);
	 program_Counter <= Interrupts_Vector_Table(1);	
	 Control_Flags(1)<='0';-- Clear the flag
	 end if;
end if;
end procedure Push_Address_Accumulator;
----------------------------------------------------------------------------------------------------------------------------------
procedure Pop_Address_Accumulator  is  -- Pop Address from address stack
begin
if stack_Pointer > 0 then 
 Stack_Pointer <= Stack_Pointer - 1;
 Returned_Address_Accumulator <= Call_Stack(Stack_Pointer-1);
 if((Stack_Pointer - 1) =0) then
 Control_Flags(5) <= '1';-- Empty stack flag
 end if;
elsif stack_Pointer = 0 then
 Control_Flags(5) <= '1';-- Empty stack flag
 Returned_Address_Accumulator <= Call_Stack(Stack_Pointer);
end if;
end procedure Pop_Address_Accumulator;
-----------------------------------------------------------
procedure Carry_Interrupt (signal Address_Accumulator : in std_logic_vector(Address_Bus_Size+8 downto 0)) is    -- Carry interrupt mechanism
begin
	 
	if ALU_Carry_Out = '1'  then
	 Control_Flags(4)<='1';
	 if Software_INT_Mask(4) = '1' then
	  Push_Address_Accumulator(Address_Accumulator);
	 program_Counter <= Interrupts_Vector_Table(4);	
	 Control_Flags(4)<='0';-- Clear the flag
	 end if;
	else
	Control_Flags(4)<='0';
   end if;
end procedure Carry_Interrupt;
------------------------------------------------------------
procedure division_by_zero_Interrupt (signal Address_Accumulator : in std_logic_vector(Address_Bus_Size+8 downto 0)) is -- division by zero error mechanism
begin
	
	if ALU_Flags(5) = '1'  then
	 Control_Flags(0)<='1';
	 if Software_INT_Mask(0) = '1' then 
	  Push_Address_Accumulator(Address_Accumulator);
	 program_Counter <= Interrupts_Vector_Table(0);	
	 Control_Flags(0)<='0';-- Clear the flag
	 end if;
	else
	Control_Flags(0)<='0';
   end if;
end procedure division_by_zero_Interrupt;
----------------------------------------------------------------------------
------------------------------------------------------------
procedure Hardware_IRQ (signal Address_Accumulator : in std_logic_vector(Address_Bus_Size+8 downto 0)) is -- hardware interrupt   --------TODO!!!!!
begin	
	if IRQ = '1'  then
	 Push_Address_Accumulator(Address_Accumulator);
	 program_Counter <= Interrupts_Vector_Table(5);	
   end if;
end procedure Hardware_IRQ;
----------------------------------------------------------------------------
begin

	 
if rising_edge(Clock) then
------------------------RESET----------
if Reset='0' then
    Memory_Enable <= '0';
    Program_Counter<=(others => '0');-- Pc=0  "reset"
	 Call_Stack <= (others=>(others=>'0'));
	 Stack_Pointer <= 0;
	 Control_Flags<= "101000"; 
	 Fetch_Counter<= (others => '0');
 --   Decode_Counter<= (others => '0');
    Store_Counter<= (others => '0');
    Execute_Counter<= (others => '0');
    Fetch_Operand_Counter<= (others => '0');
    HALT_Counter<= (others => '0');
	 Control_State   <= Fetch;
	 Request_Address <= (others => '0');
    Memory_Control <= 'Z'; 
	 ALU_Operation <="000";
	 Data_in_out_ALU <= "0000000000000000";
	 ALU_Enable <= '0';
	 TriALU_Operation <="00000";
	 Data_in_out_TriALU <= "000000000000000000000000";
	 TriALU_Enable <= '0';
	 if Software_INT_Mask(3)= '1' then 
	 program_Counter <= Interrupts_Vector_Table(3);
	 Control_State   <= Fetch;
	 Control_Flags<= "100000";  -- Clear the flag
	 end if;
----------------------------------------
else
Control_Flags(3)<='0';
Control_Flags(4)<=ALU_Carry_Out;
                -- Start counter 10
                case Control_State is----------------------Control finite state machine                   
                    when Fetch => -- Fetch instruction from memory --------------------------------------------------
						     if unsigned(Program_Counter) <= 250 then -- read just memory not IO
                         Request_Address <= Program_Counter;
                         Memory_Control <= '1'; -- Read Memory
								 Memory_Enable <= '1';
								 Data_in_out_Memory <="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; --Apply tri-state on data bus
								                       
								 Memory_Buffer_Register <= Data_in_out_Memory(27 downto 0); -- data or address part  -- last instruct bit 12
                         Instruction_Register <= Data_in_out_Memory(31 downto 28); -- instruction part
								 Memory_Address_Register <= Data_in_out_Memory(27 downto 20); -- used if we want store value in specific memory location or to fetch operand from memory
								 
								 --Clear alu buss
								 ALU_Operation <= "ZZZ"; 
								 Data_in_out_ALU <= "ZZZZZZZZZZZZZZZZ";
								 ALU_Enable <= '0';
								  --Clear trialu buss
								 TriALU_Operation <= "ZZZZZ"; 
								 Data_in_out_TriALU <= "ZZZZZZZZZZZZZZZZZZZZZZZZ";
								 TriALU_Enable <= '0';
								 
                         if Fetch_Counter = 2 then
								 Memory_Enable <= '0';
                         Control_State   <= Decode;								 
								 Fetch_Counter  <= (others => '0');
								 else
								 Fetch_Counter <= Fetch_Counter + 1;
								 end if;
							 end if;
                         
 
                    when Decode => -- Decode instruction ---------------------------------------------------------------	
						  				 
										 if ALU_Operation_Counter = 0 and TriALU_Operation_Counter = 0 then 										  
										  case Instruction_Register is -- increamnt PC based on instruction leangth  
										  when "0000" =>
										       Program_Counter <= Program_Counter+1;
										  when "1001" => 
										       Program_Counter <= Program_Counter+1;
									     when "1100" =>	  
										       if Memory_Buffer_Register(27 downto 24) = "0100" then
										       Program_Counter <= Program_Counter+2; 
												 else 
												 Program_Counter <= Program_Counter+1;
												 end if;	
	                             when "0111" =>
										        case Memory_Buffer_Register(27 downto 25) is 
									                when "000" => -- Add values to register    PC + 4
								                        if Memory_Buffer_Register(24) = '1' then
																Program_Counter <= Program_Counter+4;
																else
																Program_Counter <= Program_Counter+3;
																end if;
											          when "001" => -- Add value to register     PC + 2
								                        Program_Counter <= Program_Counter+2;
										          	 when "010" => -- Greater values            PC + 1
								                        Program_Counter <= Program_Counter+1;
											          when "011" => -- Smaller values
								                        Program_Counter <= Program_Counter+1;
											          when "100" => -- Xor values
								                        if Memory_Buffer_Register(24) = '1' then
																Program_Counter <= Program_Counter+4;
																else
																Program_Counter <= Program_Counter+3;
																end if;
											          when "101" => -- Xor value
								                        Program_Counter <= Program_Counter+2;
											          when "110" => -- Load values
								                        if Memory_Buffer_Register(24) = '1' then
																Program_Counter <= Program_Counter+4;
																else
																Program_Counter <= Program_Counter+3;
																end if;
											          when "111" => -- Load value
								                        Program_Counter <= Program_Counter+2;
											          when others =>
									          end case;
										  when others =>
										  Program_Counter <= Program_Counter+3;
								        end case;
									     end if;
									
						  case Instruction_Register is
						  
						       when "0000" =>     -- NOP instructions   split memory instruction and data in memory data section and code section
								 Control_State <= Fetch;
                         when "0001" =>     -- ADDI operation with absolute values
								 ALU_Enable <= '1';
								 ALU_Operation <="000";
								 Data_in_out_ALU <= Memory_Buffer_Register(27 downto 12);
								 Control_State <= Execute;
								 
								 when "0010" =>     -- SUBI operation with absolute values
								 ALU_Enable <= '1';
								 ALU_Operation <="001";
								 Data_in_out_ALU <= Memory_Buffer_Register(27 downto 12);
								 Control_State <= Execute;
								 
								 when "0011" =>     -- STA Store accumulator value in memory
								 case Memory_Buffer_Register(12) is     
								      when '0' => -- Store from Alu
								      ALU_Enable <= '1';
								      ALU_Operation <= "101";
								      Data_in_out_ALU <= "ZZZZZZZZZZZZZZZZ";
								      when '1' => -- Store from TriAlu
								      TriALU_Enable <= '1';
								      TriALU_Operation <= "00011";
								      Data_in_out_TriALU <= "ZZZZZZZZZZZZZZZZZZZZZZZZ";
										when others =>
								 end case;
								 if ALU_Operation_Counter = 1 then
                         Control_State <= Execute;
								 ALU_Operation_Counter  <= (others => '0');
								 else
							    ALU_Operation_Counter <= ALU_Operation_Counter + 1;
								 end if;							 
								 
								 when "0100" =>     --  MOV load value to specific register 
								 ALU_Enable <= '1';
								 ALU_Operation <="010";
								 Data_in_out_ALU <= Memory_Buffer_Register(27 downto 12);
								 Control_State <= Execute;
								 
								 when "0101" =>     -- LDA load value from address in the memory to specific register 
								 Memory_Address_Register <= Memory_Buffer_Register(27 downto 20);--                       Memory address register
								 Register_Select <= Memory_Buffer_Register(13 downto 12);
								 Control_State <= Fetch_Operand;
								 
								 --ALU inner operation----------------------------------------------------------------------
								 when "0110" =>  
						       ALU_Enable <= '1';		 
								 Data_in_out_ALU(3 downto 0) <= Memory_Buffer_Register(15 downto 12);-- Inner ALU operation modes
								 ALU_Operation <="100";
								 Control_State <= Execute;
								 -------------------------------------------------------------------------------------------
								 
								 when "0111" => -- TRIALU Vector processing SIMD
	                      TriALU_Enable <= '1';
								 TRIALU_Vector_Length <= Memory_Buffer_Register(24);
								 Data_in_out_TriALU <= Memory_Buffer_Register(23 downto 0);
								 Control_State <= Execute;									 
								     case Memory_Buffer_Register(27 downto 25) is 
									      when "000" => -- Add values to register    PC + 4
								         TriALU_Operation <="10000";
											when "001" => -- Add value to register     PC + 2
								         TriALU_Operation <="10001";
											when "010" => -- Greater values            PC + 1
								         TriALU_Operation <="10010";
											when "011" => -- Smaller values
								         TriALU_Operation <="10011";
											when "100" => -- Xor values
								         TriALU_Operation <="11000";
											when "101" => -- Xor value
								         TriALU_Operation <="11001";
											when "110" => -- Load values
								         TriALU_Operation <="11010";
											when "111" => -- Load value
								         TriALU_Operation <="11011";
											when others =>
									  end case;
									  
								 when "1000" => -- TRIALU Parallel processing MIMD
								 TriALU_Enable <= '1';
								 Data_in_out_TriALU(15 downto 0) <= Memory_Buffer_Register(27 downto 12);
								 Data_in_out_TriALU(16) <= Memory_Buffer_Register(11); -- Division over operation  1    x/y+c   , 0 x/y +c
								 Data_in_out_TriALU(17) <= Memory_Buffer_Register(10); -- Logic operations
								 Data_in_out_TriALU(19 downto 18) <= Memory_Buffer_Register(9 downto 8); -- shift a operation
								 Control_State <= Execute;									 
								 if Memory_Buffer_Register(27 downto 24) = "0000" then -- No math operations
								 TriALU_Operation <="00001"; -- load data to registers and set mods
								 else
								 TriALU_Operation <="00000"; -- Math operations
								 end if;
								 
								 when "1001" => -- TRIALU Accumulator structure                          A           A       A            A            B         B          B            B
								 TriALU_Enable <= '1';
							  	 TriALU_Operation <= '0'&Memory_Buffer_Register(27 downto 24); --  from 00100 + , 00101 - , 00110 AND , 00111 OR   , 01100 + , 01101 -  , 01110 AND , 01111 OR 
								 Control_State <= Execute;
								 
								 when "1010" => -- jump with modes       
								 if Memory_Buffer_Register(11 downto 8) = "0001" then
								 ALU_Enable <= '1';
								 ALU_Operation <= "101";
								 Returned_Address_Accumulator <= Program_Counter&Data_in_out_ALU(7 downto 0);
								 elsif Memory_Buffer_Register(11 downto 8) > "1100" then 
								 TriALU_Enable <= '1';
								 TriALU_Operation <= "00010";
								 Data_in_out_TriALU(15 downto 0) <= Memory_Buffer_Register(27 downto 12);
								 if TriALU_Operation_Counter = 1 and  Memory_Buffer_Register(11 downto 8) > "1100" then 
                         Control_State <= Execute;
								 TriALU_Operation_Counter  <= (others => '0');
								 else
								 TriALU_Operation_Counter <= TriALU_Operation_Counter + 1;
								 end if;
								 end if;
								 
								 if Memory_Buffer_Register(11 downto 8) < "1100" then 
								 Control_State <= Execute;
								 end if;
								 
								 when "1011" => -- RTS
								 Pop_Address_Accumulator;
								 Control_State <= Execute;
								 
								 when "1100" => -- TRIALU Stack structure                               Push       Pop     +         -         *         /        And      or
								 TriALU_Enable <= '1';
							  	 TriALU_Operation <= '1'&Memory_Buffer_Register(27 downto 24); --  from 10100  , 10101  , 10110  , 10111    , 11100  , 11101   , 11110  , 11111  
								 Data_in_out_TriALU(7 downto 0) <= Memory_Buffer_Register(23 downto 16);
								 Control_State <= Execute;
								 
								 when "1101" => -- INM   interrupts mask 1 enable interrupt , 0 disable interrupt
								 Software_INT_Mask <= Memory_Buffer_Register(17 downto 12); --Set interrupts mask
								 Control_State <= Execute;
								 
								 when "1110" => -- INTISR
								 
								 when "1111" => -- HLT 							 
								  if(Memory_Buffer_Register(12) = '1') then-- HALT for specific time
								    if(Memory_Buffer_Register(13) = '1') then
									 Total_Halt_Time <= unsigned(Memory_Buffer_Register(27 downto 14))*to_unsigned(board_frequency,50);					
									 else                                                                        -- hint for assmbler coder don't write big number! write between 1 and 10
									 Total_Halt_Time <= shift_right(to_unsigned(board_frequency,64),to_integer(unsigned(Memory_Buffer_Register(27 downto 14))+1));		
									 end if;									 
								  end if;
								 
								 Control_State <= Execute;
								 when others =>
								 
						  end case;	 
						  
						
						  
						  when Fetch_Operand => -- Fetch Operand form memory	----------------------------------------------------
						       Request_Address <= Memory_Address_Register(Address_Bus_Size downto 0);--------------------------------------------------------change it later!!!!!!!!
                         Memory_Control <= '1'; -- Read Memory
								 Memory_Enable <= '1';
								 Data_in_out_Memory <="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; --Apply tri-state on data bus
								 								                       
								 Memory_Buffer_Register(27 downto 20) <= Data_in_out_Memory(31 downto 24); -- Operand value
								 
                         if Fetch_Operand_Counter = 2 then
								 Memory_Enable <= '0';
								 ALU_Enable <= '1';	
                         Control_State   <= Execute;
								 Fetch_Operand_Counter  <= (others => '0');
								 else
								 Fetch_Operand_Counter <= Fetch_Operand_Counter + 1;
								 end if;
						  
                    when Execute => -- Excute instruction ------------------------------------------------------------------
						  
						  	    case Instruction_Register is
						       when "0000" =>     -- Data no instructions

                         when "0001" =>     -- ADDI operation with absolute values
								 ALU_Enable <= '0';	
								 
								 when "0010" =>     -- SUBI operation with absolute values
                         ALU_Enable <= '0';	
								 
								 when "0011" =>     -- STA Store accumulator value in memory
								     case Memory_Buffer_Register(12) is
									       when '0' =>
								          ALU_Enable <= '0';
								          Memory_Buffer_Register(7 downto 0) <= Data_in_out_ALU(7 downto 0);
											 when '1' =>
											 TriALU_Enable <= '0';
								          Memory_Buffer_Register(7 downto 0) <= Data_in_out_TriALU(7 downto 0);
											 when others =>
									  end case;
								 
								 when "0100" =>     -- MOV load value to specific register 
                         ALU_Enable <= '0';	
								 
								 when "0101" =>     -- LDA load value from address to specific register -------------	
								 Data_in_out_ALU(15 downto 8) <= Memory_Buffer_Register(27 downto 20);
								 Data_in_out_ALU(1 downto 0) <= Register_Select;
								 ALU_Operation <= "011";
								 -------------------------------------------------------------------------------------
								 
								  --ALU inner operation------------------------------------
								 when "0110" =>    
								 ALU_Enable <= '0';	
								 ----------------------------------------------------------
								 
								 when "0111" =>    -- TRIALU SIMD
								 TriALU_Enable <= '0';

								 
								 when "1000" =>    --TRIALU MIMD
								 if TriALU_Complete = '1' then
                         TriALU_Enable <= '0';
								 Control_State <= Fetch;
								 end if; 
								 
								 when "1001" =>   -- TRIALU Accumulator structure  
                         TriALU_Enable <= '0';
								 
								 when "1010" =>    --  jump command with modes
								     case Memory_Buffer_Register(11 downto 8)  is -- modes
									  when "0000"  =>-- JMP  unconditional jump to specific address
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  
									  when "0001"  =>-- CALL  unconditional CALL to specific subroutine 
									  Push_Address_Accumulator(Returned_Address_Accumulator);-- this is used when we CALL subroutine ,jump -> CALL Subroutine mode
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  ALU_Enable <= '0';
									  when "0010"  =>-- JMAGB  conditional jump to specific address when register a > register b
									  if(ALU_Flags(4)='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "0011"  =>-- JMASB  conditional jump to specific address when register a < register b
									  if(ALU_Flags(3)='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "0100"  =>-- JMAEB  conditional jump to specific address when register a = register b
									  if(ALU_Flags(4) ='0' and ALU_Flags(3) ='0') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "0101"  =>-- JMAGC  conditional jump to specific address when register a > Accumulator
									  if(ALU_Flags(2)='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "0110"  =>-- JMASC  conditional jump to specific address when register a < Accumulator
									  if(ALU_Flags(1)='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "0111"  =>-- JMAEC  conditional jump to specific address when register a = Accumulator
									  if(ALU_Flags(2) ='0' and ALU_Flags(1) ='0') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "1000"  =>-- JMANB  conditional jump to specific address when register a /= register b
									  if((ALU_Flags(4) XOR ALU_Flags(3)) ='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "1001"  =>-- JMANC  conditional jump to specific address when register a /= Accumulator
									  if((ALU_Flags(2) XOR ALU_Flags(1)) ='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "1010"  =>-- JMZ  conditional jump to specific address when Accumulator = zero
									  if(ALU_Flags(0)='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "1011"  =>-- JMSE  conditional jump to specific address when Stack is empty
									  if(ALU_Flags(5)='1') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  
									  when "1100"  =>-- JIRQ  conditional jump to specific address when IRQ = 1 -------------------------------------------used for Input
									  if(IRQ='0') then
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+20 downto 20);
									  end if;
									  -- TRIALU flags check ----------------------------------------------------------------
									  when "1101"  => 
									  TriALU_Enable <= '0';
									  if(TriALU_Flags(6)='1') then --FeedBack = limit
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+12 downto 12);
									  end if;
									  
									  when "1110"  => -- TRIALU check
									  TriALU_Enable <= '0';
									  if(TriALU_Flags(7)='1') then --FeedBack < limit
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+12 downto 12);
									  end if;
									  
									  when "1111"  => -- TRIALU check
									  TriALU_Enable <= '0';
									  if(TriALU_Flags(8)='1') then --FeedBack > limit
								     Program_Counter <= Memory_Buffer_Register(Address_Bus_Size+12 downto 12);
									  end if;

									  when others =>
						           end case;	
								 
								 
								 when "1011" =>    -- RTS returen to previous address and accumulator value before jumping to subroutines
								 Program_Counter <= Returned_Address_Accumulator(Address_Bus_Size+8 downto 8); -- return address
								 ALU_Enable <= '1';	
								 ALU_Operation <="010";
								 Data_in_out_ALU(15 downto 8) <= Returned_Address_Accumulator(7 downto 0); -- return accumulator value
							  	 Data_in_out_ALU(1 downto 0) <=  "10";
								
								 
								 when "1100" => -- TRIALU Stack structure
								 TriALU_Enable <= '0';
								 
								-- when "1101" =>    -- INM interrupts mask 							 
								 
								-- when "1110" =>    -- INTISR
								 when "1111" =>    -- HLT
								 if(Memory_Buffer_Register(12) = '1') then-- HALT for specific time
								    if(Memory_Buffer_Register(13) = '1') then
									    if(HALT_Counter = Total_Halt_Time) then -- more than one second
									    HALT_Counter <= (others => '0');
										 Control_State <= Fetch;
										 else
										 HALT_Counter<=HALT_Counter+1;
										 end if; 
									 else                                                                        -- don't write big number! write between 1 and 10
									    if Halt_Counter = Total_Halt_Time then -- less than one second
									    HALT_Counter <= (others => '0');
										 Control_State <= Fetch;
										 else
										 HALT_Counter<=HALT_Counter+1;
										 end if;									 
									 end if;
								 else-- HALT forever "it can be interrupt by hardware interrupt!"
								 Control_Flags(2) <= '1';
								 end if;
								 when others =>
								 
						  end case;	
						      --   div by zero         carry                              inner operation                      SUB                                  ADD
						  if ((Alu_Flags(5) = '1' or ALU_Carry_Out = '1') and (Instruction_Register ="0110" or Instruction_Register ="0010"  or Instruction_Register ="0001")) then
						  
						       if Execute_Counter = 0 then
						       ALU_Enable <= '1';
								 ALU_Operation <="111";
			                end if;
								 
								 if Execute_Counter = 1 then
						       Returned_Address_Accumulator <= Program_Counter&Data_in_out_ALU(7 downto 0);	
			                end if;
								 
						       if Execute_Counter = 2 then
								 ALU_Enable <= '0';
								 Carry_Interrupt(Returned_Address_Accumulator);----------------- can't happen at the same time
								 division_by_zero_Interrupt(Returned_Address_Accumulator);------ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
								 Execute_Counter  <= (others => '0');
								 Control_State   <= Fetch;
								 else
								 Execute_Counter <= Execute_Counter + 1;
								 end if;
								 
							elsif (Instruction_Register = "0011") then
							Control_State <= Store;
							elsif (Instruction_Register /= "1111" and Instruction_Register /= "1000")  then -- don't fetch anything if HALT or if there is continues operation inside TriALU
							Control_State <= Fetch;
							end if;
						 
						 
						  when Store => -- Store result in memory or io controller buffer ---------------------------------------------------------------
						  Data_in_out_Memory(7 downto 0) <= Memory_Buffer_Register(7 downto 0);
						  Request_Address <= Memory_Address_Register; 
						  Memory_Control <= '0';
						  Memory_Enable <= '1';
						  
						       if Store_Counter = 2 then                 -- IO need 2 cycles 
								 Memory_Enable <= '0';         -- -----------------------------------------------!!!!!!!!!!!!!!!!!!!!!!!!!!
                         Control_State   <= Fetch;
								 Request_Address <= Program_Counter; 
								 Store_Counter  <= (others => '0');
								 else
								 Store_Counter <= Store_Counter + 1;
								 end if;

                end case;
end if;
end if;
end process;
    
end Behavioral;
