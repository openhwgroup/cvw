
//`include "../../../config/old/rv64icfd/wally-config.vh"

`define FLEN 64//(`Q_SUPPORTED ? 128 : `D_SUPPORTED ? 64 : 32)
`define NE   11//(`Q_SUPPORTED ? 15 : `D_SUPPORTED ? 11 : 8)
`define NF   52//(`Q_SUPPORTED ? 112 : `D_SUPPORTED ? 52 : 23)
`define XLEN 64
module testbench3();

 logic [31:0] errors=0;
 logic [31:0] vectornum=0;
 logic [`FLEN*4+7:0] testvectors[6133248:0];

//  logic 	[63:0]		X,Y,Z;
 logic 	[`FLEN-1:0]		ans;
 logic 	[7:0]	 	flags;
 logic 	[2:0]		FrmE;
 logic				FmtE;
 logic  [`FLEN-1:0]      FMAResM;
 logic  [4:0]       FMAFlgM;
integer fp;
logic 	[2:0]		FOpCtrlE;
logic 		[2*`NF+1:0]		ProdManE; 
logic 		[3*`NF+5:0]		AlignedAddendE;	
logic 		[`NE+1:0]		ProdExpE; 
logic 					AddendStickyE;
logic 					KillProdE; 
// logic					XZeroE;
// logic					YZeroE;
// logic					ZZeroE;
// logic					XDenormE;
// logic					YDenormE;
// logic					ZDenormE;
// logic					XInfE;
// logic					YInfE;
// logic					ZInfE;
// logic					XNaNE;
// logic					YNaNE;
// logic					ZNaNE;

logic wnan;
// logic XNaNE;
// logic YNaNE;
// logic ZNaNE;
logic ansnan, clk;


assign FOpCtrlE = 3'b0;  

