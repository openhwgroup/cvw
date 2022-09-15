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
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module controllerinputstage
  (input logic HCLK,
   input logic                 HRESETn,
   input logic                 Save, Restore, Disable,
   output logic                Request, Active,
   // controller input
   input logic                 HWRITEin,
   input logic [2:0]           HSIZEin,
   input logic [2:0]           HBURSTin,
   input logic [1:0]           HTRANSin,
   input logic [`PA_BITS-1:0]  HADDRin,
   output logic                HREADYOut,
   // controller output
   output logic                HWRITEOut,
   output logic [2:0]          HSIZEOut,
   output logic [2:0]          HBURSTOut,
   output logic [1:0]          HTRANSOut,
   output logic [`PA_BITS-1:0] HADDROut,
   input logic                 HREADYin
   );

  logic                        HWRITESave;
  logic [2:0]                  HSIZESave;
  logic [2:0]                  HBURSTSave;
  logic [1:0]                  HTRANSSave;
  logic [`PA_BITS-1:0]         HADDRSave;

  flopenr #(1+3+3+2+`PA_BITS) SaveReg(HCLK, ~HRESETn, Save,
                                      {HWRITEin, HSIZEin, HBURSTin, HTRANSin, HADDRin}, 
                                      {HWRITESave, HSIZESave, HBURSTSave, HTRANSSave, HADDRSave});
  mux2 #(1+3+3+2+`PA_BITS) RestorMux({HWRITEin, HSIZEin, HBURSTin, HTRANSin, HADDRin}, 
                                     {HWRITESave, HSIZESave, HBURSTSave, HTRANSSave, HADDRSave},
                                     Restore,
                                     {HWRITEOut, HSIZEOut, HBURSTOut, HTRANSOut, HADDROut});

  assign Request = HTRANSOut != 2'b00;
  assign HREADYOut = HREADYin & ~Disable;
  assign Active = Request & HREADYOut;

endmodule
  
  
   
