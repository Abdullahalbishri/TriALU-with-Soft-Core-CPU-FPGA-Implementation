library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity Test is
port(
   Clock : in std_logic
);
end entity;
 
architecture sim of Test is
 
    signal MySignal : integer := 0;
 
begin
 
    process(Clock)
        variable MyVariable : integer := 0;
		  variable MyVariable2 : integer := 0;
    begin
        if rising_edge(Clock) then
        report "*** Process begin ***";
 
        MyVariable := MyVariable + 1;
		  MyVariable2 := MyVariable2 + 1;
        MySignal   <= MyVariable*MyVariable2;
 
        report "MyVariable=" & integer'image(MyVariable) &
            ", MySignal=" & integer'image(MySignal);

       end if;
    end process;
 
end architecture;