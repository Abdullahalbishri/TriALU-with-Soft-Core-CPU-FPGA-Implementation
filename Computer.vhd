library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity Computer is 
port(
Clock : in std_logic; -- System Clock
Reset : in std_logic:='Z';
Flags : out std_logic_vector(5 downto 0); -- Flags from control unit
Interrupt_trigger : in std_logic;
Input_Port : in std_logic_vector(7 downto 0);		
Output_Port : out std_logic_vector(7 downto 0)
);
end entity;



architecture behave of Computer is
constant Address_Bus_Size : integer := 7;
constant Board_frequency : integer := 5; --5;-- Altera board 50e6    --> 5 for test halt

component CPU is
 generic (
 Address_Bus_Size : integer;
 Board_frequency : integer -- Altera board 50e6
 );
 port(
 CPU_Clock : in std_logic;
 Reset : in std_logic:='Z';
 CPU_Flags : out std_logic_vector(5 downto 0);

 signal Control_Bus : out std_logic;-- control memory and IO Controller

 --buss between CPU and memory and IO Controller
 signal Data_Bus: inout std_logic_vector(31 downto 0);
 signal IRQ : in std_logic;
 signal Memory_Enable : out std_logic;
 signal Address_Bus: out std_logic_vector(Address_Bus_Size downto 0)
 );
end component;

component Memory is
 generic (Address_Bus_Size : integer );
	port(
		Clock : in std_logic;
		Reset: in std_logic:='Z';
		Read_or_Write	: in std_logic;
		Data_in_out : inout std_logic_vector(31 downto 0);
		Enable : in std_logic;
		Address_in : in std_logic_vector(Address_Bus_Size downto 0)
	);
end component;

component IO_Controller is
 generic (Address_Bus_Size : integer );
	port(
		Clock : in std_logic;
		Interrupt_Request : out std_logic:='Z';
		Interrupt_trigger : in std_logic:='Z';
		Reset : in std_logic:='Z';
		Read_or_Write	: in std_logic;
		Data_in_out : inout std_logic_vector(27 downto 0);
		Address_in : in std_logic_vector(Address_Bus_Size downto 0);
		Input_Port : in std_logic_vector(7 downto 0);	
	   Enable : in std_logic:='Z';	
		Output_Port : out std_logic_vector(7 downto 0)
	);
end component;

--buss between CPU and memory and IO_Controller
signal CONTROL_BUS : std_logic;
signal DATA_BUS: std_logic_vector(31 downto 0);
signal IRQ_BUS : std_logic;
signal ADDRESS_BUS: std_logic_vector(Address_Bus_Size downto 0);
signal MEMORY_ENABLE : std_logic;

begin


CPU_INST : CPU
generic map(
Address_Bus_Size => Address_Bus_Size,
Board_frequency => Board_frequency
)
port map(
CPU_Clock =>Clock,
Reset =>Reset,
CPU_Flags =>Flags,
--Memory Handling
Address_Bus => ADDRESS_BUS,-- Memory Address
Data_Bus => DATA_BUS,-- from and to Memory
Control_Bus => CONTROL_BUS,  -- 1 for read 0 for write
IRQ => IRQ_BUS,
Memory_Enable => MEMORY_ENABLE
);

MEM_INST : Memory 
generic map(Address_Bus_Size => Address_Bus_Size)
port map(
Clock => Clock,
Reset => Reset,
Read_or_Write => CONTROL_BUS,
Data_in_out => DATA_BUS,
Enable => MEMORY_ENABLE,
Address_in => ADDRESS_BUS
);

IO_INST : IO_Controller 
 generic map(Address_Bus_Size => Address_Bus_Size)
	port map(
		Clock => Clock,
		Reset =>Reset,
		Interrupt_Request => IRQ_BUS,
		Interrupt_trigger => Interrupt_trigger,
		Read_or_Write	=> CONTROL_BUS,
		Data_in_out  => DATA_BUS(27 downto 0),
		Address_in => ADDRESS_BUS,
		Input_Port => Input_Port,	
	   Enable => MEMORY_ENABLE,	
		Output_Port => Output_Port
	);

end behave;