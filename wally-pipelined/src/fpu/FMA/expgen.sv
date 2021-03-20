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
module expgen(xexp, yexp, zexp,
			   killprod,  sumzero, resultdenorm, normcnt, infinity, 
			   invalid, overflow, underflow, inf, 
			   nan, de0, xnan, ynan, znan, xdenorm, ydenorm, zdenorm, proddenorm, specialsel, zexpsel,
			   aligncnt, wexp,
			   prodof, sumof, sumuf, denorm0, ae);
/////////////////////////////////////////////////////////////////////////////
  
	input     	[62:52]    	xexp;           	// Exponent of multiplicand x
	input     	[62:52]  	yexp;         		// Exponent of multiplicand y
	input     	[62:52]  	zexp;           	// Exponent of addend z
	input     			killprod;    	// Z >> product
	input     			sumzero;     	// sum exactly equals zero 
	input     			resultdenorm;  // postnormalize rounded result
	input     	[8:0]  		normcnt;     	// normalization shift count 
	input     			infinity;    	// generate infinity on overflow 
	input     			invalid;     	// Result invalid
	input     			overflow;    	// Result overflowed
	input     			underflow;   	// Result underflowed 
	input     			inf;			// Some input is infinity
	input     			nan;			// Some input is NaN
	input     	[12:0]		de0;			// X is NaN NaN
	input     			xnan;			// X is NaN
	input     			ynan;			// Y is NaN
	input     			znan;			// Z is NaN 
	input     			xdenorm;		// Z is denorm
	input     			ydenorm;		// Z is denorm
	input     			zdenorm;		// Z is denorm
	input     			proddenorm;		// product is denorm
	input     			specialsel;  	// Select special result
	input     			zexpsel;  	// Select special result
	output		[11:0]   	aligncnt;       // shift count for alignment shifter
	output		[62:52]    	wexp;           	// Exponent of result
	output				prodof;         // X*Y exponent out of bounds 
	output				sumof;          // X*Y+Z exponent out of bounds 
	output				sumuf;         // X*Y+Z exponent underflows 
	output				denorm0;     	// exponent = 0 for denorm 
	output		[12:0]		ae;				//exponent of multiply

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


	assign ae = xexp + yexp;

	assign prodof = (ae - 1023 > 2046 && ~ae[12]);

	// Compute alignment shift count
	// Adjust for postrounding normalization of Z.
	// This should not increas the critical path because the time to
	// check if a round overflows is shorter than the actual round and
	// is masked by the bypass mux and two 10 bit adder delays.

	assign aligncnt = zexp - ae;// KEP use all of ae


	// Select exponent (usually from product except in case of huge addend)

	assign be = zexpsel ? zexp : ae;

	// Adjust exponent based on normalization
	// A compound adder takes care of the case of post-rounding normalization
	// requiring an extra increment
	 
	//assign de0 = sumzero ? 13'b0 : be + normcnt + 2;
	// assign de1 = sumzero ? 13'b0 : be + normcnt + 2;
	 
	// If the exponent becomes exactly zero (denormalized)
	// signal such to adjust R bit before rounding

	assign denorm0 = (de0 == 0);
	
	// check for exponent out of bounds after add 
	
	assign de = resultdenorm ? 0 : de0;
	assign sumof = de[12];
	assign sumuf = de == 0  && ~sumzero && ~resultdenorm;

	// bypass occurs before rounding or taking early results 
	
	assign wbypass = de0[10:0];
	
	// In a non-critical special mux, we combine the early result from other
	// FPU blocks with the results of exceptional conditions.  Overflow
	// produces either infinity or the largest finite number, depending on the
	// rounding mode.  NaNs are propagated or generated.

	assign specialres = invalid | nan ? nanres : // KEP added nan
					overflow ? infinityres : 
					inf ? 11'b11111111111 :
					underflow ? 11'b0 : 11'bx;

	assign infinityres = infinity ? 11'b11111111111 : 11'b11111111110;

	// IEEE 754-2008 section 6.2.3 states:
	// "If two or more inputs are NaN, then the payload of the resulting NaN should be 
	// identical to the payload of one of the input NaNs if representable in the destination
	// format. This standard does not specify which of the input NaNs will provide the payload."
	assign nanres = xnan ? xexp : (ynan ? yexp : (znan? zexp : 11'b11111111111));

	// A mux selects the early result from other FPU blocks or the 
	// normalized FMAC result.   Special cases are also detected. 
	
	assign wexp = specialsel ? specialres[10:0] : de[10:0]; 
endmodule

