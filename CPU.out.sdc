## Generated SDC file "CPU.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition"

## DATE    "Wed Jul 27 20:12:04 2022"

##
## DEVICE  "EP2C35F672C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {Clock} -period 35.000 -waveform { 0.000 17.500 } [get_ports {Clock}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Clock}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[0]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[1]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[2]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[3]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[4]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[5]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[6]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Input_Port[7]}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Interrupt_trigger}]
set_input_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Reset}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Flags[0]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Flags[1]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Flags[2]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Flags[3]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Flags[4]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Flags[5]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[0]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[1]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[2]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[3]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[4]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[5]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[6]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {Output_Port[7]}]
set_output_delay -add_delay  -clock [get_clocks {Clock}]  10.000 [get_ports {~LVDS150p/nCEO~}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

