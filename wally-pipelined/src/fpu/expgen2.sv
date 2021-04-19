/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	expgen.v
// Author:		David Harris
// Date:		11/2/1995
//
//   Block Description:
//   This block implements the exponent path of the FMAC. It performs the
//   following operations:
//
//   1) Compute exponent of multiply.  
//   2) Compare multiply and add exponents to generate alignment shift count
//   3) Adjust exponent based on normalization
//   4)  Increment exponent based on postrounding renormalization
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module expgen2(xexp, yexp, zexp,
			   sumzero, resultdenorm, infinity, 
			   FmaFlagsM, inf, expplus1,
			   nanM, de0, xnanM, ynanM, znanM,  specialsel,
			    wexp,
			   sumof, sumuf);
/////////////////////////////////////////////////////////////////////////////
  
	input logic     	[62:52]    	xexp;           	// Exponent of multiplicand x
	input logic     	[62:52]  	yexp;         		// Exponent of multiplicand y
	input logic     	[62:52]  	zexp;           	// Exponent of addend z
	input logic     			sumzero;     	// sum exactly equals zero 
	input logic     			resultdenorm;  // postnormalize rounded result
	input logic     			infinity;    	// generate infinity on overflow 
	input logic     	[4:0]	FmaFlagsM;     	// Result invalid
	input logic     			inf;			// Some input is infinity
	input logic     			nanM;			// Some input is NaN
	input logic     	[12:0]		de0;			// X is NaN NaN
	input logic     			xnanM;			// X is NaN
	input logic    			ynanM;			// Y is NaN
	input logic     			znanM;			// Z is NaN 
	input logic				expplus1;
	input logic     			specialsel;  	// Select special result
	output logic		[62:52]    	wexp;           	// Exponent of result
	output logic				sumof;          // X*Y+Z exponent out of bounds 
	output logic				sumuf;         // X*Y+Z exponent underflows 

	//   Internal nodes


	wire 	[12:0]			aligncnt0;		// Shift count for alignment
	wire 	[12:0]			aligncnt1;		// Shift count for alignment
	wire 	[12:0]			be;				// Exponent of multiply
	wire 	[12:0]			de1;			// Normalized exponent
	wire 	[12:0]			de;				// Normalized exponent
	wire 	[10:0]			infinityres;	// Infinity or max number
	wire 	[10:0]			nanres;          //	Nan propagated or generated
	wire 	[10:0]			specialres;  //	Exceptional case result

	//   Compute exponent of multiply
	// Note that the exponent does not have to be incremented on a postrounding
	//   normalization of X because the mantissa was already increased.   Report
	//   if exponent is out of bounds 

	// Select exponent (usually from product except in case of huge addend)

	//assign be = zexpsel ? zexp : ae;

	// Adjust exponent based on normalization
	// A compound adder takes care of the case of post-rounding normalization
	// requiring an extra increment
	 
	//assign de0 = sumzero ? 13'b0 : be + normcnt + 2;
	// assign de1 = sumzero ? 13'b0 : be + normcnt + 2;
	 
	
	// check for exponent out of bounds after add 
	
	assign de = resultdenorm | sumzero ? 0 : de0;
	assign sumof = ~de[12] && de > 2046;
	assign sumuf = de == 0  && ~sumzero && ~resultdenorm;

	// bypass occurs before rounding or taking early results 
	
	//assign wbypass = de0[10:0];
	
	// In a non-critical special mux, we combine the early result from other
	// FPU blocks with the results of exceptional conditions.  Overflow
	// produces either infinity or the largest finite number, depending on the
	// rounding mode.  NaNs are propagated or generated.

	assign specialres = FmaFlagsM[4] | nanM ? nanres : // invalid
					FmaFlagsM[2] ? infinityres : 	//overflow
					inf ? 11'b11111111111 :
					FmaFlagsM[1] ? 11'b0 : 11'bx; //underflow

	assign infinityres = infinity ? 11'b11111111111 : 11'b11111111110;

	// IEEE 754-2008 section 6.2.3 states:
	// "If two or more inputs are NaN, then the payload of the resulting NaN should be 
	// identical to the payload of one of the input NaNs if representable in the destination
	// format. This standard does not specify which of the input NaNs will provide the payload."
	assign nanres = xnanM ? xexp : (ynanM ? yexp : (znanM? zexp : 11'b11111111111));

	// A mux selects the early result from other FPU blocks or the 
	// normalized FMAC result.   Special cases are also detected. 
	
	assign wexp = specialsel ? specialres[10:0] : de[10:0] + expplus1; 
endmodule

