///////////////////////////////////////////////////////
// srt.sv                                            //
//                                                   //
// Written 10/31/96 by David Harris harrisd@leland   //
// Updated 10/19/21 David_Harris@hmc.edu             //
//                                                   //
// This file models a simple Radix 2 SRT divider.    //
//                                                   //
///////////////////////////////////////////////////////

// This Verilog file models a radix 2 SRT divider which
// produces one quotient digit per cycle.  The divider
// keeps the partial remainder in carry-save form.
 
/////////
// srt //
/////////
module divider(clk, req, a, b, rp, rm);
 
  // A simple Radix 2 SRT divider
 
  // Interface (neglect fact adder is clocked)
  input         clk;
  input         req;  // request a new division
  input  [51:0] a;    // a has an implied leading 1
  input  [51:0] b;    // b has an implied leading 1
  output [54:0] rp;   // positive quotient digits
  output [54:0] rm;   // positive quotient digits
 
  // Internal signals

  wire   [55:0] ps, pc;     // partial remainder in carry-save form
  wire   [55:0] d;          // divisor
  wire   [55:0] psa, pca;   // partial remainder result of csa
  wire   [55:0] psn, pcn;   // partial remainder for next cycle
  wire   [55:0] dn;         // divisor for next cycle
  wire   [55:0] dsel;       // selected divisor multiple
  wire          qp, qz, qm; // quotient is +1, 0, or -1
  wire   [55:0] d_b;        // inverse of divisor
 
  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  mux2 psmux({psa[54:0], 1'b0}, {4'b0001, a}, req, psn);
  flop psflop(clk, psn, ps);
  mux2 pcmux({pca[54:0], 1'b0}, 56'b0, req, pcn);
  flop pcflop(clk, pcn, pc);
  mux2 dmux(d, {4'b0001, b}, req, dn);
  flop dflop(clk, dn, d);

  // Quotient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  // Accumulate quotient digits in a shift register
  qsel qsel(ps[55:52], pc[55:52], qp, qz, qm);
  qacc qacc(clk, req, qp, qz, qm, rp, rm);

  // Divisor Selection logic
  inv dinv(d, d_b);
  mux3 divisorsel(d_b, 56'b0, d, qp, qz, qm, dsel);

  // Partial Product Generation
  csa csa(ps, pc, dsel, qp, psa, pca);
endmodule

//////////
// mux2 //
//////////
module mux2(in0, in1, sel, out);
  input [55:0] 	in0;
  input [55:0] 	in1;
  input  	sel;
  output [55:0] out;

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

//////////
// qsel //
//////////
module qsel(ps, pc, qp, qz, qm);
  input  [55:52] ps;
  input  [55:52] pc;
  output 	qp;
  output 	qz;
  output 	qm;

  wire          magnitude;
  wire          sign;

  // The quotient selection logic is presented for simplicity, not
  // for efficiency.  You can probably optimize your logic to
  // select the proper divisor with less delay.

  // Quotient equations from EE371 lecture notes 13-20
  assign #1 magnitude = ~((ps[54]^pc[54]) && (ps[53]^pc[53]) && 
			  (ps[52]^pc[52]));
  assign #1 sign = (ps[55]^pc[55])^
      (ps[54] && pc[54] || ((ps[54]^pc[54]) &&
			    (ps[53]&&pc[53] || ((ps[53]^pc[53]) &&
						(ps[52]&&pc[52])))));

  // Produce quotient = +1, 0, or -1
  assign #1 qp = magnitude && ~sign;
  assign #1 qz = ~magnitude;
  assign #1 qm = magnitude && sign;
endmodule

//////////
// qacc //
//////////
module qacc(clk, req, qp, qz, qm, rp, rm);
  input 	clk;
  input         req;
  input 	qp;
  input 	qz;
  input 	qm;
  output [54:0] rp;
  output [54:0] rm;

  logic    [54:0] rp, rm; // quotient bit is +/- 1;
  logic    [7:0]  count;

  always @(posedge clk)
    begin
      if (req) 
	begin
	  rp <= #1 0;
	  rm <= #1 0;
	end
      else 
	begin
	  rp <= #1 {rp[54:0], qp};
	  rm <= #1 {rm[54:0], qm};
	end
    end
endmodule

/////////
// inv //
/////////
module inv(in, out);
  input  [55:0] in;
  output [55:0] out;

  assign #1 out = ~in;
endmodule

//////////
// mux3 //
//////////
module mux3(in0, in1, in2, sel0, sel1, sel2, out);
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
module csa(in1, in2, in3, cin, out1, out2);
  input  [55:0] in1;
  input  [55:0] in2;
  input  [55:0] in3;
  input         cin;
  output [55:0] out1;
  output [55:0] out2;

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
// finaladd //
//////////////
module finaladd(rp, rm, r);
  input  [54:0] rp;
  input  [54:0] rm;
  output [51:0] r;

  wire   [54:0] diff;

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

/////////////
// counter //
/////////////
module counter(clk, req, done);
  input 	clk;
  input         req;
  output        done;

  logic           done;
  logic    [5:0]  count;

  // This block of control logic sequences the divider
  // through its iterations.  You may modify it if you
  // build a divider which completes in fewer iterations.
  // You are not responsible for the (trivial) circuit
  // design of the block.

  always @(posedge clk)
    begin
      if (count == 54) done <= #1 1;
      if (done || req) done <= #1 0;	
      if (req) count <= #1 0;
      else count <= #1 count+1;
    end
endmodule

///////////
// clock //
///////////
module clock(clk);
  output clk;
 
  // Internal clk signal
  logic clk;
 
endmodule

//////////
// testbench //
//////////
module testbench;
  logic         clk;
  logic        req;
  logic         done;
  logic [51:0] a;
  logic [51:0] b;
  logic  [51:0] r;
  logic [54:0] rp, rm;   // positive quotient digits
 
  // Test parameters
  parameter MEM_SIZE = 40000;
  parameter MEM_WIDTH = 52+52+52;
 
  `define memr  51:0
  `define memb  103:52
  `define mema  155:104

  // Test logicisters
  logic [MEM_WIDTH-1:0] Tests [0:MEM_SIZE];  // Space for input file
  logic [MEM_WIDTH-1:0] Vec;  // Verilog doesn't allow direct access to a
                            // bit field of an array 
  logic    [51:0] correctr, nextr;
  integer testnum, errors;

  // Divider
  divider  srt(clk, req, a, b, rp, rm);

  // Final adder converts quotient digits to 2's complement & normalizes
  finaladd finaladd(rp, rm, r);

  // Counter
  counter counter(clk, req, done);


    initial
    forever
      begin
        clk = 1; #17;
        clk = 0; #16;
      end


  // Read test vectors from disk
  initial
    begin
      testnum = 0; 
      errors = 0;
      $readmemh ("testvectors", Tests);
      Vec = Tests[testnum];
      a = Vec[`mema];
      b = Vec[`memb];
      nextr = Vec[`memr];
      req <= #5 1;
    end
  
  // Apply directed test vectors read from file.

  always @(posedge clk)
    begin
      if (done) 
	begin
	  req <= #5 1;
	  $display("result was %h, should be %h\n", r, correctr);
	  if ((correctr - r) > 1) // check if accurate to 1 ulp
	    begin
	      errors = errors+1;
	      $display("failed\n");
	      $stop;
	    end
	  if (a === 52'hxxxxxxxxxxxxx)
	    begin
	      $display("Tests completed successfully");
	      $stop;
	    end
	end
      if (req) 
	begin
	  req <= #5 0;
	  correctr = nextr;
	  testnum = testnum+1;
	  Vec = Tests[testnum];
	  $display("a = %h  b = %h",a,b);
	  a = Vec[`mema];
	  b = Vec[`memb];
	  nextr = Vec[`memr];
	end
    end
 
endmodule
 
