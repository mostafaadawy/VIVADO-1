#------------------------------------------
# TIMING CONSTRAINTS
#------------------------------------------

# Set Reference Clock to 153.6MHz
create_clock -period 6.5 -name refclk [get_ports refclk_p]

# Set Device Clock to 153.6MHz by default
create_clock -period 6.5 -name glbclk [get_ports clk_si570_p]

# 200 MHz system clock propogates to 100MHz and 10MHz local clocks
create_clock -period 5.000 -name clk200 [get_ports clk200_p]

# 100 MHz AXI clock
#create_clock -period 10.000 -name clk100 [get_pins clk100_bufg/O]

####### Pinout/Placement constraints for AC701 #######
# PART : ac7a200tfbg676-2

set_property LOC GTPE2_CHANNEL_X0Y3 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt0_jesd204_phy_0_gt_i/gtpe2_i]
set_property LOC GTPE2_CHANNEL_X0Y2 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt1_jesd204_phy_0_gt_i/gtpe2_i]
set_property LOC GTPE2_CHANNEL_X0Y0 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt2_jesd204_phy_0_gt_i/gtpe2_i]
set_property LOC GTPE2_CHANNEL_X0Y1 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt3_jesd204_phy_0_gt_i/gtpe2_i]

# Sys Clk - 200 MHz oscillator
set_property PACKAGE_PIN R3          [get_ports  clk200_p]
set_property PACKAGE_PIN P3          [get_ports  clk200_n]
set_property IOSTANDARD  LVDS_25     [get_ports  clk200_p]
set_property IOSTANDARD  LVDS_25     [get_ports  clk200_n]

# User Clk - 153.6 MHz sourced by Si570
set_property PACKAGE_PIN M21 [get_ports clk_si570_p]
set_property PACKAGE_PIN M22 [get_ports clk_si570_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_n]

# Output clock to Si5326 Multiplier/Jitter Attenuator
set_property PACKAGE_PIN D23 [get_ports clk_si5326_p]
set_property PACKAGE_PIN D24 [get_ports clk_si5326_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_si5326_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_si5326_n]

# GT Reference clock sourced by Si5326 Multiplier/Jitter Attenuator
set_property PACKAGE_PIN AA13       [get_ports  refclk_p]
set_property PACKAGE_PIN AB13       [get_ports  refclk_n]

# Resets for Si5326 and  PCA9548 I2C switch
set_property PACKAGE_PIN B24 [get_ports si5326_rst_n]
set_property PACKAGE_PIN R17 [get_ports iic_mux_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports si5326_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports iic_mux_rst_n]

# Enables FPGA Fan
set_property PACKAGE_PIN J26 [get_ports fan_on]
set_property IOSTANDARD LVCMOS25 [get_ports fan_on]

set_property PACKAGE_PIN H23 [get_ports mon_clk1]
set_property IOSTANDARD LVCMOS25 [get_ports mon_clk1]
set_property PACKAGE_PIN J23 [get_ports mon_clk2]
set_property IOSTANDARD LVCMOS25 [get_ports mon_clk2]

# GPIO LEDs
set_property PACKAGE_PIN M26 [get_ports {leds[0]}]
set_property PACKAGE_PIN T24 [get_ports {leds[1]}]
set_property PACKAGE_PIN T25 [get_ports {leds[2]}]
set_property PACKAGE_PIN R26 [get_ports {leds[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[3]}]

# Reset Pushbutton - North PB (SW3)
set_property PACKAGE_PIN P6 [get_ports ext_reset]
set_property IOSTANDARD LVCMOS15 [get_ports ext_reset]

# IIC
set_property PACKAGE_PIN K25 [get_ports iic_sda]
set_property PACKAGE_PIN N18 [get_ports iic_scl]
set_property IOSTANDARD LVCMOS25 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS25 [get_ports iic_scl]

# U3 Multiplexer LOCs
set_property PACKAGE_PIN B26      [get_ports  clk_sel[0]]
set_property PACKAGE_PIN C24      [get_ports  clk_sel[1]]
# U4 Multiplexer LOCs
#set_property PACKAGE_PIN A24     [get_ports  clk_sel[0]]
#set_property PACKAGE_PIN C26     [get_ports  clk_sel[1]]
set_property IOSTANDARD  LVCMOS25 [get_ports  clk_sel[0]]
set_property IOSTANDARD  LVCMOS25 [get_ports  clk_sel[1]]

set_false_path -from [get_pins {vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[*].PROBE_OUT0_INST/Probe_out_reg[*]/C}]
set_false_path -from [get_cells -hier -filter {name =~ i_axi_controller/busy_cfg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ refclk_ok_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ vio_reset_p_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ latency_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ vio_rx_sync_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ vio_tx_sync_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_rx_sync_reg/D]
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_tx_sync_reg/D]
#set_false_path -from [get_clocks clk100] -to [get_clocks clk200]

create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list rx_jesd204 tx_jesd204]]
resize_pblock [get_pblocks pblock_1] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y0}

create_pblock pblock_rx_ila
add_cells_to_pblock [get_pblocks pblock_rx_ila] [get_cells -quiet [list rx_ila]]
resize_pblock [get_pblocks pblock_rx_ila] -add {CLOCKREGION_X0Y1:CLOCKREGION_X0Y1}
