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
//    expgen    Mxponent summation, compare, and adjust
//    align     Alignment shifter
//    add       Carry-save adder for accumulate, carry propagate adder
//    lza       Leading zero anticipator to control normalization shifter
//    normalize Normalization shifter
//    round     Rounding of result
//    exception Handles exceptional cases
//    bypass    Handles bypass of result to ReadData1M or ReadData3M inputs
//    sign      One bit sign handling block 
//    special   Catch special cases (inputs = 0  / infinity /  etc.) 
//
//   The FMAC computes FmaResultM=ReadData1M*ReadData2M+ReadData3M, rounded with the mode specified by
//   RN, RZ, RM, or RP.  The result is optionally bypassed back to
//   the ReadData1M or ReadData3M inputs for use on the next cycle.  In addition,  four signals
//   are produced: trap, overflow, underflow, and inexact.  Trap indicates
//   an infinity, NaN, or denormalized number to be handled in software;
//   the other three signals are IMMM flags.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module fma2(ReadData1M, ReadData2M, ReadData3M, FrmM,
			FmaResultM, FmaFlagsM, aligncntM, rM, sM,
			tM,	normcntM, aeM, bsM,killprodM,
			xzeroM,	yzeroM,zzeroM,xdenormM,ydenormM,
			zdenormM,xinfM,yinfM,zinfM,xnanM,ynanM,znanM,
			nanM,sumshiftM,sumshiftzeroM,prodinfM

);
/////////////////////////////////////////////////////////////////////////////
 
	input 		[63:0]		ReadData1M;		// input 1
	input		[63:0]		ReadData2M;     // input 2 
	input 		[63:0]		ReadData3M;     // input 3
	input 		[2:0]	 	FrmM;          	// Rounding mode
	input 		[12:0]		aligncntM;    	// status flags
	input 		[105:0]		rM; 				// one result of partial product sum
	input 		[105:0]		sM; 				// other result of partial products
	input 		[163:0]		tM;				// output of alignment shifter	
	input 		[8:0]		normcntM; 		// shift count for normalizer
	input 		[12:0]		aeM; 		// multiplier expoent
	input 					bsM;				// sticky bit of addend
	input 					killprodM; 		// ReadData3M >> product
	input					prodinfM;
	input					xzeroM;
	input					yzeroM;
	input					zzeroM;
	input					xdenormM;
	input					ydenormM;
	input					zdenormM;
	input					xinfM;
	input					yinfM;
	input					zinfM;
	input					xnanM;
	input					ynanM;
	input					znanM;
	input					nanM;
	input			[8:0]		sumshiftM;
	input					sumshiftzeroM;


	input 		[63:0]		FmaResultM;     // output FmaResultM=ReadData1M*ReadData2M+ReadData3M
	output 		[4:0]		FmaFlagsM;    	// status flags
	

// Internal nodes
 	logic 		[163:0]		sum;			// output of carry prop adder
	logic 		[53:0]		v; 				// normalized sum, R, S bits
//	logic 		[12:0]		aligncnt; 		// shift count for alignment
	logic 		[8:0]		normcnt; 		// shift count for normalizer
	logic 					negsum; 		// negate sum
	logic 					invz; 			// invert addend
	logic 					selsum1; 		// select +1 mode of sum
	logic 					negsum0; 		// sum +0 < 0
	logic 					negsum1; 		// sum +1 < 0
	logic 					sumzero; 		// sum = 0
	logic 					infinity; 		// generate infinity on overflow
	logic 					sumof;			// result out of range
	logic					zexpsel;
	logic					denorm0;
	logic					resultdenorm;
	logic					inf;
	logic					specialsel;
	logic					expplus1;
	logic					sumuf;
	logic					psign;
	logic					sticky;
	logic			[12:0]		de0;
	logic					isAdd;

	assign isAdd = 1;














//   Instantiate fraction datapath

	add				add(.*);
	lza				lza(.*);
	normalize		normalize(.zexp(ReadData3M[62:52]),.*); 
	round			round(.xman(ReadData1M[51:0]), .yman(ReadData2M[51:0]),.zman(ReadData3M[51:0]), .wman(FmaResultM[51:0]),.wsign(FmaResultM[63]),.*);

// Instantiate exponent datapath

	expgen2			expgen2(.xexp(ReadData1M[62:52]),.yexp(ReadData2M[62:52]),.zexp(ReadData3M[62:52]),.wexp(FmaResultM[62:52]),.*);


// Instantiate control logic
 
sign				sign(.xsign(ReadData1M[63]),.ysign(ReadData2M[63]),.zsign(ReadData3M[63]),.wsign(FmaResultM[63]),.*); 
flag2				flag2(.xsign(ReadData1M[63]),.ysign(ReadData2M[63]),.zsign(ReadData3M[63]),.vbits(v[1:0]),.*); 

endmodule

