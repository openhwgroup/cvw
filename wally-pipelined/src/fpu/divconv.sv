module divconv (q1, qm1, qp1, q0, qm0, qp0, rega_out, regb_out, regc_out, regd_out,
		regr_out, d, n, sel_muxa, sel_muxb, sel_muxr, reset, clk, load_rega, load_regb, 
		load_regc, load_regd, load_regr, load_regs, P, op_type, exp_odd);

   input logic [52:0]   d, n;
   input logic [2:0] 	sel_muxa, sel_muxb;
   input logic 	        sel_muxr;   
   input logic 	        load_rega, load_regb, load_regc, load_regd;
   input logic 		load_regr, load_regs;
   input logic 		P;
   input logic 		op_type;
   input logic 		exp_odd;   
   input logic 	        reset;
   input logic 	        clk;   
   
   output logic [63:0] 	q1, qp1, qm1;
   output logic [63:0] 	q0, qp0, qm0;   
   output logic [63:0] 	rega_out, regb_out, regc_out, regd_out;
   output logic [127:0] regr_out;
   
   supply1 		vdd;
   supply0 		vss;   

   logic [63:0] 	muxa_out, muxb_out;
   logic [10:0] 	ia_div, ia_sqrt;
   logic [63:0] 	ia_out;
   logic [127:0] 	mul_out;
   logic [63:0] 	q_out1, qm_out1, qp_out1;
   logic [63:0] 	q_out0, qm_out0, qp_out0;
   logic [63:0] 	mcand, mplier, mcand_q;   
   logic [63:0] 	twocmp_out;
   logic [64:0] 	three;   
   logic [127:0] 	Carry, Carry2;
   logic [127:0] 	Sum, Sum2;
   logic [127:0] 	constant, constant2;
   logic [63:0] 	q_const, qp_const, qm_const;
   logic [63:0] 	d2, n2;   
   logic [11:0] 	d3;   
   logic muxr_out;
   logic cout1, cout2, cout3, cout4, cout5, cout6, cout7;

   // Check if exponent is odd for sqrt
   // If exp_odd=1 and sqrt, then M/2 and use ia_addr=0 as IA
   assign d2 = (exp_odd&op_type) ? {vss,d,10'h0} : {d,11'h0};
   assign n2 = op_type ? d2 : {n,11'h0};
   
   // IA div/sqrt
   sbtm_div ia1 (d[52:41], ia_div);
   sbtm_sqrt ia2 (d2[63:52], ia_sqrt);
   assign ia_out = op_type ? {ia_sqrt, {53{1'b0}}} : {ia_div, {53{1'b0}}};
   
   // Choose IA or iteration
   mux6 #(64) mx1 (d2, ia_out, rega_out, regc_out, regd_out, regb_out, sel_muxb, muxb_out);
   mux5 #(64) mx2 (regc_out, n2, ia_out, regb_out, regd_out, sel_muxa, muxa_out);

   // Deal with remainder if [0.5, 1) instead of [1, 2)
   mux2 #(128) mx3a ({~n, {75{1'b1}}}, {{1'b1}, ~n, {74{1'b1}}}, q1[63], constant2);
   // Select Mcand, Remainder/Q''  
   mux2 #(128) mx3 (128'h0, constant2, sel_muxr, constant);
   // Select mcand - remainder should always choose q1 [1,2) because
   //   adjustment of N in the from XX.FFFFFFF
   mux2 #(64) mx4 (q0, q1, q1[63], mcand_q);
   mux2 #(64) mx5 (muxb_out, mcand_q, sel_muxr&op_type, mplier);   
   mux2 #(64) mx6 (muxa_out, mcand_q, sel_muxr, mcand);
   // TDM multiplier (carry/save)
   multiplier mult1 (mcand, mplier, Sum, Carry);
   // Q*D - N (reversed but changed in rounder.v to account for sign reversal)
   csa #(128) csa1 (Sum, Carry, constant, Sum2, Carry2);
   // Add ulp for subtraction in remainder
   mux2 #(1) mx7 (1'b0, 1'b1, sel_muxr, muxr_out);

   // Constant for Q''
   mux2 #(64) mx8 ({64'h0000_0000_0000_0200}, {64'h0000_0040_0000_0000}, P, q_const);
   mux2 #(64) mx9 ({64'h0000_0000_0000_0A00}, {64'h0000_0140_0000_0000}, P, qp_const);
   mux2 #(64) mxA ({64'hFFFF_FFFF_FFFF_F9FF}, {64'hFFFF_FF3F_FFFF_FFFF}, P, qm_const);
   
   // CPA (from CSA)/Remainder addition/subtraction
   // adder #(128) cpa1 (Sum2, Carry2, muxr_out, mul_out, cout1); 
   assign {cout1, mul_out} = Sum2 + Carry2 + muxr_out;  
   
   // Assuming [1,2) - q1
   // adder #(64) cpa2 (regb_out, q_const, 1'b0, q_out1, cout2);
   assign {cout2, q_out1} = regb_out + q_const;  
   // adder #(64) cpa3 (regb_out, qp_const, 1'b0, qp_out1, cout3);
   assign {cout3, qp_out1} = regb_out + qp_const;  
   // adder #(64) cpa4 (regb_out, qm_const, 1'b1, qm_out1, cout4);
   assign {cout4, qm_out1} = regb_out + qm_const + 1'b1;  
   // Assuming [0.5,1) - q0   
   // adder #(64) cpa5 ({regb_out[62:0], vss}, q_const, 1'b0, q_out0, cout5);
   assign {cout5, q_out0} = {regb_out[62:0], vss} + q_const;  
   // adder #(64) cpa6 ({regb_out[62:0], vss}, qp_const, 1'b0, qp_out0, cout6);
   assign {cout6, qp_out0} = {regb_out[62:0], vss} + qp_const;  
   // adder #(64) cpa7 ({regb_out[62:0], vss}, qm_const, 1'b1, qm_out0, cout7);  
   assign {cout7, qm_out0} = {regb_out[62:0], vss} + qm_const + 1'b1;    

   // One's complement instead of two's complement (for hw efficiency)
   assign three = {~mul_out[126], mul_out[126], ~mul_out[125:63]};   
   mux2 #(64) mxTC (~mul_out[126:63], three[64:1],  op_type, twocmp_out);

   // regs
   flopenr #(64) regc (clk, reset, load_regc, twocmp_out, regc_out);
   flopenr #(64) regb (clk, reset, load_regb, mul_out[126:63], regb_out);
   flopenr #(64) rega (clk, reset, load_rega, mul_out[126:63], rega_out);
   flopenr #(64) regd (clk, reset, load_regd, mul_out[126:63], regd_out);
   flopenr #(128) regr (clk, reset, load_regr, mul_out, regr_out);
   // Assuming [1,2)
   flopenr #(64) rege (clk, reset, load_regs, {q_out1[63:39], (q_out1[38:10] & {29{~P}}), 10'h0}, q1);   
   flopenr #(64) regf (clk, reset, load_regs, {qm_out1[63:39], (qm_out1[38:10] & {29{~P}}), 10'h0}, qm1);
   flopenr #(64) regg (clk, reset, load_regs, {qp_out1[63:39], (qp_out1[38:10] & {29{~P}}), 10'h0}, qp1);
   // Assuming [0,1)
   flopenr #(64) regh (clk, reset, load_regs, {q_out0[63:39], (q_out0[38:10] & {29{~P}}), 10'h0}, q0);
   flopenr #(64) regj (clk, reset, load_regs, {qm_out0[63:39], (qm_out0[38:10] & {29{~P}}), 10'h0}, qm0);
   flopenr #(64) regk (clk, reset, load_regs, {qp_out0[63:39], (qp_out0[38:10] & {29{~P}}), 10'h0}, qp0);
   
endmodule // divconv

// module adder #(parameter WIDTH=8)
//    (input  logic [WIDTH-1:0] a, b,
//     input logic 	     cin,
//     output logic [WIDTH-1:0] y,
//     output logic 	     cout);
   
//    assign {cout, y} = a + b + cin;
   
// endmodule // adder

// module flopenr #(parameter WIDTH = 8)
//    (input  logic             clk, reset, en,
//     input  logic [WIDTH-1:0] d, 
//     output logic [WIDTH-1:0] q);

//    always_ff @(posedge clk, posedge reset)
//      if (reset)   q <= #10 0;
//      else if (en) q <= #10 d;
   
// endmodule // flopenr

// module flopr #(parameter WIDTH = 8)
//    (input  logic             clk, reset,
//     input  logic [WIDTH-1:0] d, 
//     output logic [WIDTH-1:0] q);

//    always_ff @(posedge clk, posedge reset)
//      if (reset) q <= #10 0;
//      else       q <= #10 d;
   
// endmodule // flopr

// module flopenrc #(parameter WIDTH = 8)
//    (input  logic             clk, reset, en, clear,
//     input  logic [WIDTH-1:0] d, 
//     output logic [WIDTH-1:0] q);

//    always_ff @(posedge clk, posedge reset)
//      if (reset)    q <= #10 0;
//      else if (en) 
//        if (clear) q <= #10 0;
//        else       q <= #10 d;
   
// endmodule // flopenrc

// module floprc #(parameter WIDTH = 8)
//    (input  logic             clk, reset, clear,
//     input  logic [WIDTH-1:0] d, 
//     output logic [WIDTH-1:0] q);

//    always_ff @(posedge clk, posedge reset)
//      if (reset) q <= #10 0;
//      else       
//        if (clear) q <= #10 0;
//        else       q <= #10 d;
   
// endmodule // floprc

// module mux2 #(parameter WIDTH = 8)
//    (input  logic [WIDTH-1:0] d0, d1, 
//     input  logic             s, 
//     output logic [WIDTH-1:0] y);

//    assign y = s ? d1 : d0;
   
// endmodule // mux2

// module mux3 #(parameter WIDTH = 8)
//    (input  logic [WIDTH-1:0] d0, d1, d2,
//     input  logic [1:0]       s, 
//     output logic [WIDTH-1:0] y);

//    assign y = s[1] ? d2 : (s[0] ? d1 : d0);
   
// endmodule // mux3

// module mux4 #(parameter WIDTH = 8)
//    (input  logic [WIDTH-1:0] d0, d1, d2, d3,
//     input  logic [1:0]       s, 
//     output logic [WIDTH-1:0] y);

//    assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0);

// endmodule // mux4

// module mux5 #(parameter WIDTH = 8)
//    (input  logic [WIDTH-1:0] d0, d1, d2, d3, d4,
//     input  logic [2:0]       s,
//     output logic [WIDTH-1:0] y);
   
//    always_comb
//      casez (s)
//        3'b000 : y = d0;       
//        3'b001 : y = d1;
//        3'b010 : y = d2;
//        3'b011 : y = d3;
//        3'b1?? : y = d4;
//      endcase // casez (s)

// endmodule // mux5

// module mux6 #(parameter WIDTH = 8)
//    (input  logic [WIDTH-1:0] d0, d1, d2, d3, d4, d5,
//     input  logic [2:0]       s,
//     output logic [WIDTH-1:0] y);
   
//    always_comb
//      casez (s)
//        3'b000 : y = d0;       
//        3'b001 : y = d1;
//        3'b010 : y = d2;
//        3'b011 : y = d3;
//        3'b10? : y = d4;
//        3'b11? : y = d5;       
//      endcase // casez (s)

// endmodule // mux6

module eqcmp #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] a, b,
    output logic             y);

   assign y = (a == b);
   
endmodule // eqcmp

// module fa (input logic a, b, c, output logic sum, carry);

//    assign sum = a^b^c;
//    assign carry = a&b|a&c|b&c;   

// endmodule // fa

// module csa #(parameter WIDTH=8) 
//    (input logic [WIDTH-1:0] a, b, c,
//     output logic [WIDTH-1:0] sum, carry);

//    logic [WIDTH:0] 	     carry_temp;   
//    genvar 		     i;
//    generate
//       for (i=0;i<WIDTH;i=i+1)
// 	begin : genbit
// 	   fa fa_inst (a[i], b[i], c[i], sum[i], carry_temp[i+1]);
// 	end
//    endgenerate
//    assign carry = {1'b0, carry_temp[WIDTH-1:1], 1'b0};     
   
// endmodule // csa
