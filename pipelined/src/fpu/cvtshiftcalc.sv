`include "wally-config.vh"

module cvtshiftcalc(
    input logic                    XZeroM,
    input logic                    ToInt,
    input logic                    IntToFp,
    input logic  [`NE:0]           CvtCalcExpM,    // the calculated expoent
    input logic  [`NF:0]           XManM,          // input mantissas
    input logic     [`FMTBITS-1:0]  OutFmt,       // output format
    input logic  [`CVTLEN-1:0]      CvtLzcInM,      // input to the Leading Zero Counter (priority encoder)
    input logic CvtResDenormUfM,
    output logic CvtResUf,
    output logic [`CVTLEN+`NF:0]    CvtShiftIn    // number to be shifted
);
    logic [$clog2(`NF):0]	ResNegNF;   // the result's fraction length negated (-NF)


    ///////////////////////////////////////////////////////////////////////////
    // shifter
    ///////////////////////////////////////////////////////////////////////////

    // seclect the input to the shifter
    //      fp  -> int:
    //          |  `XLEN  zeros |     Mantissa      | 0's if nessisary |
    //          Other problems:
    //              - if shifting to the right (neg CalcExp) then don't a 1 in the round bit (to prevent an incorrect plus 1 later durring rounding)
    //              - we do however want to keep the one in the sticky bit so set one of bits in the sticky bit area to 1
    //                  - ex: for the case 0010000.... (double)
    //      ??? -> fp:
    //          - if result is denormalized or underflowed then we want to shift right i.e. shift right then shift left:
    //              |  `NF-1  zeros   |     Mantissa      | 0's if nessisary | 
    //          - otherwise:
    //              |     LzcInM      | 0's if nessisary | 
    assign CvtShiftIn = ToInt ? {{`XLEN{1'b0}}, XManM[`NF]&~CvtCalcExpM[`NE], XManM[`NF-1]|(CvtCalcExpM[`NE]&XManM[`NF]), XManM[`NF-2:0], {`CVTLEN-`XLEN{1'b0}}} : 
                     CvtResDenormUfM ? {{`NF-1{1'b0}}, XManM, {`CVTLEN-`NF+1{1'b0}}} : 
                                   {CvtLzcInM, {`NF+1{1'b0}}};
    
    
    // choose the negative of the fraction size
    if (`FPSIZES == 1) begin
        assign ResNegNF = -($clog2(`NF)+1)'(`NF); 

    end else if (`FPSIZES == 2) begin
        assign ResNegNF = OutFmt ? -($clog2(`NF)+1)'(`NF) : -($clog2(`NF)+1)'(`NF1);

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT:  ResNegNF = -($clog2(`NF)+1)'(`NF);
                `FMT1: ResNegNF = -($clog2(`NF)+1)'(`NF1);
                `FMT2: ResNegNF = -($clog2(`NF)+1)'(`NF2);
                default: ResNegNF = 1'bx;
            endcase

    end else if (`FPSIZES == 4) begin        
        always_comb
            case (OutFmt)
                2'h3: ResNegNF = -($clog2(`NF)+1)'(`Q_NF);
                2'h1: ResNegNF = -($clog2(`NF)+1)'(`D_NF);
                2'h0: ResNegNF = -($clog2(`NF)+1)'(`S_NF);
                2'h2: ResNegNF = -($clog2(`NF)+1)'(`H_NF);
            endcase
    end
    // determine if the result underflows ??? -> fp
    //      - if the first 1 is shifted out of the result then the result underflows
    //      - can't underflow an integer to fp conversions
    assign CvtResUf = ($signed(CvtCalcExpM) < $signed({{`NE-$clog2(`NF){1'b1}}, ResNegNF}))&~XZeroM&~IntToFp;
   
endmodule