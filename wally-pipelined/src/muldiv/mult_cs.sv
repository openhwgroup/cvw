///////////////////////////////////////////
// mul_cs.sv
//
// Written: james.stine@okstate.edu 17 October 2021
// Modified: 
//
// Purpose: Carry/Save Multiplier output with Wallace Reduction
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

module mult_cs #(parameter WIDTH = 8) 
   (a, b, tc, sum, carry);

   input logic [WIDTH-1:0]    a;
   input logic [WIDTH-1:0]    b;
   input logic 		      tc;
   
   output logic [2*WIDTH-1:0] sum, carry;

   // PP array
   logic [2*WIDTH-1:0] 	      pp_array [0:WIDTH-1];
   logic [2*WIDTH-1:0] 	      next_pp_array [0:WIDTH-1];   
   logic [2*WIDTH-1:0] 	      tmp_sum, tmp_carry;
   logic [2*WIDTH-1:0] 	      temp_pp;
   logic [2*WIDTH-1:0] 	      tmp_pp_carry;
   logic [WIDTH-1:0] 	      temp_b_padded;
   logic 		      temp_bitgroup;	
   integer 		      bit_pair, height, i;      

   always_comb 
     begin 
	// For each multiplicand
	for (bit_pair=0; bit_pair < WIDTH; bit_pair=bit_pair+1)
	  begin
	     // Shift to the right via P&H
	     temp_b_padded = (b >> (bit_pair));	     	     
	     temp_bitgroup = temp_b_padded[0];
	     // PP generation
	     case (temp_bitgroup)
               1'b0 : temp_pp = {2*WIDTH-1{1'b0}};
               1'b1 : temp_pp = a;
               default : temp_pp = {2*WIDTH-1{1'b0}};
	     endcase
	     // Shift to the left via P&H
	     temp_pp = temp_pp << (bit_pair);
	     pp_array[bit_pair] = temp_pp;
	  end 

	// Height is multiplier
	height = WIDTH;

	// Wallace Tree Reduction
	while (height > 2)
	  begin
	     for (i=0; i < (height/3); i=i+1)
	       begin
		  next_pp_array[i*2] = pp_array[i*3]^pp_array[i*3+1]^pp_array[i*3+2];		  
		  tmp_pp_carry = (pp_array[i*3] & pp_array[i*3+1]) |
				 (pp_array[i*3+1] & pp_array[i*3+2]) |
				 (pp_array[i*3] & pp_array[i*3+2]);
		  next_pp_array[i*2+1] = tmp_pp_carry << 1;
	       end
	     // Reasssign not divisible by 3 rows to next_pp_array
	     if ((height % 3) > 0)
	       begin
		  for (i=0; i < (height % 3); i=i+1)
		    next_pp_array[2 * (height/3) + i] = pp_array[3 * (height/3) + i];
	       end
	     // Put back values in pp_array to start again
	     for (i=0; i < WIDTH; i=i+1) 
               pp_array[i] = next_pp_array[i];
	     // Reduce height
	     height = height - (height/3);
	  end
	// Sum is first row in reduced array
	tmp_sum = pp_array[0];
	// Carry is second row in reduced array
	tmp_carry = pp_array[1];
     end 

   assign sum = tmp_sum;
   assign carry = tmp_carry;

endmodule // mult_cs

