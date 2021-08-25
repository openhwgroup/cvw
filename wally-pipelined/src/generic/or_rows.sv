///////////////////////////////////////////
// or_rows.sv
//
// Written: David_Harris@hmc.edu 13 July 2021
// Modified: 
//
// Purpose: Various flavors of multiplexers
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

// perform an OR of all the rows in an array, producing one output for each column
// equivalent to assign y = a.or
module or_rows #(parameter ROWS = 8, COLS=2) (
  input  var logic [COLS-1:0] a[ROWS-1:0],
  output logic [COLS-1:0] y); 

  logic [COLS-1:0] mid[ROWS-1:0];
  genvar row, col;
  generate
    assign mid[1] = a[0] | a[1];
    for (row=2; row < ROWS; row++)
      assign mid[row] = mid[row-1] | a[row];
    assign y = mid[ROWS-1];
    
    /*
      for (col = 0; col < COLS; col++) begin
          assign mid[1][col] = a[0][col] | a[1][col];
          for (row=2; row < ROWS; row++)
            assign mid[row][col] = mid[row-1][col] | a[row][col];
          assign y[col] = mid[ROWS-1][col];
      end
      */
  endgenerate
endmodule

/* verilator lint_on UNOPTFLAT */
/* verilator lint_on DECLFILENAME */
