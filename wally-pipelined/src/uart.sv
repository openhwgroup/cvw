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
  input  logic            clk, reset, 
  input  logic [1:0]      MemRWuartM,
//  input  logic [7:0]      ByteMaskM,
  input  logic [`XLEN-1:0] AdrM, 
  input  logic [`XLEN-1:0] MaskedWriteDataM,
  output logic [`XLEN-1:0] RdUARTM,
  input  logic            SIN, DSRb, DCDb, CTSb, RIb,    // from E1A driver from RS232 interface
  output logic            SOUT, RTSb, DTRb, // to E1A driver to RS232 interface
  output logic            OUT1b, OUT2b, INTR, TXRDYb, RXRDYb);         // to CPU

  // UART interface signals
  logic [2:0]      A;
  logic            MEMRb, MEMWb;
  logic [7:0]      Din, Dout;

  // rename processor interface signals to match PC16550D and provide one-byte interface
  assign MEMRb = ~MemRWuartM[1];
  assign MEMWb = ~MemRWuartM[0];
  assign A = AdrM[2:0];

  generate
    if (`XLEN == 64) begin
      always_comb begin
        RdUARTM = {Dout, Dout, Dout, Dout, Dout, Dout, Dout, Dout};
        case (AdrM[2:0])
          3'b000: Din = MaskedWriteDataM[7:0];
          3'b001: Din = MaskedWriteDataM[15:8];
          3'b010: Din = MaskedWriteDataM[23:16];
          3'b011: Din = MaskedWriteDataM[31:24];
          3'b100: Din = MaskedWriteDataM[39:32];
          3'b101: Din = MaskedWriteDataM[47:40];
          3'b110: Din = MaskedWriteDataM[55:48];
          3'b111: Din = MaskedWriteDataM[63:56];
        endcase 
      end 
    end else begin // 32-bit
      always_comb begin
        RdUARTM = {Dout, Dout, Dout, Dout};
        case (AdrM[1:0])
          2'b00: Din = MaskedWriteDataM[7:0];
          2'b01: Din = MaskedWriteDataM[15:8];
          2'b10: Din = MaskedWriteDataM[23:16];
          2'b11: Din = MaskedWriteDataM[31:24];
        endcase
      end
    end
  endgenerate
  
  logic BAUDOUTb;  // loop tx clock BAUDOUTb back to rx clock RCLK
  uartPC16550D u(.RCLK(BAUDOUTb), .*);

endmodule

