/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	align.v
// Author:		David Harris
// Date:		11/2/1995
//
// Block Description:
//   This block implements the alignment shifter.   It is responsible for
//   adjusting the fraction portion of the addend relative to the fraction
//   produced in the multiplier array.
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module align(zman, aligncntE, xzeroE, yzeroE, zzeroE, zdenormE, tE, bsE, 
             killprodE,  sumshiftE, sumshiftzeroE);
/////////////////////////////////////////////////////////////////////////////

	input 		[51:0]		zman;		// Fraction of addend z;
	input 		[12:0]		aligncntE;	// amount to shift
	input				xzeroE;		// Input X = 0
	input                  		yzeroE;          // Input Y = 0 
	input                  		zzeroE;          // Input Z = 0
	input                  		zdenormE;        // Input Z is denormalized
	output    	[163:0]    	tE;              // aligned addend (54 bits left of bpt)
	output          		bsE;           	// sticky bit of addend
	output          		killprodE;    	// Z >> product
	output		[7:0]		sumshiftE;	
	output				sumshiftzeroE;

	// Internal nodes
 
	reg       	[163:0]   	tE;				// aligned addend from shifter
	reg       	[215:0]   	shift;				// aligned addend from shifter
	reg             		killprodE;			// Z >> product 
	reg             		bsE;				// sticky bit of addend
	reg             		ps;				// sticky bit of product
	reg             		zexpsel;				// sticky bit of product
	reg       	[7:0]		i;				// temp storage for finding sticky bit
	wire		[52:0]		z1;				// Z plus 1
	wire		[51:0]		z2;				// Z selected after handling rounds
	wire		[11:0]		align104;			// alignment count + 104
	logic		[8:0]		sumshiftE;
	logic sumshiftzeroE;



	// Compute sign of aligncntE + 104 to check for shifting too far right 

	//assign align104 = aligncntE+104;
	
	// Shift addend by alignment count.  Generate sticky bits from
	// addend on right shifts.  Handle special cases of shifting
	// by too much.

	always @(aligncntE or xzeroE or yzeroE or zman or zdenormE or zzeroE)
		begin

		// Default to clearing sticky bits 
		bsE = 0;
		ps = 0;

		// And to using product as primary operand in adder I exponent gen 
		killprodE = xzeroE | yzeroE;
		// d = aligncntE
		// p = 53
		if ($signed(aligncntE) <= $signed(-105)) begin //d<=-2p+1
			//product ancored case with saturated shift
			sumshiftE = 163;	// 3p+4	
			sumshiftzeroE = 0;
			shift = {1'b1,zman,163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);
			//zexpsel = 0;
		end else if($signed(aligncntE) <= $signed(2))  begin // -2p+1<d<=2
			// product ancored or cancellation
			sumshiftE = 57-aligncntE; // p + 2 - d  
			sumshiftzeroE = 0;
			shift = {~zdenormE,zman,163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);
			//zexpsel = 0;
		end else if ($signed(aligncntE)<=$signed(55))  begin // 2 < d <= p+2
			// addend ancored case
			// used to be 56 \/ somthing doesn'tE seem right too many typos
			sumshiftE = 57-aligncntE;
			sumshiftzeroE = 0;
			shift = {~zdenormE,zman, 163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);
			//zexpsel = 1;
		end else begin                 	// d >= p+3
			// addend anchored case with saturated shift
			sumshiftE = 0;	
			sumshiftzeroE = 1;		
			shift = {~zdenormE,zman, 163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);
			killprodE = 1;
			//ps = 1;
			//zexpsel = 1;

		// use some behavioral code to find sticky bit.  This is really
		// done by hardware in the shifter.
		//if (aligncntE < 0)
		//	for (i=0; i<-aligncntE-52;  i = i+1)
		//		bsE = bsE || z2[i];
		end 
	end

endmodule
