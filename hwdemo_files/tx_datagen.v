//---------------------------------------------------------------------
// Title   : Tx data generator
// Project : JESD204
//---------------------------------------------------------------------
// File    :
// Author  : Xilinx
//---------------------------------------------------------------------
// Description:
//
//---------------------------------------------------------------------
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
module tx_datagen(
  input            clk,
  input            reset,
  input            mode,             // 0 = Digital 1 = "Analog" (Sine)
  input            step_u,           // increase "analog" frequency step
  input            step_d,           // decrease "analog" frequency step
  output reg[ 7:0] step_size,        // Current "Analog" step size
  output reg[63:0] data_out          // data output
  );

  // Look Up table (1024x16) 16 bit sine wave (unsigned)
 `include "sine16bit.vh"

  wire [15:0] sine_lookup [1023:0];

  reg[2:0] step_u_d;
  reg[2:0] step_d_d;
  reg step_up;
  reg step_dn;

  reg[2:0] step;
  reg[7:0] stepsize;

  integer index0;
  integer index1;
  integer index2;
  integer index3;

  reg[15:0] sine0;
  reg[15:0] sine1;
  reg[15:0] sine2;
  reg[15:0] sine3;

  reg[ 7:0] byte_a;
  reg[ 7:0] byte_b;
  reg[ 7:0] byte_c;
  reg[ 7:0] byte_d;


  always @(posedge clk)
  begin

    if (reset == 1'b1) begin

      step_u_d   <= 3'b000;
      step_d_d   <= 3'b000;
      step_up    <= 1'b0;
      step_dn    <= 1'b0;
      step       <= 3'b010;
      stepsize   <= 8'd4;

      index0     <= 0;
      index1     <= 4;
      index2     <= 8;
      index3     <= 12;

      sine0      <= 16'b0;
      sine1      <= 16'b0;
      sine2      <= 16'b0;
      sine3      <= 16'b0;

      byte_a     <= 8'h00;
      byte_b     <= 8'hA0;
      byte_c     <= 8'hB0;
      byte_d     <= 8'hC0;

    end

    else begin

      //===============================================
      // "Analog" (Sine Wave) data generation
      //===============================================

      // Frequency Step Up/Down inputs are asynchronous Toggle inputs from VIO
      // Resync and edge detect to create a single pulse in clk domain

      step_u_d <= {step_u_d[1], step_u_d[0], step_u};
      step_up  <= step_u_d[2] ^ step_u_d[1];

      step_d_d <= {step_d_d[1], step_d_d[0], step_d};
      step_dn  <= step_d_d[2] ^ step_d_d[1];


      // Increment/Decrement the step size
      if (step_up)
        step <= step + 1;
      else if (step_dn)
        step <= step - 1;

      case (step)
        3'b000: stepsize <=   1;
        3'b001: stepsize <=   2;
        3'b010: stepsize <=   4;
        3'b011: stepsize <=   8;
        3'b100: stepsize <=  16;
        3'b101: stepsize <=  32;
        3'b110: stepsize <=  64;
        3'b111: stepsize <= 128;
      endcase

      step_size <= stepsize;

      index0 <= index0 + stepsize;
      index1 <= index1 + stepsize;
      index2 <= index2 + stepsize;
      index3 <= index3 + stepsize;

      // Generate 4 16-bit data samples per clock cycle
      sine0 <= sine_lookup[index0];
      sine1 <= sine_lookup[index1];
      sine2 <= sine_lookup[index2];
      sine3 <= sine_lookup[index3];


       //===============================================
      // Simple Digital digi Pattern generation
      //===============================================

      // 4 8-bit byte values, incremented by different steps
      byte_a <= byte_a + 1;
      byte_b <= byte_b + 2;
      byte_c <= byte_c + 3;
      byte_d <= byte_d + 8;


      //===============================================
      // Data Output
      //===============================================

      if (mode == 1'b0)
        data_out <=  {byte_d, byte_c, byte_b,  byte_a, byte_b, byte_d, byte_c, byte_a};   // Digital
      else
        data_out <=  {sine3, sine2, sine1, sine0};   // "Analog"


    end

  end

endmodule
