// This module takes as inputs two operands (op1 and op2) 
// the operation type (op_type) and the result precision (P). 
// Based on the operation and precision , it conditionally
// converts single precision values to double precision values
// and modifies the sign of op1. The converted operands are Float1
// and Float2.

module convert_inputs(Float1, Float2, op1, op2, op_type, P);
   
   input [63:0]  op1;            // 1st input operand (A)
   input [63:0]  op2;            // 2nd input operand (B)
   input [2:0] 	 op_type;        // Function opcode
   input 	 P;              // Result Precision (0 for double, 1 for single)

   output [63:0] Float1;	// Converted 1st input operand
   output [63:0] Float2;	// Converted 2nd input operand   
   
   wire 	 conv_SP;        // Convert from SP to DP
   wire 	 negate;         // Operation is negation
   wire 	 abs_val;        // Operation is absolute value
   wire 	 Zexp1;		// One if the exponent of op1 is zero
   wire 	 Zexp2;		// One if the exponent of op2 is zero
   wire 	 Oexp1;		// One if the exponent of op1 is all ones
   wire 	 Oexp2;		// One if the exponent of op2 is all ones

   // Convert from single precision to double precision if (op_type is 11X
   // and P is 0) or (op_type is not 11X and P is one). 
   assign conv_SP = (op_type[2]&op_type[1]) ^ P;

   // Test if the input exponent is zero, because if it is then the
   // exponent of the converted number should be zero. 
   assign Zexp1 = ~(op1[62] | op1[61] | op1[60] | op1[59] | 
		    op1[58] | op1[57] | op1[56] | op1[55]);
   assign Zexp2 = ~(op2[62] | op2[61] | op2[60] | op2[59] | 
		    op2[58] | op2[57] | op2[56] | op2[55]);
   assign Oexp1 =  (op1[62] & op1[61] & op1[60] & op1[59] & 
		    op1[58] & op1[57] & op1[56] & op1[55]);
   assign Oexp2 =  (op2[62] & op2[61] & op2[60] & op2[59] & 
		    op2[58] & op2[57] & op2[56] &op2[55]);

   // Conditionally convert op1. Lower 29 bits are zero for single precision.
   assign Float1[62:29] = conv_SP ? {op1[62], {3{(~op1[62]&~Zexp1)|Oexp1}}, op1[61:32]}
			  : op1[62:29];
   assign Float1[28:0] = op1[28:0] & {29{~conv_SP}};

   // Conditionally convert op2. Lower 29 bits are zero for single precision. 
   assign Float2[62:29] = conv_SP ? {op2[62], 
				     {3{(~op2[62]&~Zexp2)|Oexp2}}, op2[61:32]}
			  : op2[62:29];
   assign Float2[28:0] = op2[28:0] & {29{~conv_SP}};

   // Set the sign of Float1 based on its original sign and if the operation
   // is negation (op_type = 101) or absolute value (op_type = 100)

   assign negate  = op_type[2] & ~op_type[1] & op_type[0];
   assign abs_val = op_type[2] & ~op_type[1] & ~op_type[0];
   assign Float1[63]  = (op1[63] ^ negate) & ~abs_val;
   assign Float2[63]  = op2[63];

endmodule // convert_inputs

