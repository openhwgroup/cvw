// Exception logic for the floating point adder. Note: We may 
// actually want to move to where the result is computed.

module exception (

   input logic [2:0] 	op_type,   	// Function opcode
   input logic XSgnE, YSgnE,
   // input logic [52:0] XManE, YManE,
   input logic XDenormE, YDenormE,
   input logic XNormE, YNormE,
   input logic XZeroE, YZeroE,
   input logic XInfE, YInfE,
   input logic XNaNE, YNaNE,
   input logic XSNaNE, YSNaNE,
   output logic [3:0] Ztype,		// Indicates type of result (Z)
   output logic 	Invalid,	// Invalid operation exception
   output logic 	Denorm,		// Denormalized logic
   output logic       Sub		// The effective operation is subtraction
);
   wire		ZQNaN;	 	// '1' if result Z is a quiet NaN
   wire		ZPInf;	 	// '1' if result Z positive infnity
   wire		ZNInf;	 	// '1' if result Z negative infnity
   wire         add_sub;	// '1' if operation is add or subtract
   wire 	converts;       // See if there are any converts   
   


   // Is this instruction a convert
   assign converts      = op_type[1];
   


   // An "Invalid Operation" exception occurs if (A or B is a signalling NaN)
   // or (A and B are both Infinite and the "effective operation" is 
   // subtraction). 
   assign add_sub = ~op_type[1];
   assign Invalid = (XSNaNE | YSNaNE | (add_sub & XInfE & YInfE & (XSgnE^YSgnE^op_type[0]))) & ~converts;

   // The Denorm flag is set if (A is denormlized and the operation is not integer 
   // conversion ) or (if B is normalized and the operation is addition or  subtraction). 
   assign Denorm = XDenormE | YDenormE & add_sub;

   // The result is a quiet NaN if (an "Invalid Operation" exception occurs) 
   // or (A is a NaN) or (B is a NaN and the operation uses B).
   assign ZQNaN = Invalid | XNaNE | (YNaNE & add_sub);

   // The result is +Inf if ((A is +Inf) or (B is -Inf and the operation is
   // subtraction) or (B is +Inf and the operation is addition)) and (the
   // result is not a quiet NaN).  
   assign ZPInf = (XInfE&XSgnE | add_sub&YInfE&(~YSgnE^op_type[0]))&~ZQNaN;

   // The result is -Inf if ((A is -Inf) or (B is +Inf and the operation is
   // subtraction) or (B is -Inf and the operation is addition)) and the
   // result is not a quiet NaN.  
   assign ZNInf = (XInfE&~XSgnE | add_sub&YInfE&(YSgnE^op_type[0]))&~ZQNaN;

   // Set the type of the result as follows:
   // (needs optimization - got lazy or was late)
   // Ztype	Result 
   //  0000	Normal
   //  0001	Quiet NaN
   //  0010     Negative Infinity
   //  0011     Positive Infinity
   //  0100     +Bzero and +Azero (and vice-versa)
   //  0101     +Bzero and -Azero (and vice-versa)
   //  1000     Convert SP to DP (and vice-versa)

   assign Ztype[0] = (ZQNaN | ZPInf) | 
		     ((XZeroE & YZeroE & (XSgnE^YSgnE^op_type[0])) 
		      & ~converts);
   assign Ztype[1] = (ZNInf | ZPInf) | 
		     (((XZeroE & YZeroE & XSgnE & YSgnE & ~op_type[0]) |
		       (XZeroE & YZeroE & XSgnE & ~YSgnE & op_type[0])) 
		      & ~converts);
   assign Ztype[2] = ((XZeroE & YZeroE & ~op_type[1]) 
		      & ~converts);
   assign Ztype[3] = (op_type[1] & ~op_type[0]);

   // Determine if the effective operation is subtraction
   assign Sub = add_sub & (XSgnE^YSgnE^op_type[0]);
 
endmodule // exception

