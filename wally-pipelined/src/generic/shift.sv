///////////////////////////////////////////
// shifters.sv
//
// Written: James.Stine@okstate.edu 1 February 2021
// Modified: 
//
// Purpose: Integer Divide instructions
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
/* verilator lint_off UNOPTFLAT */

module shift_right #(parameter WIDTH=8) 
   (input logic [WIDTH-1:0]         A,
    input logic [$clog2(WIDTH)-1:0] Shift,
    output logic [WIDTH-1:0] 	    Z);
   
   logic [WIDTH-1:0] 		    stage [$clog2(WIDTH):0];
   logic 			    sign;   
   genvar 			    i;

   assign stage[0] = A;   
   generate
      for (i=0;i<$clog2(WIDTH);i=i+1) begin : genbit
	      mux2 #(WIDTH) mux_inst (stage[i], 
				   {{(WIDTH/(2**(i+1))){1'b0}}, stage[i][WIDTH-1:WIDTH/(2**(i+1))]}, 
				   Shift[$clog2(WIDTH)-i-1], 
				   stage[i+1]);
	   end
   endgenerate
   assign Z = stage[$clog2(WIDTH)];   

endmodule // shift_right

module shift_left #(parameter WIDTH=8) 
   (input logic [WIDTH-1:0]         A,
    input logic [$clog2(WIDTH)-1:0] Shift,
    output logic [WIDTH-1:0] 	    Z);
   
   logic [WIDTH-1:0] 		    stage [$clog2(WIDTH):0];
   genvar 			    i;
   
   assign stage[0] = A;   
   generate
      for (i=0;i<$clog2(WIDTH);i=i+1) begin : genbit
	     mux2 #(WIDTH) mux_inst (stage[i], 
				   {stage[i][WIDTH-1-WIDTH/(2**(i+1)):0], {(WIDTH/(2**(i+1))){1'b0}}}, 
				   Shift[$clog2(WIDTH)-i-1], 
				   stage[i+1]);
	   end
   endgenerate
   assign Z = stage[$clog2(WIDTH)];   

endmodule // shift_left

/* verilator lint_on DECLFILENAME */
/* verilator lint_on UNOPTFLAT */
