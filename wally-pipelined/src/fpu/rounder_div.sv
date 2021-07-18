//
// The rounder takes as inputs a 64-bit value to be rounded, A, the 
// exponent of the value to be rounded, the sign of the final result, Sign, 
// the precision of the results, P, and the two-bit rounding mode, rm. 
// It produces a rounded 52-bit result, Z, the exponent of the rounded 
// result, Z_exp, and a flag that indicates if the result was rounded,
// Inexact. The rounding mode has the following values.
//	rm		Modee
//      00 		round-to-nearest-even
//	01 		round-toward-zero
//      10 		round-toward-plus infinity
//      11  		round-toward-minus infinity
//

module rounder_div (Result, DenormIO, Flags, rm, P, OvEn, 
		    UnEn, exp_diff, sel_inv, Invalid, DenormIn, 
		    SignR, q1, qm1, qp1, q0, qm0, qp0, regr_out);

   input  [1:0]   rm;
   input          P;
   input          OvEn;
   input          UnEn;
   input [12:0]   exp_diff;
   input [2:0] 	  sel_inv;
   input	  Invalid;
   input	  DenormIn;
   input 	  SignR;
   
   input logic [63:0]  q1;
   input logic [63:0]  qm1;
   input logic [63:0]  qp1;
   input logic [63:0]  q0;
   input logic [63:0]  qm0;
   input logic [63:0]  qp0;   
   input logic [127:0] regr_out;
   
   output logic [63:0] Result;
   output logic        DenormIO;
   output logic [4:0]  Flags;
   
   supply1 	       vdd;
   supply0 	       vss;
   
   logic 	       Rsign;
   logic [10:0]        Rexp;
   logic [12:0]        Texp;
   logic [51:0]        Rmant;
   logic [63:0]        Tmant;
   logic [51:0]        Smant;   
   logic 	       Rzero;
   logic 	       Gdp, Gsp, G;
   logic 	       UnFlow_SP, UnFlow_DP, UnderFlow; 
   logic 	       OvFlow_SP, OvFlow_DP, OverFlow;		
   logic 	       Inexact;
   logic 	       Round_zero;
   logic 	       Infinite;
   logic 	       VeryLarge;
   logic 	       Largest;
   logic 	       Div0;      
   logic 	       Adj_exp;
   logic 	       Valid;
   logic 	       NaN;
   logic 	       Texp_l7z;
   logic 	       Texp_l7o;
   logic 	       OvCon;
   logic           zero_rem;
   logic [1:0] 	       mux_mant;
   logic 	       sign_rem;
   logic [63:0]        q, qm, qp;
   logic 	       exp_ovf, exp_ovfSP, exp_ovfDP;   

   // Remainder = 0?
   assign zero_rem = ~(|regr_out);
   // Remainder Sign
   assign sign_rem = ~regr_out[127];
   // choose correct Guard bit [1,2) or [0,1)
   assign Gdp = q1[63] ? q1[10] : q0[10];
   assign Gsp = q1[63] ? q1[39] : q0[39];
   assign G = P ? Gsp : Gdp;   
   // Selection of Rounding (from logic/switching)
   assign mux_mant[1] = (SignR&rm[1]&rm[0]&G) | (!SignR&rm[1]&!rm[0]&G) | 
			(!rm[1]&!rm[0]&G&!sign_rem) | 
			(SignR&rm[1]&rm[0]&!zero_rem&!sign_rem) | 
			(!SignR&rm[1]&!rm[0]&!zero_rem&!sign_rem);
   assign mux_mant[0] = (!SignR&rm[0]&!G&!zero_rem&sign_rem) | 
			(!rm[1]&rm[0]&!G&!zero_rem&sign_rem) | 
			(SignR&rm[1]&!rm[0]&!G&!zero_rem&sign_rem);
   
   // Which Q?
   mux2 #(64) mx1 (q0, q1, q1[63], q);
   mux2 #(64) mx2 (qm0, qm1, q1[63], qm);   
   mux2 #(64) mx3 (qp0, qp1, q1[63], qp);
   // Choose Q, Q+1, Q-1
   mux3 #(64) mx4 (q, qm, qp, mux_mant, Tmant);
   assign Smant = Tmant[62:11];
   // Compute the value of the exponent
   //   exponent is modified if we choose:
   //   1.) we choose any qm0, qp0, q0 (since we shift mant)
   //   2.) we choose qp and we overflow (for RU)
   assign exp_ovf = |{qp[62:40], (qp[39:11] & {29{~P}})};
   assign Texp = exp_diff - {{13{vss}}, ~q1[63]} + {{13{vss}}, mux_mant[1]&qp1[63]&~exp_ovf};
   
   // Overflow only occurs for double precision, if Texp[10] to Texp[0] are 
   // all ones. To encourage sharing with single precision overflow detection,
   // the lower 7 bits are tested separately. 
   assign Texp_l7o  = Texp[6]&Texp[5]&Texp[4]&Texp[3]&Texp[2]&Texp[1]&Texp[0];
   assign OvFlow_DP = (~Texp[12]&Texp[11]) | (Texp[10]&Texp[9]&Texp[8]&Texp[7]&Texp_l7o);

   // Overflow occurs for single precision if (Texp[10] is one)  and 
   // ((Texp[9] or Texp[8] or Texp[7]) is one) or (Texp[6] to Texp[0] 
   // are all ones. 
   assign OvFlow_SP = Texp[10]&(Texp[9]|Texp[8]|Texp[7]|Texp_l7o);

   // Underflow occurs for double precision if (Texp[11]/Texp[10] is one) or 
   // Texp[10] to Texp[0] are all zeros. 
   assign Texp_l7z  = ~Texp[6]&~Texp[5]&~Texp[4]&~Texp[3]&~Texp[2]&~Texp[1]&~Texp[0];
   assign UnFlow_DP = (Texp[12]&Texp[11]) | ~Texp[11]&~Texp[10]&~Texp[9]&~Texp[8]&~Texp[7]&Texp_l7z;
   
   // Underflow occurs for single precision if (Texp[10] is zero)  and 
   // (Texp[9] or Texp[8] or Texp[7]) is zero. 
   assign UnFlow_SP = ~Texp[10]&(~Texp[9]|~Texp[8]|~Texp[7]|Texp_l7z);
   
   // Set the overflow and underflow flags. They should not be set if
   // the input was infinite or NaN or the output of the adder is zero.
   // 00 = Valid
   // 10 = NaN
   assign Valid = (~sel_inv[2]&~sel_inv[1]&~sel_inv[0]);
   assign NaN = ~sel_inv[1]& sel_inv[0];
   assign UnderFlow = (P & UnFlow_SP | UnFlow_DP) & Valid;
   assign OverFlow  = (P & OvFlow_SP | OvFlow_DP) & Valid;
   assign Div0 = sel_inv[2]&sel_inv[1]&~sel_inv[0];

   // The DenormIO is set if underflow has occurred or if their was a
   // denormalized input. 
   assign DenormIO = DenormIn | UnderFlow;

   // The final result is Inexact if any rounding occurred ((i.e., R or S 
   // is one), or (if the result overflows ) or (if the result underflows and the 
   // underflow trap is not enabled)) and (value of the result was not previous set 
   // by an exception case). 
   assign Inexact = (G|~zero_rem|OverFlow|(UnderFlow&~UnEn))&Valid;

   // Set the IEEE Exception Flags: Inexact, Underflow, Overflow, Div_By_0, 
   // Invlalid. 
   assign Flags = {Inexact, UnderFlow, OverFlow, Div0, Invalid};

   // Determine sign
   assign Rzero = UnderFlow | (~sel_inv[2]&sel_inv[1]&sel_inv[0]);
   assign Rsign = SignR;   
      
   // The exponent of the final result is zero if the final result is 
   // zero or a denorm, all ones if the final result is NaN or Infinite
   // or overflow occurred and the magnitude of the number is 
   // not rounded toward from zero, and all ones with an LSB of zero
   // if overflow occurred and the magnitude of the number is 
   // rounded toward zero. If the result is single precision, 
   // Texp[7] shoud be inverted. When the Overflow trap is enabled (OvEn = 1)
   // and overflow occurs and the operation is not conversion, bits 10 and 9 are 
   // inverted for double precision, and bits 7 and 6 are inverted for single precision. 
   assign Round_zero = ~rm[1]&rm[0] | ~SignR&rm[0] | SignR&rm[1]&~rm[0];
   assign VeryLarge = OverFlow & ~OvEn;
   assign Infinite   = (VeryLarge & ~Round_zero) | sel_inv[1];
   assign Largest = VeryLarge & Round_zero;
   assign Adj_exp = OverFlow & OvEn;
   assign Rexp[10:1] = ({10{~Valid}} | 
			{Texp[10]&~Adj_exp, Texp[9]&~Adj_exp, Texp[8], 
			 (Texp[7]^P)&~(Adj_exp&P), Texp[6]&~(Adj_exp&P), Texp[5:1]} | 
		        {10{VeryLarge}})&{10{~Rzero | NaN}};
   assign Rexp[0]    = ({~Valid} | Texp[0] | Infinite)&(~Rzero | NaN)&~Largest;
   
   // If the result is zero or infinity, the mantissa is all zeros. 
   // If the result is NaN, the mantissa is 10...0
   // If the result the largest floating point number, the mantissa
   // is all ones. Otherwise, the mantissa is not changed. 
   assign Rmant[51] = Largest | NaN | (Smant[51]&~Infinite&~Rzero);
   assign Rmant[50:0] = {51{Largest}} | (Smant[50:0]&{51{~Infinite&Valid&~Rzero}});

   // For single precision, the 8 least significant bits of the exponent
   // and 23 most significant bits of the mantissa contain bits used 
   // for the final result. A double precision result is returned if 
   // overflow has occurred, the overflow trap is enabled, and a conversion
   // is being performed. 
   assign OvCon = OverFlow & OvEn;
   assign Result = (P&~OvCon) ? { {32{1'b1}}, Rsign, Rexp[7:0], Rmant[51:29]}
	           : {Rsign, Rexp, Rmant};

endmodule // rounder

