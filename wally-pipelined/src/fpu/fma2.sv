module fma2(
 
	input logic 	[63:0]		FInput1M,
	input logic		[63:0]		FInput2M,
	input logic 	[63:0]		FInput3M,
	input logic 	[2:0] 		FrmM,
	input logic 	[105:0]		ProdManM,
	input logic 	[161:0]		AlignedAddendM,	
	input logic 	[12:0]		ProdExpM,
	input logic 				AddendStickyM,
	input logic 				KillProdM,
	input logic 	[3:0]		FOpCtrlM,
	input logic					XZeroM, YZeroM, ZZeroM,
	input logic					XInfM, YInfM, ZInfM,
	input logic					XNaNM, YNaNM, ZNaNM,
	output logic	[63:0]		FmaResultM,
	output logic 	[4:0]		FmaFlagsM);
	


	logic [51:0] 	XMan, YMan, ZMan, WMan;
	logic [10:0] 	XExp, YExp, ZExp, WExp;
	logic 		 	XSgn, YSgn, ZSgn, WSgn, PSgn;
	logic [105:0]	ProdMan2;
	logic [162:0]	AlignedAddend2;
 	logic [161:0]	Sum;
	logic [162:0]	SumTmp;
	logic [12:0]	SumExp;
	logic [12:0]	SumExpMinus1;
	logic [12:0]	SumExpTmp, SumExpTmpMinus1, WExpTmp;
	logic [53:0]	NormSum;
	logic [161:0]	NormSumTmp;
	logic [8:0]		NormCnt;
	logic 			NormSumSticky;
	logic 			SumZero;
	logic 			NegSum;
	logic 			InvZ;
	logic			ResultDenorm;
	logic			Sticky;
	logic 			Plus1, Minus1, Plus1Tmp, Minus1Tmp;
	logic 			Invalid,Underflow,Overflow,Inexact;
	logic [8:0]		DenormShift;
	logic 			ProdInf, ProdOf, ProdUf;
	logic [63:0]	FmaResultTmp;
	logic 			SubBySmallNum;
	logic [63:0]	FInput3M2;
	logic			ZeroSgn, ResultSgn;

	// Set addend to zero if FMUL instruction
  	assign FInput3M2 = FOpCtrlM[2] ? 64'b0 : FInput3M;

	// split inputs into the sign bit, mantissa, and exponent for readability
	assign XSgn = FInput1M[63];
	assign YSgn = FInput2M[63];
	assign ZSgn = FInput3M2[63]^FOpCtrlM[0]; //Negate Z if subtraction

	assign XExp = FInput1M[62:52];
	assign YExp = FInput2M[62:52];
	assign ZExp = FInput3M2[62:52];

	assign XMan = FInput1M[51:0];
	assign YMan = FInput2M[51:0];
	assign ZMan = FInput3M2[51:0];



	// Calculate the product's sign
	//		Negate product's sign if FNMADD or FNMSUB
	assign PSgn = XSgn ^ YSgn ^ FOpCtrlM[1];




	// Addition
	
	// Negate Z  when doing one of the following opperations:
	//		-prod +  Z
	//		 prod -  Z 
	assign InvZ = ZSgn ^ PSgn;

	// Choose an inverted or non-inverted addend - the one is added later
	assign AlignedAddend2 = InvZ ? ~{1'b0,AlignedAddendM} : {1'b0,AlignedAddendM};
	// Kill the product if the product is too small to effect the addition (determined in fma1.sv)
	assign ProdMan2 = KillProdM ? 106'b0 : ProdManM;

	// Do the addition
	// 		- add one to negate if the added was inverted
	//		- the 2 extra bits at the begining and end are needed for rounding
	assign SumTmp = AlignedAddend2 + {55'b0, ProdMan2,2'b0} + {162'b0, InvZ};
	 
	// Is the sum negitive
	assign NegSum = SumTmp[162];
	// If the sum is negitive, negate the sum.
	assign Sum = NegSum ? -SumTmp[161:0] : SumTmp[161:0];






	// Leading one detector
	logic [8:0]	i;
	always_comb begin
			i = 0;
			while (~Sum[161-i] && $unsigned(i) <= $unsigned(9'd161)) i = i+1;  // search for leading one 
			NormCnt = i+1;    // compute shift count
	end











	// Normalization


	// Determine if the sum is zero
	assign SumZero = ~(|Sum);

	// Determine if the result is denormal
	assign ResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp+13'd52)>=0);

	// Determine the shift needed for denormal results
	assign SumExpTmpMinus1 = SumExpTmp-1;
	assign DenormShift = ResultDenorm ? SumExpTmpMinus1[8:0] : 9'b0;

	// Normalize the sum
	assign NormSumTmp = SumZero ? 162'b0 : Sum << NormCnt+DenormShift; 
	assign NormSum = NormSumTmp[161:108];
	// Calculate the sticky bit
	assign NormSumSticky = (|NormSumTmp[107:0]);
	assign Sticky = AddendStickyM | NormSumSticky;

	// Determine sum's exponent
	assign SumExpTmp = KillProdM ? {2'b0, ZExp} : ProdExpM + -({4'b0, NormCnt} - 13'd56);
	assign SumExp = SumZero ? 13'b0 : 
				 ResultDenorm ? 13'b0 :
				 SumExpTmp; 









	// Rounding

	// round to nearest even
	//		{NormSum[1], NormSum[0], Sticky}
	//		0xx - do nothing
	//		100 - tie - Plus1 if NormSum[2] = 1
	//			- don't add 1 if there was supposed to be a subtraction by a small number that didn't happen
	//		101/110/111 - Plus1

	// 	round to zero - do nothing
	//			- subtract 1 if a small number was supposed to be subtracted from the positive result

	// 	round to -infinity - Plus1 if negitive
	//			- don't add 1 if there was supposed to be a subtraction by a small number that didn't happen
	//			- subtract 1 if a small number was supposed to be subtracted from the positive result

	// 	round to infinity - Plus1 if positive

	//			- don't add 1 if there was supposed to be a subtraction by a small number that didn't happen
	//			- subtract 1 if a small number was supposed to be subtracted from the negitive result

	//  round to nearest max magnitude
	//		{NormSum[1], NormSum[0], Sticky}
	//		0xx - do nothing
	//		100 - tie - Plus1
	//			- don't add 1 if there was supposed to be a subtraction by a small number that didn't happen
	//		101/110/111 - Plus1

	// Deterimine if the result was supposed to be subtrated by a small number
	assign SubBySmallNum = AddendStickyM&InvZ&~NormSumSticky;

	always_comb begin
		// Determine if you add 1
		case (FrmM)
			3'b000: Plus1Tmp = NormSum[1] & (NormSum[0] | (Sticky&~(~NormSum[0]&SubBySmallNum)) | (~NormSum[0]&~Sticky&NormSum[2]));//round to nearest even
			3'b001: Plus1Tmp = 0;//round to zero
			3'b010: Plus1Tmp = WSgn & ~(SubBySmallNum);//round down
			3'b011: Plus1Tmp = ~WSgn & ~(SubBySmallNum);//round up
			3'b100: Plus1Tmp = (NormSum[1] & (NormSum[0] | (Sticky&~(~NormSum[0]&SubBySmallNum)) | (~NormSum[0]&~Sticky)));//round to nearest max magnitude
			default: Plus1Tmp = 1'bx;
		endcase
		// Determine if you subtract 1
		case (FrmM)
			3'b000: Minus1Tmp = 0;//round to nearest even
			3'b001: Minus1Tmp = SubBySmallNum;//round to zero
			3'b010: Minus1Tmp = ~WSgn & SubBySmallNum;//round down
			3'b011: Minus1Tmp = WSgn & SubBySmallNum;//round up
			3'b100: Minus1Tmp = 0;//round to nearest max magnitude
			default: Minus1Tmp = 1'bx;
		endcase
	
	end

	// If an answer is exact don't round
    assign Plus1 = Sticky | (|NormSum[1:0]) ? Plus1Tmp : 1'b0;
    assign Minus1 = Sticky | (|NormSum[1:0]) ? Minus1Tmp : 1'b0;
	// Compute rounded result 
    assign {WExpTmp, WMan} = {SumExp, NormSum[53:2]} - {64'b0, Minus1} + {64'b0, Plus1};
    assign WExp = WExpTmp[10:0];







	// Sign calculation


	// Determine the sign if the sum is zero
	//	if product underflows then use psign
	//	otherwise
	//		if cancelation then 0 unless round to -inf
	//		otherwise psign
	assign ZeroSgn = Underflow & ~ResultDenorm ? PSgn :
				  (PSgn^ZSgn ? FrmM == 3'b010 : PSgn);

	// is the result negitive
	// 	if p - z is the Sum negitive
	// 	if -p + z is the Sum positive
	// 	if -p - z then the Sum is negitive
	assign ResultSgn = InvZ&(ZSgn)&NegSum | InvZ&PSgn&~NegSum | ((ZSgn)&PSgn);
	assign WSgn = SumZero ? ZeroSgn : ResultSgn;
 
	// Select the result
	assign FmaResultM = XNaNM ? {XSgn, XExp, 1'b1,XMan[50:0]} : 
						YNaNM ? {YSgn, YExp, 1'b1,YMan[50:0]} :
						ZNaNM ? {ZSgn, ZExp, 1'b1,ZMan[50:0]} :
						Invalid ? {WSgn, 11'h7ff, 1'b1, 51'b0} : // has to be before inf
						XInfM ? {PSgn, XExp, XMan} :
						YInfM ? {PSgn, YExp, YMan} :
						ZInfM ? {ZSgn, ZExp, ZMan} :
						Overflow ? {WSgn, 11'h7ff, 52'b0} :
						Underflow & ~ResultDenorm ? {WSgn, 63'b0} - {63'b0, (Minus1&AddendStickyM)} + {63'b0, (Plus1&AddendStickyM)} :
						KillProdM ? {ZSgn, ZExp, ZMan} - {63'b0, (Minus1&AddendStickyM)} + {63'b0, (Plus1&AddendStickyM)}: // has to be after Underflow
						{WSgn,WExp,WMan};
	

	// Set Invalid flag for following cases:
	//   1) Inf - Inf
	//   2) 0 * Inf
	//   3) any input is a signaling NaN
	assign ProdOf = (ProdExpM >= 2047 && ~ProdExpM[12]);
	assign ProdInf = ProdOf && ~XNaNM && ~YNaNM;
	assign Invalid = (XNaNM&~XMan[51]) | (YNaNM&~YMan[51]) | (ZNaNM&~ZMan[51]) | ((XInfM || YInfM || ProdInf) & ZInfM & (XSgn ^ YSgn ^ ZSgn)) | (XZeroM & YInfM) | (YZeroM & XInfM);  
	
	// Set Overflow flag if the number is too big to be represented
	assign Overflow = WExpTmp >= 2047 & ~WExpTmp[12];

	// Set Underflow flag if the number is too small to be represented in normal numbers
	assign ProdUf = KillProdM & ZZeroM;
	assign Underflow = SumExp[12] | ProdUf;

	// Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
	assign Inexact = Sticky|Overflow| (|NormSum[1:0]);

	// Combine flags 
	//		- FMA can't set the Divide by zero flag
	//		- Don't set the underflow flag if the result is exact 
	assign FmaFlagsM = {Invalid, 1'b0, Overflow, Underflow & Inexact, Inexact};

endmodule

