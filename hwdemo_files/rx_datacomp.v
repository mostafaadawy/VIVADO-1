//---------------------------------------------------------------------
// Title   : Rx Data Checker
// Project : JESD204
//---------------------------------------------------------------------
// File    : rx_datacomp.v
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
module rx_datacomp(
  input             clk,
  input             reset,
  input             enable,

  input             rx_dvalid,
  input [63:0]      rx_data,

  output reg [7:0]  errors,
  output reg [31:0] error_count,
  output reg        started
  );


  reg[10:0] startup;

  reg[ 7:0] byte_a;
  reg[ 7:0] byte_b;
  reg[ 7:0] byte_c;
  reg[ 7:0] byte_d;


  always @(posedge clk)
  begin

    if (reset == 1'b1) begin

      startup     <= 11'b0;
      started     <= 1'b0;

      byte_a      <= 8'h00;
      byte_b      <= 8'h00;
      byte_c      <= 8'h00;
      byte_d      <= 8'h00;

      errors      <= 8'b0;
      error_count <= 32'b0;

    end

    else begin

      // If enabled and data valid, compare to expected sequence
      if ((enable == 1'b1) && (rx_dvalid == 1'b1)) begin

        // counter to delay comparision start (allow for Tx-Rx latency on mode switch)
        if (startup[10] == 1'b0)
          startup <= startup + 1;

      end

      else
        startup <= 11'b0;


      if (startup[10] == 1'b1) begin

        // Transmit data format is :
        // data_out <=  {byte_d, byte_c, byte_b,  byte_a, byte_b, byte_d, byte_c, byte_a};   // Digital
        //
        // and data pattern is :
        // 4 8-bit byte values, incremented by different steps
        //    byte_a <= byte_a + 1;
        //    byte_b <= byte_b + 2;
        //    byte_c <= byte_c + 3;
        //    byte_d <= byte_d + 8;

        // Grab 1st valid data to start reference data pattern
        if (started == 1'b0) begin
          started <= 1'b1;
          byte_a  <= rx_data[ 7:0]  + 1;      // Byte A increments by 1
          byte_c  <= rx_data[15:8]  + 3;      // Byte C increments by 3
          byte_d  <= rx_data[23:16] + 8;      // Byte D increments by 8
          byte_b  <= rx_data[31:24] + 2;      // Byte B increments by 2
        end
        else begin

          // Compare incoming data to reference pattern
          if (rx_data[7:0] != byte_a)
            errors[0] <= 1'b1;
          else
            errors[0] <= 1'b0;

          if (rx_data[15:8] != byte_c)
            errors[1] <= 1'b1;
          else
            errors[1] <= 1'b0;

          if (rx_data[23:16] != byte_d)
            errors[2] <= 1'b1;
          else
            errors[2] <= 1'b0;

          if (rx_data[31:24] != byte_b)
            errors[3] <= 1'b1;
          else
            errors[3] <= 1'b0;

          if (rx_data[39:32] != byte_a)
            errors[4] <= 1'b1;
          else
            errors[4] <= 1'b0;

          if (rx_data[47:40] != byte_b)
            errors[5] <= 1'b1;
          else
            errors[5] <= 1'b0;

          if (rx_data[55:48] != byte_c)
            errors[6] <= 1'b1;
          else
            errors[6] <= 1'b0;

          if (rx_data[63:56] != byte_d)
            errors[7] <= 1'b1;
          else
            errors[7] <= 1'b0;

          if (errors[0] | errors[1] | errors [2] | errors[3] | errors[4] | errors[5] | errors[6] | errors[7])
            error_count <= error_count + 1;


          // Maintain the reference pattern
          byte_a  <= byte_a + 1;      // Byte A increments by 1
          byte_b  <= byte_b + 2;      // Byte C increments by 2
          byte_c  <= byte_c + 3;      // Byte D increments by 3
          byte_d  <= byte_d + 8;      // Byte B increments by 8

        end
      end
      else begin
        started     <=  1'b0;
        errors      <=  8'b0;
        error_count <= 32'b0;
      end

    end


  end

endmodule
