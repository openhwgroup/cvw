
`include "wally-config.vh"

// FOpCtrlE values
//    110   min
//    101   max
//    010   equal
//    001   less than
//    011   less than or equal

module fcmp (   
   input logic  [`FMTBITS-1:0]   FmtE,           // precision 1 = double 0 = single
   input logic  [2:0]            FOpCtrlE,       // see above table
   input logic                   XSgnE, YSgnE,   // input signs
   input logic  [`NE-1:0]        XExpE, YExpE,   // input exponents
   input logic  [`NF:0]          XManE, YManE,   // input mantissa
   input logic                   XZeroE, YZeroE, // is zero
   input logic                   XNaNE, YNaNE,   // is NaN
   input logic                   XSNaNE, YSNaNE, // is signaling NaN
   input logic  [`FLEN-1:0]      FSrcXE, FSrcYE, // original, non-converted to double, inputs
   output logic                  CmpNVE,         // invalid flag
   output logic [`FLEN-1:0]      CmpFpResE,         // compare resilt
   output logic [`XLEN-1:0]      CmpIntResE         // compare resilt
   );

   logic LTabs, LT, EQ; // is X < or > or = Y
   logic [`FLEN-1:0] NaNRes;
   logic BothZero, EitherNaN, EitherSNaN;
   
   assign LTabs= {1'b0, XExpE, XManE} < {1'b0, YExpE, YManE}; // unsigned comparison, treating FP as integers
   assign LT = (XSgnE & ~YSgnE) | (XSgnE & YSgnE & ~LTabs & ~EQ) | (~XSgnE & ~YSgnE & LTabs);
   // assign LT = {~XSgnE, XExpE, XManE[`NF-1:0]} < {~YSgnE, YExpE, YManE[`NF-1:0]}; // *** James look at whether we can simplify to this, but it fails regression

   //assign LT = $signed({XSgnE, XExpE, XManE[`NF-1:0]}) < $signed({YSgnE, YExpE, YManE[`NF-1:0]});
   //assign LT = XInt < YInt;
//   assign LT = XSgnE^YSgnE ? XSgnE : XExpE==YExpE ? ((XManE<YManE)^XSgnE)&~EQ : (XExpE<YExpE)^XSgnE;
   assign EQ = (FSrcXE == FSrcYE);

   assign BothZero = XZeroE&YZeroE;
   assign EitherNaN = XNaNE|YNaNE;
   assign EitherSNaN = XSNaNE|YSNaNE;


   // flags
   //    Min/Max - if an input is a signaling NaN set invalid flag
   //    LT/LE - signaling - sets invalid if NaN input
   //    EQ - quiet - sets invalid if signaling NaN input
   always_comb begin
      case (FOpCtrlE[2:0])
         3'b110: CmpNVE = EitherSNaN;//min 
         3'b101: CmpNVE = EitherSNaN;//max
         3'b010: CmpNVE = EitherSNaN;//equal
         3'b001: CmpNVE = EitherNaN;//less than
         3'b011: CmpNVE = EitherNaN;//less than or equal
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

   // fmin/fmax of two NaNs returns a quiet NaN of the appropriate size
   // for IEEE, return the payload of X
   // for RISC-V, return the canonical NaN

   
   if (`FPSIZES == 1)
      if(`IEEE754) assign NaNRes = {XSgnE, {`NE{1'b1}}, 1'b1, XManE[`NF-2:0]};
      else         assign NaNRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};

   else if (`FPSIZES == 2) 
      if(`IEEE754) assign NaNRes = FmtE ? {XSgnE, {`NE{1'b1}}, 1'b1, XManE[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, XSgnE, {`NE1{1'b1}}, 1'b1, XManE[`NF-2:`NF-`NF1]};
      else         assign NaNRes = FmtE ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
   
   else if (`FPSIZES == 3)
      always_comb
            case (FmtE)
               `FMT:  
                  if(`IEEE754) NaNRes = {XSgnE, {`NE{1'b1}}, 1'b1, XManE[`NF-2:0]};
                  else         NaNRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
               `FMT1:
                  if(`IEEE754) NaNRes = {{`FLEN-`LEN1{1'b1}}, XSgnE, {`NE1{1'b1}}, 1'b1, XManE[`NF-2:`NF-`NF1]};
                  else         NaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
               `FMT2:
                  if(`IEEE754) NaNRes = {{`FLEN-`LEN2{1'b1}}, XSgnE, {`NE2{1'b1}}, 1'b1, XManE[`NF-2:`NF-`NF2]};
                  else         NaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
               default:        NaNRes = (`FLEN)'(0);
            endcase

   else if (`FPSIZES == 4)
      always_comb
            case (FmtE)
               2'h3:  
                  if(`IEEE754) NaNRes = {XSgnE, {`NE{1'b1}}, 1'b1, XManE[`NF-2:0]};
                  else         NaNRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
               2'h1:  
                  if(`IEEE754) NaNRes = {{`FLEN-`D_LEN{1'b1}}, XSgnE, {`D_NE{1'b1}}, 1'b1, XManE[`NF-2:`NF-`D_NF]};
                  else         NaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
               2'h0: 
                  if(`IEEE754) NaNRes = {{`FLEN-`S_LEN{1'b1}}, XSgnE, {`S_NE{1'b1}}, 1'b1, XManE[`NF-2:`NF-`S_NF]};
                  else         NaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
               2'h2:
                  if(`IEEE754) NaNRes = {{`FLEN-`H_LEN{1'b1}}, XSgnE, {`H_NE{1'b1}}, 1'b1, XManE[`NF-2:`NF-`H_NF]};
                  else         NaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
            endcase

 // when one input is a NaN -output the non-NaN
   assign CmpFpResE = FOpCtrlE[0] ? XNaNE ? YNaNE ? NaNRes : FSrcYE // Max
                                          : YNaNE ? FSrcXE : LT ? FSrcYE : FSrcXE : 
                                    XNaNE ? YNaNE ? NaNRes : FSrcYE // Min
                                          : YNaNE ? FSrcXE : LT ? FSrcXE : FSrcYE;
                                    

   assign CmpIntResE = {(`XLEN-1)'(0), (((EQ|BothZero)&FOpCtrlE[1])|(LT&FOpCtrlE[0]&~BothZero))&~EitherNaN};
   
endmodule
