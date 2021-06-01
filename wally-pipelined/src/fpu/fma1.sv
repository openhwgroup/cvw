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
//    bypass    Handles bypass of result to FInput1E or FInput3E inputs
//    sign      One bit sign handling block 
//    special   Catch special cases (inputs = 0  / infinity /  etc.) 
//
//   The FMAC computes FmaResultM=FInput1E*FInput2E+FInput3E, rounded with the mode specified by
//   RN, RZ, RM, or RP.  The result is optionally bypassed back to
//   the FInput1E or FInput3E inputs for use on the next cycle.  In addition,  four signals
//   are produced: trap, overflow, underflow, and inexact.  Trap indicates
//   an infinity, NaN, or denormalized number to be handled in software;
//   the other three signals are IEEE flags.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module fma1(FInput1E, FInput2E, FInput3E, FrmE,  
			rE, sE, tE, bsE, killprodE, sumshiftE, sumshiftzeroE,  aligncntE, aeE
			, xzeroE, yzeroE, zzeroE, xnanE,ynanE, znanE, xdenormE, ydenormE, zdenormE,
			xinfE, yinfE, zinfE, nanE, prodinfE);
/////////////////////////////////////////////////////////////////////////////
 
	input logic 		[63:0]		FInput1E;		// input 1
	input logic		[63:0]		FInput2E;     // input 2 
	input logic 		[63:0]		FInput3E;     // input 3
	input logic 		[2:0]	 	FrmE;          	// Rounding mode
	output logic 		[12:0]		aligncntE;    	// status flags
	output logic 		[105:0]		rE; 				// one result of partial product sum
	output logic 		[105:0]		sE; 				// other result of partial products
	output logic 		[163:0]		tE;				// output logic of alignment shifter	
	output logic 		[12:0]		aeE; 		// multiplier expoent
	output logic 					bsE;				// sticky bit of addend
	output logic 					killprodE; 		// FInput3E >> product
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


	logic 					prodof; 		// FInput1E*FInput2E out of range













//   Instantiate fraction datapath

	multiply		multiply(.xman(FInput1E[51:0]), .yman(FInput2E[51:0]), .*);
	align			align(.zman(FInput3E[51:0]),.*);

// Instantiate exponent datapath

	expgen1			expgen1(.xexp(FInput1E[62:52]),.yexp(FInput2E[62:52]),.zexp(FInput3E[62:52]),.*);
// Instantiate special case detection across datapath & exponent path 

	special			special(.*);


// Instantiate control output logic
 
flag1				flag1(.*); 

endmodule

