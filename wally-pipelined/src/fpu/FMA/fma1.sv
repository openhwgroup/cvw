module fma1(
 
	input logic 	[63:0]		FInput1E,	// X
	input logic		[63:0]		FInput2E,	// Y
	input logic 	[63:0]		FInput3E,	// Z
	input logic 	[2:0]		FOpCtrlE,	// 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
	input logic 				FmtE,		// precision 1 = double 0 = single
	output logic 	[105:0]		ProdManE,	// 1.X frac * 1.Y frac
	output logic 	[161:0]		AlignedAddendE,	// Z aligned for addition
	output logic 	[12:0]		ProdExpE,		// X exponent + Y exponent - bias
	output logic 				AddendStickyE,	// sticky bit that is calculated during alignment
	output logic 				KillProdE,		// set the product to zero before addition if the product is too small to matter
	output logic				XZeroE, YZeroE, ZZeroE, // inputs are zero
	output logic				XInfE, YInfE, ZInfE,	// inputs are infinity
	output logic				XNaNE, YNaNE, ZNaNE);	// inputs are NaN

	logic [51:0] 	XFrac,YFrac,ZFrac;	// input fraction
	logic [52:0] 	XMan,YMan,ZMan;		// input mantissa (with leading one)
	logic [12:0] 	XExp,YExp,ZExp;		// input exponents
	logic 		 	XSgn,YSgn,ZSgn;		// input signs
	logic [12:0]	AlignCnt;			// how far to shift the addend to align with the product
	logic [211:0] 	Shift;				// output of the alignment shifter including sticky bit
	logic			XDenormE, YDenormE, ZDenormE;	// inputs are denormal
	logic [63:0]	FInput3E2;	// value to add (Z or zero)
	logic [12:0]	Bias;	// 1023 for double, 127 for single
	logic 			XExpZero, YExpZero, ZExpZero; 	// input exponent zero
	logic 			XFracZero, YFracZero, ZFracZero; // input fraction zero
	logic 			XExpMax, YExpMax, ZExpMax; 	// input exponent all 1s

	// Set addend to zero if FMUL instruction
  	assign FInput3E2 = FOpCtrlE[2] ? 64'b0 : FInput3E;

	// split inputs into the sign bit, fraction, and exponent and handle single or double precision
	// 		- single precision is in the top half of the inputs
	assign XSgn = FInput1E[63];
	assign YSgn = FInput2E[63];
	assign ZSgn = FInput3E2[63];

	assign XExp = FmtE ? {2'b0, FInput1E[62:52]} : {5'b0, FInput1E[62:55]};
	assign YExp = FmtE ? {2'b0, FInput2E[62:52]} : {5'b0, FInput2E[62:55]};
	assign ZExp = FmtE ? {2'b0, FInput3E2[62:52]} : {5'b0, FInput3E2[62:55]};

	assign XFrac = FmtE ? FInput1E[51:0] : {FInput1E[54:32], 29'b0};
	assign YFrac = FmtE ? FInput2E[51:0] : {FInput2E[54:32], 29'b0};
	assign ZFrac = FmtE ? FInput3E2[51:0] : {FInput3E2[54:32], 29'b0};
	
	assign XMan = {~XExpZero, XFrac};
	assign YMan = {~YExpZero, YFrac};
	assign ZMan = {~ZExpZero, ZFrac};

	assign Bias = FmtE ? 13'h3ff : 13'h7f;



	// determine if an input is a special value
	assign XExpZero = ~|XExp;
	assign YExpZero = ~|YExp;
	assign ZExpZero = ~|ZExp;
	
	assign XFracZero = ~|XFrac;
	assign YFracZero = ~|YFrac;
	assign ZFracZero = ~|ZFrac;

	assign XExpMax = FmtE ? &XExp[10:0] : &XExp[7:0];
	assign YExpMax = FmtE ? &YExp[10:0] : &YExp[7:0];
	assign ZExpMax = FmtE ? &ZExp[10:0] : &ZExp[7:0];
	
	assign XNaNE = XExpMax & ~XFracZero;
	assign YNaNE = YExpMax & ~YFracZero;
	assign ZNaNE = ZExpMax & ~ZFracZero;

	assign XDenormE = XExpZero & ~XFracZero; 
	assign YDenormE = YExpZero & ~YFracZero; 
	assign ZDenormE = ZExpZero & ~ZFracZero; 

	assign XInfE = XExpMax & XFracZero; 
	assign YInfE = YExpMax & YFracZero; 
	assign ZInfE = ZExpMax & ZFracZero; 

	assign XZeroE = XExpZero & XFracZero;
	assign YZeroE = YExpZero & YFracZero;
	assign ZZeroE = ZExpZero & ZFracZero;




	// Calculate the product's exponent
	//		- When multipliying two fp numbers, add the exponents
	// 		- Subtract the bias (XExp + YExp has two biases, one from each exponent)
	//		- Denormal numbers have an an exponent value of 1, however they are 
	//		  represented with an exponent of 0. add one if there is a denormal number
	assign ProdExpE = (XZeroE|YZeroE) ? 13'b0 : 
				 XExp + YExp - Bias + XDenormE + YDenormE;

	// Calculate the product's mantissa
	//		- Add the assumed one. If the number is denormalized or zero, it does not have an assumed one.
	assign ProdManE =  XMan * YMan;



	// determine the shift count for alignment
	//		- negitive means Z is larger, so shift Z left
	//		- positive means the product is larger, so shift Z right
	//		- Denormal numbers have an an exponent value of 1, however they are 
	//		  represented with an exponent of 0. add one to the exponent if it is a denormal number
	assign AlignCnt = ProdExpE - ZExp - ZDenormE;

	// Alignment shifter

	// Defualt Addition without shifting
	// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
	//						 |1'b0| addnend |

	// the 1'b0 before the added is because the product's mantissa has two bits before the binary point (xx.xxxxxxxxxx...)
	
	always_comb 
		begin
			
		// Set default values
		AddendStickyE = 0;
		KillProdE = 0;
		
		// If the product is too small to effect the sum, kill the product

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//	| addnend |
		if ($signed(AlignCnt) <= $signed(-13'd56)) begin
			KillProdE = 1;
			AlignedAddendE = {107'b0, ZMan,2'b0};
			AddendStickyE = ~(XZeroE|YZeroE);

		// If the Addend is shifted left (negitive AlignCnt)

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//					| addnend |
		end else if($signed(AlignCnt) <= $signed(13'd0))  begin
			Shift = {55'b0, ZMan, 104'b0} << -AlignCnt;
			AlignedAddendE = Shift[211:50];
			AddendStickyE = |(Shift[49:0]);

		// If the Addend is shifted right (positive AlignCnt)

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//									| addnend |
		end else if ($signed(AlignCnt)<=$signed(13'd105))  begin
			Shift = {55'b0, ZMan, 104'b0} >> AlignCnt;
			AlignedAddendE = Shift[211:50];
			AddendStickyE = |(Shift[49:0]);

		// If the addend is too small to effect the addition		
		//		- The addend has to shift two past the end of the addend to be considered too small
		//		- The 2 extra bits are needed for rounding

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//														| addnend |
		end else begin
			AlignedAddendE = 162'b0;
			AddendStickyE = ~ZZeroE;


		end 
	end

endmodule

