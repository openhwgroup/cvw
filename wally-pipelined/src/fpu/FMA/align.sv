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
module align(zman, ae, aligncnt, xzero, yzero, zzero, zdenorm, proddenorm, t, bs, ps, 
             killprod,  zexpsel, sumshift);
/////////////////////////////////////////////////////////////////////////////

	input 		[51:0]		zman;		// Fraction of addend z;
	input 		[12:0]		ae;		// sign of exponent of addend z;
	input 		[11:0]		aligncnt;	// amount to shift
	input				xzero;		// Input X = 0
	input                  		yzero;          // Input Y = 0 
	input                  		zzero;          // Input Z = 0
	input                  		zdenorm;        // Input Z is denormalized
	input				proddenorm;	// product is denormalized
	output    	[163:0]    	t;              // aligned addend (54 bits left of bpt)
	output          		bs;           	// sticky bit of addend
	output          		ps;           	// sticky bit of product
	output          		killprod;    	// Z >> product
	output          		zexpsel;    	// Z >> product
	output		[7:0]		sumshift;	

	// Internal nodes
 
	reg       	[163:0]   	t;				// aligned addend from shifter
	reg       	[215:0]   	shift;				// aligned addend from shifter
	reg             		killprod;			// Z >> product 
	reg             		bs;				// sticky bit of addend
	reg             		ps;				// sticky bit of product
	reg             		zexpsel;				// sticky bit of product
	reg       	[7:0]		i;				// temp storage for finding sticky bit
	wire		[52:0]		z1;				// Z plus 1
	wire		[51:0]		z2;				// Z selected after handling rounds
	wire		[11:0]		align104;			// alignment count + 104
	logic		[8:0]		sumshift;



	// Compute sign of aligncnt + 104 to check for shifting too far right 

	assign align104 = aligncnt+104;
	
	// Shift addend by alignment count.  Generate sticky bits from
	// addend on right shifts.  Handle special cases of shifting
	// by too much.

	always @(z2 or aligncnt or align104 or zzero or xzero or yzero or zdenorm or proddenorm)
		begin

		// Default to clearing sticky bits 
		bs = 0;
		ps = 0;

		// And to using product as primary operand in adder I exponent gen 
		killprod = 0;

		if ($signed(aligncnt) <= $signed(-105)) begin //ae<=-103
			//product ancored case with saturated shift
			sumshift = 163;			
			shift = {~zdenorm,zman,163'b0} >> sumshift;
			t = {shift[208:51]};
			bs = |(shift[50:0]);
			//bs = ~zzero; //set sticky bit
			zexpsel = 0;
		end else if($signed(aligncnt) <= $signed(2))  begin 	// -103<ae<=2
			// product ancored or cancellation
			sumshift = 56-aligncnt;
			shift = {~zdenorm,zman,163'b0} >> sumshift;
			t = {shift[208:51]};
			bs = |(shift[51:0]);
			zexpsel = 0;
		end else if ($signed(aligncnt)<=$signed(55))  begin 	//2<ae<=54
			// addend ancored case
			sumshift = 56-aligncnt;
			shift = {~zdenorm,zman, 163'b0} >> sumshift;
			t = {shift[208:51]};
			bs = |(shift[51:0]);
			zexpsel = 1;
		end else begin                 	// ae>= 55
			// addend anchored case with saturated shift
			sumshift = 0;			
			shift = {~zdenorm,zman, 163'b0} >> sumshift;
			t = {shift[215:52]};
			bs = |(shift[51:0]);
			zexpsel = 1;

		// use some behavioral code to find sticky bit.  This is really
		// done by hardware in the shifter.
		if (aligncnt < 0)
			for (i=0; i<-aligncnt-52;  i = i+1)
				bs = bs || z2[i];
		end 
	end

endmodule
