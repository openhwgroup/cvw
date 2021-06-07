module fma1(
 
	input logic 	[63:0]		ReadData1E,
	input logic		[63:0]		ReadData2E,
	input logic 	[63:0]		ReadData3E,
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


	// split inputs into the sign bit, mantissa, and exponent for readability
	assign XSgn = ReadData1E[63];
	assign YSgn = ReadData2E[63];
	assign ZSgn = ReadData3E[63];

	assign XExp = ReadData1E[62:52];
	assign YExp = ReadData2E[62:52];
	assign ZExp = ReadData3E[62:52];

	assign XMan = ReadData1E[51:0];
	assign YMan = ReadData2E[51:0];
	assign ZMan = ReadData3E[51:0];



	// determine if an input is a special value
	assign XNaNE = &ReadData1E[62:52] && |ReadData1E[51:0]; 
	assign YNaNE = &ReadData2E[62:52] && |ReadData2E[51:0]; 
	assign ZNaNE = &ReadData3E[62:52] && |ReadData3E[51:0];

	assign XDenormE = ~(|ReadData1E[62:52]) && |ReadData1E[51:0]; 
	assign YDenormE = ~(|ReadData2E[62:52]) && |ReadData2E[51:0]; 
	assign ZDenormE = ~(|ReadData3E[62:52]) && |ReadData3E[51:0];

	assign XInfE = &ReadData1E[62:52] && ~(|ReadData1E[51:0]); 
	assign YInfE = &ReadData2E[62:52] && ~(|ReadData2E[51:0]); 
	assign ZInfE = &ReadData3E[62:52] && ~(|ReadData3E[51:0]);

	assign XZeroE = ~(|ReadData1E[62:0]);
	assign YZeroE = ~(|ReadData2E[62:0]);
	assign ZZeroE = ~(|ReadData3E[62:0]);




	// Calculate the product's exponent
	//		- When multipliying two fp numbers, add the exponents
	// 		- Subtract 3ff to remove one of the biases (XExp + YExp has two biases, one from each exponent)
	//		- Denormal numbers have an an exponent value of 1, however they are 
	//		  represented with an exponent of 0. add one if there is a denormal number
	assign ProdExpE = (XZeroE|YZeroE) ? 13'b0 : 
				 {2'b0, XExp} + {2'b0, YExp} - 13'h3ff + XDenormE + YDenormE;

	// Calculate the product's mantissa
	//		- Add the assumed one. If the number is denormalized or zero, it does not have an assumed one.
	assign ProdManE = {53'b0,~(XDenormE|XZeroE),XMan}  *  {53'b0,~(YDenormE|YZeroE),YMan};




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

	// the 1'b0 before the added is because the product's mantissa has two bits before the decimal point (xx.xxxxxxxxxx...)
	
	always_comb 
		begin
			
		// Set default values
		AddendStickyE = 0;
		KillProdE = 0;
		
		// If the product is too small to effect the sum, kill the product

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//	| addnend |
		if ($signed(AlignCnt) <= $signed(-56)) begin
			KillProdE = 1;
			AlignedAddendE = {55'b0, ~(ZZeroE|ZDenormE),ZMan,2'b0};
			AddendStickyE = ~(XZeroE|YZeroE);

		// If the Addend is shifted left (negitive AlignCnt)

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//					| addnend |
		end else if($signed(AlignCnt) <= $signed(0))  begin
			Shift = {55'b0, ~(ZZeroE|ZDenormE),ZMan, 104'b0} << -AlignCnt;
			AlignedAddendE = Shift[211:50];
			AddendStickyE = |(Shift[49:0]);

		// If the Addend is shifted right (positive AlignCnt)

		// 			| 	55'b0	 |	106'b(product)	| 2'b0 |
		//									| addnend |
		end else if ($signed(AlignCnt)<=$signed(105))  begin
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

