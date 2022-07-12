///////////////////////////////////////////
// srt.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, Cedar Turek
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
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

module srtpreproc (
  input  logic [`NF:0] XManE, YManE,
  output logic [`DIVLEN-1:0] X,
  output logic [`DIVLEN-1:0] Dpreproc,
  output logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  output logic [`DURLEN-1:0] Dur
);
  // logic  [`XLEN-1:0] PosA, PosB;
  // logic  [`DIVLEN-1:0] ExtraA, ExtraB, PreprocA, PreprocB, PreprocX, PreprocY;
  logic  [`DIVLEN-1:0] PreprocA, PreprocX;
  logic  [`DIVLEN-1:0] PreprocB, PreprocY;

  // assign PosA = (Signed & SrcA[`XLEN - 1]) ? -SrcA : SrcA;
  // assign PosB = (Signed & SrcB[`XLEN - 1]) ? -SrcB : SrcB;
  // lzc #(`XLEN) lzcA (PosA, zeroCntA);
  // lzc #(`XLEN) lzcB (PosB, zeroCntB);

  // ***can probably merge X LZC with conversion
  // cout the number of leading zeros
  lzc #(`NF+1) lzcA (XManE, XZeroCnt);
  lzc #(`NF+1) lzcB (YManE, YZeroCnt);

  // assign ExtraA = {PosA, {`DIVLEN-`XLEN{1'b0}}};
  // assign ExtraB = {PosB, {`DIVLEN-`XLEN{1'b0}}};

  // assign PreprocA = ExtraA << zeroCntA;
  // assign PreprocB = ExtraB << (zeroCntB + 1);
  assign PreprocX = {XManE[`NF-1:0]<<XZeroCnt, {`DIVLEN-`NF{1'b0}}};
  assign PreprocY = {YManE[`NF-1:0]<<YZeroCnt, {`DIVLEN-`NF{1'b0}}};

  
  assign X = PreprocX;
  assign Dpreproc = PreprocY;
  
  assign Dur = (`DURLEN)'($rtoi(`FPDUR));
  // assign intExp = zeroCntB - zeroCntA + 1;
  // assign intSign = Signed & (SrcA[`XLEN - 1] ^ SrcB[`XLEN - 1]);

  //           radix 2     radix 4
  // 1 copies  DIVLEN+2    DIVLEN+2/2
  // 2 copies  DIVLEN+2/2  DIVLEN+2/2*2
  // 4 copies  DIVLEN+2/4  DIVLEN+2/2*4
  // 8 copies  DIVLEN+2/8  DIVLEN+2/2*8

  // DIVRESLEN = DIVLEN or DIVLEN+2
  // r = 1 or 2
  // DIVRESLEN/(r*`DIVCOPIES)


endmodule