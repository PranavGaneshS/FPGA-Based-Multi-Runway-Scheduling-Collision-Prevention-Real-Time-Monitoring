##==============================================================================
## Basys 3 Master XDC Constraints File for Airport Scheduler with 3 OLEDs
## Board: Digilent Basys 3 (XC7A35T-1CPG236C)
##==============================================================================

## Clock signal (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Pushbuttons
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

set_property PACKAGE_PIN T18 [get_ports btnU]
set_property IOSTANDARD LVCMOS33 [get_ports btnU]

## Switches
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2  [get_ports {sw[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN T3  [get_ports {sw[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN T2  [get_ports {sw[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN R3  [get_ports {sw[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN W2  [get_ports {sw[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN U1  [get_ports {sw[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN T1  [get_ports {sw[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN R2  [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

##==============================================================================
## Pmod Header JA - Runway 1 OLED
## Pins: [0]:CS#, [1]:SDIN, [2]:NC, [3]:SCLK, [4]:D/C#, [5]:RES#, [6]:VBAT#, [7]:VDD#
##==============================================================================
set_property PACKAGE_PIN J1 [get_ports {ja[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[0]}]
set_property SLEW SLOW [get_ports {ja[0]}]
set_property DRIVE 4   [get_ports {ja[0]}]

set_property PACKAGE_PIN L2 [get_ports {ja[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[1]}]
set_property SLEW SLOW [get_ports {ja[1]}]
set_property DRIVE 4   [get_ports {ja[1]}]

set_property PACKAGE_PIN J2 [get_ports {ja[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[2]}]

set_property PACKAGE_PIN G2 [get_ports {ja[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[3]}]
set_property SLEW SLOW [get_ports {ja[3]}]
set_property DRIVE 4   [get_ports {ja[3]}]

set_property PACKAGE_PIN H1 [get_ports {ja[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[4]}]
set_property SLEW SLOW [get_ports {ja[4]}]
set_property DRIVE 4   [get_ports {ja[4]}]

set_property PACKAGE_PIN K2 [get_ports {ja[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[5]}]
set_property SLEW SLOW [get_ports {ja[5]}]
set_property DRIVE 4   [get_ports {ja[5]}]

set_property PACKAGE_PIN H2 [get_ports {ja[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[6]}]
set_property SLEW SLOW [get_ports {ja[6]}]
set_property DRIVE 4   [get_ports {ja[6]}]

set_property PACKAGE_PIN G3 [get_ports {ja[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[7]}]
set_property SLEW SLOW [get_ports {ja[7]}]
set_property DRIVE 4   [get_ports {ja[7]}]

##==============================================================================
## Pmod Header JB - Runway 2 OLED
## Pins: [0]:CS#, [1]:SDIN, [2]:NC, [3]:SCLK, [4]:D/C#, [5]:RES#, [6]:VBAT#, [7]:VDD#
##==============================================================================
set_property PACKAGE_PIN A14 [get_ports {jb[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[0]}]
set_property SLEW SLOW [get_ports {jb[0]}]
set_property DRIVE 4   [get_ports {jb[0]}]

set_property PACKAGE_PIN A16 [get_ports {jb[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[1]}]
set_property SLEW SLOW [get_ports {jb[1]}]
set_property DRIVE 4   [get_ports {jb[1]}]

set_property PACKAGE_PIN B15 [get_ports {jb[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[2]}]

set_property PACKAGE_PIN B16 [get_ports {jb[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[3]}]
set_property SLEW SLOW [get_ports {jb[3]}]
set_property DRIVE 4   [get_ports {jb[3]}]

set_property PACKAGE_PIN A15 [get_ports {jb[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[4]}]
set_property SLEW SLOW [get_ports {jb[4]}]
set_property DRIVE 4   [get_ports {jb[4]}]

set_property PACKAGE_PIN A17 [get_ports {jb[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[5]}]
set_property SLEW SLOW [get_ports {jb[5]}]
set_property DRIVE 4   [get_ports {jb[5]}]

set_property PACKAGE_PIN C15 [get_ports {jb[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[6]}]
set_property SLEW SLOW [get_ports {jb[6]}]
set_property DRIVE 4   [get_ports {jb[6]}]

set_property PACKAGE_PIN C16 [get_ports {jb[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[7]}]
set_property SLEW SLOW [get_ports {jb[7]}]
set_property DRIVE 4   [get_ports {jb[7]}]

##==============================================================================
## Pmod Header JC - Runway 3 OLED
## Pins: [0]:CS#, [1]:SDIN, [2]:NC, [3]:SCLK, [4]:D/C#, [5]:RES#, [6]:VBAT#, [7]:VDD#
##==============================================================================
set_property PACKAGE_PIN K17 [get_ports {jc[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[0]}]
set_property SLEW SLOW [get_ports {jc[0]}]
set_property DRIVE 4   [get_ports {jc[0]}]

set_property PACKAGE_PIN M18 [get_ports {jc[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[1]}]
set_property SLEW SLOW [get_ports {jc[1]}]
set_property DRIVE 4   [get_ports {jc[1]}]

set_property PACKAGE_PIN N17 [get_ports {jc[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[2]}]

set_property PACKAGE_PIN P18 [get_ports {jc[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[3]}]
set_property SLEW SLOW [get_ports {jc[3]}]
set_property DRIVE 4   [get_ports {jc[3]}]

set_property PACKAGE_PIN L17 [get_ports {jc[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[4]}]
set_property SLEW SLOW [get_ports {jc[4]}]
set_property DRIVE 4   [get_ports {jc[4]}]

set_property PACKAGE_PIN M19 [get_ports {jc[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[5]}]
set_property SLEW SLOW [get_ports {jc[5]}]
set_property DRIVE 4   [get_ports {jc[5]}]

set_property PACKAGE_PIN P17 [get_ports {jc[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[6]}]
set_property SLEW SLOW [get_ports {jc[6]}]
set_property DRIVE 4   [get_ports {jc[6]}]

set_property PACKAGE_PIN R18 [get_ports {jc[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jc[7]}]
set_property SLEW SLOW [get_ports {jc[7]}]
set_property DRIVE 4   [get_ports {jc[7]}]

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
