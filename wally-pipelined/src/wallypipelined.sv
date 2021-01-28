///////////////////////////////////////////
// wally-pipelined.sv
//
// Written: David_Harris@hmc.edu 6 November 2020
// Modified: 
//
// Purpose: Top level module for pipelined processor and memories
// Full RV32/64IC instruction set
//
// To Do:
//  Sort out terminology of faults, traps, interrputs, exceptions
//  Long names for instruction decoder
//  *Consitency in capitalizaiton
//  *Divide into many files
//  *Keep lint clean
//  *Put in git repo
//  Sort out memory map
//  *Automate testing based on MISA
//  Drop Funct3 from Controller pipeline if not needed
//  Finish exceptions & test
//    *Flushes caused by exceptions
//    Generate statements to reduce hardware for unneeded exception logic
//    *RET
//    *Status register
//    Misaligned instruction faults on other aults
//
//
// Note: the CSRs do not support the following features
//- Disabling portions of the instruction set with bits of the MISA register
//- Changing from RV64 to RV32 by writing the SXL/UXL bits of the STATUS register
// As of January 2020, virtual memory is not yet supported
//
// Reference MISA Values: 
//  104: C compressed
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

module wallypipelined (
  input  logic            clk, reset, 
  output logic [`XLEN-1:0] WriteDataM, DataAdrM, 
  output logic [1:0]      MemRWM,
  input  logic [31:0]     GPIOPinsIn,
  output logic [31:0]     GPIOPinsOut, GPIOPinsEn,
  input  logic            UARTSin,
  output logic            UARTSout
);

  logic [`XLEN-1:0] PCF, ReadDataM;
  logic [31:0] InstrF;
  logic [7:0]  ByteMaskM;
  logic        InstrAccessFaultF, DataAccessFaultM;
  logic        TimerIntM, SwIntM; // from CLINT
  logic        ExtIntM = 0; // not yet connected
   
  // instantiate processor and memories
  wallypipelinedhart hart(.*);

  imem imem(.AdrF(PCF[`XLEN-1:1]), .*);
  dmem dmem(.AdrM(DataAdrM), .*);
endmodule