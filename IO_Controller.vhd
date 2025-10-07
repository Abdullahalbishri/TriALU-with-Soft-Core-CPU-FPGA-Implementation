library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

use IEEE.STD_LOGIC_TEXTIO.ALL;

library STD;
use STD.TEXTIO.ALL;

entity IO_Controller is
 generic (
    Address_Bus_Size : integer  := 7
  );
	port(
		Clock : in std_logic;
		Interrupt_Request : out std_logic:='Z';-- to cpu
		Interrupt_trigger : in std_logic:='Z';-- from user 
		Reset : in std_logic:='Z';
		Read_or_Write	: in std_logic;
		Data_in_out : inout std_logic_vector(27 downto 0):="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		Address_in : in std_logic_vector(Address_Bus_Size downto 0);
		Input_Port : in std_logic_vector(7 downto 0):="ZZZZZZZZ";
      Enable : in std_logic:='Z';		
		Output_Port : out std_logic_vector(7 downto 0):="ZZZZZZZZ"
	);
end entity;


architecture behave of IO_Controller is

signal Input_Buffer : std_logic_vector(7 downto 0):="ZZZZZZZZ";
signal Output_Buffer : std_logic_vector(7 downto 0):="ZZZZZZZZ";    
                               
begin

Input_Buffer <= Input_Port; -- todo
Output_Port  <= Output_Buffer; -- done

Interrupt_Request <= Interrupt_trigger;   -- user -> io controller -> cpu
process(Clock)
begin
   	
	if rising_edge(Clock) then
	if Reset = '0' then
	Output_Buffer <= "00000000";
	Data_in_out <="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	else
	   if unsigned(Address_in) >= 251 and Enable = '1' then -- IO memory mapped start from address 256
		   if Read_or_Write = '0' then--write  output <--- STR
			   Output_Buffer <= Data_in_out(7 downto 0);--                                 !!!
			
		     -- case Data_in_out(15 downto 8) is  -- change it to address
            --  when "00000000" =>  -- output device
             
           --   when others =>  
				 
           --  end case;
		
		  elsif Read_or_Write = '1' then--read   input  ---> LDA 
		  	  Data_in_out(27 downto 20) <= Input_Buffer;
		  else
			  Data_in_out<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		  end if;
	    else
	     Data_in_out<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	 end if;
	 end if;
	end if;
end process;

end behave;








