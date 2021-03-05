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
module align(z[51:0], ae[12:0], aligncnt, xzero, yzero, zzero, zdenorm, proddenorm, t[157:0], bs, ps, 
             killprod,  bypsel[1], bypplus1, byppostnorm);
/////////////////////////////////////////////////////////////////////////////

	input 		[51:0]		z;		// Fraction of addend z;
	input 		[12:0]		ae;		// sign of exponent of addend z;
	input 		[11:0]		aligncnt;	// amount to shift
	input				xzero;		// Input X = 0
	input                  		yzero;          // Input Y = 0 
	input                  		zzero;          // Input Z = 0
	input                  		zdenorm;        // Input Z is denormalized
	input				proddenorm;	// product is denormalized
	input     	[1:1] 		bypsel;         // Select bypass to X or Z
	input				bypplus1;	// Add one to bypassed result
	input                  		byppostnorm;    // Postnormalize bypassed result 
	output    	[157:0]    	t;              // aligned addend (54 bits left of bpt)
	output          		bs;           	// sticky bit of addend
	output          		ps;           	// sticky bit of product
	output          		killprod;    	// Z >> product

	// Internal nodes
 
	reg       	[157:0]   	t;				// aligned addend from shifter
	reg             		killprod;			// Z >> product 
	reg             		bs;				// sticky bit of addend
	reg             		ps;				// sticky bit of product
	reg       	[7:0]		i;				// temp storage for finding sticky bit
	wire		[52:0]		z1;				// Z plus 1
	wire		[51:0]		z2;				// Z selected after handling rounds
	wire		[11:0]		align104;			// alignment count + 104

	// Increment fraction of Z by  one if necessary for prerounded bypass
	// This incrementor delay is masked by the alignment count computation

	assign z1 =  z + 1;
	assign z2 = bypsel[1] && bypplus1 ? (byppostnorm ? z1[52:1] : z1[51:0]): z;

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

		if(zzero) begin // if z = 0
			t = 158'b0;
			if (xzero || yzero) killprod = 1;
		end else if ((aligncnt > 53 && ~aligncnt[11]) || xzero || yzero) begin
									// Left shift by huge amount
									// or product = 0
			t = {53'b0, ~zzero, z2, 52'b0}; 
			killprod = 1;
			ps = ~xzero && ~yzero; 
		end else if ((ae[12] && align104[11]) && ~proddenorm) begin //***fix the if statement
							// KEP if the multiplier's exponent overflows
			t = {53'b0, ~zzero, z2, 52'b0}; 
			killprod = 1;
			ps = ~xzero && ~yzero; 
		end else if(align104[11])  begin 	// Right shift by huge amount
			bs = ~zzero;
			t = 0;
		end else if (~aligncnt[11])  begin 	// Left shift by reasonable amount
			t = {53'b0, ~zzero, z2, 52'b0} << aligncnt;
		end else begin                 		// Otherwise right shift 
			t = {53'b0, ~zzero, z2, 52'b0} >> -aligncnt;

		// use some behavioral code to find sticky bit.  This is really
		// done by hardware in the shifter.
		if (aligncnt < 0)
			for (i=0; i<-aligncnt-52;  i = i+1)
				bs = bs || z2[i];
		end 
	end

endmodule
