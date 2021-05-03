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

	input logic 		[51:0]		zman;		// Fraction of addend z;
	input logic 		[12:0]		aligncntE;	// amount to shift
	input logic				xzeroE;		// Input X = 0
	input logic                  		yzeroE;          // Input Y = 0 
	input logic                  		zzeroE;          // Input Z = 0
	input logic                  		zdenormE;        // Input Z is denormalized
	output logic    	[163:0]    	tE;              // aligned addend (54 bits left of bpt)
	output logic          		bsE;           	// sticky bit of addend
	output logic          		killprodE;    	// Z >> product
	output logic		[8:0]		sumshiftE;	
	output logic				sumshiftzeroE;

	// Internal nodes
 
	reg       	[215:0]   	shift;				// aligned addend from shifter
	logic 		[12:0]		tmp;
	


	always_comb 
		begin

		// Default to clearing sticky bits 
		bsE = 0;

		// And to using product as primary operand in adder I exponent gen 
		killprodE = xzeroE | yzeroE;
		// d = aligncntE
		// p = 53
		//***try reducing this hardware to use one shifter
		if ($signed(aligncntE) <= $signed(-(13'd105))) begin //d<=-2p+1
			//product ancored case with saturated shift
			sumshiftE = 163;	// 3p+4	
			sumshiftzeroE = 0;
			shift = {1'b1,zman,163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);

		end else if($signed(aligncntE) <= $signed(13'd2))  begin // -2p+1<d<=2
			// product ancored or cancellation
			tmp = 13'd57-aligncntE;
			sumshiftE = tmp[8:0]; // p + 2 - d  
			sumshiftzeroE = 0;
			shift = {~zdenormE,zman,163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);

		end else if ($signed(aligncntE)<=$signed(13'd55))  begin // 2 < d <= p+2
			// addend ancored case
			// used to be 56 \/ somthing doesn't seem right too many typos
			tmp = 13'd57-aligncntE;
			sumshiftE = tmp[8:0]; 
			sumshiftzeroE = 0;
			shift = {~zdenormE,zman, 163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);

		end else begin                 	// d >= p+3
			// addend anchored case with saturated shift
			sumshiftE = 0;	
			sumshiftzeroE = 1;		
			shift = {~zdenormE,zman, 163'b0} >> sumshiftE;
			tE = zzeroE ? 0 : {shift[215:52]};
			bsE = |(shift[51:0]);
			killprodE = 1;

		end 
	end

endmodule

