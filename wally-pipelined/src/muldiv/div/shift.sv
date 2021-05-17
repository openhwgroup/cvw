module shifter_l64 (Z, A, Shift);

   input logic [63:0]  A;
   input logic [5:0]   Shift;
   
   logic [63:0]        stage1;
   logic [63:0]        stage2;
   logic [63:0]        stage3;
   logic [63:0]        stage4;
   logic [63:0]        stage5;   
   logic [31:0]        thirtytwozeros = 32'h0;
   logic [15:0]        sixteenzeros = 16'h0;
   logic [ 7:0]        eightzeros = 8'h0;
   logic [ 3:0]        fourzeros = 4'h0;
   logic [ 1:0]        twozeros = 2'b00;
   logic 	       onezero = 1'b0;   
   
   output logic [63:0] Z;      
   
   mux2 #(64) mx01(A,      {A[31:0], thirtytwozeros}, Shift[5], stage1);   
   mux2 #(64) mx02(stage1, {stage1[47:0], sixteenzeros}, Shift[4], stage2);
   mux2 #(64) mx03(stage2, {stage2[55:0], eightzeros}, Shift[3], stage3);
   mux2 #(64) mx04(stage3, {stage3[59:0], fourzeros}, Shift[2], stage4);
   mux2 #(64) mx05(stage4, {stage4[61:0], twozeros}, Shift[1], stage5);
   mux2 #(64) mx06(stage5, {stage5[62:0], onezero}, Shift[0], Z);

endmodule // shifter_l64

module shifter_r64 (Z, A, Shift);

   input logic [63:0]  A;
   input logic [5:0]   Shift;
   
   logic [63:0]        stage1;
   logic [63:0]        stage2;
   logic [63:0]        stage3;
   logic [63:0]        stage4;
   logic [63:0]        stage5;   		  
   logic [31:0]        thirtytwozeros = 32'h0;		  
   logic [15:0]        sixteenzeros = 16'h0;
   logic [ 7:0]        eightzeros = 8'h0;
   logic [ 3:0]        fourzeros = 4'h0;
   logic [ 1:0]        twozeros = 2'b00;
   logic 	       onezero = 1'b0;   
   
   output logic [63:0] Z;
   
   mux2 #(64) mx01(A, {thirtytwozeros, A[63:32]}, Shift[5], stage1);		  
   mux2 #(64) mx02(stage1, {sixteenzeros, stage1[63:16]}, Shift[4], stage2);
   mux2 #(64) mx03(stage2, {eightzeros, stage2[63:8]}, Shift[3], stage3);
   mux2 #(64) mx04(stage3, {fourzeros, stage3[63:4]}, Shift[2], stage4);
   mux2 #(64) mx05(stage4, {twozeros, stage4[63:2]}, Shift[1], stage5);
   mux2 #(64) mx06(stage5, {onezero, stage5[63:1]},  Shift[0], Z);
   
endmodule // shifter_r64

module shifter_l32 (Z, A, Shift);

   input logic [31:0]  A;
   input logic [4:0]   Shift;
   
   logic [31:0]        stage1;
   logic [31:0]        stage2;
   logic [31:0]        stage3;
   logic [31:0]        stage4;
   logic [15:0]        sixteenzeros = 16'h0;
   logic [ 7:0]        eightzeros = 8'h0;
   logic [ 3:0]        fourzeros = 4'h0;
   logic [ 1:0]        twozeros = 2'b00;
   logic 	       onezero = 1'b0;   
   
   output logic [31:0] Z;      

   mux2 #(32) mx01(A,      {A[15:0], sixteenzeros},    Shift[4], stage1);
   mux2 #(32) mx02(stage1, {stage1[23:0], eightzeros}, Shift[3], stage2);
   mux2 #(32) mx03(stage2, {stage2[27:0], fourzeros},  Shift[2], stage3);
   mux2 #(32) mx04(stage3, {stage3[29:0], twozeros},   Shift[1], stage4);
   mux2 #(32) mx05(stage4, {stage4[30:0], onezero},    Shift[0], Z);

endmodule // shifter_l32

module shifter_r32 (Z, A, Shift);

   input logic [31:0]  A;
   input logic [4:0]   Shift;
   
   logic [31:0]        stage1;
   logic [31:0]        stage2;
   logic [31:0]        stage3;
   logic [31:0]        stage4;
   logic [15:0]        sixteenzeros = 16'h0;
   logic [ 7:0]        eightzeros = 8'h0;
   logic [ 3:0]        fourzeros = 4'h0;
   logic [ 1:0]        twozeros = 2'b00;
   logic 	       onezero = 1'b0;   
   
   output logic [31:0] Z;
   
   mux2 #(32) mx01(A,      {sixteenzeros, A[31:16]},   Shift[4], stage1);
   mux2 #(32) mx02(stage1, {eightzeros, stage1[31:8]}, Shift[3], stage2);
   mux2 #(32) mx03(stage2, {fourzeros, stage2[31:4]},  Shift[2], stage3);
   mux2 #(32) mx04(stage3, {twozeros, stage3[31:2]},   Shift[1], stage4);
   mux2 #(32) mx05(stage4, {onezero, stage4[31:1]},    Shift[0], Z);
   
endmodule // shifter_r32

`define XLEN 32
module shift_right #(parameter WIDTH=8) (input logic [`XLEN-1:0]         A,
					 input logic [$clog2(`XLEN)-1:0] Shift,
					 output logic [`XLEN-1:0] 	 Z);
   
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

module shift_left #(parameter WIDTH=8) (input logic [`XLEN-1:0]         A,
					input logic [$clog2(`XLEN)-1:0] Shift,
					output logic [`XLEN-1:0] 	Z);
   
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



