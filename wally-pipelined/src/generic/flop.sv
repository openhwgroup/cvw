///////////////////////////////////////////
// flop.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: arious flavors of flip-flops
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
/* verilator lint_off DECLFILENAME */

// ordinary flip-flop
module flop #(parameter WIDTH = 8) ( 
  input  logic             clk,
  input  logic [WIDTH-1:0] d, 
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clk)
    q <= #1 d;
endmodule

// flop with asynchronous reset
module flopr #(parameter WIDTH = 8) ( 
  input  logic             clk, reset,
  input  logic [WIDTH-1:0] d, 
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= #1 0;
    else       q <= #1 d;
endmodule

// flop with enable
module flopen #(parameter WIDTH = 8) (
  input  logic             clk, en,
  input  logic [WIDTH-1:0] d, 
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clk)
    if (en) q <= #1 d;
endmodule

// flop with enable, asynchronous reset, synchronous clear
module flopenrc #(parameter WIDTH = 8) (
  input  logic             clk, reset, clear, en,
  input  logic [WIDTH-1:0] d, 
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset)   q <= #1 0;
    else if (en) 
      if (clear) q <= #1 0;
      else       q <= #1 d;
endmodule

// flop with enable, asynchronous reset
module flopenr #(parameter WIDTH = 8) (
  input  logic             clk, reset, en,
  input  logic [WIDTH-1:0] d, 
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset)   q <= #1 0;
    else if (en) q <= #1 d;
endmodule

// flop with enable, asynchronous set
module flopens #(parameter WIDTH = 8) (
  input  logic             clk, set, en,
  input  logic [WIDTH-1:0] d, 
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge set)
    if (set)   q <= #1 1;
    else if (en) q <= #1 d;
endmodule


// flop with enable, asynchronous load
module flopenl #(parameter WIDTH = 8, parameter type TYPE=logic [WIDTH-1:0]) (
  input  logic clk, load, en,
  input  TYPE d,
  input  TYPE val,
  output TYPE q);

  always_ff @(posedge clk, posedge load)
    if (load)    q <= #1 val;
    else if (en) q <= #1 d;
endmodule

// flop with asynchronous reset, synchronous clear
module floprc #(parameter WIDTH = 8) (
  input  logic clk,
  input  logic reset,
  input  logic clear,
  input  logic [WIDTH-1:0] d, 
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= #1 0;
    else       
      if (clear) q <= #1 0;
      else       q <= #1 d;
endmodule

/* verilator lint_on DECLFILENAME */
