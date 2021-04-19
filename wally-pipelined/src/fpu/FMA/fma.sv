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
//    bypass    Handles bypass of result to ReadData1E or ReadData3E inputs
//    sign      One bit sign handling block 
//    special   Catch special cases (inputs = 0  / infinity /  etc.) 
//
//   The FMAC computes FmaResultM=ReadData1E*ReadData2E+ReadData3E, rounded with the mode specified by
//   RN, RZ, RM, or RP.  The result is optionally bypassed back to
//   the ReadData1E or ReadData3E inputs for use on the next cycle.  In addition,  four signals
//   are produced: trap, overflow, underflow, and inexact.  Trap indicates
//   an infinity, NaN, or denormalized number to be handled in software;
//   the other three signals are IEEE flags.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module fma(ReadData1E, ReadData2E, ReadData3E, FrmE,
			FmaResultM, FmaFlagsM, aligncnt);
/////////////////////////////////////////////////////////////////////////////
 
	input 		[63:0]		ReadData1E;		// input 1
	input		[63:0]		ReadData2E;     // input 2 
	input 		[63:0]		ReadData3E;     // input 3
	input 		[2:0]	 	FrmE;          	// Rounding mode
	output 		[63:0]		FmaResultM;     // output FmaResultM=ReadData1E*ReadData2E+ReadData3E
	output 		[4:0]		FmaFlagsM;    	// status flags
	output 		[12:0]		aligncnt;    	// status flags

// Internal nodes
 
	logic 		[105:0]		r; 				// one result of partial product sum
	logic 		[105:0]		s; 				// other result of partial products
	logic 		[163:0]		t;				// output of alignment shifter
	logic 		[163:0]		sum;			// output of carry prop adder
	logic 		[53:0]		v; 				// normalized sum, R, S bits
//	logic 		[12:0]		aligncnt; 		// shift count for alignment
	logic 		[8:0]		normcnt; 		// shift count for normalizer
	logic 		[12:0]		ae; 		// multiplier expoent
	logic 					bs;				// sticky bit of addend
	logic 					ps;				// sticky bit of product
	logic 					killprod; 		// ReadData3E >> product
	logic 					negsum; 		// negate sum
	logic 					invz; 			// invert addend
	logic 					selsum1; 		// select +1 mode of sum
	logic 					negsum0; 		// sum +0 < 0
	logic 					negsum1; 		// sum +1 < 0
	logic 					sumzero; 		// sum = 0
	logic 					infinity; 		// generate infinity on overflow
	logic 					prodof; 		// ReadData1E*ReadData2E out of range
	logic 					sumof;			// result out of range
	logic					xzero;
	logic					yzero;
	logic					zzero;
	logic					xdenorm;
	logic					ydenorm;
	logic					zdenorm;
	logic					proddenorm;
	logic					zexpsel;
	logic					denorm0;
	logic					resultdenorm;
	logic					inf;
	logic					xinf;
	logic					yinf;
	logic					zinf;
	logic					xnan;
	logic					ynan;
	logic					znan;
	logic					specialsel;
	logic					expplus1;
	logic					nan;
	logic					sumuf;
	logic					psign;
	logic					sticky;
	logic			[8:0]		sumshift;
	logic					sumshiftzero;
	logic			[12:0]		de0;
	logic					isAdd;

	assign isAdd = 1;














//   Instantiate fraction datapath

	multiply		multiply(.xman(ReadData1E[51:0]), .yman(ReadData2E[51:0]), .*);
	align			align(.zman(ReadData3E[51:0]),.*);
	add				add(.*);
	lza				lza(.*);
	normalize		normalize(.zexp(ReadData3E[62:52]),.*); 
	round			round(.xman(ReadData1E[51:0]), .yman(ReadData2E[51:0]),.zman(ReadData3E[51:0]), .wman(FmaResultM[51:0]),.wsign(FmaResultM[63]),.*);

// Instantiate exponent datapath

	expgen			expgen(.xexp(ReadData1E[62:52]),.yexp(ReadData2E[62:52]),.zexp(ReadData3E[62:52]),.wexp(FmaResultM[62:52]),.*);
// Instantiate special case detection across datapath & exponent path 

	special			special(.*);


// Instantiate control logic
 
sign				sign(.xsign(ReadData1E[63]),.ysign(ReadData2E[63]),.zsign(ReadData3E[63]),.wsign(FmaResultM[63]),.*); 
flag				flag(.zsign(ReadData3E[63]),.vbits(v[1:0]),.*); 

endmodule

