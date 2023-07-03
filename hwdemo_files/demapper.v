//---------------------------------------------------------------------
// Title   : Rx Lane data Demapper
// Project : JESD204
//---------------------------------------------------------------------
// File    : demapper.v
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
module demapper(
  input             rx_aclk,
  input             rx_aresetn,

  //AXI-S Lane 0 from JESD204 Rx core
  input  [31:0]     rx0_tdata,
  
  //AXI-S Lane 1 from JESD204 Rx core
  input  [31:0]     rx1_tdata,

  //AXI-S Lane 2 from JESD204 Rx core
  input  [31:0]     rx2_tdata,

  //AXI-S Lane 3 from JESD204 Rx core
  input  [31:0]     rx3_tdata,

  input             rx_tvalid,
  
  // Framing mar    kers
  input  [3:0]      rx_sof,
  input  [3:0]      rx_eof,

  // "Channel" data out - 4 16-bit 'samples' per clock
  output reg        rx_dvalid,
  output reg [63:0] rx_data0,
  output reg [63:0] rx_data1
  );


  reg[31:0] lane0;
  reg[31:0] lane1;
  reg[31:0] lane2;
  reg[31:0] lane3;

  reg       lane_valid;


  //===========================================
  // Rx Sample Demapping
  //
  // - based on eg NXP DAC1628 LMF = 421 mode
  //   to match the Tx mapping mode for this demo
  //===========================================

  always @(posedge rx_aclk)
  begin

    if (rx_aresetn == 1'b0) begin
      rx_dvalid  <= 1'b0;
      rx_data0   <= 64'b0;
      rx_data1   <= 64'b0;
    end

    else begin

      if (rx_tvalid) begin
        lane0 <= rx0_tdata;
        lane1 <= rx1_tdata;
        lane2 <= rx2_tdata;
        lane3 <= rx3_tdata;
      end

      lane_valid <= rx_tvalid;

      if (lane_valid) begin
        rx_dvalid <= 1'b1;
        rx_data0  <= {lane1, lane0};
        rx_data1  <= {lane3, lane2};
      end
      else begin
        rx_dvalid <= 1'b0;
        rx_data0  <= 64'b0;
        rx_data1  <= 64'b0;
      end

    end

  end

endmodule
