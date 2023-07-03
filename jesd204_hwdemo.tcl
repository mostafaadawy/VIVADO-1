# ---------------------------------------------------------------------------------
# ------       TCL script for generating JESD204 Hardware Demos      --------------
# ------                    Vivado 2015.1                            --------------
# ------                    May 2015                            --------------
# ---------------------------------------------------------------------------------
source search.tcl
set valid 0

#Check if tcl script is being run within Vivado
if {[info commands version] ne "version"} {
  puts "Please run JESD204 Hardware Demo within Vivado 2016.1."
  exit
}

#Check that the correct version of Vivado is being used
set vivado_ver [version -short]
puts "Current version of Vivado: $vivado_ver"
if {[string compare $vivado_ver "[2016.1]"] == 0} {
  puts "Current version of JESD204 Hardware Demo requires Vivado 2015.3 to run. Please use correct version of Vivado!"
  exit
}

# Stay in while loop until a valid option is given by the user
while {$valid == 0} {
  puts "1. Kintex-7 KC705"
  puts "2. Virtex-7 VC709"
  puts "3. Zynq ZC706"
  puts "4. Artix AC701"
#  puts "5. Ultrascale KCU105"
  puts -nonewline "Please select number of hardware demo to be generated: "
  flush stdout
  set hw_demo [gets stdin]

  # Switch case will ensure the project has selected the correct board
  switch $hw_demo {
    # Setup the KC705 Hardware Demo
    1 {
      puts "Selected Demo $hw_demo"
      set PROJ_NAME kc705_hwdemo
      create_project -force $PROJ_NAME ./$PROJ_NAME -part xc7k325tffg900-2
      set_property board xilinx.com:kintex7:kc705:1.1 [current_project]
      findReplace xc7k325t_0 xc7k325t_0 kc705_hwdemo kc705_hwdemo kc705_hwdemo.runs/impl_1/jesd204_kc705.bit kc705_hwdemo.runs/impl_1/jesd204_kc705.bit
      set valid 1
    }
    # Setup the VC709 Hardware Demo
    2 {
      puts "Selected Demo $hw_demo"
      set PROJ_NAME vc709_hwdemo
      create_project -force $PROJ_NAME ./$PROJ_NAME
      set_property board xilinx.com:virtex7:vc709:1.0 [current_project]
      findReplace xc7k325t_0 xc7vx690t_0 kc705_hwdemo vc709_hwdemo kc705_hwdemo.runs/impl_1/jesd204_kc705.bit vc709_hwdemo.runs/impl_1/jesd204_vc709.bit 
      set valid 1
    }
    # Setup the ZC706 Hardware Demo
    3 {
      puts "Selected Demo $hw_demo"
      set PROJ_NAME zc706_hwdemo
      create_project -force $PROJ_NAME ./$PROJ_NAME -part xc7z045ffg900-2
      set_property board xilinx.com:zynq:zc706:1.1 [current_project]
      findReplace xc7k325t_0 xc7z045t_0 kc705_hwdemo zc706_hwdemo kc705_hwdemo.runs/impl_1/jesd204_kc705.bit zc706_hwdemo.runs/impl_1/jesd204_zc706.bit 
      set valid 1
    }
     # Setup the AC701 Hardware Demo
    4 {
      puts "Selected Demo $hw_demo."
      set PROJ_NAME ac701_hwdemo
      create_project -force $PROJ_NAME ./$PROJ_NAME
      set_property board xilinx.com:artix7:ac701:1.0 [current_project]
      findReplace xc7k325t_0 xc7a200t_0 kc705_hwdemo ac701_hwdemo kc705_hwdemo.runs/impl_1/jesd204_kc705.bit ac701_hwdemo.runs/impl_1/jesd204_ac701.bit     
      set valid 1
    }
    # Setup the KCU105 Hardware Demo. NOT SUPPORTED IN 2014.3
    5 {
      puts "Selected Demo $hw_demo."
      set PROJ_NAME kcu105_hwdemo
      create_project -force $PROJ_NAME ./$PROJ_NAME 
      set_property board_part xilinx.com:kcu105:1.0 [current_project]
  #    findReplace xc7k325t_0 xcku060_0 kc705_hwdemo kcu105_hwdemo kc705_hwdemo.runs/impl_1/jesd204_kc705.bit kcu105_hwdemo.runs/impl_1/jesd204_kcu105.bit
      set valid 0
    }

    default {
      puts "Invalid selection please select again!"
      set valid 0
    }
  }
}
# -------- Generating the cores is common for all projects except Ultrascale --------------
if {$hw_demo == 5} {
  #Generate Tx JESD204 Core
  create_ip -name jesd204 -vendor xilinx.com -library ip -module_name jesd204_0
  set_property -dict [list CONFIG.C_LANES {4} CONFIG.GT_Line_Rate {10.0} CONFIG.GT_REFCLK_FREQ {250} CONFIG.C_PLL_SELECTION {1} CONFIG.DRPCLK_FREQ {100.0}] [get_ips jesd204_0]
  generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_0/jesd204_0.xci]
  create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_0/jesd204_0.xci]
  reset_run jesd204_0_synth_1
  launch_run  jesd204_0_synth_1
  wait_on_run jesd204_0_synth_1

  # Open Example Design
  open_example_project -force -dir ./$PROJ_NAME [get_ips  jesd204_0]

  # Generate Rx JESD204 Core
  create_ip -name jesd204 -vendor xilinx.com -library ip -module_name jesd204_1
  set_property -dict [list CONFIG.C_NODE_IS_TRANSMIT {0} CONFIG.C_LANES {4} CONFIG.GT_Line_Rate {10.0} CONFIG.GT_REFCLK_FREQ {250} CONFIG.C_PLL_SELECTION {1} CONFIG.DRPCLK_FREQ {100.0}] [get_ips jesd204_1]
  generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_1/jesd204_1.xci]
  create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_1/jesd204_1.xci]
  reset_run jesd204_1_synth_1
  launch_run  jesd204_1_synth_1
  wait_on_run jesd204_1_synth_1

  #Import files for Hardware Demo
  import_files -fileset constrs_1 ./hwdemo_files/kcu105.xdc
  import_files -norecurse {./hwdemo_files/kcu105_iic_controller.vhd ./hwdemo_files/jesd204_kcu105.v ./hwdemo_files/sync_block.v}

  #Import files from Example Design
  import_files $PROJ_NAME/jesd204_0_example/jesd204_0_example.srcs/sources_1/imports/example_design/support/jesd204_0_clocking.v
  
  # Generate JESD204 PHY Core
  create_ip -name jesd204_phy -vendor xilinx.com -library ip -module_name jesd204_phy_0
  set_property -dict [list CONFIG.C_LANES {4} CONFIG.TransceiverControl {true} CONFIG.GT_Line_Rate {10.0} CONFIG.C_PLL_SELECTION {1} CONFIG.RX_GT_Line_Rate {10.0} CONFIG.RX_PLL_SELECTION {1} CONFIG.GT_REFCLK_FREQ {250} CONFIG.RX_GT_REFCLK_FREQ {250} CONFIG.DRPCLK_FREQ {100.0}] [get_ips jesd204_phy_0]
  generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_phy_0/jesd204_phy_0.xci]
  create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_phy_0/jesd204_phy_0.xci]
  reset_run jesd204_phy_0_synth_1
  launch_run  jesd204_phy_0_synth_1
  wait_on_run jesd204_phy_0_synth_1    

} else {
  if {$hw_demo == 4} {
    #Generate Tx JESD204 Core
    create_ip -name jesd204 -vendor xilinx.com -library ip -module_name jesd204_0
    set_property -dict [list CONFIG.C_LANES {4} CONFIG.GT_Line_Rate {6.144} CONFIG.C_PLL_SELECTION {4} CONFIG.USE_RPAT {true} CONFIG.USE_JSPAT {true} CONFIG.Global_clk_sel {false}] [get_ips jesd204_0]
    generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_0/jesd204_0.xci]
    create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_0/jesd204_0.xci]
    reset_run jesd204_0_synth_1
    launch_run  jesd204_0_synth_1
    wait_on_run jesd204_0_synth_1

    # Open Example Design
    open_example_project -force -dir ./$PROJ_NAME [get_ips  jesd204_0]

    # Generate Rx JESD204 Core
    create_ip -name jesd204 -vendor xilinx.com -library ip -module_name jesd204_1
    set_property -dict [list CONFIG.C_NODE_IS_TRANSMIT {0} CONFIG.C_LANES {4} CONFIG.GT_Line_Rate {6.144} CONFIG.C_PLL_SELECTION {4} CONFIG.Global_clk_sel {false}] [get_ips jesd204_1]
    generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_1/jesd204_1.xci]
    create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_1/jesd204_1.xci]
    reset_run jesd204_1_synth_1
    launch_run  jesd204_1_synth_1
    wait_on_run jesd204_1_synth_1
    
    # Generate JESD204 PHY Core
    create_ip -name jesd204_phy -vendor xilinx.com -library ip -module_name jesd204_phy_0
    set_property -dict [list CONFIG.C_LANES {4} CONFIG.TransceiverControl {true} CONFIG.GT_Line_Rate {6.144} CONFIG.C_PLL_SELECTION {4} CONFIG.RX_GT_Line_Rate {6.144} CONFIG.RX_PLL_SELECTION {4}] [get_ips jesd204_phy_0]
    generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_phy_0/jesd204_phy_0.xci]
    create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_phy_0/jesd204_phy_0.xci]
    reset_run jesd204_phy_0_synth_1
    launch_run  jesd204_phy_0_synth_1
    wait_on_run jesd204_phy_0_synth_1    
  
  } else {
    #Generate Tx JESD204 Core
    create_ip -name jesd204 -vendor xilinx.com -library ip -module_name jesd204_0
    set_property -dict [list CONFIG.C_LANES {4} CONFIG.GT_Line_Rate {10.0} CONFIG.C_PLL_SELECTION {3} CONFIG.USE_RPAT {true} CONFIG.USE_JSPAT {true}] [get_ips jesd204_0]
    generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_0/jesd204_0.xci]
    create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_0/jesd204_0.xci]
    reset_run jesd204_0_synth_1
    launch_run  jesd204_0_synth_1
    wait_on_run jesd204_0_synth_1

    # Open Example Design
    open_example_project -force -dir ./$PROJ_NAME [get_ips  jesd204_0]

    # Generate Rx JESD204 Core
    create_ip -name jesd204 -vendor xilinx.com -library ip -module_name jesd204_1
    set_property -dict [list CONFIG.C_NODE_IS_TRANSMIT {0} CONFIG.C_LANES {4} CONFIG.GT_Line_Rate {10.0} CONFIG.C_PLL_SELECTION {3}] [get_ips jesd204_1]
    generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_1/jesd204_1.xci]
    create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_1/jesd204_1.xci]
    reset_run jesd204_1_synth_1
    launch_run  jesd204_1_synth_1
    wait_on_run jesd204_1_synth_1
    
    # Generate JESD204 PHY Core
    create_ip -name jesd204_phy -vendor xilinx.com -library ip -module_name jesd204_phy_0
    set_property -dict [list CONFIG.C_LANES {4} CONFIG.TransceiverControl {true} CONFIG.GT_Line_Rate {10.0} CONFIG.C_PLL_SELECTION {3} CONFIG.RX_GT_Line_Rate {10.0} CONFIG.RX_PLL_SELECTION {3} CONFIG.GT_REFCLK_FREQ {250.000} CONFIG.RX_GT_REFCLK_FREQ {250.000}] [get_ips jesd204_phy_0]
    generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_phy_0/jesd204_phy_0.xci]
    create_ip_run [get_files -of_objects [get_fileset sources_1] ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/jesd204_phy_0/jesd204_phy_0.xci]
    reset_run jesd204_phy_0_synth_1
    launch_run  jesd204_phy_0_synth_1
    wait_on_run jesd204_phy_0_synth_1  
  }  

  switch $hw_demo {
    1 {
      #Import files for Hardware Demo
      import_files -fileset constrs_1 ./hwdemo_files/kc705.xdc
      import_files -norecurse {./hwdemo_files/jesd204_kc705.v ./hwdemo_files/kc705_iic_controller.vhd}
    }

    2 {
      #Import files for Hardware Demo
      import_files -fileset constrs_1 ./hwdemo_files/vc709.xdc
      import_files -norecurse {./hwdemo_files/jesd204_vc709.v ./hwdemo_files/vc709_iic_controller.vhd}
    }

    3 {
      #Import files for Hardware Demo
      import_files -fileset constrs_1 ./hwdemo_files/zc706.xdc
      import_files -norecurse {./hwdemo_files/jesd204_zc706.v ./hwdemo_files/zc706_iic_controller.vhd}
    }

    4 {
      #Import files for Hardware Demo
      import_files -fileset constrs_1 ./hwdemo_files/ac701.xdc
      import_files -norecurse {./hwdemo_files/jesd204_ac701.v ./hwdemo_files/ac701_iic_controller.vhd}
    }

    default {
      puts "Error should never reach this state"
    }
  }

  #Import files from Example Design
  import_files $PROJ_NAME/jesd204_0_example/jesd204_0_example.srcs/sources_1/imports/example_design/support/jesd204_0_clocking.v

  update_compile_order -fileset sources_1

}

