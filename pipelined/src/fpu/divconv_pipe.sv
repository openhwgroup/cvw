///////////////////////////////////////////
//
// Written: James Stine
// Modified: 8/1/2018
//
// Purpose: Convergence unit for pipelined floating point divider/square root top unit (Goldschmidt)
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

`include "wally-config.vh"

module divconv_pipe (q1, qm1, qp1, q0, qm0, qp0, rega_out, regb_out, regc_out, regd_out,
		     regr_out, d, n, sel_muxa, sel_muxb, sel_muxr, reset, clk,
		     load_rega, load_regb, load_regc, load_regd, load_regr, load_regs, load_regp,
		     P, op_type, exp_odd);

   input logic [52:0]   d, n;
   input logic [2:0] 	sel_muxa, sel_muxb;
   input logic 	        sel_muxr;   
   input logic 	        load_rega, load_regb, load_regc, load_regd;
   input logic 		load_regr, load_regs;
   input logic 		load_regp;   
   input logic 		P;
   input logic 		op_type;
   input logic 		exp_odd;   
   input logic 	        reset;
   input logic 	        clk;   
   
   output logic [59:0] 	q1, qp1, qm1;
   output logic [59:0] 	q0, qp0, qm0;   
   output logic [59:0] 	rega_out, regb_out, regc_out, regd_out;
   output logic [119:0] regr_out;
   
   supply1 		vdd;
   supply0 		vss;   

   logic [59:0] 	muxa_out, muxb_out;
   logic 		muxr_out;
   logic [10:0] 	ia_div, ia_sqrt;
   logic [59:0] 	ia_out;
   logic [119:0] 	mul_out;
   logic [59:0] 	q_out1, qm_out1, qp_out1;
   logic [59:0] 	q_out0, qm_out0, qp_out0;
   logic [59:0] 	mcand, mplier, mcand_q;   
   logic [59:0] 	twocmp_out;
   logic [60:0] 	three;   
   logic [119:0] 	Carry, Carry2;
   logic [119:0] 	Sum, Sum2;
   logic [119:0] 	constant, constant2;
   logic [59:0] 	q_const, qp_const, qm_const;
   logic [59:0] 	d2, n2;   
   logic [11:0] 	d3;   

   // Check if exponent is odd for sqrt
   // If exp_odd=1 and sqrt, then M/2 and use ia_addr=0 as IA
   assign d2 = (exp_odd&op_type) ? {vss, d, 6'h0} : {d, 7'h0};
   assign n2 = op_type ? d2 : {n, 7'h0};
   
   // IA div/sqrt
   sbtm_div ia1 (d[52:41], ia_div);
   sbtm_sqrt ia2 (d2[59:48], ia_sqrt);
   assign ia_out = op_type ? {ia_sqrt, {49{1'b0}}} : {ia_div, {49{1'b0}}};
   
   // Choose IA or iteration
   mux6 #(60) mx1 (d2, ia_out, rega_out, regc_out, regd_out, regb_out, sel_muxb, muxb_out);
   mux5 #(60) mx2 (regc_out, n2, ia_out, regb_out, regd_out, sel_muxa, muxa_out);

   // Deal with remainder if [0.5, 1) instead of [1, 2)
   mux2 #(120) mx3a ({~n, {67{1'b1}}}, {{1'b1}, ~n, {66{1'b1}}}, q1[59], constant2);
   // Select Mcand, Remainder/Q''  
   mux2 #(120) mx3 (120'h0, constant2, sel_muxr, constant);
   // Select mcand - remainder should always choose q1 [1,2) because
   //   adjustment of N in the from XX.FFFFFFF
   mux2 #(60) mx4 (q0, q1, q1[59], mcand_q);
   mux2 #(60) mx5 (muxb_out, mcand_q, sel_muxr&op_type, mplier);   
   mux2 #(60) mx6 (muxa_out, mcand_q, sel_muxr, mcand);
   // R4 Booth TDM multiplier (carry/save)
   redundantmul #(60) bigmul(.a(mcand), .b(mplier), .out0(Sum), .out1(Carry));   
   // Q*D - N (reversed but changed in rounder.v to account for sign reversal)
   csa #(120) csa1 (Sum, Carry, constant, Sum2, Carry2);
   // Add ulp for subtraction in remainder
   mux2 #(1) mx7 (1'b0, 1'b1, sel_muxr, muxr_out);

   // Constant for Q''
   mux2 #(60) mx8 ({60'h0000_0000_0000_020}, {60'h0000_0040_0000_000}, P, q_const);
   mux2 #(60) mx9 ({60'h0000_0000_0000_0A0}, {60'h0000_0140_0000_000}, P, qp_const);
   mux2 #(60) mxA ({60'hFFFF_FFFF_FFFF_F9F}, {60'hFFFF_FF3F_FFFF_FFF}, P, qm_const);

   logic [119:0] 	Sum_pipe;
   logic [119:0] 	Carry_pipe;
   logic 		muxr_pipe;   
   logic 		rega_pipe;
   logic 		regb_pipe;
   logic 		regc_pipe;
   logic 		regd_pipe;
   logic 		regs_pipe;
   logic 		regs_pipe2;
   logic 		regr_pipe;
   logic 		P_pipe;
   logic 		op_type_pipe;
   logic [59:0] 	q_const_pipe;
   logic [59:0] 	qm_const_pipe;
   logic [59:0] 	qp_const_pipe;
   logic [59:0] 	q_const_pipe2;
   logic [59:0] 	qm_const_pipe2;
   logic [59:0] 	qp_const_pipe2;      
   
   // Stage 1
   flopenr #(120) regp1 (clk, reset, load_regp, Sum2, Sum_pipe);
   flopenr #(120) regp2 (clk, reset, load_regp, Carry2, Carry_pipe);
   flopenr #(1) regp3 (clk, reset, load_regp, muxr_out, muxr_pipe);

   flopenr #(1) regp4 (clk, reset, load_regp, load_rega, rega_pipe);
   flopenr #(1) regp5 (clk, reset, load_regp, load_regb, regb_pipe);
   flopenr #(1) regp6 (clk, reset, load_regp, load_regc, regc_pipe);
   flopenr #(1) regp7 (clk, reset, load_regp, load_regd, regd_pipe);
   flopenr #(1) regp8 (clk, reset, load_regp, load_regs, regs_pipe);
   flopenr #(1) regp9 (clk, reset, load_regp, load_regr, regr_pipe);
   flopenr #(1) regpA (clk, reset, load_regp, P, P_pipe);
   flopenr #(1) regpB (clk, reset, load_regp, op_type, op_type_pipe);
   flopenr #(60) regpC (clk, reset, load_regp, q_const, q_const_pipe);
   flopenr #(60) regpD (clk, reset, load_regp, qp_const, qp_const_pipe);
   flopenr #(60) regpE (clk, reset, load_regp, qm_const, qm_const_pipe);

   // CPA (from CSA)/Remainder addition/subtraction
   assign mul_out = Sum_pipe + Carry_pipe + {119'h0, muxr_pipe};   
   // One's complement instead of two's complement (for hw efficiency)
   assign three = {~mul_out[118] , mul_out[118], ~mul_out[117:59]};   
   mux2 #(60) mxTC (~mul_out[118:59], three[60:1],  op_type_pipe, twocmp_out);

   // Stage 2
   flopenr #(60) regc (clk, reset, regc_pipe, twocmp_out, regc_out);
   flopenr #(60) regb (clk, reset, regb_pipe, mul_out[118:59], regb_out);
   flopenr #(60) rega (clk, reset, rega_pipe, mul_out[118:59], rega_out);
   flopenr #(60) regd (clk, reset, regd_pipe, mul_out[118:59], regd_out);
   flopenr #(120) regr (clk, reset, regr_pipe, mul_out, regr_out);   
   flopenr #(1) regl (clk, reset, regs_pipe, regs_pipe, regs_pipe2);
   flopenr #(60) regm (clk, reset, regs_pipe, q_const_pipe, q_const_pipe2);
   flopenr #(60) regn (clk, reset, regs_pipe, qp_const_pipe, qp_const_pipe2);
   flopenr #(60) rego (clk, reset, regs_pipe, qm_const_pipe, qm_const_pipe2);   

   // Assuming [1,2) - q1
   assign q_out1 = regb_out + q_const;  
   assign qp_out1 = regb_out + qp_const;  
   assign qm_out1 = regb_out + qm_const + 1'b1;  
   // Assuming [0.5,1) - q0   
   assign q_out0 = {regb_out[58:0], 1'b0} + q_const;  
   assign qp_out0 = {regb_out[58:0], 1'b0} + qp_const;  
   assign qm_out0 = {regb_out[58:0], 1'b0} + qm_const + 1'b1;    

   // Stage 3
   // Assuming [1,2)
   flopenr #(60) rege (clk, reset, regs_pipe2, {q_out1[59:35], (q_out1[34:6] & {29{~P_pipe}}), 6'h0}, q1);   
   flopenr #(60) regf (clk, reset, regs_pipe2, {qm_out1[59:35], (qm_out1[34:6] & {29{~P_pipe}}), 6'h0}, qm1);
   flopenr #(60) regg (clk, reset, regs_pipe2, {qp_out1[59:35], (qp_out1[34:6] & {29{~P_pipe}}), 6'h0}, qp1);
   // Assuming [0,1)
   flopenr #(60) regh (clk, reset, regs_pipe2, {q_out0[59:35], (q_out0[34:6] & {29{~P_pipe}}), 6'h0}, q0);
   flopenr #(60) regj (clk, reset, regs_pipe2, {qm_out0[59:35], (qm_out0[34:6] & {29{~P_pipe}}), 6'h0}, qm0);
   flopenr #(60) regk (clk, reset, regs_pipe2, {qp_out0[59:35], (qp_out0[34:6] & {29{~P_pipe}}), 6'h0}, qp0);
   
endmodule // divconv

// *** rewrote behaviorally dh 5 Jan 2021 for speed
module csa #(parameter WIDTH=8) (
   input logic [WIDTH-1:0] a, b, c,
	output logic [WIDTH-1:0] sum, carry);

   assign sum = a ^ b ^ c;
   assign carry = (a & (b | c)) | (b & c);
/*
   logic [WIDTH:0] 					  carry_temp;   
   genvar 						  i;
       for (i=0;i<WIDTH;i=i+1) begin : genbit
	    fa fa_inst (a[i], b[i], c[i], sum[i], carry_temp[i+1]);
	  end
   assign carry = {carry_temp[WIDTH-1:1], 1'b0};     
*/
endmodule // csa
