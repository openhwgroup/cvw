`include "wally-config.vh"

module fpuclassify (
    input  logic [63:0] FInput1E,
    input  logic        FmtE,           // 0-single 1-double
    output logic [63:0] ClassResultE
    );

    logic [31:0] single;
    logic [63:0] double;
    logic sign;
    logic infinity, NaN, zero, normal, subnormal;
    logic ExpNotZero, ExpOnes, ManNotZero, ExpZero, ManZero, FirstBitMan;
   
    // single and double precision layouts
    assign single = FInput1E[63:32];
    assign double = FInput1E;
    assign sign = FInput1E[63];

    // basic calculations for readabillity
    assign ExpNotZero = FmtE ? |double[62:52] : |single[30:23];
    assign ExpZero = ~ExpNotZero;
    assign ExpOnes = FmtE ? &double[62:52] : &single[30:23];
    assign ManNotZero = FmtE ? |double[51:0] : |single[22:0];
    assign ManZero = ~ManNotZero;
    assign FirstBitMan = FmtE ? double[51] : single[22];

    // determine the type of number
    assign NaN      = ExpOnes & ManNotZero;
    assign infinity = ExpOnes & ManZero;
    assign zero     = ExpZero & ManZero;
    assign subnormal= ExpZero & ManNotZero;
    assign normal   = ExpNotZero;

    // determine sub category and combine into the result
    //  bit 0 - -infinity
    //  bit 1 - -normal
    //  bit 2 - -subnormal
    //  bit 3 - -zero
    //  bit 4 - +zero
    //  bit 5 - +subnormal
    //  bit 6 - +normal
    //  bit 7 - +infinity
    //  bit 8 - signaling NaN
    //  bit 9 - quiet NaN
    assign ClassResultE = {{`XLEN-10{1'b0}}, FirstBitMan&NaN, ~FirstBitMan&NaN, ~sign&infinity, ~sign&normal, 
                                    ~sign&subnormal, ~sign&zero, sign&zero, sign&subnormal, sign&normal, sign&infinity, {64-`XLEN{1'b0}}};


endmodule
