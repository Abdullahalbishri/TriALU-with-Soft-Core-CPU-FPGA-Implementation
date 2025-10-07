library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

use IEEE.STD_LOGIC_TEXTIO.ALL;

library STD;
use STD.TEXTIO.ALL;

entity Memory is
 generic (
    Address_Bus_Size : integer  := 7
  );
	port(
		Clock : in std_logic;
		Reset: in std_logic:='Z';
		Read_or_Write	: in std_logic;
		Data_in_out : inout std_logic_vector(31 downto 0):="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; -- 32 bit data bus
		Enable : in std_logic:='Z';
		Address_in : in std_logic_vector(Address_Bus_Size downto 0)
	);
end entity;


architecture behave of Memory is

type Memory_Architecture is array(0 to 256) of std_logic_vector(7 downto 0); -- 250 Address one byte word

-- divistion by zero interrupt with subroutine
                                          -- ADD     --STR    --SUB                                       -- here
--signal Memory_Data:Memory_Architecture :=(x"11011",x"30700",x"20101",x"0E5E1",x"41411",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00001");
                                              --MOV   HLT        ADR
--signal Memory_Data:Memory_Architecture :=(x"40100",x"f0007",x"60000",x"30700",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00001");
                                            --LDA
--signal Memory_Data:Memory_Architecture :=(x"50401",x"00000",x"00000",x"00000",x"00100",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00001");
--interrupts test section---------------------------------------------------------------------------------------
--divistion by zero interrupt with subroutine INM       MOV      MOV     DIV      STA                                                                     INM      RTS
--signal Memory_Data:Memory_Architecture :=(x"D0001",x"40800",x"40001",x"60003",x"30700",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"D0000",x"B0000",x"00000",x"00000");
--Carry interrupt with subroutine            INM       MOV      MOV     ADD     STA                                    INM      RTS
--signal Memory_Data:Memory_Architecture :=(x"D0010",x"4ff00",x"4ff01",x"60000",x"30700",x"00000",x"00000",x"00000",x"D0000",x"B0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");
--Carry interrupt with subroutine and div by zero  
--                                               INM       MOV      MOV     ADD     STA                           MOV      MOV     DIV     RET               INM      RET
  --signal Memory_Data:Memory_Architecture :=(x"D0011",x"4ff00",x"4ff01",x"60000",x"30700",x"00000",x"00000",x"40800",x"40001",x"60003",x"B0000",x"00000",x"D0000",x"B0000",x"00000",x"00000");
----------------------------------------------------------------------------------------------------------------                                         
														  --JMP to location 7                                                                                --RET
--signal Memory_Data:Memory_Architecture :=(x"A0700",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"40800",x"40201",x"90000",x"30700",x"B0000",x"00000",x"00000",x"00000",x"00000");
                                           -- Mov,    Mov,  inneraluop, JMASB 7,                           stor 
--signal Memory_Data:Memory_Architecture :=(x"40800",x"40201",x"6000A",x"A0703",x"00000",x"00000",x"00000",x"30700",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00001");
-- loop program
--signal Memory_Data:Memory_Architecture :=(x"40300",x"50701",x"6000C",x"30700",x"A0105",x"00000",x"00000",x"00100",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");
                                                    -- Mov,    Mov,       ADR                                    stor ->output   HLT
--signal Memory_Data:Memory_Architecture :=(x"00000",x"40100",x"40101",x"60000",x"00000",x"00000",x"00000",x"00000",x"30f00",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  
--                                          LDA        jirq    mov      add                             stor ->output  HLT
--signal Memory_Data:Memory_Architecture :=(x"50f00",x"a000c",x"40101",x"60000",x"00000",x"00000",x"00000",x"30f00",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  -- in hardware input test 
--                                          JIRQ      JMP     LDA -> input
--signal Memory_Data:Memory_Architecture :=(x"A020c",x"A0000",x"50f00",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");
--signal Memory_Data:Memory_Architecture :=(x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");
--signal Memory_Data:Memory_Architecture :=(x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"30f00",x"00000",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");

--                                           LDA             ADD a+1      1      store                     output    HLT     JMP
--signal Memory_Data:Memory_Architecture :=(x"50300",x"00000",x"60008",x"00000",x"30300",x"00000",x"00000",x"30f00",x"f0007",x"A0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000"); -- Counter on board

--signal Memory_Data:Memory_Architecture :=(x"80401",x"80501",x"80609",x"81605",x"A023F",x"31c01",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  -- Fibonacci on board using TriAlu  with mods Switcher

--signal Memory_Data:Memory_Architecture :=(x"80001",x"80101",x"80209",x"81615",x"A027D",x"81625",x"A023F",x"31c01",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  -- Fibonacci on board using TriAlu without mods 7 instructions , 10000 ps , 100 cycles
                                                                           --cmp  f =2                                 f >2
--signal Memory_Data:Memory_Architecture :=(x"80401",x"80501",x"80609",x"81615",x"A029D",x"81625",x"30f01",x"f0007",x"A023F",x"30f01",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  -- Fibonacci on board using TriAlu  7 instructions
                                                                                                                                                       --error 
--signal Memory_Data:Memory_Architecture :=(x"50100",x"00100",x"50301",x"00100",x"60000",x"30100",x"50700",x"00200",x"50901",x"00900",x"6000d",x"30900",x"a1907",x"50100",x"50301",x"60000",x"30300",x"50700",x"50901",x"6000d",x"30900",x"a0006",x"50302",x"31C00",x"f0000",x"50102",x"31C00",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");    -- Fibonacci on board using Alu     18 instructions , 53600 ps , 536 cycles
--                                          load 9     9-1    load 0  load 1
--signal Memory_Data:Memory_Architecture :=(x"80209",x"88001",x"80400",x"80D01",x"81605",x"31c01",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  -- Fibonacci on board using TriAlu  with mods continues Switcher 

--signal Memory_Data:Memory_Architecture :=(x"80205",x"80801",x"88A15",x"31c01",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"f0000");  -- Factorial of 5

--signal Memory_Data:Memory_Architecture :=(x"80205",x"80801",x"80902",x"82615",x"31c01",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"f0000");  --  Power of number 2^5
--                                           load 1    A+ACC
--signal Memory_Data:Memory_Architecture :=(x"80001",x"94000",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  -- TriAlu Accummulator structer Accumulator =  A + Accumulator 
--                                           push     push     push    add       add
--signal Memory_Data:Memory_Architecture :=(x"C4010",x"C4020",x"C4030",x"C6000",x"C6000",x"f0000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000",x"00000");  -- TriAlu Stack structure 

signal Memory_Data:Memory_Architecture :=(others=>(others=>'0'));

begin

process(Clock)
begin
if rising_edge(Clock) then
if Reset='0' then
-- TRIALU Stack 
--Memory_Data(0) <= x"C4"; -- Push 1
--Memory_Data(1) <= x"01";	
--Memory_Data(2) <= x"C4"; -- Push 2
--Memory_Data(3) <= x"02";
--Memory_Data(4) <= x"C4"; -- Push 3
--Memory_Data(5) <= x"03";
--Memory_Data(6) <= x"C6"; -- Add
--Memory_Data(7) <= x"C6"; -- Add
--Memory_Data(8) <= x"f0"; -- HLT
--Memory_Data(9) <= x"00";
-------------------------------------

-- TRIALU Fibonacci on board using TriAlu  with mods Switcher
--Memory_Data(0) <= x"80"; -- load 
--Memory_Data(1) <= x"40";
--Memory_Data(2) <= x"10";
--Memory_Data(3) <= x"80"; -- load
--Memory_Data(4) <= x"50";
--Memory_Data(5) <= x"10";
--Memory_Data(6) <= x"80"; -- load
--Memory_Data(7) <= x"60";
--Memory_Data(8) <= x"90";
--Memory_Data(9) <= x"81"; -- Add a+b  --feedback
--Memory_Data(10) <= x"60";
--Memory_Data(11) <= x"50";
--Memory_Data(12) <= x"A0"; -- compare 
--Memory_Data(13) <= x"20";
--Memory_Data(14) <= x"9f";
--Memory_Data(15) <= x"3f"; -- store
--Memory_Data(16) <= x"e0";
--Memory_Data(17) <= x"10";
--Memory_Data(18) <= x"f0"; -- hlt
--Memory_Data(19) <= x"00";
--Memory_Data(20) <= x"00";
----------------------------------

-- TRIALU Fibonacci on board using TriAlu  with mods Switcher and stack push
--Memory_Data(0) <= x"C4"; -- Push 0
--Memory_Data(1) <= x"00";	
--Memory_Data(2) <= x"C4"; -- Push 1
--Memory_Data(3) <= x"01";
--Memory_Data(4) <= x"80"; -- load
--Memory_Data(5) <= x"60";
--Memory_Data(6) <= x"90";
--Memory_Data(7) <= x"81"; -- Add a+b  --feedback
--Memory_Data(8) <= x"60";
--Memory_Data(9) <= x"50";
--Memory_Data(10) <= x"A0"; -- compare 
--Memory_Data(11) <= x"10";
--Memory_Data(12) <= x"7f";
--Memory_Data(13) <= x"3f"; -- store output
--Memory_Data(14) <= x"e0";
--Memory_Data(15) <= x"10";
--Memory_Data(16) <= x"f0"; -- hlt
--Memory_Data(17) <= x"00";
--Memory_Data(18) <= x"00";
----------------------------------

--Conter x"50300",x"00000",x"60008",x"00000",x"30300",x"00000",x"00000",x"30f00",x"f0007",x"A0000"
Memory_Data(0) <= x"51"; -- load from location 19
Memory_Data(1) <= x"30";
Memory_Data(2) <= x"00";
Memory_Data(3) <= x"00"; -- 00 gap
Memory_Data(4) <= x"60"; -- A++
Memory_Data(5) <= x"00";
Memory_Data(6) <= x"80"; 
Memory_Data(7) <= x"31"; -- store in location 19
Memory_Data(8) <= x"30";
Memory_Data(9) <= x"00"; 
Memory_Data(10) <= x"3f"; -- output
Memory_Data(11) <= x"e0";
Memory_Data(12) <= x"00"; 
Memory_Data(13) <= x"f0"; -- sleep
Memory_Data(14) <= x"00";
Memory_Data(15) <= x"70"; 
Memory_Data(16) <= x"a0"; -- jump
Memory_Data(17) <= x"00";
Memory_Data(18) <= x"00"; 
Memory_Data(19) <= x"01"; 
------------------------------------------

--Memory_Data(0) <= x"71"; -- vector load
--Memory_Data(1) <= x"01"; -- 1	
--Memory_Data(2) <= x"02"; -- 2
--Memory_Data(3) <= x"03"; -- 3
--Memory_Data(4) <= x"74"; -- find the greatar value
--Memory_Data(5) <= x"f0"; -- hlt
--Memory_Data(6) <= x"00";
--Memory_Data(7) <= x"00";

----------------------------------------------
--Memory_Data(0) <= x"71"; -- vector load
--Memory_Data(1) <= x"01"; -- 1	
--Memory_Data(2) <= x"01"; -- 1
--Memory_Data(3) <= x"06"; -- 6
--Memory_Data(4) <= x"8D"; -- divition over operation    D= 1101 op2 11 /  op1 01 +
--Memory_Data(5) <= x"E0"; 
--Memory_Data(6) <= x"48";
--Memory_Data(7) <= x"F0";-- hlt
---------------------------------------------

------------------------------------------------
-- Hamming weight
--Memory_Data(0) <= x"C4"; -- Push 7
--Memory_Data(1) <= x"07";	
--Memory_Data(2) <= x"C4"; -- Push 1
--Memory_Data(3) <= x"01";
--Memory_Data(4) <= x"80"; -- load continus mode and 8
--Memory_Data(5) <= x"A0";
--Memory_Data(6) <= x"80";
--Memory_Data(7) <= x"84"; -- hamming weight
--Memory_Data(8) <= x"80"; 
--Memory_Data(9) <= x"55";
--Memory_Data(10) <= x"F0"; -- hlt
---------------------------------------------------
 Data_in_out <="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

 elsif unsigned(Address_in) <= 250 and Enable = '1' then -- enable -> memory mapped >= 256 IO

		if Read_or_Write = '0' then -- write
			Memory_Data(to_integer(unsigned(Address_in)))<=Data_in_out(7 downto 0);	
			
		elsif Read_or_Write = '1' then -- read 
			Data_in_out <= Memory_Data(to_integer(unsigned(Address_in)))&Memory_Data(to_integer(unsigned(Address_in)+1))&Memory_Data(to_integer(unsigned(Address_in)+2))&Memory_Data(to_integer(unsigned(Address_in)+3)); 
		else
			Data_in_out<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		end if;
	 else
	 Data_in_out<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
 end if;
end if;
end process;

end behave;