// nearest even - 000
// twords zero - 001
// down - 010
// up - 011
// nearest max mag - 100  
assign FrmE = 3'b000;
assign FmtE = 1'b1;

    logic  [`FLEN-1:0] X, Y, Z;
    // logic         FmtE;
    // logic  [2:0]  FOpCtrlE;
    logic        XSgnE, YSgnE, ZSgnE;
    logic [`NE-1:0] XExpE, YExpE, ZExpE;
    logic [`NF-1:0] XFracE, YFracE, ZFracE;
    logic        XAssumed1E, YAssumed1E, ZAssumed1E;
    logic XNormE;
    logic XNaNE, YNaNE, ZNaNE;
    logic XSNaNE, YSNaNE, ZSNaNE;
    logic XDenormE, YDenormE, ZDenormE;
    logic XZeroE, YZeroE, ZZeroE;
    logic [`NE-1:0] BiasE;
    logic XInfE, YInfE, ZInfE;
    logic XExpMaxE;
 //***rename to make significand = 1.frac m = significand
    logic           XFracZero, YFracZero, ZFracZero; // input fraction zero
    logic           XExpZero, YExpZero, ZExpZero; // input exponent zero
    logic [`FLEN-1:0]    Addend; // value to add (Z or zero)
    logic           YExpMaxE, ZExpMaxE;  // input exponent all 1s

    assign Addend = FOpCtrlE[2] ? (`FLEN)'(0) : Z; // Z is only used in the FMA, and is set to Zero if a multiply opperation
    assign XSgnE = FmtE ? X[`FLEN-1] : X[31];
    assign YSgnE = FmtE ? Y[`FLEN-1] : Y[31];
    assign ZSgnE = FmtE ? Addend[`FLEN-1] : Addend[31];

    assign XExpE = FmtE ? X[62:52] : {X[30], {3{~X[30]&~XExpZero|XExpMaxE}}, X[29:23]}; 
    assign YExpE = FmtE ? Y[62:52] : {Y[30], {3{~Y[30]&~YExpZero|YExpMaxE}}, Y[29:23]}; 
    assign ZExpE = FmtE ? Addend[62:52] : {Addend[30], {3{~Addend[30]&~ZExpZero|ZExpMaxE}}, Addend[29:23]}; 

    assign XFracE = FmtE ? X[`NF-1:0] : {X[22:0], 29'b0};
    assign YFracE = FmtE ? Y[`NF-1:0] : {Y[22:0], 29'b0};
    assign ZFracE = FmtE ? Addend[`NF-1:0] : {Addend[22:0], 29'b0};

    assign XAssumed1E = FmtE ? |X[62:52] : |X[30:23]; 
    assign YAssumed1E = FmtE ? |Y[62:52] : |Y[30:23];
    assign ZAssumed1E = FmtE ? |Z[62:52] : |Z[30:23];

    assign XExpZero = ~XAssumed1E;
    assign YExpZero = ~YAssumed1E;
    assign ZExpZero = ~ZAssumed1E;
   
    assign XFracZero = ~|XFracE;
    assign YFracZero = ~|YFracE;
    assign ZFracZero = ~|ZFracE;

    assign XExpMaxE = FmtE ? &X[62:52] : &X[30:23];
    assign YExpMaxE = FmtE ? &Y[62:52] : &Y[30:23];
    assign ZExpMaxE = FmtE ? &Z[62:52] : &Z[30:23];
   
    assign XNormE = ~(XExpMaxE|XExpZero);
    
    assign XNaNE = XExpMaxE & ~XFracZero;
    assign YNaNE = YExpMaxE & ~YFracZero;
    assign ZNaNE = ZExpMaxE & ~ZFracZero;

    assign XSNaNE = XNaNE&~XFracE[`NF-1];
    assign YSNaNE = YNaNE&~YFracE[`NF-1];
    assign ZSNaNE = ZNaNE&~ZFracE[`NF-1];

    assign XDenormE = XExpZero & ~XFracZero;
    assign YDenormE = YExpZero & ~YFracZero;
    assign ZDenormE = ZExpZero & ~ZFracZero;

    assign XInfE = XExpMaxE & XFracZero;
    assign YInfE = YExpMaxE & YFracZero;
    assign ZInfE = ZExpMaxE & ZFracZero;

    assign XZeroE = XExpZero & XFracZero;
    assign YZeroE = YExpZero & YFracZero;
    assign ZZeroE = ZExpZero & ZFracZero;

    assign BiasE = 13'h3ff;

assign	wnan = FmtE ? &FMAResM[`FLEN-2:`NF] && |FMAResM[`NF-1:0] : &FMAResM[30:23] && |FMAResM[22:0]; 
// assign	XNaNE = FmtE ? &X[62:52] && |X[51:0] : &X[62:55] && |X[54:32]; 
// assign	YNaNE = FmtE ? &Y[62:52] && |Y[51:0] : &Y[62:55] && |Y[54:32]; 
// assign	ZNaNE = FmtE ? &Z[62:52] && |Z[51:0] : &Z[62:55] && |Z[54:32]; 
assign	ansnan = FmtE ? &ans[`FLEN-2:`NF] && |ans[`NF-1:0] : &ans[30:23] && |ans[22:0]; 
 // instantiate device under test

    logic [3*`NF+5:0]	SumE, SumM;       
    logic 			    InvZE, InvZM;
    logic 			    NegSumE, NegSumM;
    logic 			    ZSgnEffE, ZSgnEffM;
    logic 			    PSgnE, PSgnM;
    logic [8:0]			NormCntE, NormCntM;
    
    fma1 fma1 (.XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE({XAssumed1E,XFracE}), .YManE({YAssumed1E,YFracE}), .ZManE({ZAssumed1E,ZFracE}),
                 .XDenormE, .YDenormE, .ZDenormE,  .XZeroE, .YZeroE, .ZZeroE,
                .FOpCtrlE, .FmtE, .SumE, .NegSumE, .InvZE, .NormCntE, .ZSgnEffE, .PSgnE,
                .ProdExpE, .AddendStickyE, .KillProdE); 
fma2 UUT2(.XSgnM(XSgnE), .YSgnM(YSgnE), .XExpM(XExpE), .YExpM(YExpE), .ZExpM(ZExpE), .XManM({XAssumed1E,XFracE}), .YManM({YAssumed1E,YFracE}), .ZManM({ZAssumed1E,ZFracE}), .XNaNM(XNaNE), .YNaNM(YNaNE), .ZNaNM(ZNaNE), .XZeroM(XZeroE), .YZeroM(YZeroE), .ZZeroM(ZZeroE), .XInfM(XInfE), .YInfM(YInfE), .ZInfM(ZInfE), .XSNaNM(XSNaNE), .YSNaNM(YSNaNE), .ZSNaNM(ZSNaNE),
              //  .FSrcXE, .FSrcYE, .FSrcZE, .FSrcXM, .FSrcYM, .FSrcZM, 
                .KillProdM(KillProdE), .AddendStickyM(AddendStickyE), .ProdExpM(ProdExpE), .SumM(SumE), .NegSumM(NegSumE), .InvZM(InvZE), .NormCntM(NormCntE), .ZSgnEffM(ZSgnEffE), .PSgnM(PSgnE),
               .FmtM(FmtE), .FrmM(FrmE), .FMAFlgM, .FMAResM);


 // produce clock
 always
 begin
 clk = 1; #5; clk = 0; #5;
 end
 // at start of test, load vectors
 // and pulse reset
 initial
 begin
    $readmemh("testFloatNoSpace", testvectors);
 end
 // apply test vectors on rising edge of clk
always @(posedge clk)
 begin
  #1; 
  if (FmtE==1'b1) {X, Y, Z, ans, flags} = testvectors[vectornum];
  else	begin	  X = {{32{1'b1}}, testvectors[vectornum][135:104]};
  		  Y = {{32{1'b1}}, testvectors[vectornum][103:72]};
  		  Z = {{32{1'b1}}, testvectors[vectornum][71:40]};
  		  ans = {{32{1'b1}}, testvectors[vectornum][39:8]};
  		  flags = testvectors[vectornum][7:0];
  end
 end
 // check results on falling edge of clk
  always @(negedge clk) begin
 
	if((FmtE==1'b1) & (FMAFlgM != flags[4:0] || (!wnan && (FMAResM != ans)) || (wnan && ansnan && ~((XNaNE && (FMAResM[`FLEN-2:0] == {XExpE,1'b1,X[`NF-2:0]})) || (YNaNE && (FMAResM[`FLEN-2:0] == {YExpE,1'b1,Y[`NF-2:0]}))  || (ZNaNE && (FMAResM[`FLEN-2:0] == {ZExpE,1'b1,Z[`NF-2:0]})) || (FMAResM[`FLEN-2:0] == ans[`FLEN-2:0]))))) begin
  //  fp = $fopen("/home/kparry/riscv-wally/pipelined/src/fpu/FMA/tbgen/results.dat","w");
	// if((FmtE==1'b1) & (FMAFlgM != flags[4:0] || (FMAResM != ans))) begin
        $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
		if(FMAResM == 64'h8000000000000000) $display( "FMAResM=-zero ");
		if(XDenormE) $display( "xdenorm ");
		if(YDenormE) $display( "ydenorm ");
		if(ZDenormE) $display( "zdenorm ");
		if(FMAFlgM[4] != 0) $display( "invld ");
		if(FMAFlgM[2] != 0) $display( "ovrflw ");
		if(FMAFlgM[1] != 0) $display( "unflw ");
		if(FMAResM[`FLEN] && FMAResM[`FLEN-2:`NF] == {`NE{1'b1}} && FMAResM[`NF-1:0] == 0) $display( "FMAResM=-inf ");
		if(~FMAResM[`FLEN] && FMAResM[`FLEN-2:`NF] == {`NE{1'b1}} && FMAResM[`NF-1:0] == 0) $display( "FMAResM=+inf ");
		if(FMAResM[`FLEN-2:`NF] == {`NE{1'b1}} && FMAResM[`NF-1:0] != 0 && ~FMAResM[`NF-1]) $display( "FMAResM=sigNaN ");
		if(FMAResM[`FLEN-2:`NF] == {`NE{1'b1}} && FMAResM[`NF-1:0] != 0 && FMAResM[`NF-1]) $display( "FMAResM=qutNaN ");
		if(ans[`FLEN] && ans[`FLEN-2:`NF] == {`NE{1'b1}} && ans[`NF-1:0] == 0) $display( "ans=-inf ");
		if(~ans[`FLEN] && ans[`FLEN-2:`NF] == {`NE{1'b1}} && ans[`NF-1:0] == 0) $display( "ans=+inf ");
		if(ans[`FLEN-2:`NF] == {`NE{1'b1}} && ans[`NF-1:0] != 0 && ~ans[`NF-1]) $display( "ans=sigNaN ");
		if(ans[`FLEN-2:`NF] == {`NE{1'b1}} && ans[`NF-1:0] != 0 && ans[`NF-1]) $display( "ans=qutNaN ");
        errors = errors + 1;
	  //if (errors == 10)
		$stop;
    end
    if((FmtE==1'b0)&(FMAFlgM != flags[4:0] || (!wnan && (FMAResM != ans)) || (wnan && ansnan && ~(((XNaNE && (FMAResM[30:0] == {X[30:23],1'b1,X[21:0]})) || (YNaNE && (FMAResM[30:0] == {Y[30:23],1'b1,Y[21:0]}))  || (ZNaNE && (FMAResM[30:0] == {Z[30:23],1'b1,Z[21:0]})) || (FMAResM[30:0] == ans[30:0]))) ))) begin
        $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
		if(FMAResM == 64'h8000000000000000) $display( "FMAResM=-zero ");
		if(~(|X[30:23]) && |X[22:0]) $display( "xdenorm ");
		if(~(|Y[30:23]) && |Y[22:0]) $display( "ydenorm ");
		if(~(|Z[30:23]) && |Z[22:0]) $display( "zdenorm ");
		if(FMAFlgM[4] != 0) $display( "invld ");
		if(FMAFlgM[2] != 0) $display( "ovrflw ");
		if(FMAFlgM[1] != 0) $display( "unflw ");
		if(FMAResM == 64'hFF80000000000000) $display( "FMAResM=-inf ");
		if(FMAResM == 64'h7F80000000000000) $display( "FMAResM=+inf ");
		if(&FMAResM[30:23] && |FMAResM[22:0] && ~FMAResM[22]) $display( "FMAResM=sigNaN ");
		if(&FMAResM[30:23] && |FMAResM[22:0] && FMAResM[22] ) $display( "FMAResM=qutNaN ");
		if(ans == 64'hFF80000000000000) $display( "ans=-inf ");
		if(ans == 64'h7F80000000000000) $display( "ans=+inf ");
		if(&ans[30:23] && |ans[22:0] && ~ans[22] ) $display( "ans=sigNaN ");
		if(&ans[30:23] && |ans[22:0] && ans[22]) $display( "ans=qutNaN ");
        errors = errors + 1;
	  if (errors == 10)
		$stop;
    end
 vectornum = vectornum + 1;
 if (testvectors[vectornum] === 194'bx) begin
 $display("%d tests completed with %d errors", vectornum, errors);
 $stop;
 end
 end
endmodule
