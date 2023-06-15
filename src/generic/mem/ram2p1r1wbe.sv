///////////////////////////////////////////
// 2 port sram.
//
// Written: ross1728@gmail.com May 3, 2021
//          Two port SRAM 1 read port and 1 write port.
//          When clk rises Addr and LineWriteData are sampled.
//          Following the clk edge read data is output from the sampled Addr.
//          Write
// Modified: james.stine@okstate.edu Feb 1, 2023
//           Integration of memories 
//
// Purpose: Storage and read/write access to data cache data, tag valid, dirty, and replacement.
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

// WIDTH is number of bits in one "word" of the memory, DEPTH is number of such words

module ram2p1r1wbe import cvw::*; #(parameter cvw_t P,
                                    parameter DEPTH=1024, WIDTH=68) (
  input  logic                     clk,
  input  logic                     ce1, ce2,
  input  logic [$clog2(DEPTH)-1:0] ra1,
  input  logic [WIDTH-1:0]         wd2,
  input  logic [$clog2(DEPTH)-1:0] wa2,
  input  logic                     we2,
  input  logic [(WIDTH-1)/8:0]     bwe2,
  output logic [WIDTH-1:0]         rd1
);

  logic [WIDTH-1:0]                mem[DEPTH-1:0];
  localparam                      SRAMWIDTH = 32;
  localparam                      SRAMNUMSETS = SRAMWIDTH/WIDTH;      

  // ***************************************************************************
  // TRUE Smem macro
  // ***************************************************************************

  if ((P.USE_SRAM == 1) & (WIDTH == 68) & (DEPTH == 1024)) begin
    
    ram2p1r1wbe_1024x68 memory1(.CLKA(clk), .CLKB(clk), 
      .CEBA(~ce1), .CEBB(~ce2),
      .WEBA('0), .WEBB(~we2),            
      .AA(ra1), .AB(wa2),
      .DA('0),
      .DB(wd2),
      .BWEBA('0), .BWEBB('1),
      .QA(rd1),
      .QB());

  end else if ((P.USE_SRAM == 1) & (WIDTH == 36) & (DEPTH == 1024)) begin
    
    ram2p1r1wbe_1024x36 memory1(.CLKA(clk), .CLKB(clk), 
      .CEBA(~ce1), .CEBB(~ce2),
      .WEBA('0), .WEBB(~we2),            
      .AA(ra1), .AB(wa2),
      .DA('0),
      .DB(wd2),
      .BWEBA('0), .BWEBB('1),
      .QA(rd1),
      .QB());      

  end else if ((P.USE_SRAM == 1) & (WIDTH == 2) & (DEPTH == 1024)) begin

    logic [SRAMWIDTH-1:0]     SRAMReadData;      
    logic [SRAMWIDTH-1:0]     SRAMWriteData;      
    logic [SRAMWIDTH-1:0]     RD1Sets[SRAMNUMSETS-1:0];
    logic [SRAMNUMSETS-1:0]   SRAMBitMaskPre;      
    logic [SRAMWIDTH-1:0]     SRAMBitMask;      
    logic [$clog2(DEPTH)-1:0] RA1Q;
    
    onehotdecoder #($clog2(SRAMNUMSETS)) oh1(wa2[$clog2(SRAMNUMSETS)-1:0], SRAMBitMaskPre);      
    genvar                    index;
    for (index = 0; index < SRAMNUMSETS; index++) begin:readdatalinesetsmux
      assign RD1Sets[index] = SRAMReadData[(index*WIDTH)+WIDTH-1 : (index*WIDTH)];   
      assign SRAMWriteData[index*2+1:index*2] = wd2;
      assign SRAMBitMask[index*2+1:index*2] = {2{SRAMBitMaskPre[index]}};      
    end
    flopen #($clog2(DEPTH)) mem_reg1 (clk, ce1, ra1, RA1Q);      
    assign rd1 = RD1Sets[RA1Q[$clog2(SRAMWIDTH)-1:0]];      
    ram2p1r1wbe_64x32 memory2(.CLKA(clk), .CLKB(clk), 
      .CEBA(~ce1), .CEBB(~ce2),
      .WEBA('0), .WEBB(~we2),            
      .AA(ra1[$clog2(DEPTH)-1:$clog2(SRAMNUMSETS)]), 
      .AB(wa2[$clog2(DEPTH)-1:$clog2(SRAMNUMSETS)]),
      .DA('0),
      .DB(SRAMWriteData),
      .BWEBA('0), .BWEBB(SRAMBitMask),
      .QA(SRAMReadData),
      .QB());

  end else begin
    
    // ***************************************************************************
    // READ first SRAM model
    // ***************************************************************************
    integer i;
    
    // Read
    logic [$clog2(DEPTH)-1:0] ra1d;
    flopen #($clog2(DEPTH)) adrreg(clk, ce1, ra1, ra1d);
    assign rd1 = mem[ra1d];

    /*      // Read
     always_ff @(posedge clk) 
     if(ce1) rd1 <= #1 mem[ra1]; */
    
    // Write divided into part for bytes and part for extra msbs
    // coverage off     
    //   when byte write enables are tied high, the last IF is always taken
    if(WIDTH >= 8) 
      always @(posedge clk) 
        if (ce2 & we2) 
          for(i = 0; i < WIDTH/8; i++) 
            if(bwe2[i]) mem[wa2][i*8 +: 8] <= #1 wd2[i*8 +: 8];
    // coverage on
  
    if (WIDTH%8 != 0) // handle msbs if width not a multiple of 8
      always @(posedge clk) 
        if (ce2 & we2 & bwe2[WIDTH/8])
          mem[wa2][WIDTH-1:WIDTH-WIDTH%8] <= #1 wd2[WIDTH-1:WIDTH-WIDTH%8];
  end
  
endmodule
