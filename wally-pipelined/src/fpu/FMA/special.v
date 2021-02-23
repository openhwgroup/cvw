/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	special.v
// Author:		David Harris
// Date:		12/2/1995
//
// Block Description:
//   This block implements special case handling for unusual operands (e.g. 
//   0, NaN,  denormalize,  infinity).   The block consists of zero/one detectors.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module special(x[63:0], y[63:0], z[63:0], ae, xzero, yzero, zzero,
				xnan, ynan, znan, xdenorm, ydenorm, zdenorm, proddenorm, xinf, yinf, zinf);
/////////////////////////////////////////////////////////////////////////////

	input   		[63:0]     	x;             // Input x
	input     	[63:0]     	y;           	// Input Y
	input      	[63:0]    	z;            	// Input z 
	input		[12:0]			ae;			// exponent of product
	output						xzero;			// Input x = 0
	output						yzero;			// Input y = 0
	output						zzero;			// Input z = 0
	output						xnan;			// x is NaN
	output						ynan;			// y is NaN
	output						znan;			// z is NaN
	output						xdenorm;		// x is denormalized
	output						ydenorm;		// y is denormalized
	output						zdenorm;		// z is denormalized
	output						proddenorm;		// product is denormalized
	output						xinf;			// x is infinity
	output						yinf;			// y is infinity
	output						zinf;			// z is infinity

	// In the actual circuit design, the gates looking at bits
	// 51:0 and at bits 62:52 should be shared among the various detectors.

	// Check if input is NaN

	assign xnan = &x[62:52] && |x[51:0]; 
	assign ynan = &y[62:52] && |y[51:0]; 
	assign znan = &z[62:52] && |z[51:0];

	// Check if input is denormalized

	assign xdenorm = ~(|x[62:52]) && |x[51:0]; 
	assign ydenorm = ~(|y[62:52]) && |y[51:0]; 
	assign zdenorm = ~(|z[62:52]) && |z[51:0];
	assign proddenorm = &ae & ~xzero & ~yzero; //KEP is the product denormalized

	// Check if input is infinity

	assign xinf = &x[62:52] && ~(|x[51:0]); 
	assign yinf = &y[62:52] && ~(|y[51:0]); 
	assign zinf = &z[62:52] && ~(|z[51:0]);

	// Check if inputs are all zero
	// Also forces denormalized inputs to zero.
	//   In the circuit implementation,  this can be optimized
	// to just check if the exponent is zero.
	
	// KATHERINE - commented following (21/01/11)
	// assign xzero = ~(|x[62:0]) || xdenorm;
	// assign yzero = ~(|y[62:0]) || ydenorm;
	// assign zzero = ~(|z[62:0]) || zdenorm;
	// KATHERINE - removed denorm to prevent outputing zero when computing with a denormalized number
	assign xzero = ~(|x[62:0]);
	assign yzero = ~(|y[62:0]);
	assign zzero = ~(|z[62:0]);
 endmodule
