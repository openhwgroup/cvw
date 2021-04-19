/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	flag.v
// Author:		David Harris
// Date:		12/6/1995
//
// Block Description:
//       This block generates the flags: invalid, overflow, underflow, inexact. 
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module flag1(xnanE, ynanE, znanE, prodof, prodinfE, nanE);
/////////////////////////////////////////////////////////////////////////////

	input logic                  		xnanE;        	// X is NaN 
	input logic                  		ynanE;        	// Y is NaN 
	input logic                 		znanE;       	// Z is NaN
	input logic                  		prodof;         // X*Y overflows exponent
	output logic				nanE;		// Some	source is NaN
 
	//   Internal nodes

	output logic				prodinfE;	// X*Y larger than max possible

	// If any input is NaN, propagate the NaN 

	assign nanE = xnanE || ynanE || znanE;


	// Generate infinity checks

	assign prodinfE = prodof && ~xnanE && ~ynanE;


endmodule
