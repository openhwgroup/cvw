`timescale 1 ns/10 ps
module tb;


 reg 	[63:0]		ReadData1E;
 reg 	[63:0]		ReadData2E;
 reg 	[63:0]		ReadData3E;
 reg 	[63:0]		ans;
 reg 	[2:0]		FrmE;
 wire 	[63:0]		FmaResultM;
 wire 	[4:0]	 	FmaFlagsM;

	wire 		[12:0]		aligncntE;    	// status flags
	wire 		[105:0]		ProdManE; 				// other result of partial products
	wire 		[161:0]		AlignedAddendE;				// wire of alignment shifter	
	wire 		[8:0]		normcntE; 		// shift count for normalizer
	wire 		[12:0]		ProdExpE; 		// multiplier expoent
	wire 					AddendStickyE;				// sticky bit of addend
	wire 					KillProdE; 		// ReadData3E >> product
	wire 					prodofE; 		// ReadData1E*ReadData2E out of range
	wire					XZeroE;
	wire					yzeroE;
	wire					zzeroE;
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
wire 	[3:0]		FOpCtrlM;

assign FOpCtrlM = 4'b0;


localparam period = 20;  
fma1 UUT1(.*);
fma2 UUT2(.ReadData1M(ReadData1E), .ReadData2M(ReadData2E), .ReadData3M(ReadData3E), .FrmM(FrmE), .ProdManM(ProdManE),
			.AlignedAddendM(AlignedAddendE), .ProdExpM(ProdExpE), .AddendStickyM(AddendStickyE),.KillProdM(KillProdE),
			.XZeroM(XZeroE),.YZeroM(YZeroE),.ZZeroM(ZZeroE),.XInfM(XInfE),.YInfM(YInfE),.ZInfM(ZInfE),.XNaNM(XNaNE),.YNaNM(YNaNE),.ZNaNM(ZNaNE), .*);


initial 
    begin
    fp = $fopen("/home/kparry/riscv-wally/wally-pipelined/src/fpu/FMA/tbgen/results.dat","w");
