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
module special(ReadData1E, ReadData2E, ReadData3E, xzeroE, yzeroE, zzeroE,
				xnanE, ynanE, znanE, xdenormE, ydenormE, zdenormE, xinfE, yinfE, zinfE);
/////////////////////////////////////////////////////////////////////////////

	input logic   	[63:0]     	ReadData1E;              // Input ReadData1E
	input logic     	[63:0]     	ReadData2E;           	// Input ReadData2E
	input logic      	[63:0]    	ReadData3E;            	// Input ReadData3E 
	output logic				xzeroE;		// Input ReadData1E = 0
	output logic				yzeroE;		// Input ReadData2E = 0
	output logic				zzeroE;		// Input ReadData3E = 0
	output logic				xnanE;		// ReadData1E is NaN
	output logic				ynanE;		// ReadData2E is NaN
	output logic				znanE;		// ReadData3E is NaN
	output logic				xdenormE;	// ReadData1E is denormalized
	output logic				ydenormE;	// ReadData2E is denormalized
	output logic				zdenormE;	// ReadData3E is denormalized
	output logic				xinfE;		// ReadData1E is infinity
	output logic				yinfE;		// ReadData2E is infinity
	output logic				zinfE;		// ReadData3E is infinity

	// In the actual circuit design, the gates looking at bits
	// 51:0 and at bits 62:52 should be shared among the various detectors.

	// Check if input is NaN

	assign xnanE = &ReadData1E[62:52] && |ReadData1E[51:0]; 
	assign ynanE = &ReadData2E[62:52] && |ReadData2E[51:0]; 
	assign znanE = &ReadData3E[62:52] && |ReadData3E[51:0];

	// Check if input is denormalized

	assign xdenormE = ~(|ReadData1E[62:52]) && |ReadData1E[51:0]; 
	assign ydenormE = ~(|ReadData2E[62:52]) && |ReadData2E[51:0]; 
	assign zdenormE = ~(|ReadData3E[62:52]) && |ReadData3E[51:0];

	// Check if input is infinity

	assign xinfE = &ReadData1E[62:52] && ~(|ReadData1E[51:0]); 
	assign yinfE = &ReadData2E[62:52] && ~(|ReadData2E[51:0]); 
	assign zinfE = &ReadData3E[62:52] && ~(|ReadData3E[51:0]);

	// Check if inputs are all zero
	// Also forces denormalized inputs to zero.
	//   In the circuit implementation,  this can be optimized
	// to just check if the exponent is zero.
	
	// KATHERINE - commented following (21/01/11)
	// assign xzeroE = ~(|ReadData1E[62:0]) || xdenormE;
	// assign yzeroE = ~(|ReadData2E[62:0]) || ydenormE;
	// assign zzeroE = ~(|ReadData3E[62:0]) || zdenormE;
	// KATHERINE - removed denorm to prevent output logicing zero when computing with a denormalized number
	assign xzeroE = ~(|ReadData1E[62:0]);
	assign yzeroE = ~(|ReadData2E[62:0]);
	assign zzeroE = ~(|ReadData3E[62:0]);
 endmodule
