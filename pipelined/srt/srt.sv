///////////////////////////////////////////
// srt.sv
//
// Written: David_Harris@hmc.edu 13 January 2022
// Modified: 
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module srt #(parameter Nf=52) (
  input  logic clk,
  input  logic Start, 
  input  logic Stall, // *** multiple pipe stages
  input  logic Flush, // *** multiple pipe stages
  // Floating Point Inputs
  // later add exponents, signs, special cases
  input  logic       XSign, YSign,
  input  logic [`NE-1:0] XExp, YExp,
  input  logic [Nf-1:0] SrcXFrac, SrcYFrac,
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic [1:0] Fmt, // Floats: 00 = 16 bit, 01 = 32 bit, 10 = 64 bit, 11 = 128 bit
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputss
  input  logic       Sqrt, // perform square root, not divide
  output logic       rsign,
  output logic [Nf-1:0] Quot, Rem, QuotOTFC, // *** later handle integers
  output logic [`NE-1:0] rExp,
  output logic [3:0] Flags
);

  logic          qp, qz, qm; // quotient is +1, 0, or -1
  logic [`NE-1:0] calcExp;
  logic           calcSign;
  logic [Nf-1:0]  X, Dpreproc;
  logic [Nf+3:0]  WS, WSA, WSN, WC, WCA, WCN, D, Db, Dsel;
  logic [Nf+2:0]  rp, rm;
 
  srtpreproc #(Nf) preproc(SrcA, SrcB, SrcXFrac, SrcYFrac, Fmt, W64, Signed, Int, Sqrt, X, Dpreproc);

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  mux2   #(Nf+4) wsmux({WSA[54:0], 1'b0}, {4'b0001, X}, Start, WSN);
  flop   #(Nf+4) wsflop(clk, WSN, WS);
  mux2   #(Nf+4) wcmux({WCA[54:0], 1'b0}, 56'b0, Start, WCN);
  flop   #(Nf+4) wcflop(clk, WCN, WC);
  flopen #(Nf+4) dflop(clk, Start, {4'b0001, Dpreproc}, D);

  // Quotient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  // Accumulate quotient digits in a shift register
  qsel #(Nf) qsel(WS[55:52], WC[55:52], qp, qz, qm);
  qacc #(Nf+3) qacc(clk, Start, qp, qz, qm, rp, rm);
  flopen #(`NE) expflop(clk, Start, calcExp, rExp);
  flopen #(1) signflop(clk, Start, calcSign, rsign);

  // Divisor Selection logic
  inv dinv(D, Db);
  mux3onehot divisorsel(Db, 56'b0, D, qp, qz, qm, Dsel);

  // Partial Product Generation
  csa csa(WS, WC, Dsel, qp, WSA, WCA);

  expcalc expcalc(.XExp, .YExp, .calcExp);

  signcalc signcalc(.XSign, .YSign, .calcSign);

  srtpostproc postproc(rp, rm, Quot);
  
  otfc otfc(qp, qz, qm, Quot, QuotOTFC);
endmodule

module srtpostproc #(parameter N=52) (
  input [N+2:0] rp, rm,
  output [N-1:0] Quot
);

  //assign Quot = rp - rm;
  finaladd finaladd(rp, rm, Quot);
endmodule

module srtpreproc #(parameter Nf=52) (
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic [Nf-1:0] SrcXFrac, SrcYFrac,
  input  logic [1:0] Fmt, // Floats: 00 = 16 bit, 01 = 32 bit, 10 = 64 bit, 11 = 128 bit
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputss
  input  logic       Sqrt, // perform square root, not divide
  output logic [Nf-1:0] X, D
);

  // Initial: just pass X and Y through for simple fp division
  assign X = SrcXFrac;
  assign D = SrcYFrac;
endmodule

/*

//////////
// mux2 //
//////////
module mux2(input  logic [55:0] in0, in1, 
            input  logic        sel, 
            output logic [55:0] out);
 
   assign #1 out = sel ? in1 : in0;
endmodule

//////////
// flop //
//////////
module flop(clk, in, out);
  input 	clk;
  input  [55:0] in;
  output [55:0] out;

  logic    [55:0] state;

  always @(posedge clk)
      state <= #1 in;

  assign #1 out = state;
endmodule

*/

