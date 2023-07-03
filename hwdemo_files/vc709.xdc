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


####### Pinout/Placement constraints for VC709 #######
# PART : vc7vx690tffg1761-2

set_property PACKAGE_PIN AN2 [get_ports {txp[0]}]
set_property PACKAGE_PIN AN1 [get_ports {txn[0]}]
set_property PACKAGE_PIN AM8 [get_ports {rxp[0]}]
set_property PACKAGE_PIN AM7 [get_ports {rxn[0]}]

set_property PACKAGE_PIN AP4 [get_ports {txp[1]}]
set_property PACKAGE_PIN AP3 [get_ports {txn[1]}]
set_property PACKAGE_PIN AN6 [get_ports {rxp[1]}]
set_property PACKAGE_PIN AN5 [get_ports {rxn[1]}]


set_property PACKAGE_PIN AM4 [get_ports {txp[2]}]
set_property PACKAGE_PIN AM3 [get_ports {txn[2]}]
set_property PACKAGE_PIN AL6 [get_ports {rxp[2]}]
set_property PACKAGE_PIN AL5 [get_ports {rxn[2]}]

set_property PACKAGE_PIN AL2 [get_ports {txp[3]}]
set_property PACKAGE_PIN AL1 [get_ports {txn[3]}]
set_property PACKAGE_PIN AJ6 [get_ports {rxp[3]}]
set_property PACKAGE_PIN AJ5 [get_ports {rxn[3]}]

# Sys Clk - 200 MHz oscillator
set_property PACKAGE_PIN H19     [get_ports clk200_p]
set_property PACKAGE_PIN G18     [get_ports clk200_n]
set_property IOSTANDARD  LVDS     [get_ports clk200_p]
set_property IOSTANDARD  LVDS     [get_ports clk200_n]

# User Clk - 250 MHz sourced by Si570
set_property PACKAGE_PIN AK34 [get_ports clk_si570_p]
set_property PACKAGE_PIN AL34 [get_ports clk_si570_n]
set_property IOSTANDARD LVDS [get_ports clk_si570_p]
set_property IOSTANDARD LVDS [get_ports clk_si570_n]

# Output clock to Si5326 Multiplier/Jitter Attenuator
set_property PACKAGE_PIN AW32 [get_ports clk_si5326_p]
set_property PACKAGE_PIN AW33 [get_ports clk_si5326_n]
set_property IOSTANDARD LVDS  [get_ports clk_si5326_p]
set_property IOSTANDARD LVDS  [get_ports clk_si5326_n]

# GT Reference clock sourced by Si5326 Multiplier/Jitter Attenuator
set_property PACKAGE_PIN AH8 [get_ports refclk_p]
set_property PACKAGE_PIN AH7 [get_ports refclk_n]

# Resets for Si5326 and  PCA9548 I2C switch
set_property PACKAGE_PIN AT36 [get_ports si5326_rst_n]
set_property PACKAGE_PIN AY42 [get_ports iic_mux_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports si5326_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports iic_mux_rst_n]

set_property PACKAGE_PIN AJ32 [get_ports mon_clk1]
set_property IOSTANDARD LVCMOS18 [get_ports mon_clk1]
set_property PACKAGE_PIN AK32 [get_ports mon_clk2]
set_property IOSTANDARD LVCMOS18 [get_ports mon_clk2]

# Enables FPGA Fan
set_property PACKAGE_PIN BA37 [get_ports fan_on]
set_property IOSTANDARD LVCMOS18 [get_ports fan_on]

# GPIO LEDs
set_property PACKAGE_PIN AM39     [get_ports  leds[0]]
set_property PACKAGE_PIN AN39     [get_ports  leds[1]]
set_property PACKAGE_PIN AR37     [get_ports  leds[2]]
set_property PACKAGE_PIN AN41     [get_ports  leds[3]]
set_property PACKAGE_PIN AR35     [get_ports  leds[4]]
set_property PACKAGE_PIN AP41     [get_ports  leds[5]]
set_property PACKAGE_PIN AP42     [get_ports  leds[6]]
set_property PACKAGE_PIN AU39     [get_ports  leds[7]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[0]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[1]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[2]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[3]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[4]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[5]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[6]]
set_property IOSTANDARD  LVCMOS18 [get_ports  leds[7]]

# Reset Pushbutton - North PB (SW2)
set_property PACKAGE_PIN AR40 [get_ports ext_reset]
set_property IOSTANDARD LVCMOS18 [get_ports ext_reset]

# IIC
set_property PACKAGE_PIN AU32 [get_ports iic_sda]
set_property PACKAGE_PIN AT35 [get_ports iic_scl]
set_property IOSTANDARD LVCMOS18 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS18 [get_ports iic_scl]

set_property PACKAGE_PIN Y42      [get_ports  tx_disable[0]]
set_property PACKAGE_PIN AB41     [get_ports  tx_disable[1]]
set_property PACKAGE_PIN AC38     [get_ports  tx_disable[2]]
set_property PACKAGE_PIN AC40     [get_ports  tx_disable[3]]
set_property IOSTANDARD  LVCMOS18 [get_ports  tx_disable[0]]
set_property IOSTANDARD  LVCMOS18 [get_ports  tx_disable[1]]
set_property IOSTANDARD  LVCMOS18 [get_ports  tx_disable[2]]
set_property IOSTANDARD  LVCMOS18 [get_ports  tx_disable[3]]

set_false_path -from [get_pins {vio_control/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[*].PROBE_OUT0_INST/Probe_out_reg[*]/C}]
set_false_path -from [get_cells -hier -filter {name =~ vio_reset_p_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ latency_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells {i_axi_controller/busy_cfg_reg* && IS_SEQUENTIAL}] 
set_false_path -from [get_cells {refclk_ok_reg* && IS_SEQUENTIAL}] 
set_false_path -from [get_cells -hier -filter {name =~ rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ vio_rx_sync_reg* && IS_SEQUENTIAL}] -to glbclk
set_false_path -from [get_cells -hier -filter {name =~ vio_tx_sync_reg* && IS_SEQUENTIAL}] -to glbclk
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_rx_sync_reg/D]
set_false_path -from [get_pins rx_jesd204/inst/i_jesd204_1/rx_32_c/sync_c/syncn_reg/C] -to [get_pins vio_tx_sync_reg/D]

set_false_path -from [get_cells -hier -filter {name =~ i_axi_controller/status_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~ vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ i_axi_controller/rd_data_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~ vio_control/inst/PROBE_IN_INST/probe_in_reg_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ i_iic_controller/done_reg* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {name =~ refclk_ok_count_reg* && IS_SEQUENTIAL}]
set_false_path -from [get_clocks clk200] -to [get_clocks glbclk]
