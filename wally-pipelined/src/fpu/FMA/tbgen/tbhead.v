`timescale 1 ns/10 ps
module tb;


 reg 	[63:0]		FInput1E;
 reg 	[63:0]		FInput2E;
 reg 	[63:0]		FInput3E;
 reg 	[63:0]		ans;
 wire 	[2:0]		FrmE;
 wire 	[63:0]		FmaResultM;
 wire 	[4:0]	 	FmaFlagsM;
 reg 	[4:0]	 	flags;
 wire				FmtE;

	wire 		[12:0]		aligncntE;    	// status flags
	wire 		[105:0]		ProdManE; 				// other result of partial products
	wire 		[161:0]		AlignedAddendE;				// wire of alignment shifter	
	wire 		[8:0]		normcntE; 		// shift count for normalizer
	wire 		[12:0]		ProdExpE; 		// multiplier expoent
	wire 					AddendStickyE;				// sticky bit of addend
	wire 					KillProdE; 		// FInput3E >> product
	wire 					prodofE; 		// FInput1E*FInput2E out of range
	wire					XZeroE;
	wire					YZeroE;
	wire					ZZeroE;
	wire					XDenormE;
	wire					YDenormE;
	wire					ZDenormE;
	wire					XInfE;
	wire					YInfE;
	wire					ZInfE;
	wire					XNaNE;
	wire					YNaNE;
	wire					ZNaNE;
	wire					nanE;
	wire			[8:0]		sumshiftE;
	wire					sumshiftzeroE;
    wire prodinfE;

integer fp;
reg wnan;
reg xnan;
reg ynan;
reg znan;
reg ansnan;
reg		[105:0]		s;				//	partial product 2	
reg		[51:0] 		xnorm;
reg 		[51:0] 		ynorm;
wire 	[2:0]		FOpCtrlE;
assign FOpCtrlE = 3'b0;  
// nearest even - 000
// twords zero - 001
// down - 010
// up - 011
// nearest max mag - 100  
assign FrmE = 3'b000;
assign FmtE = 1'b1;


localparam period = 20;  
fma1 UUT1(.*);
fma2 UUT2(.FInput1M(FInput1E), .FInput2M(FInput2E), .FInput3M(FInput3E), .FrmM(FrmE), .ProdManM(ProdManE),
			.AlignedAddendM(AlignedAddendE), .ProdExpM(ProdExpE), .AddendStickyM(AddendStickyE),.KillProdM(KillProdE), .FOpCtrlM(FOpCtrlE),
			.XZeroM(XZeroE),.YZeroM(YZeroE),.ZZeroM(ZZeroE),.XInfM(XInfE),.YInfM(YInfE),.ZInfM(ZInfE),.XNaNM(XNaNE),.YNaNM(YNaNE),.ZNaNM(ZNaNE), .FmtM(FmtE), .*);


initial 
    begin
    fp = $fopen("/home/kparry/riscv-wally/wally-pipelined/src/fpu/FMA/tbgen/results.dat","w");
