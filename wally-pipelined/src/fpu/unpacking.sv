module unpacking (
    input logic  [63:0] X, Y, Z,
    input logic         FmtE,
    input logic  [2:0]  FOpCtrlE,
    output logic        XSgnE, YSgnE, ZSgnE,
    output logic [10:0] XExpE, YExpE, ZExpE,
    output logic [52:0] XManE, YManE, ZManE,
    output logic XNormE,
    output logic XNaNE, YNaNE, ZNaNE,
    output logic XSNaNE, YSNaNE, ZSNaNE,
    output logic XDenormE, YDenormE, ZDenormE,
    output logic XZeroE, YZeroE, ZZeroE,
    output logic [10:0] BiasE,
    output logic XInfE, YInfE, ZInfE,
    output logic XExpMaxE
);
 //***rename to make significand = 1.frac m = significand
    logic [51:0]    XFracE, YFracE, ZFracE;
    logic           XAssumed1E, YAssumed1E, ZAssumed1E;
    logic           XFracZero, YFracZero, ZFracZero; // input fraction zero
    logic           XExpZero, YExpZero, ZExpZero; // input exponent zero
    logic [63:0]    Addend; // value to add (Z or zero)
    logic           YExpMaxE, ZExpMaxE;  // input exponent all 1s

    assign Addend = FOpCtrlE[2] ? 64'b0 : Z; // Z is only used in the FMA, and is set to Zero if a multiply opperation
    assign XSgnE = FmtE ? X[63] : X[31];
    assign YSgnE = FmtE ? Y[63] : Y[31];
    assign ZSgnE = FmtE ? Addend[63]^FOpCtrlE[0] : Addend[31]^FOpCtrlE[0]; // *** Maybe this should be done in the FMA for modularity?

    assign XExpE = FmtE ? X[62:52] : {3'b0, X[30:23]}; // *** maybe convert to full number of bits here?
    assign YExpE = FmtE ? Y[62:52] : {3'b0, Y[30:23]};
    assign ZExpE = FmtE ? Addend[62:52] : {3'b0, Addend[30:23]};

    assign XFracE = FmtE ? X[51:0] : {X[22:0], 29'b0};
    assign YFracE = FmtE ? Y[51:0] : {Y[22:0], 29'b0};
    assign ZFracE = FmtE ? Addend[51:0] : {Addend[22:0], 29'b0};

    assign XAssumed1E = |XExpE; // *** should these be prepended now to create a significand?
    assign YAssumed1E = |YExpE;
    assign ZAssumed1E = |ZExpE;

    assign XManE = {XAssumed1E, XFracE};
    assign YManE = {YAssumed1E, YFracE};
    assign ZManE = {ZAssumed1E, ZFracE};

    assign XExpZero = ~XAssumed1E;
    assign YExpZero = ~YAssumed1E;
    assign ZExpZero = ~ZAssumed1E;
   
    assign XFracZero = ~|XFracE;
    assign YFracZero = ~|YFracE;
    assign ZFracZero = ~|ZFracE;

    assign XExpMaxE = FmtE ? &XExpE[10:0] : &XExpE[7:0];
    assign YExpMaxE = FmtE ? &YExpE[10:0] : &YExpE[7:0];
    assign ZExpMaxE = FmtE ? &ZExpE[10:0] : &ZExpE[7:0];
   
    assign XNormE = ~(XExpMaxE|XExpZero);
    
    assign XNaNE = XExpMaxE & ~XFracZero;
    assign YNaNE = YExpMaxE & ~YFracZero;
    assign ZNaNE = ZExpMaxE & ~ZFracZero;

    assign XSNaNE = XNaNE&~XFracE[51];
    assign YSNaNE = YNaNE&~YFracE[51];
    assign ZSNaNE = ZNaNE&~ZFracE[51];

    assign XDenormE = XExpZero & ~XFracZero;
    assign YDenormE = YExpZero & ~YFracZero;
    assign ZDenormE = ZExpZero & ~ZFracZero;

    assign XInfE = XExpMaxE & XFracZero;
    assign YInfE = YExpMaxE & YFracZero;
    assign ZInfE = ZExpMaxE & ZFracZero;

    assign XZeroE = XExpZero & XFracZero;
    assign YZeroE = YExpZero & YFracZero;
    assign ZZeroE = ZExpZero & ZFracZero;

    assign BiasE = FmtE ? 13'h3ff : 13'h7f; // *** is it better to convert to full precision exponents so bias isn't needed?

endmodule