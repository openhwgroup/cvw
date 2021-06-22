module testbench3();

 logic [31:0] errors=0;
 logic [31:0] vectornum=0;
 logic [264:0] testvectors[6133248:0];

 logic 	[63:0]		FInput1E,FInput2E,FInput3E;
 logic 	[63:0]		ans;
 logic 	[7:0]	 	flags;
 logic 	[2:0]		FrmE;
 logic				FmtE;
 logic  [63:0]      FmaResultM;
 logic  [4:0]       FmaFlagsM;
integer fp;
logic 	[2:0]		FOpCtrlE;
logic 		[105:0]		ProdManE; 
logic 		[161:0]		AlignedAddendE;	
logic 		[12:0]		ProdExpE; 
logic 					AddendStickyE;
logic 					KillProdE; 
logic					XZeroE;
logic					YZeroE;
logic					ZZeroE;
logic					XDenormE;
logic					YDenormE;
logic					ZDenormE;
logic					XInfE;
logic					YInfE;
logic					ZInfE;
logic					XNaNE;
logic					YNaNE;
logic					ZNaNE;

logic wnan;
logic xnan;
logic ynan;
logic znan;
logic ansnan, clk;


assign FOpCtrlE = 3'b0;  

// nearest even - 000
// twords zero - 001
// down - 010
// up - 011
// nearest max mag - 100  
assign FrmE = 3'b010;
assign FmtE = 1'b1;


assign	wnan = FmtE ? &FmaResultM[62:52] && |FmaResultM[51:0] : &FmaResultM[62:55] && |FmaResultM[54:32]; 
assign	xnan = FmtE ? &FInput1E[62:52] && |FInput1E[51:0] : &FInput1E[62:55] && |FInput1E[54:32]; 
assign	ynan = FmtE ? &FInput2E[62:52] && |FInput2E[51:0] : &FInput2E[62:55] && |FInput2E[54:32]; 
assign	znan = FmtE ? &FInput3E[62:52] && |FInput3E[51:0] : &FInput3E[62:55] && |FInput3E[54:32]; 
assign	ansnan = FmtE ? &ans[62:52] && |ans[51:0] : &ans[62:55] && |ans[54:32]; 
 // instantiate device under test
