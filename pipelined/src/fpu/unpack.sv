`include "wally-config.vh"

module unpack ( 
    input logic  [`FLEN-1:0]        X, Y, Z,    // inputs from register file
    input logic  [`FPSIZES/3:0]     FmtE,       // format signal 00 - single 01 - double 11 - quad 10 - half
    output logic                    XSgnE, YSgnE, ZSgnE,    // sign bits of XYZ
    output logic [`NE-1:0]          XExpE, YExpE, ZExpE,    // exponents of XYZ (converted to largest supported precision)
    output logic [`NF:0]            XManE, YManE, ZManE,    // mantissas of XYZ (converted to largest supported precision)
    output logic                    XNormE,                 // is X a normalized number
    output logic                    XNaNE, YNaNE, ZNaNE,    // is XYZ a NaN
    output logic                    XSNaNE, YSNaNE, ZSNaNE, // is XYZ a signaling NaN
    output logic                    XDenormE, YDenormE, ZDenormE,   // is XYZ denormalized
    output logic                    XZeroE, YZeroE, ZZeroE,         // is XYZ zero
    output logic                    XInfE, YInfE, ZInfE,            // is XYZ infinity
    output logic                    XExpMaxE                        // does X have the maximum exponent (NaN or Inf)
);
 
    logic [`NF-1:0] XFracE, YFracE, ZFracE; //Fraction of XYZ
    logic           XExpNonzero, YExpNonzero, ZExpNonzero; // is the exponent of XYZ non-zero
    logic           XFracZero, YFracZero, ZFracZero; // is the fraction zero
    logic           XExpZero, YExpZero, ZExpZero; // is the exponent zero
    logic           YExpMaxE, ZExpMaxE;  // is the exponent all 1s
    
    unpackinput unpackinputX (.In(X), .FmtE, .Sgn(XSgnE), .Exp(XExpE), .Man(XManE), 
                            .NaN(XNaNE), .SNaN(XSNaNE), .Denorm(XDenormE), 
                            .Zero(XZeroE), .Inf(XInfE), .ExpMax(XExpMaxE), .ExpZero(XExpZero));

    unpackinput unpackinputY (.In(Y), .FmtE, .Sgn(YSgnE), .Exp(YExpE), .Man(YManE), 
                            .NaN(YNaNE), .SNaN(YSNaNE), .Denorm(YDenormE), 
                            .Zero(YZeroE), .Inf(YInfE), .ExpMax(YExpMaxE), .ExpZero(YExpZero));

    unpackinput unpackinputZ (.In(Z), .FmtE, .Sgn(ZSgnE), .Exp(ZExpE), .Man(ZManE), 
                            .NaN(ZNaNE), .SNaN(ZSNaNE), .Denorm(ZDenormE), 
                            .Zero(ZZeroE), .Inf(ZInfE), .ExpMax(ZExpMaxE), .ExpZero(ZExpZero));

                            
    // is X normalized
    assign XNormE = ~(XExpMaxE|XExpZero);
    
endmodule