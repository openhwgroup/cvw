
// `include "wally-config.vh"
module cvtfp (
    input logic [10:0] XExpE,
    input logic [52:0] XManE,
    input logic XSgnE,
    input logic XZeroE,
    input logic XDenormE,
    input logic XInfE,
    input logic XNaNE,
    input logic XSNaNE,
    input logic [2:0] FrmE,
    input logic FmtE,
    output logic [63:0] CvtFpResE,
    output logic [4:0] CvtFpFlgE);

    logic [7:0] DExp;
    logic [51:0] Frac;
    logic Denorm;


	logic [8:0]	i,NormCnt;
	always_comb begin
			i = 0;
			while (~XManE[52-i] && i <= 52) i = i+1;  // search for leading one 
			NormCnt = i;
	end








    logic [12:0] DExpCalc;
    // logic Overflow, Underflow;
    assign DExpCalc = (XExpE-1023+127)&{13{~XZeroE}};
    assign Denorm = $signed(DExpCalc) <= 0 & $signed(DExpCalc) > $signed(-23);

    logic [12:0] ShiftCnt;
	logic [51:0] SFrac;
	logic [25:0] DFrac;
	logic [77:0] DFracTmp;
    //assign ShiftCnt = FmtE ? -DExpCalc&{13{Denorm}} : NormCnt;
    assign SFrac = XManE[51:0] << NormCnt;
logic Shift;
assign Shift = {13{Denorm|(($signed(DExpCalc) > $signed(-25)) & DExpCalc[12])}};
	assign DFracTmp = {XManE, 25'b0} >> ((-DExpCalc+1)&{13{Shift}});
assign DFrac = DFracTmp[76:51];

    logic Sticky, UfSticky, Guard, Round, LSBFrac, UfGuard, UfRound, UfLSBFrac;
    logic CalcPlus1, UfCalcPlus1;
    logic Plus1, UfPlus1;
    // used to determine underflow flag
    assign UfSticky = |DFracTmp[50:0];
    assign UfGuard = DFrac[1];
    assign UfRound = DFrac[0];
    assign UfLSBFrac = DFrac[2];

    
    assign Sticky = UfSticky | UfRound;
    assign Guard = DFrac[2];
    assign Round = DFrac[1];
    assign LSBFrac = DFrac[3];


    always_comb begin
        // Determine if you add 1
        case (FrmE)
            3'b000: CalcPlus1 = Guard & (Round | (Sticky) | (~Round&~Sticky&LSBFrac));//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = XSgnE;//round down
            3'b011: CalcPlus1 = ~XSgnE;//round up
            3'b100: CalcPlus1 = (Guard & (Round | (Sticky) | (~Round&~Sticky)));//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
        // Determine if you add 1 (for underflow flag)
        case (FrmE)
            3'b000: UfCalcPlus1 = UfGuard & (UfRound | UfSticky | (~UfRound&~UfSticky&UfLSBFrac));//round to nearest even
            3'b001: UfCalcPlus1 = 0;//round to zero
            3'b010: UfCalcPlus1 = XSgnE;//round down
            3'b011: UfCalcPlus1 = ~XSgnE;//round up
            3'b100: UfCalcPlus1 = (UfGuard & (UfRound | UfSticky | (~UfRound&~UfSticky)));//round to nearest max magnitude
            default: UfCalcPlus1 = 1'bx;
        endcase
   
    end

    // If an answer is exact don't round
    assign Plus1 = CalcPlus1 & (Sticky | UfGuard | Guard | Round);
    assign UfPlus1 = UfCalcPlus1 & (Sticky | UfGuard);
    logic [12:0] DExpFull;
logic [22:0] DResFrac;
logic [7:0] DResExp;
    assign {DExpFull, DResFrac} = {DExpCalc&{13{~Denorm}}, DFrac[25:3]} + Plus1;
    assign DResExp = DExpFull[7:0];

	logic [10:0] SExp;
	assign SExp = XExpE-(NormCnt&{8{~XZeroE}})+({11{XDenormE}}&1024-127);

    logic Overflow, Underflow, Inexact;
    assign Overflow = $signed(DExpFull) >= $signed({1'b0, {8{1'b1}}}) & ~(XNaNE|XInfE);
    assign Underflow = (($signed(DExpFull) <= 0) & ((Sticky|Guard|Round) | (XManE[52]&~|DFrac) | (|DFrac&~Denorm)) | ((DExpFull == 1) & Denorm & ~(UfPlus1&UfLSBFrac))) & ~(XNaNE|XInfE);
    assign Inexact = (Sticky|Guard|Round|Underflow|Overflow) &~(XNaNE);

logic [31:0] DRes;
    assign DRes = XNaNE ? {XSgnE, XExpE, 1'b1, XManE[50:29]} : 
			Underflow & ~Denorm ? {XSgnE, 30'b0, CalcPlus1&(|FrmE[1:0]|Shift)} : 
			    Overflow | XInfE ? ((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~XSgnE) | (FrmE[1:0]==2'b11&XSgnE)) & ~XInfE ? {XSgnE, 8'hfe, {23{1'b1}}} :
                                                                                                                 {XSgnE, 8'hff, 23'b0} : 
			    {XSgnE, DResExp, DResFrac};
    assign CvtFpResE = FmtE ? {{32{1'b1}},DRes} : {XSgnE, SExp, SFrac[51]|XNaNE, SFrac[50:0]};
    assign CvtFpFlgE = FmtE ? {XSNaNE, 1'b0, Overflow, Underflow, Inexact} : {XSNaNE, 4'b0};

endmodule // fpadd


