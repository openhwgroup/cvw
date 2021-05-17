///////////////////////////////////////////
// mul.sv
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


module div (Qf, remf, done, divBusy, div0, N, D, clk, reset, start);

   input logic [63:0]  N, D;
   input logic 	       clk;
   input logic 	       reset;
   input logic 	       start;
   
   output logic [63:0] Qf;
   output logic [63:0] remf;
   output logic        div0;
   output logic        done;
   output logic        divBusy;   

   logic 	       divdone;   
   logic 	       enable;
   logic 	       state0;
   logic 	       V;   
   logic [7:0] 	       Num;
   logic [5:0] 	       P, NumIter, RemShift;
   logic [63:0]        op1, op2, op1shift, Rem5;
   logic [64:0]        Qd, Rd, Qd2, Rd2;
   logic [63:0]        Q, rem0;
   logic [3:0] 	       quotient;
   logic 	       otfzero; 
   logic 	       shiftResult;
   logic 	       enablev, state0v, donev, divdonev, oftzerov, divBusyv, ulp;

   // Divider goes the distance to 37 cycles
   // (thanks the evil divisor for D = 0x1) 
   // but could theoretically be stopped when
   // divdone is asserted.  The enable signal
   // turns off register storage thus invalidating
   // any future cycles.
   
   // Shift D, if needed (for integer)
   // needed to allow qst to be in range for integer
   // division [1,2) and allow integer divide to work.
   //
   // The V or valid bit can be used to determine if D
   // is 0 and thus a divide by 0 exception.  This div0
   // exception is given to FSM to tell the operation to 
   // quit gracefully.

   // div0 produced output  errors have untested results
   // (it is assumed the OS would handle some output)
   
   lz64 p1 (P, V, D);
   shifter_l64 p2 (op2, D, P);
   assign op1 = N;
   assign div0 = ~V;

   // #iter: N = m+v+s = m+(s+2) = m+2+s (mod k = 0)
   // v = 2 since \rho < 1 (add 4 to make sure its a ceil)
   adder #(8) cpa1 ({2'b0, P}, 
		    {5'h0, shiftResult, ~shiftResult, 1'b0}, 
		    Num);      
   
   // Determine whether need to add just Q/Rem
   assign shiftResult = P[0];   
   // div by 2 (ceil)
   assign NumIter = Num[6:1];   
   assign RemShift = P;

   // FSM to control integer divider
   //   assume inputs are postive edge and
   //   datapath (divider) is negative edge
   fsm64 fsm1 (enablev, state0v, donev, divdonev, otfzerov, divBusyv,
	       start, div0, NumIter, ~clk, reset);

   flopr #(1) rega (~clk, reset, donev, done);
   flopr #(1) regb (~clk, reset, divdonev, divdone);
   flopr #(1) regc (~clk, reset, otfzerov, otfzero);
   flopr #(1) regd (~clk, reset, enablev, enable);
   flopr #(1) rege (~clk, reset, state0v, state0);
   flopr #(1) regf (~clk, reset, divBusyv, divBusy);      
   
   // To obtain a correct remainder the last bit of the
   // quotient has to be aligned with a radix-r boundary.
   // Since the quotient is in the range 1/2 < q < 2 (one
   // integer bit and m fractional bits), this is achieved by
   // shifting N right by v+s so that (m+v+s) mod k = 0.  And,
   // the quotient has to be aligned to the integer position.

   // Actual divider unit FIXME: r16 (jes)
   divide4x64 p3 (Qd, Rd, quotient, op1, op2, clk, reset, state0, 
		  enable, otfzero, shiftResult);

   // Storage registers to hold contents stable
   flopenr #(65) reg3 (clk, reset, enable, Rd, Rd2);
   flopenr #(65) reg4 (clk, reset, enable, Qd, Qd2);         

   // Probably not needed - just assigns results
   assign Q = Qd2[63:0];
   assign Rem5 = Rd2[64:1];  
   
   // Adjust remainder by m (no need to adjust by
   // n ln(r)
   shifter_r64 p4 (rem0, Rem5, RemShift);

   // RISC-V has exceptions for divide by 0 (Table 6.1 of SPEC)
   mux2 #(64) exc1 (Q, {64{1'b1}}, div0, Qf);
   mux2 #(64) exc2 (rem0, op1, div0, remf);   

endmodule // int32div

