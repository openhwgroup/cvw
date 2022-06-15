///////////////////////////////////////////
// intdiv.sv
//
// Written: James.Stine@okstate.edu 1 February 2021
// Modified: 
//
// Purpose: Integer Divide instructions
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

// *** <Thomas Fleming> I added these verilator controls to clean up the
// lint output. The linter warnings should be fixed, but now the output is at
// least readable.
/* verilator lint_off COMBDLY */
/* verilator lint_off IMPLICIT */

`include "idiv-config.vh"

module intdiv #(parameter WIDTH=64) 
   (Qf, done, remf, div0, N, D, clk, reset, start, S);

   input logic [WIDTH-1:0]   N, D;
   input logic 		     clk;
   input logic 		     reset;
   input logic 		     start;
   input logic 		     S;   
   
   output logic [WIDTH-1:0]  Qf;
   output logic [WIDTH-1:0]  remf;
   output logic 	     div0;
   output logic 	     done;
   
   logic 		     enable;
   logic 		     state0;
   logic 		     V;   
   logic [$clog2(WIDTH):0]   Num;
   logic [$clog2(WIDTH)-1:0] P, NumIter, RemShift, RemShiftP;
   logic [WIDTH-1:0] 	     op1, op2, op1shift, Rem5;
   logic [WIDTH:0] 	     Qd, Rd, Qd2, Rd2;
   logic [WIDTH:0] 	     Q2d, Qd3;
   logic [WIDTH-1:0] 	     Q, Q2, rem0;
   logic [3:0] 		     quotient;
   logic 		     otfzero; 
   logic 		     shiftResult;
   
   logic [WIDTH-1:0] 	     twoD;
   logic [WIDTH-1:0] 	     twoN;
   logic 		     SignD;
   logic 		     SignN;
   logic [WIDTH-1:0] 	     QT, remT;
   logic 		     D_NegOne;
   logic 		     Max_N;
   logic [1:0] 		     QR;
   logic 		     tcQ, tcR;   

   // Check if negative (two's complement)
   //   If so, convert to positive
   adder #(WIDTH) cpa1 ((D ^ {WIDTH{D[WIDTH-1]&S}}), {{WIDTH-1{1'b0}}, D[WIDTH-1]&S}, twoD);
   adder #(WIDTH) cpa2 ((N ^ {WIDTH{N[WIDTH-1]&S}}), {{WIDTH-1{1'b0}}, N[WIDTH-1]&S}, twoN);   
   assign SignD = D[WIDTH-1];
   assign SignN = N[WIDTH-1];   
   // Max N and D = -1 (Overflow)
   assign Max_N = (~|N[WIDTH-2:0]) & N[WIDTH-1];
   assign D_NegOne = &D;
   
   // Divider goes the distance to 37 cycles
   // (thanks to the evil divisor for D = 0x1) 
   // The enable signal turns off register storage thus invalidating
   // any future cycles.
   
   // Shift D, if needed (for integer)
   // needed to allow qst to be in range for integer
   // division [1,2) and allow integer divide to work.
   //
   // The V or valid bit can be used to determine if D
   // is 0 and thus a divide by 0 exception.  This div0
   // exception is given to FSM to tell the operation to 
   // quit gracefully.

   lod_hier #(WIDTH) p1 (.ZP(P), .ZV(V), .B(twoD));
   shift_left #(WIDTH) p2 (twoD, P, op2);
   assign op1 = twoN;   
   assign div0 = ~V;

   // #iter: N = m+v+s = m+2+s (mod k = 0)
   // v = 2 since \rho < 1 (add 4 to make sure its a ceil)
   // k = 2 (r = 2^k)
   adder #($clog2(WIDTH)+1) cpa3 ({1'b0, P}, 
				  {{$clog2(WIDTH)+1-3{1'b0}}, shiftResult, ~shiftResult, 1'b0}, 
				  Num);      
   
   // Determine whether need to add just Q/Rem
   assign shiftResult = P[0];   
   // div by 2 (ceil)
   assign NumIter = Num[$clog2(WIDTH):1];   
   assign RemShift = P;

   // Avoid critical path of RemShift
   flopr #($clog2(WIDTH)) reg1 (clk, reset, RemShift, RemShiftP);   

   // FSM to control integer divider
   //   assume inputs are postive edge and
   //   datapath (divider) is negative edge
   fsm64 #($clog2(WIDTH)) fsm1 (enablev, state0v, donev, otfzerov,
				start, div0, NumIter, ~clk, reset);

   flopr #(1) rega (~clk, reset, donev, done);
   flopr #(1) regc (~clk, reset, otfzerov, otfzero);
   flopr #(1) regd (~clk, reset, enablev, enable);
   flopr #(1) rege (~clk, reset, state0v, state0);   
   
   // To obtain a correct remainder the last bit of the
   // quotient has to be aligned with a radix-r boundary.
   // Since the quotient is in the range 1/2 < q < 2 (one
   // integer bit and m fractional bits), this is achieved by
   // shifting N right by v+s so that (m+v+s) mod k = 0.  And,
   // the quotient has to be aligned to the integer position.
   divide4 #(WIDTH) p3 (Qd, Q2d, Rd, quotient, op1, op2, clk, reset, state0, 
			enable, otfzero, shiftResult);

   // Storage registers to hold contents stable
   flopenr #(WIDTH+1) reg3 (clk, reset, enable, Rd, Rd2);
   flopenr #(WIDTH+1) reg4 (clk, reset, enable, Qd, Qd2);
   flopenr #(WIDTH+1) reg5 (clk, reset, enable, Q2d, Qd3);            

   // Probably not needed - just assigns results
   assign Q = Qd2[WIDTH-1:0];
   assign Rem5 = Rd2[WIDTH:1];
   assign Q2 = Qd3[WIDTH-1:0];   
   
   // Adjust remainder by m (no need to adjust by
   shift_right #(WIDTH) p4 (Rem5, RemShiftP, rem0);

   // Adjust Q/Rem for Signed
   always_comb
     casex({S, SignN, SignD})
       3'b000 : QR = 2'b00;
       3'b001 : QR = 2'b00;
       3'b010 : QR = 2'b00;
       3'b011 : QR = 2'b00;
       3'b100 : QR = 2'b00;
       3'b101 : QR = 2'b10;
       3'b110 : QR = 2'b11;
       3'b111 : QR = 2'b01;
       default: QR = 2'b00;
     endcase // casex ({SignN, SignD, S})
   assign {tcQ, tcR} = QR;    

   // When Dividend (N) and/or Divisor (D) are negative (first bit is '1'):
   // - When N and D are negative: Remainder i
   // s negative (undergoes a two's complement).
   // - When N is negative: Quotient and Remainder are both negative (undergo a two's complement).
   // - When D is negative: Quotient is negative (undergoes a two's complement).
   adder #(WIDTH) cpa4 ((rem0 ^ {WIDTH{tcR}}), {{WIDTH-1{1'b0}}, tcR}, remT);
   adder #(WIDTH) cpa5 ((Q ^ {WIDTH{tcQ}}), {{WIDTH-1{1'b0}}, tcQ}, QT);         

   // RISC-V has exceptions for divide by 0 and overflow (see Table 6.1 of spec)
   exception_int #(WIDTH) exc (QT, remT, N, S, div0, Max_N, D_NegOne, Qf, remf);
   
endmodule // intdiv

// Division by Recurrence (r=4)
module divide4 #(parameter WIDTH=64) 
   (Q, Q2, rem0, quotient, op1, op2, clk, reset, state0, 
    enable, otfzero, shiftResult); 

   input logic [WIDTH-1:0]   op1, op2;
   input logic 		     clk, state0;
   input logic 		     reset;
   input logic 		     enable;
   input logic 		     otfzero;
   input logic 		     shiftResult;   
   
   output logic [WIDTH:0]    rem0;
   output logic [WIDTH:0]    Q;
   output logic [WIDTH:0]    Q2;   
   output logic [3:0] 	     quotient;   

   logic [WIDTH+3:0] 	     Sum, Carry;   
   logic [WIDTH:0] 	     Qstar;   
   logic [WIDTH:0] 	     QMstar;
   logic [WIDTH:0] 	     QM2star;   
   logic [7:0] 		     qtotal;   
   logic [WIDTH+3:0] 	     SumN, CarryN, SumN2, CarryN2;
   logic [WIDTH+3:0] 	     divi1, divi2, divi1c, divi2c, dive1;
   logic [WIDTH+3:0] 	     mdivi_temp, mdivi;   
   logic 		     zero;
   logic [1:0] 		     qsel;
   logic [1:0] 		     Qin, QMin;
   logic 		     CshiftQ, CshiftQM;
   logic [WIDTH+3:0] 	     rem1, rem2, rem3;
   logic [WIDTH+3:0] 	     SumR, CarryR;
   logic [WIDTH:0] 	     Qt;

   // Create one's complement values of Divisor (for q*D)
   assign divi1 = {3'h0, op2, 1'b0};
   assign divi2 = {2'h0, op2, 2'b0};
   assign divi1c = ~divi1;
   assign divi2c = ~divi2;
   // Shift x1 if not mod k
   mux2 #(WIDTH+4) mx1 ({3'b000, op1, 1'b0},  {4'h0, op1}, shiftResult, dive1);   

   // I I I . F F F F F ... (Robertson Criteria - \rho * qmax * D)
   mux2 #(WIDTH+4) mx2 ({CarryN2[WIDTH+1:0], 2'h0}, {WIDTH+4{1'b0}}, state0, CarryN);
   mux2 #(WIDTH+4) mx3 ({SumN2[WIDTH+1:0], 2'h0}, dive1, state0, SumN);
   // Simplify QST
   adder #(8) cpa1 (SumN[WIDTH+3:WIDTH-4], CarryN[WIDTH+3:WIDTH-4], qtotal);   
   // q = {+2, +1, -1, -2} else q = 0
   qst4 pd1 (qtotal[7:1], divi1[WIDTH-1:WIDTH-3], quotient);
   assign ulp = quotient[2]|quotient[3];
   assign zero = ~(quotient[3]|quotient[2]|quotient[1]|quotient[0]);
   // Map to binary encoding
   assign qsel[1] = quotient[3]|quotient[2];
   assign qsel[0] = quotient[3]|quotient[1];   
   mux4 #(WIDTH+4) mx4 (divi2, divi1, divi1c, divi2c, qsel, mdivi_temp);
   mux2 #(WIDTH+4) mx5 (mdivi_temp, {WIDTH+4{1'b0}}, zero, mdivi);
   csa #(WIDTH+4) csa1 (mdivi, SumN, {CarryN[WIDTH+3:1], ulp}, Sum, Carry);
   // regs : save CSA
   flopenr #(WIDTH+4) reg1 (clk, reset, enable, Sum, SumN2);
   flopenr #(WIDTH+4) reg2 (clk, reset, enable, Carry, CarryN2);
   // OTF
   ls_control otf1 (quotient, Qin, QMin, CshiftQ, CshiftQM);   
   otf #(WIDTH+1) otf2 (Qin, QMin, CshiftQ, CshiftQM, 
			clk, otfzero, enable, Qstar, QMstar);

   // Correction and generation of Remainder
   adder #(WIDTH+4) cpa2 (SumN2[WIDTH+3:0], CarryN2[WIDTH+3:0], rem1);
   // Add back +D as correction
   csa #(WIDTH+4) csa2 (CarryN2[WIDTH+3:0], SumN2[WIDTH+3:0], divi1, SumR, CarryR);
   adder #(WIDTH+4) cpa3 (SumR, CarryR, rem2);   
   // Choose remainder (Rem or Rem+D)
   mux2 #(WIDTH+4) mx6 (rem1, rem2, rem1[WIDTH+3], rem3);
   // Choose correct Q or QM
   mux2 #(WIDTH+1) mx7 (Qstar, QMstar, rem1[WIDTH+3], Qt);
   // Final results
   assign rem0 = rem3[WIDTH:0];
   assign Q = Qt;
   
endmodule // divide4

module ls_control (quot, Qin, QMin, CshiftQ, CshiftQM);

   input logic [3:0] quot;

   output logic [1:0] Qin;
   output logic [1:0] QMin;
   output logic       CshiftQ;
   output logic       CshiftQM;

   logic [5:0] 	      qout;   

   // q = {+2, +1, -1, -2}
   always_comb
     casex(quot)
       4'b0000 : qout = 6'b00_11_0_0;
       4'b0001 : qout = 6'b10_01_1_0;
       4'b0010 : qout = 6'b11_10_1_0;       
       4'b0100 : qout = 6'b01_00_0_1;
       4'b1000 : qout = 6'b10_01_0_1;
       default : qout = 6'bxx_xx_x_x;
     endcase // case (quot)

   assign {Qin, QMin, CshiftQ, CshiftQM} = qout;

endmodule // ls_control

// On-the-fly Conversion per Ercegovac/Lang
module otf #(parameter WIDTH=8) 
   (Qin, QMin, CshiftQ, CshiftQM, clk, reset, enable, R2Q, R1Q);
   
   input logic [1:0]        Qin, QMin;
   input logic 		    CshiftQ, CshiftQM;
   input logic 		    clk;
   input logic 	            reset;
   input logic 		    enable;   

   output logic [WIDTH-1:0] R2Q;
   output logic [WIDTH-1:0] R1Q;   

   logic [WIDTH-1:0] 	    Qstar, QMstar;      
   logic [WIDTH-1:0] 	    M1Q, M2Q;

   // QM
   mux2 #(WIDTH)  m1 (QMstar, Qstar, CshiftQM, M1Q);
   flopenr #(WIDTH) r1 (clk, reset, enable, {M1Q[WIDTH-3:0], QMin}, R1Q);
   // Q
   mux2 #(WIDTH)  m2 (Qstar, QMstar, CshiftQ, M2Q);
   flopenr #(WIDTH) r2 (clk, reset, enable, {M2Q[WIDTH-3:0], Qin}, R2Q);
   
   assign Qstar = R2Q;
   assign QMstar = R1Q;

endmodule // otf

module adder #(parameter WIDTH=8) 
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] y);

   assign y = a + b;

endmodule // adder

module fa (input logic a, b, c, output logic sum, carry);

   assign sum = a^b^c;
   assign carry = a&b|a&c|b&c;   

endmodule // fa

module csa #(parameter WIDTH=8) 
   (input logic [WIDTH-1:0] a, b, c,
    output logic [WIDTH-1:0] sum, carry);
   
   logic [WIDTH:0] 	     carry_temp;   
   genvar 		     i;
   generate
      for (i=0;i<WIDTH;i=i+1)
	begin : genbit
	   fa fa_inst (a[i], b[i], c[i], sum[i], carry_temp[i+1]);
	end
   endgenerate
   assign carry = {1'b0, carry_temp[WIDTH-1:1], 1'b0};     

endmodule // csa

module flopenr #(parameter WIDTH = 8) 
   (input logic clk, reset, en,
    input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);

   always_ff @(posedge clk, posedge reset) 
     if (reset) q <= 0; 
     else if (en) q <= d;

endmodule // flopenr

module flopr #(parameter WIDTH = 8) 
   (input logic clk, reset, input
    logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);

   always_ff @(posedge clk, posedge reset) 
     if (reset) q <= 0; 
     else q <= d;

endmodule // flopr

module flopenrc #(parameter WIDTH = 8) 
   (input logic clk, reset, en, clear, 
    input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);

   always_ff @(posedge clk, posedge reset) 
     if (reset) q <= 0; 
     else 
       if (en) 
	 if (clear) q <= 0; 
	 else q <= d;

endmodule // flopenrc

module floprc #(parameter WIDTH = 8) 
   (input logic clk, reset, clear,
    input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);

   always_ff @(posedge clk, posedge reset) 
     if (reset) q <= 0; 
     else 
       if (clear) q <= 0; 
       else q <= d;

endmodule // floprc

module eqcmp #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] a, b,
    output logic y);
   
   assign y = (a == b);
   
endmodule // eqcmp

module qst4 (input logic [6:0] s, input logic [2:0] d,
	     output logic [3:0] q);

   always_comb
     case({d, s})
       10'b000_0000000: q = 4'b0000;
       10'b000_0000001: q = 4'b0000;
       10'b000_0000010: q = 4'b0000;
       10'b000_0000011: q = 4'b0000;
       10'b000_0000100: q = 4'b0100;
       10'b000_0000101: q = 4'b0100;
       10'b000_0000110: q = 4'b0100;
       10'b000_0000111: q = 4'b0100;
       10'b000_0001000: q = 4'b0100;
       10'b000_0001001: q = 4'b0100;
       10'b000_0001010: q = 4'b0100;
       10'b000_0001011: q = 4'b0100;
       10'b000_0001100: q = 4'b1000;
       10'b000_0001101: q = 4'b1000;
       10'b000_0001110: q = 4'b1000;
       10'b000_0001111: q = 4'b1000;
       10'b000_0010000: q = 4'b1000;
       10'b000_0010001: q = 4'b1000;
       10'b000_0010010: q = 4'b1000;
       10'b000_0010011: q = 4'b1000;
       10'b000_0010100: q = 4'b1000;
       10'b000_0010101: q = 4'b1000;
       10'b000_0010110: q = 4'b1000;
       10'b000_0010111: q = 4'b1000;
       10'b000_0011000: q = 4'b1000;
       10'b000_0011001: q = 4'b1000;
       10'b000_0011010: q = 4'b1000;
       10'b000_0011011: q = 4'b1000;
       10'b000_0011100: q = 4'b1000;
       10'b000_0011101: q = 4'b1000;
       10'b000_0011110: q = 4'b1000;
       10'b000_0011111: q = 4'b1000;
       10'b000_0100000: q = 4'b1000;
       10'b000_0100001: q = 4'b1000;
       10'b000_0100010: q = 4'b1000;
       10'b000_0100011: q = 4'b1000;
       10'b000_0100100: q = 4'b1000;
       10'b000_0100101: q = 4'b1000;
       10'b000_0100110: q = 4'b1000;
       10'b000_0100111: q = 4'b1000;
       10'b000_0101000: q = 4'b1000;
       10'b000_0101001: q = 4'b1000;
       10'b000_0101010: q = 4'b1000;
       10'b000_0101011: q = 4'b1000;
       10'b000_0101100: q = 4'b1000;
       10'b000_0101101: q = 4'b1000;
       10'b000_0101110: q = 4'b1000;
       10'b000_0101111: q = 4'b1000;
       10'b000_0110000: q = 4'b1000;
       10'b000_0110001: q = 4'b1000;
       10'b000_0110010: q = 4'b1000;
       10'b000_0110011: q = 4'b1000;
       10'b000_0110100: q = 4'b1000;
       10'b000_0110101: q = 4'b1000;
       10'b000_0110110: q = 4'b1000;
       10'b000_0110111: q = 4'b1000;
       10'b000_0111000: q = 4'b1000;
       10'b000_0111001: q = 4'b1000;
       10'b000_0111010: q = 4'b1000;
       10'b000_0111011: q = 4'b1000;
       10'b000_0111100: q = 4'b1000;
       10'b000_0111101: q = 4'b1000;
       10'b000_0111110: q = 4'b1000;
       10'b000_0111111: q = 4'b1000;
       10'b000_1000000: q = 4'b0001;
       10'b000_1000001: q = 4'b0001;
       10'b000_1000010: q = 4'b0001;
       10'b000_1000011: q = 4'b0001;
       10'b000_1000100: q = 4'b0001;
       10'b000_1000101: q = 4'b0001;
       10'b000_1000110: q = 4'b0001;
       10'b000_1000111: q = 4'b0001;
       10'b000_1001000: q = 4'b0001;
       10'b000_1001001: q = 4'b0001;
       10'b000_1001010: q = 4'b0001;
       10'b000_1001011: q = 4'b0001;
       10'b000_1001100: q = 4'b0001;
       10'b000_1001101: q = 4'b0001;
       10'b000_1001110: q = 4'b0001;
       10'b000_1001111: q = 4'b0001;
       10'b000_1010000: q = 4'b0001;
       10'b000_1010001: q = 4'b0001;
       10'b000_1010010: q = 4'b0001;
       10'b000_1010011: q = 4'b0001;
       10'b000_1010100: q = 4'b0001;
       10'b000_1010101: q = 4'b0001;
       10'b000_1010110: q = 4'b0001;
       10'b000_1010111: q = 4'b0001;
       10'b000_1011000: q = 4'b0001;
       10'b000_1011001: q = 4'b0001;
       10'b000_1011010: q = 4'b0001;
       10'b000_1011011: q = 4'b0001;
       10'b000_1011100: q = 4'b0001;
       10'b000_1011101: q = 4'b0001;
       10'b000_1011110: q = 4'b0001;
       10'b000_1011111: q = 4'b0001;
       10'b000_1100000: q = 4'b0001;
       10'b000_1100001: q = 4'b0001;
       10'b000_1100010: q = 4'b0001;
       10'b000_1100011: q = 4'b0001;
       10'b000_1100100: q = 4'b0001;
       10'b000_1100101: q = 4'b0001;
       10'b000_1100110: q = 4'b0001;
       10'b000_1100111: q = 4'b0001;
       10'b000_1101000: q = 4'b0001;
       10'b000_1101001: q = 4'b0001;
       10'b000_1101010: q = 4'b0001;
       10'b000_1101011: q = 4'b0001;
       10'b000_1101100: q = 4'b0001;
       10'b000_1101101: q = 4'b0001;
       10'b000_1101110: q = 4'b0001;
       10'b000_1101111: q = 4'b0001;
       10'b000_1110000: q = 4'b0001;
       10'b000_1110001: q = 4'b0001;
       10'b000_1110010: q = 4'b0001;
       10'b000_1110011: q = 4'b0010;
       10'b000_1110100: q = 4'b0010;
       10'b000_1110101: q = 4'b0010;
       10'b000_1110110: q = 4'b0010;
       10'b000_1110111: q = 4'b0010;
       10'b000_1111000: q = 4'b0010;
       10'b000_1111001: q = 4'b0010;
       10'b000_1111010: q = 4'b0010;
       10'b000_1111011: q = 4'b0010;
       10'b000_1111100: q = 4'b0000;
       10'b000_1111101: q = 4'b0000;
       10'b000_1111110: q = 4'b0000;
       10'b000_1111111: q = 4'b0000;
       10'b001_0000000: q = 4'b0000;
       10'b001_0000001: q = 4'b0000;
       10'b001_0000010: q = 4'b0000;
       10'b001_0000011: q = 4'b0000;
       10'b001_0000100: q = 4'b0100;
       10'b001_0000101: q = 4'b0100;
       10'b001_0000110: q = 4'b0100;
       10'b001_0000111: q = 4'b0100;
       10'b001_0001000: q = 4'b0100;
       10'b001_0001001: q = 4'b0100;
       10'b001_0001010: q = 4'b0100;
       10'b001_0001011: q = 4'b0100;
       10'b001_0001100: q = 4'b0100;
       10'b001_0001101: q = 4'b0100;
       10'b001_0001110: q = 4'b1000;
       10'b001_0001111: q = 4'b1000;
       10'b001_0010000: q = 4'b1000;
       10'b001_0010001: q = 4'b1000;
       10'b001_0010010: q = 4'b1000;
       10'b001_0010011: q = 4'b1000;
       10'b001_0010100: q = 4'b1000;
       10'b001_0010101: q = 4'b1000;
       10'b001_0010110: q = 4'b1000;
       10'b001_0010111: q = 4'b1000;
       10'b001_0011000: q = 4'b1000;
       10'b001_0011001: q = 4'b1000;
       10'b001_0011010: q = 4'b1000;
       10'b001_0011011: q = 4'b1000;
       10'b001_0011100: q = 4'b1000;
       10'b001_0011101: q = 4'b1000;
       10'b001_0011110: q = 4'b1000;
       10'b001_0011111: q = 4'b1000;
       10'b001_0100000: q = 4'b1000;
       10'b001_0100001: q = 4'b1000;
       10'b001_0100010: q = 4'b1000;
       10'b001_0100011: q = 4'b1000;
       10'b001_0100100: q = 4'b1000;
       10'b001_0100101: q = 4'b1000;
       10'b001_0100110: q = 4'b1000;
       10'b001_0100111: q = 4'b1000;
       10'b001_0101000: q = 4'b1000;
       10'b001_0101001: q = 4'b1000;
       10'b001_0101010: q = 4'b1000;
       10'b001_0101011: q = 4'b1000;
       10'b001_0101100: q = 4'b1000;
       10'b001_0101101: q = 4'b1000;
       10'b001_0101110: q = 4'b1000;
       10'b001_0101111: q = 4'b1000;
       10'b001_0110000: q = 4'b1000;
       10'b001_0110001: q = 4'b1000;
       10'b001_0110010: q = 4'b1000;
       10'b001_0110011: q = 4'b1000;
       10'b001_0110100: q = 4'b1000;
       10'b001_0110101: q = 4'b1000;
       10'b001_0110110: q = 4'b1000;
       10'b001_0110111: q = 4'b1000;
       10'b001_0111000: q = 4'b1000;
       10'b001_0111001: q = 4'b1000;
       10'b001_0111010: q = 4'b1000;
       10'b001_0111011: q = 4'b1000;
       10'b001_0111100: q = 4'b1000;
       10'b001_0111101: q = 4'b1000;
       10'b001_0111110: q = 4'b1000;
       10'b001_0111111: q = 4'b1000;
       10'b001_1000000: q = 4'b0001;
       10'b001_1000001: q = 4'b0001;
       10'b001_1000010: q = 4'b0001;
       10'b001_1000011: q = 4'b0001;
       10'b001_1000100: q = 4'b0001;
       10'b001_1000101: q = 4'b0001;
       10'b001_1000110: q = 4'b0001;
       10'b001_1000111: q = 4'b0001;
       10'b001_1001000: q = 4'b0001;
       10'b001_1001001: q = 4'b0001;
       10'b001_1001010: q = 4'b0001;
       10'b001_1001011: q = 4'b0001;
       10'b001_1001100: q = 4'b0001;
       10'b001_1001101: q = 4'b0001;
       10'b001_1001110: q = 4'b0001;
       10'b001_1001111: q = 4'b0001;
       10'b001_1010000: q = 4'b0001;
       10'b001_1010001: q = 4'b0001;
       10'b001_1010010: q = 4'b0001;
       10'b001_1010011: q = 4'b0001;
       10'b001_1010100: q = 4'b0001;
       10'b001_1010101: q = 4'b0001;
       10'b001_1010110: q = 4'b0001;
       10'b001_1010111: q = 4'b0001;
       10'b001_1011000: q = 4'b0001;
       10'b001_1011001: q = 4'b0001;
       10'b001_1011010: q = 4'b0001;
       10'b001_1011011: q = 4'b0001;
       10'b001_1011100: q = 4'b0001;
       10'b001_1011101: q = 4'b0001;
       10'b001_1011110: q = 4'b0001;
       10'b001_1011111: q = 4'b0001;
       10'b001_1100000: q = 4'b0001;
       10'b001_1100001: q = 4'b0001;
       10'b001_1100010: q = 4'b0001;
       10'b001_1100011: q = 4'b0001;
       10'b001_1100100: q = 4'b0001;
       10'b001_1100101: q = 4'b0001;
       10'b001_1100110: q = 4'b0001;
       10'b001_1100111: q = 4'b0001;
       10'b001_1101000: q = 4'b0001;
       10'b001_1101001: q = 4'b0001;
       10'b001_1101010: q = 4'b0001;
       10'b001_1101011: q = 4'b0001;
       10'b001_1101100: q = 4'b0001;
       10'b001_1101101: q = 4'b0001;
       10'b001_1101110: q = 4'b0001;
       10'b001_1101111: q = 4'b0001;
       10'b001_1110000: q = 4'b0001;
       10'b001_1110001: q = 4'b0010;
       10'b001_1110010: q = 4'b0010;
       10'b001_1110011: q = 4'b0010;
       10'b001_1110100: q = 4'b0010;
       10'b001_1110101: q = 4'b0010;
       10'b001_1110110: q = 4'b0010;
       10'b001_1110111: q = 4'b0010;
       10'b001_1111000: q = 4'b0010;
       10'b001_1111001: q = 4'b0010;
       10'b001_1111010: q = 4'b0000;
       10'b001_1111011: q = 4'b0000;
       10'b001_1111100: q = 4'b0000;
       10'b001_1111101: q = 4'b0000;
       10'b001_1111110: q = 4'b0000;
       10'b001_1111111: q = 4'b0000;
       10'b010_0000000: q = 4'b0000;
       10'b010_0000001: q = 4'b0000;
       10'b010_0000010: q = 4'b0000;
       10'b010_0000011: q = 4'b0000;
       10'b010_0000100: q = 4'b0100;
       10'b010_0000101: q = 4'b0100;
       10'b010_0000110: q = 4'b0100;
       10'b010_0000111: q = 4'b0100;
       10'b010_0001000: q = 4'b0100;
       10'b010_0001001: q = 4'b0100;
       10'b010_0001010: q = 4'b0100;
       10'b010_0001011: q = 4'b0100;
       10'b010_0001100: q = 4'b0100;
       10'b010_0001101: q = 4'b0100;
       10'b010_0001110: q = 4'b0100;
       10'b010_0001111: q = 4'b1000;
       10'b010_0010000: q = 4'b1000;
       10'b010_0010001: q = 4'b1000;
       10'b010_0010010: q = 4'b1000;
       10'b010_0010011: q = 4'b1000;
       10'b010_0010100: q = 4'b1000;
       10'b010_0010101: q = 4'b1000;
       10'b010_0010110: q = 4'b1000;
       10'b010_0010111: q = 4'b1000;
       10'b010_0011000: q = 4'b1000;
       10'b010_0011001: q = 4'b1000;
       10'b010_0011010: q = 4'b1000;
       10'b010_0011011: q = 4'b1000;
       10'b010_0011100: q = 4'b1000;
       10'b010_0011101: q = 4'b1000;
       10'b010_0011110: q = 4'b1000;
       10'b010_0011111: q = 4'b1000;
       10'b010_0100000: q = 4'b1000;
       10'b010_0100001: q = 4'b1000;
       10'b010_0100010: q = 4'b1000;
       10'b010_0100011: q = 4'b1000;
       10'b010_0100100: q = 4'b1000;
       10'b010_0100101: q = 4'b1000;
       10'b010_0100110: q = 4'b1000;
       10'b010_0100111: q = 4'b1000;
       10'b010_0101000: q = 4'b1000;
       10'b010_0101001: q = 4'b1000;
       10'b010_0101010: q = 4'b1000;
       10'b010_0101011: q = 4'b1000;
       10'b010_0101100: q = 4'b1000;
       10'b010_0101101: q = 4'b1000;
       10'b010_0101110: q = 4'b1000;
       10'b010_0101111: q = 4'b1000;
       10'b010_0110000: q = 4'b1000;
       10'b010_0110001: q = 4'b1000;
       10'b010_0110010: q = 4'b1000;
       10'b010_0110011: q = 4'b1000;
       10'b010_0110100: q = 4'b1000;
       10'b010_0110101: q = 4'b1000;
       10'b010_0110110: q = 4'b1000;
       10'b010_0110111: q = 4'b1000;
       10'b010_0111000: q = 4'b1000;
       10'b010_0111001: q = 4'b1000;
       10'b010_0111010: q = 4'b1000;
       10'b010_0111011: q = 4'b1000;
       10'b010_0111100: q = 4'b1000;
       10'b010_0111101: q = 4'b1000;
       10'b010_0111110: q = 4'b1000;
       10'b010_0111111: q = 4'b1000;
       10'b010_1000000: q = 4'b0001;
       10'b010_1000001: q = 4'b0001;
       10'b010_1000010: q = 4'b0001;
       10'b010_1000011: q = 4'b0001;
       10'b010_1000100: q = 4'b0001;
       10'b010_1000101: q = 4'b0001;
       10'b010_1000110: q = 4'b0001;
       10'b010_1000111: q = 4'b0001;
       10'b010_1001000: q = 4'b0001;
       10'b010_1001001: q = 4'b0001;
       10'b010_1001010: q = 4'b0001;
       10'b010_1001011: q = 4'b0001;
       10'b010_1001100: q = 4'b0001;
       10'b010_1001101: q = 4'b0001;
       10'b010_1001110: q = 4'b0001;
       10'b010_1001111: q = 4'b0001;
       10'b010_1010000: q = 4'b0001;
       10'b010_1010001: q = 4'b0001;
       10'b010_1010010: q = 4'b0001;
       10'b010_1010011: q = 4'b0001;
       10'b010_1010100: q = 4'b0001;
       10'b010_1010101: q = 4'b0001;
       10'b010_1010110: q = 4'b0001;
       10'b010_1010111: q = 4'b0001;
       10'b010_1011000: q = 4'b0001;
       10'b010_1011001: q = 4'b0001;
       10'b010_1011010: q = 4'b0001;
       10'b010_1011011: q = 4'b0001;
       10'b010_1011100: q = 4'b0001;
       10'b010_1011101: q = 4'b0001;
       10'b010_1011110: q = 4'b0001;
       10'b010_1011111: q = 4'b0001;
       10'b010_1100000: q = 4'b0001;
       10'b010_1100001: q = 4'b0001;
       10'b010_1100010: q = 4'b0001;
       10'b010_1100011: q = 4'b0001;
       10'b010_1100100: q = 4'b0001;
       10'b010_1100101: q = 4'b0001;
       10'b010_1100110: q = 4'b0001;
       10'b010_1100111: q = 4'b0001;
       10'b010_1101000: q = 4'b0001;
       10'b010_1101001: q = 4'b0001;
       10'b010_1101010: q = 4'b0001;
       10'b010_1101011: q = 4'b0001;
       10'b010_1101100: q = 4'b0001;
       10'b010_1101101: q = 4'b0001;
       10'b010_1101110: q = 4'b0001;
       10'b010_1101111: q = 4'b0001;
       10'b010_1110000: q = 4'b0010;
       10'b010_1110001: q = 4'b0010;
       10'b010_1110010: q = 4'b0010;
       10'b010_1110011: q = 4'b0010;
       10'b010_1110100: q = 4'b0010;
       10'b010_1110101: q = 4'b0010;
       10'b010_1110110: q = 4'b0010;
       10'b010_1110111: q = 4'b0010;
       10'b010_1111000: q = 4'b0010;
       10'b010_1111001: q = 4'b0010;
       10'b010_1111010: q = 4'b0000;
       10'b010_1111011: q = 4'b0000;
       10'b010_1111100: q = 4'b0000;
       10'b010_1111101: q = 4'b0000;
       10'b010_1111110: q = 4'b0000;
       10'b010_1111111: q = 4'b0000;
       10'b011_0000000: q = 4'b0000;
       10'b011_0000001: q = 4'b0000;
       10'b011_0000010: q = 4'b0000;
       10'b011_0000011: q = 4'b0000;
       10'b011_0000100: q = 4'b0100;
       10'b011_0000101: q = 4'b0100;
       10'b011_0000110: q = 4'b0100;
       10'b011_0000111: q = 4'b0100;
       10'b011_0001000: q = 4'b0100;
       10'b011_0001001: q = 4'b0100;
       10'b011_0001010: q = 4'b0100;
       10'b011_0001011: q = 4'b0100;
       10'b011_0001100: q = 4'b0100;
       10'b011_0001101: q = 4'b0100;
       10'b011_0001110: q = 4'b0100;
       10'b011_0001111: q = 4'b0100;
       10'b011_0010000: q = 4'b1000;
       10'b011_0010001: q = 4'b1000;
       10'b011_0010010: q = 4'b1000;
       10'b011_0010011: q = 4'b1000;
       10'b011_0010100: q = 4'b1000;
       10'b011_0010101: q = 4'b1000;
       10'b011_0010110: q = 4'b1000;
       10'b011_0010111: q = 4'b1000;
       10'b011_0011000: q = 4'b1000;
       10'b011_0011001: q = 4'b1000;
       10'b011_0011010: q = 4'b1000;
       10'b011_0011011: q = 4'b1000;
       10'b011_0011100: q = 4'b1000;
       10'b011_0011101: q = 4'b1000;
       10'b011_0011110: q = 4'b1000;
       10'b011_0011111: q = 4'b1000;
       10'b011_0100000: q = 4'b1000;
       10'b011_0100001: q = 4'b1000;
       10'b011_0100010: q = 4'b1000;
       10'b011_0100011: q = 4'b1000;
       10'b011_0100100: q = 4'b1000;
       10'b011_0100101: q = 4'b1000;
       10'b011_0100110: q = 4'b1000;
       10'b011_0100111: q = 4'b1000;
       10'b011_0101000: q = 4'b1000;
       10'b011_0101001: q = 4'b1000;
       10'b011_0101010: q = 4'b1000;
       10'b011_0101011: q = 4'b1000;
       10'b011_0101100: q = 4'b1000;
       10'b011_0101101: q = 4'b1000;
       10'b011_0101110: q = 4'b1000;
       10'b011_0101111: q = 4'b1000;
       10'b011_0110000: q = 4'b1000;
       10'b011_0110001: q = 4'b1000;
       10'b011_0110010: q = 4'b1000;
       10'b011_0110011: q = 4'b1000;
       10'b011_0110100: q = 4'b1000;
       10'b011_0110101: q = 4'b1000;
       10'b011_0110110: q = 4'b1000;
       10'b011_0110111: q = 4'b1000;
       10'b011_0111000: q = 4'b1000;
       10'b011_0111001: q = 4'b1000;
       10'b011_0111010: q = 4'b1000;
       10'b011_0111011: q = 4'b1000;
       10'b011_0111100: q = 4'b1000;
       10'b011_0111101: q = 4'b1000;
       10'b011_0111110: q = 4'b1000;
       10'b011_0111111: q = 4'b1000;
       10'b011_1000000: q = 4'b0001;
       10'b011_1000001: q = 4'b0001;
       10'b011_1000010: q = 4'b0001;
       10'b011_1000011: q = 4'b0001;
       10'b011_1000100: q = 4'b0001;
       10'b011_1000101: q = 4'b0001;
       10'b011_1000110: q = 4'b0001;
       10'b011_1000111: q = 4'b0001;
       10'b011_1001000: q = 4'b0001;
       10'b011_1001001: q = 4'b0001;
       10'b011_1001010: q = 4'b0001;
       10'b011_1001011: q = 4'b0001;
       10'b011_1001100: q = 4'b0001;
       10'b011_1001101: q = 4'b0001;
       10'b011_1001110: q = 4'b0001;
       10'b011_1001111: q = 4'b0001;
       10'b011_1010000: q = 4'b0001;
       10'b011_1010001: q = 4'b0001;
       10'b011_1010010: q = 4'b0001;
       10'b011_1010011: q = 4'b0001;
       10'b011_1010100: q = 4'b0001;
       10'b011_1010101: q = 4'b0001;
       10'b011_1010110: q = 4'b0001;
       10'b011_1010111: q = 4'b0001;
       10'b011_1011000: q = 4'b0001;
       10'b011_1011001: q = 4'b0001;
       10'b011_1011010: q = 4'b0001;
       10'b011_1011011: q = 4'b0001;
       10'b011_1011100: q = 4'b0001;
       10'b011_1011101: q = 4'b0001;
       10'b011_1011110: q = 4'b0001;
       10'b011_1011111: q = 4'b0001;
       10'b011_1100000: q = 4'b0001;
       10'b011_1100001: q = 4'b0001;
       10'b011_1100010: q = 4'b0001;
       10'b011_1100011: q = 4'b0001;
       10'b011_1100100: q = 4'b0001;
       10'b011_1100101: q = 4'b0001;
       10'b011_1100110: q = 4'b0001;
       10'b011_1100111: q = 4'b0001;
       10'b011_1101000: q = 4'b0001;
       10'b011_1101001: q = 4'b0001;
       10'b011_1101010: q = 4'b0001;
       10'b011_1101011: q = 4'b0001;
       10'b011_1101100: q = 4'b0001;
       10'b011_1101101: q = 4'b0001;
       10'b011_1101110: q = 4'b0010;
       10'b011_1101111: q = 4'b0010;
       10'b011_1110000: q = 4'b0010;
       10'b011_1110001: q = 4'b0010;
       10'b011_1110010: q = 4'b0010;
       10'b011_1110011: q = 4'b0010;
       10'b011_1110100: q = 4'b0010;
       10'b011_1110101: q = 4'b0010;
       10'b011_1110110: q = 4'b0010;
       10'b011_1110111: q = 4'b0010;
       10'b011_1111000: q = 4'b0010;
       10'b011_1111001: q = 4'b0010;
       10'b011_1111010: q = 4'b0000;
       10'b011_1111011: q = 4'b0000;
       10'b011_1111100: q = 4'b0000;
       10'b011_1111101: q = 4'b0000;
       10'b011_1111110: q = 4'b0000;
       10'b011_1111111: q = 4'b0000;
       10'b100_0000000: q = 4'b0000;
       10'b100_0000001: q = 4'b0000;
       10'b100_0000010: q = 4'b0000;
       10'b100_0000011: q = 4'b0000;
       10'b100_0000100: q = 4'b0000;
       10'b100_0000101: q = 4'b0000;
       10'b100_0000110: q = 4'b0100;
       10'b100_0000111: q = 4'b0100;
       10'b100_0001000: q = 4'b0100;
       10'b100_0001001: q = 4'b0100;
       10'b100_0001010: q = 4'b0100;
       10'b100_0001011: q = 4'b0100;
       10'b100_0001100: q = 4'b0100;
       10'b100_0001101: q = 4'b0100;
       10'b100_0001110: q = 4'b0100;
       10'b100_0001111: q = 4'b0100;
       10'b100_0010000: q = 4'b0100;
       10'b100_0010001: q = 4'b0100;
       10'b100_0010010: q = 4'b1000;
       10'b100_0010011: q = 4'b1000;
       10'b100_0010100: q = 4'b1000;
       10'b100_0010101: q = 4'b1000;
       10'b100_0010110: q = 4'b1000;
       10'b100_0010111: q = 4'b1000;
       10'b100_0011000: q = 4'b1000;
       10'b100_0011001: q = 4'b1000;
       10'b100_0011010: q = 4'b1000;
       10'b100_0011011: q = 4'b1000;
       10'b100_0011100: q = 4'b1000;
       10'b100_0011101: q = 4'b1000;
       10'b100_0011110: q = 4'b1000;
       10'b100_0011111: q = 4'b1000;
       10'b100_0100000: q = 4'b1000;
       10'b100_0100001: q = 4'b1000;
       10'b100_0100010: q = 4'b1000;
       10'b100_0100011: q = 4'b1000;
       10'b100_0100100: q = 4'b1000;
       10'b100_0100101: q = 4'b1000;
       10'b100_0100110: q = 4'b1000;
       10'b100_0100111: q = 4'b1000;
       10'b100_0101000: q = 4'b1000;
       10'b100_0101001: q = 4'b1000;
       10'b100_0101010: q = 4'b1000;
       10'b100_0101011: q = 4'b1000;
       10'b100_0101100: q = 4'b1000;
       10'b100_0101101: q = 4'b1000;
       10'b100_0101110: q = 4'b1000;
       10'b100_0101111: q = 4'b1000;
       10'b100_0110000: q = 4'b1000;
       10'b100_0110001: q = 4'b1000;
       10'b100_0110010: q = 4'b1000;
       10'b100_0110011: q = 4'b1000;
       10'b100_0110100: q = 4'b1000;
       10'b100_0110101: q = 4'b1000;
       10'b100_0110110: q = 4'b1000;
       10'b100_0110111: q = 4'b1000;
       10'b100_0111000: q = 4'b1000;
       10'b100_0111001: q = 4'b1000;
       10'b100_0111010: q = 4'b1000;
       10'b100_0111011: q = 4'b1000;
       10'b100_0111100: q = 4'b1000;
       10'b100_0111101: q = 4'b1000;
       10'b100_0111110: q = 4'b1000;
       10'b100_0111111: q = 4'b1000;
       10'b100_1000000: q = 4'b0001;
       10'b100_1000001: q = 4'b0001;
       10'b100_1000010: q = 4'b0001;
       10'b100_1000011: q = 4'b0001;
       10'b100_1000100: q = 4'b0001;
       10'b100_1000101: q = 4'b0001;
       10'b100_1000110: q = 4'b0001;
       10'b100_1000111: q = 4'b0001;
       10'b100_1001000: q = 4'b0001;
       10'b100_1001001: q = 4'b0001;
       10'b100_1001010: q = 4'b0001;
       10'b100_1001011: q = 4'b0001;
       10'b100_1001100: q = 4'b0001;
       10'b100_1001101: q = 4'b0001;
       10'b100_1001110: q = 4'b0001;
       10'b100_1001111: q = 4'b0001;
       10'b100_1010000: q = 4'b0001;
       10'b100_1010001: q = 4'b0001;
       10'b100_1010010: q = 4'b0001;
       10'b100_1010011: q = 4'b0001;
       10'b100_1010100: q = 4'b0001;
       10'b100_1010101: q = 4'b0001;
       10'b100_1010110: q = 4'b0001;
       10'b100_1010111: q = 4'b0001;
       10'b100_1011000: q = 4'b0001;
       10'b100_1011001: q = 4'b0001;
       10'b100_1011010: q = 4'b0001;
       10'b100_1011011: q = 4'b0001;
       10'b100_1011100: q = 4'b0001;
       10'b100_1011101: q = 4'b0001;
       10'b100_1011110: q = 4'b0001;
       10'b100_1011111: q = 4'b0001;
       10'b100_1100000: q = 4'b0001;
       10'b100_1100001: q = 4'b0001;
       10'b100_1100010: q = 4'b0001;
       10'b100_1100011: q = 4'b0001;
       10'b100_1100100: q = 4'b0001;
       10'b100_1100101: q = 4'b0001;
       10'b100_1100110: q = 4'b0001;
       10'b100_1100111: q = 4'b0001;
       10'b100_1101000: q = 4'b0001;
       10'b100_1101001: q = 4'b0001;
       10'b100_1101010: q = 4'b0001;
       10'b100_1101011: q = 4'b0001;
       10'b100_1101100: q = 4'b0010;
       10'b100_1101101: q = 4'b0010;
       10'b100_1101110: q = 4'b0010;
       10'b100_1101111: q = 4'b0010;
       10'b100_1110000: q = 4'b0010;
       10'b100_1110001: q = 4'b0010;
       10'b100_1110010: q = 4'b0010;
       10'b100_1110011: q = 4'b0010;
       10'b100_1110100: q = 4'b0010;
       10'b100_1110101: q = 4'b0010;
       10'b100_1110110: q = 4'b0010;
       10'b100_1110111: q = 4'b0010;
       10'b100_1111000: q = 4'b0000;
       10'b100_1111001: q = 4'b0000;
       10'b100_1111010: q = 4'b0000;
       10'b100_1111011: q = 4'b0000;
       10'b100_1111100: q = 4'b0000;
       10'b100_1111101: q = 4'b0000;
       10'b100_1111110: q = 4'b0000;
       10'b100_1111111: q = 4'b0000;
       10'b101_0000000: q = 4'b0000;
       10'b101_0000001: q = 4'b0000;
       10'b101_0000010: q = 4'b0000;
       10'b101_0000011: q = 4'b0000;
       10'b101_0000100: q = 4'b0000;
       10'b101_0000101: q = 4'b0000;
       10'b101_0000110: q = 4'b0100;
       10'b101_0000111: q = 4'b0100;
       10'b101_0001000: q = 4'b0100;
       10'b101_0001001: q = 4'b0100;
       10'b101_0001010: q = 4'b0100;
       10'b101_0001011: q = 4'b0100;
       10'b101_0001100: q = 4'b0100;
       10'b101_0001101: q = 4'b0100;
       10'b101_0001110: q = 4'b0100;
       10'b101_0001111: q = 4'b0100;
       10'b101_0010000: q = 4'b0100;
       10'b101_0010001: q = 4'b0100;
       10'b101_0010010: q = 4'b0100;
       10'b101_0010011: q = 4'b0100;
       10'b101_0010100: q = 4'b1000;
       10'b101_0010101: q = 4'b1000;
       10'b101_0010110: q = 4'b1000;
       10'b101_0010111: q = 4'b1000;
       10'b101_0011000: q = 4'b1000;
       10'b101_0011001: q = 4'b1000;
       10'b101_0011010: q = 4'b1000;
       10'b101_0011011: q = 4'b1000;
       10'b101_0011100: q = 4'b1000;
       10'b101_0011101: q = 4'b1000;
       10'b101_0011110: q = 4'b1000;
       10'b101_0011111: q = 4'b1000;
       10'b101_0100000: q = 4'b1000;
       10'b101_0100001: q = 4'b1000;
       10'b101_0100010: q = 4'b1000;
       10'b101_0100011: q = 4'b1000;
       10'b101_0100100: q = 4'b1000;
       10'b101_0100101: q = 4'b1000;
       10'b101_0100110: q = 4'b1000;
       10'b101_0100111: q = 4'b1000;
       10'b101_0101000: q = 4'b1000;
       10'b101_0101001: q = 4'b1000;
       10'b101_0101010: q = 4'b1000;
       10'b101_0101011: q = 4'b1000;
       10'b101_0101100: q = 4'b1000;
       10'b101_0101101: q = 4'b1000;
       10'b101_0101110: q = 4'b1000;
       10'b101_0101111: q = 4'b1000;
       10'b101_0110000: q = 4'b1000;
       10'b101_0110001: q = 4'b1000;
       10'b101_0110010: q = 4'b1000;
       10'b101_0110011: q = 4'b1000;
       10'b101_0110100: q = 4'b1000;
       10'b101_0110101: q = 4'b1000;
       10'b101_0110110: q = 4'b1000;
       10'b101_0110111: q = 4'b1000;
       10'b101_0111000: q = 4'b1000;
       10'b101_0111001: q = 4'b1000;
       10'b101_0111010: q = 4'b1000;
       10'b101_0111011: q = 4'b1000;
       10'b101_0111100: q = 4'b1000;
       10'b101_0111101: q = 4'b1000;
       10'b101_0111110: q = 4'b1000;
       10'b101_0111111: q = 4'b1000;
       10'b101_1000000: q = 4'b0001;
       10'b101_1000001: q = 4'b0001;
       10'b101_1000010: q = 4'b0001;
       10'b101_1000011: q = 4'b0001;
       10'b101_1000100: q = 4'b0001;
       10'b101_1000101: q = 4'b0001;
       10'b101_1000110: q = 4'b0001;
       10'b101_1000111: q = 4'b0001;
       10'b101_1001000: q = 4'b0001;
       10'b101_1001001: q = 4'b0001;
       10'b101_1001010: q = 4'b0001;
       10'b101_1001011: q = 4'b0001;
       10'b101_1001100: q = 4'b0001;
       10'b101_1001101: q = 4'b0001;
       10'b101_1001110: q = 4'b0001;
       10'b101_1001111: q = 4'b0001;
       10'b101_1010000: q = 4'b0001;
       10'b101_1010001: q = 4'b0001;
       10'b101_1010010: q = 4'b0001;
       10'b101_1010011: q = 4'b0001;
       10'b101_1010100: q = 4'b0001;
       10'b101_1010101: q = 4'b0001;
       10'b101_1010110: q = 4'b0001;
       10'b101_1010111: q = 4'b0001;
       10'b101_1011000: q = 4'b0001;
       10'b101_1011001: q = 4'b0001;
       10'b101_1011010: q = 4'b0001;
       10'b101_1011011: q = 4'b0001;
       10'b101_1011100: q = 4'b0001;
       10'b101_1011101: q = 4'b0001;
       10'b101_1011110: q = 4'b0001;
       10'b101_1011111: q = 4'b0001;
       10'b101_1100000: q = 4'b0001;
       10'b101_1100001: q = 4'b0001;
       10'b101_1100010: q = 4'b0001;
       10'b101_1100011: q = 4'b0001;
       10'b101_1100100: q = 4'b0001;
       10'b101_1100101: q = 4'b0001;
       10'b101_1100110: q = 4'b0001;
       10'b101_1100111: q = 4'b0001;
       10'b101_1101000: q = 4'b0001;
       10'b101_1101001: q = 4'b0001;
       10'b101_1101010: q = 4'b0001;
       10'b101_1101011: q = 4'b0001;
       10'b101_1101100: q = 4'b0010;
       10'b101_1101101: q = 4'b0010;
       10'b101_1101110: q = 4'b0010;
       10'b101_1101111: q = 4'b0010;
       10'b101_1110000: q = 4'b0010;
       10'b101_1110001: q = 4'b0010;
       10'b101_1110010: q = 4'b0010;
       10'b101_1110011: q = 4'b0010;
       10'b101_1110100: q = 4'b0010;
       10'b101_1110101: q = 4'b0010;
       10'b101_1110110: q = 4'b0010;
       10'b101_1110111: q = 4'b0010;
       10'b101_1111000: q = 4'b0000;
       10'b101_1111001: q = 4'b0000;
       10'b101_1111010: q = 4'b0000;
       10'b101_1111011: q = 4'b0000;
       10'b101_1111100: q = 4'b0000;
       10'b101_1111101: q = 4'b0000;
       10'b101_1111110: q = 4'b0000;
       10'b101_1111111: q = 4'b0000;
       10'b110_0000000: q = 4'b0000;
       10'b110_0000001: q = 4'b0000;
       10'b110_0000010: q = 4'b0000;
       10'b110_0000011: q = 4'b0000;
       10'b110_0000100: q = 4'b0000;
       10'b110_0000101: q = 4'b0000;
       10'b110_0000110: q = 4'b0000;
       10'b110_0000111: q = 4'b0000;
       10'b110_0001000: q = 4'b0100;
       10'b110_0001001: q = 4'b0100;
       10'b110_0001010: q = 4'b0100;
       10'b110_0001011: q = 4'b0100;
       10'b110_0001100: q = 4'b0100;
       10'b110_0001101: q = 4'b0100;
       10'b110_0001110: q = 4'b0100;
       10'b110_0001111: q = 4'b0100;
       10'b110_0010000: q = 4'b0100;
       10'b110_0010001: q = 4'b0100;
       10'b110_0010010: q = 4'b0100;
       10'b110_0010011: q = 4'b0100;
       10'b110_0010100: q = 4'b1000;
       10'b110_0010101: q = 4'b1000;
       10'b110_0010110: q = 4'b1000;
       10'b110_0010111: q = 4'b1000;
       10'b110_0011000: q = 4'b1000;
       10'b110_0011001: q = 4'b1000;
       10'b110_0011010: q = 4'b1000;
       10'b110_0011011: q = 4'b1000;
       10'b110_0011100: q = 4'b1000;
       10'b110_0011101: q = 4'b1000;
       10'b110_0011110: q = 4'b1000;
       10'b110_0011111: q = 4'b1000;
       10'b110_0100000: q = 4'b1000;
       10'b110_0100001: q = 4'b1000;
       10'b110_0100010: q = 4'b1000;
       10'b110_0100011: q = 4'b1000;
       10'b110_0100100: q = 4'b1000;
       10'b110_0100101: q = 4'b1000;
       10'b110_0100110: q = 4'b1000;
       10'b110_0100111: q = 4'b1000;
       10'b110_0101000: q = 4'b1000;
       10'b110_0101001: q = 4'b1000;
       10'b110_0101010: q = 4'b1000;
       10'b110_0101011: q = 4'b1000;
       10'b110_0101100: q = 4'b1000;
       10'b110_0101101: q = 4'b1000;
       10'b110_0101110: q = 4'b1000;
       10'b110_0101111: q = 4'b1000;
       10'b110_0110000: q = 4'b1000;
       10'b110_0110001: q = 4'b1000;
       10'b110_0110010: q = 4'b1000;
       10'b110_0110011: q = 4'b1000;
       10'b110_0110100: q = 4'b1000;
       10'b110_0110101: q = 4'b1000;
       10'b110_0110110: q = 4'b1000;
       10'b110_0110111: q = 4'b1000;
       10'b110_0111000: q = 4'b1000;
       10'b110_0111001: q = 4'b1000;
       10'b110_0111010: q = 4'b1000;
       10'b110_0111011: q = 4'b1000;
       10'b110_0111100: q = 4'b1000;
       10'b110_0111101: q = 4'b1000;
       10'b110_0111110: q = 4'b1000;
       10'b110_0111111: q = 4'b1000;
       10'b110_1000000: q = 4'b0001;
       10'b110_1000001: q = 4'b0001;
       10'b110_1000010: q = 4'b0001;
       10'b110_1000011: q = 4'b0001;
       10'b110_1000100: q = 4'b0001;
       10'b110_1000101: q = 4'b0001;
       10'b110_1000110: q = 4'b0001;
       10'b110_1000111: q = 4'b0001;
       10'b110_1001000: q = 4'b0001;
       10'b110_1001001: q = 4'b0001;
       10'b110_1001010: q = 4'b0001;
       10'b110_1001011: q = 4'b0001;
       10'b110_1001100: q = 4'b0001;
       10'b110_1001101: q = 4'b0001;
       10'b110_1001110: q = 4'b0001;
       10'b110_1001111: q = 4'b0001;
       10'b110_1010000: q = 4'b0001;
       10'b110_1010001: q = 4'b0001;
       10'b110_1010010: q = 4'b0001;
       10'b110_1010011: q = 4'b0001;
       10'b110_1010100: q = 4'b0001;
       10'b110_1010101: q = 4'b0001;
       10'b110_1010110: q = 4'b0001;
       10'b110_1010111: q = 4'b0001;
       10'b110_1011000: q = 4'b0001;
       10'b110_1011001: q = 4'b0001;
       10'b110_1011010: q = 4'b0001;
       10'b110_1011011: q = 4'b0001;
       10'b110_1011100: q = 4'b0001;
       10'b110_1011101: q = 4'b0001;
       10'b110_1011110: q = 4'b0001;
       10'b110_1011111: q = 4'b0001;
       10'b110_1100000: q = 4'b0001;
       10'b110_1100001: q = 4'b0001;
       10'b110_1100010: q = 4'b0001;
       10'b110_1100011: q = 4'b0001;
       10'b110_1100100: q = 4'b0001;
       10'b110_1100101: q = 4'b0001;
       10'b110_1100110: q = 4'b0001;
       10'b110_1100111: q = 4'b0001;
       10'b110_1101000: q = 4'b0001;
       10'b110_1101001: q = 4'b0001;
       10'b110_1101010: q = 4'b0010;
       10'b110_1101011: q = 4'b0010;
       10'b110_1101100: q = 4'b0010;
       10'b110_1101101: q = 4'b0010;
       10'b110_1101110: q = 4'b0010;
       10'b110_1101111: q = 4'b0010;
       10'b110_1110000: q = 4'b0010;
       10'b110_1110001: q = 4'b0010;
       10'b110_1110010: q = 4'b0010;
       10'b110_1110011: q = 4'b0010;
       10'b110_1110100: q = 4'b0010;
       10'b110_1110101: q = 4'b0010;
       10'b110_1110110: q = 4'b0010;
       10'b110_1110111: q = 4'b0010;
       10'b110_1111000: q = 4'b0000;
       10'b110_1111001: q = 4'b0000;
       10'b110_1111010: q = 4'b0000;
       10'b110_1111011: q = 4'b0000;
       10'b110_1111100: q = 4'b0000;
       10'b110_1111101: q = 4'b0000;
       10'b110_1111110: q = 4'b0000;
       10'b110_1111111: q = 4'b0000;
       10'b111_0000000: q = 4'b0000;
       10'b111_0000001: q = 4'b0000;
       10'b111_0000010: q = 4'b0000;
       10'b111_0000011: q = 4'b0000;
       10'b111_0000100: q = 4'b0000;
       10'b111_0000101: q = 4'b0000;
       10'b111_0000110: q = 4'b0000;
       10'b111_0000111: q = 4'b0000;
       10'b111_0001000: q = 4'b0100;
       10'b111_0001001: q = 4'b0100;
       10'b111_0001010: q = 4'b0100;
       10'b111_0001011: q = 4'b0100;
       10'b111_0001100: q = 4'b0100;
       10'b111_0001101: q = 4'b0100;
       10'b111_0001110: q = 4'b0100;
       10'b111_0001111: q = 4'b0100;
       10'b111_0010000: q = 4'b0100;
       10'b111_0010001: q = 4'b0100;
       10'b111_0010010: q = 4'b0100;
       10'b111_0010011: q = 4'b0100;
       10'b111_0010100: q = 4'b0100;
       10'b111_0010101: q = 4'b0100;
       10'b111_0010110: q = 4'b0100;
       10'b111_0010111: q = 4'b0100;
       10'b111_0011000: q = 4'b1000;
       10'b111_0011001: q = 4'b1000;
       10'b111_0011010: q = 4'b1000;
       10'b111_0011011: q = 4'b1000;
       10'b111_0011100: q = 4'b1000;
       10'b111_0011101: q = 4'b1000;
       10'b111_0011110: q = 4'b1000;
       10'b111_0011111: q = 4'b1000;
       10'b111_0100000: q = 4'b1000;
       10'b111_0100001: q = 4'b1000;
       10'b111_0100010: q = 4'b1000;
       10'b111_0100011: q = 4'b1000;
       10'b111_0100100: q = 4'b1000;
       10'b111_0100101: q = 4'b1000;
       10'b111_0100110: q = 4'b1000;
       10'b111_0100111: q = 4'b1000;
       10'b111_0101000: q = 4'b1000;
       10'b111_0101001: q = 4'b1000;
       10'b111_0101010: q = 4'b1000;
       10'b111_0101011: q = 4'b1000;
       10'b111_0101100: q = 4'b1000;
       10'b111_0101101: q = 4'b1000;
       10'b111_0101110: q = 4'b1000;
       10'b111_0101111: q = 4'b1000;
       10'b111_0110000: q = 4'b1000;
       10'b111_0110001: q = 4'b1000;
       10'b111_0110010: q = 4'b1000;
       10'b111_0110011: q = 4'b1000;
       10'b111_0110100: q = 4'b1000;
       10'b111_0110101: q = 4'b1000;
       10'b111_0110110: q = 4'b1000;
       10'b111_0110111: q = 4'b1000;
       10'b111_0111000: q = 4'b1000;
       10'b111_0111001: q = 4'b1000;
       10'b111_0111010: q = 4'b1000;
       10'b111_0111011: q = 4'b1000;
       10'b111_0111100: q = 4'b1000;
       10'b111_0111101: q = 4'b1000;
       10'b111_0111110: q = 4'b1000;
       10'b111_0111111: q = 4'b1000;
       10'b111_1000000: q = 4'b0001;
       10'b111_1000001: q = 4'b0001;
       10'b111_1000010: q = 4'b0001;
       10'b111_1000011: q = 4'b0001;
       10'b111_1000100: q = 4'b0001;
       10'b111_1000101: q = 4'b0001;
       10'b111_1000110: q = 4'b0001;
       10'b111_1000111: q = 4'b0001;
       10'b111_1001000: q = 4'b0001;
       10'b111_1001001: q = 4'b0001;
       10'b111_1001010: q = 4'b0001;
       10'b111_1001011: q = 4'b0001;
       10'b111_1001100: q = 4'b0001;
       10'b111_1001101: q = 4'b0001;
       10'b111_1001110: q = 4'b0001;
       10'b111_1001111: q = 4'b0001;
       10'b111_1010000: q = 4'b0001;
       10'b111_1010001: q = 4'b0001;
       10'b111_1010010: q = 4'b0001;
       10'b111_1010011: q = 4'b0001;
       10'b111_1010100: q = 4'b0001;
       10'b111_1010101: q = 4'b0001;
       10'b111_1010110: q = 4'b0001;
       10'b111_1010111: q = 4'b0001;
       10'b111_1011000: q = 4'b0001;
       10'b111_1011001: q = 4'b0001;
       10'b111_1011010: q = 4'b0001;
       10'b111_1011011: q = 4'b0001;
       10'b111_1011100: q = 4'b0001;
       10'b111_1011101: q = 4'b0001;
       10'b111_1011110: q = 4'b0001;
       10'b111_1011111: q = 4'b0001;
       10'b111_1100000: q = 4'b0001;
       10'b111_1100001: q = 4'b0001;
       10'b111_1100010: q = 4'b0001;
       10'b111_1100011: q = 4'b0001;
       10'b111_1100100: q = 4'b0001;
       10'b111_1100101: q = 4'b0001;
       10'b111_1100110: q = 4'b0001;
       10'b111_1100111: q = 4'b0001;
       10'b111_1101000: q = 4'b0010;
       10'b111_1101001: q = 4'b0010;
       10'b111_1101010: q = 4'b0010;
       10'b111_1101011: q = 4'b0010;
       10'b111_1101100: q = 4'b0010;
       10'b111_1101101: q = 4'b0010;
       10'b111_1101110: q = 4'b0010;
       10'b111_1101111: q = 4'b0010;
       10'b111_1110000: q = 4'b0010;
       10'b111_1110001: q = 4'b0010;
       10'b111_1110010: q = 4'b0010;
       10'b111_1110011: q = 4'b0010;
       10'b111_1110100: q = 4'b0010;
       10'b111_1110101: q = 4'b0010;
       10'b111_1110110: q = 4'b0010;
       10'b111_1110111: q = 4'b0010;
       10'b111_1111000: q = 4'b0000;
       10'b111_1111001: q = 4'b0000;
       10'b111_1111010: q = 4'b0000;
       10'b111_1111011: q = 4'b0000;
       10'b111_1111100: q = 4'b0000;
       10'b111_1111101: q = 4'b0000;
       10'b111_1111110: q = 4'b0000;
       10'b111_1111111: q = 4'b0000;
     endcase

endmodule // qst4

// FSM Control for Integer Divider
module fsm64 #(parameter WIDTH=7)
  (en, state0, done, otfzero, start, error, NumIter, clk, reset);

   input logic [WIDTH-1:0]  NumIter;   
   input logic 		    clk;
   input logic 		    reset;
   input logic 		    start;
   input logic 		    error;   
   
   output logic 	    done;      
   output logic 	    en;
   output logic 	    state0;
   output logic 	    otfzero;   
   
   logic 		    LT, EQ;
   
   typedef enum logic [6:0]  {S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
			      S10, S11, S12, S13, S14, S15, S16, S17, S18, S19,
			      S20, S21, S22, S23, S24, S25, S26, S27, S28, S29,
			      S30, S31, S32, S33, S34, S35, S36, S37, S38, S39,
			      S40, S41, S42, S43, S44, S45, S46, S47, S48, S49,
			      S50, S51, S52, S53, S54, S55, S56, S57, S58, S59,
			      S60, S61, S62, S63, S64, S65, S66, S67, S68, S69,
			      S70, S71, S72, S73, S74, S75, S76, S77, S78, S79,
			      S80, S81, S82, S83, S84, S85, S86, S87, S88, S89,
			      S90, S91, S92, S93, S94, S95, S96, S97, S98, S99,
			      S100, S101, S102, S103, S104, S105, S106, S107, S108, S109,
			      Done} statetype;
   
   statetype CURRENT_STATE, NEXT_STATE;

   always @(posedge clk)
     begin
	if(reset==1'b1)
	  CURRENT_STATE<=S0;
	else
	  CURRENT_STATE<=NEXT_STATE;
     end

   // Cheated and made 8 - let synthesis do its magic
   magcompare8 comp1 (LT, EQ, {1'h0, CURRENT_STATE}, {{8-WIDTH{1'b0}}, NumIter});

   always @(CURRENT_STATE or start)
     begin
 	case(CURRENT_STATE)
	  S0:
	    begin
	       if (start==1'b0)
		 begin
		    otfzero = 1'b1;   
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S0;
		 end 
	       else 
		 begin
		    otfzero = 1'b0;	       		    
		    en = 1'b1;
		    state0 = 1'b1;
		    done = 1'b0;
		    NEXT_STATE <= S1;
		 end 
	    end	    
	  S1:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S2;
		 end
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    
	    end // case: S1	  
	  S2:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S3;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S2
	  S3:
	    begin	       
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S4;
		 end 
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       
	    end // case: S3
	  S4:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S5;
		 end 	       	    
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		       	       
	    end // case: S4
	  S5:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S6;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       	       
	    end // case: S5
	  S6:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S7;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S6
	  S7:
	    begin
	       otfzero = 1'b0;	     
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S8;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S7
	  S8:
	    begin
	       otfzero = 1'b0;	     
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S9;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S8
	  S9:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S10;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S9
	  S10:
	    begin
	       otfzero = 1'b0;	      
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S11;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S10
	  S11:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S12;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S11
	  S12:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S13;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S12
	  S13:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S14;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S13
	  S14:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S15;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S14
	  S15:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S16;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S15
	  S16:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S17;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S16
	  S17:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S18;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S17
	  S18:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S19;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S18
	  S19:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S20;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S19
	  S20:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S21;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S20
	  S21:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S22;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S21
	  S22:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S23;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S22
	  S23:
	    begin
	       otfzero = 1'b0;
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S24;		    
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S23 
	  S24:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S25;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S24
	  S25:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S26;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S25
	  S26:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S27;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S26
	  S27:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S28;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S27
	  S28:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S29;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S28
	  S29:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S30;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S29
	  S30:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S31;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S30
	  S31:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S32;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S31  
	  S32:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S33;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S32
	  S33:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S34;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S33
	  S34:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S35;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S34  	  
	  S35:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S36;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S35
	  S36:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S37;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S36
	  S37:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S38;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S37
	  S38:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S39;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S38
	  S39:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S40;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S39
	  S40:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S41;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S40
	  S41:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S42;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S41
	  S42:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S43;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S42
	  S43:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S44;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S43
	  S44:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S45;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S44
	  S45:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S46;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S45
	  S46:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S47;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S46
	  S47:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S48;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S47
	  S48:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S49;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S48
	  S49:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S50;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S49
	  S50:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S51;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S50
	  S51:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S52;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S51
	  S52:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S53;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S52
	  S53:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S54;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S53
	  S54:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S55;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S54
	  S55:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S56;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S55
	  S56:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S57;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S56
	  S57:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S58;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S57
	  S58:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S59;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S58
	  S59:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S60;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S59
	  S60:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S61;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S60
	  S61:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S62;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S61
	  S62:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S63;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S62
	  S63:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S64;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S63
	  S64:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= S65;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S64
	  S65:
	    begin
	       otfzero = 1'b0;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    NEXT_STATE <= Done;
		 end		    	       	       
	    end // case: S65
	  Done:
	    begin
	       otfzero = 1'b1;	       	       	       
	       state0 = 1'b0;
	       done = 1'b1;
	       if (EQ)
		 begin
		    en = 1'b1;
		 end
	       else
		 begin
		    en = 1'b0;
		 end
	       NEXT_STATE <= S0;
	    end // case: Done
	  default: 
	    begin
	       otfzero = 1'b0;	       
	       en = 1'b0;
	       state0 = 1'b0;
	       done = 1'b0;
	       NEXT_STATE <= S0;
	    end
	endcase // case(CURRENT_STATE)	
     end // always @ (CURRENT_STATE or X)   

endmodule // fsm64

// 2-bit magnitude comparator
// This module compares two 2-bit values A and B. LT is '1' if A < B 
// and GT is '1'if A > B. LT and GT are both '0' if A = B.

module magcompare2b (LT, GT, A, B);

   input logic [1:0] A;
   input logic [1:0] B;
   
   output logic      LT;
   output logic      GT;
   
   // Determine if A < B  using a minimized sum-of-products expression
   assign LT = ~A[1]&B[1] | ~A[1]&~A[0]&B[0] | ~A[0]&B[1]&B[0];
   // Determine if A > B  using a minimized sum-of-products expression
   assign GT = A[1]&~B[1] | A[1]&A[0]&~B[0] | A[0]&~B[1]&~B[0];

endmodule // magcompare2b

// J. E. Stine and M. J. Schulte, "A combined two's complement and
// floating-point comparator," 2005 IEEE International Symposium on
// Circuits and Systems, Kobe, 2005, pp. 89-92 Vol. 1. 
// doi: 10.1109/ISCAS.2005.1464531

module magcompare8 (LT, EQ, A, B);

   input logic [7:0]  A;
   input logic [7:0]  B;
   
   logic [3:0] 	      s;
   logic [3:0] 	      t;
   logic [1:0] 	      u;
   logic [1:0] 	      v;
   logic 	      GT;
   //wire 	LT;   
   
   output logic       EQ;
   output logic       LT;   
   
   magcompare2b mag1 (s[0], t[0], A[1:0], B[1:0]);
   magcompare2b mag2 (s[1], t[1], A[3:2], B[3:2]);
   magcompare2b mag3 (s[2], t[2], A[5:4], B[5:4]);
   magcompare2b mag4 (s[3], t[3], A[7:6], B[7:6]);
   
   magcompare2b mag5 (u[0], v[0], t[1:0], s[1:0]);
   magcompare2b mag6 (u[1], v[1], t[3:2], s[3:2]);

   magcompare2b mag7 (LT, GT, v[1:0], u[1:0]);
   
   assign EQ = ~(GT | LT);   

endmodule // magcompare8

module exception_int #(parameter WIDTH=8) 
   (Q, rem, op1, S, div0, Max_N, D_NegOne, Qf, remf);

   input logic [WIDTH-1:0] Q;
   input logic [WIDTH-1:0] rem;
   input logic [WIDTH-1:0] op1;      
   input logic 		   S;
   input logic 		   div0;
   input logic 		   Max_N;
   input logic 		   D_NegOne;
   
   output logic [WIDTH-1:0] Qf;
   output logic [WIDTH-1:0] remf;

   always_comb
     case ({div0, S, Max_N, D_NegOne})
       4'b0000 : Qf = Q;
       4'b0001 : Qf = Q;
       4'b0010 : Qf = Q;       
       4'b0011 : Qf = Q;
       4'b0100 : Qf = Q;
       4'b0101 : Qf = Q;       
       4'b0110 : Qf = Q;       
       4'b0111 : Qf = {1'b1, {WIDTH-1{1'h0}}};       
       4'b1000 : Qf = {WIDTH{1'b1}};
       4'b1001 : Qf = {WIDTH{1'b1}};
       4'b1010 : Qf = {WIDTH{1'b1}};
       4'b1011 : Qf = {WIDTH{1'b1}};       
       4'b1100 : Qf = {WIDTH{1'b1}};
       4'b1101 : Qf = {WIDTH{1'b1}};
       4'b1110 : Qf = {WIDTH{1'b1}};
       4'b1111 : Qf = {WIDTH{1'b1}};       
       default: Qf = Q;       
     endcase 

   always_comb
     case ({div0, S, Max_N, D_NegOne})
       4'b0000 : remf = rem;
       4'b0001 : remf = rem;
       4'b0010 : remf = rem;       
       4'b0011 : remf = rem;
       4'b0100 : remf = rem;
       4'b0101 : remf = rem;
       4'b0110 : remf = rem;
       4'b0111 : remf = {WIDTH{1'h0}};
       4'b1000 : remf = op1;
       4'b1001 : remf = op1;
       4'b1010 : remf = op1;
       4'b1011 : remf = op1;       
       4'b1100 : remf = op1;
       4'b1101 : remf = op1;       
       4'b1110 : remf = op1;       
       4'b1111 : remf = op1;              
       default: remf = rem;
     endcase 

endmodule // exception_int

/* verilator lint_on COMBDLY */
/* verilator lint_on IMPLICIT */
