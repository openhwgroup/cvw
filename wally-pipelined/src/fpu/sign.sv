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
module sign(xsign, ysign, zsign, negsum0, negsum1, bsM, FrmM, FmaFlagsM, 
			 sumzero, zinfM, inf, wsign, invz, negsum, selsum1, isAdd);
////////////////////////////////////////////////////////////////////////////I
 
	input logic					xsign;			// Sign of X 
	input logic					ysign;			// Sign of Y 
	input logic					zsign;			// Sign of Z
	input logic					isAdd;
	input logic					negsum0;		// Sum in +O mode is negative 
	input logic					negsum1;		// Sum in +1 mode is negative 
	input logic					bsM;				// sticky bit from addend
	input logic		[2:0]		FrmM;				// Round toward minus infinity
	input logic		[4:0]		FmaFlagsM;				// Round toward minus infinity
	input logic					sumzero;		// Sum = O
	input logic					zinfM;			// Y = Inf
	input logic					inf;			// Some input = Inf
	output logic					wsign;			// Sign of W 
	output logic					invz;			// Invert addend into adder
	output logic					negsum;			// Negate result of adder
	output logic					selsum1;		// Select +1 mode from compound adder
 
	// Internal nodes

	wire					zerosign;    	// sign if result= 0 
	wire					sumneg;    	// sign if result= 0 
	wire					infsign;     	// sign if result= Inf 
	// Compute sign of product 

	assign psign = xsign ^ ysign;

	// Invert addend if sign of Z is different from sign of product assign invz = zsign ^ psign;

	//do you invert z
	assign invz = (zsign ^ psign);

	assign selsum1 = invz;
	//negate sum if its negitive
	assign negsum = (selsum1&negsum1) | (~selsum1&negsum0);
	// is the sum negitive
	// 	if p - z is the sum negitive
	// 	if -p + z is the sum positive
	// 	if -p - z then the sum is negitive
	assign sumneg = invz&zsign&negsum1 | invz&psign&~negsum1 | (zsign&psign);
	//always @(invz or negsum0 or negsum1 or bsM or ps)
	//	begin
	//		if (~invz) begin               // both inputs have same sign  
	//			negsum = 0;
	//			selsum1 = 0;
	//		end else if (bsM) begin        // sticky bit set on addend
	//			selsum1 = 0;
	//			negsum = negsum0; 
	//		end else if (ps) begin 		// sticky bit set on product
	//			selsum1 = 1;
	//			negsum =  negsum1;
	//		end else begin 				// both sticky bits clear
	//			//selsum1 = negsum1; 	// KEP 210113-10:44 Selsum1 was adding 1 to values that were multiplied by 0
	//			 selsum1 = ~negsum1; //original
	//			negsum = negsum1;
	//	end 
	//end

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
 
	//assign zerosign = (~invz && killprodM) ? zsign : rm;//***look into
//	assign zerosign = (~invz && killprodM) ? zsign : 0;
	// zero sign
	//	if product underflows then use psign
	//	otherwise
	//		addition
	//			if cancelation then 0 unless round to -inf
	//			otherwise psign
	//		subtraction
	//			if cancelation then 0 unless round to -inf
	//			otherwise psign

	assign zerosign = FmaFlagsM[1] ? psign :
			  (isAdd ? (psign^zsign ? FrmM == 3'b010 : psign) :
				  (psign^zsign ? psign : FrmM == 3'b010));
	assign infsign = zinfM ? zsign : psign; //KEP 210112 keep the correct sign when result is infinity
	//assign infsign = xinfM ? (yinfM ? psign : xsign) : yinfM ? ysign : zsign;//original
	assign tmp = FmaFlagsM[4] ? 0 : (inf ? infsign :(sumzero ? zerosign : psign ^ negsum));
	assign wsign = FmaFlagsM[4] ? 0 : (inf ? infsign :(sumzero ? zerosign : sumneg));

endmodule
