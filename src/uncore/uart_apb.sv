///////////////////////////////////////////
// uart_apb.sv
//
// Written: David_Harris@hmc.edu 21 January 2021
// Modified: 
//
// Purpose: APB Interface to Universial Asynchronous Receiver/ Transmitter with FIFOs
//          Emulates interface of Texas Instruments PC165550D
//          Compatible with UART in Imperas Virtio model
// 
// Documentation: RISC-V System on Chip Design Chapter 15
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module uart_apb import cvw::*; #(parameter cvw_t P) (
  input  logic                PCLK, PRESETn,
  input  logic                PSEL,
  input  logic [2:0]          PADDR, 
  input  logic [P.XLEN-1:0]   PWDATA,
  input  logic [P.XLEN/8-1:0] PSTRB,
  input  logic                PWRITE,
  input  logic                PENABLE,
  output logic [P.XLEN-1:0]   PRDATA,
  output logic                PREADY,
  input  logic                SIN, DSRb, DCDb, CTSb, RIb,           // from E1A driver from RS232 interface
  output logic                SOUT, RTSb, DTRb,                     // to E1A driver to RS232 interface
  output logic                OUT1b, OUT2b, INTR, TXRDYb, RXRDYb);  // to CPU

  // UART interface signals
  logic [2:0]      entry;
  logic            MEMRb, MEMWb, memread, memwrite;
  logic [7:0]      Din, Dout;

  assign memwrite = PWRITE & PENABLE & PSEL;  // only write in access phase
  assign memread  = ~PWRITE & PENABLE & PSEL;  
  assign PREADY   = 1'b1; // CLINT never takes >1 cycle to respond
  assign entry    = PADDR[2:0];
  assign MEMRb    = ~memread;
  assign MEMWb    = ~memwrite;

  if (P.XLEN == 64) begin:uart
    always_comb begin
      PRDATA = {Dout, Dout, Dout, Dout, Dout, Dout, Dout, Dout};
      case (entry)
        3'b000: Din = PWDATA[7:0];
        3'b001: Din = PWDATA[15:8];
        3'b010: Din = PWDATA[23:16];
        3'b011: Din = PWDATA[31:24];
        3'b100: Din = PWDATA[39:32];
        3'b101: Din = PWDATA[47:40];
        3'b110: Din = PWDATA[55:48];
        3'b111: Din = PWDATA[63:56];
      endcase 
    end 
  end else begin:uart // 32-bit
    always_comb begin
      PRDATA = {Dout, Dout, Dout, Dout};
      case (entry[1:0])
        2'b00: Din = PWDATA[7:0];
        2'b01: Din = PWDATA[15:8];
        2'b10: Din = PWDATA[23:16];
        2'b11: Din = PWDATA[31:24];
      endcase
    end
  end
  
  logic BAUDOUTb;  // loop tx clock BAUDOUTb back to rx clock RCLK
  uartPC16550D #(P.UART_PRESCALE) u(  
    // Processor Interface
    .PCLK, .PRESETn,
    .A(entry), .Din, 
    .Dout,
    .MEMRb, .MEMWb, 
    .INTR, .TXRDYb, .RXRDYb,
    // Clocks
    .BAUDOUTb, .RCLK(BAUDOUTb),
    // E1A Driver
    .SIN, .DSRb, .DCDb, .CTSb, .RIb,
    .SOUT, .RTSb, .DTRb, .OUT1b, .OUT2b
);

endmodule
