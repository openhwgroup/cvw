module fma2(
 
	input logic 	[63:0]		X,	// X
	input logic		[63:0]		Y,	// Y
	input logic 	[63:0]		Z,	// Z
	input logic 	[2:0] 		FrmM,		// rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
	input logic 	[2:0]		FOpCtrlM,	// 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
	input logic 				FmtM,		// precision 1 = double 0 = single
	input logic 	[105:0]		ProdManM,	// 1.X frac * 1.Y frac
	input logic 	[161:0]		AlignedAddendM,	// Z aligned for addition
	input logic 	[12:0]		ProdExpM,		// X exponent + Y exponent - bias
	input logic 				AddendStickyM,	// sticky bit that is calculated during alignment
	input logic 				KillProdM,		// set the product to zero before addition if the product is too small to matter
	input logic					XZeroM, YZeroM, ZZeroM, // inputs are zero
	input logic					XInfM, YInfM, ZInfM,	// inputs are infinity
	input logic					XNaNM, YNaNM, ZNaNM,	// inputs are NaN
	output logic	[63:0]		FmaResultM,		// FMA final result
	output logic 	[4:0]		FmaFlagsM);		// FMA flags {invalid, divide by zero, overflow, underflow, inexact}
	


	logic [51:0] 	ResultFrac;	// Result fraction
	logic [10:0] 	ResultExp;	// Result exponent
	logic 		 	ResultSgn;	// Result sign
	logic [10:0] 	ZExp;	// input exponent
	logic 		 	XSgn, YSgn, ZSgn;	// input sign
	logic 		 	PSgn;		// product sign
	logic [105:0]	ProdMan2;	// product being added
	logic [162:0]	AlignedAddend2;	// possibly inverted aligned Z
 	logic [161:0]	Sum;		// positive sum
	logic [162:0]	PreSum;		// possibly negitive sum 
	logic [12:0]	SumExp;		// exponent of the normalized sum
	logic [12:0]	SumExpTmp;	// exponent of the normalized sum not taking into account denormal or zero results
	logic [12:0]	SumExpTmpMinus1;	// SumExpTmp-1
	logic [12:0]	FullResultExp;		// ResultExp with bits to determine sign and overflow
	logic [53:0]	NormSum;	// normalized sum
	logic [161:0]	SumShifted; // sum shifted for normalization
	logic [8:0]		NormCnt;	// output of the leading zero detector
	logic 			NormSumSticky; // sticky bit calulated from the normalized sum
	logic 			SumZero;	// is the sum zero
	logic 			NegSum;		// is the sum negitive
	logic 			InvZ;		// invert Z if there is a subtraction (-product + Z or product - Z)
	logic			ResultDenorm;	// is the result denormalized
	logic			Sticky;		// Sticky bit
	logic 			Plus1, Minus1, CalcPlus1, CalcMinus1;	// do you add or subtract one for rounding
	logic 			Invalid,Underflow,Overflow,Inexact;	// flags
	logic [8:0]		DenormShift;	// right shift if the result is denormalized
	logic 			SubBySmallNum;	// was there supposed to be a subtraction by a small number
	logic [63:0]	Addend;		// value to add (Z or zero)
	logic			ZeroSgn;		// the result's sign if the sum is zero
	logic			ResultSgnTmp;	// the result's sign assuming the result is not zero
	logic 			Guard, Round, LSBNormSum;	// bits needed to determine rounding
	logic [12:0] 	MaxExp;		// maximum value of the exponent
	logic [12:0] 	FracLen;	// length of the fraction
	logic 			SigNaN;		// is an input a signaling NaN
	logic 			UnderflowFlag; 	// Underflow singal used in FmaFlagsM (used to avoid a circular depencency)
	logic [63:0] XNaNResult, YNaNResult, ZNaNResult, InvalidResult, OverflowResult, KillProdResult, UnderflowResult; // possible results

	
	///////////////////////////////////////////////////////////////////////////////
	// Select input fields
	// The following logic duplicates fma1 because it's cheaper to recompute than provide registers
	///////////////////////////////////////////////////////////////////////////////

	// Set addend to zero if FMUL instruction
  	assign Addend = FOpCtrlM[2] ? 64'b0 : Z;

	// split inputs into the sign bit, and exponent to handle single or double precision
	// 		- single precision is in the top half of the inputs
	assign XSgn = X[63];
	assign YSgn = Y[63];
	assign ZSgn = Addend[63]^FOpCtrlM[0]; //Negate Z if subtraction

	assign ZExp = FmtM ? Addend[62:52] : {3'b0, Addend[62:55]};




	// Calculate the product's sign
	//		Negate product's sign if FNMADD or FNMSUB
	assign PSgn = XSgn ^ YSgn ^ FOpCtrlM[1];



	///////////////////////////////////////////////////////////////////////////////
	// Addition
	///////////////////////////////////////////////////////////////////////////////
	
	// Negate Z  when doing one of the following opperations:
	//		-prod +  Z
	//		 prod -  Z 
	assign InvZ = ZSgn ^ PSgn;

	// Choose an inverted or non-inverted addend - the one is added later
	assign AlignedAddend2 = InvZ ? ~{1'b0, AlignedAddendM} : {1'b0, AlignedAddendM};
	// Kill the product if the product is too small to effect the addition (determined in fma1.sv)
	assign ProdMan2 = KillProdM ? 106'b0 : ProdManM;

	// Do the addition
	// 		- add one to negate if the added was inverted
	//		- the 2 extra bits at the begining and end are needed for rounding
	assign PreSum = AlignedAddend2 + {55'b0, ProdMan2, 2'b0} + {162'b0, InvZ};
	 
	// Is the sum negitive
	assign NegSum = PreSum[162];
	// If the sum is negitive, negate the sum.
	assign Sum = NegSum ? -PreSum[161:0] : PreSum[161:0];






	///////////////////////////////////////////////////////////////////////////////
	// Leading one detector
	///////////////////////////////////////////////////////////////////////////////

	//*** replace with non-behavoral code
	logic [8:0]	i;
	always_comb begin
			i = 0;
			while (~Sum[161-i] && $unsigned(i) <= $unsigned(9'd161)) i = i+1;  // search for leading one 
			NormCnt = i+1;    // compute shift count
	end











	///////////////////////////////////////////////////////////////////////////////
	// Normalization
	///////////////////////////////////////////////////////////////////////////////

	// Determine if the sum is zero
	assign SumZero = ~(|Sum);

	// determine the length of the fraction based on precision
	assign FracLen = FmtM ? 13'd52 : 13'd23;

	// Determine if the result is denormal
	assign SumExpTmp = KillProdM ? {2'b0, ZExp} : ProdExpM + -({4'b0, NormCnt} - 13'd56);
	assign ResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-FracLen)) & ~SumZero;

	// Determine the shift needed for denormal results
	assign SumExpTmpMinus1 = SumExpTmp-1;
	assign DenormShift = ResultDenorm ? SumExpTmpMinus1[8:0] : 9'b0;

	// Normalize the sum
	assign SumShifted = SumZero ? 162'b0 : Sum << NormCnt+DenormShift; 
	assign NormSum = SumShifted[161:108];
	// Calculate the sticky bit
	assign NormSumSticky = FmtM ? (|SumShifted[107:0]) : (|SumShifted[136:0]);
	assign Sticky = AddendStickyM | NormSumSticky;

	// Determine sum's exponent
	assign SumExp = SumZero ? 13'b0 : 
				 ResultDenorm ? 13'b0 :
				 SumExpTmp; 





	///////////////////////////////////////////////////////////////////////////////
	// Rounding
	///////////////////////////////////////////////////////////////////////////////

	// round to nearest even
	//		{Guard, Round, Sticky}
	//		0xx - do nothing
	//		100 - tie - Plus1 if result is odd  (LSBNormSum = 1)
	//			- don't add 1 if a small number was supposed to be subtracted
	//		101 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
	//		110/111 - Plus1

	// 	round to zero - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

	// 	round to -infinity 
	//			- Plus1 if negative unless a small number was supposed to be subtracted from a result with guard and round bits of 0
	//			- subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

	// 	round to infinity 
	//			- Plus1 if positive unless a small number was supposed to be subtracted from a result with guard and round bits of 0
	//			- subtract 1 if a small number was supposed to be subtracted from a negative result with guard and round bits of 0

	//  round to nearest max magnitude
	//		{Guard, Round, Sticky}
	//		0xx - do nothing
	//		100 - tie - Plus1
	//			- don't add 1 if a small number was supposed to be subtracted
	//		101 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
	//		110/111 - Plus1

	// determine guard, round, and least significant bit of the result
	assign Guard = FmtM ? NormSum[1] : NormSum[30];
	assign Round = FmtM ? NormSum[0] : NormSum[29];
	assign LSBNormSum = FmtM ? NormSum[2] : NormSum[31];

	// Deterimine if a small number was supposed to be subtrated
	assign SubBySmallNum = AddendStickyM&InvZ&~(NormSumSticky)&~ZZeroM;

	always_comb begin
		// Determine if you add 1
		case (FrmM)
			3'b000: CalcPlus1 = Guard & (Round | (Sticky&~(~Round&SubBySmallNum)) | (~Round&~Sticky&LSBNormSum&~SubBySmallNum));//round to nearest even
			3'b001: CalcPlus1 = 0;//round to zero
			3'b010: CalcPlus1 = ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round down
			3'b011: CalcPlus1 = ~ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round up
			3'b100: CalcPlus1 = (Guard & (Round | (Sticky&~(~Round&SubBySmallNum)) | (~Round&~Sticky&~SubBySmallNum)));//round to nearest max magnitude
			default: CalcPlus1 = 1'bx;
		endcase
		// Determine if you subtract 1
		case (FrmM)
			3'b000: CalcMinus1 = 0;//round to nearest even
			3'b001: CalcMinus1 = SubBySmallNum & ~Guard & ~Round;//round to zero
			3'b010: CalcMinus1 = ~ResultSgn & ~Guard & ~Round & SubBySmallNum;//round down
			3'b011: CalcMinus1 = ResultSgn & ~Guard & ~Round & SubBySmallNum;//round up
			3'b100: CalcMinus1 = 0;//round to nearest max magnitude
			default: CalcMinus1 = 1'bx;
		endcase
	
	end

	// If an answer is exact don't round
    assign Plus1 = CalcPlus1 & (Sticky | Guard | Round);
    assign Minus1 = CalcMinus1 & (Sticky | Guard | Round);

	// Compute rounded result 
	logic [64:0] RoundAdd;
	logic [51:0] NormSumTruncated;
	assign RoundAdd = FmtM ? Minus1 ? {65{1'b1}} : {64'b0, Plus1} : 
							 Minus1 ? {{36{1'b1}}, 29'b0} :	{35'b0, Plus1, 29'b0};
	assign NormSumTruncated = FmtM ? NormSum[53:2] : {NormSum[53:31], 29'b0};

	assign {FullResultExp, ResultFrac} = {SumExp, NormSumTruncated} + RoundAdd;
    assign ResultExp = FullResultExp[10:0];







	///////////////////////////////////////////////////////////////////////////////
	// Sign calculation
	///////////////////////////////////////////////////////////////////////////////

	// Determine the sign if the sum is zero
	//		if cancelation then 0 unless round to -infinity
	//		otherwise psign
	assign ZeroSgn = (PSgn^ZSgn)&~Underflow ? FrmM == 3'b010 : PSgn;

	// is the result negitive
	// 	if p - z is the Sum negitive
	// 	if -p + z is the Sum positive
	// 	if -p - z then the Sum is negitive
	assign ResultSgnTmp = InvZ&(ZSgn)&NegSum | InvZ&PSgn&~NegSum | ((ZSgn)&PSgn);
	assign ResultSgn = SumZero ? ZeroSgn : ResultSgnTmp;
 




	///////////////////////////////////////////////////////////////////////////////
	// Flags
	///////////////////////////////////////////////////////////////////////////////



	// Set Invalid flag for following cases:
	//   1) Inf - Inf (unless x or y is NaN)
	//   2) 0 * Inf
	//   3) any input is a signaling NaN
	assign MaxExp = FmtM ? 13'd2047 : 13'd255;
	assign SigNaN = FmtM ? (XNaNM&~X[51]) | (YNaNM&~Y[51]) | (ZNaNM&~Addend[51]) : 
						   (XNaNM&~X[54]) | (YNaNM&~Y[54]) | (ZNaNM&~Addend[54]);
	assign Invalid = SigNaN | ((XInfM || YInfM) & ZInfM & (PSgn ^ ZSgn) & ~XNaNM & ~YNaNM) | (XZeroM & YInfM) | (YZeroM & XInfM);  
	
	// Set Overflow flag if the number is too big to be represented
	//		- Don't set the overflow flag if an overflowed result isn't outputed
	assign Overflow = FullResultExp >= MaxExp & ~FullResultExp[12]&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

	// Set Underflow flag if the number is too small to be represented in normal numbers
	//		- Don't set the underflow flag if the result is exact 
	assign Underflow = (SumExp[12] | ((SumExp == 0) & (Round|Guard|Sticky))    )&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);
	assign UnderflowFlag = Underflow | (FullResultExp == 0)&Minus1; // before rounding option
	// assign UnderflowFlag = (Underflow | (FullResultExp == 0)&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM)&(Round|Guard|Sticky))  & ~(FullResultExp == 1); //after rounding option
	// Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
	//		- Don't set the underflow flag if an underflowed result isn't outputed
	assign Inexact = (Sticky|Overflow|Guard|Round|Underflow)&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

	// Combine flags 
	//		- FMA can't set the Divide by zero flag
	//		- Don't set the underflow flag if the result was rounded up to a normal number
	assign FmaFlagsM = {Invalid, 1'b0, Overflow, UnderflowFlag, Inexact};







	///////////////////////////////////////////////////////////////////////////////
	// Select the result
	///////////////////////////////////////////////////////////////////////////////
	assign XNaNResult = FmtM ? {XSgn, X[62:52], 1'b1,X[50:0]} : {XSgn, X[62:55], 1'b1,X[53:0]};
	assign YNaNResult = FmtM ? {YSgn, Y[62:52], 1'b1,Y[50:0]} : {YSgn, Y[62:55], 1'b1,Y[53:0]};
	assign ZNaNResult = FmtM ? {ZSgn, Addend[62:52], 1'b1,Addend[50:0]} : {ZSgn, Addend[62:55], 1'b1,Addend[53:0]};
	assign OverflowResult =  FmtM ? ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, 11'h7fe, {52{1'b1}}} : 
																														  {ResultSgn, 11'h7ff, 52'b0} : 
									((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, 8'hfe, {23{1'b1}}, 32'b0} :
																														  {ResultSgn, 8'hff, 55'b0};
	assign InvalidResult = FmtM ? {ResultSgn, 11'h7ff, 1'b1, 51'b0} : {ResultSgn, 8'hff, 1'b1, 54'b0};
	assign KillProdResult = FmtM ?{ResultSgn, Addend[62:0] - {62'b0, (Minus1&AddendStickyM)}} + {62'b0, (Plus1&AddendStickyM)} : {ResultSgn, Addend[62:32] - {30'b0, (Minus1&AddendStickyM)} + {30'b0, (Plus1&AddendStickyM)}, 32'b0};
	assign UnderflowResult = FmtM ? {ResultSgn, 63'b0} + {63'b0, (CalcPlus1&(AddendStickyM|FrmM[1]))} : {{ResultSgn, 31'b0} + {31'b0, (CalcPlus1&(AddendStickyM|FrmM[1]))}, 32'b0};
	assign FmaResultM = XNaNM ? XNaNResult : 
						YNaNM ? YNaNResult : 
						ZNaNM ? ZNaNResult :
						Invalid ? InvalidResult : // has to be before inf
						XInfM ? {PSgn, X[62:0]} :
						YInfM ? {PSgn, Y[62:0]} :
						ZInfM ? {ZSgn, Addend[62:0]} :
						Overflow ? OverflowResult :	
						KillProdM ? KillProdResult : // has to be after Underflow		
						Underflow & ~ResultDenorm ? UnderflowResult :	
						FmtM ? {ResultSgn, ResultExp, ResultFrac} : 
							   {ResultSgn, ResultExp[7:0], ResultFrac, 3'b0};



endmodule