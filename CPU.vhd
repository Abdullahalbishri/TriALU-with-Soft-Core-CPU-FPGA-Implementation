library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity CPU is 
 generic (
 Address_Bus_Size : integer:= 7;
 Board_frequency : integer:=  5 -- Altera board 50e6
 );
port(
CPU_Clock : in std_logic;
Reset : in std_logic:='0';
CPU_Flags : out std_logic_vector(5 downto 0);

signal Control_Bus : out std_logic;-- control memory and IO Controller

--buss between CPU and memory and IO Controller
signal Data_Bus: inout std_logic_vector(31 downto 0);
signal IRQ : in std_logic;
signal Memory_Enable : out std_logic;
signal Address_Bus: out std_logic_vector(Address_Bus_Size downto 0)
);
end entity;



architecture behave of CPU is

component Control_Unit is
 generic (
 Address_Bus_Size : integer;
 Board_frequency : integer
 );
Port ( 
     Clock: in std_logic;
     Reset: in std_logic;
	  Control_Flags : out std_logic_vector(5 downto 0);
     --Memory Handling
     Request_Address: out std_logic_vector(Address_Bus_Size downto 0);-- Memory Address
     Data_in_out_Memory : inout std_logic_vector(31 downto 0);-- from and to Memory
     Memory_Control : out std_logic;  -- 1 for read 0 for write
	  Memory_Enable : out std_logic;
	  --IO Handling
	  IRQ : in std_logic;
     --ALU Handling 
     ALU_Operation: out std_logic_vector(2 downto 0);-- ALU Operations
     Data_in_out_ALU : inout std_logic_vector(15 downto 0);-- from and to ALU
     ALU_Enable : out std_logic;
	  ALU_Carry_Out : in std_logic;
     ALU_Flags : in std_logic_vector(5 downto 0);
	  --TriALU Handling 
     TriALU_Operation: out std_logic_vector(4 downto 0):="ZZZZZ";-- ALU Operations
     Data_in_out_TriALU : inout std_logic_vector(23 downto 0):="ZZZZZZZZZZZZZZZZZZZZZZZZ";-- from and to ALU
     TRIALU_Vector_Length : out std_logic:='0';
	  TriALU_Enable : out std_logic:='Z';
     TriALU_Carry_Out : in std_logic;
     TriALU_Flags : in std_logic_vector(9 downto 0);
	  TriALU_Complete : in std_logic
);
end component;

component ALU is
port(
   Clock : in std_logic;
   ALU_Operation: in std_logic_vector(2 downto 0);-- ALU Operations
   Data_in_out_ControlUnit : inout std_logic_vector(15 downto 0);-- from and to Control unit
	Carry_Out : out std_logic;
	Flags : out std_logic_vector(5 downto 0); 
	Enable : in std_logic; --from control unit
   Reset: in std_logic:='Z'
);
end component;

component TriALU is
port(
     Clock : in std_logic;
     ALU_Operation: in std_logic_vector(4 downto 0);-- TriALU Operations
     Data_in_out_ControlUnit : inout std_logic_vector(23 downto 0):="ZZZZZZZZZZZZZZZZZZZZZZZZ";-- from and to Control unit
	  Vector_Length : in std_logic:='0';
	  Carry_Out : out std_logic:='0';
	  Flags : out std_logic_vector(9 downto 0):="ZZZZZZZZZZ"; 
	  Enable : in std_logic:='Z';
	  Reset : in std_logic:='Z';
	  Complete : Buffer std_logic
);
end component;

--buss between control uint and alu
signal ALU_OPERATION_BUS : std_logic_vector(2 downto 0);
signal ALU_DATA_BUS: std_logic_vector(15 downto 0);
signal CARRY_OUT_BUS: std_logic;
signal FLAGS_BUS: std_logic_vector(5 downto 0);
signal ENABLE_BUS: std_logic;

--buss between control uint and trialu
signal TriALU_OPERATION_BUS : std_logic_vector(4 downto 0);
signal TriALU_DATA_BUS: std_logic_vector(23 downto 0);
signal TriALU_VECTOR_LENGTH_BUS: std_logic;
signal TriALU_CARRY_OUT_BUS: std_logic;
signal TriALU_FLAGS_BUS: std_logic_vector(9 downto 0);
signal TriALU_ENABLE_BUS: std_logic;
signal TriALU_COMPLETE_BUS: std_logic;

begin

ALU_INST : ALU port map(
   Clock =>CPU_Clock,
   ALU_Operation => ALU_OPERATION_BUS,-- ALU Operations
   Data_in_out_ControlUnit => ALU_DATA_BUS,-- from and to Control unit
	Carry_Out => CARRY_OUT_BUS, -- to control unit
	Flags => FLAGS_BUS, -- to control unit
	Enable => ENABLE_BUS, --from control unit
   Reset => Reset
);

TRIALU_INST : TriALU port map(
   Clock =>CPU_Clock,
   ALU_Operation => TriALU_OPERATION_BUS,-- TriALU Operations
   Data_in_out_ControlUnit => TriALU_DATA_BUS,-- from and to Control unit
	Vector_Length => TRIALU_VECTOR_LENGTH_BUS,
	Carry_Out => TriALU_CARRY_OUT_BUS, -- to control unit
	Flags => TriALU_FLAGS_BUS, -- to control unit
	Enable => TriALU_ENABLE_BUS, --from control unit
   Reset => Reset,
	Complete => TriALU_COMPLETE_BUS
);

CU_INST : Control_Unit
generic map(
Address_Bus_Size => Address_Bus_Size,
Board_frequency => Board_frequency
)
port map(
Clock =>CPU_Clock,
Reset =>Reset,
Control_Flags =>CPU_Flags,
--Memory Handling
Request_Address => Address_Bus,-- Memory Address and io
Data_in_out_Memory => Data_Bus,-- from and to Memory
Memory_Control => control_Bus,  -- 1 for read 0 for write
Memory_Enable => Memory_Enable,
--IO Handling
IRQ => IRQ,
--ALU Handling 
  ALU_Operation =>ALU_OPERATION_BUS,-- ALU Operations
  Data_in_out_ALU => ALU_DATA_BUS,-- from and to ALU
  ALU_Enable => ENABLE_BUS,
  ALU_Carry_Out => CARRY_OUT_BUS, -- from alu
  ALU_Flags => FLAGS_BUS,          -- from alu
--TriALU Handling
   TriALU_Operation => TriALU_OPERATION_BUS,-- TriALU Operations
   Data_in_out_TriALU => TriALU_DATA_BUS,
	TRIALU_vector_Length => TRIALU_VECTOR_LENGTH_BUS,
   TriALU_Enable => TriALU_ENABLE_BUS,
   TriALU_Carry_Out => TriALU_CARRY_OUT_BUS,
   TriALU_Flags => TriALU_FLAGS_BUS,
	TriALU_Complete => TriALU_COMPLETE_BUS
);


end behave;