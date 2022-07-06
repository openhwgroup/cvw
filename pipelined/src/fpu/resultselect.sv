`include "wally-config.vh"

module resultselect(
    input logic                 XSgnM,        // input signs
    input logic  [`NF:0]        XManM, YManM, ZManM, // input mantissas
    input logic                 XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic  [2:0]          FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic  [`FMTBITS-1:0] OutFmt,       // output format
    input logic                 InfIn,
    input logic                 XInfM, YInfM,
    input logic                 XZeroM,
    input logic                 IntZeroM,
    input logic                 NaNIn,
    input logic                 IntToFp,
    input logic                 Int64,
    input logic                 Signed,
    input logic                 CvtOp,
    input logic                 DivOp,
    input logic                 FmaOp,
    input logic                 Plus1,
    input logic                 DivByZero,
    input logic  [`NE:0]        CvtCalcExpM,    // the calculated expoent
    input logic                 ResSgn,  // the res's sign
    input logic                 IntInvalid, Invalid, Overflow,  // flags
    input logic                 CvtResUf,
    input logic  [`NE-1:0]      ResExp,          // Res exponent
    input logic  [`NE+1:0]      FullResExp,          // Res exponent
    input logic  [`NF-1:0]      ResFrac,         // Res fraction
    input logic  [`XLEN+1:0]    NegRes,     // the negation of the result
    output logic [`FLEN-1:0]    PostProcResM,     // final res
    output logic [`XLEN-1:0]    FCvtIntResM     // final res
);
    logic [`FLEN-1:0]   XNaNRes, YNaNRes, ZNaNRes, InvalidRes, OfRes, UfRes, NormRes; // possible results
    logic OfResMax;
    logic [`XLEN-1:0]       OfIntRes;   // the overflow result for integer output
    logic KillRes;
    logic SelOfRes;


    // does the overflow result output the maximum normalized floating point number
    //                output infinity if the input is infinity
    assign OfResMax = (~InfIn|(IntToFp&CvtOp))&~DivByZero&((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResSgn) | (FrmM[1:0]==2'b11&ResSgn));

    if (`FPSIZES == 1) begin

        //NaN res selection depending on standard
        if(`IEEE754) begin
            assign XNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]};
            assign YNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]};
            assign ZNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]};
            assign InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
        end else begin
            assign InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
        end

        assign OfRes =  OfResMax ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}};
        assign UfRes = {ResSgn, {`FLEN-1{1'b0}}, Plus1&FrmM[1]&~(DivOp&YInfM)};
        assign NormRes = {ResSgn, ResExp, ResFrac};

    end else if (`FPSIZES == 2) begin //will the format conversion in killprod work in other conversions?
        if(`IEEE754) begin
            assign XNaNRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, XManM[`NF-2:`NF-`NF1]};
            assign YNaNRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, YManM[`NF-2:`NF-`NF1]};
            assign ZNaNRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`NF1]};
            assign InvalidRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
        end else begin 
            assign InvalidRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
        end
        
        assign OfRes =  OutFmt ? OfResMax ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}} :
                               OfResMax ? {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} : {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1{1'b1}}, (`NF1)'(0)};
        assign UfRes = OutFmt ? {ResSgn, (`FLEN-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)} : {{`FLEN-`LEN1{1'b1}}, ResSgn, (`LEN1-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
        assign NormRes = OutFmt ? {ResSgn, ResExp, ResFrac} : {{`FLEN-`LEN1{1'b1}}, ResSgn, ResExp[`NE1-1:0], ResFrac[`NF-1:`NF-`NF1]};

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT: begin  
                    if(`IEEE754) begin
                        XNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]};
                        YNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]};
                        ZNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]};
                        InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end else begin 
                        InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end
                    
                    OfRes = OfResMax ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}};
                    UfRes = {ResSgn, (`FLEN-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
                    NormRes = {ResSgn, ResExp, ResFrac};
                end
                `FMT1: begin  
                    if(`IEEE754) begin
                        XNaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, XManM[`NF-2:`NF-`NF1]};
                        YNaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, YManM[`NF-2:`NF-`NF1]};
                        ZNaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`NF1]};
                        InvalidRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
                    end else begin 
                        InvalidRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
                    end
                    OfRes = OfResMax ? {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} : {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1{1'b1}}, (`NF1)'(0)};
                    UfRes = {{`FLEN-`LEN1{1'b1}}, ResSgn, (`LEN1-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
                    NormRes = {{`FLEN-`LEN1{1'b1}}, ResSgn, ResExp[`NE1-1:0], ResFrac[`NF-1:`NF-`NF1]};
                end
                `FMT2: begin  
                    if(`IEEE754) begin
                        XNaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, XManM[`NF-2:`NF-`NF2]};
                        YNaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, YManM[`NF-2:`NF-`NF2]};
                        ZNaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`NF2]};
                        InvalidRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
                    end else begin 
                        InvalidRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
                    end
                    
                    OfRes = OfResMax ? {{`FLEN-`LEN2{1'b1}}, ResSgn, {`NE2-1{1'b1}}, 1'b0, {`NF2{1'b1}}} : {{`FLEN-`LEN2{1'b1}}, ResSgn, {`NE2{1'b1}}, (`NF2)'(0)};
                    UfRes = {{`FLEN-`LEN2{1'b1}}, ResSgn, (`LEN2-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
                    NormRes = {{`FLEN-`LEN2{1'b1}}, ResSgn, ResExp[`NE2-1:0], ResFrac[`NF-1:`NF-`NF2]};
                end
                default: begin
                    if(`IEEE754) begin
                        XNaNRes = (`FLEN)'(0);
                        YNaNRes = (`FLEN)'(0);
                        ZNaNRes = (`FLEN)'(0);
                        InvalidRes = (`FLEN)'(0);
                    end else begin 
                        InvalidRes = (`FLEN)'(0);
                    end
                    OfRes = (`FLEN)'(0);
                    UfRes = (`FLEN)'(0);
                    NormRes = (`FLEN)'(0);
                end
            endcase

    end else if (`FPSIZES == 4) begin 
        always_comb
            case (OutFmt)
                2'h3: begin  
                    if(`IEEE754) begin
                        XNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]};
                        YNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]};
                        ZNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]};
                        InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end else begin 
                        InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end
                    
                    OfRes = OfResMax ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}};
                    UfRes = {ResSgn, (`FLEN-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
                    NormRes = {ResSgn, ResExp, ResFrac};
                end
                2'h1: begin  
                    if(`IEEE754) begin
                        XNaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, XManM[`NF-2:`NF-`D_NF]};
                        YNaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, YManM[`NF-2:`NF-`D_NF]};
                        ZNaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`D_NF]};
                        InvalidRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
                    end else begin 
                        InvalidRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
                    end
                    OfRes = OfResMax ? {{`FLEN-`D_LEN{1'b1}}, ResSgn, {`D_NE-1{1'b1}}, 1'b0, {`D_NF{1'b1}}} : {{`FLEN-`D_LEN{1'b1}}, ResSgn, {`D_NE{1'b1}}, (`D_NF)'(0)};
                    UfRes = {{`FLEN-`D_LEN{1'b1}}, ResSgn, (`D_LEN-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
                    NormRes = {{`FLEN-`D_LEN{1'b1}}, ResSgn, ResExp[`D_NE-1:0], ResFrac[`NF-1:`NF-`D_NF]};
                end
                2'h0: begin  
                    if(`IEEE754) begin
                        XNaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, XManM[`NF-2:`NF-`S_NF]};
                        YNaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, YManM[`NF-2:`NF-`S_NF]};
                        ZNaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`S_NF]};
                        InvalidRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
                    end else begin 
                        InvalidRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
                    end
                    
                    OfRes = OfResMax ? {{`FLEN-`S_LEN{1'b1}}, ResSgn, {`S_NE-1{1'b1}}, 1'b0, {`S_NF{1'b1}}} : {{`FLEN-`S_LEN{1'b1}}, ResSgn, {`S_NE{1'b1}}, (`S_NF)'(0)};
                    UfRes = {{`FLEN-`S_LEN{1'b1}}, ResSgn, (`S_LEN-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
                    NormRes = {{`FLEN-`S_LEN{1'b1}}, ResSgn, ResExp[`S_NE-1:0], ResFrac[`NF-1:`NF-`S_NF]};
                end
                2'h2: begin  
                    if(`IEEE754) begin
                        XNaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, XManM[`NF-2:`NF-`H_NF]};
                        YNaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, YManM[`NF-2:`NF-`H_NF]};
                        ZNaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`H_NF]};
                        InvalidRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
                    end else begin 
                        InvalidRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
                    end
                    
                    OfRes = OfResMax ? {{`FLEN-`H_LEN{1'b1}}, ResSgn, {`H_NE-1{1'b1}}, 1'b0, {`H_NF{1'b1}}} : {{`FLEN-`H_LEN{1'b1}}, ResSgn, {`H_NE{1'b1}}, (`H_NF)'(0)};      
	            // zero is exact fi dividing by infinity so don't add 1
                    UfRes = {{`FLEN-`H_LEN{1'b1}}, ResSgn, (`H_LEN-2)'(0), Plus1&FrmM[1]&~(DivOp&YInfM)};
                    NormRes = {{`FLEN-`H_LEN{1'b1}}, ResSgn, ResExp[`H_NE-1:0], ResFrac[`NF-1:`NF-`H_NF]};
                end
            endcase

    end

    



    // determine if you shoould kill the res - Cvt
    //      - do so if the res underflows, is zero (the exp doesnt calculate correctly). or the integer input is 0
    //      - dont set to zero if fp input is zero but not using the fp input
    //      - dont set to zero if int input is zero but not using the int input
    assign KillRes = CvtOp ? (CvtResUf|(XZeroM&~IntToFp)|(IntZeroM&IntToFp)) : FullResExp[`NE+1] | (((YInfM&~XInfM)|XZeroM)&DivOp);//Underflow & ~ResDenorm & (ResExp!=1);
    assign SelOfRes = Overflow|DivByZero|(InfIn&~(YInfM&DivOp));
    // output infinity with result sign if divide by zero
    if(`IEEE754) begin
        assign PostProcResM = XNaNM&~(IntToFp&CvtOp) ? XNaNRes :
                         YNaNM&~CvtOp ? YNaNRes :
                         ZNaNM&FmaOp ? ZNaNRes :
                         Invalid ? InvalidRes : 
                         SelOfRes ? OfRes :
                         KillRes ? UfRes :  
                         NormRes;
    end else begin
        assign PostProcResM = NaNIn|Invalid ? InvalidRes :
                         SelOfRes ? OfRes :
                         KillRes ? UfRes :  
                         NormRes;
    end

    ///////////////////////////////////////////////////////////////////////////////////////
    //
    //      |||||||||||   |||     |||   |||||||||||||
    //          |||       ||||||  |||        |||
    //          |||       ||| ||| |||        |||
    //          |||       |||  ||||||        |||
    //      |||||||||||   |||     |||        |||
    //
    ///////////////////////////////////////////////////////////////////////////////////////        

    // *** probably can optimize the negation
    // select the overflow integer res
    //      - negitive infinity and out of range negitive input
    //                 |  int  |  long  |
    //          signed | -2^31 | -2^63  |
    //        unsigned |   0   |    0   |
    //
    //      - positive infinity and out of range positive input and NaNs
    //                 |   int  |  long  |
    //          signed | 2^31-1 | 2^63-1 |
    //        unsigned | 2^32-1 | 2^64-1 |
    //
    //      other: 32 bit unsinged res should be sign extended as if it were a signed number
    assign OfIntRes = Signed ? XSgnM&~XNaNM ? Int64 ? {1'b1, {`XLEN-1{1'b0}}} : {{`XLEN-32{1'b1}}, 1'b1, {31{1'b0}}} : // signed negitive
                                              Int64 ? {1'b0, {`XLEN-1{1'b1}}} : {{`XLEN-32{1'b0}}, 1'b0, {31{1'b1}}} : // signed positive
                               XSgnM&~XNaNM ? {`XLEN{1'b0}} : // unsigned negitive
                                              {`XLEN{1'b1}};// unsigned positive


    // select the integer output
    //      - if the input is invalid (out of bounds NaN or Inf) then output overflow res
    //      - if the input underflows
    //          - if rounding and signed opperation and negitive input, output -1
    //          - otherwise output a rounded 0
    //      - otherwise output the normal res (trmined and sign extended if nessisary)
    assign FCvtIntResM = IntInvalid ?  OfIntRes :
			            CvtCalcExpM[`NE] ? XSgnM&Signed&Plus1 ? {{`XLEN{1'b1}}} : {{`XLEN-1{1'b0}}, Plus1} : //CalcExp has to come after invalid ***swap to actual mux at some point??
                        Int64 ? NegRes[`XLEN-1:0] : {{`XLEN-32{NegRes[31]}}, NegRes[31:0]};
endmodule