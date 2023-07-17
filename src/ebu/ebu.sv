///////////////////////////////////////////
// abhmulticontroller
//
// Written: Ross Thompson ross1728@gmail.com
// Created: August 29, 2022
// Modified: 18 January 2023
//
// Purpose: AHB multi controller interface to merge LSU and IFU controls.
//          See ARM_HIH0033A_AMBA_AHB-Lite_SPEC 1.0
//          Arbitrates requests from instruction and data streams
//          Connects core to peripherals and I/O pins on SOC
//          Bus width presently matches XLEN
// 
// Documentation: RISC-V System on Chip Design Chapter 6 (Figures 6.25 and 6.26)
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

module ebu #(parameter XLEN, PA_BITS, AHBW)(
  input  logic                clk, reset,
  // Signals from IFU
  input  logic [1:0]          IFUHTRANS, // IFU AHB transaction request
  input  logic [2:0]          IFUHSIZE,  // IFU AHB transaction size
  input  logic [2:0]          IFUHBURST, // IFU AHB burst length
  input  logic [PA_BITS-1:0]  IFUHADDR,  // IFU AHB address
  output logic                IFUHREADY, // AHB peripheral ready gated by possible non-grant
  // Signals from LSU
  input  logic [1:0]          LSUHTRANS, // LSU AHB transaction request
  input  logic                LSUHWRITE, // LSU AHB transaction direction. 1: write, 0: read
  input  logic [2:0]          LSUHSIZE,  // LSU AHB size
  input  logic [2:0]          LSUHBURST, // LSU AHB burst length
  input  logic [PA_BITS-1:0]  LSUHADDR,  // LSU AHB address
  input  logic [XLEN-1:0]     LSUHWDATA, // initially support AHBW = XLEN
  input  logic [XLEN/8-1:0]   LSUHWSTRB, // AHB byte mask
  output logic                LSUHREADY, // AHB peripheral. Never gated as LSU always has priority

  // AHB-Lite external signals
  output logic                HCLK, HRESETn, 
  input  logic                HREADY,    // AHB peripheral ready
  input  logic                HRESP,     // AHB peripheral response. 0: OK 1: Error
  output logic [PA_BITS-1:0]  HADDR,     // AHB address to peripheral after arbitration
  output logic [AHBW-1:0]     HWDATA,    // AHB Write data after arbitration
  output logic [XLEN/8-1:0]   HWSTRB,    // AHB byte write enables after arbitration
  output logic                HWRITE,    // AHB transaction direction after arbitration
  output logic [2:0]          HSIZE,     // AHB transaction size after arbitration
  output logic [2:0]          HBURST,    // AHB burst length after arbitration
  output logic [3:0]          HPROT,     // AHB protection.  Wally does not use
  output logic [1:0]          HTRANS,    // AHB transaction request after arbitration
  output logic                HMASTLOCK  // AHB master lock.  Wally does not use
);

  logic                       LSUDisable;
  logic                       LSUSelect;
  logic                       IFUSave;
  logic                       IFURestore;
  logic                       IFUDisable;
  logic                       IFUSelect;

  logic [PA_BITS-1:0]         IFUHADDROut;
  logic [1:0]                 IFUHTRANSOut;
  logic [2:0]                 IFUHBURSTOut;
  logic [2:0]                 IFUHSIZEOut;
  logic                       IFUHWRITEOut;
  
  logic [PA_BITS-1:0]         LSUHADDROut;
  logic [1:0]                 LSUHTRANSOut;
  logic [2:0]                 LSUHBURSTOut;
  logic [2:0]                 LSUHSIZEOut;
  logic                       LSUHWRITEOut;

  logic                       IFUReq;
  logic                       LSUReq;

  assign HCLK = clk;
  assign HRESETn = ~reset;

  // if two requests come in at once pick one to select and save the others Address phase
  // inputs.  Abritration scheme is LSU always goes first.

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // input stages and muxing for IFU and LSU
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  controllerinput #(PA_BITS) IFUInput(.HCLK, .HRESETn, .Save(IFUSave), .Restore(IFURestore), .Disable(IFUDisable),
    .Request(IFUReq),
    .HWRITEIn(1'b0), .HSIZEIn(IFUHSIZE), .HBURSTIn(IFUHBURST), .HTRANSIn(IFUHTRANS), .HADDRIn(IFUHADDR),
    .HWRITEOut(IFUHWRITEOut), .HSIZEOut(IFUHSIZEOut), .HBURSTOut(IFUHBURSTOut), .HREADYOut(IFUHREADY),
    .HTRANSOut(IFUHTRANSOut), .HADDROut(IFUHADDROut), .HREADYIn(HREADY));

  // LSU always has priority so there should never be a need to save and restore the address phase inputs.
  controllerinput #(PA_BITS, 0) LSUInput(.HCLK, .HRESETn, .Save(1'b0), .Restore(1'b0), .Disable(LSUDisable),
    .Request(LSUReq),
    .HWRITEIn(LSUHWRITE), .HSIZEIn(LSUHSIZE), .HBURSTIn(LSUHBURST), .HTRANSIn(LSUHTRANS), .HADDRIn(LSUHADDR), .HREADYOut(LSUHREADY),
    .HWRITEOut(LSUHWRITEOut), .HSIZEOut(LSUHSIZEOut), .HBURSTOut(LSUHBURSTOut),
    .HTRANSOut(LSUHTRANSOut), .HADDROut(LSUHADDROut), .HREADYIn(HREADY));

  // output mux //*** switch to structural implementation
  assign HADDR = LSUSelect ? LSUHADDROut : IFUSelect ? IFUHADDROut : '0;
  assign HSIZE = LSUSelect ? LSUHSIZEOut : IFUSelect ? IFUHSIZEOut: '0; 
  assign HBURST = LSUSelect ? LSUHBURSTOut : IFUSelect ? IFUHBURSTOut : '0; // If doing memory accesses, use LSUburst, else use Instruction burst.
  assign HTRANS = LSUSelect ? LSUHTRANSOut : IFUSelect ? IFUHTRANSOut: '0; // SEQ if not first read or write, NONSEQ if first read or write, IDLE otherwise
  assign HWRITE = LSUSelect ? LSUHWRITEOut : IFUSelect ? 1'b0 : '0;
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HMASTLOCK = 0; // no locking supported

  // data phase muxing.  This would be a mux if IFU wrote data.
  assign HWDATA = LSUHWDATA;
  assign HWSTRB = LSUHWSTRB;
  // HRDATA is sent to all controllers at the core level.

  ebufsmarb ebufsmarb(.HCLK, .HRESETn, .HBURST, .HREADY, .LSUReq, .IFUReq, .IFUSave,
          .IFURestore, .IFUDisable, .IFUSelect, .LSUDisable, .LSUSelect);
  
endmodule


