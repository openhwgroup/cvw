module fma1(
 
	input logic 	[63:0]		FInput1E,
	input logic		[63:0]		FInput2E,
	input logic 	[63:0]		FInput3E,
	input logic 	[3:0]		FOpCtrlE,
	output logic 	[105:0]		ProdManE,
	output logic 	[161:0]		AlignedAddendE,	
	output logic 	[12:0]		ProdExpE,
	output logic 				AddendStickyE,
	output logic 				KillProdE,
	output logic				XZeroE, YZeroE, ZZeroE,
	output logic				XInfE, YInfE, ZInfE,
	output logic				XNaNE, YNaNE, ZNaNE);

	logic [51:0] 	XMan,YMan,ZMan;
	logic [10:0] 	XExp,YExp,ZExp;
	logic 		 	XSgn,YSgn,ZSgn;
	logic [12:0]	AlignCnt;
	logic [211:0] 	Shift;
	logic			XDenormE, YDenormE, ZDenormE;
	logic [63:0]	FInput3E2;

	// Set addend to zero if FMUL instruction
  	assign FInput3E2 = FOpCtrlE[2] ? 64'b0 : FInput3E;

	// split inputs into the sign bit, mantissa, and exponent for readability
	assign XSgn = FInput1E[63];
	assign YSgn = FInput2E[63];
	assign ZSgn = FInput3E2[63];

	assign XExp = FInput1E[62:52];
	assign YExp = FInput2E[62:52];
	assign ZExp = FInput3E2[62:52];

	assign XMan = FInput1E[51:0];
	assign YMan = FInput2E[51:0];
	assign ZMan = FInput3E2[51:0];



	// determine if an input is a special value
	assign XNaNE = &XExp && |XMan; 
	assign YNaNE = &YExp && |XMan; 
	assign ZNaNE = &ZExp && |ZMan;

	assign XDenormE = ~(|XExp) && |XMan; 
	assign YDenormE = ~(|YExp) && |YMan; 
	assign ZDenormE = ~(|ZExp) && |ZMan;

	assign XInfE = &XExp && ~(|XMan); 
	assign YInfE = &YExp && ~(|YMan); 
	assign ZInfE = &ZExp && ~(|ZMan);

	assign XZeroE = ~(|{XExp, XMan});
	assign YZeroE = ~(|{YExp, YMan});
	assign ZZeroE = ~(|{ZExp, ZMan});




	// Calculate the product's exponent
	//		- When multipliying two fp numbers, add the exponents
	// 		- Subtract 3ff to remove one of the biases (XExp + YExp has two biases, one from each exponent)
	//		- Denormal numbers have an an exponent value of 1, however they are 
	//		  represented with an exponent of 0. add one if there is a denormal number
	assign ProdExpE = (XZeroE|YZeroE) ? 13'b0 : 
				 {2'b0, XExp} + {2'b0, YExp} - 13'h3ff + {12'b0, XDenormE} + {12'b0, YDenormE};

	// Calculate the product's mantissa
	//		- Add the assumed one. If the number is denormalized or zero, it does not have an assumed one.
	assign ProdManE = {53'b0,~(XDenormE|XZeroE),XMan}  *  {53'b0,~(YDenormE|YZeroE),YMan};




	// determine the shift count for alignment
	//		- negitive means Z is larger, so shift Z left
	//		- positive means the product is larger, so shift Z right
	//		- Denormal numbers have an an exponent value of 1, however they are 
	//		  represented with an exponent of 0. add one to the exponent if it is a denormal number
	assign AlignCnt = ProdExpE - {2'b0, ZExp} - {12'b0, ZDenormE};

	// Alignment shifter

	// Defualt Addition without shifting
	// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
	//						 |1'b0| addnend |

	// the 1'b0 before the added is because the product's mantissa has two bits before the decimal point (xx.xxxxxxxxxx...)
	
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
			AlignedAddendE = {107'b0, ~(ZZeroE|ZDenormE),ZMan,2'b0};
			AddendStickyE = ~(XZeroE|YZeroE);

		// If the Addend is shifted left (negitive AlignCnt)

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//					| addnend |
		end else if($signed(AlignCnt) <= $signed(13'd0))  begin
			Shift = {55'b0, ~(ZZeroE|ZDenormE),ZMan, 104'b0} << -AlignCnt;
			AlignedAddendE = Shift[211:50];
			AddendStickyE = |(Shift[49:0]);

		// If the Addend is shifted right (positive AlignCnt)

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//									| addnend |
		end else if ($signed(AlignCnt)<=$signed(13'd105))  begin
			Shift = {55'b0, ~(ZZeroE|ZDenormE),ZMan, 104'b0} >> AlignCnt;
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