module divide4x64 (Q, rem0, quotient, op1, op2, clk, reset, state0, 
		   enable, otfzero, shiftResult); 

   input logic [63:0]   op1, op2;
   input logic 		clk, state0;
   input logic 		reset;
   input logic 		enable;
   input logic 		otfzero;
   input logic 		shiftResult;   
   
   output logic [64:0] 	rem0;
   output logic [64:0] 	Q;
   output logic [3:0] 	quotient;   

   logic [67:0] 	Sum, Carry;   
   logic [64:0] 	Qstar;   
   logic [64:0] 	QMstar;   
   logic [7:0] 		qtotal;   
   logic [67:0] 	SumN, CarryN, SumN2, CarryN2;
   logic [67:0] 	divi1, divi2, divi1c, divi2c, dive1;
   logic [67:0] 	mdivi_temp, mdivi;   
   logic 		zero;
   logic [1:0] 		qsel;
   logic [1:0] 		Qin, QMin;
   logic 		CshiftQ, CshiftQM;
   logic [67:0] 	rem1, rem2, rem3;
   logic [67:0] 	SumR, CarryR;
   logic [64:0] 	Qt;   

   // Create one's complement values of Divisor (for q*D)
   assign divi1 = {3'h0, op2, 1'b0};
   assign divi2 = {2'h0, op2, 2'b0};
   assign divi1c = ~divi1;
   assign divi2c = ~divi2;
   // Shift x1 if not mod k
   mux2 #(68) mx1 ({3'b000, op1, 1'b0},  {4'h0, op1}, shiftResult, dive1);   

   // I I I . F F F F F ... (Robertson Criteria - \rho * qmax * D)
   mux2 #(68) mx2 ({CarryN2[65:0], 2'h0}, 68'h0, state0, CarryN);
   mux2 #(68) mx3 ({SumN2[65:0], 2'h0}, dive1, state0, SumN);
   // Simplify QST
   adder #(8) cpa1 (SumN[67:60], CarryN[67:60], qtotal);   
   // q = {+2, +1, -1, -2} else q = 0
   qst4 pd1 (qtotal[7:1], divi1[63:61], quotient);
   assign ulp = quotient[2]|quotient[3];
   assign zero = ~(quotient[3]|quotient[2]|quotient[1]|quotient[0]);
   // Map to binary encoding
   assign qsel[1] = quotient[3]|quotient[2];
   assign qsel[0] = quotient[3]|quotient[1];   
   mux4 #(68) mx4 (divi2, divi1, divi1c, divi2c, qsel, mdivi_temp);
   mux2 #(68) mx5 (mdivi_temp, 68'h0, zero, mdivi);
   csa #(68) csa1 (mdivi, SumN, {CarryN[67:1], ulp}, Sum, Carry);
   // regs : save CSA
   flopenr #(68) reg1 (clk, reset, enable, Sum, SumN2);
   flopenr #(68) reg2 (clk, reset, enable, Carry, CarryN2);
   // OTF
   ls_control otf1 (quotient, Qin, QMin, CshiftQ, CshiftQM);   
   otf #(65) otf2 (Qin, QMin, CshiftQ, CshiftQM, clk, 
		   otfzero, enable, Qstar, QMstar);

   // Correction and generation of Remainder
   adder #(68) cpa2 (SumN2[67:0], CarryN2[67:0], rem1);
   // Add back +D as correction
   csa #(68) csa2 (CarryN2[67:0], SumN2[67:0], divi1, SumR, CarryR);
   adder #(68) cpa3 (SumR, CarryR, rem2);   
   // Choose remainder (Rem or Rem+D)
   mux2 #(68) mx6 (rem1, rem2, rem1[67], rem3);
   // Choose correct Q or QM
   mux2 #(65) mx7 (Qstar, QMstar, rem1[67], Qt);
   // Final results
   assign rem0 = rem3[64:0];
   assign Q = Qt;   
   
endmodule // divide4x64

module ls_control (quot, Qin, QMin, CshiftQ, CshiftQM);

   input logic [3:0] quot;

   output logic [1:0] Qin;
   output logic [1:0] QMin;
   output logic       CshiftQ;
   output logic       CshiftQM;

   // Load/Store Control for OTF
   assign Qin[1] = (quot[1]) | (quot[3]) | (quot[0]);
   assign Qin[0] = (quot[1]) | (quot[2]);
   assign QMin[1] = (quot[1]) | (!quot[3]&!quot[2]&!quot[1]&!quot[0]);
   assign QMin[0] = (quot[3]) | (quot[0]) | 
		    (!quot[3]&!quot[2]&!quot[1]&!quot[0]);
   assign CshiftQ = (quot[1]) | (quot[0]);
   assign CshiftQM = (quot[3]) | (quot[2]);   

