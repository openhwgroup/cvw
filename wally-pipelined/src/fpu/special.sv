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
module special(Input1E, Input2E, Input3E, xzeroE, yzeroE, zzeroE,
				xnanE, ynanE, znanE, xdenormE, ydenormE, zdenormE, xinfE, yinfE, zinfE);
/////////////////////////////////////////////////////////////////////////////

	input logic   	[63:0]     	Input1E;              // Input Input1E
	input logic     	[63:0]     	Input2E;           	// Input Input2E
	input logic      	[63:0]    	Input3E;            	// Input Input3E 
	output logic				xzeroE;		// Input Input1E = 0
	output logic				yzeroE;		// Input Input2E = 0
	output logic				zzeroE;		// Input Input3E = 0
	output logic				xnanE;		// Input1E is NaN
	output logic				ynanE;		// Input2E is NaN
	output logic				znanE;		// Input3E is NaN
	output logic				xdenormE;	// Input1E is denormalized
	output logic				ydenormE;	// Input2E is denormalized
	output logic				zdenormE;	// Input3E is denormalized
	output logic				xinfE;		// Input1E is infinity
	output logic				yinfE;		// Input2E is infinity
	output logic				zinfE;		// Input3E is infinity

	// In the actual circuit design, the gates looking at bits
	// 51:0 and at bits 62:52 should be shared among the various detectors.

	// Check if input is NaN

	assign xnanE = &Input1E[62:52] && |Input1E[51:0]; 
	assign ynanE = &Input2E[62:52] && |Input2E[51:0]; 
	assign znanE = &Input3E[62:52] && |Input3E[51:0];

	// Check if input is denormalized

	assign xdenormE = ~(|Input1E[62:52]) && |Input1E[51:0]; 
	assign ydenormE = ~(|Input2E[62:52]) && |Input2E[51:0]; 
	assign zdenormE = ~(|Input3E[62:52]) && |Input3E[51:0];

	// Check if input is infinity

	assign xinfE = &Input1E[62:52] && ~(|Input1E[51:0]); 
	assign yinfE = &Input2E[62:52] && ~(|Input2E[51:0]); 
	assign zinfE = &Input3E[62:52] && ~(|Input3E[51:0]);

	// Check if inputs are all zero
	// Also forces denormalized inputs to zero.
	//   In the circuit implementation,  this can be optimized
	// to just check if the exponent is zero.
	
	// KATHERINE - commented following (21/01/11)
	// assign xzeroE = ~(|Input1E[62:0]) || xdenormE;
	// assign yzeroE = ~(|Input2E[62:0]) || ydenormE;
	// assign zzeroE = ~(|Input3E[62:0]) || zdenormE;
	// KATHERINE - removed denorm to prevent output logicing zero when computing with a denormalized number
	assign xzeroE = ~(|Input1E[62:0]);
	assign yzeroE = ~(|Input2E[62:0]);
	assign zzeroE = ~(|Input3E[62:0]);
 endmodule
