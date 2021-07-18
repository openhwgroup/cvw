// //
// // File name : fpdiv
// // Title     : Floating-Point Divider/Square-Root
// // project   : FPU
// // Library   : fpdiv
// // Author(s) : James E. Stine, Jr.
// // Purpose   : definition of main unit to floating-point div/sqrt
// // notes :   
// //
// // Copyright Oklahoma State University
// //
// // Basic Operations
// //
// // Step 1: Load operands, set flags, and convert SP to DP
// // Step 2: Check for special inputs ( +/- Infinity,  NaN)
// // Step 3: Exponent Logic
// // Step 4: Divide/Sqrt using Goldschmidt
// // Step 5: Normalize the result.//
// //   Shift left until normalized.  Normalized when the value to the 
// //   left of the binrary point is 1.
// // Step 6: Round the result.// 
// // Step 7: Put quotient/remainder onto output.
// //

// // `timescale 1ps/1ps
// module fdivsqrt (FDivSqrtDoneE, FDivResultM, FDivSqrtFlgM, DivInput1E, DivInput2E, FrmE, DivOpType, FmtE, DivOvEn, DivUnEn,
// 	      FDivStartE, reset, clk, FDivBusyE, HoldInputs);

//    input [63:0] DivInput1E;		// 1st input operand (A)
//    input [63:0] DivInput2E;		// 2nd input operand (B)
//    input [2:0] 	FrmE;		// Rounding mode - specify values 
//    input 	DivOpType;	// Function opcode
//    input 	FmtE;   		// Result Precision (0 for double, 1 for single) //***will need to swap this
//    input 	DivOvEn;		// Overflow trap enabled
//    input 	DivUnEn;   	// Underflow trap enabled

//    input 	FDivStartE;
//    input 	reset;
//    input 	clk;   

//    output [63:0] FDivResultM;	// Result of operation
//    output [4:0]  FDivSqrtFlgM;   	// IEEE exception flags 
//    output 	 FDivSqrtDoneE;
//    output    FDivBusyE, HoldInputs;

//    supply1 	  vdd;
//    supply0 	  vss;   

//    wire [63:0] 	 Float1; 
//    wire [63:0] 	 Float2;
//    wire [63:0] 	 IntValue;
   
//    wire 	 DivDenormM;   	// DivDenormM on input or output
//    wire [12:0] 	 exp1, exp2, expF;
//    wire [12:0] 	 exp_diff, bias;
//    wire [13:0] 	 exp_sqrt;
//    wire [12:0] 	 exp_s;
//    wire [12:0] 	 exp_c;
   
//    wire [10:0] 	 exponent, exp_pre;
//    wire [63:0] 	 Result;   
//    wire [52:0] 	 mantissaA;
//    wire [52:0] 	 mantissaB; 
//    wire [63:0] 	 sum, sum_tc, sum_corr, sum_norm;
   
//    wire [5:0] 	 align_shift;
//    wire [5:0] 	 norm_shift;
//    wire [2:0] 	 sel_inv;
//    wire		 op1_Norm, op2_Norm;
//    wire		 opA_Norm, opB_Norm;
//    wire		 Invalid;
//    wire 	 DenormIn, DenormIO;
//    wire [4:0] 	 FlagsIn;   	
//    wire 	 exp_gt63;
//    wire 	 Sticky_out;
//    wire 	 signResult, sign_corr;
//    wire          corr_sign;
//    wire 	 zeroB;         
//    wire 	 convert;
//    wire          swap;
//    wire          sub;
   
//    wire [63:0] 	 q1, qm1, qp1, q0, qm0, qp0;
//    wire [63:0] 	 rega_out, regb_out, regc_out, regd_out;
//    wire [127:0]  regr_out;
//    wire [2:0] 	 sel_muxa, sel_muxb;
//    wire 	 sel_muxr;   
//    wire 	 load_rega, load_regb, load_regc, load_regd, load_regr, load_regs;

//    wire 	 donev, sel_muxrv, sel_muxsv;
//    wire [1:0] 	 sel_muxav, sel_muxbv;   
//    wire 	 load_regav, load_regbv, load_regcv;
//    wire 	 load_regrv, load_regsv;
   
//    logic exp_cout1, exp_cout2, exp_odd, open;


