///////////////////////////////////////////////////////////////////////////// 
// Block Name:	round.v
// Author:		David Harris
// Date:		11/2/1995
//
// Block Description: 
//   This block is responsible for rounding the normalized result of //   the FMAC.   Because prenormalized results may be bypassed back to //   the FMAC X and z inputs, rounding does not appear in the critical //   path of most floating point code.   This is good because rounding //   requires an entire 52 bit carry-propagate half-adder delay.
//
//   The results from other FPU blocks (e.g. FCVT,  FDIV,  etc)  are also 
//   muxed in to form the actual result for register file writeback.  This
//   saves a mux from the writeback path.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module round(v, rz, rn, rp, rm, wsign,
			  invalid, overflow, underflow, inf, nan, xnan, ynan, znan, 
			  xman, yman, zman,
			  wman, infinity, specialsel);
/////////////////////////////////////////////////////////////////////////////

	input		[53:0]		v;		// normalized sum, R, S bits
	input				rz;		// Round toward zero
	input				rn;		// Round toward	nearest
	input				rp;		// Round toward	plus infinity
	input				rm;		// Round toward	minus infinity
	input				wsign;		// Sign of result
	input 				invalid;	// Trap on infinity, NaN, denorm
	input				overflow;	// Result overflowed
	input				underflow;	// Result underflowed
	input				inf;		// Some input is infinity
	input				nan;		// Some input is NaN
	input				xnan;		// X is NaN
	input				ynan;		// Y is NaN
	input				znan;		// Z is NaN
	input		[51:0]		xman;		// Input X
	input		[51:0]		yman;		// Input Y
	input		[51:0]		zman;		// Input Z
	output		[51:0]		wman; 		// rounded result of FMAC
	//output				postnormalize; 	// Right shift 1 for post-rounding norm
	output				infinity;    	// Generate infinity on overflow
	output				specialsel;  	// Select special result

	// Internal nodes

	wire				plus1;		// Round by adding one 
	wire		[52:0]		v1;		// Result + 1 (for rounding)
	wire		[51:0]		specialres;	// Result of exceptional case 
	wire		[51:0]		infinityres;	// Infinity or largest real number
	wire		[51:0]		nanres;		// Propagated or generated NaN 

	// Compute if round should occur.  This equation is derived from
	// the rounding tables.


	assign plus1 = rn && ((v[1] && v[0]) || (v[2] && (v[1]))) ||
					 rp && ~wsign && (v[1] || v[0]) ||
					 rm && wsign && (v[1] || v[0]);

	// Compute rounded result 
    assign v1 = v[53:2] + 1;
	// Determine if postnormalization is necessary
	// Predicted by all bits =1 before round +1

	//assign postnormalize = &(v[53:2]) && plus1;

	// Determine special result in event of of selection of a result from
	// another FPU functional unit,  infinity, NAN,  or underflow
	// The special result mux is a 4:1 mux that should not appear in the
	// critical path of the machine.   It is not priority encoded,  despite
	// the code below suggesting otherwise.  Also,  several of the identical data
	// inputs to the wide muxes can be combined at the expense of more
	// complicated non-critical control in the circuit implementation.

	assign specialsel =  overflow || underflow || invalid ||
							nan || inf;
	assign specialres = invalid | nan ? nanres : //KEP added nan
						 overflow ? infinityres : 
						 inf ? 52'b0 :
						underflow ? 52'b0 : 52'bx;  // default to undefined 

	// Overflow is handled differently for different rounding modes
	// Round is to either infinity or to maximum finite number

	assign infinity = rn || (rp && ~wsign) || (rm && wsign);
	assign infinityres = infinity ? 52'b0 : {52{1'b1}};

	// Invalid operations produce a quiet NaN. The result should
	// propagate an input if the input is NaN. Since we assume all
	// NaN inputs are already quiet, we don't have to force them quiet.

	// assign nanres = xnan ? x: (ynan ? y : (znan ? z : {1'b1, 51'b0})); // original

	// IEEE 754-2008 section 6.2.3 states:
	// "If two or more inputs are NaN, then the payload of the resulting NaN should be 
	// identical to the payload of one of the input NaNs if representable in the destination
	// format. This standard does not specify which of the input NaNs will provide the payload."
	assign nanres = xnan ? {1'b1, xman[50:0]}: (ynan ? {1'b1, yman[50:0]} : (znan ? {1'b1, zman[50:0]} : {1'b1, 51'b0}));// KEP 210112 add the 1 to make NaNs quiet

	// Select result with 4:1 mux
	// If the sum is zero and we round up,  there is a special case in
	// which we produce a massive loss of significance and trap to software.
	// It is handled in the exception unit. 

	assign wman = specialsel ? specialres : (plus1 ? v1[51:0] : v[53:2]);
	
endmodule