endmodule 

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

endmodule // otf8

module adder #(parameter WIDTH=8) (input logic [WIDTH-1:0] a, b,
				   output logic [WIDTH-1:0] y);

   assign y = a + b;

endmodule // adder

module fa (input logic a, b, c, output logic sum, carry);

   assign sum = a^b^c;
   assign carry = a&b|a&c|b&c;   

endmodule // fa

module csa #(parameter WIDTH=8) (input logic [WIDTH-1:0] a, b, c,
				 output logic [WIDTH-1:0] sum, carry);

   logic [WIDTH:0] 					  carry_temp;   
   genvar 						  i;
   generate
      for (i=0;i<WIDTH;i=i+1)
	begin : genbit
	   fa fa_inst (a[i], b[i], c[i], sum[i], carry_temp[i+1]);
	end
   endgenerate
   //assign carry = {1'b0, carry_temp[WIDTH-1:1], 1'b0};     // trmimmed excess bit dh 5/3/21
   assign carry = {carry_temp[WIDTH-1:1], 1'b0};     

endmodule // adder

module eqcmp #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] a, b,
    output logic y);
   
   assign y = (a == b);
   
endmodule // eqcmp

module qst4 (input logic [6:0] s, input logic [2:0] d,
	     output logic [3:0] q);
   
   
   assign q[3] = (!s[6]&s[5]) | (!d[2]&!s[6]&s[4]) | (!s[6]&s[4]&s[3]) | 
		 (!d[1]&!s[6]&s[4]&s[2]) | (!d[0]&!s[6]&s[4]&s[2]) | 
		 (!d[1]&!d[0]&!s[6]&s[4]&s[1]) | 
		 (!d[2]&!d[1]&!d[0]&!s[6]&s[3]&s[2]) | 
		 (!d[2]&!d[1]&!s[6]&s[3]&s[2]&s[1]) | 
		 (!d[2]&!d[0]&!s[6]&s[3]&s[2]&s[1]&s[0]);
   
   assign q[2] = (d[2]&!s[6]&!s[5]&!s[4]&s[3]) | 
		 (!s[6]&!s[5]&!s[4]&s[3]&!s[2]) | 
		 (!d[2]&!s[6]&!s[5]&!s[4]&!s[3]&s[2]) | 
		 (d[2]&d[1]&d[0]&!s[6]&!s[5]&s[4]&!s[3]) | 
		 (d[2]&d[1]&!s[6]&!s[5]&s[4]&!s[3]&!s[2]) | 
		 (d[2]&d[0]&!s[6]&!s[5]&s[4]&!s[3]&!s[2]) | 
		 (d[2]&!s[6]&!s[5]&s[4]&!s[3]&!s[2]&!s[1]) | 
		 (!d[2]&d[1]&d[0]&!s[6]&!s[5]&!s[4]&s[2]) | 
		 (!d[1]&!s[6]&!s[5]&!s[4]&!s[3]&s[2]&s[1]) | 
		 (!d[2]&d[1]&!s[6]&!s[5]&!s[4]&s[2]&!s[1]) | 
		 (!d[2]&d[0]&!s[6]&!s[5]&!s[4]&s[2]&!s[1]) | 
		 (!d[2]&d[1]&!s[6]&!s[5]&!s[4]&s[2]&!s[0]);
   
   assign q[1] = (d[2]&s[6]&s[5]&s[4]&!s[3]) | 
		 (d[1]&s[6]&s[5]&s[4]&!s[3]) | (s[6]&s[5]&s[4]&!s[3]&s[2]) | 
		 (d[2]&s[6]&s[5]&!s[4]&s[3]&s[2]) | 
		 (d[0]&s[6]&s[5]&s[4]&!s[3]&s[1]) | 
		 (d[2]&d[1]&d[0]&s[6]&s[5]&!s[4]&s[3]) | 
		 (d[2]&d[1]&s[6]&s[5]&!s[4]&s[3]&s[1]) | 
		 (!d[2]&s[6]&s[5]&s[4]&s[3]&!s[2]&!s[1]) | 
		 (!d[2]&!d[1]&!d[0]&s[6]&s[5]&s[4]&s[3]&!s[2]) | 
		 (d[1]&d[0]&s[6]&s[5]&!s[4]&s[3]&s[2]&s[1]) | 
		 (!d[2]&d[0]&s[6]&s[5]&s[4]&!s[2]&!s[1]&s[0]) | 
		 (!d[2]&!d[1]&!d[0]&s[6]&s[5]&s[4]&!s[2]&s[1]&s[0]);
   
   assign q[0] = (s[6]&!s[5]) | (s[6]&!s[4]&!s[3]) | 
		 (!d[2]&!d[1]&s[6]&!s[4]) | (!d[2]&!d[0]&s[6]&!s[4]) | 
		 (!d[2]&s[6]&!s[4]&!s[2]) | (!d[1]&s[6]&!s[4]&!s[2]) | 
		 (!d[2]&s[6]&!s[4]&!s[1]) | (!d[0]&s[6]&!s[4]&!s[2]&!s[1]) | 
		 (!d[2]&!d[1]&!d[0]&s[6]&!s[3]&!s[2]&!s[1]) | 
		 (!d[2]&!d[1]&!d[0]&s[6]&!s[3]&!s[2]&!s[0]) | 
		 (!d[2]&!d[1]&s[6]&!s[3]&!s[2]&!s[1]&!s[0]);
   
