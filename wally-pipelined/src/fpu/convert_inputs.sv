///////////////////////////////////////////
//
// Written: James Stine
// Modified: 8/1/2018
//
// Purpose: Floating point divider/square root top unit (Goldschmidt)
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

module convert_inputs(
   input [63:0]  op1,      // 1st input operand (A)
   input [63:0]  op2,      // 2nd input operand (B)
   input [2:0]   op_type,  // Function opcode
   input 	     P,        // Result Precision (0 for double, 1 for single)

   output [63:0] Float1,	// Converted 1st input operand
   output [63:0] Float2	   // Converted 2nd input operand   
);

   wire 	 conv_SP;   // Convert from SP to DP
   wire 	 Zexp1;		// One if the exponent of op1 is zero
   wire 	 Zexp2;		// One if the exponent of op2 is zero
   wire 	 Oexp1;		// One if the exponent of op1 is all ones
   wire 	 Oexp2;		// One if the exponent of op2 is all ones

   // Convert from single precision to double precision if (op_type is 11X
   // and P is 0) or (op_type is not 11X and P is one). 
   assign conv_SP = ~P;

   // Test if the input exponent is zero, because if it is then the
   // exponent of the converted number should be zero. 
   assign Zexp1 = ~(|op1[30:23]);
   assign Zexp2 = ~(|op2[30:23]);
   assign Oexp1 =  (&op1[30:23]);
   assign Oexp2 =  (&op2[30:23]);

   // Conditionally convert op1. Lower 29 bits are zero for single precision.
   assign Float1[62:29] = conv_SP ? {op1[30], {3{(~op1[30]&~Zexp1)|Oexp1}}, op1[29:0]}
			  : op1[62:29];
   assign Float1[28:0] = op1[28:0] & {29{~conv_SP}};

   // Conditionally convert op2. Lower 29 bits are zero for single precision. 
   assign Float2[62:29] = conv_SP ? {op2[30], {3{(~op2[30]&~Zexp2)|Oexp2}}, op2[29:0]}
			  : op2[62:29];
   assign Float2[28:0] = op2[28:0] & {29{~conv_SP}};

   // Set the sign of Float1 based on its original sign and if the operation
   // is negation (op_type = 101) or absolute value (op_type = 100)

   assign Float1[63]  = conv_SP ? op1[31] : op1[63];
   assign Float2[63]  = conv_SP ? op2[31] : op2[63];

endmodule // convert_inputs