#Import Common files from Hardware Demo
import_files -norecurse {./hwdemo_files/sine16bit.vh}
import_files -norecurse {./hwdemo_files/mapper.v ./hwdemo_files/tx_datagen.v ./hwdemo_files/demapper.v ./hwdemo_files/rx_datacomp.v ./hwdemo_files/axi_controller.vhd}

#Generate IIC Core
create_ip -name axi_iic -vendor xilinx.com -library ip -module_name axi_iic_0
set_property -dict [list CONFIG.AXI_ACLK_FREQ_MHZ {100} CONFIG.C_SCL_INERTIAL_DELAY {50} CONFIG.C_SDA_INERTIAL_DELAY {50} CONFIG.USE_BOARD_FLOW {false}] [get_ips axi_iic_0]
set_property generate_synth_checkpoint false [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/axi_iic_0/axi_iic_0.xci]
generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/axi_iic_0/axi_iic_0.xci]

#Generate VIO Core
create_ip -name vio -vendor xilinx.com -library ip -module_name vio_0
set_property -dict [list CONFIG.C_NUM_PROBE_IN {8} CONFIG.C_NUM_PROBE_OUT {17} CONFIG.C_PROBE_IN0_WIDTH {32} CONFIG.C_PROBE_IN6_WIDTH {8} CONFIG.C_PROBE_IN7_WIDTH {12} CONFIG.C_PROBE_OUT0_WIDTH {32} CONFIG.C_PROBE_OUT1_WIDTH {12} CONFIG.C_PROBE_OUT2_WIDTH {1} CONFIG.C_PROBE_OUT6_WIDTH {3}] [get_ips vio_0]
generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/vio_0/vio_0.xci]

