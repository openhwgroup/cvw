
`include "wally-config.vh"
// largest length in IEU/FPU
`define LGLEN ((`NF<`XLEN) ? `XLEN : `NF)

module fcvt (
    input logic             XSgnE,          // input's sign
    input logic [`NE-1:0]   XExpE,          // input's exponent
    input logic [`NF:0]     XManE,          // input's fraction
    input logic [`XLEN-1:0] ForwardedSrcAE, // integer input - from IEU
    input logic [2:0]       FOpCtrlE,       // choose which opperation (look below for values)
    input logic             FWriteIntE,     // is fp->int (since it's writting to the integer register)
    input logic             XZeroE,         // is the input zero
    input logic             XDenormE,   // is the input denormalized
    input logic             XInfE,          // is the input infinity
    input logic             XNaNE,          // is the input a NaN
    input logic             XSNaNE,         // is the input a signaling NaN
    input logic [2:0]       FrmE,           // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic [`FPSIZES/3:0] FmtE,        // the input's precision (11=quad 01=double 00=single 10=half)
    output logic [`FLEN-1:0] CvtResE,       // the fp conversion result
    output logic [`XLEN-1:0] CvtIntResE,    // the int conversion result
    output logic [4:0]      CvtFlgE         // the conversion's flags
    );

    // OpCtrls:
    //  fp->fp conversions: {0, output precision} - only one of the operations writes to the int register
    //      half   - 10
    //      single - 00
    //      double - 01
    //      quad   - 11
    //  int<->fp conversions: {is int->fp?, is the integer 64-bit?, is the integer signed?}
    //                            bit 2              bit 1                   bit 0
    //      for example: signed long -> single floating point has the OpCode 101

    // (FF) fp  -> fp coversion signals
    // (IF) int -> fp coversion signals
    // (FI) fp  -> int coversion signals


    logic [`FPSIZES/3:0]    OutFmt;     // format of the output
    logic [`XLEN-1:0]       PosInt;     // the positive integer input
    logic [`XLEN-1:0]       TrimInt;    // integer trimmed to the correct size
    logic [`LGLEN-1:0]      LzcIn;      // input to the Leading Zero Counter (priority encoder)
    logic [`NE:0]           CalcExp;    // the calculated expoent
	logic [$clog2(`LGLEN+1)-1:0] ShiftAmt;  // how much to shift by
    logic [`LGLEN+`NF:0]    ShiftIn;    // number to be shifted
    logic                   ResDenormUf;// does the result underflow or is denormalized
    logic                   ResUf;      // does the result underflow
    logic [`LGLEN+`NF:0]    Shifted;    // the shifted result
    logic [`NE-2:0]         NewBias;    // the bias of the final result
    logic [$clog2(`NF):0]	ResNegNF;   // the result's fraction length negated (-NF)
    logic [`NE-1:0]	        OldExp;     // the old exponent
    logic                   ResSgn;     // the result's sign
    logic                   Sticky;     // sticky bit - for rounding
    logic                   Round;      // round bit - for rounding
    logic                   LSBFrac;    // the least significant bit of the fraction - for rounding
    logic                   CalcPlus1;  // the calculated plus 1
    logic                   Plus1;      // add one to the final result?
    logic [`FLEN-1:0]       ShiftedPlus1;   // plus one shifted to the proper position
    logic [`NE:0]           FullResExp; // the full result exponent (with the overflow bit) 
    logic [`NE-1:0]         ResExp;     // the result's exponent (trimmed to the correct size)
    logic [`NF-1:0]         ResFrac;    // the result's fraction
    logic [`XLEN+1:0]       NegRes;     // the negation of the result
    logic [`XLEN-1:0]       OfIntRes;   // the overflow result for integer output
    logic                   Overflow, Underflow, Inexact, Invalid; // flags
    logic                   IntInexact, FpInexact, IntInvalid, FpInvalid;   // flags for FP and int outputs
    logic [`NE-1:0]         MaxExp;         // the maximum exponent before overflow
    logic [1:0]             NegResMSBS;     // the negitive integer result's most significant bits
    logic [`FLEN-1:0]       NaNRes, InfRes, Res, UfRes; //various special results
    logic                   KillRes;    // kill the result?
    logic                   Signed;     // is the opperation with a signed integer?
    logic                   Int64;      // is the integer 64 bits?
    logic                   IntToFp;       // is the opperation an int->fp conversion?
    logic                   ToInt;      // is the opperation an fp->int conversion?
    logic [$clog2(`LGLEN+1)-1:0] ZeroCnt; // output from the LZC


    // seperate OpCtrl for code readability
    assign Signed = FOpCtrlE[0];
    assign Int64 =  FOpCtrlE[1];
    assign IntToFp =   FOpCtrlE[2];
    assign ToInt =  FWriteIntE;

    // choose the ouptut format depending on the opperation
    //      - fp -> fp: OpCtrl contains the percision of the output
    //      - int -> fp: FmtE contains the percision of the output
    if (`FPSIZES == 2) 
        assign OutFmt = IntToFp ? FmtE : (FOpCtrlE[1:0] == `FMT); 
    else if (`FPSIZES == 3 | `FPSIZES == 4) 
        assign OutFmt = IntToFp ? FmtE : FOpCtrlE[1:0]; 


    ///////////////////////////////////////////////////////////////////////////
    // negation
    ///////////////////////////////////////////////////////////////////////////
    // 1) negate the input if the input is a negitive singed integer
    // 2) trim the input to the proper size (kill the 32 most significant zeroes if needed)

    assign PosInt = ResSgn ? -ForwardedSrcAE : ForwardedSrcAE;
    assign TrimInt = {{`XLEN-32{Int64}}, {32{1'b1}}} & PosInt;

    ///////////////////////////////////////////////////////////////////////////
    // lzc 
    ///////////////////////////////////////////////////////////////////////////
    
    // choose the input to the leading zero counter i.e. priority encoder
    //             int -> fp : | positive integer | 00000... (if needed) | 
    //             fp  -> fp : | fraction         | 00000... (if needed) | 
    assign LzcIn = IntToFp ? {TrimInt, {`LGLEN-`XLEN{1'b0}}} :
                             {XManE[`NF-1:0], {`LGLEN-`NF{1'b0}}};
    
    lzc #(`LGLEN) lzc (.num(LzcIn), .ZeroCnt);


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
    //              |     lzcIn      | 0's if nessisary | 
    assign ShiftIn = ToInt ? {{`XLEN{1'b0}}, XManE[`NF]&~CalcExp[`NE], XManE[`NF-1]|(CalcExp[`NE]&XManE[`NF]), XManE[`NF-2:0], {`LGLEN-`XLEN{1'b0}}} : 
                     ResDenormUf ? {{`NF-1{1'b0}}, XManE, {`LGLEN-`NF+1{1'b0}}} : 
                                   {LzcIn, {`NF+1{1'b0}}};
// kill the shift if it's negitive
    // select the amount to shift by
    //      fp -> int: 
    //          - shift left by CalcExp - essentially shifting until the unbiased exponent = 0
    //              - don't shift if supposed to shift right (underflowed or denorm input)
    //      denormalized/undeflowed result fp -> fp:
    //          - shift left by NF-1+CalcExp - to shift till the biased expoenent is 0
    //      ??? -> fp: 
    //          - shift left by ZeroCnt+1 - to shift till the result is normalized
    //              - only shift fp -> fp if the intital value is denormalized
    //                  - this is a problem because the input to the lzc was the fraction rather than the mantissa
    //                  - rather have a few and-gates than an extra bit in the priority encoder??? *** is this true?
    assign ShiftAmt = ToInt ? CalcExp[$clog2(`LGLEN+1)-1:0]&{$clog2(`LGLEN+1){~CalcExp[`NE]}} :
                    ResDenormUf&~IntToFp ? ($clog2(`LGLEN+1))'(`NF-1)+CalcExp[$clog2(`LGLEN+1)-1:0] : 
                              (ZeroCnt+1)&{$clog2(`LGLEN+1){XDenormE|IntToFp}};
    
    // shift
    //      fp -> int: |  `XLEN  zeros |     Mantissa      | 0's if nessisary | << CalcExp
    //          process:
    //              - start - CalcExp = 1 + XExp - Largest Bias
    //                  |  `XLEN  zeros     |     Mantissa      | 0's if nessisary |
    //
    //              - shift left 1 (1)
    //                  | `XLEN-1 zeros |bit|     frac      | 0's if nessisary |
    //                                      . <- binary point
    //
    //              - shift left till unbiased exponent is 0 (XExp - Largest Bias)
    //                  |  0's |     Mantissa      |      0's if nessisary     |
    //                  |     keep          |
    //
    //      fp -> fp:
    //          - if result is denormalized or underflowed:
    //              |  `NF-1  zeros   |     Mantissa      | 0's if nessisary | << NF+CalcExp-1
    //          process:
    //             - start
    //                 |     mantissa      | 0's |
    //
    //             - shift right by NF-1 (NF-1)
    //                 |  `NF-1  zeros   |     mantissa      | 0's |
    //
    //             - shift left by CalcExp = XExp - Largest bias + new bias
    //                 |   0's  |     mantissa      |     0's      |
    //                 |       keep      |
    //
    //          - if the input is denormalized:
    //              |     lzcIn      | 0's if nessisary | << ZeroCnt+1
    //              - plus 1 to shift out the first 1
    //
    //      int -> fp: |     lzcIn      | 0's if nessisary | << ZeroCnt+1
    //              - plus 1 to shift out the first 1

    assign Shifted = ShiftIn << ShiftAmt;

    ///////////////////////////////////////////////////////////////////////////
    // exp calculations
    ///////////////////////////////////////////////////////////////////////////


    // *** possible optimizaations:
        //  - if subtracting exp by bias only the msb needs a full adder, the rest can be HA - dunno how to implement this for synth
        //  - Smaller exp -> Larger Exp can be calculated with: *** can use in Other units??? FMA??? insert this thing in later
        //          Exp if in range: {~Exp[SNE-1], Exp[SNE-2:0]}
        //          Exp in range if: Exp[SNE-1] = 1 & Exp[LNE-2:SNE] = 1111... & Exp[LNE-1] = 0 | Exp[SNE-1] = 0 & Exp[LNE-2:SNE] = 000... & Exp[LNE-1] = 1
        //                     i.e.: &Exp[LNE-2:SNE-1] xor Exp[LNE-1]
        //          Too big if:      Exp[LNE-1] = 1
        //          Too small if:    none of the above

    // Select the bias of the output
    //      fp -> int : select 1
    //      ??? -> fp : pick the new bias depending on the output format 
    if (`FPSIZES == 1) begin
        assign NewBias = ToInt ? (`NE-1)'(1) : (`NE-1)'(`BIAS); 

    end else if (`FPSIZES == 2) begin
        assign NewBias = ToInt ? (`NE-1)'(1) : OutFmt ? (`NE-1)'(`BIAS) : (`NE-1)'(`BIAS1); 

    end else if (`FPSIZES == 3) begin
        logic [`NE-2:0] NewBiasToFp;
        always_comb
            case (OutFmt)
                `FMT: NewBiasToFp =  (`NE-1)'(`BIAS);
                `FMT1: NewBiasToFp = (`NE-1)'(`BIAS1);
                `FMT2: NewBiasToFp = (`NE-1)'(`BIAS2);
                default: NewBiasToFp = 1'bx;
            endcase
        assign NewBias = ToInt ? (`NE-1)'(1) : NewBiasToFp; 

    end else if (`FPSIZES == 4) begin        
        logic [`NE-2:0] NewBiasToFp;
        always_comb
            case (OutFmt)
                2'h3: NewBiasToFp =  (`NE-1)'(`Q_BIAS);
                2'h1: NewBiasToFp =  (`NE-1)'(`D_BIAS);
                2'h0: NewBiasToFp =  (`NE-1)'(`S_BIAS);
                2'h2: NewBiasToFp =  (`NE-1)'(`H_BIAS);
            endcase
        assign NewBias = ToInt ? (`NE-1)'(1) : NewBiasToFp; 
    end
    // select the old exponent
    //      int -> fp : largest bias + XLEN
    //      fp -> ??? : XExp
    assign OldExp = IntToFp ? (`NE)'(`BIAS)+(`NE)'(`XLEN) : XExpE;
    
    // calculate CalcExp
    //      fp -> fp : 
    //          - XExp - Largest bias + new bias - (ZeroCnt+1)
    //                                          only do ^ if the input was denormalized
    //              - convert the expoenent to the final preciaion (Exp - oldBias + newBias)
    //              - correct the expoent when there is a normalization shift ( + ZeroCnt+1) 
    //      fp -> int : XExp - Largest Bias + 1 - (ZeroCnt+1)
    //          |  `XLEN  zeros |     Mantissa      | 0's if nessisary | << CalcExp
    //          process:
    //              - start
    //                  |  `XLEN  zeros     |     Mantissa      | 0's if nessisary |
    //
    //              - shift left 1 (1)
    //                  | `XLEN-1 zeros |bit|     frac      | 0's if nessisary |
    //                                      . <- binary point
    //
    //              - shift left till unbiased exponent is 0 (XExp - Largest Bias)
    //                  |  0's |     Mantissa      |      0's if nessisary     |
    //                  |     keep        |
    //
    //              - if the input is denormalized then we dont shift... so the  "- (ZeroCnt+1)" is just leftovers from other options
    //      int -> fp : largest bias +  XLEN - Largest bias + new bias - 1 - ZeroCnt = XLEN + NewBias - 1 - ZeroCnt
    //              Process:
    //                  - shifted right by XLEN (XLEN)
    //                  - shift left to normilize (-1-ZeroCnt)
    //                  - newBias to make the biased exponent
    //          
    assign CalcExp = {1'b0, OldExp} - (`NE+1)'(`BIAS) + {2'b0, NewBias} - {{`NE{1'b0}}, XDenormE|IntToFp} - {{`NE-$clog2(`LGLEN+1)+1{1'b0}}, (ZeroCnt&{$clog2(`LGLEN+1){XDenormE|IntToFp}})};
    // find if the result is dnormal or underflows
    //      - if Calculated expoenent is 0 or negitive (and the input/result is not exactaly 0)
    //      - can't underflow an integer to Fp conversion
    assign ResDenormUf = (~|CalcExp | CalcExp[`NE])&~XZeroE&~IntToFp;
    // choose the negative of the fraction size
    if (`FPSIZES == 1) begin
        assign ResNegNF = -`NF; 

    end else if (`FPSIZES == 2) begin
        assign ResNegNF = OutFmt ? -`NF : -`NF1;

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT:  ResNegNF = -`NF;
                `FMT1: ResNegNF = -`NF1;
                `FMT2: ResNegNF = -`NF2;
                default: ResNegNF = 1'bx;
            endcase

    end else if (`FPSIZES == 4) begin        
        always_comb
            case (OutFmt)
                2'h3: ResNegNF = -`Q_NF;
                2'h1: ResNegNF = -`D_NF;
                2'h0: ResNegNF = -`S_NF;
                2'h2: ResNegNF = -`H_NF;
            endcase
    end
    // determine if the result underflows ??? -> fp
    //      - if the first 1 is shifted out of the result then the result underflows
    //      - can't underflow an integer to fp conversions
    assign ResUf = ($signed(CalcExp) < $signed({{`NE-$clog2(`NF){1'b1}}, ResNegNF}))&~XZeroE&~IntToFp;

    
    ///////////////////////////////////////////////////////////////////////////
    // sign
    ///////////////////////////////////////////////////////////////////////////

    // determine the sign of the result
    //      - if int -> fp
    //          - if 64-bit : check the msb of the 64-bit integer input and if it's signed
    //          - if 32-bit : check the msb of the 32-bit integer input and if it's signed
    //      - otherwise: the floating point input's sign
    assign ResSgn = IntToFp ? Int64 ? ForwardedSrcAE[`XLEN-1]&Signed : ForwardedSrcAE[31]&Signed : XSgnE;

    ///////////////////////////////////////////////////////////////////////////
    // rounding
    ///////////////////////////////////////////////////////////////////////////

    // round to nearest even
    //      {Round, Sticky}
    //      0x - do nothing
    //      10 - tie - Plus1 if result is odd  (LSBNormSum = 1)
    //      11 - Plus1

    //  round to zero - do nothing

    //  round to -infinity - Plus1 if negative

    //  round to infinity - Plus1 if positive

    //  round to nearest max magnitude
    //      {Guard, Round, Sticky}
    //      0x - do nothing
    //      1x - Plus1
    // ResUf is used when a fp->fp result underflows but all the bits get shifted out, which leaves nothing for the sticky bit
    if (`FPSIZES == 1) begin
        assign Sticky = ToInt ? |Shifted[`LGLEN+`NF-`XLEN-1:0] : |Shifted[`LGLEN+`NF-`NF-1:0]|ResUf;
        assign Round =  ToInt ? Shifted[`LGLEN+`NF-`XLEN] : Shifted[`LGLEN+`NF-`NF];
        assign LSBFrac = ToInt ? Shifted[`LGLEN+`NF-`XLEN+1] : Shifted[`LGLEN+`NF-`NF+1];

    end else if (`FPSIZES == 2) begin    
        assign Sticky = ToInt ? |Shifted[`LGLEN+`NF-`XLEN-1:0] : 
                        (OutFmt ? |Shifted[`LGLEN+`NF-`NF-1:0] : |Shifted[`LGLEN+`NF-`NF1-1:0])|ResUf;
        assign Round =  ToInt ? Shifted[`LGLEN+`NF-`XLEN] : 
                        OutFmt ? Shifted[`LGLEN+`NF-`NF] : Shifted[`LGLEN+`NF-`NF1];
        assign LSBFrac = ToInt ? Shifted[`LGLEN+`NF-`XLEN+1] : 
                        OutFmt ? Shifted[`LGLEN+`NF-`NF+1] : Shifted[`LGLEN+`NF-`NF1+1];

    end else if (`FPSIZES == 3) begin
        logic ToFpSticky, ToFpRound, ToFpLSBFrac;
        always_comb
            case (OutFmt)
                `FMT:  begin 
                     ToFpSticky = |Shifted[`LGLEN+`NF-`NF-1:0];
                     ToFpRound =   Shifted[`LGLEN+`NF-`NF];
                     ToFpLSBFrac = Shifted[`LGLEN+`NF-`NF+1];
                end
                `FMT1:  begin 
                     ToFpSticky = |Shifted[`LGLEN+`NF-`NF1-1:0];
                     ToFpRound =   Shifted[`LGLEN+`NF-`NF1];
                     ToFpLSBFrac = Shifted[`LGLEN+`NF-`NF1+1];
                end
                `FMT2:  begin 
                     ToFpSticky = |Shifted[`LGLEN+`NF-`NF2-1:0];
                     ToFpRound =   Shifted[`LGLEN+`NF-`NF2];
                     ToFpLSBFrac = Shifted[`LGLEN+`NF-`NF2+1];
                end
                default:  begin 
                     ToFpSticky = 1'bx;
                     ToFpRound = 1'bx;
                     ToFpLSBFrac = 1'bx;
                end
            endcase
            assign Sticky = ToInt ? |Shifted[`LGLEN+`NF-`XLEN-1:0] : ToFpSticky|ResUf;
            assign Round =  ToInt ? Shifted[`LGLEN+`NF-`XLEN] : ToFpRound;
            assign LSBFrac = ToInt ? Shifted[`LGLEN+`NF-`XLEN+1] : ToFpLSBFrac;

    end else if (`FPSIZES == 4) begin        
        logic ToFpSticky, ToFpRound, ToFpLSBFrac;
        always_comb
            case (OutFmt)
                2'h3:  begin 
                     ToFpSticky = |Shifted[`LGLEN+`Q_NF-`Q_NF-1:0];
                     ToFpRound =   Shifted[`LGLEN+`Q_NF-`Q_NF];
                     ToFpLSBFrac = Shifted[`LGLEN+`Q_NF-`Q_NF+1];
                end
                2'h1:  begin 
                     ToFpSticky = |Shifted[`LGLEN+`Q_NF-`D_NF-1:0];
                     ToFpRound =   Shifted[`LGLEN+`Q_NF-`D_NF];
                     ToFpLSBFrac = Shifted[`LGLEN+`Q_NF-`D_NF+1];
                end
                2'h0:  begin 
                     ToFpSticky = |Shifted[`LGLEN+`Q_NF-`S_NF-1:0];
                     ToFpRound =   Shifted[`LGLEN+`Q_NF-`S_NF];
                     ToFpLSBFrac = Shifted[`LGLEN+`Q_NF-`S_NF+1];
                end
                2'h2:  begin 
                     ToFpSticky = |Shifted[`LGLEN+`Q_NF-`H_NF-1:0];
                     ToFpRound =   Shifted[`LGLEN+`Q_NF-`H_NF];
                     ToFpLSBFrac = Shifted[`LGLEN+`Q_NF-`H_NF+1];
                end
            endcase
            assign Sticky = ToInt ? |Shifted[`LGLEN+`NF-`XLEN-1:0] : ToFpSticky|ResUf;
            assign Round =  ToInt ? Shifted[`LGLEN+`NF-`XLEN] : ToFpRound;
            assign LSBFrac = ToInt ? Shifted[`LGLEN+`NF-`XLEN+1] : ToFpLSBFrac;
    end

    always_comb
        // Determine if you add 1
        case (FrmE)
            3'b000: CalcPlus1 = Round & (Sticky | LSBFrac);//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = ResSgn;//round down
            3'b011: CalcPlus1 = ~ResSgn;//round up
            3'b100: CalcPlus1 = Round;//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase

    // dont round if exact
    assign Plus1 = CalcPlus1&(Round|Sticky);

    // shift the 1 to the propper position for rounding
    //     - dont round it converting to integer
    if (`FPSIZES == 1) begin
        assign ShiftedPlus1 = {{`FLEN-1{1'b0}},Plus1&~ToInt};

    end else if (`FPSIZES == 2) begin
        assign ShiftedPlus1 = OutFmt ? {{`FLEN-1{1'b0}},Plus1&~ToInt} : {{`NE+`NF1{1'b0}}, Plus1&~ToInt, {`FLEN-`NE-`NF1-1{1'b0}}};

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT:  ShiftedPlus1 = {{`FLEN-1{1'b0}},Plus1&~ToInt};
                `FMT1: ShiftedPlus1 = {{`NE+`NF1{1'b0}}, Plus1&~ToInt, {`FLEN-`NE-`NF1-1{1'b0}}};
                `FMT2: ShiftedPlus1 = {{`NE+`NF2{1'b0}}, Plus1&~ToInt, {`FLEN-`NE-`NF2-1{1'b0}}};
                default: ShiftedPlus1 = 0;
            endcase

    end else if (`FPSIZES == 4) begin        
        always_comb
            case (OutFmt)
                2'h3: ShiftedPlus1 = {{`Q_LEN-1{1'b0}},Plus1&~ToInt};
                2'h1: ShiftedPlus1 = {{`Q_NE+`D_NF{1'b0}}, Plus1&~ToInt, {`Q_LEN-`Q_NE-`D_NF-1{1'b0}}};
                2'h0: ShiftedPlus1 = {{`Q_NE+`S_NF{1'b0}}, Plus1&~ToInt, {`Q_LEN-`Q_NE-`S_NF-1{1'b0}}};
                2'h2: ShiftedPlus1 = {{`Q_NE+`H_NF{1'b0}}, Plus1&~ToInt, {`Q_LEN-`Q_NE-`H_NF-1{1'b0}}};
            endcase
    end
    // kill calcExp if the result is denormalized
    assign {FullResExp, ResFrac} = {CalcExp&{`NE+1{~ResDenormUf}}, Shifted[`LGLEN+`NF:`LGLEN+`NF+1-`NF]} + ShiftedPlus1;
    // trim the result's expoent to size
    assign ResExp = FullResExp[`NE-1:0];
    ///////////////////////////////////////////////////////////////////////////
    // flags
    ///////////////////////////////////////////////////////////////////////////
    
    // calculate the flags

    // find the maximum exponent (the exponent and larger overflows)
    if (`FPSIZES == 1) begin
        assign MaxExp = ToInt ? Int64 ? 65 : 33 : {`NE{1'b1}};

    end else if (`FPSIZES == 2) begin    
        assign MaxExp = ToInt ? Int64 ? 65 : 33 :
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
            assign MaxExp = ToInt ? Int64 ? 65 : 33 : MaxExpFp;

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
            assign MaxExp = ToInt ? Int64 ? 65 : 33 : MaxExpFp;
    end

    //                 if the result exponent is larger then the maximum possible exponent
    //                 |                  and the exponent is positive
    //                 |                  |             and the input is not NaN or Infinity
    //                 |                  |             |
    assign Overflow = ((ResExp >= MaxExp)&~CalcExp[`NE]&(~(XNaNE|XInfE)|IntToFp));

    //                 if the result is denormalized or underflowed
    //                 |             and the result did not round into normal values
    //                 |             |                             and the result is not exact
    //                 |             |                             |              and the result isn't NaN
    //                 |             |                             |              |
    assign Underflow = ResDenormUf & ~(ResExp==1 & CalcExp == 0) & (Sticky|Round)&~(XNaNE);

    // we are using the IEEE convertToIntegerExact opperations (rather then the exact ones) which do singal the inexact flag
    //                  if there were bits thrown away
    //                  |            if overflowed or underflowed
    //                  |            |                    and if not a NaN
    //                  |            |                    |
    assign FpInexact = (Sticky|Round|Underflow|Overflow)&(~XNaNE|IntToFp);

    //                  if the result is too small to be represented and not 0
    //                  |                                     and if the result is not invalid (outside the integer bounds)
    //                  |                                     |
    assign IntInexact = ((CalcExp[`NE]&~XZeroE)|Sticky|Round)&~Invalid;

    // select the inexact flag to output
    assign Inexact = ToInt ? IntInexact : FpInexact;

    //                  if an input was a singaling NaN(and we're using a FP input)
    //                  |
    assign FpInvalid = (XSNaNE&~IntToFp);

    assign NegResMSBS = Signed ? Int64 ? NegRes[`XLEN:`XLEN-1] : NegRes[32:31] :
			              Int64 ? NegRes[`XLEN+1:`XLEN] : NegRes[33:32];
    //                  if the input is NaN or infinity
    //                  |           if the integer result overflows (out of range) 
    //                  |           |         if the input was negitive but ouputing to a unsigned number
    //                  |           |         |                    the result doesn't round to zero
    //                  |           |         |                    |               or the result rounds up out of bounds
    //                  |           |         |                    |                       and the result didn't underflow
    //                  |           |         |                    |                       |
    assign IntInvalid = XNaNE|XInfE|Overflow|((XSgnE&~Signed)&(~((CalcExp[`NE]|(~|CalcExp))&~Plus1)))|(NegResMSBS[1]^NegResMSBS[0]);
    //                                                                                                     |
    //                                                                                                     or when the positive result rounds up out of range
    // select the inexact flag to output
    assign Invalid = ToInt ? IntInvalid : FpInvalid;
    // pack the flags together
    //      - fp -> int does not set the overflow or underflow flags
    assign CvtFlgE = {Invalid, 1'b0, Overflow&~ToInt, Underflow&~ToInt, Inexact};


    ///////////////////////////////////////////////////////////////////////////
    // result selection
    ///////////////////////////////////////////////////////////////////////////

    // determine if you shoould kill the result
    //      - do so if the result underflows, is zero (the exp doesnt calculate correctly). or the integer input is 0
    //      - dont set to zero if fp input is zero but not using the fp input
    //      - dont set to zero if int input is zero but not using the int input
    assign KillRes = (ResUf|(XZeroE&~IntToFp)|(~|TrimInt&IntToFp));

    if (`FPSIZES == 1) begin        
        // IEEE sends a payload while Riscv says to send a canonical quiet NaN
        if(`IEEE754) begin
            assign NaNRes = {1'b0, {`NE+1{1'b1}}, XManE[`NF-2:0]};
        end else begin 
            assign NaNRes = {1'b0, {`NE+1{1'b1}}, {`NF-1{1'b0}}};
        end
        // determine the infinity result
        //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
        //      - otherwise: output infinity with the correct sign
        //      - kill the infinity singal if the input isn't fp
        assign InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}};

        // result for when the result is killed i.e. underflowes
        //      - output a rounded 0 with the correct sign
        assign UfRes = {ResSgn, (`FLEN-2)'(0), Plus1&FrmE[1]};

        // format the result - NaN box single precision (put 1's in the unused msbs)
        assign Res   = {ResSgn, ResExp, ResFrac};


    end else if (`FPSIZES == 2) begin
        // IEEE sends a payload while Riscv says to send a canonical quiet NaN
        if(`IEEE754) begin
            assign NaNRes = OutFmt ? {1'b0, {`NE+1{1'b1}}, XManE[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1+1{1'b1}}, XManE[`NF-2:`NF-`NF1]};
        end else begin 
            assign NaNRes = OutFmt ? {1'b0, {`NE+1{1'b1}}, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1+1{1'b1}}, {`NF1-1{1'b0}}};
        end
        // determine the infinity result
        //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
        //      - otherwise: output infinity with the correct sign
        //      - kill the infinity singal if the input isn't fp
        assign InfRes =  OutFmt ? (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                                        {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}} :
                                                 (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} :
                                                                                                                                        {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1{1'b1}}, (`NF1)'(0)};

        // result for when the result is killed i.e. underflowes
        //      - output a rounded 0 with the correct sign
        assign UfRes = OutFmt ? {ResSgn, (`FLEN-2)'(0), Plus1&FrmE[1]} : {{`FLEN-`LEN1{1'b1}}, ResSgn, (`LEN1-2)'(0), Plus1&FrmE[1]};

        // format the result - NaN box single precision (put 1's in the unused msbs)
        assign Res   = OutFmt ? {ResSgn, ResExp, ResFrac} : {{`FLEN-`LEN1{1'b1}}, ResSgn, ResExp[`NE1-1:0], ResFrac[`NF-1:`NF-`NF1]};

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT: begin
                    // IEEE sends a payload while Riscv says to send a canonical quiet NaN
                    if(`IEEE754) begin
                        NaNRes = {1'b0, {`NE+1{1'b1}}, XManE[`NF-2:0]};
                    end else begin 
                        NaNRes = {1'b0, {`NE+1{1'b1}}, {`NF-1{1'b0}}};
                    end
                    // determine the infinity result
                    //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
                    //      - otherwise: output infinity with the correct sign
                    //      - kill the infinity singal if the input isn't fp
                    InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}};

                    // result for when the result is killed i.e. underflowes
                    //      - output a rounded 0 with the correct sign
                    UfRes = {ResSgn, (`FLEN-2)'(0), Plus1&FrmE[1]};

                    // format the result - NaN box single precision (put 1's in the unused msbs)
                    Res = {ResSgn, ResExp, ResFrac};
                end
                `FMT1: begin
                    // IEEE sends a payload while Riscv says to send a canonical quiet NaN
                    if(`IEEE754) begin
                        NaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1+1{1'b1}}, XManE[`NF-2:`NF-`NF1]};
                    end else begin 
                        NaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1+1{1'b1}}, {`NF1-1{1'b0}}};
                    end
                    // determine the infinity result
                    //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
                    //      - otherwise: output infinity with the correct sign
                    //      - kill the infinity singal if the input isn't fp
                    InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} : {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1{1'b1}}, (`NF1)'(0)};

                    // result for when the result is killed i.e. underflowes
                    //      - output a rounded 0 with the correct sign
                    UfRes = {{`FLEN-`LEN1{1'b1}}, ResSgn, (`LEN1-2)'(0), Plus1&FrmE[1]};

                    // format the result - NaN box single precision (put 1's in the unused msbs)
                    Res = {{`FLEN-`LEN1{1'b1}}, ResSgn, ResExp[`NE1-1:0], ResFrac[`NF-1:`NF-`NF1]};
                end
                `FMT2: begin
                    // IEEE sends a payload while Riscv says to send a canonical quiet NaN
                    if(`IEEE754) begin
                        NaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2+1{1'b1}}, XManE[`NF-2:`NF-`NF2]};
                    end else begin 
                        NaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2+1{1'b1}}, {`NF2-1{1'b0}}};
                    end
                    // determine the infinity result
                    //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
                    //      - otherwise: output infinity with the correct sign
                    //      - kill the infinity singal if the input isn't fp
                    InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {{`FLEN-`LEN2{1'b1}}, ResSgn, {`NE2-1{1'b1}}, 1'b0, {`NF2{1'b1}}} : {{`FLEN-`LEN2{1'b1}}, ResSgn, {`NE2{1'b1}}, (`NF2)'(0)};

                    // result for when the result is killed i.e. underflowes
                    //      - output a rounded 0 with the correct sign
                    UfRes = {{`FLEN-`LEN2{1'b1}}, ResSgn, (`LEN2-2)'(0), Plus1&FrmE[1]};

                    // format the result - NaN box single precision (put 1's in the unused msbs)
                    Res = {{`FLEN-`LEN2{1'b1}}, ResSgn, ResExp[`NE2-1:0], ResFrac[`NF-1:`NF-`NF2]};
                end
                default: begin
                    NaNRes = 1'bx;
                    InfRes = 1'bx;
                    UfRes  = 1'bx;
                    Res    = 1'bx;
                end
            endcase
    end else if (`FPSIZES == 4) begin        
        always_comb
            case (OutFmt)
                2'h3: begin
                    // IEEE sends a payload while Riscv says to send a canonical quiet NaN
                    if(`IEEE754) begin
                        NaNRes = {1'b0, {`Q_NE+1{1'b1}}, XManE[`Q_NF-2:0]};
                    end else begin 
                        NaNRes = {1'b0, {`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}};
                    end
                    // determine the infinity result
                    //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
                    //      - otherwise: output infinity with the correct sign
                    //      - kill the infinity singal if the input isn't fp
                    InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {ResSgn, {`Q_NE-1{1'b1}}, 1'b0, {`Q_NF{1'b1}}} : {ResSgn, {`Q_NE{1'b1}}, {`Q_NF{1'b0}}};

                    // result for when the result is killed i.e. underflowes
                    //      - output a rounded 0 with the correct sign
                    UfRes = {ResSgn, (`Q_LEN-2)'(0), Plus1&FrmE[1]};

                    // format the result - NaN box single precision (put 1's in the unused msbs)
                    Res = {ResSgn, ResExp, ResFrac};
                end
                2'h1: begin
                    // IEEE sends a payload while Riscv says to send a canonical quiet NaN
                    if(`IEEE754) begin
                        NaNRes = {{`Q_LEN-`D_LEN{1'b1}}, 1'b0, {`D_NE+1{1'b1}}, XManE[`Q_NF-2:`Q_NF-`D_NF]};
                    end else begin 
                        NaNRes = {{`Q_LEN-`D_LEN{1'b1}}, 1'b0, {`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}};
                    end
                    // determine the infinity result
                    //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
                    //      - otherwise: output infinity with the correct sign
                    //      - kill the infinity singal if the input isn't fp
                    InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {{`Q_LEN-`D_LEN{1'b1}}, ResSgn, {`D_NE-1{1'b1}}, 1'b0, {`D_NF{1'b1}}} : {{`Q_LEN-`D_LEN{1'b1}}, ResSgn, {`D_NE{1'b1}}, (`D_NF)'(0)};

                    // result for when the result is killed i.e. underflowes
                    //      - output a rounded 0 with the correct sign
                    UfRes = {{`Q_LEN-`D_LEN{1'b1}}, ResSgn, (`D_LEN-2)'(0), Plus1&FrmE[1]};

                    // format the result - NaN box single precision (put 1's in the unused msbs)
                    Res = {{`Q_LEN-`D_LEN{1'b1}}, ResSgn, ResExp[`D_NE-1:0], ResFrac[`Q_NF-1:`Q_NF-`D_NF]};
                end
                2'h0: begin
                    // IEEE sends a payload while Riscv says to send a canonical quiet NaN
                    if(`IEEE754) begin
                        NaNRes = {{`Q_LEN-`S_LEN{1'b1}}, 1'b0, {`S_NE+1{1'b1}}, XManE[`Q_NF-2:`Q_NF-`S_NF]};
                    end else begin 
                        NaNRes = {{`Q_LEN-`S_LEN{1'b1}}, 1'b0, {`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}};
                    end
                    // determine the infinity result
                    //      - if the input was infinity or rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
                    //      - otherwise: output infinity with the correct sign
                    //      - kill the infinity singal if the input isn't fp
                    InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {{`Q_LEN-`S_LEN{1'b1}}, ResSgn, {`S_NE-1{1'b1}}, 1'b0, {`S_NF{1'b1}}} : {{`Q_LEN-`S_LEN{1'b1}}, ResSgn, {`S_NE{1'b1}}, (`S_NF)'(0)};

                    // result for when the result is killed i.e. underflowes
                    //      - output a rounded 0 with the correct sign
                    UfRes = {{`Q_LEN-`S_LEN{1'b1}}, ResSgn, (`S_LEN-2)'(0), Plus1&FrmE[1]};

                    // format the result - NaN box single precision (put 1's in the unused msbs)
                    Res = {{`Q_LEN-`S_LEN{1'b1}}, ResSgn, ResExp[`S_NE-1:0], ResFrac[`Q_NF-1:`Q_NF-`S_NF]};
                end
                2'h2: begin
                    // IEEE sends a payload while Riscv says to send a canonical quiet NaN
                    if(`IEEE754) begin
                        NaNRes = {{`Q_LEN-`H_LEN{1'b1}}, 1'b0, {`H_NE+1{1'b1}}, XManE[`Q_NF-2:`Q_NF-`H_NF]};
                    end else begin 
                        NaNRes = {{`Q_LEN-`H_LEN{1'b1}}, 1'b0, {`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}};
                    end
                    // determine the infinity result
                    //      - if the input overflows in rounding mode RZ, RU, RD (and not rounding the value) then output the maximum normalized floating point number with the correct sign
                    //      - otherwise: output infinity with the correct sign
                    //      - kill the infinity singal if the input isn't fp
                    InfRes = (~XInfE|IntToFp)&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {{`Q_LEN-`H_LEN{1'b1}}, ResSgn, {`H_NE-1{1'b1}}, 1'b0, {`H_NF{1'b1}}} : {{`Q_LEN-`H_LEN{1'b1}}, ResSgn, {`H_NE{1'b1}}, (`H_NF)'(0)};

                    // result for when the result is killed i.e. underflowes
                    //      - output a rounded 0 with the correct sign
                    UfRes = {{`Q_LEN-`H_LEN{1'b1}}, ResSgn, (`H_LEN-2)'(0), Plus1&FrmE[1]};

                    // format the result - NaN box single precision (put 1's in the unused msbs)
                    Res = {{`Q_LEN-`H_LEN{1'b1}}, ResSgn, ResExp[`H_NE-1:0], ResFrac[`Q_NF-1:`Q_NF-`H_NF]};
                end
            endcase
    end

    
    // choose the floating point result
    //      - if the input is NaN (and using the NaN input) output the NaN result
    //      - if the input is infinity or the output overflows
    //      - kill the InfE signal if the input isn't a floating point value
    //      - if killing the result output the underflow result
    //      - otherwise output the normal result
    assign CvtResE = XNaNE&~IntToFp ? NaNRes : 
                     (XInfE&~IntToFp)|Overflow ? InfRes :
                     KillRes ? UfRes :
                     Res;
    // *** probably can optimize the negation
    // select the overflow integer result
    //      - negitive infinity and out of range negitive input
    //                 |  int  |  long  |
    //          signed | -2^31 | -2^63  |
    //        unsigned |   0   |    0   |
    //
    //      - positive infinity and out of range negitive input and NaNs
    //                 |   int  |  long  |
    //          signed | 2^31-1 | 2^63-1 |
    //        unsigned | 2^32-1 | 2^64-1 |
    //
    //      other: 32 bit unsinged result should be sign extended as if it were a signed number
    assign OfIntRes = Signed ? XSgnE&~XNaNE ? Int64 ? {1'b1, {`XLEN-1{1'b0}}} : {{`XLEN-32{1'b1}}, 1'b1, {31{1'b0}}} : // signed negitive
                                              Int64 ? {1'b0, {`XLEN-1{1'b1}}} : {{`XLEN-32{1'b0}}, 1'b0, {31{1'b1}}} : // signed positive
                               XSgnE&~XNaNE ? {`XLEN{1'b0}} : // unsigned negitive
                                              {`XLEN{1'b1}};// unsigned positive
    
    // round and negate the positive result if needed
    assign NegRes = XSgnE ? -({2'b0, Shifted[`LGLEN+`NF:`LGLEN+`NF+1-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1}) : {2'b0, Shifted[`LGLEN+`NF:`LGLEN+`NF+1-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1};
    // select the integer output
    //      - if the input is invalid (out of bounds NaN or Inf) then output overflow result
    //      - if the input underflows
    //          - if rounding and signed opperation and negitive input, output -1
    //          - otherwise output a rounded 0
    //      - otherwise output the normal result (trmined and sign extended if nessisary)
    assign CvtIntResE = Invalid ?  OfIntRes :
			            CalcExp[`NE] ? XSgnE&Signed&Plus1 ? {{`XLEN{1'b1}}} : {{`XLEN-1{1'b0}}, Plus1} : //CalcExp has to come after invalid ***swap to actual mux at some point??
                        Int64 ? NegRes[`XLEN-1:0] : {{`XLEN-32{NegRes[31]}}, NegRes[31:0]};

endmodule