//////////
// qsel //
//////////
module qsel #(parameter Nf=52) ( // *** eventually just change to 4 bits
  input  logic [Nf+3:Nf] ps, pc, 
  output logic         qp, qz, qm
);
 
  logic [Nf+3:Nf]  p, g;
  logic          magnitude, sign, cout;

  // The quotient selection logic is presented for simplicity, not
  // for efficiency.  You can probably optimize your logic to
  // select the proper divisor with less delay.

  // Quotient equations from EE371 lecture notes 13-20
  assign p = ps ^ pc;
  assign g = ps & pc;

  assign #1 magnitude = ~(&p[54:52]);
  assign #1 cout = g[54] | (p[54] & (g[53] | p[53] & g[52]));
  assign #1 sign = p[55] ^ cout;
/*  assign #1 magnitude = ~((ps[54]^pc[54]) & (ps[53]^pc[53]) & 
			  (ps[52]^pc[52]));
  assign #1 sign = (ps[55]^pc[55])^
      (ps[54] & pc[54] | ((ps[54]^pc[54]) &
			    (ps[53]&pc[53] | ((ps[53]^pc[53]) &
						(ps[52]&pc[52]))))); */

  // Produce quotient = +1, 0, or -1
  assign #1 qp = magnitude & ~sign;
  assign #1 qz = ~magnitude;
  assign #1 qm = magnitude & sign;
endmodule

//////////
// qacc //
//////////
module qacc #(parameter N=55) (
  input  logic         clk, 
  input  logic         req, 
  input  logic         qp, qz, qm, 
  output logic [N-1:0] rp, rm
);

  flopr #(N) rmreg(clk, req, {rm[53:0], qm}, rm);
  flopr #(N) rpreg(clk, req, {rp[53:0], qp}, rp);
/*  always @(posedge clk)
    begin
      if (req) 
	begin
	  rp <= #1 0;
	  rm <= #1 0;
	end
      else 
	begin
	  rm <= #1 {rm[54:0], qm};
	  rp <= #1 {rp[54:0], qp};
	end
    end */
endmodule

//////////
// otfc //
//////////

module otfc #(parameter N=52) (
  input  logic         qp, qz, qm,
  input  logic [N-1:0] Quot,
  output logic [N-1:0] QuotOTFC
);

    assign QuotOTFC = Quot;

endmodule

/////////
// inv //
/////////

module inv(input  logic [55:0] in, 
           output logic [55:0] out);

  assign #1 out = ~in;
endmodule

//////////
// mux3 //
//////////
module mux3onehot(in0, in1, in2, sel0, sel1, sel2, out);
  input  [55:0] in0;
  input  [55:0] in1;
  input  [55:0] in2;
  input         sel0;
  input         sel1;
  input         sel2;
  output [55:0] out;

  // lazy inspection of the selects
  // really we should make sure selects are mutually exclusive
  assign #1 out = sel0 ? in0 : (sel1 ? in1 : in2);
endmodule


/////////
// csa //
/////////
module csa #(parameter N=56) (
  input  logic [N-1:0] in1, in2, in3, 
  input  logic         cin, 
  output logic [N-1:0] out1, out2
);

  // This block adds in1, in2, in3, and cin to produce 
  // a result out1 / out2 in carry-save redundant form.
  // cin is just added to the least significant bit and
  // is required to handle adding a negative divisor.
  // Fortunately, the carry (out2) is shifted left by one
  // bit, leaving room in the least significant bit to 
  // insert cin.

  assign #1 out1 = in1 ^ in2 ^ in3;
  assign #1 out2 = {in1[54:0] & (in2[54:0] | in3[54:0]) | 
		    (in2[54:0] & in3[54:0]), cin};
endmodule


//////////////
// expcalc  //
//////////////

module expcalc(
  input logic  [`NE-1:0] XExp, YExp,
  output logic [`NE-1:0] calcExp
);

  assign calcExp = XExp - YExp + `BIAS;

endmodule

//////////////
// signcalc //
//////////////

module signcalc(
  input logic  XSign, YSign,
  output logic calcSign
);

  assign calcSign = XSign ^ YSign;

endmodule

//////////////
// finaladd //
//////////////
module finaladd(
  input  logic [54:0] rp, rm, 
  output logic [51:0] r
);

  logic   [54:0] diff;

  // this magic block performs the final addition for you
  // to convert the positive and negative quotient digits
  // into a normalized mantissa.  It returns the 52 bit
  // mantissa after shifting to guarantee a leading 1.
  // You can assume this block operates in one cycle
  // and do not need to budget it in your area and power
  // calculations.
	
  // Since no rounding is performed, the result may be too 
  // small by one unit in the least significant place (ulp).
  // The checker ignores such an error.

  assign #1 diff = rp - rm;
  assign #1 r = diff[54] ? diff[53:2] : diff[52:1];
endmodule

