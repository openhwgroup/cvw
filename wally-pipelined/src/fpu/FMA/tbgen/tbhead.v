`timescale 1 ns/10 ps
module tb;


 reg 		[63:0]		xrf;
 reg 		[63:0]		y;
 reg 		[63:0]		zrf;
 reg 		[63:0]		ans;
 reg 						rn;
 reg 						rz;
 reg 						rm;
 reg 						rp;
 reg 		[63:0]		earlyres;
 reg 						earlyressel;
 reg 		[1:0]			bypsel;
 reg 						bypplus1;
 reg 						byppostnorm;
 wire 	[63:0]		w;
 wire 	[63:0]		wbypass;
 wire 		 			invalid;
 wire 					overflow;
 wire 					underflow;
 wire 					inexact;

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
fmac UUT(.xrf(xrf), .y(y), .zrf(zrf), .rn(rn), .rz(rz), .rp(rp), .rm(rm),
		.earlyres(earlyres), .earlyressel(earlyressel), .bypsel(bypsel), .bypplus1(bypplus1), .byppostnorm(byppostnorm), 
		.w(w), .wbypass(wbypass), .invalid(invalid), .overflow(overflow), .underflow(underflow), .inexact(inexact));


initial 
    begin
    fp = $fopen("/home/kparry/riscv-wally/wally-pipelined/src/fpu/FMA/tbgen/results.dat","w");
