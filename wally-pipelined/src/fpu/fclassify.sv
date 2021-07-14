
`include "wally-config.vh"

module fclassify (
    input  logic XSgnE,
    input  logic [51:0] XFracE,
    input logic XNaNE, 
    input logic XSNaNE,
    input logic XNormE,
    input logic XDenormE,
    input logic XZeroE,
    input logic XInfE,
    // input  logic        FmtE,           // 0-Single 1-Double
    output logic [63:0] ClassResE
    );

    // logic XSgnE;
    // logic Inf, NaN, Zero, Norm, Denorm;
    logic PInf, PZero, PNorm, PDenorm;
    logic NInf, NZero, NNorm, NDenorm;
    // logic MaxExp, ExpZero, ManZero, FirstBitFrac;
   
    // Single and Double precision layouts
    // assign XSgnE = FmtE ? FSrcXE[63] : FSrcXE[31];

    // basic calculations for readabillity
    
    // assign ExpZero = FmtE ? ~|FSrcXE[62:52] : ~|FSrcXE[30:23];
    // assign MaxExp = FmtE ? &FSrcXE[62:52] : &FSrcXE[30:23];
    // assign ManZero = FmtE ? ~|FSrcXE[51:0] : ~|FSrcXE[22:0];
    // assign FirstBitFrac = FmtE ? FSrcXE[51] : FSrcXE[22];

    // determine the type of number
    // assign NaN      = MaxExp & ~ManZero;
    // assign Inf = MaxExp & ManZero;
    // assign Zero     = ExpZero & ManZero;
    // assign Denorm= ExpZero & ~ManZero;
    // assign Norm   = ~ExpZero;

    // determine the sub categories
    // assign QNaN = FirstBitFrac&NaN;
    // assign SNaN = ~FirstBitFrac&NaN;
    assign PInf = ~XSgnE&XInfE;
    assign NInf = XSgnE&XInfE;
    assign PNorm = ~XSgnE&XNormE;
    assign NNorm = XSgnE&XNormE;
    assign PDenorm = ~XSgnE&XDenormE;
    assign NDenorm = XSgnE&XDenormE;
    assign PZero = ~XSgnE&XZeroE;
    assign NZero = XSgnE&XZeroE;

    // determine sub category and combine into the result
    //  bit 0 - -Inf
    //  bit 1 - -Norm
    //  bit 2 - -Denorm
    //  bit 3 - -Zero
    //  bit 4 - +Zero
    //  bit 5 - +Denorm
    //  bit 6 - +Norm
    //  bit 7 - +Inf
    //  bit 8 - signaling NaN
    //  bit 9 - quiet NaN
    assign ClassResE = {{54{1'b0}}, XNaNE&~XSNaNE, XSNaNE, PInf, PNorm,  PDenorm, PZero, NZero, NDenorm, NNorm, NInf};

endmodule
