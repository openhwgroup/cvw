///////////////////////////////////////////
//
// Written: James Stine
// Modified: 8/1/2018
//
// Purpose: Floating point divider/square root rounder unit (Goldschmidt)
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

module rounder_div (
    input logic [1:0] 	rm,
    input logic 	P,
    input logic 	OvEn,
    input logic 	UnEn,
    input logic [12:0] 	exp_diff,
    input logic [2:0] 	sel_inv,
    input logic 	Invalid,
    input logic 	SignR,
    input logic [63:0] 	Float1,
    input logic [63:0] 	Float2,
    input logic 	XNaNQ,
    input logic 	YNaNQ,
    input logic 	XZeroQ,
    input logic 	YZeroQ, 
    input logic 	XInfQ,
    input logic 	YInfQ,
    input logic 	op_type, 
    input logic [59:0] 	q1,
    input logic [59:0] 	qm1,
    input logic [59:0] 	qp1,
    input logic [59:0] 	q0,
    input logic [59:0] 	qm0,
    input logic [59:0] 	qp0, 
    input logic [119:0] regr_out,
   
    output logic [63:0] Result,
    output logic [4:0] 	Flags
    );
      
   logic 		Rsign;
   logic [10:0] 	Rexp;
   logic [12:0] 	Texp;
   logic [51:0] 	Rmant;
   logic [59:0] 	Tmant;
   logic [51:0] 	Smant;   
   logic 		Rzero;
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
   logic 	       zero_rem;
   logic [1:0] 	       mux_mant;
   logic 	       sign_rem;
   logic [59:0]        q, qm, qp;
   logic 	       exp_ovf;

   logic [50:0]        NaN_out;
   logic 	       NaN_Sign_out;   
   logic 	       Sign_out;     

   // Remainder = 0?
   assign zero_rem = ~(|regr_out);
   // Remainder Sign
   assign sign_rem = ~regr_out[119];
   // choose correct Guard bit [1,2) or [0,1)
   assign Gdp = q1[59] ? q1[6] : q0[6];
   assign Gsp = q1[59] ? q1[35] : q0[35];
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
   mux2 #(60) mx1 (q0, q1, q1[59], q);
   mux2 #(60) mx2 (qm0, qm1, q1[59], qm);   
   mux2 #(60) mx3 (qp0, qp1, q1[59], qp);
   // Choose Q, Q+1, Q-1
   mux3 #(60) mx4 (q, qm, qp, mux_mant, Tmant);
   assign Smant = Tmant[58:7];
   // Compute the value of the exponent
   //   exponent is modified if we choose:
   //   1.) we choose any qm0, qp0, q0 (since we shift mant)
   //   2.) we choose qp and we overflow (for RU)
   assign exp_ovf = |{qp[58:36], (qp[35:7] & {29{~P}})};
   assign Texp = exp_diff - {{12{1'b0}}, ~q1[59]} + {{12{1'b0}}, mux_mant[1]&qp1[59]&~exp_ovf};
   
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
   assign Valid = ~sel_inv[2]&~sel_inv[1]&~sel_inv[0];
   assign NaN = sel_inv[2]&sel_inv[1]&sel_inv[0]; 
   assign UnderFlow = (P & UnFlow_SP | UnFlow_DP) & Valid;
   assign OverFlow  = (P & OvFlow_SP | OvFlow_DP) & Valid;
   assign Div0 = YZeroQ&~XZeroQ&~op_type&~NaN;   

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
   assign NaN_out = ~XNaNQ&YNaNQ ? Float2[50:0] : Float1[50:0];
   assign NaN_Sign_out = ~XNaNQ&YNaNQ ? Float2[63] : Float1[63];
   assign Sign_out = (XZeroQ&YZeroQ | XInfQ&YInfQ)&~op_type | Rsign&~XNaNQ&~YNaNQ | 
   		     NaN_Sign_out&(XNaNQ|YNaNQ);
   // FIXME (jes) - Imperas gives sNaN a Sign=0 where x86 gives Sign=1
   // | Float1[63]&op_type;  (logic to fix this but removed for now)
   
   assign Rmant[51] = Largest | NaN | (Smant[51]&~Infinite&~Rzero);
   assign Rmant[50:0] = ({51{Largest}} | (Smant[50:0]&{51{~Infinite&Valid&~Rzero}}) |
			(NaN_out&{51{NaN}}))&({51{~(op_type&Float1[63]&~XZeroQ)}});
   
   // For single precision, the 8 least significant bits of the exponent
   // and 23 most significant bits of the mantissa contain bits used 
   // for the final result. A double precision result is returned if 
   // overflow has occurred, the overflow trap is enabled, and a conversion
   // is being performed. 
   assign OvCon = OverFlow & OvEn;
   assign Result = (P&~OvCon) ? { {32{1'b1}}, Sign_out, Rexp[7:0], Rmant[51:29]}
	           : {Sign_out, Rexp, Rmant};

endmodule // rounder

