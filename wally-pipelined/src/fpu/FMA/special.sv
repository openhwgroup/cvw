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
module special(ReadData1E, ReadData2E, ReadData3E, ae, xzero, yzero, zzero,
				xnan, ynan, znan, xdenorm, ydenorm, zdenorm, proddenorm, xinf, yinf, zinf);
/////////////////////////////////////////////////////////////////////////////

	input   	[63:0]     	ReadData1E;              // Input ReadData1E
	input     	[63:0]     	ReadData2E;           	// Input ReadData2E
	input      	[63:0]    	ReadData3E;            	// Input ReadData3E 
	input		[12:0]		ae;		// exponent of product
	output				xzero;		// Input ReadData1E = 0
	output				yzero;		// Input ReadData2E = 0
	output				zzero;		// Input ReadData3E = 0
	output				xnan;		// ReadData1E is NaN
	output				ynan;		// ReadData2E is NaN
	output				znan;		// ReadData3E is NaN
	output				xdenorm;	// ReadData1E is denormalized
	output				ydenorm;	// ReadData2E is denormalized
	output				zdenorm;	// ReadData3E is denormalized
	output				proddenorm;	// product is denormalized
	output				xinf;		// ReadData1E is infinity
	output				yinf;		// ReadData2E is infinity
	output				zinf;		// ReadData3E is infinity

	// In the actual circuit design, the gates looking at bits
	// 51:0 and at bits 62:52 should be shared among the various detectors.

	// Check if input is NaN

	assign xnan = &ReadData1E[62:52] && |ReadData1E[51:0]; 
	assign ynan = &ReadData2E[62:52] && |ReadData2E[51:0]; 
	assign znan = &ReadData3E[62:52] && |ReadData3E[51:0];

	// Check if input is denormalized

	assign xdenorm = ~(|ReadData1E[62:52]) && |ReadData1E[51:0]; 
	assign ydenorm = ~(|ReadData2E[62:52]) && |ReadData2E[51:0]; 
	assign zdenorm = ~(|ReadData3E[62:52]) && |ReadData3E[51:0];
	assign proddenorm = &ae & ~xzero & ~yzero; //KEP is the product denormalized

	// Check if input is infinity

	assign xinf = &ReadData1E[62:52] && ~(|ReadData1E[51:0]); 
	assign yinf = &ReadData2E[62:52] && ~(|ReadData2E[51:0]); 
	assign zinf = &ReadData3E[62:52] && ~(|ReadData3E[51:0]);

	// Check if inputs are all zero
	// Also forces denormalized inputs to zero.
	//   In the circuit implementation,  this can be optimized
	// to just check if the exponent is zero.
	
	// KATHERINE - commented following (21/01/11)
	// assign xzero = ~(|ReadData1E[62:0]) || xdenorm;
	// assign yzero = ~(|ReadData2E[62:0]) || ydenorm;
	// assign zzero = ~(|ReadData3E[62:0]) || zdenorm;
	// KATHERINE - removed denorm to prevent outputing zero when computing with a denormalized number
	assign xzero = ~(|ReadData1E[62:0]);
	assign yzero = ~(|ReadData2E[62:0]);
	assign zzero = ~(|ReadData3E[62:0]);
 endmodule
