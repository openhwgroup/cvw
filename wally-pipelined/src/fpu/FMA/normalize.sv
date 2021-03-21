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
module normalize(sum, zexp, normcnt, ae, aligncnt, sumshift, sumzero, bs, ps, denorm0, zdenorm, de0, resultdenorm, v); 
/////////////////////////////////////////////////////////////////////////////
	input     	[163:0]  	sum;            // sum
	input     	[62:52]  	zexp;            // sum
	input		[8:0] 		normcnt;     	// normalization shift count
	input		[12:0] 		ae;     	// normalization shift count
	input		[12:0] 		aligncnt;     	// normalization shift count
	input		[8:0] 		sumshift;     	// normalization shift count
	input				sumzero;	// sum is zero
	input				bs;		// sticky bit for addend
	input				ps;		// sticky bit for product
	input				denorm0;	// exponent = -1023
	input                  		zdenorm;        // Input Z is denormalized
	output		[12:0]		de0;
	output                  	resultdenorm;        // Input Z is denormalized
	output		[53:0]		v;		// normalized sum, R, S bits

	// Internal nodes

	reg       	[53:0]     	v;           	// normalized sum, R, S bits 
	logic                  	resultdenorm;        // Input Z is denormalized
	logic 		[12:0]	de0;
	logic       	[163:0]  	sumshifted;     // shifted sum
	logic       	[163:0]  	sumshiftedtmp;     // shifted sum
logic tmp;

	// When the sum is zero,  normalization does not apply and only the
	// sticky bit must be computed.  Otherwise,  the sum is right-shifted
	// and the Rand S bits (v[1]  and v[O],  respectively) are assigned.

	// The R bit is also set on denormalized numbers where the exponent
	// was computed to be exactly -1023 and the L bit was set.  This
	// is required for correct rounding up of multiplication results.

	// The sticky bit calculation is actually built into the shifter and
	// does not require a true subtraction shown in the model.
 
	assign tmp = ($signed(ae-normcnt+2) >= $signed(-1022));
	always @(sum or normcnt or sumshift or ae or aligncnt)
		begin
		// d = aligncnt
		// l = normcnt
		// p = 53
		// ea + eb = ae
			if ($signed(aligncnt)<=$signed(2))  begin //d<=2 
				// product anchored or cancellation
				if ($signed(ae-normcnt+2) >= $signed(-1022)) begin //ea+eb-l+2 >= emin
					//normal result
					sumshifted = sum << (55+normcnt); // p+2+l
					v = sumshifted[162:109];
					resultdenorm = 0;
					//de0 = ae-normcnt+2-1023;
					de0 = ae-normcnt+2;
				end else begin
					sumshifted = sum << (1079+ae);
					v = sumshifted[162:109];
					resultdenorm = 1;
					de0 = 0;
				end

			end else begin                 // extract normalized bits
				sumshifted = sum << sumshift;//-1;
				//if(sumshifted[163])begin
				//	v = sumshifted[162:109];
				//	de0 = zexp -1;
				//end else if (zdenorm || sumshifted[162]) begin
				//	v = sumshifted[161:108];
				//	de0 = zexp;
				//end else begin
				//	v = sumshifted[160:107];
				//	de0 = zexp+1;
				//end

					v = sumshifted[162:109];
					de0 = zexp;
				resultdenorm = 0;
		end 
	end


	// shift sum left by normcnt,  filling the right with zeros 
	//assign sumshifted = sum << normcnt;
	
endmodule

