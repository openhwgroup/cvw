
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
    input logic             XOrigDenormE,   // is the input denormalized
    input logic             XInfE,          // is the input infinity
    input logic             XNaNE,          // is the input a NaN
    input logic             XSNaNE,         // is the input a signaling NaN
    input logic [2:0]       FrmE,           // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic [`FPSIZES/3:0] FmtE,        // the input's precision (11=quad 01=double 00=single 10=half)
    output logic [`FLEN-1:0] CvtResE,       // the fp to fp conversion's result
    output logic [`XLEN-1:0] CvtIntResE,    // the fp to fp conversion's result
    output logic [4:0]      CvtFlgE         // the fp to fp conversion's flags
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
    logic [`LGLEN-1:0]      LzcIn;      // input to the Leading Zero Counter (priority encoder)
    logic [`NE:0]           CalcExp;    // the calculated expoent
	logic [$clog2(`LGLEN):0] ShiftAmt;  // how much to shift by
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


    // seperate OpCtrl for code readability
    assign Signed = FOpCtrlE[0];
    assign Int64 =  FOpCtrlE[1];
    assign IntToFp =   FOpCtrlE[2];
    assign ToInt =  FWriteIntE;

    // choose the ouptut format depending on the opperation
    //      - fp -> fp: OpCtrl contains the percision of the output
    //      - int -> fp: FmtE contains the percision of the output
    assign OutFmt = IntToFp ? FmtE : (FOpCtrlE[1:0] == `FMT);

    ///////////////////////////////////////////////////////////////////////////
    // negation
    ///////////////////////////////////////////////////////////////////////////
    // negate the input if the input is a negitive singed integer
    //      - remove leading ones if the input is a unsigned 32-bit integer
    //
    //              Negitive input
    //                      64-bit input : negate the input
    //                      32-bit input : trim to 32-bits and negate the input
    //              Positive input
    //                      64-bit input : do nothing
    //                      32-bit input : trim to 32-bits

    assign PosInt = ResSgn ? Int64 ? -ForwardedSrcAE : {{`XLEN-32{1'b0}}, -ForwardedSrcAE[31:0]} : 
                             Int64 ? ForwardedSrcAE : {{`XLEN-32{1'b0}}, ForwardedSrcAE[31:0]};

    ///////////////////////////////////////////////////////////////////////////
    // lzc 
    ///////////////////////////////////////////////////////////////////////////
    
    // choose the input to the leading zero counter i.e. priority encoder
    //             int -> fp : | positive integer | 00000... (if needed) | 
    //             fp  -> fp : | fraction         | 00000... (if needed) | 
    assign LzcIn = IntToFp ? {PosInt, {`LGLEN-`XLEN{1'b0}}} :      // I->F
                          {XManE[`NF-1:0], {`LGLEN-`NF{1'b0}}}; // F->F
    
    // lglen is the largest possible value of ZeroCnt (NF or XLEN) hence normcnt must be log2(lglen) bits
	logic [$clog2(`LGLEN):0]	i, ZeroCnt;
	always_comb begin
			i = 0;
			while (~LzcIn[`LGLEN-1-i] & i <= `LGLEN-1) i = i+1;  // search for leading one 
			ZeroCnt = i;
	end


    ///////////////////////////////////////////////////////////////////////////
    // shifter
    ///////////////////////////////////////////////////////////////////////////
    // F->F shift so the fraction is not denormalized
    //      Large->Small Denrom -> Norm Frac:
    //
    //              |    Frac    | `NF zeros| << ShiftCnt
    //
    //      Small->Large Norm -> Denorm Frac:
    //              - shift right so that the new-bias exponet = 1
    //              - so shift right by new-bias - 1 exponent
    //              - ie shift left by NF - 1 + new-bias exponent (if this is negitive then 0 is selected as a result later)
    //                  - new-bias exponent is negitive
    //
    //             |  `NF-1 zeros |1|    Frac    | << NF + new-bias exponent
    //             |      keep      |
    //
    // Int -> Fp : 
    //             |    Int    | `NF zeros| << ShiftCnt
    // Fp -> Int : 
    //             |  `XLEN  zeros |     Man      | << CalcExp


    // seclect the input to the shifter
    //      fp  -> int:
    //          |  `XLEN  zeros |     Mantissa      | 0's if nessisary |
    //          Other problems:
    //              - if shifting to the right (neg CalcExp) then don't a 1 in the round bit (to prevent an incorrect plus 1 later durring rounding)
    //              - we do however want to keep the one in the sticky bit so set one of bits in the sticky bit area to 1
    //                  - ex: for the case 0010000.... (double)
    //      ??? -> fp:
    //          - if result is denormalized or underflowed then we want to normalize the result:
    //              |  `NF  zeros   |     Mantissa      | 0's if nessisary | 
    //          - otherwise:
    //              |     lzcIn      | 0's if nessisary | 
    assign ShiftIn = ToInt ? {{`XLEN{1'b0}}, XManE[`NF]&~CalcExp[`NE], XManE[`NF-1]|(CalcExp[`NE]&XManE[`NF]), XManE[`NF-2:0], {`LGLEN-`XLEN{1'b0}}} : 
                     ResDenormUf ? {{`NF-1{1'b0}}, XManE, {`LGLEN-`NF+1{1'b0}}} : {LzcIn, {`NF+1{1'b0}}};
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
    assign ShiftAmt = ToInt ? CalcExp[$clog2(`LGLEN):0]&{$clog2(`LGLEN)+1{~CalcExp[`NE]}} :
                    ResDenormUf&~IntToFp ? ($clog2(`LGLEN)+1)'(`NF-1)+CalcExp[$clog2(`LGLEN):0] : (ZeroCnt+1)&{$clog2(`LGLEN)+1{XOrigDenormE|IntToFp}};
    
    // shift
    assign Shifted = ShiftIn << ShiftAmt;

    ///////////////////////////////////////////////////////////////////////////
    // exp calculations
    ///////////////////////////////////////////////////////////////////////////
    //  fp -> int
    //      CalcExp = 1 - largest bias + 1 - 


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

    assign NewBias = ToInt ? (`NE-1)'(1) : OutFmt ? (`NE-1)'(`BIAS) : (`NE-1)'(`BIAS1); 

    // select the old exponent
    //      int -> fp : largest bias + XLEN
    //      fp -> ??? : XExp
    assign OldExp = IntToFp ? (`NE)'(`BIAS)+(`NE)'(`XLEN) : XExpE;
    
    // calculate CalcExp
    //      fp -> fp : 
    //          - XExp - Largest bias + new bias
    //      fp -> int : XExp
    //      int -> fp : largest bias + XLEN
    // the -XOrigDenorm is to take into account the correction (which had a plus 1)
    assign CalcExp = {1'b0, OldExp} - (`NE+1)'(`BIAS) + {2'b0, NewBias} - {{`NE{1'b0}}, XOrigDenormE|IntToFp} - {{`NE-$clog2(`LGLEN){1'b0}}, (ZeroCnt&{$clog2(`LGLEN)+1{XOrigDenormE|IntToFp}})};
    // if result is 0 or negitive
    assign ResDenormUf = (~|CalcExp | CalcExp[`NE])&~XZeroE;
    assign ResNegNF = (FOpCtrlE[1:0] == `FMT) ? -`NF : -`NF1;
    // if the reuslt underflows and somthing is shifted out set the sticky bit
    assign ResUf = ($signed(CalcExp) < $signed({{`NE-$clog2(`NF){1'b1}}, ResNegNF}))&~XZeroE;

    
    ///////////////////////////////////////////////////////////////////////////
    // sign
    ///////////////////////////////////////////////////////////////////////////

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

    // ResUf is used when a fp->fp result underflows but all the bits get shifted out, leaving nothing for the sticky bit
    assign Sticky = ToInt ? |Shifted[`LGLEN+`NF-`XLEN-1:0] : 
                    (OutFmt ? |Shifted[`LGLEN+`NF-`NF-1:0] : |Shifted[`LGLEN+`NF-`NF1-1:0])|ResUf;
    assign Round =  ToInt ? Shifted[`LGLEN+`NF-`XLEN] : 
                    OutFmt ? Shifted[`LGLEN+`NF-`NF] : |Shifted[`LGLEN+`NF-`NF1];
    assign LSBFrac = ToInt ? Shifted[`LGLEN+`NF-`XLEN+1] : 
                    OutFmt ? Shifted[`LGLEN+`NF-`NF+1] : Shifted[`LGLEN+`NF-`NF1+1];


    always_comb begin // ***remove guard bit
        // Determine if you add 1
        case (FrmE)
            3'b000: CalcPlus1 = Round & (Sticky | LSBFrac);//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = ResSgn;//round down
            3'b011: CalcPlus1 = ~ResSgn;//round up
            3'b100: CalcPlus1 = Round;//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
    end
    assign Plus1 = CalcPlus1&(Round|Sticky);
    assign ShiftedPlus1 = OutFmt ? {{`FLEN-1{1'b0}},Plus1} : {{`NE+`NF1{1'b0}}, Plus1, {`FLEN-`NE-`NF1-1{1'b0}}};

    // kill calcExp if the result is denormalized
    assign {FullResExp, ResFrac} = {CalcExp&{`NE+1{~ResDenormUf}}, Shifted[`LGLEN+`NF:`LGLEN+`NF+1-`NF]} + ShiftedPlus1;
    assign ResExp = FullResExp[`NE-1:0];
    ///////////////////////////////////////////////////////////////////////////
    // flags
    ///////////////////////////////////////////////////////////////////////////
    
    // calculate the flags
    // dont set underflow overflow or inexact flags if result is NaN
    assign MaxExp = ToInt ? Int64 ? 65 : 33 :
			OutFmt ? {`NE{1'b1}} : {{`NE-`NE1{1'b0}}, {`NE1{1'b1}}};
    // if the exponent is lager or equal to the maximum and it's not negitive
    // F->F if the input is inf then the output is also Inf ie exact, so dont set the underflow flag

    //                 if the result exponent is larger then the maximum possible exponent
    //                 |                  and the exponent is positive
    //                 |                  |             and the input is not NaN or Infinity
    //                 |                  |             |
    assign Overflow = ((ResExp >= MaxExp)&~CalcExp[`NE]&~(XNaNE|XInfE));
    // only set the underflow flag if not-exact
    // set the underflow flag if the result is denomal or underflowed
    // can't underflow durring to integer conversions

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
    assign Inexact = ToInt ? IntInexact : FpInexact;
    //                  if an input was a singaling NaN(and we're using a FP input)
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
    assign Invalid = ToInt ? IntInvalid : FpInvalid;
    // pack the flags together and choose the result based on the opperation
    // don't set the overflow or underfolw flags if converting to integer
    assign CvtFlgE = {Invalid, 1'b0, Overflow&~ToInt, Underflow&~ToInt, Inexact};


    ///////////////////////////////////////////////////////////////////////////
    // result selection
    ///////////////////////////////////////////////////////////////////////////
    // when the input is zero for F->F the exponent is not calulated as 0 so combine with underflow result

    //logic [$clog2(`NF)-1:0] MinDenormExp;
    //assign MinDenormExp = FOpCtrlE[1:0] == `FMT ? -`NE : -`NE1;
    assign KillRes = (ResUf|(XZeroE&~IntToFp)|(~|PosInt&IntToFp));
    //assign NaNRes = FOpCtrlE[1:0] == `FMT ? {1'b0, {`NE+1{1'b1}}, (`NF-1)'(0)} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
    
    if(`IEEE754) begin
        assign NaNRes = FOpCtrlE[1:0] == `FMT ? {1'b0, {`NE+1{1'b1}}, XManE[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1+1{1'b1}}, XManE[`NF-2:`NF-`NF1]};
    end else begin 
        assign NaNRes = FOpCtrlE[1:0] == `FMT ? {1'b0, {`NE+1{1'b1}}, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1+1{1'b1}}, {`NF1-1{1'b0}}};
    end
    // assign InfRes = FOpCtrlE[1:0] == `FMT ? {ResSgn, {`NE{1'b1}}, (`NF)'(0)} : {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1{1'b1}}, (`NF1)'(0)}; 
// output one less then the maximum value if rounding down (RZ RU RD)
// if infinitiy output infinity 
    assign InfRes =  FOpCtrlE[1:0] == `FMT ? ~XInfE&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {ResSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                            {ResSgn, {`NE{1'b1}}, {`NF{1'b0}}} :
                                        ~XInfE&((FrmE[1:0]==2'b01) | (FrmE[1:0]==2'b10&~ResSgn) | (FrmE[1:0]==2'b11&ResSgn)) ? {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} :
                                                                                                                            {{`FLEN-`LEN1{1'b1}}, ResSgn, {`NE1{1'b1}}, (`NF1)'(0)};
// if RU/RD then round the underflowed result if needed 
// integer zero's exponent is not calculated corresctly so go through underflow result  
    assign UfRes = OutFmt ? {ResSgn, (`FLEN-2)'(0), Plus1&FrmE[1]} : {{`FLEN-`LEN1{1'b1}}, ResSgn, (`LEN1-2)'(0), Plus1&FrmE[1]};
    assign Res    = OutFmt ? {ResSgn, ResExp, ResFrac} : {{`FLEN-`LEN1{1'b1}}, ResSgn, ResExp[`NE1-1:0], ResFrac[`NF-1:`NF-`NF1]};
    assign CvtResE = XNaNE&~IntToFp ? NaNRes : 
                     (XInfE|Overflow)&~IntToFp ? InfRes :
                     KillRes ? UfRes :
                     Res;
    // *** probably can optimize the negation
    // NaNs sould ouput the same as a positive infinity
    // a 32bit unsigend result should be sign extended (as if it is not a unsigned number)
    assign OfIntRes = Signed ? XSgnE&~XNaNE ? Int64 ? {1'b1, {`XLEN-1{1'b0}}} : {{`XLEN-32{1'b1}}, 1'b1, {31{1'b0}}} : // signed negitive
                                            Int64 ? {1'b0, {`XLEN-1{1'b1}}} : {{`XLEN-32{1'b0}}, 1'b0, {31{1'b1}}} : // signed positive
                                    XSgnE&~XNaNE ? {`XLEN{1'b0}} : // unsigned negitive
                                            {`XLEN{1'b1}};// unsigned positive
    
    
    assign NegRes = XSgnE ? -({2'b0, Shifted[`LGLEN+`NF:`LGLEN+`NF+1-`XLEN]}+{{`XLEN+1{1'b0}},Plus1}) : {2'b0, Shifted[`LGLEN+`NF:`LGLEN+`NF+1-`XLEN]}+{{`XLEN+1{1'b0}},Plus1};
    assign CvtIntResE = Invalid ?  OfIntRes :
			CalcExp[`NE] ? XSgnE&Signed&Plus1 ? {{`XLEN{1'b1}}} : {{`XLEN-1{1'b0}}, Plus1} : //CalcExp has to come after invalid ***swap to actual mux at some point??
            Int64 ? NegRes[`XLEN-1:0] : {{`XLEN-32{NegRes[31]}}, NegRes[31:0]};

endmodule