if {$hw_demo == 4} {
  #Generate TX ILA
  create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0
  set_property -dict [list CONFIG.C_PROBE16_WIDTH {4} CONFIG.C_PROBE15_WIDTH {32} CONFIG.C_PROBE14_WIDTH {4} CONFIG.C_PROBE13_WIDTH {32} CONFIG.C_PROBE12_WIDTH {4} CONFIG.C_PROBE11_WIDTH {32} CONFIG.C_PROBE10_WIDTH {4} CONFIG.C_PROBE9_WIDTH {32} CONFIG.C_PROBE8_WIDTH {1} CONFIG.C_PROBE7_WIDTH {4} CONFIG.C_PROBE6_WIDTH {4} CONFIG.C_PROBE3_WIDTH {32} CONFIG.C_PROBE2_WIDTH {32} CONFIG.C_PROBE1_WIDTH {32} CONFIG.C_PROBE0_WIDTH {32} CONFIG.C_DATA_DEPTH {1024} CONFIG.C_NUM_OF_PROBES {17}] [get_ips ila_0]
  generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/ila_0/ila_0.xci]

  #Generate RX ILA
  create_ip -name ila -vendor xilinx.com -library ip -module_name ila_1
  set_property -dict [list CONFIG.C_PROBE28_WIDTH {4} CONFIG.C_PROBE27_WIDTH {4} CONFIG.C_PROBE26_WIDTH {4} CONFIG.C_PROBE25_WIDTH {32} CONFIG.C_PROBE24_WIDTH {4} CONFIG.C_PROBE23_WIDTH {4} CONFIG.C_PROBE22_WIDTH {4} CONFIG.C_PROBE21_WIDTH {32} CONFIG.C_PROBE20_WIDTH {4} CONFIG.C_PROBE19_WIDTH {4} CONFIG.C_PROBE18_WIDTH {4} CONFIG.C_PROBE17_WIDTH {32} CONFIG.C_PROBE16_WIDTH {4} CONFIG.C_PROBE15_WIDTH {4} CONFIG.C_PROBE14_WIDTH {4} CONFIG.C_PROBE13_WIDTH {32} CONFIG.C_PROBE12_WIDTH {8} CONFIG.C_PROBE11_WIDTH {8} CONFIG.C_PROBE10_WIDTH {32} CONFIG.C_PROBE9_WIDTH {32} CONFIG.C_PROBE7_WIDTH {16} CONFIG.C_PROBE6_WIDTH {4} CONFIG.C_PROBE5_WIDTH {4} CONFIG.C_PROBE3_WIDTH {32} CONFIG.C_PROBE2_WIDTH {32} CONFIG.C_PROBE1_WIDTH {32} CONFIG.C_PROBE0_WIDTH {32} CONFIG.C_DATA_DEPTH {1024} CONFIG.C_NUM_OF_PROBES {29}] [get_ips ila_1]
  generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/ila_1/ila_1.xci]
} else {
  #Generate TX ILA
  create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0
  set_property -dict [list CONFIG.C_PROBE16_WIDTH {4} CONFIG.C_PROBE15_WIDTH {32} CONFIG.C_PROBE14_WIDTH {4} CONFIG.C_PROBE13_WIDTH {32} CONFIG.C_PROBE12_WIDTH {4} CONFIG.C_PROBE11_WIDTH {32} CONFIG.C_PROBE10_WIDTH {4} CONFIG.C_PROBE9_WIDTH {32} CONFIG.C_PROBE8_WIDTH {1} CONFIG.C_PROBE7_WIDTH {4} CONFIG.C_PROBE6_WIDTH {4} CONFIG.C_PROBE3_WIDTH {32} CONFIG.C_PROBE2_WIDTH {32} CONFIG.C_PROBE1_WIDTH {32} CONFIG.C_PROBE0_WIDTH {32} CONFIG.C_DATA_DEPTH {4096} CONFIG.C_NUM_OF_PROBES {17}] [get_ips ila_0]
  generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/ila_0/ila_0.xci]

  #Generate RX ILA
  create_ip -name ila -vendor xilinx.com -library ip -module_name ila_1
  set_property -dict [list CONFIG.C_PROBE28_WIDTH {4} CONFIG.C_PROBE27_WIDTH {4} CONFIG.C_PROBE26_WIDTH {4} CONFIG.C_PROBE25_WIDTH {32} CONFIG.C_PROBE24_WIDTH {4} CONFIG.C_PROBE23_WIDTH {4} CONFIG.C_PROBE22_WIDTH {4} CONFIG.C_PROBE21_WIDTH {32} CONFIG.C_PROBE20_WIDTH {4} CONFIG.C_PROBE19_WIDTH {4} CONFIG.C_PROBE18_WIDTH {4} CONFIG.C_PROBE17_WIDTH {32} CONFIG.C_PROBE16_WIDTH {4} CONFIG.C_PROBE15_WIDTH {4} CONFIG.C_PROBE14_WIDTH {4} CONFIG.C_PROBE13_WIDTH {32} CONFIG.C_PROBE12_WIDTH {8} CONFIG.C_PROBE11_WIDTH {8} CONFIG.C_PROBE10_WIDTH {32} CONFIG.C_PROBE9_WIDTH {32} CONFIG.C_PROBE7_WIDTH {16} CONFIG.C_PROBE6_WIDTH {4} CONFIG.C_PROBE5_WIDTH {4} CONFIG.C_PROBE3_WIDTH {32} CONFIG.C_PROBE2_WIDTH {32} CONFIG.C_PROBE1_WIDTH {32} CONFIG.C_PROBE0_WIDTH {32} CONFIG.C_DATA_DEPTH {4096} CONFIG.C_NUM_OF_PROBES {29}] [get_ips ila_1]
  generate_target all [get_files  ./$PROJ_NAME/$PROJ_NAME.srcs/sources_1/ip/ila_1/ila_1.xci]
}
 reset_run synth_1
 launch_runs synth_1
 wait_on_run synth_1
 launch_runs impl_1
 wait_on_run impl_1
 launch_runs impl_1 -to_step write_bitstream
 open_hw
 close_hw
