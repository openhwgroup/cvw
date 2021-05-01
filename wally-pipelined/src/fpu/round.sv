///////////////////////////////////////////////////////////////////////////// 
// Block Name:	round.v
// Author:		David Harris
// Date:		11/2/1995
//
// Block Description: 
//   This block is responsible for rounding the normalized result of //   the FMAC.   Because prenormalized results may be bypassed back to //   the FMAC X and z input logics, rounding does not appear in the critical //   path of most floating point code.   This is good because rounding //   requires an entire 52 bit carry-propagate half-adder delay.
//
//   The results from other FPU blocks (e.g. FCVT,  FDIV,  etc)  are also 
//   muxed in to form the actual result for register file writeback.  This
//   saves a mux from the writeback path.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module round(v, sticky, FrmM, wsign,
			  FmaFlagsM, inf, nanM, xnanM, ynanM, znanM, 
			  xman, yman, zman,
			  wman, infinity, specialsel,expplus1);
/////////////////////////////////////////////////////////////////////////////

	input logic		[53:0]		v;		// normalized sum, R, S bits
	input logic				sticky;		//sticky bit
	input logic		[2:0]	FrmM;
	input logic				wsign;		// Sign of result
	input logic 		[4:0]	FmaFlagsM;
	input logic				inf;		// Some input logic is infinity
	input logic				nanM;		// Some input logic is NaN
	input logic				xnanM;		// X is NaN
	input logic				ynanM;		// Y is NaN
	input logic				znanM;		// Z is NaN
	input logic		[51:0]		xman;		// input logic X
	input logic		[51:0]		yman;		// input logic Y
	input logic		[51:0]		zman;		// input logic Z
	output logic		[51:0]		wman; 		// rounded result of FMAC
	output logic				infinity;    	// Generate infinity on overflow
	output logic				specialsel;  	// Select special result
	output logic				expplus1;

	// Internal nodes

	logic				plus1;		// Round by adding one 
	wire		[52:0]		v1;		// Result + 1 (for rounding)
	wire		[51:0]		specialres;	// Result of exceptional case 
	wire		[51:0]		infinityres;	// Infinity or largest real number
	wire		[51:0]		nanres;		// Propagated or generated NaN 

	// Compute if round should occur.  This equation is derived from
	// the rounding tables.

	// round to infinity - plus1 if positive
	// round to -infinity - plus1 if negitive
	// round to zero - do nothing
	// round to nearest even
	//	{v[1], v[0], sticky}
	//	0xx - do nothing
	//	100 - tie - plus1 if v[2] = 1
	//	101/110/111 - plus1
	always_comb begin
		case (FrmM)
			3'b000: plus1 = (v[1] & (v[0] | sticky | (~v[0]&~sticky&v[2])));//round to nearest even
			3'b001: plus1 = 0;//round to zero
			3'b010: plus1 = wsign;//round down
			3'b011: plus1 = ~wsign;//round up
			3'b100: plus1 = (v[1] & (v[0] | sticky | (~v[0]&~sticky&~wsign)));//round to nearest max magnitude
			default: plus1 = 1'bx;
		endcase
	end
	// assign plus1 = (rn & v[1] & (v[0] | sticky | (~v[0]&~sticky&v[2]))) |
	// 	       (rp & ~wsign) |
	// 	       (rm & wsign);
	//assign plus1 = rn && ((v[1] && v[0]) || (v[2] && (v[1]))) ||
	//				 rp && ~wsign && (v[1] || v[0]) ||
	//				 rm && wsign && (v[1] || v[0]);

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
	// input logics to the wide muxes can be combined at the expense of more
	// complicated non-critical control in the circuit implementation.

	assign specialsel =  FmaFlagsM[2] ||  FmaFlagsM[1] ||  FmaFlagsM[4] || //overflow underflow invalid
							nanM || inf;
	assign specialres = FmaFlagsM[4] | nanM ? nanres : //invalid
						 FmaFlagsM[2] ? infinityres : //overflow
						 inf ? 52'b0 :
						 FmaFlagsM[1] ? 52'b0 : 52'bx;  // underflow

	// Overflow is handled differently for different rounding modes
	// Round is to either infinity or to maximum finite number

	assign infinity =  |FrmM;//rn || (rp && ~wsign) || (rm && wsign);//***look into this
	assign infinityres = infinity ? 52'b0 : {52{1'b1}};

	// Invalid operations produce a quiet NaN. The result should
	// propagate an input logic if the input logic is NaN. Since we assume all
	// NaN input logics are already quiet, we don't have to force them quiet.

	// assign nanres = xnanM ? x: (ynanM ? y : (znanM ? z : {1'b1, 51'b0})); // original

	// IEEE 754-2008 section 6.2.3 states:
	// "If two or more input logics are NaN, then the payload of the resulting NaN should be 
	// identical to the payload of one of the input logic NaNs if representable in the destination
	// format. This standard does not specify which of the input logic NaNs will provide the payload."
	assign nanres = xnanM ? {1'b1, xman[50:0]}: (ynanM ? {1'b1, yman[50:0]} : (znanM ? {1'b1, zman[50:0]} : {1'b1, 51'b0}));// KEP 210112 add the 1 to make NaNs quiet

	// Select result with 4:1 mux
	// If the sum is zero and we round up,  there is a special case in
	// which we produce a massive loss of significance and trap to software.
	// It is handled in the exception unit. 
	assign expplus1 = v1[52] & ~specialsel & plus1;
	assign wman = specialsel ? specialres : (plus1 ? v1[51:0] : v[53:2]);
	
endmodule

