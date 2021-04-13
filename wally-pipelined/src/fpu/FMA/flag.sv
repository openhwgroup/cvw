/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	flag.v
// Author:		David Harris
// Date:		12/6/1995
//
// Block Description:
//       This block generates the flags: invalid, overflow, underflow, inexact. 
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module flag(xnan, ynan, znan, xinf, yinf, zinf, prodof, sumof, sumuf,
			 psign,  zsign, xzero, yzero, zzero, vbits, killprod,
			 inf, nan, FmaFlagsM,sticky);
/////////////////////////////////////////////////////////////////////////////

	input                  		xnan;        	// X is NaN 
	input                  		ynan;        	// Y is NaN 
	input                 		znan;       	// Z is NaN 
	input                  		sticky;        	// X is Inf
	input                  		xinf;        	// X is Inf
	input                 		yinf;       	// Y is Inf 
	input                  		zinf;        	// Z is Inf
	input                  		prodof;         // X*Y overflows exponent
	input                  		sumof;          // X*Y + z underflows exponent
	input                  		sumuf;          // X*Y + z underflows exponent
	input				psign; 		// Sign of product
	input				zsign; 		// Sign of z
	input				xzero;		// x = 0
	input				yzero;		// y = 0
	input				zzero;		// y = 0
	input				killprod;
	input     	[1:0]  		vbits;		// R and S bits of result
	output				inf;		// Some	source is Inf
	output				nan;		// Some	source is NaN
	output		[4:0]	FmaFlagsM;
 
	//   Internal nodes

	wire				prodinf;	// X*Y larger than max possible
	wire				suminf;		// X*Y+Z larger than max possible

	// If any input is NaN, propagate the NaN 

	assign nan = xnan || ynan || znan;

	// Same with infinity (inf - inf and O * inf don't propagate inf
	//  but it's ok becaue illegal op takes higher precidence)

	assign inf= xinf || yinf || zinf || suminf;//KEP added suminf 
	//assign inf= xinf || yinf || zinf;//original

	// Generate infinity checks

	assign prodinf = prodof && ~xnan && ~ynan;
	//KEP added if the product is infinity then sum is infinity
	assign suminf = sumof && ~xnan && ~ynan && ~znan;

	// Set invalid flag for following cases:
	//   1) Inf - Inf
	//   2) 0 * Inf
	//   3) Output = NaN (this is not part of the IEEE spec,  only 486 proj)

	assign FmaFlagsM[4] = (xinf || yinf || prodinf) && zinf && (psign ^ zsign) ||
					   xzero && yinf || yzero && xinf;// KEP remove case 3) above

	assign FmaFlagsM[3] = 0; // divide by zero flag


	// Set the overflow flag for the following cases:
	//   1) Rounded multiply result would be out of bounds
	//   2) Rounded add result would be out of bounds

	assign FmaFlagsM[2] = suminf && ~inf;

	// Set the underflow  flag for the following cases:
	//   1) Any input is denormalized
	//   2)  Output would be denormalized or smaller

	assign FmaFlagsM[1] = (sumuf && ~inf && ~prodinf && ~nan) || (killprod & zzero & ~(yzero | xzero));

	// Set the inexact flag for the following cases:
	//   1) Multiplication inexact
	//   2) Addition  inexact
	// One of these cases occurred if the R or S bit is set

	assign FmaFlagsM[0] = (vbits[0] || vbits[1] ||sticky  || suminf) && ~(inf || nan);

endmodule
