///////////////////////////////////////////
// dcu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Data cache unit
//          Top level of the memory-stage hart logic
//          Contains data cache, subword read/write datapath, interface to external bus
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

module dcu (
  input  logic [1:0]      MemRWM,
  input  logic [`XLEN-1:0] ReadDataM,
  input  logic [`XLEN-1:0] DataAdrM,
  input  logic [2:0]      Funct3M,
  output logic [`XLEN-1:0] ReadDataExtM,
  input  logic [`XLEN-1:0] WriteDataFullM,
  output logic [`XLEN-1:0] WriteDataM,
  output logic [7:0]      ByteMaskM,
  input  logic            DataAccessFaultM,
  output logic            LoadMisalignedFaultM, LoadAccessFaultM,
  output logic            StoreMisalignedFaultM, StoreAccessFaultM
);
                  
  memdp memdp(.*);

endmodule

