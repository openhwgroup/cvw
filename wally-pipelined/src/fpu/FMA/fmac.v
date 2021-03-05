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
module fmac(xrf, y, zrf, rn, rz, rp, rm,
			earlyres, earlyressel, bypsel, bypplus1, byppostnorm, 
			w, wbypass, invalid, overflow, underflow, inexact);
/////////////////////////////////////////////////////////////////////////////
 
	input 		[63:0]		xrf;			// input X from reg file
	input		[63:0]		y;				// input Y  
	input 		[63:0]		zrf;          	// input Z from reg file 
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
 
	wire 		[63:0]		x;				// input X after bypass mux
	wire 		[63:0]		z; 				// input Z after bypass mux
	wire 		[105:0]		r; 				// one result of partial product sum
	wire 		[105:0]		s; 				// other result of partial products
	wire 		[157:0]		t;				// output of alignment shifter
	wire 		[157:0]		sum;			// output of carry prop adder
	wire 		[53:0]		v; 				// normalized sum, R, S bits
	wire 		[11:0]		aligncnt; 		// shift count for alignment
	wire 		[8:0]		normcnt; 		// shift count for normalizer
	wire 		[12:0]		ae; 		// multiplier expoent
	wire 					bs;				// sticky bit of addend
	wire 					ps;				// sticky bit of product
	wire 					killprod; 		// Z >> product
	wire 					negsum; 		// negate sum
	wire 					invz; 			// invert addend
	wire 					selsum1; 		// select +1 mode of sum
	wire 					negsum0; 		// sum +0 < 0
	wire 					negsum1; 		// sum +1 < 0
	wire 					sumzero; 		// sum = 0
	wire 					infinity; 		// generate infinity on overflow
	wire 					prodof; 		// X*Y out of range
	wire 					sumof;			// result out of range

//   Instantiate fraction datapath

	array			array(x[51:0], y[51:0], xdenorm, ydenorm, r[105:0], s[105:0],
						  bypsel[0], bypplus1);
	align			align(z[51:0], ae, aligncnt, xzero, yzero,  zzero, zdenorm, proddenorm,
					      t[157:0], bs, ps, killprod, 
						  bypsel[1], bypplus1, byppostnorm);
	add				add(r[105:0], s[105:0], t[157:0], sum[157:0],
					    negsum, invz, selsum1, killprod, negsum0, negsum1, proddenorm);
	lop				lop(sum, normcnt, sumzero);
	normalize		normalize(sum[157:0], normcnt, sumzero, bs, ps, denorm0, zdenorm,
							  v[53:0]); 
	round			round(v[53:0], earlyres[51:0], earlyressel, rz, rn, rp, rm, w[63],
						  invalid, overflow,  underflow, inf, nan, xnan, ynan, znan,
						  x[51:0], y[51:0],  z[51:0],
						  w[51:0], postnorrnalize, infinity, specialsel);
	bypass			bypass(xrf[63:0], zrf[63:0], wbypass[63:0], bypsel[1:0],
						   x[63:0], z[63:0]); 

// Instantiate exponent datapath

	expgen			expgen(x[62:52], y[62:52], z[62:52],
						   earlyres[62:52], earlyressel, bypsel[1], byppostnorm,
						   killprod, sumzero, postnorrnalize, normcnt, 
						   infinity, invalid, overflow, underflow, 
						   inf, nan, xnan, ynan, znan, zdenorm, proddenorm, specialsel,
						   aligncnt, w[62:52], wbypass[62:52],
						   prodof, sumof, sumuf, denorm0, ae);
// Instantiate special case detection across datapath & exponent path 

	special			special(x[63:0], y[63:0], z[63:0], ae, xzero, yzero, zzero,
							xnan, ynan, znan, xdenorm, ydenorm, zdenorm, proddenorm,
							xinf, yinf, zinf);

// Produce W for bypass

assign wbypass[51:0] = v[53:2];
assign wbypass[63] = w[63];

// Instantiate control logic
 
sign				sign(x[63], y[63], z[63], negsum0, negsum1, bs, ps, 
					     killprod, rm, overflow, sumzero, nan, invalid, xinf, yinf, zinf, inf, 
						 w[63], invz, negsum, selsum1, psign); 
flag				flag(xnan, ynan, znan, xinf, yinf, zinf, prodof, sumof, sumuf,
						 psign, z[63], xzero, yzero, v[1:0],
						 inf, nan, invalid, overflow, underflow, inexact); 

endmodule

