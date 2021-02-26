///////////////////////////////////////////
// uart.sv
//
// Written: David_Harris@hmc.edu 21 January 2021
// Modified: 
//
// Purpose: Interface to Universial Asynchronous Receiver/ Transmitter with FIFOs
//          Emulates interface of Texas Instruments PC165550D
//          Compatible with UART in Imperas Virtio model ***
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module uart (
  input  logic             HCLK, HRESETn, 
  input  logic [1:0]       MemRWuart,
  input  logic [2:0]       HADDR, 
  input  logic [`XLEN-1:0] HWDATA,
  output logic [`XLEN-1:0] HREADUART,
  output logic             HRESPUART, HREADYUART,
  input  logic             SIN, DSRb, DCDb, CTSb, RIb,    // from E1A driver from RS232 interface
  output logic             SOUT, RTSb, DTRb, // to E1A driver to RS232 interface
  output logic             OUT1b, OUT2b, INTR, TXRDYb, RXRDYb);         // to CPU

  // UART interface signals
  logic [2:0]      A;
  logic            MEMRb, MEMWb;
  logic [7:0]      Din, Dout;

  // rename processor interface signals to match PC16550D and provide one-byte interface
  assign MEMRb = ~MemRWuart[1];
  assign MEMWb = ~MemRWuart[0];
  assign A = HADDR[2:0];
  assign HRESPUART = 0; // OK
  //assign HREADYUART = 1; // Respond immediately
  always_ff @(posedge HCLK) // delay response to data cycle
    HREADYUART <= ~MEMRb | ~MEMWb;

  generate
    if (`XLEN == 64) begin
      always @(posedge HCLK) begin
        HREADUART = {Dout, Dout, Dout, Dout, Dout, Dout, Dout, Dout};
        case (HADDR)
          3'b000: Din = HWDATA[7:0];
          3'b001: Din = HWDATA[15:8];
          3'b010: Din = HWDATA[23:16];
          3'b011: Din = HWDATA[31:24];
          3'b100: Din = HWDATA[39:32];
          3'b101: Din = HWDATA[47:40];
          3'b110: Din = HWDATA[55:48];
          3'b111: Din = HWDATA[63:56];
        endcase 
      end 
    end else begin // 32-bit
      always @(posedge HCLK) begin
        HREADUART = {Dout, Dout, Dout, Dout};
        case (HADDR[1:0])
          2'b00: Din = HWDATA[7:0];
          2'b01: Din = HWDATA[15:8];
          2'b10: Din = HWDATA[23:16];
          2'b11: Din = HWDATA[31:24];
        endcase
      end
    end
  endgenerate
  
  logic BAUDOUTb;  // loop tx clock BAUDOUTb back to rx clock RCLK
  // *** make sure reads don't occur on UART unless fully selected because they could change state.  This applies to all peripherals
  uartPC16550D u(.RCLK(BAUDOUTb), .*);

endmodule

