
// `include "wally-config.vh"
module cvtfp (
    input logic [10:0] XExpE,   // input's exponent
    input logic [52:0] XManE,   // input's mantissa
    input logic XSgnE,          // input's sign
    input logic XZeroE,         // is the input zero
    input logic XDenormE,       // is the input denormalized
    input logic XInfE,          // is the input infinity
    input logic XNaNE,          // is the input a NaN
    input logic XSNaNE,         // is the input a signaling NaN
    input logic [2:0] FrmE,     // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic FmtE,           // the input's precision (1 = double 0 = single)
    output logic [63:0] CvtFpResE,  // the fp to fp conversion's result
    output logic [4:0] CvtFpFlgE);  // the fp to fp conversion's flags

    logic [12:0] DSExp; // double to single precision exponent
    logic Denorm;       // is the double to single precision result denormalized
    logic Shift;        // do you shift the double precision exponent (if single precision result is denormalized)
	logic [51:0] SDFrac;    // single to double precision fraction
	logic [25:0] DSFrac;    // double to single precision fraction
	logic [77:0] DSFracShifted; // single precision fraction shifted for double precision
    logic Sticky, UfSticky, Guard, Round, LSBFrac, UfGuard, UfRound, UfLSBFrac; // rounding bits
    logic CalcPlus1, UfCalcPlus1, Plus1, UfPlus1; // do you add one to the result
    logic [12:0] DSExpFull; // full double to single exponent
    logic [22:0] DSResFrac; // final double to single fraction
    logic [7:0] DSResExp;   // final double to single exponent
	logic [10:0] SDExp;     // final single to double precision exponent
    logic Overflow, Underflow, Inexact; // flags
    logic [31:0] DSRes; // double to single precision result



    ///////////////////////////////////////////////////////////////////////////////
    // LZC
    ///////////////////////////////////////////////////////////////////////////////


    // LZC - find the first 1 in the input's mantissa
	logic [8:0]	i,NormCnt;
	always_comb begin
			i = 0;
			while (~XManE[52-i] && i <= 52) i = i+1;  // search for leading one 
			NormCnt = i;
	end


    ///////////////////////////////////////////////////////////////////////////////
    // Expoents
    ///////////////////////////////////////////////////////////////////////////////

    // convert the single precion exponent to single precision.
    //      - subtract the double precision exponent (1023) and add the
    //        single precsision exponent (127)
    //      - if the input is zero then kill the exponent

    assign DSExp = ({2'b0,XExpE}-13'd1023+13'd127)&{13{~XZeroE}};

    // is the converted double to single precision exponent in the denormalized range
    assign Denorm = $signed(DSExp) <= 0 & $signed(DSExp) > $signed(-(13'd23));

    
    // caluculate the final single to double precsion exponent
    //      - subtract the single precision bias (127) and add the double
    //        precision bias (127)
    //      - if the result is zero or denormalized, kill the exponent
	assign SDExp = XExpE-({2'b0,NormCnt&{9{~XZeroE}}})+({11{XDenormE}}&1024-127); //*** seems ineffecient



    ///////////////////////////////////////////////////////////////////////////////
    // Fraction
    ///////////////////////////////////////////////////////////////////////////////


    // normalize the single precision fraction for double precsion
    //      - needed for denormal single precsion values
    assign SDFrac = XManE[51:0] << NormCnt;

    // check if the double precision mantissa needs to be shifted
    //      - the mantissa needs to be shifted if the single precision result is denormal
    assign Shift = Denorm | (($signed(DSExp) > $signed(-(13'd25))) & DSExp[12]);
    // shift the mantissa
	assign DSFracShifted = {XManE, 25'b0} >> ((-DSExp+1)&{13{Shift}}); //***might be some optimization here
    assign DSFrac = DSFracShifted[76:51];



    ///////////////////////////////////////////////////////////////////////////////
    // Rounder
    ///////////////////////////////////////////////////////////////////////////////

    // used to determine underflow flag
    assign UfSticky = |DSFracShifted[50:0];
    assign UfGuard = DSFrac[1];
    assign UfRound = DSFrac[0];
    assign UfLSBFrac = DSFrac[2];

    
    assign Sticky = UfSticky | UfRound;
    assign Guard = DSFrac[2];
    assign Round = DSFrac[1];
    assign LSBFrac = DSFrac[3];


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

    // if an answer is exact don't round
    assign Plus1 = CalcPlus1 & (Sticky | UfGuard | Guard | Round);
    assign UfPlus1 = UfCalcPlus1 & (Sticky | UfGuard);



    // round the double to single precision result
    assign {DSExpFull, DSResFrac} = {DSExp&{13{~Denorm}}, DSFrac[25:3]} + {35'b0,Plus1};
    assign DSResExp = DSExpFull[7:0];


    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////

    // calculate the flags
    //      - overflow, underflow and inexact can only be set by the double to single precision opperation
    //      - don't set underflow or overflow if the input is NaN or Infinity
    //      - don't set the inexact flag if the input is NaN 
    assign Overflow = $signed(DSExpFull) >= $signed({5'b0, {8{1'b1}}}) & ~(XNaNE|XInfE);
    assign Underflow = (($signed(DSExpFull) <= 0) & ((Sticky|Guard|Round) | (XManE[52]&~|DSFrac) | (|DSFrac&~Denorm)) | ((DSExpFull == 1) & Denorm & ~(UfPlus1&UfLSBFrac))) & ~(XNaNE|XInfE);
    assign Inexact = (Sticky|Guard|Round|Underflow|Overflow) &~(XNaNE);
    
    // pack the flags together and choose the result based on the opperation
    assign CvtFpFlgE = FmtE ? {XSNaNE, 1'b0, Overflow, Underflow, Inexact} : {XSNaNE, 4'b0};



    ///////////////////////////////////////////////////////////////////////////////
    // Result Selection
    ///////////////////////////////////////////////////////////////////////////////

    // select the double to single precision result
    assign DSRes = XNaNE ? {XSgnE, {8{1'b1}}, 1'b1, XManE[50:29]} : 
			Underflow & ~Denorm ? {XSgnE, 30'b0, CalcPlus1&(|FrmE[1:0]|Shift)} : 
			Overflow | XInfE ? ((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~XSgnE) | (FrmE[1:0]==2'b11&XSgnE)) & ~XInfE ? {XSgnE, 8'hfe, {23{1'b1}}} :
                                                                                                                      {XSgnE, 8'hff, 23'b0} : 
			{XSgnE, DSResExp, DSResFrac};

    // select the final result based on the opperation
    assign CvtFpResE = FmtE ? {{32{1'b1}},DSRes} : {XSgnE, SDExp, SDFrac[51]|XNaNE, SDFrac[50:0]};

endmodule // fpadd


