
`include "wally-config.vh"

module fclassify (
    input logic         XSgnE,  // sign bit
    input logic         XNaNE,  // is NaN
    input logic         XSNaNE, // is signaling NaN
    input logic         XNormE, // is normal
    input logic         XDenormE, // is denormal
    input logic         XZeroE, // is zero
    input logic         XInfE,  // is infinity
    output logic [63:0] ClassResE // classify result
    );

    logic PInf, PZero, PNorm, PDenorm;
    logic NInf, NZero, NNorm, NDenorm;

   
    // determine the sub categories
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
