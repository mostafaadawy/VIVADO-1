#------------------------------------------
# TIMING CONSTRAINTS
#------------------------------------------

# Set Reference Clock to 250.0MHz
create_clock -period 4.00 -name refclk [get_ports refclk_p]

# Set Device Clock to 250.0MHz by default
create_clock -period 4.00 -name glbclk [get_ports clk_si570_p]

# 300 MHz system clock propogates to 100MHz and 10MHz local clocks
create_clock -period 3.333 -name clk300 [get_ports clk300_p]

# 100 MHz AXI clock
#create_clock -period 10.000 -name clk100 [get_pins clk100_bufg/O]

####### Pinout/Placement constraints for KCU105 #######
set_property LOC GTHE3_CHANNEL_X1Y12 [get_cells -hierarchical -filter {NAME =~ i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt_i/inst/gen_gtwizard_gthe3_top.jesd204_phy_0_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[*].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X1Y13 [get_cells -hierarchical -filter {NAME =~ i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt_i/inst/gen_gtwizard_gthe3_top.jesd204_phy_0_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[*].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X1Y14 [get_cells -hierarchical -filter {NAME =~ i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt_i/inst/gen_gtwizard_gthe3_top.jesd204_phy_0_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[*].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X1Y15 [get_cells -hierarchical -filter {NAME =~ i_jesd204_phy/inst/jesd204_phy_block_i/jesd204_phy_0_gt_i/inst/gen_gtwizard_gthe3_top.jesd204_phy_0_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[*].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Sys Clk - 300 MHz oscillator
set_property PACKAGE_PIN AK17 [get_ports clk300_p]
set_property PACKAGE_PIN AK16 [get_ports clk300_n]
set_property IOSTANDARD LVDS [get_ports clk300_p]
set_property IOSTANDARD LVDS [get_ports clk300_n]

# User Clk - 250 MHz sourced by Si570
set_property PACKAGE_PIN M25 [get_ports clk_si570_p]
set_property PACKAGE_PIN M26 [get_ports clk_si570_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_si570_n]

set_property PACKAGE_PIN E12 [get_ports si570_clk_sel]
set_property IOSTANDARD LVCMOS18 [get_ports si570_clk_sel]

# GT Reference clock sourced by Si570
set_property PACKAGE_PIN P6 [get_ports refclk_p]
set_property PACKAGE_PIN P5 [get_ports refclk_n]

# Resets for Si5328 and  PCA9548 I2C switch
set_property PACKAGE_PIN K23 [get_ports si5326_rst_n]
set_property PACKAGE_PIN AP10 [get_ports iic_mux_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports si5326_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports iic_mux_rst_n]

set_property PACKAGE_PIN H27 [get_ports mon_clk1]
set_property IOSTANDARD LVCMOS18 [get_ports mon_clk1]
set_property PACKAGE_PIN G27 [get_ports mon_clk2]
set_property IOSTANDARD LVCMOS18 [get_ports mon_clk2]

# GPIO LEDs
set_property PACKAGE_PIN P25 [get_ports {leds[0]}]
set_property PACKAGE_PIN H23 [get_ports {leds[1]}]
set_property PACKAGE_PIN P20 [get_ports {leds[2]}]
set_property PACKAGE_PIN P21 [get_ports {leds[3]}]
set_property PACKAGE_PIN N22 [get_ports {leds[4]}]
set_property PACKAGE_PIN M22 [get_ports {leds[5]}]
set_property PACKAGE_PIN R23 [get_ports {leds[6]}]
set_property PACKAGE_PIN P23 [get_ports {leds[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {leds[7]}]

# Reset Pushbutton - North PB (SW2)
set_property PACKAGE_PIN AD10 [get_ports ext_reset]
set_property IOSTANDARD LVCMOS18 [get_ports ext_reset]

#FPGA Fan
set_property PACKAGE_PIN AJ9 [get_ports fan_on]
set_property IOSTANDARD LVCMOS18 [get_ports fan_on]

# IIC
set_property PACKAGE_PIN J25 [get_ports iic_sda]
set_property PACKAGE_PIN J24 [get_ports iic_scl]
set_property IOSTANDARD LVCMOS18 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS18 [get_ports iic_scl]

set_false_path -from [get_cells i_axi_controller/busy_cfg_reg*]
set_false_path -from [get_cells refclk_ok_reg*]
set_false_path -from [get_cells -hier -filter {name =~ vio_reset_p_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ latency_reg* && IS_SEQUENTIAL}]
set_false_path -to   [get_cells -hier -filter {name =~ repeat_interval_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_pins {vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[8].PROBE_OUT0_INST/Probe_out_reg[0]/C}] -to [get_pins vio_reset_d1_reg/D]
set_false_path -from [get_pins {vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[13].PROBE_OUT0_INST/Probe_out_reg[0]/C vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[10].PROBE_OUT0_INST/Probe_out_reg[0]/C vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[7].PROBE_OUT0_INST/Probe_out_reg[0]/C vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[11].PROBE_OUT0_INST/Probe_out_reg[0]/C vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[12].PROBE_OUT0_INST/Probe_out_reg[0]/C vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[15].PROBE_OUT0_INST/Probe_out_reg[0]/C vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[14].PROBE_OUT0_INST/Probe_out_reg[0]/C vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[9].PROBE_OUT0_INST/Probe_out_reg[0]/C}] -to [get_pins {sync_ch0_step_up/data_sync_reg0/D sync_ch0_step_down/data_sync_reg0/D sync_vio_resync/data_sync_reg0/D sync_datamode/data_sync_reg0/D sync_rx_error_inject/data_sync_reg0/D sync_sysref_disable/data_sync_reg0/D sync_ch1_step_up/data_sync_reg0/D sync_ch1_step_down/data_sync_reg0/D}]
set_false_path -from [get_cells -hier -filter {name =~ rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ sync_vio_resync/data_sync_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ i_iic_controller/done_reg* && IS_SEQUENTIAL}]
set_false_path -to [get_cells -hier -filter {name =~ latency_i_reg* && IS_SEQUENTIAL}]

set_false_path -from [get_clocks clk100] -to [get_clocks glbclk]