//    // Convert the input operands to their appropriate forms based on 
//    // the orignal operands, the DivOpType , and their precision FmtE. 
//    // Single precision inputs are converted to double precision 
//    // and the sign of the first operand is set appropratiately based on
//    // if the operation is absolute value or negation. 
//    convert_inputs_div divconv1 (Float1, Float2, DivInput1E, DivInput2E, DivOpType, FmtE);

//    // Test for exceptions and return the "Invalid Operation" and
//    // "Denormalized" Input FDivSqrtFlgM. The "sel_inv" is used in
//    // the third pipeline stage to select the result. Also, op1_Norm
//    // and op2_Norm are one if DivInput1E and DivInput2E are not zero or denormalized.
//    // sub is one if the effective operation is subtaction. 
//    exception_div divexc1 (sel_inv, Invalid, DenormIn, op1_Norm, op2_Norm, 
// 		   Float1, Float2, DivOpType);

//    // Determine Sign/Mantissa
//    assign signResult = ((Float1[63]^Float2[63])&~DivOpType) | Float1[63]&DivOpType;
//    assign mantissaA = {vdd, Float1[51:0]};
//    assign mantissaB = {vdd, Float2[51:0]};
//    // Perform Exponent Subtraction - expA - expB + Bias   
//    assign exp1 = {2'b0, Float1[62:52]};
//    assign exp2 = {2'b0, Float2[62:52]};
//    // bias : DP = 2^{11-1}-1 = 1023
//    assign bias = {3'h0, 10'h3FF};
//    // Divide exponent
//    csa #(13) csa1 (exp1, ~exp2, bias, exp_s, exp_c); //***adder
//    exp_add explogic1 (exp_cout1, {open, exp_diff}, //***adder?
// 		      {vss, exp_s}, {vss, exp_c}, 1'b1);
//    // Sqrt exponent (check if exponent is odd)
//    assign exp_odd = Float1[52] ? vss : vdd;
//    exp_add explogic2 (exp_cout2, exp_sqrt, //***adder?
// 		      {vss, exp1}, {4'h0, 10'h3ff}, exp_odd);
//    // Choose correct exponent
//    assign expF = DivOpType ? exp_sqrt[13:1] : exp_diff;   

//    // Main Goldschmidt/Division Routine
//    divconv goldy (q1, qm1, qp1, q0, qm0, qp0, 
// 		  rega_out, regb_out, regc_out, regd_out,
// 		  regr_out, mantissaB, mantissaA, 
// 		  sel_muxa, sel_muxb, sel_muxr, 
// 		  reset, clk,
// 		  load_rega, load_regb, load_regc, load_regd,
// 		  load_regr, load_regs, FmtE, DivOpType, exp_odd);

//    // FSM : control divider
//    fsm control (FDivSqrtDoneE, load_rega, load_regb, load_regc, load_regd, 
// 		load_regr, load_regs, sel_muxa, sel_muxb, sel_muxr, 
// 		clk, reset, FDivStartE, DivOpType, FDivBusyE, HoldInputs);
   
//    // Round the mantissa to a 52-bit value, with the leading one
//    // removed. The rounding units also handles special cases and 
//    // set the exception flags.
//    //***add max magnitude and swap negitive and positive infinity
//    rounder_div divround1 (Result, DenormIO, FlagsIn, 
// 		   FrmE, FmtE, DivOvEn, DivUnEn, expF, 
//    		   sel_inv, Invalid, DenormIn, signResult, 
// 		   q1, qm1, qp1, q0, qm0, qp0, regr_out);

//    // Store the final result and the exception flags in registers.
//    flopenr #(64) rega (clk, reset, FDivSqrtDoneE, Result, FDivResultM);
//    flopenr #(1) regb (clk, reset, FDivSqrtDoneE, DenormIO, DivDenormM);   
//    flopenr #(5) regc (clk, reset, FDivSqrtDoneE, FlagsIn, FDivSqrtFlgM);   
   
// endmodule // fpadd

// //
// // Brent-Kung Prefix Adder 
// //   (yes, it is 14 bits as my generator is broken for 13 bits :( 
// //    assume, synthesizer will delete stuff not needed )
// //
// module exp_add (cout, sum, a, b, cin);
   
//    input [13:0] a, b;
//    input 	cin;
   
//    output [13:0] sum;
//    output 	 cout;

