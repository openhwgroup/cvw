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
	wire 		[105:0]		rE; 				// one result of partial product sum
	wire 		[105:0]		sE; 				// other result of partial products
	wire 		[163:0]		tE;				// wire of alignment shifter	
	wire 		[8:0]		normcntE; 		// shift count for normalizer
	wire 		[12:0]		aeE; 		// multiplier expoent
	wire 					bsE;				// sticky bit of addend
	wire 					killprodE; 		// ReadData3E >> product
	wire 					prodofE; 		// ReadData1E*ReadData2E out of range
	wire					xzeroE;
	wire					yzeroE;
	wire					zzeroE;
	wire					xdenormE;
	wire					ydenormE;
	wire					zdenormE;
	wire					xinfE;
	wire					yinfE;
	wire					zinfE;
	wire					xnanE;
	wire					ynanE;
	wire					znanE;
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


localparam period = 20;  
fma1 UUT1(.*);
fma2 UUT2(.ReadData1M(ReadData1E), .ReadData2M(ReadData2E), .ReadData3M(ReadData3E), .FrmM(FrmE),
			 .aligncntM(aligncntE), .rM(rE), .sM(sE),
			.tM(tE),	.normcntM(normcntE), .aeM(aeE), .bsM(bsE),.killprodM(killprodE),
			.xzeroM(xzeroE),	.yzeroM(yzeroE),.zzeroM(zzeroE),.xdenormM(xdenormE),.ydenormM(ydenormE),
			.zdenormM(zdenormE),.xinfM(xinfE),.yinfM(yinfE),.zinfM(zinfE),.xnanM(xnanE),.ynanM(ynanE),.znanM(znanE),
			.nanM(nanE),.sumshiftM(sumshiftE),.sumshiftzeroM(sumshiftzeroE), .prodinfM(prodinfE), .*);


initial 
    begin
    fp = $fopen("/home/kparry/riscv-wally/wally-pipelined/src/fpu/FMA/tbgen/results.dat","w");
