 ////////////////////////////////////////////////////////////////////////////////
// Block Name:	fmac.v
// Author:		David Harris
// Date:		11/2/1995
//
// Block Description:
//   This is the top level block of a floating-point  multiply/accumulate
//   unit(FMAC).   It instantiates the following sub-blocks:
//
//    array     Booth encoding, partial product generation, product summation
//    expgen    Exponent summation, compare, and adjust
//    align     Alignment shifter
//    add       Carry-save adder for accumulate, carry propagate adder
//    lza       Leading zero anticipator to control normalization shifter
//    normalize Normalization shifter
//    round     Rounding of result
//    exception Handles exceptional cases
//    bypass    Handles bypass of result to Input1E or Input3E inputs
//    sign      One bit sign handling block 
//    special   Catch special cases (inputs = 0  / infinity /  etc.) 
//
//   The FMAC computes FmaResultM=Input1E*Input2E+Input3E, rounded with the mode specified by
//   RN, RZ, RM, or RP.  The result is optionally bypassed back to
//   the Input1E or Input3E inputs for use on the next cycle.  In addition,  four signals
//   are produced: trap, overflow, underflow, and inexact.  Trap indicates
//   an infinity, NaN, or denormalized number to be handled in software;
//   the other three signals are IEEE flags.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module fma1(Input1E, Input2E, Input3E, FrmE,  
			rE, sE, tE, bsE, killprodE, sumshiftE, sumshiftzeroE,  aligncntE, aeE
			, xzeroE, yzeroE, zzeroE, xnanE,ynanE, znanE, xdenormE, ydenormE, zdenormE,
			xinfE, yinfE, zinfE, nanE, prodinfE);
/////////////////////////////////////////////////////////////////////////////
 
	input logic 		[63:0]		Input1E;		// input 1
	input logic		[63:0]		Input2E;     // input 2 
	input logic 		[63:0]		Input3E;     // input 3
	input logic 		[2:0]	 	FrmE;          	// Rounding mode
	output logic 		[12:0]		aligncntE;    	// status flags
	output logic 		[105:0]		rE; 				// one result of partial product sum
	output logic 		[105:0]		sE; 				// other result of partial products
	output logic 		[163:0]		tE;				// output logic of alignment shifter	
	output logic 		[12:0]		aeE; 		// multiplier expoent
	output logic 					bsE;				// sticky bit of addend
	output logic 					killprodE; 		// Input3E >> product
	output logic					xzeroE;
	output logic					yzeroE;
	output logic					zzeroE;
	output logic					xdenormE;
	output logic					ydenormE;
	output logic					zdenormE;
	output logic					xinfE;
	output logic					yinfE;
	output logic					zinfE;
	output logic					xnanE;
	output logic					ynanE;
	output logic					znanE;
	output logic					nanE;
	output logic					prodinfE;
	output logic			[8:0]		sumshiftE;
	output logic					sumshiftzeroE;

// Internal nodes
 
//	output logic 		[12:0]		aligncntE; 		// shift count for alignment


	logic 					prodof; 		// Input1E*Input2E out of range













//   Instantiate fraction datapath

	multiply		multiply(.xman(Input1E[51:0]), .yman(Input2E[51:0]), .*);
	align			align(.zman(Input3E[51:0]),.*);

// Instantiate exponent datapath

	expgen1			expgen1(.xexp(Input1E[62:52]),.yexp(Input2E[62:52]),.zexp(Input3E[62:52]),.*);
// Instantiate special case detection across datapath & exponent path 

	special			special(.*);


// Instantiate control output logic
 
flag1				flag1(.*); 

endmodule

