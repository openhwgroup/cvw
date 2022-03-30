
`include "wally-config.vh"

// FOpCtrlE values
//    111   min
//    101   max
//    010   equal
//    001   less than
//    011   less than or equal


module fcmp (   
   input logic                FmtE,           // precision 1 = double 0 = single
   input logic  [2:0]         FOpCtrlE,       // see above table
   input logic                XSgnE, YSgnE,   // input signs
   input logic  [`NE-1:0]     XExpE, YExpE,   // input exponents
   input logic  [`NF:0]       XManE, YManE,   // input mantissa
   input logic                XZeroE, YZeroE, // is zero
   input logic                XNaNE, YNaNE,   // is NaN
   input logic                XSNaNE, YSNaNE, // is signaling NaN
   input logic  [`FLEN-1:0]   FSrcXE, FSrcYE, // original, non-converted to double, inputs
   output logic               CmpNVE,         // invalid flag
   output logic [`FLEN-1:0]   CmpResE         // compare resilt
   );

   logic LTabs, LT, EQ; // is X < or > or = Y
   logic BothZeroE, EitherNaNE, EitherSNaNE;
   
   assign LTabs= {1'b0, XExpE, XManE} < {1'b0, YExpE, YManE}; // unsigned comparison, treating FP as integers
   assign LT = (XSgnE & ~YSgnE) | (XSgnE & YSgnE & ~LTabs & ~EQ) | (~XSgnE & ~YSgnE & LTabs);
   //assign LT = $signed({XSgnE, XExpE, XManE[`NF-1:0]}) < $signed({YSgnE, YExpE, YManE[`NF-1:0]});
   //assign LT = XInt < YInt;
//   assign LT = XSgnE^YSgnE ? XSgnE : XExpE==YExpE ? ((XManE<YManE)^XSgnE)&~EQ : (XExpE<YExpE)^XSgnE;
   assign EQ = (FSrcXE == FSrcYE);

   assign BothZeroE = XZeroE&YZeroE;
   assign EitherNaNE = XNaNE|YNaNE;
   assign EitherSNaNE = XSNaNE|YSNaNE;


   // flags
   //    Min/Max - if an input is a signaling NaN set invalid flag
   //    LT/LE - signaling - sets invalid if NaN input
   //    EQ - quiet - sets invalid if signaling NaN input
   always_comb begin
      case (FOpCtrlE[2:0])
         3'b111: CmpNVE = EitherSNaNE;//min 
         3'b101: CmpNVE = EitherSNaNE;//max
         3'b010: CmpNVE = EitherSNaNE;//equal
         3'b001: CmpNVE = EitherNaNE;//less than
         3'b011: CmpNVE = EitherNaNE;//less than or equal
         default: CmpNVE = 1'b0;
      endcase
   end 

   // Min/Max
   //    - outputs the min/max of X and Y
   //    - -0 < 0
   //    - if both are NaN return quiet X
   //    - if one is a NaN output the non-NaN
   // LT/LE/EQ
   //    - -0 = 0
   //    - inf = inf and -inf = -inf
   //    - return 0 if comparison with NaN (unordered)

   logic [`FLEN-1:0] QNaN;
   // fmin/fmax of two NaNs returns a quiet NaN of the appropriate size
   // for IEEE, return the payload of X
   // for RISC-V, return the canonical NaN
   if(`IEEE754) assign QNaN = FmtE ? {XSgnE, XExpE, 1'b1, XManE[`NF-2:0]} : {{32{1'b1}}, XSgnE, XExpE[7:0], 1'b1, XManE[50:29]};
   else         assign QNaN = FmtE ? {1'b0, XExpE, 1'b1, 51'b0} : {{32{1'b1}}, 1'b0, XExpE[7:0], 1'b1, 22'b0};
 
   always_comb begin
      case (FOpCtrlE[2:0])
         3'b111: CmpResE = XNaNE ? YNaNE ? QNaN : FSrcYE // Min
                                 : YNaNE ? FSrcXE : LT ? FSrcXE : FSrcYE;
         3'b101: CmpResE = XNaNE ? YNaNE ? QNaN : FSrcYE // Max
                                 : YNaNE ? FSrcXE : LT ? FSrcYE : FSrcXE;
         3'b010: CmpResE = {63'b0, (EQ|BothZeroE) & ~EitherNaNE}; // Equal
         3'b001: CmpResE = {63'b0, LT & ~BothZeroE & ~EitherNaNE}; // Less than
         3'b011: CmpResE = {63'b0, (LT|EQ|BothZeroE) & ~EitherNaNE}; // Less than or equal
         default: CmpResE = 64'b0;
      endcase
   end 

   
endmodule
