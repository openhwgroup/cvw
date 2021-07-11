
// `include "wally-config.vh"
module fcvt (
    input logic [63:0] X,
    input logic [64-1:0] SrcAE,
    input logic [3:0] FOpCtrlE,
    input logic [2:0] FrmE,
    input logic FmtE,
    output logic [63:0] CvtResE,
    output logic [4:0] CvtFlgE);

    logic [10:0] XExp;
    logic [51:0] XFrac;
    logic XSgn;
    logic [10:0] ResExp,TmpExp;
    logic [51:0] ResFrac;
    logic ResSgn;
    logic [10:0] NormCnt;
    logic [11:0]    Bias;   // 1023 for double, 127 for single
    logic [7:0]    Bits, SubBits;
    logic [64+51:0]    ShiftedManTmp;
    logic [64+51:0]    ShiftVal;
    logic [64+1:0]    ShiftedMan;
    logic [64:0]	RoundedTmp;
    logic [63:0]	Rounded;
    logic [12:0]    ExpVal, ShiftCnt;
    logic [64-1:0] PosInt;
    
    logic [64-1:0] CvtIntRes;
    logic [63:0] CvtRes;
    logic XFracZero, Of,Uf;
    logic XExpMax;
    logic XNaN, XDenorm, XInf, XZero;
    logic Plus1,CalcPlus1, Guard, Round, LSB, Sticky;
    logic SgnRes, In64;
    logic Res64;
    logic RoundMSB;
    logic RoundSgn;
    logic XExpZero;

      //  fcvt.w.s  = 0010 -
      //  fcvt.wu.s = 0110 -
      //  fcvt.s.w  = 0001 
      //  fcvt.s.wu = 0101 
      //  fcvt.l.s  = 1010 -
      //  fcvt.lu.s = 1110 -
      //  fcvt.s.l  = 1001 
      //  fcvt.s.lu = 1101 
      //  fcvt.w.d  = 0010 - 
      //  fcvt.wu.d = 0110 -
      //  fcvt.d.w  = 0001 
      //  fcvt.d.wu = 0101 
      //  fcvt.l.d  = 1010 -
      //  fcvt.lu.d = 1110 -
      //  fcvt.d.l  = 1001 --
      //  fcvt.d.lu = 1101 --
      //  {long, unsigned, to int, from int} Fmt controls the output for fp -> fp
    assign XSgn = X[63];
    assign XExp = FmtE ? X[62:52] : {3'b0, X[62:55]};
    assign XFrac = FmtE ? X[51:0] : {X[54:32], 29'b0};
    assign XExpZero = ~|XExp;
   
    assign XFracZero = ~|XFrac;
    assign XExpMax = FmtE ? &XExp[10:0] : &XExp[7:0];
    assign XNaN = XExpMax & ~XFracZero;
    assign XDenorm = XExpZero & ~XFracZero;
    assign XInf = XExpMax & XFracZero;
    assign XZero = XExpZero & XFracZero;


    assign Bias = FmtE ? 12'h3ff : 12'h7f;
    assign Res64 = ((FOpCtrlE==4'b1010 || FOpCtrlE==4'b1110) | (FmtE&(FOpCtrlE==4'b0001 | FOpCtrlE==4'b0101 | FOpCtrlE==4'b0000 | FOpCtrlE==4'b1001 | FOpCtrlE==4'b1101)));
    assign In64 = ((FOpCtrlE==4'b1001 || FOpCtrlE==4'b1101) | (FmtE&(FOpCtrlE==4'b0010 | FOpCtrlE==4'b0110 | FOpCtrlE==4'b1010 | FOpCtrlE==4'b1110) | (FOpCtrlE==4'b1101 & ~FmtE)));
    assign SubBits = In64 ? 8'd64 : 8'd32;
    assign Bits = Res64 ? 8'd64 : 8'd32;
    assign ExpVal = XExp - Bias + XDenorm;

////////////////////////////////////////////////////////

	logic [64-1:0] IntIn;
    assign IntIn = FOpCtrlE[3] ? SrcAE : {SrcAE[31:0], 32'b0};
    assign PosInt = IntIn[64-1]&~FOpCtrlE[2] ? -IntIn : IntIn;
    assign ResSgn = ~FOpCtrlE[2] ? IntIn[64-1] : 1'b0;
    
	// Leading one detector
	logic [8:0]	i;
	always_comb begin
			i = 0;
			while (~PosInt[64-1-i] && i <= 64) i = i+1;  // search for leading one 
			NormCnt = i+1;    // compute shift count
	end
    assign TmpExp = i==64 ? 0 : Bias + SubBits - NormCnt;




////////////////////////////////////////////



    assign ShiftCnt = FOpCtrlE[1] ? ExpVal : NormCnt;
    assign ShiftVal = FOpCtrlE[1] ? {{64-2{1'b0}}, ~(XDenorm|XZero), XFrac} : {PosInt, 52'b0};
	//if shift = -1 then shift one bit right for round to nearest (shift over 2 never rounds)
	// if the shift is negitive add bit for sticky bit
	// otherwise shift left
    assign ShiftedManTmp = &ShiftCnt ? {{64-1{1'b0}}, ~(XDenorm|XZero), XFrac[51:1]} : ShiftCnt[12] ? {115'b0, ~XZero} : ShiftVal << ShiftCnt;

    assign ShiftedMan = ShiftedManTmp[64+51:50];
    assign Sticky = |ShiftedManTmp[49:0] | &ShiftCnt&XFrac[0] | (FOpCtrlE[0]&|ShiftedManTmp[62:50]) | (FOpCtrlE[0]&~FmtE&|ShiftedManTmp[91:63]);

    
    // determine guard, round, and least significant bit of the result
    assign Guard = FOpCtrlE[1] ? ShiftedMan[1] : FmtE ? ShiftedMan[13] : ShiftedMan[42];
    assign Round = FOpCtrlE[1] ? ShiftedMan[0] : FmtE ? ShiftedMan[12] : ShiftedMan[41];
    assign LSB = FOpCtrlE[1] ? ShiftedMan[2] : FmtE ? ShiftedMan[14] : ShiftedMan[43];

    always_comb begin
        // Determine if you add 1
        case (FrmE)
            3'b000: CalcPlus1 = Guard & (Round | Sticky | (~Round&~Sticky&LSB));//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = (XSgn&FOpCtrlE[1]) | (ResSgn&FOpCtrlE[0]);//round down
            3'b011: CalcPlus1 = (~XSgn&FOpCtrlE[1]) | (~ResSgn&FOpCtrlE[0]);//round up
            3'b100: CalcPlus1 = Guard & (Round | Sticky | (~Round&~Sticky));//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
    end

    assign Plus1 = CalcPlus1 & (Guard|Round|Sticky)&~(XZero&FOpCtrlE[1]);

    assign RoundedTmp = ShiftedMan[64+1:2] + Plus1;
    assign {ResExp, ResFrac} = FmtE ? {TmpExp, ShiftedMan[64+1:14]} + Plus1 :  {{TmpExp, ShiftedMan[64+1:43]} + Plus1, 29'b0} ;

     assign Rounded = Res64 ? XSgn&FOpCtrlE[1] ? -RoundedTmp[63:0] : RoundedTmp[63:0] : 
			      XSgn ? {{32{1'b1}}, -RoundedTmp[31:0]} : {32'b0, RoundedTmp[31:0]};
     assign RoundMSB = Res64 ? RoundedTmp[64] : RoundedTmp[32];
     assign RoundSgn = Res64 ? Rounded[63] : Rounded[31];



   // Choose result
   //    double to unsigned long
   //         >2^64-1 or +inf or NaN - all 1's
   //         <0 or -inf - zero
   //         otherwise rounded result
    //assign Of = (~XSgn&($signed(ShiftCnt) >= $signed(Bits))) | (RoundMSB&(ShiftCnt==(Bits-1))) | (~XSgn&XInf) | XNaN;
    assign Of = (~XSgn&($signed(ShiftCnt) >= $signed(Bits))) | (~XSgn&RoundSgn&~FOpCtrlE[2]) | (RoundMSB&(ShiftCnt==(Bits-1))) | (~XSgn&XInf) | XNaN;
    assign Uf = FOpCtrlE[2] ? XSgn&~XZero | (XSgn&XInf) | (XSgn&~XZero&(~ShiftCnt[12]|CalcPlus1)) | (ShiftCnt[12]&Plus1) : (XSgn&XInf) | (XSgn&($signed(ShiftCnt) >= $signed(Bits))) | (XSgn&~RoundSgn&~ShiftCnt[12]);    // assign CvtIntRes =  (XSgn | ShiftCnt[12]) ? {64{1'b0}}  : (ShiftCnt >= 64) ? {64{1'b1}} : Rounded;
    assign SgnRes = ~FOpCtrlE[3] & FOpCtrlE[1];
    assign CvtIntRes = Of ? FOpCtrlE[2] ? SgnRes ? {32'b0, {32{1'b1}}}: {64{1'b1}} : SgnRes ? {33'b0, {31{1'b1}}}: {1'b0, {63{1'b1}}} : 
                    Uf ? FOpCtrlE[2] ? 64'b0 : SgnRes ? {32'b0, 1'b1, 31'b0} : {1'b1, 63'b0} :
		            Rounded[64-1:0];
                    
    assign CvtRes = FmtE ? {ResSgn, ResExp, ResFrac} : {ResSgn, ResExp[7:0], ResFrac, 3'b0};
    assign CvtResE = FOpCtrlE[0] ? CvtRes : CvtIntRes;
    assign CvtFlgE = {(Of | Uf)&FOpCtrlE[1], 3'b0, (Guard|Round|Sticky)&FOpCtrlE[0]};




endmodule // fpadd