fma1 UUT1(.X(FInput1E), .Y(FInput2E), .Z(FInput3E), .*);
fma2 UUT2(.X(FInput1E), .Y(FInput2E), .Z(FInput3E), .FrmM(FrmE), .ProdManM(ProdManE),
			.AlignedAddendM(AlignedAddendE), .ProdExpM(ProdExpE), .AddendStickyM(AddendStickyE),.KillProdM(KillProdE), .FOpCtrlM(FOpCtrlE),
			.XZeroM(XZeroE),.YZeroM(YZeroE),.ZZeroM(ZZeroE),.XInfM(XInfE),.YInfM(YInfE),.ZInfM(ZInfE),.XNaNM(XNaNE),.YNaNM(YNaNE),.ZNaNM(ZNaNE), .FmtM(FmtE), .*);


 // generate clock
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
  if (FmtE==1'b1) {FInput1E, FInput2E, FInput3E, ans, flags} = testvectors[vectornum];
  else	begin	  FInput1E = {testvectors[vectornum][135:104],32'b0};
  		  FInput2E = {testvectors[vectornum][103:72],32'b0};
  		  FInput3E = {testvectors[vectornum][71:40],32'b0};
  		  ans = {testvectors[vectornum][39:8],32'b0};
  		  flags = testvectors[vectornum][7:0];
  end
 end
 // check results on falling edge of clk
  always @(negedge clk) begin
 
  //  fp = $fopen("/home/kparry/riscv-wally/wally-pipelined/src/fpu/FMA/tbgen/results.dat","w");
	if((FmtE==1'b1) & (FmaFlagsM != flags[4:0] || (!wnan && (FmaResultM != ans)) || (wnan && ansnan && ~((xnan && (FmaResultM[62:0] == {FInput1E[62:52],1'b1,FInput1E[50:0]})) || (ynan && (FmaResultM[62:0] == {FInput2E[62:52],1'b1,FInput2E[50:0]}))  || (znan && (FmaResultM[62:0] == {FInput3E[62:52],1'b1,FInput3E[50:0]})) || (FmaResultM[62:0] == ans[62:0]))))) begin
        $display( "%h %h %h %h %h %h %h  Wrong ",FInput1E,FInput2E, FInput3E, FmaResultM, ans, FmaFlagsM, flags);
		if(FmaResultM == 64'h8000000000000000) $display( "FmaResultM=-zero ");
		if(~(|FInput1E[62:52]) && |FInput1E[51:0]) $display( "xdenorm ");
		if(~(|FInput2E[62:52]) && |FInput2E[51:0]) $display( "ydenorm ");
		if(~(|FInput3E[62:52]) && |FInput3E[51:0]) $display( "zdenorm ");
		if(FmaFlagsM[4] != 0) $display( "invld ");
		if(FmaFlagsM[2] != 0) $display( "ovrflw ");
		if(FmaFlagsM[1] != 0) $display( "unflw ");
		if(FmaResultM == 64'hFFF0000000000000) $display( "FmaResultM=-inf ");
		if(FmaResultM == 64'h7FF0000000000000) $display( "FmaResultM=+inf ");
		if(FmaResultM >  64'h7FF0000000000000 && FmaResultM <  64'h7FF8000000000000 ) $display( "FmaResultM=sigNaN ");
		if(FmaResultM >  64'hFFF8000000000000 && FmaResultM <  64'hFFF8000000000000 ) $display( "FmaResultM=sigNaN ");
		if(FmaResultM >= 64'h7FF8000000000000 && FmaResultM <= 64'h7FFfffffffffffff ) $display( "FmaResultM=qutNaN ");
		if(FmaResultM >= 64'hFFF8000000000000 && FmaResultM <= 64'hFFFfffffffffffff ) $display( "FmaResultM=qutNaN ");
		if(ans == 64'hFFF0000000000000) $display( "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $display( "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $display( "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $display( "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $display( "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $display( "ans=qutNaN ");
        errors = errors + 1;
	  if (errors == 20)
		$stop;
    end
    if((FmtE==1'b0)&(FmaFlagsM != flags[4:0] || (!wnan && (FmaResultM != ans)) || (wnan && ansnan && ~(((xnan && (FmaResultM[62:0] == {FInput1E[62:55],1'b1,FInput1E[53:0]})) || (ynan && (FmaResultM[62:0] == {FInput2E[62:55],1'b1,FInput2E[53:0]}))  || (znan && (FmaResultM[62:0] == {FInput3E[62:55],1'b1,FInput3E[53:0]})) || (FmaResultM[62:0] == ans[62:0]))) ))) begin
        $display( "%h %h %h %h %h %h %h  Wrong ",FInput1E,FInput2E, FInput3E, FmaResultM, ans, FmaFlagsM, flags);
		if(FmaResultM == 64'h8000000000000000) $display( "FmaResultM=-zero ");
		if(~(|FInput1E[62:55]) && |FInput1E[54:32]) $display( "xdenorm ");
		if(~(|FInput2E[62:55]) && |FInput2E[54:32]) $display( "ydenorm ");
		if(~(|FInput3E[62:55]) && |FInput3E[54:32]) $display( "zdenorm ");
		if(FmaFlagsM[4] != 0) $display( "invld ");
		if(FmaFlagsM[2] != 0) $display( "ovrflw ");
		if(FmaFlagsM[1] != 0) $display( "unflw ");
		if(FmaResultM == 64'hFF80000000000000) $display( "FmaResultM=-inf ");
		if(FmaResultM == 64'h7F80000000000000) $display( "FmaResultM=+inf ");
		if(&FmaResultM[62:55] && |FmaResultM[54:32] && ~FmaResultM[54]) $display( "FmaResultM=sigNaN ");
		if(&FmaResultM[62:55] && |FmaResultM[54:32] && FmaResultM[54] ) $display( "FmaResultM=qutNaN ");
		if(ans == 64'hFF80000000000000) $display( "ans=-inf ");
		if(ans == 64'h7F80000000000000) $display( "ans=+inf ");
		if(&ans[62:55] && |ans[54:32] && ~ans[54] ) $display( "ans=sigNaN ");
		if(&ans[62:55] && |ans[54:32] && ans[54]) $display( "ans=qutNaN ");
        errors = errors + 1;
	  //if (errors == 10)
		$stop;
    end
 vectornum = vectornum + 1;
 if (testvectors[vectornum] === 194'bx) begin
 $display("%d tests completed with %d errors", vectornum, errors);
 $stop;
 end
 end
endmodule
