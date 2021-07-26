// This module takes as inputs two operands (op1 and op2) 
// and the result precision (P).  Based on the operation and precision, 
// it conditionally converts single precision values to double 
// precision values and modifies the sign of op1. 
// The converted operands are Float1 and Float2.
module convert_inputs_div (
   
   input logic [63:0]  op1,           // 1st input operand (A)
   input logic [63:0]  op2,           // 2nd input operand (B)
   input logic 	     P,             // Result Precision (0 for double, 1 for single)
   input logic 	     op_type,       // Operation   

   output logic [63:0] Float1,	      // Converted 1st input operand
   output logic [63:0] Float2b	      // Converted 2nd input operand   
);

   logic [63:0]        Float2;   
   logic 	           Zexp1;	      // One if the exponent of op1 is zero
   logic 	           Zexp2;	      // One if the exponent of op2 is zero
   logic 	           Oexp1;	      // One if the exponent of op1 is all ones
   logic 	           Oexp2;	      // One if the exponent of op2 is all ones

   // Test if the input exponent is zero, because if it is then the
   // exponent of the converted number should be zero. 
   assign Zexp1 = ~(|op1[30:23]);
   assign Zexp2 = ~(|op2[30:23]);
   assign Oexp1 =  (&op1[30:23]);
   assign Oexp2 =  (&op2[30:23]);

   // Conditionally convert op1. Lower 29 bits are zero for single precision.
   assign Float1[62:29] = P ? {op1[30], {3{(~op1[30]&~Zexp1)|Oexp1}}, op1[29:0]}
			  : op1[62:29];
   assign Float1[28:0] = op1[28:0] & {29{~P}};

   // Conditionally convert op2. Lower 29 bits are zero for single precision. 
   assign Float2[62:29] = P ? {op2[30], {3{(~op2[30]&~Zexp2)|Oexp2}}, op2[29:0]}
			  : op2[62:29];
   assign Float2[28:0] = op2[28:0] & {29{~P}};

   // Set the sign of Float1 based on its original sign
   assign Float1[63]  = P ? op1[31] : op1[63];
   assign Float2[63]  = P ? op2[31] : op2[63];

   // For sqrt, assign Float2 same as Float1 for simplicity
   assign Float2b = op_type ? Float1 : Float2;   

endmodule // convert_inputs