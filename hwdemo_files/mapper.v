//---------------------------------------------------------------------
// Title   : Tx Lane Data Mapper
// Project : JESD204
//---------------------------------------------------------------------
// File    : mapper.v
// Author  : Xilinx
//---------------------------------------------------------------------
// Description:
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
//----------------------------------------------------------------------------
module mapper(
  input             tx_aclk,
  input             tx_aresetn,

  // Channel 0 data - 4 16-bit 'samples' per clock
  input [63:0]      tx_data0,
  // Channel 1 data - 4 16-bit 'samples' per clock
  input [63:0]      tx_data1,

  input             tx_tready,
  
  // AXI-S Lane 0 to JESD204 Tx core
  output reg [31:0] tx0_tdata,

  // AXI-S Lane 1 to JESD204 Tx core
  output reg [31:0] tx1_tdata,

  // AXI-S Lane 2 to JESD204 Tx core
  output reg [31:0] tx2_tdata,
  
  // AXI-S Lane 3 to JESD204 Tx core
  output reg [31:0] tx3_tdata
  );


  //===========================================
  // Tx Sample Mapping - LMF = 421 mode eg NXP DAC1628
  //===========================================

  always @(posedge tx_aclk)
  begin

    if (tx_aresetn == 1'b0) begin

      tx0_tdata  <= 32'b0;
      tx1_tdata  <= 32'b0;
      tx2_tdata  <= 32'b0;
      tx3_tdata  <= 32'b0;

    end

    else begin
      
      if (tx_tready) begin
        tx0_tdata  <= tx_data0[31:0];      // Lane 0
        tx1_tdata  <= tx_data0[63:32];     // Lane 1
        tx2_tdata  <= tx_data1[31:0];      // Lane 2
        tx3_tdata  <= tx_data1[63:32];     // Lane 3
      end
      else begin
        tx0_tdata  <= 64'b0;
        tx1_tdata  <= 64'b0;
        tx2_tdata  <= 64'b0;
        tx3_tdata  <= 64'b0;
      end

    end

  end

endmodule
