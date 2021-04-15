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

	input                  		xnanE;        	// X is NaN 
	input                  		ynanE;        	// Y is NaN 
	input                 		znanE;       	// Z is NaN
	input                  		prodof;         // X*Y overflows exponent
	output				nanE;		// Some	source is NaN
 
	//   Internal nodes

	output				prodinfE;	// X*Y larger than max possible

	// If any input is NaN, propagate the NaN 

	assign nanE = xnanE || ynanE || znanE;


	// Generate infinity checks

	assign prodinfE = prodof && ~xnanE && ~ynanE;


endmodule