//    wire [14:0] 	 p,g;
//    wire [13:0] 	 c;

//    // pre-computation
//    assign p={a^b,1'b0};
//    assign g={a&b, cin};

//    // prefix tree
//    brent_kung prefix_tree(c, p[13:0], g[13:0]);

//    // post-computation
//    assign sum=p[14:1]^c;
//    assign cout=g[14]|(p[14]&c[13]);

// endmodule // exp_add

// module brent_kung (c, p, g);
   
//    input [13:0] p;
//    input [13:0] g;
//    output [14:1] c;

//    logic G_1_0, G_3_2,G_5_4,G_7_6,G_9_8,G_11_10,G_13_12,G_3_0,G_7_4,G_11_8;
//    logic P_3_2,P_5_4,P_7_6,P_9_8,P_11_10,P_13_12,P_7_4,P_11_8;
//    logic G_7_0,G_11_0,G_5_0,G_9_0,G_13_0,G_2_0,G_4_0,G_6_0,G_8_0,G_10_0,G_12_0;
//    // parallel-prefix, Brent-Kung

//    // Stage 1: Generates G/FmtE pairs that span 1 bits
//    grey b_1_0 (G_1_0, {g[1],g[0]}, p[1]);
//    black b_3_2 (G_3_2, P_3_2, {g[3],g[2]}, {p[3],p[2]});
//    black b_5_4 (G_5_4, P_5_4, {g[5],g[4]}, {p[5],p[4]});
//    black b_7_6 (G_7_6, P_7_6, {g[7],g[6]}, {p[7],p[6]});
//    black b_9_8 (G_9_8, P_9_8, {g[9],g[8]}, {p[9],p[8]});
//    black b_11_10 (G_11_10, P_11_10, {g[11],g[10]}, {p[11],p[10]});
//    black b_13_12 (G_13_12, P_13_12, {g[13],g[12]}, {p[13],p[12]});

//    // Stage 2: Generates G/FmtE pairs that span 2 bits
//    grey g_3_0 (G_3_0, {G_3_2,G_1_0}, P_3_2);
//    black b_7_4 (G_7_4, P_7_4, {G_7_6,G_5_4}, {P_7_6,P_5_4});
//    black b_11_8 (G_11_8, P_11_8, {G_11_10,G_9_8}, {P_11_10,P_9_8});

//    // Stage 3: Generates G/FmtE pairs that span 4 bits
//    grey g_7_0 (G_7_0, {G_7_4,G_3_0}, P_7_4);

//    // Stage 4: Generates G/FmtE pairs that span 8 bits

//    // Stage 5: Generates G/FmtE pairs that span 4 bits
//    grey g_11_0 (G_11_0, {G_11_8,G_7_0}, P_11_8);

//    // Stage 6: Generates G/FmtE pairs that span 2 bits
//    grey g_5_0 (G_5_0, {G_5_4,G_3_0}, P_5_4);
//    grey g_9_0 (G_9_0, {G_9_8,G_7_0}, P_9_8);
//    grey g_13_0 (G_13_0, {G_13_12,G_11_0}, P_13_12);

//    // Last grey cell stage 
//    grey g_2_0 (G_2_0, {g[2],G_1_0}, p[2]);
//    grey g_4_0 (G_4_0, {g[4],G_3_0}, p[4]);
//    grey g_6_0 (G_6_0, {g[6],G_5_0}, p[6]);
//    grey g_8_0 (G_8_0, {g[8],G_7_0}, p[8]);
//    grey g_10_0 (G_10_0, {g[10],G_9_0}, p[10]);
//    grey g_12_0 (G_12_0, {g[12],G_11_0}, p[12]);

//    // Final Stage: Apply c_k+1=G_k_0
//    assign c[1]=g[0];
//    assign c[2]=G_1_0;
//    assign c[3]=G_2_0;
//    assign c[4]=G_3_0;
//    assign c[5]=G_4_0;
//    assign c[6]=G_5_0;
//    assign c[7]=G_6_0;
//    assign c[8]=G_7_0;
//    assign c[9]=G_8_0;

//    assign c[10]=G_9_0;
//    assign c[11]=G_10_0;
//    assign c[12]=G_11_0;
//    assign c[13]=G_12_0;
//    assign c[14]=G_13_0;

// endmodule // brent_kung

