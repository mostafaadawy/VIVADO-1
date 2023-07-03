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


####### Pinout/Placement constraints for KC705 #######
# PART : xc7k325tffg900-2

# Place the GTXE2s - GTXE2 117-0 to 117-3  -> SMAs/SGMII/SFP/FMC LPC DP0 - suitable for PMA loopback mode only
set_property PACKAGE_PIN K5 [get_ports {rxn[0]}]
set_property PACKAGE_PIN K2 [get_ports {txp[0]}]
set_property PACKAGE_PIN K1 [get_ports {txn[0]}]
set_property PACKAGE_PIN K6 [get_ports {rxp[0]}]

set_property PACKAGE_PIN H5 [get_ports {rxn[1]}]
set_property PACKAGE_PIN J4 [get_ports {txp[1]}]
set_property PACKAGE_PIN J3 [get_ports {txn[1]}]
set_property PACKAGE_PIN H6 [get_ports {rxp[1]}]

set_property PACKAGE_PIN G3 [get_ports {rxn[2]}]
set_property PACKAGE_PIN H2 [get_ports {txp[2]}]
set_property PACKAGE_PIN H1 [get_ports {txn[2]}]
set_property PACKAGE_PIN G4 [get_ports {rxp[2]}]

set_property PACKAGE_PIN F5 [get_ports {rxn[3]}]
set_property PACKAGE_PIN F2 [get_ports {txp[3]}]
set_property PACKAGE_PIN F1 [get_ports {txn[3]}]
set_property PACKAGE_PIN F6 [get_ports {rxp[3]}]

# Sys Clk - 200 MHz oscillator
set_property PACKAGE_PIN AD12     [get_ports clk200_p]
set_property PACKAGE_PIN AD11     [get_ports clk200_n]
set_property IOSTANDARD  LVDS     [get_ports clk200_p]
set_property IOSTANDARD  LVDS     [get_ports clk200_n]

# User Clk - 250 MHz sourced by Si570
set_property PACKAGE_PIN K28 [get_ports clk_si570_p]
set_property PACKAGE_PIN K29 [get_ports clk_si570_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_n]

# Output clock to Si5326 Multiplier/Jitter Attenuator
set_property LOC OLOGIC_X0Y96 [get_cells oddr0]
set_property PACKAGE_PIN W27 [get_ports clk_si5326_p]
set_property PACKAGE_PIN W28 [get_ports clk_si5326_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_si5326_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_si5326_n]

# GT Reference clock sourced by Si5326 Multiplier/Jitter Attenuator
set_property PACKAGE_PIN L8 [get_ports refclk_p]
set_property PACKAGE_PIN L7 [get_ports refclk_n]

# Resets for Si5326 and  PCA9548 I2C switch
set_property PACKAGE_PIN AE20 [get_ports si5326_rst_n]
set_property PACKAGE_PIN P23 [get_ports iic_mux_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports si5326_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports iic_mux_rst_n]

set_property PACKAGE_PIN Y23 [get_ports mon_clk1]
set_property IOSTANDARD LVCMOS25 [get_ports mon_clk1]
set_property PACKAGE_PIN Y24 [get_ports mon_clk2]
set_property IOSTANDARD LVCMOS25 [get_ports mon_clk2]

# Enables FPGA Fan
set_property PACKAGE_PIN L26 [get_ports fan_on]
set_property IOSTANDARD LVCMOS25 [get_ports fan_on]

# GPIO LEDs
set_property PACKAGE_PIN AB8 [get_ports {leds[0]}]
set_property PACKAGE_PIN AA8 [get_ports {leds[1]}]
set_property PACKAGE_PIN AC9 [get_ports {leds[2]}]
set_property PACKAGE_PIN AB9 [get_ports {leds[3]}]
set_property PACKAGE_PIN AE26 [get_ports {leds[4]}]
set_property PACKAGE_PIN G19 [get_ports {leds[5]}]
set_property PACKAGE_PIN E18 [get_ports {leds[6]}]
set_property PACKAGE_PIN F16 [get_ports {leds[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds[7]}]

# Reset Pushbutton - North PB (SW2)
set_property PACKAGE_PIN AA12 [get_ports ext_reset]
set_property IOSTANDARD LVCMOS18 [get_ports ext_reset]

# IIC
set_property PACKAGE_PIN L21 [get_ports iic_sda]
set_property PACKAGE_PIN K21 [get_ports iic_scl]
set_property IOSTANDARD LVCMOS25 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS25 [get_ports iic_scl]

set_false_path -from [get_pins {vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[*].PROBE_OUT0_INST/Probe_out_reg[*]/C}]
set_false_path -from [get_cells -hier -filter {name =~ vio_reset_p_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ latency_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells {i_axi_controller/busy_cfg_reg*}]
set_false_path -from [get_cells {refclk_ok_reg*}]
set_false_path -from [get_cells -hier -filter {name =~ rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ vio_rx_sync_reg* && IS_SEQUENTIAL}] -to glbclk
set_false_path -from [get_cells -hier -filter {name =~ vio_tx_sync_reg* && IS_SEQUENTIAL}] -to glbclk
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_rx_sync_reg/D]
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_tx_sync_reg/D]
set_false_path -from [get_cells -hier -filter {name =~ i_iic_controller/done_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~refclk_ok_count_reg* && IS_SEQUENTIAL}]

set_false_path -from [get_cells -hier -filter {name =~ i_axi_controller/status_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~ vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ i_axi_controller/rd_data_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~ vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_clocks clk200] -to [get_clocks glbclk]
