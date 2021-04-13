`timescale 1 ns/10 ps
module tb;


 reg 	[63:0]		ReadData1E;
 reg 	[63:0]		ReadData2E;
 reg 	[63:0]		ReadData3E;
 reg 	[63:0]		ans;
 reg 	[2:0]		FrmE;
 wire 	[63:0]		FmaResultM;
 wire 	[4:0]	 	FmaFlagsM;

integer fp;
reg wnan;
reg xnan;
reg ynan;
reg znan;
wire [12:0] aligncnt;
reg ansnan;
reg		[105:0]		s;				//	partial product 2	
reg		[51:0] 		xnorm;
reg 		[51:0] 		ynorm;

localparam period = 20;  
fma UUT(.*);


initial 
    begin
    fp = $fopen("/home/kparry/riscv-wally/wally-pipelined/src/fpu/FMA/tbgen/results.dat","w");
