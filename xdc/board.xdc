
##############################################
##########      Configuration       ##########
##############################################
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CONFIG_MODE SPIx4  [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]

##############################################
##########      Clocks/Reset        ##########
##############################################


#
# 100 MHz system clock
#
set_property -dict {PACKAGE_PIN AJ28 IOSTANDARD LVCMOS18} [get_ports init_clk]
create_clock -period 10.000 [get_ports init_clk]


#
# System Reset
#
#set_property -dict {PACKAGE_PIN AH24 IOSTANDARD LVCMOS18} [get_ports sys_reset_l]


#
# 100 MHz PCIe clock
#
set_property PACKAGE_PIN AE7                   [get_ports pcie_refclk_clk_p]
set_property PACKAGE_PIN AE6                   [get_ports pcie_refclk_clk_n]
create_clock -period 10.000 -name pcie_sys_clk [get_ports pcie_refclk_clk_p]
set_clock_groups -group [get_clocks pcie_sys_clk -include_generated_clocks] -asynchronous


#
# PCIe reset
#
#set_property PACKAGE_PIN AJ31    [get_ports pcie_sys_reset_l]
#set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_reset_l]
#set_property PULLUP true         [get_ports pcie_sys_reset_l]


#
# QSFP_0 clock, 322.265625 Mhz, bottom or left port
#
# Use CMAC X0Y2, transceivers X0Y16 thru X0Y19
#
# MGTREFCLK0 for Quad 128  
set_property PACKAGE_PIN N33 [get_ports qsfp0_clk_clk_p]
set_property PACKAGE_PIN N34 [get_ports qsfp0_clk_clk_n]


#
# QSFP_1 clock, 322.265625 Mhz, top or right port
#
# Use CMAC X0Y0, transceivers X0Y4 thru X0Y7
#
# MGTREFCLK0 for Quad 125  
set_property PACKAGE_PIN AE33 [get_ports qsfp1_clk_clk_p]
set_property PACKAGE_PIN Ae34 [get_ports qsfp1_clk_clk_n]




#create_clock -period 3.103 -name gt_ref_clk  [get_ports gt_ref_clk_p]
#set_clock_groups -group [get_clocks gt_ref_clk -include_generated_clocks] -asynchronous




#set_false_path -to [get_pins -leaf -of_objects [get_cells -hier *cdc_to* -filter {is_sequential}] -filter {NAME=~*cmac_cdc*/*/D}]

##############################################
##########  QSFP Status & Control   ##########
##############################################
#set_property -dict {PACKAGE_PIN AH25  IOSTANDARD LVCMOS18} [ get_ports fpga_i2c_master_l ]

#set_property -dict {PACKAGE_PIN AU24  IOSTANDARD LVCMOS18} [ get_ports qsfp_present_l[0] ]
#set_property -dict {PACKAGE_PIN AW23  IOSTANDARD LVCMOS18} [ get_ports qsfp_present_l[1] ]

set_property -dict {PACKAGE_PIN AW26  IOSTANDARD LVCMOS18} [ get_ports qsfp_rst_l[0] ]
set_property -dict {PACKAGE_PIN AU27  IOSTANDARD LVCMOS18} [ get_ports qsfp_rst_l[1] ]

set_property -dict {PACKAGE_PIN AV26  IOSTANDARD LVCMOS18} [ get_ports qsfp_lp[0] ]
set_property -dict {PACKAGE_PIN AT27  IOSTANDARD LVCMOS18} [ get_ports qsfp_lp[1] ]


#set_property IOSTANDARD LVCMOS18 [get_ports fpga_i2c_master_l]
#set_property PACKAGE_PIN AH25    [get_ports fpga_i2c_master_l]

#set_property IOSTANDARD LVCMOS18 [get_ports qsfp_rst_l_1]
#set_property PACKAGE_PIN AW26    [get_ports qsfp_rst_l_1]

#set_property IOSTANDARD LVCMOS18 [get_ports qsfp_rst_l_2]
#set_property PACKAGE_PIN AU27    [get_ports qsfp_rst_l_2]

#set_property IOSTANDARD LVCMOS18 [get_ports qsfp_lp_1]
#set_property PACKAGE_PIN AV26    [get_ports qsfp_lp_1]

#set_property IOSTANDARD LVCMOS18 [get_ports qsfp_lp_2]
#set_property PACKAGE_PIN AT27    [get_ports qsfp_lp_2]

##############################################
##########           LEDs           ##########
##############################################

set_property -dict {PACKAGE_PIN AR24  IOSTANDARD LVCMOS18} [get_ports {led_green_l[0]}]
set_property -dict {PACKAGE_PIN AT26  IOSTANDARD LVCMOS18} [get_ports {led_green_l[1]}]
set_property -dict {PACKAGE_PIN AR23  IOSTANDARD LVCMOS18} [get_ports {led_green_l[2]}]
set_property -dict {PACKAGE_PIN AR26  IOSTANDARD LVCMOS18} [get_ports {led_green_l[3]}]

set_property -dict {PACKAGE_PIN AP24  IOSTANDARD LVCMOS18} [get_ports {led_orange_l[0]}]
set_property -dict {PACKAGE_PIN AT25  IOSTANDARD LVCMOS18} [get_ports {led_orange_l[1]}]
set_property -dict {PACKAGE_PIN AP23  IOSTANDARD LVCMOS18} [get_ports {led_orange_l[2]}]
set_property -dict {PACKAGE_PIN AR25  IOSTANDARD LVCMOS18} [get_ports {led_orange_l[3]}]