endmodule // qst4

// LZD

module lz2 (P, V, B0, B1);

   input logic  B0;
   input logic 	B1;

   output logic P;
   output logic V;

   assign V = B0 | B1;
   assign P = B0 & ~B1;
   
endmodule // lz2

module lz4 (ZP, ZV, B0, B1, V0, V1);
   
   input logic        B0;
   input logic        B1;
   input logic        V0;
   input logic        V1;
   
   output logic [1:0] ZP;
   output logic       ZV;
   
   assign ZP[0] = V0 ? B0 : B1;
   assign ZP[1] = ~V0;
   assign ZV = V0 | V1;

endmodule // lz4

module lz8 (ZP, ZV, B);
   
   input logic [7:0]  B;

   logic 	      s1p0;
   logic 	      s1v0;
   logic 	      s1p1;
   logic 	      s1v1;
   logic 	      s2p0;
   logic 	      s2v0;
   logic 	      s2p1;
   logic 	      s2v1;
   logic [1:0] 	      ZPa;
   logic [1:0] 	      ZPb;
   logic 	      ZVa;
   logic 	      ZVb;
   
   output logic [2:0] ZP;
   output logic       ZV;
   
   lz2 l1(s1p0, s1v0, B[2], B[3]);
   lz2 l2(s1p1, s1v1, B[0], B[1]);
   lz4 l3(ZPa, ZVa, s1p0, s1p1, s1v0, s1v1);

   lz2 l4(s2p0, s2v0, B[6], B[7]);
   lz2 l5(s2p1, s2v1, B[4], B[5]);
   lz4 l6(ZPb, ZVb, s2p0, s2p1, s2v0, s2v1);

   assign ZP[1:0] = ZVb ? ZPb : ZPa;
   assign ZP[2]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lz8

module lz16 (ZP, ZV, B);

   input logic [15:0]  B;

   logic [2:0] 	       ZPa;
   logic [2:0] 	       ZPb;
   logic 	       ZVa;
   logic 	       ZVb;   

   output logic [3:0]  ZP;
   output logic        ZV;

   lz8 l1(ZPa, ZVa, B[7:0]);
   lz8 l2(ZPb, ZVb, B[15:8]);

   assign ZP[2:0] = ZVb ? ZPb : ZPa;
   assign ZP[3]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lz16

module lz32 (ZP, ZV, B);

   input logic [31:0] B;

   logic [3:0] 	      ZPa;
   logic [3:0] 	      ZPb;
   logic 	      ZVa;
   logic 	      ZVb;
   
   output logic [4:0] ZP;
   output logic       ZV;
   
   lz16 l1(ZPa, ZVa, B[15:0]);
   lz16 l2(ZPb, ZVb, B[31:16]);
   
   assign ZP[3:0] = ZVb ? ZPb : ZPa;
   assign ZP[4]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lz32

