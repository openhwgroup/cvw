`include "wally-config.vh"

module flags(
    input logic                 XSgnM,
    input logic                 XSNaNM, YSNaNM, ZSNaNM, // inputs are signaling NaNs
    input logic                 XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic Plus1,
    input logic                 InfIn,                  // is a Inf input being used
    input logic                 XZeroM, YZeroM,         // inputs are zero
    input logic                 XNaNM, YNaNM,           // inputs are NaN
    input logic                 NaNIn,                  // is a NaN input being used
    input logic                 Sqrt,                   // Sqrt?
    input logic                 ToInt,                  // convert to integer
    input logic                 IntToFp,                // convert integer to floating point
    input logic                 Int64,                  // convert to 64 bit integer
    input logic                 Signed,                 // convert to a signed integer
    input logic [`FMTBITS-1:0]  OutFmt,                 // output format
    input logic [`NE:0]         CvtCalcExpM,            // the calculated expoent - Cvt
    input logic                 CvtOp,                  // conversion opperation?
    input logic                 DivOp,                  // conversion opperation?
    input logic                 FmaOp,                  // Fma opperation?
    input logic  [`NE+1:0]      FullResExp,             // ResExp with bits to determine sign and overflow
    input logic  [`NE+1:0]      RoundExp,               // exponent of the normalized sum
    input logic  [1:0]          NegResMSBS,             // the negitive integer result's most significant bits
    input logic                 ZSgnEffM, PSgnM,        // the product and modified Z signs
    input logic                 Round, UfLSBRes, Sticky, UfPlus1, // bits used to determine rounding
    output logic                Invalid, Overflow, Underflow, // flags used to select the res
    output logic [4:0]          PostProcFlgM // flags
);
    logic               SigNaN;     // is an input a signaling NaN
    logic               Inexact;    // inexact flag
    logic               FpInexact;  // floating point inexact flag
    logic               IntInexact; // integer inexact flag
    logic               IntInvalid; // integer invalid flag
    logic               FmaInvalid; // integer invalid flag
    logic               DivInvalid; // integer invalid flag
    logic               DivByZero;
    logic [`NE-1:0]     MaxExp;     // the maximum exponent before overflow

    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////



   if (`FPSIZES == 1) begin
        assign MaxExp = ToInt&CvtOp ? Int64 ? (`NE)'(65) : (`NE)'(33) : {`NE{1'b1}};

    end else if (`FPSIZES == 2) begin    
        assign MaxExp = ToInt&CvtOp ? Int64 ? (`NE)'($unsigned(65)) : (`NE)'($unsigned(33)) :
                OutFmt ? {`NE{1'b1}} : {{`NE-`NE1{1'b0}}, {`NE1{1'b1}}};

    end else if (`FPSIZES == 3) begin
        logic [`NE-1:0] MaxExpFp;
        always_comb
            case (OutFmt)
                `FMT:  begin 
                     MaxExpFp = {`NE{1'b1}};
                end
                `FMT1:  begin 
                     MaxExpFp = {{`NE-`NE1{1'b0}}, {`NE1{1'b1}}};
                end
                `FMT2:  begin 
                     MaxExpFp = {{`NE-`NE2{1'b0}}, {`NE2{1'b1}}};
                end
                default:  begin 
                     MaxExpFp = 1'bx;
                end
            endcase
            assign MaxExp = ToInt&CvtOp ? Int64 ? (`NE)'(65) : (`NE)'(33) : MaxExpFp;

    end else if (`FPSIZES == 4) begin        
        logic [`NE-1:0] MaxExpFp;
        always_comb
            case (OutFmt)
                2'h3:  begin 
                     MaxExpFp = {`Q_NE{1'b1}};
                end
                2'h1:  begin 
                     MaxExpFp = {{`Q_NE-`D_NE{1'b0}}, {`D_NE{1'b1}}};
                end
                2'h0:  begin 
                     MaxExpFp = {{`Q_NE-`S_NE{1'b0}}, {`S_NE{1'b1}}};
                end
                2'h2:  begin 
                     MaxExpFp = {{`Q_NE-`H_NE{1'b0}}, {`H_NE{1'b1}}};
                end
            endcase
            assign MaxExp = ToInt&CvtOp ? Int64 ? (`NE)'(65) : (`NE)'(33) : MaxExpFp;
    end

    //                 if the result is greater than or equal to the max exponent
    //                 |                     and the exponent isn't negitive
    //                 |                     |                   if the input isnt infinity or NaN
    //                 |                     |                   |            
    assign Overflow = (FullResExp>={2'b0, MaxExp}) & ~FullResExp[`NE+1]&~(InfIn|NaNIn);

    // detecting tininess after rounding
    //                  the exponent is negitive
    //                  |                    the result is denormalized
    //                  |                    |                    the result is normal and rounded from a denorm
    //                  |                    |                    |                                      and if given an unbounded exponent the result does not round
    //                  |                    |                    |                                      |                     and if the result is not exact
    //                  |                    |                    |                                      |                     |               and if the input isnt infinity or NaN
    //                  |                    |                    |                                      |                     |               |
    assign Underflow = ((FullResExp[`NE+1] | (FullResExp == 0) | ((FullResExp == 1) & (RoundExp == 0) & ~(UfPlus1&UfLSBRes)))&(Round|Sticky))&~(InfIn|NaNIn);

    // Set Inexact flag if the res is diffrent from what would be outputed given infinite precision
    //      - Don't set the underflow flag if an underflowed res isn't outputed
    assign FpInexact = (Sticky|Overflow|Round|Underflow)&~(InfIn|NaNIn);

    //                  if the res is too small to be represented and not 0
    //                  |                                     and if the res is not invalid (outside the integer bounds)
    //                  |                                     |
    assign IntInexact = ((CvtCalcExpM[`NE]&~XZeroM)|Sticky|Round)&~Invalid;

    // select the inexact flag to output
    assign Inexact = ToInt ? IntInexact : FpInexact;

    // Set Invalid flag for following cases:
    //   1) any input is a signaling NaN
    //   2) Inf - Inf (unless x or y is NaN)
    //   3) 0 * Inf

    //                  if the input is NaN or infinity
    //                  |           if the integer res overflows (out of range) 
    //                  |           |         if the input was negitive but ouputing to a unsigned number
    //                  |           |         |                    the res doesn't round to zero
    //                  |           |         |                    |               or the res rounds up out of bounds
    //                  |           |         |                    |                       and the res didn't underflow
    //                  |           |         |                    |                       |
    assign IntInvalid = XNaNM|XInfM|Overflow|((XSgnM&~Signed)&(~((CvtCalcExpM[`NE]|(~|CvtCalcExpM))&~Plus1)))|(NegResMSBS[1]^NegResMSBS[0]);
    //                                                                                                     |
    //                                                                                                     or when the positive res rounds up out of range
    assign SigNaN = (XSNaNM&~(IntToFp&CvtOp)) | (YSNaNM&~CvtOp) | (ZSNaNM&FmaOp);
    assign FmaInvalid = ((XInfM | YInfM) & ZInfM & (PSgnM ^ ZSgnEffM) & ~XNaNM & ~YNaNM) | (XZeroM & YInfM) | (YZeroM & XInfM);
    assign DivInvalid = ((XInfM & YInfM) | (XZeroM & YZeroM))&~Sqrt | (XSgnM&Sqrt);

    assign Invalid = SigNaN | (FmaInvalid&FmaOp) | (DivInvalid&DivOp) | (IntInvalid&CvtOp&ToInt);


    assign DivByZero = YZeroM&DivOp;  

    // Combine flags
    //      - to integer results do not set the underflow or overflow flags
    assign PostProcFlgM = {Invalid, DivByZero, Overflow&~(ToInt&CvtOp), Underflow&~(ToInt&CvtOp), Inexact};

endmodule




