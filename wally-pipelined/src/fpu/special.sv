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
module special(FInput1E, FInput2E, FInput3E, xzeroE, yzeroE, zzeroE,
				xnanE, ynanE, znanE, xdenormE, ydenormE, zdenormE, xinfE, yinfE, zinfE);
/////////////////////////////////////////////////////////////////////////////

	input logic   	[63:0]     	FInput1E;              // Input FInput1E
	input logic     	[63:0]     	FInput2E;           	// Input FInput2E
	input logic      	[63:0]    	FInput3E;            	// Input FInput3E 
	output logic				xzeroE;		// Input FInput1E = 0
	output logic				yzeroE;		// Input FInput2E = 0
	output logic				zzeroE;		// Input FInput3E = 0
	output logic				xnanE;		// FInput1E is NaN
	output logic				ynanE;		// FInput2E is NaN
	output logic				znanE;		// FInput3E is NaN
	output logic				xdenormE;	// FInput1E is denormalized
	output logic				ydenormE;	// FInput2E is denormalized
	output logic				zdenormE;	// FInput3E is denormalized
	output logic				xinfE;		// FInput1E is infinity
	output logic				yinfE;		// FInput2E is infinity
	output logic				zinfE;		// FInput3E is infinity

	// In the actual circuit design, the gates looking at bits
	// 51:0 and at bits 62:52 should be shared among the various detectors.

	// Check if input is NaN

	assign xnanE = &FInput1E[62:52] && |FInput1E[51:0]; 
	assign ynanE = &FInput2E[62:52] && |FInput2E[51:0]; 
	assign znanE = &FInput3E[62:52] && |FInput3E[51:0];

	// Check if input is denormalized

	assign xdenormE = ~(|FInput1E[62:52]) && |FInput1E[51:0]; 
	assign ydenormE = ~(|FInput2E[62:52]) && |FInput2E[51:0]; 
	assign zdenormE = ~(|FInput3E[62:52]) && |FInput3E[51:0];

	// Check if input is infinity

	assign xinfE = &FInput1E[62:52] && ~(|FInput1E[51:0]); 
	assign yinfE = &FInput2E[62:52] && ~(|FInput2E[51:0]); 
	assign zinfE = &FInput3E[62:52] && ~(|FInput3E[51:0]);

	// Check if inputs are all zero
	// Also forces denormalized inputs to zero.
	//   In the circuit implementation,  this can be optimized
	// to just check if the exponent is zero.
	
	// KATHERINE - commented following (21/01/11)
	// assign xzeroE = ~(|FInput1E[62:0]) || xdenormE;
	// assign yzeroE = ~(|FInput2E[62:0]) || ydenormE;
	// assign zzeroE = ~(|FInput3E[62:0]) || zdenormE;
	// KATHERINE - removed denorm to prevent output logicing zero when computing with a denormalized number
	assign xzeroE = ~(|FInput1E[62:0]);
	assign yzeroE = ~(|FInput2E[62:0]);
	assign zzeroE = ~(|FInput3E[62:0]);
 endmodule
