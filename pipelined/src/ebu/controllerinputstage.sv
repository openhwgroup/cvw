///////////////////////////////////////////
// controller input stage
//
// Written: Ross Thompson August 31, 2022
// ross1728@gmail.com
// Modified: 
//
// Purpose: AHB multi controller interface to merge LSU and IFU controls.
//          See ARM_HIH0033A_AMBA_AHB-Lite_SPEC 1.0
//          Arbitrates requests from instruction and data streams
//          Connects core to peripherals and I/O pins on SOC
//          Bus width presently matches XLEN
//          Anticipate replacing this with an AXI bus interface to communicate with FPGA DRAM/Flash controllers
// 
// A component of the CORE-V Wally configurable RISC-V project.
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

`include "wally-config.vh"

module controllerinputstage #(parameter SAVE_ENABLED = 1)
  (input logic HCLK,
   input logic                 HRESETn,
   input logic                 Save, Restore, Disable,
   output logic                Request,
   // controller input
   input logic                 HWRITEIn,
   input logic [2:0]           HSIZEIn,
   input logic [2:0]           HBURSTIn,
   input logic [1:0]           HTRANSIn,
   input logic [`PA_BITS-1:0]  HADDRIn,
   output logic                HREADYOut,
   // controller output
   output logic                HWRITEOut,
   output logic [2:0]          HSIZEOut,
   output logic [2:0]          HBURSTOut,
   output logic [1:0]          HTRANSOut,
   output logic [`PA_BITS-1:0] HADDROut,
   input logic                 HREADYIn
   );

  logic                        HWRITESave;
  logic [2:0]                  HSIZESave;
  logic [2:0]                  HBURSTSave;
  logic [1:0]                  HTRANSSave;
  logic [`PA_BITS-1:0]         HADDRSave;

  if (SAVE_ENABLED) begin
  flopenr #(1+3+3+2+`PA_BITS) SaveReg(HCLK, ~HRESETn, Save,
                                      {HWRITEIn, HSIZEIn, HBURSTIn, HTRANSIn, HADDRIn}, 
                                      {HWRITESave, HSIZESave, HBURSTSave, HTRANSSave, HADDRSave});
  mux2 #(1+3+3+2+`PA_BITS) RestorMux({HWRITEIn, HSIZEIn, HBURSTIn, HTRANSIn, HADDRIn}, 
                                     {HWRITESave, HSIZESave, HBURSTSave, HTRANSSave, HADDRSave},
                                     Restore,
                                     {HWRITEOut, HSIZEOut, HBURSTOut, HTRANSOut, HADDROut});
  end else begin
    assign HWRITEOut = HWRITEIn;
    assign HSIZEOut = HSIZEIn;
    assign HBURSTOut = HBURSTIn;
    assign HTRANSOut = HTRANSIn;
    assign HADDROut = HADDRIn;
  end

  assign Request = HTRANSOut != 2'b00;
  assign HREADYOut = HREADYIn & ~Disable;

endmodule
  
  
   
