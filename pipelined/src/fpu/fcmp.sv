
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

   logic LT, EQ; // is X < or > or = Y

   // X is less than Y:
   //    Signs:
   //       X      Y    answer
   //      pos    pos    idk - keep checking
   //      pos    neg    no
   //      neg    pos    yes
   //      neg    neg    idk - keep checking
   //    Exponent 
   //       - if XExp < YExp
   //             - if negitive - no
   //             - if positive - yes
   //       - otherwise keep checking
   //    Mantissa
   //       - XMan < YMan then
   //             - if negitive - no
   //             - if positive - yes
   // note: LT does -0 < 0
   assign LT = XSgnE^YSgnE ? XSgnE : XExpE==YExpE ? ((XManE<YManE)^XSgnE)&~EQ : (XExpE<YExpE)^XSgnE;
   assign EQ = (FSrcXE == FSrcYE);

   // flags
   //    Min/Max - if an input is a signaling NaN set invalid flag
   //    LT/LE - signaling - sets invalid if NaN input
   //    EQ - quiet - sets invalid if signaling NaN input
   always_comb begin
      case (FOpCtrlE[2:0])
         3'b111: CmpNVE = XSNaNE|YSNaNE;//min 
         3'b101: CmpNVE = XSNaNE|YSNaNE;//max
         3'b010: CmpNVE = XSNaNE|YSNaNE;//equal
         3'b001: CmpNVE = XNaNE|YNaNE;//less than
         3'b011: CmpNVE = XNaNE|YNaNE;//less than or equal
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

   logic [`FLEN-1:0] QNaNX, QNaNY;
    if(`IEEE754) begin
        assign QNaNX = FmtE ? {XSgnE, XExpE, 1'b1, XManE[`NF-2:0]} : {{32{1'b1}}, XSgnE, XExpE[7:0], 1'b1, XManE[50:29]};
        assign QNaNY = FmtE ? {YSgnE, YExpE, 1'b1, YManE[`NF-2:0]} : {{32{1'b1}}, YSgnE, YExpE[7:0], 1'b1, YManE[50:29]};
    end else begin
        assign QNaNX = FmtE ? {1'b0, XExpE, 1'b1, 51'b0} : {{32{1'b1}}, 1'b0, XExpE[7:0], 1'b1, 22'b0};
        assign QNaNY = FmtE ? {1'b0, YExpE, 1'b1, 51'b0} : {{32{1'b1}}, 1'b0, YExpE[7:0], 1'b1, 22'b0};
    end
 
   always_comb begin
      case (FOpCtrlE[2:0])
         3'b111: CmpResE = XNaNE ? YNaNE ? QNaNX : FSrcYE // Min
                                 : YNaNE ? FSrcXE : LT ? FSrcXE : FSrcYE;
         3'b101: CmpResE = XNaNE ? YNaNE ? QNaNX : FSrcYE // Max
                                 : YNaNE ? FSrcXE : LT ? FSrcYE : FSrcXE;
         3'b010: CmpResE = {63'b0, (EQ|(XZeroE&YZeroE))&~(XNaNE|YNaNE)}; // Equal
         3'b001: CmpResE = {63'b0, LT&~(XZeroE&YZeroE)&~(XNaNE|YNaNE)}; // Less than
         3'b011: CmpResE = {63'b0, (LT|EQ|(XZeroE&YZeroE))&~(XNaNE|YNaNE)}; // Less than or equal
         default: CmpResE = 64'b0;
      endcase
   end 

   
endmodule
