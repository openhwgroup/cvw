module fma2(
 
	input logic 	[63:0]		FInput1M,
	input logic		[63:0]		FInput2M,
	input logic 	[63:0]		FInput3M,
	input logic 	[2:0] 		FrmM,
	input logic 	[105:0]		ProdManM,
	input logic 	[161:0]		AlignedAddendM,	
	input logic 	[12:0]		ProdExpM,
	input logic 				FmtM,
	input logic 				AddendStickyM,
	input logic 				KillProdM,
	input logic 	[2:0]		FOpCtrlM,
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

	assign XExp = FmtM ? FInput1M[62:52] : {3'b0, FInput1M[62:55]};
	assign YExp = FmtM ? FInput2M[62:52] : {3'b0, FInput2M[62:55]};
	assign ZExp = FmtM ? FInput3M2[62:52] : {3'b0, FInput3M2[62:55]};

	assign XMan = FmtM ? FInput1M[51:0] : {FInput1M[54:32], 29'b0};
	assign YMan = FmtM ? FInput2M[51:0] : {FInput2M[54:32], 29'b0};
	assign ZMan = FmtM ? FInput3M2[51:0] : {FInput3M2[54:32], 29'b0};



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

	logic [12:0] ManLen;
	assign ManLen = FmtM ? 13'd52 : 13'd23;
	// Determine if the result is denormal
	assign ResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-ManLen));

	// Determine the shift needed for denormal results
	assign SumExpTmpMinus1 = SumExpTmp-1;
	assign DenormShift = ResultDenorm ? SumExpTmpMinus1[8:0] : 9'b0;

	// Normalize the sum
	assign NormSumTmp = SumZero ? 162'b0 : Sum << NormCnt+DenormShift; 
	assign NormSum = NormSumTmp[161:108];
	// Calculate the sticky bit
	assign NormSumSticky = FmtM ? (|NormSumTmp[107:0]) : (|NormSumTmp[136:0]);
	assign Sticky = AddendStickyM | NormSumSticky;

	// Determine sum's exponent
	assign SumExpTmp = KillProdM ? {2'b0, ZExp} : ProdExpM + -({4'b0, NormCnt} - 13'd56);
	assign SumExp = SumZero ? 13'b0 : 
				 ResultDenorm ? 13'b0 :
				 SumExpTmp; 





	// Rounding

	// round to nearest even
	//		{Gaurd, Round, Sticky}
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
	//		{Gaurd, Round, Sticky}
	//		0xx - do nothing
	//		100 - tie - Plus1
	//			- don't add 1 if there was supposed to be a subtraction by a small number that didn't happen
	//		101/110/111 - Plus1

	// Deterimine if the result was supposed to be subtrated by a small number
	logic Gaurd, Round;
	assign Gaurd = FmtM ? NormSum[1] : NormSum[30];
	assign Round = FmtM ? NormSum[0] : NormSum[29];
	assign SubBySmallNum = AddendStickyM&InvZ&~NormSumSticky;

	always_comb begin
		// Determine if you add 1
		case (FrmM)
			3'b000: Plus1Tmp = Gaurd & (Round | (Sticky&~(~Round&SubBySmallNum)) | (~Round&~Sticky&NormSum[2]));//round to nearest even
			3'b001: Plus1Tmp = 0;//round to zero
			3'b010: Plus1Tmp = WSgn & ~(SubBySmallNum);//round down
			3'b011: Plus1Tmp = ~WSgn & ~(SubBySmallNum);//round up
			3'b100: Plus1Tmp = (Gaurd & (Round | (Sticky&~(~Round&SubBySmallNum)) | (~Round&~Sticky)));//round to nearest max magnitude
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
    assign Plus1 = Sticky | (Gaurd|Round) ? Plus1Tmp : 1'b0;
    assign Minus1 = Sticky | (Gaurd|Round) ? Minus1Tmp : 1'b0;
	// Compute rounded result 
    assign {WExpTmp, WMan} = FmtM ? {SumExp, NormSum[53:2]} - {64'b0, Minus1} + {64'b0, Plus1} : {{SumExp, NormSum[53:31]} - {35'b0, Minus1} + {35'b0, Plus1}, 28'b0};
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
	assign FmaResultM = XNaNM ? (FmtM ? {XSgn, FInput1M[62:52], 1'b1,FInput1M[50:0]} : {XSgn, FInput1M[62:55], 1'b1,FInput1M[53:0]}) : 
						YNaNM ? (FmtM ? {YSgn, FInput2M[62:52], 1'b1,FInput2M[50:0]} : {YSgn, FInput2M[62:55], 1'b1,FInput2M[53:0]}) : 
						ZNaNM ? (FmtM ? {ZSgn, FInput3M2[62:52], 1'b1,FInput3M2[50:0]} : {ZSgn, FInput3M2[62:55], 1'b1,FInput3M2[53:0]}) :
						Invalid ? (FmtM ? {WSgn, 11'h7ff, 1'b1, 51'b0} : {WSgn, 8'h7f8, 1'b1, 54'b0}) : // has to be before inf
						XInfM ? {PSgn, FInput1M[62:0]} :
						YInfM ? {PSgn, FInput2M[62:0]} :
						ZInfM ? {ZSgn, FInput3M2[62:0]} :
						Overflow ? (FmtM ? {WSgn, 11'h7ff, 52'b0} : {WSgn, 8'h7f8, 55'b0}) :
						Underflow & ~ResultDenorm ? (FmtM ? {WSgn, 63'b0} - {63'b0, (Minus1&AddendStickyM)} + {63'b0, (Plus1&AddendStickyM)} : {{WSgn, 31'b0} - {31'b0, (Minus1&AddendStickyM)} + {31'b0, (Plus1&AddendStickyM)}, 32'b0}) : //***do you need minus1?
						KillProdM ? (FmtM ? FInput3M2 - {63'b0, (Minus1&AddendStickyM)} + {63'b0, (Plus1&AddendStickyM)} : {FInput3M2[63:32] - {31'b0, (Minus1&AddendStickyM)} + {31'b0, (Plus1&AddendStickyM)}, 32'b0}) : // has to be after Underflow
						FmtM ? {WSgn,WExp,WMan} : {WSgn,WExp[6:0],WMan,4'b0};
logic [63:0] tmp;
	assign tmp = {WSgn,WExp[6:0],WMan,4'b0};

	// Set Invalid flag for following cases:
	//   1) Inf - Inf
	//   2) 0 * Inf
	//   3) any input is a signaling NaN
	logic [12:0] MaxExp;
	assign MaxExp = FmtM ? 13'd2047 : 13'd255;
	assign ProdOf = (ProdExpM >= MaxExp && ~ProdExpM[12]);
	assign ProdInf = ProdOf && ~XNaNM && ~YNaNM;
	assign SigNaN = FmtM ? (XNaNM&~FInput1M[51]) | (YNaNM&~FInput2M[51]) | (ZNaNM&~FInput3M2[51]) : (XNaNM&~FInput1M[54]) | (YNaNM&~FInput2M[54]) | (ZNaNM&~FInput3M2[54]);
	assign Invalid = SigNaN | ((XInfM || YInfM || ProdInf) & ZInfM & (XSgn ^ YSgn ^ ZSgn)) | (XZeroM & YInfM) | (YZeroM & XInfM);  
	
	// Set Overflow flag if the number is too big to be represented
	assign Overflow = WExpTmp >= MaxExp & ~WExpTmp[12];

	// Set Underflow flag if the number is too small to be represented in normal numbers
	assign ProdUf = KillProdM & ZZeroM;
	assign Underflow = SumExp[12] | ProdUf;

	// Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
	assign Inexact = (Sticky|Overflow| (Gaurd|Round))&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

	// Combine flags 
	//		- FMA can't set the Divide by zero flag
	//		- Don't set the underflow flag if the result is exact 
	assign FmaFlagsM = {Invalid, 1'b0, Overflow, Underflow & Inexact, Inexact};

endmodule

