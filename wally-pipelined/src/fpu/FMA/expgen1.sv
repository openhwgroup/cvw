/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	expgen.v
// Author:		David Harris
// Date:		11/2/1995
//
//   Block Description:
//   This block implements the exponent path of the FMAC. It performs the
//   following operations:
//
//   1) Compute exponent of multiply.  
//   2) Compare multiply and add exponents to generate alignment shift count
//   3) Adjust exponent based on normalization
//   4)  Increment exponent based on postrounding renormalization
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module expgen1(xexp, yexp, zexp, xzeroE, yzeroE,
			   xdenormE, ydenormE, zdenormE, 
			   aligncntE, prodof, aeE);
/////////////////////////////////////////////////////////////////////////////
  
	input logic     	[62:52]    	xexp;           	// Exponent of multiplicand x
	input logic     	[62:52]  	yexp;         		// Exponent of multiplicand y
	input logic     	[62:52]  	zexp;           	// Exponent of addend z
	input logic     			xdenormE;		// Z is denorm
	input logic     			ydenormE;		// Z is denorm
	input logic     			zdenormE;		// Z is denorm
	input logic     			xzeroE;		// Z is denorm
	input logic     			yzeroE;		// Z is denorm
	output logic		[12:0]   	aligncntE;       // shift count for alignment shifter
	output logic			prodof;         // X*Y exponent out of bounds 
	output logic		[12:0]		aeE;				//exponent of multiply

	//   Internal nodes


	wire 	[12:0]			aligncnt0;		// Shift count for alignment
	wire 	[12:0]			aligncnt1;		// Shift count for alignment
	wire 	[12:0]			be;				// Exponent of multiply
	wire 	[12:0]			de1;			// Normalized exponent
	wire 	[12:0]			de;				// Normalized exponent
	wire 	[10:0]			infinityres;	// Infinity or max number
	wire 	[10:0]			nanres;          //	Nan propagated or generated
	wire 	[10:0]			specialres;  //	Exceptional case result

	//   Compute exponent of multiply
	// Note that the exponent does not have to be incremented on a postrounding
	//   normalization of X because the mantissa was already increased.   Report
	//   if exponent is out of bounds 


	assign aeE = xzeroE|yzeroE ? 0 : {2'b0,xexp} + {2'b0,yexp} - 13'd1023;

	assign prodof = (aeE > 2046 && ~aeE[12]);

	// Compute alignment shift count
	// Adjust for postrounding normalization of Z.
	// This should not increas the critical path because the time to
	// check if a round overflows is shorter than the actual round and
	// is masked by the bypass mux and two 10 bit adder delays.
	// assign aligncnt0 = - 1 + ~xdenormE + ~ydenormE - ~zdenormE;
	// assign aligncnt1 = - 1 + {12'b0,~xdenormE} + {12'b0,~ydenormE} - {12'b0,~zdenormE};
	assign aligncntE = {2'b0,zexp} -aeE - 1 + {12'b0,~xdenormE} + {12'b0,~ydenormE} - {12'b0,~zdenormE};
	//assign aligncntE = zexp -aeE - 1 + ~xdenormE + ~ydenormE - ~zdenormE;
	//assign aligncntE = zexp - aeE;// KEP use all of aeE

	// Select exponent (usually from product except in case of huge addend)

	//assign be = zexpsel ? zexp : aeE;

	// Adjust exponent based on normalization
	// A compound adder takes care of the case of post-rounding normalization
	// requiring an extra increment
	 
	//assign de0 = sumzero ? 13'b0 : be + normcnt + 2;
	// assign de1 = sumzero ? 13'b0 : be + normcnt + 2;
	 

	// bypass occurs before rounding or taking early results 
	
	//assign wbypass = de0[10:0];
	
	// In a non-critical special mux, we combine the early result from other
	// FPU blocks with the results of exceptional conditions.  Overflow
	// produces either infinity or the largest finite number, depending on the
	// rounding mode.  NaNs are propagated or generated.
endmodule


