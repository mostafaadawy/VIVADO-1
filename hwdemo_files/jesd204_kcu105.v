//---------------------------------------------------------------------
// Title   : Hardware Demo design top level for JESD204 on KC705
// Project : JESD204
//---------------------------------------------------------------------
// File    : jesd204_kcu105.v
// Author  : Xilinx
//---------------------------------------------------------------------
// Description:
//   This example design for JESD204 is designed to be hosted on
//   the KCU705 Kintex-8 Evaluation Board using Vivado LabTools to provide
//   Control and Monitoring of dual Tx and Rx JESD204 cores in loopback.
//
//---------------------------------------------------------------------
// (c) Copyright 2012-2013 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//---------------------------------------------------------------------
module jesd204_kcu105 (

  // 300 MHz system clock
  input       clk300_p,
  input       clk300_n,

  // clock in from Si570 Programmable Oscillator
  input       clk_si570_p,
  input       clk_si570_n,

  output      si570_clk_sel,

  // clock in from Si5326 - GTX Refclk
  input       refclk_p,
  input       refclk_n,

  // Clock control IIC
  inout       iic_sda,
  inout       iic_scl,

  output      si5326_rst_n,
  output      iic_mux_rst_n,

  // External Reset
  input       ext_reset,

  // Status LEDs
  output[7:0] leds,

  // Board Fan control
  output      fan_on,

  output  [3:0]  txp,
  output  [3:0]  txn,
  input  [3:0]   rxp,
  input  [3:0]   rxn,

  output    mon_clk1,
  output    mon_clk2
  );
  
  assign si570_clk_sel = 1'b0;

  (* mark_debug = "TRUE" *) wire [31:0]  gt0_txdata;
  (* mark_debug = "TRUE" *) wire [3:0]   gt0_txcharisk;

  (* mark_debug = "TRUE" *) wire [31:0]  gt0_rxdata;
  (* mark_debug = "TRUE" *) wire [3:0]   gt0_rxcharisk;
  (* mark_debug = "TRUE" *) wire [3:0]   gt0_rxdisperr;
  (* mark_debug = "TRUE" *) wire [3:0]   gt0_rxnotintable;

  (* mark_debug = "TRUE" *) wire [31:0]  gt1_txdata;
  (* mark_debug = "TRUE" *) wire [3:0]   gt1_txcharisk;

  (* mark_debug = "TRUE" *) wire [31:0]  gt1_rxdata;
  (* mark_debug = "TRUE" *) wire [3:0]   gt1_rxcharisk;
  (* mark_debug = "TRUE" *) wire [3:0]   gt1_rxdisperr;
  (* mark_debug = "TRUE" *) wire [3:0]   gt1_rxnotintable;

  (* mark_debug = "TRUE" *) wire [31:0]  gt2_txdata;
  (* mark_debug = "TRUE" *) wire [3:0]   gt2_txcharisk;

  (* mark_debug = "TRUE" *) wire [31:0]  gt2_rxdata;
  (* mark_debug = "TRUE" *) wire [3:0]   gt2_rxcharisk;
  (* mark_debug = "TRUE" *) wire [3:0]   gt2_rxdisperr;
  (* mark_debug = "TRUE" *) wire [3:0]   gt2_rxnotintable;


  (* mark_debug = "TRUE" *) wire [31:0]  gt3_txdata;
   (* mark_debug = "TRUE" *)wire [3:0]   gt3_txcharisk;

  (* mark_debug = "TRUE" *) wire [31:0]  gt3_rxdata;
  (* mark_debug = "TRUE" *) wire [3:0]   gt3_rxcharisk;
  (* mark_debug = "TRUE" *) wire [3:0]   gt3_rxdisperr;
  (* mark_debug = "TRUE" *) wire [3:0]   gt3_rxnotintable; 

  wire        refclk;

  // Tx
  wire        core_clk;
  wire        txclk_rdy;

  reg         tx_sysref;
  wire        tx_sync;

  (* mark_debug = "TRUE" *) wire[3:0]   tx_sof;
  (* mark_debug = "TRUE" *) wire[3:0]   tx_somf;

  wire[31:0]  tx0_tdata;
  wire[31:0]  tx1_tdata;
  wire[31:0]  tx2_tdata;
  wire[31:0]  tx3_tdata;

  wire[127:0] tx_tdata;
  wire        tx_tready;

  (* mark_debug = "TRUE" *) reg         rx_sysref;
  wire        rx_sync;

  (* mark_debug = "TRUE" *) wire[3:0]   rx_sof;
  (* mark_debug = "TRUE" *) wire[3:0]   rx_eof;
  (* mark_debug = "TRUE" *) wire[15:0]  rx_frame_error;

  // AXI-Lite Control/Status
  wire        axi_aclk;
  wire        axi_aresetn;
  wire[11:0]  axi_awaddr;
  wire        axi_awvalid;
  wire        axi_awready;
  wire[31:0]  axi_wdata;
  wire        axi_wvalid;
  wire        axi_wready;
  wire[ 1:0]  axi_bresp;
  wire        axi_bvalid;
  wire        axi_bready;
  wire[11:0]  axi_araddr;
  wire        axi_arvalid;
  wire        axi_arready;
  wire[31:0]  axi_rdata;
  wire[ 1:0]  axi_rresp;
  wire        axi_rvalid;
  wire        axi_rready;

  // TX AXI-Lite Control/Status
  wire        tx_axi_awvalid;
  wire        tx_axi_awready;
  wire        tx_axi_wvalid;
  wire        tx_axi_wready;
  wire[ 1:0]  tx_axi_bresp;
  wire        tx_axi_bvalid;
  wire        tx_axi_bready;
  wire        tx_axi_arvalid;
  wire        tx_axi_arready;
  wire[31:0]  tx_axi_rdata;
  wire[ 1:0]  tx_axi_rresp;
  wire        tx_axi_rvalid;
  wire        tx_axi_rready;

  // RX AXI-Lite Control/Status
  wire        rx_axi_awvalid;
  wire        rx_axi_awready;
  wire        rx_axi_wvalid;
  wire        rx_axi_wready;
  wire[ 1:0]  rx_axi_bresp;
  wire        rx_axi_bvalid;
  wire        rx_axi_bready;
  wire        rx_axi_arvalid;
  wire        rx_axi_arready;
  wire[31:0]  rx_axi_rdata;
  wire[ 1:0]  rx_axi_rresp;
  wire        rx_axi_rvalid;
  wire        rx_axi_rready;

  wire        axi_busy;
  wire[1:0]   init_start;

  (* mark_debug = "TRUE" *) wire[127:0] rx_tdata;
  (* mark_debug = "TRUE" *) wire        rx_tvalid;

  // SYNCB Generation
  (* mark_debug = "TRUE" *) wire        vio_resync;
  wire        vio_resync_sync;
  (* mark_debug = "TRUE" *) wire        cfg_resync;
  (* mark_debug = "TRUE" *) wire        force_resync;

  // SYSREF Generation
  (* mark_debug = "TRUE" *) wire        sysref_disable;
  wire        sysref_disable_sync;
  reg[5:0]    sysref_count;
  reg         sysref;

  // Tx Data Generation & Mapping
  (* mark_debug = "TRUE" *) wire        datamode;
  wire        datamode_sync;
  (* mark_debug = "TRUE" *) wire        ch0_step_up;
  wire        ch0_step_up_sync;
  (* mark_debug = "TRUE" *) wire        ch0_step_down;
  wire        ch0_step_down_sync;
  wire[ 7:0]  step_size_0;
  (* mark_debug = "TRUE" *) wire[63:0]  tx_data0;

  (* mark_debug = "TRUE" *) wire        ch1_step_up;
  wire        ch1_step_up_sync;
  (* mark_debug = "TRUE" *) wire        ch1_step_down;
  wire        ch1_step_down_sync;
  (* mark_debug = "TRUE" *) wire[ 7:0]  step_size_1;
  wire[63:0]  tx_data1;

  // Rx Demapping and Data compare
  wire        rx_dvalid;
  wire[63:0]  rx_data0;
  wire[63:0]  rx_data1;

  // Error injection
  (* mark_debug = "TRUE" *) wire        rx_error_inject;
  wire        rx_error_inject_sync;
  wire[63:0]  rx_data0e;

  wire        enable_datacomp;
  wire [ 7:0] rx0_errors;
  wire [31:0] rx0_error_count;
  wire [ 7:0] rx1_errors;
  wire [31:0] rx1_error_count;

  wire        rx0_started;
  wire        rx1_started;

  // VIO AXI Controller
  (* mark_debug = "TRUE" *) wire        read_req;
  (* mark_debug = "TRUE" *) wire        write_req;
  (* mark_debug = "TRUE" *) wire[11:0]  address;
  (* mark_debug = "TRUE" *) wire[31:0]  wr_data;
  (* mark_debug = "TRUE" *) wire[31:0]  rd_data;
  (* mark_debug = "TRUE" *) wire        config_change;
  (* mark_debug = "TRUE" *) wire        core_axi_sel;
  (* mark_debug = "TRUE" *) wire[ 2:0]  config_sel;

  wire [7:0]  axi_status;
  reg         axi_access;

  // Clocks & Resets
  wire        clk_si570b;
  wire        clk_si570;
  wire        clk_si5326;

  wire        clk300;
  wire        clk300b;
  wire        clk100b;
  wire        clk10b;
  wire        clkfb;
  wire        clk100;
  wire        clk10;

  wire        mmcm_locked;
  wire        mmcm_reset;
  wire        iic_done;

  (* mark_debug = "TRUE" *) reg         vio_mmcm_locked;
  (* mark_debug = "TRUE" *) reg         vio_iic_done;
  (* mark_debug = "TRUE" *) reg         vio_tx_sync;
  (* mark_debug = "TRUE" *) reg         vio_rx_sync;

  // Resets & Startup sequencing
  reg         vio_reset_d1 = 1'b0;
  reg         vio_reset_d2 = 1'b0;
  reg         vio_reset_d3 = 1'b0;
  reg         vio_reset_p  = 1'b0;
  reg [4:0]   vio_reset_sr = 5'b0;

  reg [10:0]  refclk_ok_count;
  (* mark_debug = "TRUE" *) reg         refclk_ok;

  (* mark_debug = "TRUE" *) wire        vio_reset;
  (* mark_debug = "TRUE" *) wire [3:0]  status_iic;
  wire        iic_reset;
  wire        axi_reset;
  wire        core_reset;

  reg [23:0]  alive_tx;
  reg [23:0]  alive_rx;

  wire         txoutclk;
  wire         rxoutclk;
  wire         common_pll0_clk_i;
  wire         common_pll0_refclk_i;
  (* mark_debug = "TRUE" *) wire         common_pll0_lock_i;

  wire [3:0]   prbssel_i;
  wire         rxencommaalign_i;
  wire         tx_reset_gt;
  (* mark_debug = "TRUE" *) wire         tx_reset_done;
  wire         rx_reset_gt;
  (* mark_debug = "TRUE" *) wire         rx_reset_done;

  reg          cfg_req_d1;
  reg          cfg_req_p;
  reg          wr_req_d1;
  reg          wr_req_p;
  reg          rd_req_d1;
  reg          rd_req_p;

  (* mark_debug = "TRUE" *) wire         axi_sel;

  //====================Signals for latency test=========================
  reg        stop_flag;
  reg [23:0] repeat_interval;
  (* mark_debug = "TRUE" *) reg [11:0] latency_i;
  (* mark_debug = "TRUE" *) reg [11:0] latency;

  (* mark_debug = "TRUE" *) wire      tx_pulse;
  (* mark_debug = "TRUE" *) wire      rx_pulse;
  (* mark_debug = "TRUE" *) wire      calc_latency;

  parameter size = 2;
  parameter idle = 2'b01, counting = 2'b10; //stopped = 3'b100;
  (* mark_debug = "TRUE" *) reg [size-1:0] state;
  // ====================================================================

  // axi_sel selects between TX and RX JESD204 axi to read or write
  // When init_start[1] is high, vio input is ignored.

  assign axi_sel = (init_start[1]) ? init_start[0] : core_axi_sel;

  assign axi_awready = (axi_sel) ? tx_axi_awready  :  rx_axi_awready;
  assign axi_awready = (axi_sel) ? tx_axi_awready  :  rx_axi_awready;
  assign axi_wready  = (axi_sel) ? tx_axi_wready   :  rx_axi_wready;
  assign axi_bresp   = (axi_sel) ? tx_axi_bresp    :  rx_axi_bresp;
  assign axi_bvalid  = (axi_sel) ? tx_axi_bvalid   :  rx_axi_bvalid;
  assign axi_arready = (axi_sel) ? tx_axi_arready  :  rx_axi_arready;
  assign axi_rdata   = (axi_sel) ? tx_axi_rdata    :  rx_axi_rdata;
  assign axi_rresp   = (axi_sel) ? tx_axi_rresp    :  rx_axi_rresp;
  assign axi_rvalid  = (axi_sel) ? tx_axi_rvalid   :  rx_axi_rvalid;

  assign tx_axi_awvalid = (axi_sel) ?  axi_awvalid  :  1'b0;
  assign tx_axi_wvalid  = (axi_sel) ?  axi_wvalid   :  1'b0;
  assign tx_axi_bready  = (axi_sel) ?  axi_bready   :  1'b0;
  assign tx_axi_arvalid = (axi_sel) ?  axi_arvalid  :  1'b0;
  assign tx_axi_rready  = (axi_sel) ?  axi_rready   :  1'b0;

  assign rx_axi_awvalid = (~axi_sel) ?  axi_awvalid :  1'b0;
  assign rx_axi_wvalid  = (~axi_sel) ?  axi_wvalid  :  1'b0;
  assign rx_axi_bready  = (~axi_sel) ?  axi_bready  :  1'b0;
  assign rx_axi_arvalid = (~axi_sel) ?  axi_arvalid :  1'b0;
  assign rx_axi_rready  = (~axi_sel) ?  axi_rready  :  1'b0;

  //===================================
  // Local Clock Generation
  //===================================

  // 300 MHz system clock from KCU105
   IBUFDS clk300_ibuf (
     .I  (clk300_p),
     .IB (clk300_n),
     .O  (clk300)
     );

   BUFG clk300_bufg (
     .I      (clk300),
     .O      (clk300b)
     );

  // MMCM generates local clocks from 300 MHz input
  //
  // CLKOUT0 : clk100 100 MHz - AXI Lite interface and I2C Controller
  // CLKOUT1 : clk10   10 MHz - slow clock for long resets etc.

  MMCM_ADV #(
    .BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (3),
    .CLKFBOUT_MULT_F      (10.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (10.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKOUT1_DIVIDE       (100),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (3.333),
    .REF_JITTER1          (0.010)
    )
    mmcm_adv_i(
    .CLKIN1               (clk300),
    .CLKIN2               (1'b0),
    .CLKINSEL             (1'b1),
    .CLKFBIN              (clkfb),
    .CLKOUT0              (clk100b),
    .CLKOUT0B             (),
    .CLKOUT1              (clk10b),
    .CLKOUT1B             (),
    .CLKOUT2              (),
    .CLKOUT2B             (),
    .CLKOUT3              (),
    .CLKOUT3B             (),
    .CLKOUT4              (),
    .CLKOUT5              (),
    .CLKOUT6              (),
    .CLKFBOUT             (clkfb),
    .CLKFBOUTB            (),
    .CLKFBSTOPPED         (),
    .CLKINSTOPPED         (),
    .DO                   (),
    .DRDY                 (),
    .DADDR                (7'd0),
    .DCLK                 (1'b0),
    .DEN                  (1'b0),
    .DI                   (16'd0),
    .DWE                  (1'b0),
    .LOCKED               (mmcm_locked),
    .PSCLK                (1'b0),
    .PSEN                 (1'b0),
    .PSINCDEC             (1'b0),
    .PWRDWN               (1'b0),
    .RST                  (mmcm_reset)
    );

   BUFG clk100_bufg (
     .I  (clk100b),
     .O  (clk100)
     );

  BUFG clk10_bufg (
    .I  (clk10b),
    .O  (clk10)
    );

  //===================================
  // SYNC Generation
  //===================================

  // Resync can be forced via VIO and also on config changes
  assign force_resync = vio_resync_sync | cfg_resync;

  // Rx Sync routes to Tx, allowing for forced resync
  assign tx_sync = force_resync ? 1'b0 : rx_sync;

  //===================================
  // SYSREF Generation
  //===================================
  // generate a periodic SYSREF
  //
  // LMFC interval is every 4 clocks for the 32-byte Multiframe
  // size used by all the preset configs
  //
  // a SYSREF pulse will be generated every 64 clocks (16 LMFC periods)
  //
  always @(posedge core_clk)
  begin
    if (tx_aresetn == 1'b0) begin
      sysref_count <= 6'b0;
      sysref       <= 1'b0;
    end
    else begin
      sysref_count <= sysref_count + 1;
      if (sysref_count == 6'b111111)
        sysref = 1'b1;
      else
        sysref = 1'b0;

      tx_sysref <= sysref & ~sysref_disable_sync;
      rx_sysref <= sysref & ~sysref_disable_sync;
    end
  end

  //===========================================
  // Tx Data generator(s)
  //===========================================

  // "Channel" 0 64-bit data generator (4 16-bit samples per clock)
  tx_datagen i_txdatagen0(
    .clk       (core_clk),             //input            clk,
    .reset     (core_reset),          //input            reset,
    .mode      (datamode_sync),       //input            mode,             // 0 = Digital 1 = "Analog" (Sine)
    .step_u    (ch0_step_up_sync),    //input            step_u,           // increase "analog" frequency step
    .step_d    (ch0_step_down_sync),  //input            step_d,           // decrease "analog" frequency step
    .step_size (step_size_0),         //output reg[ 7:0] step_size,        // Current "Analog" step size
    .data_out  (tx_data0)             //output reg[63:0] data_out          // data output
    );

  // "Channel" 1 64-bit data generator (4 16-bit samples per clock)
  tx_datagen i_txdatagen1(
    .clk       (core_clk),            //input            clk,
    .reset     (core_reset),          //input            reset,
    .mode      (datamode_sync),       //input            mode,             // 0 = Digital 1 = "Analog" (Sine)
    .step_u    (ch1_step_up_sync),    //input            step_u,           // increase "analog" frequency step
    .step_d    (ch1_step_down_sync),  //input            step_d,           // decrease "analog" frequency step
    .step_size (step_size_1),         //output reg[ 7:0] step_size,        // Current "Analog" step size
    .data_out  (tx_data1)             //output reg[63:0] data_out          // data output
    );


  //===========================================
  // Tx Sample Mapping
  //===========================================
  mapper i_mapper(
    .tx_aclk       (core_clk),                                // input             tx_aclk,
    .tx_aresetn    (tx_aresetn ),                             // input             tx_aresetn,

    // Channel 0 data - 4 16-bit 'samples' per clock
    .tx_data0      (tx_data0),                                // input [63:0]      tx_data0,
    // Channel 1 data - 4 16-bit 'samples' per clock
    .tx_data1      (tx_data1),                                // input [63:0]      tx_data1,

    .tx_tready    (tx_tready),                                // input             tx_tready,
    // AXI-S Lane 0 to JESD204 Tx core
    .tx0_tdata     (tx0_tdata ),                              // output reg [31:0] tx0_tdata,

    // AXI-S Lane 1 to JESD204 Tx core
    .tx1_tdata     (tx1_tdata ),                              // output reg [31:0] tx1_tdata,

    // AXI-S Lane 2 to JESD204 Tx core
    .tx2_tdata     (tx2_tdata ),                              // output reg [31:0] tx2_tdata,

    // AXI-S Lane 3 to JESD204 Tx core
    .tx3_tdata     (tx3_tdata )                               // output reg [31:0] tx3_tdata,
  );

  // Lane Data
    assign  tx_tdata  = (tx_pulse) ? {4{32'hB5B5B5B5}} : {tx3_tdata, tx2_tdata, tx1_tdata, tx0_tdata};

  //===================================
  //Transmit JESD204 core
  //===================================
  jesd204_0 tx_jesd204 (
    .tx_reset                   (core_reset),        // input tx_reset
    .tx_reset_gt                (tx_reset_gt),       // output tx_reset_gt
    .tx_core_clk                (core_clk),          // input tx_core_clk

    // Tx AXI-S interface clock and reset
    .tx_aresetn                 (tx_aresetn),        // output tx_aresetn

    .tx_reset_done              (tx_reset_done),     // input tx_reset_done

    .tx_sysref                  (tx_sysref),         // input tx_sysref
    .tx_sync                    (tx_sync),           // input tx_sync

    // Input Data to Core
    .tx_tdata                   (tx_tdata),          // input [127 : 0] tx_tdata
    .tx_tready                  (tx_tready),         // output tx_tready

    // Output Data to GTs
    // Lane 0
    .gt0_txdata                 (gt0_txdata),
    .gt0_txcharisk              (gt0_txcharisk),
  
    // Lane 1
    .gt1_txdata                 (gt1_txdata),
    .gt1_txcharisk              (gt1_txcharisk),
  
    // Lane 2
    .gt2_txdata                 (gt2_txdata),

    .gt2_txcharisk              (gt2_txcharisk),
  
    // Lane 3
    .gt3_txdata                 (gt3_txdata),
    .gt3_txcharisk              (gt3_txcharisk),    
    
    .gt_prbssel_out             (prbssel_i),         // output [3 : 0] gt_prbssel_out

    .tx_start_of_frame          (tx_sof),            // output [3 : 0] tx_start_of_frame
    .tx_start_of_multiframe     (tx_somf),           // output [3 : 0] tx_start_of_multiframe

    // AXI Ports
    .s_axi_aclk                 (clk100),            // input s_axi_aclk
    .s_axi_aresetn              (axi_aresetn),       // input          s_axi_aresetn,

    .s_axi_awaddr               (axi_awaddr),        // input [31:0]   s_axi_awaddr,
    .s_axi_awvalid              (tx_axi_awvalid),    // input          s_axi_awvalid,
    .s_axi_awready              (tx_axi_awready),    // output         s_axi_awready,
    .s_axi_wdata                (axi_wdata),         // input [31:0]   s_axi_wdata,
    .s_axi_wstrb                (4'b1111),           // input [3:0]    s_axi_wstrb,
    .s_axi_wvalid               (tx_axi_wvalid),     // input          s_axi_wvalid,
    .s_axi_wready               (tx_axi_wready),     // output         s_axi_wready,
    .s_axi_bresp                (tx_axi_bresp),      // output[1:0]    s_axi_bresp,
    .s_axi_bvalid               (tx_axi_bvalid),     // output         s_axi_bvalid,
    .s_axi_bready               (tx_axi_bready),     // input          s_axi_bready,
    .s_axi_araddr               (axi_araddr),        // input [31:0]   s_axi_araddr,
    .s_axi_arvalid              (tx_axi_arvalid),    // input          s_axi_arvalid,
    .s_axi_arready              (tx_axi_arready),    // output         s_axi_arready,
    .s_axi_rdata                (tx_axi_rdata),      // output[31:0]   s_axi_rdata,
    .s_axi_rresp                (tx_axi_rresp),      // output[1:0]    s_axi_rresp,
    .s_axi_rvalid               (tx_axi_rvalid),     // output         s_axi_rvalid,
    .s_axi_rready               (tx_axi_rready)      // input          s_axi_rready,
  );

  //===================================
  // Receive JESD204 Core
  //===================================
  jesd204_1 rx_jesd204 (

    .rx_reset              (core_reset),         // input rx_reset
    .rx_reset_gt           (rx_reset_gt),        // output rx_reset_gt
    .rx_core_clk           (core_clk),           // input rx_core_clk
    .rx_reset_done         (rx_reset_done),      // input rx_reset_done

    // Rx AXI-S interface clock and reset
    .rx_aresetn            (rx_aresetn),         // output rx_aresetn

    .rx_sysref             (rx_sysref),          // input rx_sysref
    .rx_sync               (rx_sync),            // output rx_sync
    
    // Lane 0
    .gt0_rxdata            (gt0_rxdata),
    .gt0_rxcharisk         (gt0_rxcharisk),
    .gt0_rxdisperr         (gt0_rxdisperr),
    .gt0_rxnotintable      (gt0_rxnotintable),
  
    // Lane 1
    .gt1_rxdata            (gt1_rxdata),
    .gt1_rxcharisk         (gt1_rxcharisk),
    .gt1_rxdisperr         (gt1_rxdisperr),
    .gt1_rxnotintable      (gt1_rxnotintable),
  
    // Lane 2
    .gt2_rxdata            (gt2_rxdata),
    .gt2_rxcharisk         (gt2_rxcharisk),
    .gt2_rxdisperr         (gt2_rxdisperr),
    .gt2_rxnotintable      (gt2_rxnotintable),
  
    // Lane 3
    .gt3_rxdata            (gt3_rxdata),
    .gt3_rxcharisk         (gt3_rxcharisk),
    .gt3_rxdisperr         (gt3_rxdisperr),
    .gt3_rxnotintable      (gt3_rxnotintable),   

    .rxencommaalign_out    (rxencommaalign_i),   // output rxencommaalign_out

    .rx_tdata              (rx_tdata),           // output [127 : 0] rx_tdata
    .rx_tvalid             (rx_tvalid),          // output rx_tvalid
    .rx_start_of_frame     (rx_sof),             // output [3 : 0] rx_start_of_frame
    .rx_end_of_frame       (rx_eof),             // output [3 : 0] rx_end_of_frame
    .rx_frame_error        (rx_frame_error),     // output [15 : 0] rx_frame_error

    // AXI Ports
    .s_axi_aclk            (clk100),             // input          s_axi_aclk
    .s_axi_aresetn         (axi_aresetn),        // input          s_axi_aresetn,

    .s_axi_awaddr          (axi_awaddr),         // input [11:0]   s_axi_awaddr,
    .s_axi_awvalid         (rx_axi_awvalid),     // input          s_axi_awvalid,
    .s_axi_awready         (rx_axi_awready),     // output         s_axi_awready,
    .s_axi_wdata           (axi_wdata),          // input [31:0]   s_axi_wdata,
    .s_axi_wstrb           (4'b1111),            // input [3:0]    s_axi_wstrb,
    .s_axi_wvalid          (rx_axi_wvalid),      // input          s_axi_wvalid,
    .s_axi_wready          (rx_axi_wready),      // output         s_axi_wready,
    .s_axi_bresp           (rx_axi_bresp),       // output[1:0]    s_axi_bresp,
    .s_axi_bvalid          (rx_axi_bvalid),      // output         s_axi_bvalid,
    .s_axi_bready          (rx_axi_bready),      // input          s_axi_bready,
    .s_axi_araddr          (axi_araddr),         // input [11:0]   s_axi_araddr,
    .s_axi_arvalid         (rx_axi_arvalid),     // input          s_axi_arvalid,
    .s_axi_arready         (rx_axi_arready),     // output         s_axi_arready,
    .s_axi_rdata           (rx_axi_rdata),       // output[31:0]   s_axi_rdata,
    .s_axi_rresp           (rx_axi_rresp),       // output[1:0]    s_axi_rresp,
    .s_axi_rvalid          (rx_axi_rvalid),      // output         s_axi_rvalid,
    .s_axi_rready          (rx_axi_rready)       // input          s_axi_rready,
  );

  //===========================================
  // Rx Sample Demapping
  //===========================================
  demapper i_demapper(
    .rx_aclk       (core_clk),                                 // input             rx_aclk,
    .rx_aresetn    (rx_aresetn),                               // input             rx_aresetn,
                                                               //
    //AXI-S Lane 0 from JESD204 Rx core                        // input  [31:0]     rx0_tdata,
    .rx0_tdata     (rx_tdata[31:0]),
                                                               //
    //AXI-S Lane 1 from JESD204 Rx core                        // input  [31:0]     rx1_tdata,
    .rx1_tdata     (rx_tdata[63:32]),
                                                               //
    //AXI-S Lane 2 from JESD204 Rx core                        // input  [31:0]     rx2_tdata,
    .rx2_tdata     (rx_tdata[95:64]),
                                                               //
    //AXI-S Lane 3 from JESD204 Rx core                        // input  [31:0]     rx3_tdata,
    .rx3_tdata     (rx_tdata[127:96]),

    .rx_tvalid     (rx_tvalid),                                // input             rx_tvalid
                                                               //
    // Framing markers                                         // input  [3:0]      rx_sof,
    .rx_sof        (rx_sof),                                   // input  [3:0]      rx_eof,
    .rx_eof        (rx_eof),                                   //
                                                               //
    // "Channel" data out - 4 16-bit 'samples' per clock       //
    .rx_dvalid     (rx_dvalid),                                // output reg        rx_dvalid
    .rx_data0      (rx_data0),                                 // output reg [63:0] rx_data0
    .rx_data1      (rx_data1)                                  // output reg [63:0] rx_data1
    );


  //===========================================
  // Rx Data receiver(s)
  //===========================================

  assign enable_datacomp = ~datamode_sync;   // Enable comparison on digital data pattern only

  // Error injection - error 2 bits of the data on (pulsed) rx_error_inject
  assign rx_data0e[ 7]   = rx_error_inject_sync ? ~rx_data0[ 7] : rx_data0[ 7];
  assign rx_data0e[63]   = rx_error_inject_sync ? ~rx_data0[63] : rx_data0[63];

  assign rx_data0e[62:8] = rx_data0[62:8];
  assign rx_data0e[ 6:0] = rx_data0[ 6:0];

  // "Channel" 0  (4 16-bit samples per clock)
  rx_datacomp i_rxdatacomp0(
    .clk             (core_clk),                                 // input             clk,
    .reset           (core_reset),                               // input             reset,
    .enable          (enable_datacomp),                          // input             enable,
                                                                 //
    .rx_dvalid       (rx_dvalid),                                // input             rx_dvalid,
    .rx_data         (rx_data0e),                                // input [63:0]      rx_data,
                                                                 //
    .errors          (rx0_errors),                               // output reg [7:0]  errors,
    .error_count     (rx0_error_count),                          // output reg [31:0] error_count
    .started         (rx0_started)
    );

  // "Channel" 1 (4 16-bit samples per clock)
  rx_datacomp i_rxdatacomp1(
    .clk             (core_clk),                                 // input             clk,
    .reset           (core_reset),                               // input             reset,
    .enable          (enable_datacomp),                          // input             enable,
                                                                 //
    .rx_dvalid       (rx_dvalid),                                // input             rx_dvalid,
    .rx_data         (rx_data1),                                 // input [63:0]      rx_data,
                                                                 //
    .errors          (rx1_errors),                               // output reg [7:0]  errors,
    .error_count     (rx1_error_count),                          // output reg [31:0] error_count
    .started         (rx1_started)
    );

  //======================== Latency CODE =========================
  //===============================================================

  always @ (posedge core_clk or posedge core_reset)
  begin
    if (core_reset) begin
      repeat_interval <= 24'h000000;
    end
    else if (tx_sync==1'b0 || rx_sync==1'b0 || calc_latency == 1'b0) begin
      repeat_interval <= 24'h000000;
    end
    else begin            //Once cores have synced begin timer that will create pulses
      repeat_interval <= repeat_interval + 1;
    end
   end

  assign tx_pulse = (repeat_interval == 24'hFFFFFF) ? 1'b1 : 1'b0;  // Will create a pulse every time the interval timer loops around
  assign rx_pulse = stop_flag;                                      //Creates a pulse once I see the data on the receiver

  //State machine will wait for start flag to start timer
  //Will remain in counting state until stop flag goes high
  always @(posedge core_clk or posedge core_reset)
  begin
    if (core_reset) begin
      state     <= idle;
      latency_i <= 12'h000;
      latency   <= 12'h000;
      stop_flag <= 1'b0;
    end
    else if (tx_sync==1'b0 || rx_sync==1'b0) begin
      state     <= idle;
      latency_i <= 12'h000;
      latency   <= 12'h000;
      stop_flag <= 1'b0;
    end
    else begin
    case(state)
       idle : begin
         latency_i <= 12'h000;    //reset counter
         stop_flag <= 1'b0;

         if (tx_pulse == 1'b0)    //Begin counting when I see a pulse
           state <= idle;
         else
           state <= counting;
       end

       counting : begin
         if (rx_tdata != {4{32'hB5B5B5B5}}) begin //Count until I see the data I injected
           latency_i <= latency_i + 1;
         end
         else begin
           stop_flag <= 1'b1;
           latency <= latency_i;
           state <= idle;
         end
       end
     endcase
    end
  end

  //===============================================================
  //===============================================================

  //*******************************************
  //Shared Clocking Module
  //Clocks from this module can be used to share
  //with other CL modules
  //*******************************************
  jesd204_0_clocking
  i_shared_clocks(
    .refclk_pad_n         (refclk_n),
    .refclk_pad_p         (refclk_p),
    .refclk               (refclk),       //Used to drive GT Ref clock
    .glblclk_pad_n        (clk_si570_n),
    .glblclk_pad_p        (clk_si570_p),

    .coreclk              (core_clk)      //Clock used by JESD204 core and usrclk2 input for GT module
  );

  assign mon_clk1  = core_clk;
  assign mon_clk2  = core_clk;

  wire tx_gt_reset;
  wire rx_gt_reset;
//  assign tx_gt_reset = tx_reset_gt || ~common_pll0_lock_i;
//  assign rx_gt_reset = rx_reset_gt || ~common_pll0_lock_i;

  //------------------------------------------------------------
  // Instantiate the JESD204 PHY core
  //------------------------------------------------------------
  jesd204_phy_0
  i_jesd204_phy (
    // Reset Done for each GT Channel
    .gt_txresetdone          (),
    .gt_rxresetdone          (),

    // CPLL Lock for each GT Channel
    .gt_cplllock             (),

    // Loopback
    .gt_loopback             ({4{3'b010}}),

    .gt_txprbsforceerr       (4'b0),

    .gt_rxprbssel            (16'b0),
    .gt_rxprbscntreset       (4'b0),
    .gt_rxprbserr            (),

    // Power Down Ports
    .gt_rxpd                 (8'b0),
    .gt_txpd                 (8'b0),

    // TX Reset and Initialization
    .gt_txpcsreset           (4'b0),
    .gt_txpmareset           (4'b0),

    // RX Reset and Initialization
    .gt_rxpcsreset           (4'b0),
    .gt_rxpmareset           (4'b0),
    .gt_rxbufreset           (4'b0),
    .gt_rxpmaresetdone       (),

    // TX Buffer Ports
    .gt_txbufstatus          (),

    // RX Buffer Ports
    .gt_rxbufstatus          (),

    // PCI Express Ports
    .gt_rxrate               (12'b0),

    // RX Margin Analysis Ports
    .gt_eyescantrigger       (4'b0),
    .gt_eyescanreset         (4'b0),
    .gt_eyescandataerror     (),

    // RX Equalizer Ports
    .gt_rxdfelpmreset        (4'b0),
    .gt_rxlpmen              (4'b0),

    // RX CDR Ports
    .gt_rxcdrhold            (4'b0),

    // RX Digital Monitor Ports
    .gt_dmonitorout          (),

    // RX Byte and Word Alignment Ports
    .gt_rxcommadet           (), 
   
    // Reset Inputs for each direction
    .tx_reset_gt             (tx_reset_gt),
    .rx_reset_gt             (rx_reset_gt),

    // GT Common I/O
    .qpll0_refclk             (refclk),
    .common0_qpll0_lock_out   (common_pll0_lock_i),
    .common0_qpll0_refclk_out (common_pll0_refclk_i),
    .common0_qpll0_clk_out    (common_pll0_clk_i),

    // Reset Done for each direction
    .tx_reset_done           (tx_reset_done),
    .rx_reset_done           (rx_reset_done),

    .rxencommaalign          (rxencommaalign_i), //If connecting with RX core use signal from RX JESD204

    // Clocks
    .tx_core_clk              (core_clk),
    .txoutclk                 (txoutclk),
   
    .rx_core_clk              (core_clk),   
    .rxoutclk                 (rxoutclk),
     
    .drpclk                   (clk100),  
    
    //Tx PRBSSEL Pattern Generator  
    .gt_prbssel               (prbssel_i),      
    
    // DRP
    .gt0_drpaddr             (9'd0),
    .gt0_drpdi               (16'd0),
    .gt0_drpen               (1'b0),
    .gt0_drpwe               (1'b0),
    .gt0_drpdo               (),
    .gt0_drprdy              (),

    .gt1_drpaddr             (9'd0),
    .gt1_drpdi               (16'd0),
    .gt1_drpen               (1'b0),
    .gt1_drpwe               (1'b0),
    .gt1_drpdo               (),
    .gt1_drprdy              (),

    .gt2_drpaddr             (9'd0),
    .gt2_drpdi               (16'd0),
    .gt2_drpen               (1'b0),
    .gt2_drpwe               (1'b0),
    .gt2_drpdo               (),
    .gt2_drprdy              (),

    .gt3_drpaddr             (9'd0),
    .gt3_drpdi               (16'd0),
    .gt3_drpen               (1'b0),
    .gt3_drpwe               (1'b0),
    .gt3_drpdo               (),
    .gt3_drprdy              (),

    // Serial ports
    .rxn_in                  (rxn),
    .rxp_in                  (rxp),
    .txn_out                 (txn),
    .txp_out                 (txp),
  
    // Tx Ports
    // Lane 0
    .gt0_txdata              (gt0_txdata),
    .gt0_txcharisk           (gt0_txcharisk),
  
    // Lane 1
    .gt1_txdata              (gt1_txdata),
    .gt1_txcharisk           (gt1_txcharisk),
  
    // Lane 2
    .gt2_txdata              (gt2_txdata),
    .gt2_txcharisk           (gt2_txcharisk),
  
    // Lane 3
    .gt3_txdata              (gt3_txdata),
    .gt3_txcharisk           (gt3_txcharisk),
  
  
    // Transmit Control
    .gt_txpostcursor          ({4{5'b00000}}),
    .gt_txprecursor           ({4{5'b00000}}),
    .gt_txdiffctrl            ({4{4'b1000}}),
    .gt_txpolarity            (4'b0),
  
    // Rx Ports
    // Lane 0
    .gt0_rxdata              (gt0_rxdata),
    .gt0_rxcharisk           (gt0_rxcharisk),
    .gt0_rxdisperr           (gt0_rxdisperr),
    .gt0_rxnotintable        (gt0_rxnotintable),  
  
    // Lane 1
    .gt1_rxdata              (gt1_rxdata),
    .gt1_rxcharisk           (gt1_rxcharisk),
    .gt1_rxdisperr           (gt1_rxdisperr),
    .gt1_rxnotintable        (gt1_rxnotintable),  
  
    // Lane 2
    .gt2_rxdata              (gt2_rxdata),
    .gt2_rxcharisk           (gt2_rxcharisk),
    .gt2_rxdisperr           (gt2_rxdisperr),
    .gt2_rxnotintable        (gt2_rxnotintable),  
  
    // Lane 3
    .gt3_rxdata              (gt3_rxdata),
    .gt3_rxcharisk           (gt3_rxcharisk),
    .gt3_rxdisperr           (gt3_rxdisperr),
    .gt3_rxnotintable        (gt3_rxnotintable),  
  
    .gt_rxpolarity            (4'b0)
  );

  reg[14:0]   count_800us;

  reg[ 7:0]   debounce0;

  reg         ext_reset_clean;

  // Debouncer for External Pushbuttons
  always @(posedge clk10)
  begin

    // ~800 us interval counter
    // 14-bit counter @ 10MHz => 8921 cycles => ~810 us
    if (count_800us[14])
      count_800us <= 14'b0;
    else
      count_800us <= count_800us + 1;

    // debounce shift register
    if (count_800us[14]) begin
      debounce0 <= {debounce0[6:0], ext_reset};
    end

    if (debounce0 == 8'b11111111)
      ext_reset_clean <= 1'b1;
    else if (debounce0 == 8'b00000000)
      ext_reset_clean <= 1'b0;

  end

  //===========================================
  // IIC Controller (Reference clock setup)
  //===========================================
  iic_controller i_iic_controller(
    .reset     (iic_reset),
    .clk100    (clk100),
    .iic_sda   (iic_sda),
    .iic_scl   (iic_scl),
    .status    (status_iic),
    .done      (iic_done)
    );

  //===========================================
  // Reset sequencing
  //===========================================
  //
  // Ensure a ~100 us delay after the IIC controller has set up
  // the reference clock to allow the J204 core to come out of reset
  // with a stable reference clock
  // 11 bit counter @ 10 MHz => 1024 cycles => 102 us

  always @(posedge clk10 or posedge iic_reset )
  begin
    if (iic_reset) begin
      refclk_ok_count <= 11'b0;
      refclk_ok       <= 1'b0;
    end
    else begin
      if (iic_done) begin
        if (!refclk_ok_count[10])
          refclk_ok_count <= refclk_ok_count + 1;
      end
      else
        refclk_ok_count <= 11'b0;

      refclk_ok <= refclk_ok_count[10];

    end
  end

  // reset IIC devices
  assign si5326_rst_n  = !iic_reset;
  assign iic_mux_rst_n = !iic_reset;

  // Vivado VIO is synchronous only, so a VIO reset needs to be
  // handled appropriately using a clock which is not reset by the
  // reset itself
  always @(posedge clk300b)
  begin

    // handle as async to clk200
    vio_reset_d1 <= vio_reset;
    vio_reset_d2 <= vio_reset_d1;
    vio_reset_d3 <= vio_reset_d2;

    // vio_reset rising edge creates a reset pulse to the mmcm
    if (vio_reset_d2 == 1'b1 && vio_reset_d3 == 1'b0)
      vio_reset_sr <= 5'b11111;
    else
      vio_reset_sr <= {vio_reset_sr[3:0], 1'b0};

    vio_reset_p <= vio_reset_sr[4];

  end

  // Complete reset can be invoked from push button or vio
  assign mmcm_reset  = vio_reset_p | ext_reset;

  // Hold AXI interface reset until core reset(s) are released
  assign axi_reset  = core_reset;

  // hold I2C reset until MMCM locked
  assign iic_reset = ~mmcm_locked;

  // Bulk of design held in reset until reference clock is setup and stabilised
  assign core_reset = ~refclk_ok;



  //===================================
  // AXI Interface Controller
  //===================================
  axi_controller i_axi_controller(
    .clk            (clk100),
    .rst            (axi_reset),

    // Control Interface
    .rd_req         (rd_req_p),
    .wr_req         (wr_req_p),
    .cfg            (config_sel),
    .cfg_req        (cfg_req_p),
    .address        (address),
    .wr_data        (wr_data),
    .rd_data        (rd_data),

     // AXI-Lite bus interface
    .axi_aresetn    (axi_aresetn),
    .axi_awaddr     (axi_awaddr),
    .axi_awvalid    (axi_awvalid),
    .axi_awready    (axi_awready),
    .axi_wdata      (axi_wdata),
    .axi_wvalid     (axi_wvalid),
    .axi_wready     (axi_wready),
    .axi_bresp      (axi_bresp),
    .axi_bvalid     (axi_bvalid),
    .axi_bready     (axi_bready),
    .axi_araddr     (axi_araddr),
    .axi_arvalid    (axi_arvalid),
    .axi_arready    (axi_arready),
    .axi_rdata      (axi_rdata),
    .axi_rresp      (axi_rresp),
    .axi_rvalid     (axi_rvalid),
    .axi_rready     (axi_rready),

    .busy_vio       (axi_busy),
    .busy_cfg       (cfg_resync),
    .init_start     (init_start),
    .cfg_out        (),
    .status         (axi_status)
    );

  //===========================================
  // LEDs and Monitor ports
  //===========================================

  // LEDs

  // Divide core_clk for flashing LED
  always @(posedge core_clk)
    alive_tx <= alive_tx + 1;

  // Divide core_clk for flashing LED
  always @(posedge core_clk)
    alive_rx <= alive_rx + 1;


  assign leds[7] = alive_tx[23];
  assign leds[6] = alive_rx[23];
  assign leds[5] = mmcm_locked;
  assign leds[4] = iic_done;
  assign leds[3] = tx_aresetn;
  assign leds[2] = rx_aresetn;
  assign leds[1] = tx_sync;
  assign leds[0] = rx_sync;

  assign fan_on  = 1'b1;  // ensures the FPGA fan runs

  //===========================================
  // Vivado Logic Analyser modules
  //===========================================

  // create pulses for rd_req, write_req and cfg_req
  always @(posedge clk100)
  begin

    cfg_req_d1 <= config_change;
    cfg_req_p  <= (config_change ^ cfg_req_d1);

    wr_req_d1  <= write_req;
    wr_req_p   <= (write_req ^ wr_req_d1);

    rd_req_d1  <= read_req;
    rd_req_p   <= (read_req ^ rd_req_d1);
  end
  
  always @(posedge clk100)
  begin
    vio_mmcm_locked <= mmcm_locked;
    vio_iic_done    <= iic_done;
    vio_tx_sync     <= tx_sync;
    vio_rx_sync     <= rx_sync;
  end

  vio_0 vio_control (
    .clk            (clk100),         // input clk
    .probe_in0      (rd_data),        // input [31 : 0] probe_in0
    .probe_in1      (vio_mmcm_locked), // input [0 : 0] probe_in1
    .probe_in2      (vio_iic_done),   // input [0 : 0] probe_in2
    .probe_in3      (refclk_ok),      // input [0 : 0] probe_in3
    .probe_in4      (vio_tx_sync),    // input [0 : 0] probe_in4
    .probe_in5      (vio_rx_sync),    // input [0 : 0] probe_in5
    .probe_in6      (axi_status),     // input [7 : 0] probe_in6
    .probe_in7      (latency),        // input [11 : 0] probe_in7

    .probe_out0     (wr_data),        // output [31 : 0] probe_out0
    .probe_out1     (address),        // output [11 : 0] probe_out1
    .probe_out2     (core_axi_sel),   // output [0 : 0] probe_out2
    .probe_out3     (write_req),      // output [0 : 0] probe_out3
    .probe_out4     (read_req),       // output [0 : 0] probe_out4
    .probe_out5     (config_change),  // output [0 : 0] probe_out5
    .probe_out6     (config_sel[1:0]),// output [1 : 0] probe_out6
    .probe_out7     (rx_error_inject),// output [0 : 0] probe_out7
    .probe_out8     (vio_reset),      // output [0 : 0] probe_out8
    .probe_out9     (vio_resync),     // output [0 : 0] probe_out9
    .probe_out10    (sysref_disable), // output [0 : 0] probe_out10
    .probe_out11    (datamode),       // output [0 : 0] probe_out11
    .probe_out12    (ch0_step_up),    // output [0 : 0] probe_out12
    .probe_out13    (ch0_step_down),  // output [0 : 0] probe_out13
    .probe_out14    (ch1_step_up),    // output [0 : 0] probe_out14
    .probe_out15    (ch1_step_down),  // output [0 : 0] probe_out15
    .probe_out16    (calc_latency)    // output [0 : 0] probe_out16
  );


  //Clock domain crossing
  sync_block sync_sysref_disable (
    .clk             (core_clk),
    .data_in         (sysref_disable),
    .data_out        (sysref_disable_sync)
  );

  sync_block sync_datamode (
    .clk             (core_clk),
    .data_in         (datamode),
    .data_out        (datamode_sync)
  );

  sync_block sync_ch0_step_up (
    .clk             (core_clk),
    .data_in         (ch0_step_up),
    .data_out        (ch0_step_up_sync)
  );

  sync_block sync_ch0_step_down (
    .clk             (core_clk),
    .data_in         (ch0_step_down),
    .data_out        (ch0_step_down_sync)
  );

  sync_block sync_ch1_step_up (
    .clk             (core_clk),
    .data_in         (ch1_step_up),
    .data_out        (ch1_step_up_sync)
  );

  sync_block sync_ch1_step_down (
    .clk             (core_clk),
    .data_in         (ch1_step_down),
    .data_out        (ch1_step_down_sync)
  );

  sync_block sync_rx_error_inject (
    .clk             (core_clk),
    .data_in         (rx_error_inject),
    .data_out        (rx_error_inject_sync)
  );

  sync_block sync_vio_resync (
    .clk             (core_clk),
    .data_in         (vio_resync),
    .data_out        (vio_resync_sync)
  );

  //-------------------------
  // TX ILA
  //-------------------------

  ila_0 tx_ila (
    .clk      (core_clk),               // input clk

    .probe0   (tx0_tdata),              // input [31 : 0] probe0
    .probe1   (tx1_tdata),              // input [31 : 0] probe1
    .probe2   (tx2_tdata),              // input [31 : 0] probe2
    .probe3   (tx3_tdata),              // input [31 : 0] probe3
    .probe4   (tx_sysref),              // input [0 : 0] probe4
    .probe5   (vio_tx_sync),            // input [0 : 0] probe5
    .probe6   (tx_sof),                 // input [3 : 0] probe6
    .probe7   (tx_somf),                // input [3 : 0] probe7
    .probe8   (tx_tready),              // input [0 : 0] probe8
    //Data from GT
    .probe9   (gt0_txdata),             // input [31 : 0] probe9
    .probe10  (gt0_txcharisk),          // input [3 : 0] probe10
    .probe11  (gt1_txdata),             // input [31 : 0] probe11
    .probe12  (gt1_txcharisk),          // input [3 : 0] probe12
    .probe13  (gt2_txdata),             // input [31 : 0] probe13
    .probe14  (gt2_txcharisk),          // input [3 : 0] probe14
    .probe15  (gt3_txdata),             // input [31 : 0] probe15
    .probe16  (gt3_txcharisk)           // input [3 : 0] probe16
  );

  //-------------------------
  // RX ILA
  //-------------------------

  ila_1 rx_ila (
    .clk           (core_clk),             // input clk

    //Data output from RX JESD204
    .probe0        (rx_tdata[31:0]),          // input [31 : 0] probe0
    .probe1        (rx_tdata[63:32]),         // input [31 : 0] probe1
    .probe2        (rx_tdata[95:64]),         // input [31 : 0] probe2
    .probe3        (rx_tdata[127:96]),        // input [31 : 0] probe3

    .probe4        (rx_tvalid),               // input [0 : 0] probe4
    .probe5        (rx_sof),                  // input [3 : 0] probe5
    .probe6        (rx_eof),                  // input [3 : 0] probe6
    .probe7        (rx_frame_error),          // input [16 : 0] probe7
    .probe8        (vio_rx_sync),             // input [0 : 0] probe8
    .probe9        (rx0_error_count),         // input [31 : 0] probe9
    .probe10       (rx1_error_count),         // input [31 : 0] probe10
    .probe11       (rx0_errors),              // input [7 : 0] probe11
    .probe12       (rx1_errors),              // input [7 : 0] probe12
    //Data from GT
    .probe13       (gt0_rxdata),              // input [31 : 0] probe13
    .probe14       (gt0_rxcharisk),           // input [3 : 0] probe14
    .probe15       (gt0_rxdisperr),           // input [3 : 0] probe15
    .probe16       (gt0_rxnotintable),        // input [3 : 0] probe16
    .probe17       (gt1_rxdata),              // input [31 : 0] probe17
    .probe18       (gt1_rxcharisk),           // input [3 : 0] probe18
    .probe19       (gt1_rxdisperr),           // input [3 : 0] probe19
    .probe20       (gt1_rxnotintable),        // input [3 : 0] probe20
    .probe21       (gt2_rxdata),              // input [31 : 0] probe21
    .probe22       (gt2_rxcharisk),           // input [3 : 0] probe22
    .probe23       (gt2_rxdisperr),           // input [3 : 0] probe23
    .probe24       (gt2_rxnotintable),        // input [3 : 0] probe24
    .probe25       (gt3_rxdata),              // input [31 : 0] probe25
    .probe26       (gt3_rxcharisk),           // input [3 : 0] probe26
    .probe27       (gt3_rxdisperr),           // input [3 : 0] probe27
    .probe28       (gt3_rxnotintable)         // input [3 : 0] probe28
  );

endmodule
