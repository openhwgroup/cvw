
`include "wally-config.vh"

module fclassify (
    input  logic [63:0] SrcXE,
    input  logic        FmtE,           // 0-Single 1-Double
    output logic [63:0] ClassResE
    );

    logic [31:0] Single;
    logic [63:0] Double;
    logic Sgn;
    logic Inf, NaN, Zero, Norm, Denorm;
    logic PInf, QNaN, PZero, PNorm, PDenorm;
    logic NInf, SNaN, NZero, NNorm, NDenorm;
    logic MaxExp, ExpZero, ManZero, FirstBitFrac;
   
    // Single and Double precision layouts
    assign Single = SrcXE[63:32];
    assign Double = SrcXE;
    assign Sgn = SrcXE[63];

    // basic calculations for readabillity
    
    assign ExpZero = FmtE ? ~|Double[62:52] : ~|Single[30:23];
    assign MaxExp = FmtE ? &Double[62:52] : &Single[30:23];
    assign ManZero = FmtE ? ~|Double[51:0] : ~|Single[22:0];
    assign FirstBitFrac = FmtE ? Double[51] : Single[22];

    // determine the type of number
    assign NaN      = MaxExp & ~ManZero;
    assign Inf = MaxExp & ManZero;
    assign Zero     = ExpZero & ManZero;
    assign Denorm= ExpZero & ~ManZero;
    assign Norm   = ~ExpZero;

    // determine the sub categories
    assign QNaN = FirstBitFrac&NaN;
    assign SNaN = ~FirstBitFrac&NaN;
    assign PInf = ~Sgn&Inf;
    assign NInf = Sgn&Inf;
    assign PNorm = ~Sgn&Norm;
    assign NNorm = Sgn&Norm;
    assign PDenorm = ~Sgn&Denorm;
    assign NDenorm = Sgn&Denorm;
    assign PZero = ~Sgn&Zero;
    assign NZero = Sgn&Zero;

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
    assign ClassResE = {{54{1'b0}}, QNaN, SNaN, PInf, PNorm,  PDenorm, PZero, NZero, NDenorm, NNorm, NInf};

endmodule
