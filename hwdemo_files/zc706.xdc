#------------------------------------------
# TIMING CONSTRAINTS
#------------------------------------------

# Set Reference Clock to 250MHz
create_clock -period 4.0 -name refclk [get_ports refclk_p]

# Set Device Clock to 250MHz by default
create_clock -period 4.0 -name glbclk [get_ports clk_si570_p]

# 200 MHz system clock propogates to 100MHz and 10MHz local clocks
create_clock -period 5.000 -name clk200 [get_ports clk200_p]

# 100 MHz AXI clock
#create_clock -period 10.000 -name clk100 [get_pins clk100_bufg/O]


####### Pinout/Placement constraints for ZC706 #######
# PART : xc7z045tffg900-2
set_property LOC GTXE2_CHANNEL_X0Y11 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt0_jesd204_phy_0_gt_i/gtxe2_i]
set_property LOC GTXE2_CHANNEL_X0Y10 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt1_jesd204_phy_0_gt_i/gtxe2_i]
set_property LOC GTXE2_CHANNEL_X0Y9 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt2_jesd204_phy_0_gt_i/gtxe2_i]
set_property LOC GTXE2_CHANNEL_X0Y8 [get_cells i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt/inst/jesd204_phy_0_gt_i/gt3_jesd204_phy_0_gt_i/gtxe2_i]

# Sys Clk - 200 MHz oscillator
set_property PACKAGE_PIN H9     [get_ports clk200_p]
set_property PACKAGE_PIN G9     [get_ports clk200_n]
set_property IOSTANDARD  LVDS   [get_ports clk200_p]
set_property IOSTANDARD  LVDS   [get_ports clk200_n]

# User Clk - 250 MHz sourced by Si570
set_property PACKAGE_PIN AF14   [get_ports clk_si570_p]
set_property PACKAGE_PIN AG14   [get_ports clk_si570_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_n]

# Output clock to Si5326 Multiplier/Jitter Attenuator
set_property PACKAGE_PIN AD20   [get_ports clk_si5326_p]
set_property PACKAGE_PIN AE20   [get_ports clk_si5326_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_si5326_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_si5326_n]

# GT Reference clock sourced by Si5326 Multiplier/Jitter Attenuator
set_property PACKAGE_PIN AC8 [get_ports refclk_p]
set_property PACKAGE_PIN AC7 [get_ports refclk_n]

# Resets for Si5326 and  PCA9548 I2C switch
set_property PACKAGE_PIN W23     [get_ports si5326_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports si5326_rst_n]

set_property PACKAGE_PIN AD18    [get_ports mon_clk1]
set_property IOSTANDARD LVCMOS25 [get_ports mon_clk1]
set_property PACKAGE_PIN AD19    [get_ports mon_clk2]
set_property IOSTANDARD LVCMOS25 [get_ports mon_clk2]

# GPIO LEDs
set_property PACKAGE_PIN Y21     [get_ports {leds[0]}]
set_property PACKAGE_PIN G2      [get_ports {leds[1]}]
set_property PACKAGE_PIN W21     [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[2]}]

# Reset Pushbutton - Left PB (SW7)
set_property PACKAGE_PIN AK25    [get_ports ext_reset]
set_property IOSTANDARD LVCMOS25 [get_ports ext_reset]

# IIC
set_property PACKAGE_PIN AJ18    [get_ports iic_sda]
set_property PACKAGE_PIN AJ14    [get_ports iic_scl]
set_property IOSTANDARD LVCMOS25 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS25 [get_ports iic_scl]

set_false_path -from [get_pins {vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[*].PROBE_OUT0_INST/Probe_out_reg[*]/C}]
set_false_path -from [get_cells -hier -filter {name =~ vio_reset_p_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ latency_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells {i_axi_controller/busy_cfg_reg*}] 
set_false_path -from [get_cells -filter {name =~refclk_ok_reg* && IS_SEQUENTIAL}] 
set_false_path -from [get_cells {i_axi_controller/rd_data_reg*}] -to [get_cells {vio_control/inst/PROBE_IN_INST/probe_in_reg_reg*}]
set_false_path -from [get_cells -hier -filter {name =~ rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ vio_rx_sync_reg* && IS_SEQUENTIAL}] -to glbclk
set_false_path -from [get_cells -hier -filter {name =~ vio_tx_sync_reg* && IS_SEQUENTIAL}] -to glbclk
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_rx_sync_reg/D]
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_tx_sync_reg/D]

set_false_path -from [get_cells -hier -filter {name =~ i_axi_controller/status_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~ vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ i_axi_controller/rd_data_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~ vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_clocks clk200] -to [get_clocks glbclk]
