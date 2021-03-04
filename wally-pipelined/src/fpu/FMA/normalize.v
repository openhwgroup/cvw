/////////////////////////////////////////////////////////////////////////////// 
// Block Name:	normalize.v
// Author:		David Harris
// Date:		11/2/1995
//
// Block Description:
//   This block performs the normalization shift.  It also
//   generates the Rands bits for rounding.  Finally, it
//   handles the special case of a zero sum.
//
//   v[53:2]  is the fraction component of the prerounded result.
//   It can be bypassed back to the X or Z inputs of the FMAC
//   for back-to-back operations. 
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module normalize(sum[157:0], normcnt, sumzero, bs, ps, denorm0, zdenorm, v[53:0]); 
/////////////////////////////////////////////////////////////////////////////
	input     	[157:0]  	sum;            // sum
	input		[8:0] 		normcnt;     	// normalization shift count
	input				sumzero;	// sum is zero
	input				bs;		// sticky bit for addend
	input				ps;		// sticky bit for product
	input				denorm0;	// exponent = -1023
	input                  		zdenorm;        // Input Z is denormalized
	output		[53:0]		v;		// normalized sum, R, S bits

	// Internal nodes

	reg       	[53:0]     	v;           	// normalized sum, R, S bits 
	wire       	[157:0]  	sumshifted;     // shifted sum

	// When the sum is zero,  normalization does not apply and only the
	// sticky bit must be computed.  Otherwise,  the sum is right-shifted
	// and the Rand S bits (v[1]  and v[O],  respectively) are assigned.

	// The R bit is also set on denormalized numbers where the exponent
	// was computed to be exactly -1023 and the L bit was set.  This
	// is required for correct rounding up of multiplication results.

	// The sticky bit calculation is actually built into the shifter and
	// does not require a true subtraction shown in the model.
 
	always @(sum or normcnt or sumzero or bs or ps or sumshifted or denorm0)
		begin
			if (sumzero)  begin            // special case
				v[53:1] = 0;
				v[0] =  ps ||  bs ;
			end else begin                 // extract normalized bits
				v[53:3] = sumshifted[156:106];
				// KEP prevent plus1 in round.v when z is denormalized.
				v[2] = sumshifted[105] || sumshifted[106] && denorm0 && ~zdenorm; 
				v[1] = sumshifted[104] || sumshifted[105] && denorm0 && ~zdenorm;
				v[0] = |(sumshifted[103:0]) || ps || bs;
		end 
	end


	// shift sum left by normcnt,  filling the right with zeros 
	assign sumshifted = sum << normcnt;
	
endmodule

