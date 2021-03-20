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
//    bypass    Handles bypass of result to X or Z inputs
//    sign      One bit sign handling block 
//    special   Catch special cases (inputs = 0  / infinity /  etc.) 
//
//   The FMAC computes W=X*Y+Z, rounded with the mode specified by
//   RN, RZ, RM, or RP.  The result is optionally bypassed back to
//   the X or Z inputs for use on the next cycle.  In addition,  four signals
//   are produced: trap, overflow, underflow, and inexact.  Trap indicates
//   an infinity, NaN, or denormalized number to be handled in software;
//   the other three signals are IEEE flags.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module fmac(x, y, z, rn, rz, rp, rm,
			earlyres, earlyressel, bypsel, bypplus1, byppostnorm, 
			w, wbypass, invalid, overflow, underflow, inexact);
/////////////////////////////////////////////////////////////////////////////
 
	input 		[63:0]		x;			// input X from reg file
	input		[63:0]		y;				// input Y  
	input 		[63:0]		z;          	// input Z from reg file 
	input 			 		rn;          	// Round to Nearest
	input 					rz;           	// Round toward zero
	input 					rm;          	// Round toward minus infinity
	input 					rp;          	// Round toward plus infinity
	input 		[63:0]		earlyres;    	// Early result from other FP logic
	input 					earlyressel;	// Select early result, not W 
	input 		[1:0]		bypsel;     	// Select W bypass to X, or z 
	input 					bypplus1;    	// Add one in bypass
	input 					byppostnorm;	// postnormalize in bypass
	output 		[63:0]		w;           	// output W=X*Y+Z
	output 		[63:0]		wbypass;     	// prerounded output W=X*Y+Z for bypass
	output 					invalid;    	// Result is invalid 
	output					overflow;		// Result overflowed 
	output					underflow;   	// Result underflowed
	output 					inexact;     	// Result is not an exact number 

// Internal nodes
 
	logic 		[105:0]		r; 				// one result of partial product sum
	logic 		[105:0]		s; 				// other result of partial products
	logic 		[163:0]		t;				// output of alignment shifter
	logic 		[163:0]		sum;			// output of carry prop adder
	logic 		[53:0]		v; 				// normalized sum, R, S bits
	logic 		[11:0]		aligncnt; 		// shift count for alignment
	logic 		[8:0]		normcnt; 		// shift count for normalizer
	logic 		[12:0]		ae; 		// multiplier expoent
	logic 					bs;				// sticky bit of addend
	logic 					ps;				// sticky bit of product
	logic 					killprod; 		// Z >> product
	logic 					negsum; 		// negate sum
	logic 					invz; 			// invert addend
	logic 					selsum1; 		// select +1 mode of sum
	logic 					negsum0; 		// sum +0 < 0
	logic 					negsum1; 		// sum +1 < 0
	logic 					sumzero; 		// sum = 0
	logic 					infinity; 		// generate infinity on overflow
	logic 					prodof; 		// X*Y out of range
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
	logic					nan;
	logic					sumuf;
	logic					psign;
	logic			[8:0]		sumshift;
	logic			[12:0]		de0;














//   Instantiate fraction datapath

	multiply		multiply(.xman(x[51:0]), .yman(y[51:0]), .*);
	align			align(.zman(z[51:0]),.*);
	add				add(.*);
	lza				lza(.*);
	normalize		normalize(.zexp(z[62:52]),.*); 
	round			round(.xman(x[51:0]), .yman(y[51:0]),.zman(z[51:0]), .wman(w[51:0]),.wsign(w[63]),.*);

// Instantiate exponent datapath

	expgen			expgen(.xexp(x[62:52]),.yexp(y[62:52]),.zexp(z[62:52]),.wexp(w[62:52]),.*);
// Instantiate special case detection across datapath & exponent path 

	special			special(.*);


// Instantiate control logic
 
sign				sign(.xsign(x[63]),.ysign(y[63]),.zsign(z[63]),.wsign(w[63]),.*); 
flag				flag(.zsign(z[63]),.vbits(v[1:0]),.*); 

endmodule

