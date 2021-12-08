
`include "wally-config.vh"
// `include "../../config/rv64icfd/wally-config.vh"
module fcvt (
	input logic             XSgnE,      // X's sign
    input logic [10:0]      XExpE,      // X's exponent
    input logic [52:0]      XManE,     // X's fraction
    input logic             XZeroE,     // is X zero
    input logic             XNaNE,      // is X NaN 
    input logic             XInfE,      // is X infinity
    input logic             XDenormE,   // is X denormalized
    input logic [10:0]      BiasE,      // bias - depends on precision (max exponent/2)
    input logic [`XLEN-1:0] ForwardedSrcAE,      // integer input
    input logic [2:0]       FOpCtrlE,   // chooses which instruction is done (full list below)
    input logic [2:0]       FrmE,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic             FmtE,       // precision 1 = double 0 = single
    output logic [63:0]     CvtResE,    // convert final result
    output logic [4:0]      CvtFlgE);   // convert flags {invalid, divide by zero, overflow, underflow, inexact}

    logic               ResSgn;         // FP result's sign
    logic [10:0]        ResExp,TmpExp;  // FP result's exponent
    logic [51:0]        ResFrac;        // FP result's fraction
    logic [5:0]         LZResP;         // lz output
    logic [7:0]         Bits;           // how many bits are in the integer result
    logic [7:0]         SubBits;        // subtract these bits from the exponent (FP result)
    logic [64+51:0]     ShiftedManTmp;  // Shifted mantissa
    logic [64+51:0]     ShiftVal;       // value being shifted (to int - XMan, to FP - |integer input|)
    logic [64+1:0]      ShiftedMan;     // shifted mantissa truncated
    logic [64:0]	    RoundedTmp;     // full size rounded result - in case of overfow
    logic [63:0]	    Rounded;        // rounded result
    logic [12:0]        ExpVal;         // unbiased X exponent
    logic [12:0]        ShiftCnt;       // how much is the mantissa shifted
	logic [64-1:0]      IntIn;          // trimed integer input
    logic [64-1:0]      PosInt;         // absolute value of the integer input
    logic [63:0]        CvtIntRes;      // interger result from the fp -> int instructions
    logic [63:0]        CvtFPRes;       // floating point result from the int -> fp instructions
    logic               Of, Uf;         // did the integer result underflow or overflow
    logic               Guard, Round, LSB, Sticky;  // bits used to determine rounding
    logic               Plus1,CalcPlus1;    // do you add one for rounding
    logic               SgnRes;             // sign of the floating point result
    logic               Res64, In64;        // is the result or input 64 bits
    logic               RoundMSB;           // most significant bit of the fraction
    logic               RoundSgn;           // sign of the rounded result

    // FOpCtrlE:
      //  fcvt.w.s  = 001
      //  fcvt.wu.s = 011
      //  fcvt.s.w  = 000
      //  fcvt.s.wu = 010
      //  fcvt.l.s  = 101
      //  fcvt.lu.s = 111
      //  fcvt.s.l  = 100
      //  fcvt.s.lu = 110
      //  fcvt.w.d  = 001 
      //  fcvt.wu.d = 011
      //  fcvt.d.w  = 000
      //  fcvt.d.wu = 010
      //  fcvt.l.d  = 101
      //  fcvt.lu.d = 111
      //  fcvt.d.l  = 100
      //  fcvt.d.lu = 110
      //  {long, unsigned, to int, from int}
   
    // calculate signals based off the input and output's size
    assign Res64 = (FOpCtrlE[0]&FOpCtrlE[2]) | (FmtE&~FOpCtrlE[0]);
    assign In64 =  (~FOpCtrlE[0]&FOpCtrlE[2]) | (FmtE&FOpCtrlE[0]);
    assign SubBits = In64 ? 8'd64 : 8'd32;
    assign Bits = Res64 ? 8'd64 : 8'd32;

    // calulate the unbiased exponent
    assign ExpVal = {1'b0,XExpE} - {1'b0,BiasE} + {12'b0, XDenormE};

////////////////////////////////////////////////////////

    // position the input in the most significant bits
    assign IntIn = FOpCtrlE[2] ? {ForwardedSrcAE, {64-`XLEN{1'b0}}} : {ForwardedSrcAE[31:0], 32'b0};
    // make the integer positive
    assign PosInt = IntIn[64-1]&~FOpCtrlE[1] ? -IntIn : IntIn;
    // determine the integer's sign
    assign ResSgn = ~FOpCtrlE[1] ? IntIn[64-1] : 1'b0;
    
	// Leading one detector
	logic [8:0]	i;
	always_comb begin
			i = 0;
			while (~PosInt[64-1-i] && i < `XLEN) i = i+1;  // search for leading one 
			LZResP = i[5:0]+1;    // compute shift count
	end

    // if no one was found set to zero otherwise calculate the exponent
    assign TmpExp = i==`XLEN ? 0 : FmtE ? 11'd1023 + {3'b0, SubBits} - {5'b0, LZResP} : 11'd127 + {3'b0, SubBits} - {5'b0, LZResP};




////////////////////////////////////////////


    // select the shift value and amount based on operation (to fp or int)
    assign ShiftCnt = FOpCtrlE[0] ? ExpVal : {7'b0, LZResP};
    assign ShiftVal = FOpCtrlE[0] ? {{64-1{1'b0}}, XManE} : {PosInt, 52'b0};

	// if shift = -1 then shift one bit right for gaurd bit (right shifting twice never rounds)
	// if the shift is negitive add a bit for sticky bit calculation
	// otherwise shift left
    assign ShiftedManTmp = &ShiftCnt ? {{64{1'b0}}, XManE[52:1]} : ShiftCnt[12] ? {{64+51{1'b0}}, ~XZeroE} : ShiftVal << ShiftCnt;

    // truncate the shifted mantissa
    assign ShiftedMan = ShiftedManTmp[64+51:50];

    // calculate sticky bit 
    //  - take into account the possible right shift from before
    //  - the sticky bit calculation covers three diffrent sizes depending on the opperation
    assign Sticky = |ShiftedManTmp[49:0] | &ShiftCnt&XManE[0] | (~FOpCtrlE[0]&|ShiftedManTmp[62:50]) | (~FOpCtrlE[0]&~FmtE&|ShiftedManTmp[91:63]);

    
    // determine guard, round, and least significant bit of the result
    assign Guard = FOpCtrlE[0] ? ShiftedMan[1] : FmtE ? ShiftedMan[13] : ShiftedMan[42];
    assign Round = FOpCtrlE[0] ? ShiftedMan[0] : FmtE ? ShiftedMan[12] : ShiftedMan[41];
    assign LSB = FOpCtrlE[0] ? ShiftedMan[2] : FmtE ? ShiftedMan[14] : ShiftedMan[43];

    always_comb begin
        // Determine if you add 1
        case (FrmE)
            3'b000: CalcPlus1 = Guard & (Round | Sticky | (~Round&~Sticky&LSB));//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = (XSgnE&FOpCtrlE[0]) | (ResSgn&~FOpCtrlE[0]);//round down
            3'b011: CalcPlus1 = (~XSgnE&FOpCtrlE[0]) | (~ResSgn&~FOpCtrlE[0]);//round up
            3'b100: CalcPlus1 = Guard & (Round | Sticky | (~Round&~Sticky));//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
    end

    // dont tound if the result is exact
    assign Plus1 = CalcPlus1 & (Guard|Round|Sticky)&~(XZeroE&FOpCtrlE[0]);

    // round the shifted mantissa
    assign RoundedTmp = ShiftedMan[64+1:2] + {64'b0, Plus1};
    assign {ResExp, ResFrac} = FmtE ? {TmpExp, ShiftedMan[64+1:14]} + {62'b0, Plus1} :  {{TmpExp, ShiftedMan[64+1:43]} + {33'b0,Plus1}, 29'b0} ;

    // fit the rounded result into the appropriate size and take the 2's complement if needed
     assign Rounded = Res64 ? XSgnE&FOpCtrlE[0] ? -RoundedTmp[63:0] : RoundedTmp[63:0] : 
			      XSgnE ? {{32{1'b1}}, -RoundedTmp[31:0]} : {32'b0, RoundedTmp[31:0]};

    // extract the MSB and Sign for later use (will be used to determine underflow and overflow)
     assign RoundMSB = Res64 ? RoundedTmp[64] : RoundedTmp[32];
     assign RoundSgn = Res64 ? Rounded[63] : Rounded[31];


    // check if the result overflows
    assign Of = (~XSgnE&($signed(ShiftCnt) >= $signed({{5{Bits[7]}}, Bits}))) | (~XSgnE&RoundSgn&~FOpCtrlE[1]) | (RoundMSB&(ShiftCnt==({{5{Bits[7]}}, Bits}-1))) | (~XSgnE&XInfE) | XNaNE;

    // check if the result underflows (this calculation changes if the result is signed or unsigned)
    assign Uf = FOpCtrlE[1] ? XSgnE&~XZeroE | (XSgnE&XInfE) | (XSgnE&~XZeroE&(~ShiftCnt[12]|CalcPlus1)) | (ShiftCnt[12]&Plus1) : (XSgnE&XInfE) | (XSgnE&($signed(ShiftCnt) >= $signed({{5{Bits[7]}}, Bits}))) | (XSgnE&~RoundSgn&~ShiftCnt[12]);    // assign CvtIntRes =  (XSgnE | ShiftCnt[12]) ? {64{1'b0}}  : (ShiftCnt >= 64) ? {64{1'b1}} : Rounded;
    
    // calculate the result's sign
    assign SgnRes = ~FOpCtrlE[2] & FOpCtrlE[0];

    // select the integer result
    assign CvtIntRes = Of ? FOpCtrlE[1] ? {64{1'b1}} : SgnRes ? {33'b0, {31{1'b1}}}: {1'b0, {63{1'b1}}} : 
                    Uf ? FOpCtrlE[1] ? 64'b0 : SgnRes ? {32'b0, 1'b1, 31'b0} : {1'b1, 63'b0} :
		            Rounded[64-1:0];

    // select the floating point result            
    assign CvtFPRes = FmtE ? {ResSgn, ResExp, ResFrac} : {{32{1'b1}}, ResSgn, ResExp[7:0], ResFrac[51:29]};

    // select the result
    assign CvtResE = ~FOpCtrlE[0] ? CvtFPRes : CvtIntRes;

    // calculate the flags
    //      - to int only sets the invalid flag
    //      - from int only sets the inexact flag
    assign CvtFlgE = {(Of | Uf)&FOpCtrlE[0], 3'b0, (Guard|Round|Sticky)&~FOpCtrlE[0]};




endmodule // fpadd