module lz64 (ZP, ZV, B);

   input logic [63:0]  B;
   
   logic [4:0] 	       ZPa;
   logic [4:0] 	       ZPb;
   logic 	       ZVa;
   logic 	       ZVb;
   
   output logic [5:0]  ZP;
   output logic        ZV;
   
   lz32 l1(ZPa, ZVa, B[31:0]);
   lz32 l2(ZPb, ZVb, B[63:32]);
   
   assign ZP[4:0] = ZVb ? ZPb : ZPa;
   assign ZP[5]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lz64

// FSM Control for Integer Divider

module fsm64 (en, state0, done, divdone, otfzero, divBusy,
	      start, error, NumIter, clk, reset);

   input logic [5:0]  NumIter;   
   input logic 	      clk;
   input logic 	      reset;
   input logic 	      start;
   input logic 	      error;   
   
   output logic       done;      
   output logic       en;
   output logic       state0;
   output logic       divdone;
   output logic       otfzero;
   output logic       divBusy;   
   
   logic 	      LT, EQ;
   logic 	      Divide0;   
   logic [5:0] 	      CURRENT_STATE;
   logic [5:0] 	      NEXT_STATE;   
   
   parameter [5:0] 
     S0=6'd0, S1=6'd1, S2=6'd2,
     S3=6'd3, S4=6'd4, S5=6'd5,
     S6=6'd6, S7=6'd7, S8=6'd8,
     S9=6'd9, S10=6'd10, S11=6'd11,
     S12=6'd12, S13=6'd13, S14=6'd14,
     S15=6'd15, S16=6'd16, S17=6'd17,
     S18=6'd18, S19=6'd19, S20=6'd20,
     S21=6'd21, S22=6'd22, S23=6'd23,
     S24=6'd24, S25=6'd25, S26=6'd26,
     S27=6'd27, S28=6'd28, S29=6'd29,
     S30=6'd30, S31=6'd31, S32=6'd32,
     S33=6'd33, S34=6'd34, S35=6'd35,
     S36=6'd36, Done=6'd37;      
   
   always @(posedge clk)
     begin
	if(reset==1'b1)
	  CURRENT_STATE<=S0;
	else
	  CURRENT_STATE<=NEXT_STATE;
     end

   // Going to cheat and hard code number of states 
   // needed into FSM instead of using a counter
   // FIXME: could counter be better

   // Cheated and made 8 - let synthesis do its magic
   magcompare8 comp1 (LT, EQ, {2'h0, CURRENT_STATE}, {2'h0, NumIter});

   always @(CURRENT_STATE or start)
     begin
 	case(CURRENT_STATE)
	  S0:
	    begin
	       if (start==1'b0)
		 begin
		    otfzero = 1'b1;   
		    en = 1'b0;
		    divBusy = 1'b0;		    
		    state0 = 1'b0;
		    divdone = 1'b0;		    
		    done = 1'b0;
		    NEXT_STATE <= S0;
		 end 
	       else 
		 begin
		    otfzero = 1'b0;	       		    
		    en = 1'b1;
		    divBusy = 1'b1;		    		    
		    state0 = 1'b1;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		    
		    done = 1'b0;
		    divdone = 1'b0;		 		 
		    NEXT_STATE <= S1;
		 end 
	    end	    
	  S1:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S2;
		 end
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S2;
		 end		    
	    end // case: S1	  
	  S2:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S3;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S3;
		 end		    	       	       
	    end // case: S2
	  S3:
	    begin	       
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S4;
		 end 
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S4;
		 end		    	       
	    end // case: S3
	  S4:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S5;
		 end 	       	    
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S5;
		 end		       	       
	    end // case: S4
	  S5:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S6;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S6;
		 end		    	       	       	       
	    end // case: S5
	  S6:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S7;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S7;
		 end		    	       	       
	    end // case: S6
	  S7:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S8;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S8;
		 end		    	       	       
	    end // case: S7
	  S8:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S9;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S9;
		 end		    	       	       
	    end // case: S8
	  S9:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S10;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S10;
		 end		    	       	       
	    end // case: S9
	  S10:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S11;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S11;
		 end		    	       	       
	    end // case: S10
	  S11:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S12;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S12;
		 end		    	       	       
	    end // case: S11
	  S12:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S13;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S13;
		 end		    	       	       
	    end // case: S12
	  S13:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S14;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S14;
		 end		    	       	       
	    end // case: S13
	  S14:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S15;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S15;
		 end		    	       	       
	    end // case: S14
	  S15:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S16;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S16;
		 end		    	       	       
	    end // case: S15
	  S16:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S17;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S17;
		 end		    	       	       
	    end // case: S16
	  S17:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S18;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S18;
		 end		    	       	       
	    end // case: S17
	  S18:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S19;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S19;
		 end		    	       	       
	    end // case: S18
	  S19:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S20;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S20;
		 end		    	       	       
	    end // case: S19
	  S20:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S21;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S21;
		 end		    	       	       
	    end // case: S20
	  S21:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S22;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S22;
		 end		    	       	       
	    end // case: S21
	  S22:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;
		    NEXT_STATE <= S23;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S23;
		 end		    	       	       
	    end // case: S22
	  S23:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S24;		    
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S24;
		 end		    	       	       
	    end // case: S23 
	  S24:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S25;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S25;
		 end		    	       	       
	    end // case: S24
	  S25:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S26;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S26;
		 end		    	       	       
	    end // case: S25
	  S26:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S27;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S27;
		 end		    	       	       
	    end // case: S26
	  S27:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S28;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S28;
		 end		    	       	       
	    end // case: S27
	  S28:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S29;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S29;
		 end		    	       	       
	    end // case: S28
	  S29:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S30;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S30;
		 end		    	       	       
	    end // case: S29
	  S30:
	    begin
	       otfzero = 1'b0;
     	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S31;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S31;
		 end		    	       	       
	    end // case: S30
	  S31:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S32;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S32;
		 end		    	       	       
	    end // case: S31  
	  S32:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S33;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S33;
		 end		    	       	       
	    end // case: S32
	  S33:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S34;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S34;
		 end		    	       	       
	    end // case: S33
	  S34:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S35;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S35;
		 end		    	       	       
	    end // case: S34  	  
	  S35:
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       if (LT|EQ)
		 begin
		    en = 1'b1;
		    state0 = 1'b0;
		    done = 1'b0;
		    if (EQ)
		      divdone = 1'b1;		    
		    else
		      divdone = 1'b0;		 		 
		    NEXT_STATE <= S36;
		 end // if (LT|EQ)
	       else
		 begin
		    en = 1'b0;
		    state0 = 1'b0;
		    done = 1'b0;
		    divdone = 1'b0;
		    NEXT_STATE <= S36;
		 end		    	       	       
	    end // case: S35	  
	  S36:
	    begin
	       otfzero = 1'b1;
	       divBusy = 1'b1;	       
	       state0 = 1'b0;
	       done = 1'b1;
	       if (EQ)
		 begin
		    divdone = 1'b1;
		    en = 1'b1;
		 end
	       else
		 begin
		    divdone = 1'b0;
		    en = 1'b0;
		 end
	       NEXT_STATE <= S0;
	    end // case: S36
	  default: 
	    begin
	       otfzero = 1'b0;
	       divBusy = 1'b1;	       
	       en = 1'b0;
	       state0 = 1'b0;
	       done = 1'b0;
	       divdone = 1'b0;
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

module shifter_l64 (Z, A, Shift);

   input logic [63:0]  A;
   input logic [5:0]   Shift;
   
   logic [63:0]        stage1;
   logic [63:0]        stage2;
   logic [63:0]        stage3;
   logic [63:0]        stage4;
   logic [63:0]        stage5;   
   
   output logic [63:0] Z;      
   
   mux2 #(64) mx01(A,      {A[31:0], 32'h0}, Shift[5], stage1);   
   mux2 #(64) mx02(stage1, {stage1[47:0], 16'h0}, Shift[4], stage2);
   mux2 #(64) mx03(stage2, {stage2[55:0], 8'h0}, Shift[3], stage3);
   mux2 #(64) mx04(stage3, {stage3[59:0], 4'h0}, Shift[2], stage4);
   mux2 #(64) mx05(stage4, {stage4[61:0], 2'h0}, Shift[1], stage5);
   mux2 #(64) mx06(stage5, {stage5[62:0], 1'h0}, Shift[0], Z);

endmodule // shifter_l64

module shifter_r64 (Z, A, Shift);

   input logic [63:0]  A;
   input logic [5:0]   Shift;
   
   logic [63:0]        stage1;
   logic [63:0]        stage2;
   logic [63:0]        stage3;
   logic [63:0]        stage4;
   logic [63:0]        stage5;   		  
   
   output logic [63:0] Z;
   
   mux2 #(64) mx01(A, {32'h0, A[63:32]}, Shift[5], stage1);		  
   mux2 #(64) mx02(stage1, {16'h0, stage1[63:16]}, Shift[4], stage2);
   mux2 #(64) mx03(stage2, {8'h0, stage2[63:8]}, Shift[3], stage3);
   mux2 #(64) mx04(stage3, {4'h0, stage3[63:4]}, Shift[2], stage4);
   mux2 #(64) mx05(stage4, {2'h0, stage4[63:2]}, Shift[1], stage5);
   mux2 #(64) mx06(stage5, {1'h0, stage5[63:1]},  Shift[0], Z);
   
endmodule // shifter_r64

module shifter_l32 (Z, A, Shift);

   input logic [31:0]  A;
   input logic [4:0]   Shift;
   
   logic [31:0]        stage1;
   logic [31:0]        stage2;
   logic [31:0]        stage3;
   logic [31:0]        stage4;
   
   output logic [31:0] Z;      

   mux2 #(32) mx01(A,      {A[15:0], 16'h0},    Shift[4], stage1);
   mux2 #(32) mx02(stage1, {stage1[23:0], 8'h0}, Shift[3], stage2);
   mux2 #(32) mx03(stage2, {stage2[27:0], 4'h0},  Shift[2], stage3);
   mux2 #(32) mx04(stage3, {stage3[29:0], 2'h0},   Shift[1], stage4);
   mux2 #(32) mx05(stage4, {stage4[30:0], 1'h0},    Shift[0], Z);

endmodule // shifter_l32

module shifter_r32 (Z, A, Shift);

   input logic [31:0]  A;
   input logic [4:0]   Shift;
   
   logic [31:0]        stage1;
   logic [31:0]        stage2;
   logic [31:0]        stage3;
   logic [31:0]        stage4;
   
   output logic [31:0] Z;
   
   mux2 #(32) mx01(A,      {16'h0, A[31:16]},   Shift[4], stage1);
   mux2 #(32) mx02(stage1, {8'h0, stage1[31:8]}, Shift[3], stage2);
   mux2 #(32) mx03(stage2, {4'h0, stage2[31:4]},  Shift[2], stage3);
   mux2 #(32) mx04(stage3, {2'h0, stage3[31:2]},   Shift[1], stage4);
   mux2 #(32) mx05(stage4, {1'h0, stage4[31:1]},    Shift[0], Z);
   
endmodule // shifter_r32

module shift_right #(parameter WIDTH=8) 
   (input logic [`XLEN-1:0]         A,
    input logic [$clog2(`XLEN)-1:0] Shift,
    output logic [`XLEN-1:0] 	    Z);
   
   logic [`XLEN-1:0] 							 stage [$clog2(`XLEN):0];
   genvar 								 i;
   
   assign stage[0] = A;   
   generate
      for (i=0;i<$clog2(`XLEN);i=i+1)
	begin : genbit
	   mux2 #(`XLEN) mux_inst (stage[i], 
				   {{(`XLEN/(2**(i+1))){1'b0}}, stage[i][`XLEN-1:`XLEN/(2**(i+1))]}, 
				   Shift[$clog2(`XLEN)-i-1], 
				   stage[i+1]);
	end
   endgenerate
   assign Z = stage[$clog2(`XLEN)];   

endmodule // shift_right

module shift_left #(parameter WIDTH=8) 
   (input logic [`XLEN-1:0]         A,
    input logic [$clog2(`XLEN)-1:0] Shift,
    output logic [`XLEN-1:0] 	    Z);
   
   logic [`XLEN-1:0] 							stage [$clog2(`XLEN):0];
   genvar 								i;
   
   assign stage[0] = A;   
   generate
      for (i=0;i<$clog2(`XLEN);i=i+1)
	begin : genbit
	   mux2 #(`XLEN) mux_inst (stage[i], 
				   {stage[i][`XLEN-1-`XLEN/(2**(i+1)):0], {(`XLEN/(2**(i+1))){1'b0}}}, 
				   Shift[$clog2(`XLEN)-i-1], 
				   stage[i+1]);
	end
   endgenerate
   assign Z = stage[$clog2(`XLEN)];   

endmodule // shift_right

/* verilator lint_on COMBDLY */
/* verilator lint_on IMPLICIT */

