
`include "../../../config/old/rv64icfd/wally-config.vh"

// `define FLEN (`Q_SUPPORTED ? 128 : `D_SUPPORTED ? 64 : `F_SUPPORTED ? 32 : 16)
// `define NE   (`Q_SUPPORTED ? 15 : `D_SUPPORTED ? 11 : `F_SUPPORTED ? 8 : 5)
// `define NF   (`Q_SUPPORTED ? 112 : `D_SUPPORTED ? 52 : `F_SUPPORTED ? 23 : 10)
// `define FMT (`Q_SUPPORTED ? 3 : `D_SUPPORTED ? 1 : `F_SUPPORTED ? 0 : 2)
// `define BIAS (`Q_SUPPORTED ? 16383 : `D_SUPPORTED ? 1023 : `F_SUPPORTED ? 127 : 15)
// `define XLEN 64
// `define IEEE754 1
`define Q_SUPPORTED 1
// `define D_SUPPORTED 0
// `define F_SUPPORTED 0
`define H_SUPPORTED 0
`define FPSIZES ((`Q_SUPPORTED&`D_SUPPORTED&`F_SUPPORTED&`H_SUPPORTED) ? 4 : (`Q_SUPPORTED&`D_SUPPORTED&`F_SUPPORTED) | (`Q_SUPPORTED&`D_SUPPORTED&`H_SUPPORTED) | (`Q_SUPPORTED&`F_SUPPORTED&`H_SUPPORTED) | (`D_SUPPORTED&`F_SUPPORTED&`H_SUPPORTED) ? 3 : (`Q_SUPPORTED&`D_SUPPORTED) | (`Q_SUPPORTED&`F_SUPPORTED) | (`Q_SUPPORTED&`H_SUPPORTED) | (`D_SUPPORTED&`F_SUPPORTED) | (`D_SUPPORTED&`H_SUPPORTED) | (`F_SUPPORTED&`H_SUPPORTED) ? 2 : 1)
`define LEN1  ((`D_SUPPORTED & (`FLEN !== 64)) ? 64   : (`F_SUPPORTED & (`FLEN !== 32)) ? 32  : 16)
`define NE1   ((`D_SUPPORTED & (`FLEN !== 64)) ? 11   : (`F_SUPPORTED & (`FLEN !== 32)) ? 8   : 5)
`define NF1   ((`D_SUPPORTED & (`FLEN !== 64)) ? 52   : (`F_SUPPORTED & (`FLEN !== 32)) ? 23  : 10)
`define FMT1  ((`D_SUPPORTED & (`FLEN !== 64)) ? 1    : (`F_SUPPORTED & (`FLEN !== 32)) ? 0   : 2)
`define BIAS1 ((`D_SUPPORTED & (`FLEN !== 64)) ? 1023 : (`F_SUPPORTED & (`FLEN !== 32)) ? 127 : 15)
`define LEN2  ((`F_SUPPORTED & (`LEN1 !== 32)) ? 32   : 16)
`define NE2   ((`F_SUPPORTED & (`LEN1 !== 32)) ? 8    : 5)
`define NF2   ((`F_SUPPORTED & (`LEN1 !== 32)) ? 23   : 10)
`define FMT2  ((`F_SUPPORTED & (`LEN1 !== 32)) ? 0    : 2)
`define BIAS2 ((`F_SUPPORTED & (`LEN1 !== 32)) ? 127  : 15)
`define LEN3 16
`define NE3 5//make constants for the constants ie 11/8/5 ect
`define NF3 10 // always support less hten max - maybe halfs
`define FMT3 2
`define BIAS3 15
module testbench3();

 logic [31:0] errors=0;
 logic [31:0] vectornum=0;
 logic [`FLEN*4+7:0] testvectors[6133248:0];

//  logic 	[63:0]		X,Y,Z;
 logic 	[`FLEN-1:0]		ans;
 logic 	[7:0]	 	flags;
 logic 	[2:0]		FrmE;
 logic	[`FPSIZES/3:0]			FmtE;
 logic  [`FLEN-1:0]      FMAResM;
 logic  [4:0]       FMAFlgM;
logic 	[2:0]		FOpCtrlE;
logic 		[2*`NF+1:0]		ProdManE; 
logic 		[3*`NF+5:0]		AlignedAddendE;	
logic 		[`NE+1:0]		ProdExpE; 
logic 					AddendStickyE;
logic 					KillProdE; 

logic wnan;
logic ansnan, clk;


assign FOpCtrlE = 3'b0;  

// nearest even - 000
// twords zero - 001
// down - 010
// up - 011
// nearest max mag - 100  
assign FrmE = 3'b010;
assign FmtE = (`FPSIZES/3+1)'(1);

    logic  [`FLEN-1:0] X, Y, Z;
    // logic         FmtE;
    // logic  [2:0]  FOpCtrlE;
    logic        XSgnE, YSgnE, ZSgnE;
    logic [`NE-1:0] XExpE, YExpE, ZExpE;
    logic [`NF:0] XManE, YManE, ZManE;
    logic XNormE;
    logic XExpMaxE;
    logic XNaNE, YNaNE, ZNaNE;
    logic XSNaNE, YSNaNE, ZSNaNE;
    logic XDenormE, YDenormE, ZDenormE;
    logic XZeroE, YZeroE, ZZeroE;
    logic [`NE-1:0] BiasE;
    logic XInfE, YInfE, ZInfE;
    logic [`FLEN-1:0]    Addend; // value to add (Z or zero)
    logic           YExpMaxE, ZExpMaxE, Mult;  // input exponent all 1s

	assign Mult = 1'b0;
  unpacking unpacking(.*);

// assign	wnan = XNaNE|YNaNE|ZNaNE; 
// assign	ansnan = FmtE ? &ans[`FLEN-2:`NF] && |ans[`NF-1:0] : &ans[30:23] && |ans[22:0]; 
 
    if (`FPSIZES === 1) begin
      assign ansnan = &ans[`FLEN-2:`NF]&(|ans[`NF-1:0]);
      assign wnan = &FMAResM[`FLEN-2:`NF]&(|FMAResM[`NF-1:0]);
    end else if (`FPSIZES === 2) begin                  
      assign ansnan = FmtE ? &ans[`FLEN-2:`NF]&(|ans[`NF-1:0]) : &ans[`LEN1-2:`NF1]&(|ans[`NF1-1:0]);
      assign wnan = FmtE ? &FMAResM[`FLEN-2:`NF]&(|FMAResM[`NF-1:0]) : &FMAResM[`LEN1-2:`NF1]&(|FMAResM[`NF1-1:0]);
    end else if (`FPSIZES === 3) begin
        always_comb begin
            case (FmtE)
                `FMT: begin                  
                  assign ansnan = &ans[`FLEN-2:`NF]&(|ans[`NF-1:0]);
                  assign wnan = &FMAResM[`FLEN-2:`NF]&(|FMAResM[`NF-1:0]);

                end
                `FMT1: begin                    
                  assign ansnan = &ans[`LEN1-2:`NF1]&(|ans[`NF1-1:0]);
                  assign wnan = &FMAResM[`LEN1-2:`NF1]&(|FMAResM[`NF1-1:0]);

                end
                `FMT2: begin
                    assign ansnan = &ans[`LEN2-2:`NF2]&(|ans[`NF2-1:0]);
                    assign wnan = &FMAResM[`LEN2-2:`NF2]&(|FMAResM[`NF2-1:0]);
                end
                default: begin
                    assign ansnan = 0;
                    assign wnan = 0;
                end
            endcase
        end

    end else begin
        always_comb begin
            case (FmtE)
                `FMT: begin                  
                  assign ansnan = &ans[`FLEN-2:`NF]&(|ans[`NF-1:0]);
                  assign wnan = &FMAResM[`FLEN-2:`NF]&(|FMAResM[`NF-1:0]);

                end
                `FMT1: begin                    
                  assign ansnan = &ans[`LEN1-2:`NF1]&(|ans[`NF1-1:0]);
                  assign wnan = &FMAResM[`LEN1-2:`NF1]&(|FMAResM[`NF1-1:0]);

                end
                `FMT2: begin
                    assign ansnan = &ans[`LEN2-2:`NF2]&(|ans[`NF2-1:0]);
                    assign wnan = &FMAResM[`LEN2-2:`NF2]&(|FMAResM[`NF2-1:0]);
                end
                `FMT3: begin
                    assign ansnan = &ans[`LEN3-2:`NF3]&(|ans[`NF3-1:0]);
                    assign wnan = &FMAResM[`LEN3-2:`NF3]&(|FMAResM[`NF3-1:0]);
                end
            endcase
        end
    end
 // instantiate device under test

    logic [3*`NF+5:0]	SumE, SumM;       
    logic 			    InvZE, InvZM;
    logic 			    NegSumE, NegSumM;
    logic 			    ZSgnEffE, ZSgnEffM;
    logic 			    PSgnE, PSgnM;
    logic [$clog2(3*`NF+7)-1:0]			NormCntE, NormCntM;
    
    fma1 fma1 (.XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE,
                 .XDenormE, .YDenormE, .ZDenormE,  .XZeroE, .YZeroE, .ZZeroE,
                .FOpCtrlE, .FmtE, .SumE, .NegSumE, .InvZE, .NormCntE, .ZSgnEffE, .PSgnE,
                .ProdExpE, .AddendStickyE, .KillProdE); 
fma2 UUT2(.XSgnM(XSgnE), .YSgnM(YSgnE), .XExpM(XExpE), .YExpM(YExpE), .ZExpM(ZExpE), .XManM(XManE), .YManM(YManE), .ZManM(ZManE), .XNaNM(XNaNE), .YNaNM(YNaNE), .ZNaNM(ZNaNE), .XZeroM(XZeroE), .YZeroM(YZeroE), .ZZeroM(ZZeroE), .XInfM(XInfE), .YInfM(YInfE), .ZInfM(ZInfE), .XSNaNM(XSNaNE), .YSNaNM(YSNaNE), .ZSNaNM(ZSNaNE),
              //  .FSrcXE, .FSrcYE, .FSrcZE, .FSrcXM, .FSrcYM, .FSrcZM, 
                .KillProdM(KillProdE), .AddendStickyM(AddendStickyE), .ProdExpM(ProdExpE), .SumM(SumE), .NegSumM(NegSumE), .InvZM(InvZE), .NormCntM(NormCntE), .ZSgnEffM(ZSgnEffE), .PSgnM(PSgnE),
               .FmtM(FmtE), .FrmM(FrmE), .FMAFlgM, .FMAResM, .Mult);


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
  if (`FPSIZES === 3 | `FPSIZES === 4) begin
    if (FmtE==2'b11) {X, Y, Z, ans, flags} = testvectors[vectornum];
    else if (FmtE==2'b01)	begin	  
      X = {{`FLEN-64{1'b1}}, testvectors[vectornum][263:200]};
      Y = {{`FLEN-64{1'b1}}, testvectors[vectornum][199:136]};
      Z = {{`FLEN-64{1'b1}}, testvectors[vectornum][135:72]};
      ans = {{`FLEN-64{1'b1}}, testvectors[vectornum][71:8]};
      flags = testvectors[vectornum][7:0];
    end
    else if (FmtE==2'b00)	begin	  
      X = {{`FLEN-32{1'b1}}, testvectors[vectornum][135:104]};
      Y = {{`FLEN-32{1'b1}}, testvectors[vectornum][103:72]};
      Z = {{`FLEN-32{1'b1}}, testvectors[vectornum][71:40]};
      ans = {{`FLEN-32{1'b1}}, testvectors[vectornum][39:8]};
      flags = testvectors[vectornum][7:0];
    end
    else	begin	  
      X = {{`FLEN-16{1'b1}}, testvectors[vectornum][71:56]};
      Y = {{`FLEN-16{1'b1}}, testvectors[vectornum][55:40]};
      Z = {{`FLEN-16{1'b1}}, testvectors[vectornum][39:24]};
      ans = {{`FLEN-16{1'b1}}, testvectors[vectornum][23:8]};
      flags = testvectors[vectornum][7:0];
    end
  end
  else begin
    if (FmtE==1'b1) {X, Y, Z, ans, flags} = testvectors[vectornum];
    else if (FmtE==1'b0)	begin	  
      X = {{`FLEN-`LEN1{1'b1}}, testvectors[vectornum][8+4*(`LEN1)-1:8+3*(`LEN1)]};
      Y = {{`FLEN-`LEN1{1'b1}}, testvectors[vectornum][8+3*(`LEN1)-1:8+2*(`LEN1)]};
      Z = {{`FLEN-`LEN1{1'b1}}, testvectors[vectornum][8+2*(`LEN1)-1:8+(`LEN1)]};
      ans = {{`FLEN-`LEN1{1'b1}}, testvectors[vectornum][8+(`LEN1-1):8]};
      flags = testvectors[vectornum][7:0];
    end
  end
 end
 // check results on falling edge of clk
  always @(negedge clk) begin
      if (`FPSIZES === 1 | `FPSIZES === 2) begin
        if((FmtE==1'b1) & (FMAFlgM !== flags[4:0] || (!wnan && (FMAResM !== ans)) || (wnan && ansnan && ~((XNaNE && (FMAResM[`FLEN-2:0] === {X[`FLEN-2:`NF],1'b1,X[`NF-2:0]})) || (YNaNE && (FMAResM[`FLEN-2:0] === {Y[`FLEN-2:`NF],1'b1,Y[`NF-2:0]}))  || (ZNaNE && (FMAResM[`FLEN-2:0] === {Z[`FLEN-2:`NF],1'b1,Z[`NF-2:0]})) || (FMAResM[`FLEN-2:0] === ans[`FLEN-2:0]))))) begin
        //  fp = $fopen("/home/kparry/riscv-wally/pipelined/src/fpu/FMA/tbgen/results.dat","w");
        // if((FmtE==1'b1) & (FMAFlgM !== flags[4:0] || (FMAResM !== ans))) begin
              $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
          if(XDenormE) $display( "xdenorm ");
          if(YDenormE) $display( "ydenorm ");
          if(ZDenormE) $display( "zdenorm ");
          if(FMAFlgM[4] !== 0) $display( "invld ");
          if(FMAFlgM[2] !== 0) $display( "ovrflw ");
          if(FMAFlgM[1] !== 0) $display( "unflw ");
          if(FMAResM[`FLEN] && FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] === 0) $display( "FMAResM=-inf ");
          if(~FMAResM[`FLEN] && FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] === 0) $display( "FMAResM=+inf ");
          if(FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] !== 0 && ~FMAResM[`NF-1]) $display( "FMAResM=sigNaN ");
          if(FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] !== 0 && FMAResM[`NF-1]) $display( "FMAResM=qutNaN ");
          if(ans[`FLEN] && ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] === 0) $display( "ans=-inf ");
          if(~ans[`FLEN] && ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] === 0) $display( "ans=+inf ");
          if(ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] !== 0 && ~ans[`NF-1]) $display( "ans=sigNaN ");
          if(ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] !== 0 && ans[`NF-1]) $display( "ans=qutNaN ");
              errors = errors + 1;
          //if (errors === 10)
          $stop;
          end
          if((FmtE==1'b0)&(FMAFlgM !== flags[4:0] || (!wnan && (FMAResM !== ans)) || (wnan && ansnan && ~(((XNaNE && (FMAResM[`LEN1-2:0] === {X[`LEN1-2:`NF1],1'b1,X[`NF1-2:0]})) || (YNaNE && (FMAResM[`LEN1-2:0] === {Y[`LEN1-2:`NF1],1'b1,Y[`NF1-2:0]}))  || (ZNaNE && (FMAResM[`LEN1-2:0] === {Z[`LEN1-2:`NF1],1'b1,Z[`NF1-2:0]})) || (FMAResM[`LEN1-2:0] === ans[`LEN1-2:0]))) ))) begin
              $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
          if(~(|X[30:23]) && |X[22:0]) $display( "xdenorm ");
          if(~(|Y[30:23]) && |Y[22:0]) $display( "ydenorm ");
          if(~(|Z[30:23]) && |Z[22:0]) $display( "zdenorm ");
          if(FMAFlgM[4] !== 0) $display( "invld ");
          if(FMAFlgM[2] !== 0) $display( "ovrflw ");
          if(FMAFlgM[1] !== 0) $display( "unflw ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && ~FMAResM[22]) $display( "FMAResM=sigNaN ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && FMAResM[22] ) $display( "FMAResM=qutNaN ");
          if(&ans[30:23] && |ans[22:0] && ~ans[22] ) $display( "ans=sigNaN ");
          if(&ans[30:23] && |ans[22:0] && ans[22]) $display( "ans=qutNaN ");
              errors = errors + 1;
        // if (errors === 9)
          $stop;
          end
 end else begin
   
        if((FmtE==2'b11) & (FMAFlgM !== flags[4:0] || (!wnan && (FMAResM !== ans)) || (wnan && ansnan && ~((XNaNE && (FMAResM[`FLEN-2:0] === {X[`FLEN-2:`NF],1'b1,X[`NF-2:0]})) || (YNaNE && (FMAResM[`FLEN-2:0] === {Y[`FLEN-2:`NF],1'b1,Y[`NF-2:0]}))  || (ZNaNE && (FMAResM[`FLEN-2:0] === {Z[`FLEN-2:`NF],1'b1,Z[`NF-2:0]})) || (FMAResM[`FLEN-2:0] === ans[`FLEN-2:0]))))) begin
        //  fp = $fopen("/home/kparry/riscv-wally/pipelined/src/fpu/FMA/tbgen/results.dat","w");
        // if((FmtE==1'b1) & (FMAFlgM !== flags[4:0] || (FMAResM !== ans))) begin
              $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
          if(XDenormE) $display( "xdenorm ");
          if(YDenormE) $display( "ydenorm ");
          if(ZDenormE) $display( "zdenorm ");
          if(FMAFlgM[4] !== 0) $display( "invld ");
          if(FMAFlgM[2] !== 0) $display( "ovrflw ");
          if(FMAFlgM[1] !== 0) $display( "unflw ");
          if(FMAResM[`FLEN] && FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] === 0) $display( "FMAResM=-inf ");
          if(~FMAResM[`FLEN] && FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] === 0) $display( "FMAResM=+inf ");
          if(FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] !== 0 && ~FMAResM[`NF-1]) $display( "FMAResM=sigNaN ");
          if(FMAResM[`FLEN-2:`NF] === {`NE{1'b1}} && FMAResM[`NF-1:0] !== 0 && FMAResM[`NF-1]) $display( "FMAResM=qutNaN ");
          if(ans[`FLEN] && ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] === 0) $display( "ans=-inf ");
          if(~ans[`FLEN] && ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] === 0) $display( "ans=+inf ");
          if(ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] !== 0 && ~ans[`NF-1]) $display( "ans=sigNaN ");
          if(ans[`FLEN-2:`NF] === {`NE{1'b1}} && ans[`NF-1:0] !== 0 && ans[`NF-1]) $display( "ans=qutNaN ");
              errors = errors + 1;
          //if (errors === 10)
          $stop;
          end
          if((FmtE==1'b01)&(FMAFlgM !== flags[4:0] || (!wnan && (FMAResM !== ans)) || (wnan && ansnan && ~(((XNaNE && (FMAResM[64-2:0] === {X[64-2:52],1'b1,X[52-2:0]})) || (YNaNE && (FMAResM[64-2:0] === {Y[64-2:52],1'b1,Y[52-2:0]}))  || (ZNaNE && (FMAResM[64-2:0] === {Z[64-2:52],1'b1,Z[52-2:0]})) || (FMAResM[62:0] === ans[62:0]))) ))) begin
              $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
          if(~(|X[30:23]) && |X[22:0]) $display( "xdenorm ");
          if(~(|Y[30:23]) && |Y[22:0]) $display( "ydenorm ");
          if(~(|Z[30:23]) && |Z[22:0]) $display( "zdenorm ");
          if(FMAFlgM[4] !== 0) $display( "invld ");
          if(FMAFlgM[2] !== 0) $display( "ovrflw ");
          if(FMAFlgM[1] !== 0) $display( "unflw ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && ~FMAResM[22]) $display( "FMAResM=sigNaN ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && FMAResM[22] ) $display( "FMAResM=qutNaN ");
          if(&ans[30:23] && |ans[22:0] && ~ans[22] ) $display( "ans=sigNaN ");
          if(&ans[30:23] && |ans[22:0] && ans[22]) $display( "ans=qutNaN ");
              errors = errors + 1;
        // if (errors === 9)
          $stop;
          end
          if((FmtE==2'b00)&(FMAFlgM !== flags[4:0] || (!wnan && (FMAResM !== ans)) || (wnan && ansnan && ~(((XNaNE && (FMAResM[32-2:0] === {X[32-2:23],1'b1,X[23-2:0]})) || (YNaNE && (FMAResM[32-2:0] === {Y[32-2:23],1'b1,Y[23-2:0]}))  || (ZNaNE && (FMAResM[32-2:0] === {Z[32-2:23],1'b1,Z[23-2:0]})) || (FMAResM[30:0] === ans[30:0]))) ))) begin
              $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
          if(~(|X[30:23]) && |X[22:0]) $display( "xdenorm ");
          if(~(|Y[30:23]) && |Y[22:0]) $display( "ydenorm ");
          if(~(|Z[30:23]) && |Z[22:0]) $display( "zdenorm ");
          if(FMAFlgM[4] !== 0) $display( "invld ");
          if(FMAFlgM[2] !== 0) $display( "ovrflw ");
          if(FMAFlgM[1] !== 0) $display( "unflw ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && ~FMAResM[22]) $display( "FMAResM=sigNaN ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && FMAResM[22] ) $display( "FMAResM=qutNaN ");
          if(&ans[30:23] && |ans[22:0] && ~ans[22] ) $display( "ans=sigNaN ");
          if(&ans[30:23] && |ans[22:0] && ans[22]) $display( "ans=qutNaN ");
              errors = errors + 1;
        // if (errors === 9)
          $stop;
          end
          if((FmtE==2'b10)&(FMAFlgM !== flags[4:0] || (!wnan && (FMAResM !== ans)) || (wnan && ansnan && ~(((XNaNE && (FMAResM[16-2:0] === {X[16-2:10],1'b1,X[10-2:0]})) || (YNaNE && (FMAResM[16-2:0] === {Y[16-2:10],1'b1,Y[10-2:0]}))  || (ZNaNE && (FMAResM[16-2:0] === {Z[16-2:10],1'b1,Z[10-2:0]})) || (FMAResM[14:0] === ans[14:0]))) ))) begin
              $display( "%h %h %h %h %h %h %h  Wrong ",X,Y, Z, FMAResM, ans, FMAFlgM, flags);
          if(~(|X[30:23]) && |X[22:0]) $display( "xdenorm ");
          if(~(|Y[30:23]) && |Y[22:0]) $display( "ydenorm ");
          if(~(|Z[30:23]) && |Z[22:0]) $display( "zdenorm ");
          if(FMAFlgM[4] !== 0) $display( "invld ");
          if(FMAFlgM[2] !== 0) $display( "ovrflw ");
          if(FMAFlgM[1] !== 0) $display( "unflw ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && ~FMAResM[22]) $display( "FMAResM=sigNaN ");
          if(&FMAResM[30:23] && |FMAResM[22:0] && FMAResM[22] ) $display( "FMAResM=qutNaN ");
          if(&ans[30:23] && |ans[22:0] && ~ans[22] ) $display( "ans=sigNaN ");
          if(&ans[30:23] && |ans[22:0] && ans[22]) $display( "ans=qutNaN ");
              errors = errors + 1;
        // if (errors === 9)
          $stop;
          end
 end
	
 vectornum = vectornum + 1;
 if (testvectors[vectornum] === 194'bx) begin
 $display("%d tests completed with %d errors", vectornum, errors);
 $stop;
 end
 end
endmodule
