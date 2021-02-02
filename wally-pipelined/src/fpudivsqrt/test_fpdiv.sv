`timescale 1ps/1ps
module tb;

   logic [63:0]  op1;	
   logic [63:0]  op2;	
   logic [1:0] 	 rm;	
   logic 	 op_type;
   logic 	 P;   	
   logic 	 OvEn;	
   logic 	 UnEn;   
   
   logic 	 start;
   logic 	 reset;
   logic 	 clk;   
   
   logic [63:0]  AS_Result;
   logic [4:0] 	 Flags;   
   logic 	 Denorm;  
   logic 	 done;   
   
   integer 	 handle3;
   integer 	 desc3;   

   fpdiv dut (done, AS_Result, Flags, Denorm, op1, op2, rm, op_type, P, OvEn, UnEn,
	      start, reset, clk);   
   
   initial 
     begin	
	clk = 1'b1;
	forever #333 clk = ~clk;
     end

   initial
     begin
	handle3 = $fopen("fpdiv.out");
     end

   always 
     begin
	desc3 = handle3;
	#5 $fdisplay(desc3, "%h %h | %h %h %h",
		     op1, op2, AS_Result, Flags, Denorm);	
     end

   initial
     begin
	#0  start = 1'b0;
	#0  P = 1'b1;
	#0  OvEn = 1'b0;
	#0  UnEn = 1'b0;
	// 00 round-to-nearest-even
	// 01 round-toward-zero
	// 10 round-toward-plus infinity
	// 11 round-toward-minus infinity	
	#0  rm = 2'b00;
	#0  op_type = 1'b1;
	
	#0  op1 = 64'h3ffc_0000_0000_0000; // 1.75
	#0  op2 = 64'h3ffe_0000_0000_0000; // 1.875
	#0  op1 = 64'h3ffe_e219_652b_d3c3; // 1.9302
	#0  op2 = 64'h3ff7_346d_c5d6_3886; // 1.4503
	#0  op1 = 64'h404f_b1d4_9518_2a99; // 63.3893
	#0  op2 = 64'h4020_9b94_d940_7896; // 8.30387
	#0  op1 = 64'h3ff6_3d98_4781_6b47; // 1.390037803
	#0  op2 = 64'h3fd7_b540_56e5_c87a; // 0.370437703
	#0  op1 = 64'h3fed_c505_fada_95fd; // 0.930300703 
	#0  op2 = 64'h4029_dc59_e3a1_24a8; // 12.9303733
	#0 op1 = 64'h41E0_0003_FFFB_FFFF;	
	#0 op2 = 64'hBFDF_FFFF_FFEF_FFFF;
	#0 op1 = 64'h41E0_0003_FFFB_FFFF;	
	#0 op2 = 64'h3FDF_FFFF_FFEF_FFFF;
	#0 op1 = 64'hB68F_FFF8_0000_00FF;	
	#0 op2 = 64'h3F90_8000_0007_FFFF;
	#0 op1 = 64'h0000_0000_0000_0000;	
	#0 op2 = 64'hA57F_319E_DE38_F755;
	#0 op1 = 64'hC1DF_FFFF_FFE0_0080;
	#0 op2 = 64'h3FA4_8EDF_3623_F076;
	#0 op1 = 64'hC030_00FF_FFFF_FFE0;
	#0 op2 = 64'h47EF_FDFF_FDFF_FFFF;
	#0 op1 = 64'h4030_00FF_FFFF_FFE0;
	#0 op2 = 64'h47EF_FDFF_FDFF_FFFF;
	#0  op1 = 64'h5555_5555_5555_5555; // 1.75
	#0  op2 = 64'haaaa_aaaa_aaaa_aaaa; // 1.875
	#0  op1 = 64'h3ffc_0000_0000_0000; // 1.75
	#0  op2 = 64'h0000_0000_0000_0000; // 0.00 (Div0 exception)
	#0  op1 = 64'h3ff7_10cb_0000_0000;
	#0  op2 = 64'h3fb9_a36e_0000_0000;
	#0  op1 = 64'h37e0_0000_0000_0001;
	#0  op2 = 64'h3be6_a09e_667f_3bce;

	#0  op1 = 64'h37e0_0000_0000_0001;
	#0  op1 = 64'h43d3_6fa3_cad3_f59e;
	#0  op1 = 64'h2470_0000_ffff_ffef;
	#0  op1 = 64'h7ff0_0000_0000_0000;
	#0  op1 = 64'h7fef_ffff_ffff_ffff;
	#0  op1 = 64'hffe0_0000_0000_0000;
	#0  op2 = 64'h7fe0_0000_0000_0001;
	#0  op1 = 64'h69ff_ff7f_0000_0000;
	#0  op2 = 64'h0;
	#0  op1 = 64'h3f7f_ffff_0000_0000;
	#0  op1 = 64'h4180_0000_0000_0000;	
	

	//#0  op1 = 64'h3fe0_0000_0000_0000; // 1.75  (SP)
	//#0  op2 = 64'h3ff0_0000_0000_0000; // 1.875 (SP)
	//#0  op1 = 64'h3ff7_10cb_0000_0000; // 1.75  (SP)
	//#0  op2 = 64'h3fb9_a36e_0000_0000; // 1.875 (SP)	
	//#0  op1 = 64'h427d_8ea5_0000_0000; // 1.75  (SP)
	//#0  op2 = 64'h4104_dca7_0000_0000; // 1.875 (SP)
	//#0  op1 = 64'h3fb1_ecc2_0000_0000; // 1.75  (SP)
	//#0  op2 = 64'h3ebd_aa03_0000_0000; // 1.875 (SP)
	//#0  op1 = 64'h3f6e_2830_0000_0000;	
	//#0  op2 = 64'h414e_e2cf_0000_0000;
	//#0  op1 = 64'h8683_f7ff_0000_0000;	
	//#0  op2 = 64'hc07f_3fff_0000_0000;
	//#0  op1 = 64'h0100_0000_0000_0000;	
	//#0  op2 = 64'h3400_00ef_0000_0000;
	//#0  op1 = 64'hbed5_6444_0000_0000;	
	//#0  op2 = 64'h3e7f_f400_0000_0000;
	//#0  op1 = 64'h0100_087f_0000_0000;	
	//#0  op2 = 64'hfe80_4fff_0000_0000;
	

	//#0 op1 = 64'hc513_492f_a359_69e3;
	//#0 op2 = 64'hbfcf_fdff_ffff_ffef;
	//#0 op1 = 64'h41E0_0003_FFFB_FFFF;	
	//#0 op2 = 64'hBFDF_FFFF_FFEF_FFFF;
	//#0 op1 = 64'hf17ffffffff7fff0;	
	//#0 op2 = 64'h001ffffffffffffe;
	//#0 op1 = 64'hC040_0000_0000_1000;	
	//#0 op2 = 64'h802f_ff7f_ffff_ffc0;
	//#0 op1 = 64'h3800008000000002;
	//#0 op2 = 64'h7ff0000000000000;
	//#0 op1 = 64'h8020200007fffffe;
	//#0 op2 = 64'hc59000000000083f;
	//#0 op1 = 64'h0140008000fffffe;
	//#0 op2 = 64'hd2e0001ffffffffb;
	//#0 op1 = 64'h4013_95a7_515b_e3d9;	
	//#0 op2 = 64'h8010_0000_0004_0007;
	//#0 op1 = 64'h0010_0000_0000_0000;	
	//#0 op2 = 64'h3fff_ffff_ffff_ffff;
	//#0 op1 = 64'h0010_0000_0000_0000;	
	//#0 op2 = 64'h4000_0000_0000_0001;
	//#0 op1 = 64'h4000000000000001;
	//#0 op2 = 64'h403000004007fffe; // _3fbfffff7ff00207_00000_0 | 3fbfffff7ff00206_0
	//#0 op1 = 64'hffe0_0000_0000_0000;
	//#0 op2 = 64'hc0a0_0000_4008_0000;
	//#0 op1 = 64'hffe0_0000_0000_0001;
	//#0 op2 = 64'hbfd0_0000_0000_0000;

	//#0 op1 = 64'h801f_ffff_ffff_ffff;
	//#0 op2 = 64'h4000_0000_0000_0000;


	#0  reset = 1'b1;	
	#1000 reset = 1'b0;	
	#3000 start = 1'b1;
	#800 start = 1'b0;
	

     end


endmodule // tb





