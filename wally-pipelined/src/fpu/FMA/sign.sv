/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	sign.v
// Author:		David Harris
// Date:		12/1/1995
//
// Block Description:
//   This block manages the signs of the numbers.
//   1 =  negative
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module sign(xsign, ysign, zsign, negsum0, negsum1, bs, ps, killprod, rm, overflow,
			 sumzero, nan, invalid, xinf, yinf, zinf, inf, wsign, invz, negsum, selsum1, psign);
////////////////////////////////////////////////////////////////////////////I
 
	input					xsign;			// Sign of X 
	input					ysign;			// Sign of Y 
	input					zsign;			// Sign of Z
	input					negsum0;		// Sum in +O mode is negative 
	input					negsum1;		// Sum in +1 mode is negative 
	input					bs;				// sticky bit from addend
	input					ps;				// sticky bit from product
	input					killprod;		// Product forced to zero
	input					rm;				// Round toward minus infinity
	input					overflow;				// Round toward minus infinity
	input					sumzero;		// Sum = O
	input					nan;			// Some input is NaN
	input					invalid;		// Result invalid
	input					xinf;			// X = Inf
	input					yinf;			// Y = Inf
	input					zinf;			// Y = Inf
	input					inf;			// Some input = Inf
	output					wsign;			// Sign of W 
	output					invz;			// Invert addend into adder
	output					negsum;			// Negate result of adder
	output					selsum1;		// Select +1 mode from compound adder
	output					psign;			// sign of product X * Y 
 
	// Internal nodes

	wire					zerosign;    	// sign if result= 0 
	wire					infsign;     	// sign if result= Inf 
	reg						negsum;         // negate result of adder 
	reg						selsum1;     	// select +1 mode from compound adder 
logic tmp;

	// Compute sign of product 

	assign psign = xsign ^ ysign;

	// Invert addend if sign of Z is different from sign of product assign invz = zsign ^ psign;
	assign invz = (zsign ^ psign);
	// Select +l mode for adder and compute if result must be negated
	// This is done according to cases based on the sticky bit.

	always @(invz or negsum0 or negsum1 or bs or ps)
		begin
			if (~invz) begin               // both inputs have same sign //KEP if overflow 
				negsum = 0;
				selsum1 = 0;
			end else if (bs) begin        // sticky bit set on addend
				selsum1 = 0;
				negsum = negsum0; 
			end else if (ps) begin 		// sticky bit set on product
				selsum1 = 1;
				negsum =  negsum1;
			end else begin 				// both sticky bits clear
				selsum1 = negsum1; 	// KEP 210113-10:44 Selsum1 was adding 1 to values that were multiplied by 0
				// selsum1 = ~negsum1; //original
				negsum = negsum1;
		end 
	end

	// Compute sign of result
	// This involves a special case when the sum is zero:
	//   x+x retains the same sign as x even when x = +/- 0.
	//   otherwise,  x-x = +O unless in the RM mode when x-x = -0
	// There is also a special case for NaNs and invalid results;
	// the sign of the NaN produced is forced to be 0.
	// Sign calculation is not in the critical path so the cases
	// can be tolerated. 
	// IEEE 754-2008 section 6.3 states 
	// 		"When ether an input or result is NaN, this standard does not interpret the sign of a NaN."
	// 		also pertaining to negZero it states:
	//			"When the sum/difference of two operands with opposite signs is exactly zero, the sign of that sum/difference
	//			 shall be +0 in all rounding attributes EXCEPT roundTowardNegative. Under that attribute, the sign of an exact zero 
	//			 sum/difference shall be -0.  However, x+x = x-(-X) retains the same sign as x even when x is zero."
 
	assign zerosign = (~invz && killprod) ? zsign : rm;
	assign infsign = zinf ? zsign : psign; //KEP 210112 keep the correct sign when result is infinity
	//assign infsign = xinf ? (yinf ? psign : xsign) : yinf ? ysign : zsign;//original
	assign tmp = invalid ? 0 : (inf ? infsign :(sumzero ? zerosign : psign ^ negsum));
	assign wsign = invalid ? 0 : (inf ? infsign :(sumzero ? zerosign : psign ^ negsum));

endmodule
