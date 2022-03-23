
`include "wally-config.vh"
`define PATH "../../../../tests/fp/vectors/"

string tests[] = '{
    "f16_mulAdd_rne.tv",
    "f16_mulAdd_rz.tv",
    "f16_mulAdd_ru.tv",
    "f16_mulAdd_rd.tv",
    "f16_mulAdd_rnm.tv",
    "f32_mulAdd_rne.tv",
    "f32_mulAdd_rz.tv",
    "f32_mulAdd_ru.tv",
    "f32_mulAdd_rd.tv",
    "f32_mulAdd_rnm.tv",
    "f64_mulAdd_rne.tv",
    "f64_mulAdd_rz.tv",
    "f64_mulAdd_ru.tv",
    "f64_mulAdd_rd.tv",
    "f64_mulAdd_rnm.tv",
    "f128_mulAdd_rne.tv",
    "f128_mulAdd_rz.tv",
    "f128_mulAdd_ru.tv",
    "f128_mulAdd_rd.tv",
    "f128_mulAdd_rnm.tv"
};

// steps to run FMA tests
//    1) create test vectors in riscv-wally/tests/fp with: ./run-all.sh
//    2) go to riscv-wally/pipelined/testbench/fp/tests
//    3) run ./sim-wally-batch

module fmatestbench();

  logic clk;
  logic [31:0] errors=0;
  logic [31:0] vectornum=0;
  logic [`FLEN*4+7+4+4:0] testvectors[6133248:0];
  int i = `ZFH_SUPPORTED ? 0 : `F_SUPPORTED ? 5 : `D_SUPPORTED ? 10 : 15; // set i to the first test that is run

  logic [`FLEN-1:0]     X, Y, Z;  // inputs read from TestFloat
  logic [`FLEN-1:0]	    ans;      // result from TestFloat
  logic [7:0]	 	        flags;    // flags read form testfloat
  logic [2:0]		        FrmE;     // rounding mode
  logic	[`FPSIZES/3:0]  FmtE;     // format - 10 = half, 00 = single, 01 = double, 11 = quad
  logic [3:0]		        FrmRead;  // rounding mode read from testfloat
  logic	[3:0]			      FmtRead;  // format read from testfloat
  logic [`FLEN-1:0]     FMAResM;  // FMA's outputed result
  logic [4:0]           FMAFlgM;  // FMA's outputed flags
  logic [2:0]		        FOpCtrlE; // which opperation
  logic                 wnan;     // is the outputed result NaN
  logic                 ansnan;   // is the correct answer NaN
  
  // signals needed to connect modules
  logic [`NE+1:0]	  ProdExpE;
  logic 				    AddendStickyE;
  logic 					  KillProdE; 
  logic             XSgnE, YSgnE, ZSgnE;
  logic [`NE-1:0]   XExpE, YExpE, ZExpE;
  logic [`NF:0]     XManE, YManE, ZManE;
  logic             XNormE;
  logic             XExpMaxE;
  logic             XNaNE, YNaNE, ZNaNE;
  logic             XSNaNE, YSNaNE, ZSNaNE;
  logic             XDenormE, YDenormE, ZDenormE;
  logic             XInfE, YInfE, ZInfE;
  logic             XZeroE, YZeroE, ZZeroE;
  logic             YExpMaxE, ZExpMaxE, Mult;
  logic [3*`NF+5:0]	SumE;       
  logic 			      InvZE;
  logic 			      NegSumE;
  logic 			      ZSgnEffE;
  logic 			      PSgnE;
  logic [$clog2(3*`NF+7)-1:0]	NormCntE;


  assign FOpCtrlE = 3'b0; // set to 0 because test float only tests fMADD
  assign Mult = 1'b0;     // set to zero because not testing multiplication

  // check if the calculated result or correct answer is NaN
  always_comb begin
    case (FmtRead)
        4'b11: begin // quad             
          assign ansnan = &ans[`FLEN-2:`NF]&(|ans[`NF-1:0]);
          assign wnan = &FMAResM[`FLEN-2:`NF]&(|FMAResM[`NF-1:0]);

        end
        4'b01: begin // double                 
          assign ansnan = &ans[`LEN1-2:`NF1]&(|ans[`NF1-1:0]);
          assign wnan = &FMAResM[`LEN1-2:`NF1]&(|FMAResM[`NF1-1:0]);

        end
        4'b00: begin // single
            assign ansnan = &ans[`LEN2-2:`NF2]&(|ans[`NF2-1:0]);
            assign wnan = &FMAResM[`LEN2-2:`NF2]&(|FMAResM[`NF2-1:0]);
        end
        4'b10: begin // half
            assign ansnan = &ans[`H_LEN-2:`H_NF]&(|ans[`H_NF-1:0]);
            assign wnan = &FMAResM[`H_LEN-2:`H_NF]&(|FMAResM[`H_NF-1:0]);
        end
    endcase
  end

  // instantiate devices under test
  unpack unpack(.X, .Y, .Z, .FmtE, .FOpCtrlE, .XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE,
                .XManE, .YManE, .ZManE, .XNormE, .XNaNE, .YNaNE, .ZNaNE, .XSNaNE, .YSNaNE, .ZSNaNE,
                .XDenormE, .YDenormE, .ZDenormE, .XZeroE, .YZeroE, .ZZeroE, .XInfE, .YInfE, .ZInfE,
                .XExpMaxE);
  fma1 fma1(.XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE,
            .XDenormE, .YDenormE, .ZDenormE,  .XZeroE, .YZeroE, .ZZeroE,
            .FOpCtrlE, .FmtE, .SumE, .NegSumE, .InvZE, .NormCntE, .ZSgnEffE, .PSgnE,
            .ProdExpE, .AddendStickyE, .KillProdE); 
  fma2 fma2(.XSgnM(XSgnE), .YSgnM(YSgnE), .XExpM(XExpE), .YExpM(YExpE), .ZExpM(ZExpE), .XManM(XManE), .YManM(YManE), .ZManM(ZManE), 
            .XNaNM(XNaNE), .YNaNM(YNaNE), .ZNaNM(ZNaNE), .XZeroM(XZeroE), .YZeroM(YZeroE), .ZZeroM(ZZeroE), .XInfM(XInfE), .YInfM(YInfE), .ZInfM(ZInfE), 
            .XSNaNM(XSNaNE), .YSNaNM(YSNaNE), .ZSNaNM(ZSNaNE), .KillProdM(KillProdE), .AddendStickyM(AddendStickyE), .ProdExpM(ProdExpE), 
            .SumM(SumE), .NegSumM(NegSumE), .InvZM(InvZE), .NormCntM(NormCntE), .ZSgnEffM(ZSgnEffE), .PSgnM(PSgnE), .FmtM(FmtE), .FrmM(FrmE), 
            .FMAFlgM, .FMAResM, .Mult);


  // produce clock
  always begin
    clk = 1; #5; clk = 0; #5;
  end
  
  // Read first test
  initial begin
      $display("\n\nRunning %s vectors", tests[i]);
      $readmemh({`PATH, tests[i]}, testvectors);
  end

  // apply test vectors on rising edge of clk
  always @(posedge clk) begin
    #1; 
    flags = testvectors[vectornum][15:8];
    FrmRead = testvectors[vectornum][7:4];
    FmtRead = testvectors[vectornum][3:0];
    if (FmtRead==4'b11 & `Q_SUPPORTED) 	begin       // quad
      X = testvectors[vectornum][16+4*(`Q_LEN)-1:16+3*(`Q_LEN)];
      Y = testvectors[vectornum][16+3*(`Q_LEN)-1:16+2*(`Q_LEN)];
      Z = testvectors[vectornum][16+2*(`Q_LEN)-1:16+`Q_LEN];
      ans = testvectors[vectornum][16+(`Q_LEN-1):16];
    end
    else if (FmtRead==4'b01 & `D_SUPPORTED)	begin	  // double
      X = {{`FLEN-`D_LEN{1'b1}}, testvectors[vectornum][16+4*(`D_LEN)-1:16+3*(`D_LEN)]};
      Y = {{`FLEN-`D_LEN{1'b1}}, testvectors[vectornum][16+3*(`D_LEN)-1:16+2*(`D_LEN)]};
      Z = {{`FLEN-`D_LEN{1'b1}}, testvectors[vectornum][16+2*(`D_LEN)-1:16+`D_LEN]};
      ans = {{`FLEN-`D_LEN{1'b1}}, testvectors[vectornum][16+(`D_LEN-1):16]};
    end
    else if (FmtRead==4'b00 & `F_SUPPORTED)	begin	  // single
      X = {{`FLEN-`S_LEN{1'b1}}, testvectors[vectornum][16+4*(`S_LEN)-1:16+3*(`S_LEN)]};
      Y = {{`FLEN-`S_LEN{1'b1}}, testvectors[vectornum][16+3*(`S_LEN)-1:16+2*(`S_LEN)]};
      Z = {{`FLEN-`S_LEN{1'b1}}, testvectors[vectornum][16+2*(`S_LEN)-1:16+`S_LEN]};
      ans = {{`FLEN-`S_LEN{1'b1}}, testvectors[vectornum][16+(`S_LEN-1):16]};
    end
    else if (FmtRead==4'b10 & `ZFH_SUPPORTED)	begin	  // half
      X = {{`FLEN-`H_LEN{1'b1}}, testvectors[vectornum][16+4*(`H_LEN)-1:16+3*(`H_LEN)]};
      Y = {{`FLEN-`H_LEN{1'b1}}, testvectors[vectornum][16+3*(`H_LEN)-1:16+2*(`H_LEN)]};
      Z = {{`FLEN-`H_LEN{1'b1}}, testvectors[vectornum][16+2*(`H_LEN)-1:16+`H_LEN]};
      ans = {{`FLEN-`H_LEN{1'b1}}, testvectors[vectornum][16+(`H_LEN-1):16]};
    end
    else begin	  
      X = {`FLEN{1'bx}};
      Y = {`FLEN{1'bx}};
      Z = {`FLEN{1'bx}};
      ans = {`FLEN{1'bx}};
    end

    // trim format and rounding mode to appropriate size
    if (`FPSIZES <= 2) FmtE = FmtRead === `FMT; // rewrite format if 2 or less floating formats are supported
    else FmtE = FmtRead[1:0];
    FrmE = FrmRead[2:0];
  end

  // check results on falling edge of clk
    always @(negedge clk) begin
      // quad
        if((FmtRead==4'b11) & ~((FMAFlgM === flags[4:0]) | (FMAResM === ans) | (wnan & (FMAResM[`FLEN-2:0] === ans[`FLEN-2:0] | (XNaNE&(FMAResM[`FLEN-2:0] === {X[`FLEN-2:`NF],1'b1,X[`NF-2:0]})) | (YNaNE&(FMAResM[`FLEN-2:0] === {Y[`FLEN-2:`NF],1'b1,Y[`NF-2:0]})) | (ZNaNE&(FMAResM[`FLEN-2:0] === {Z[`FLEN-2:`NF],1'b1,Z[`NF-2:0]})))))) begin
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
          if (errors === 1) $stop;
        end
      // double
        if((FmtRead==4'b01) & ~((FMAFlgM === flags[4:0]) | (FMAResM === ans) | (wnan & (FMAResM[`D_LEN-2:0] === ans[`D_LEN-2:0] | (XNaNE&(FMAResM[`D_LEN-2:0] === {X[`D_LEN-2:`D_NF],1'b1,X[`D_NF-2:0]})) | (YNaNE&(FMAResM[`D_LEN-2:0] === {Y[`D_LEN-2:`D_NF],1'b1,Y[`D_NF-2:0]})) | (ZNaNE&(FMAResM[`D_LEN-2:0] === {Z[`D_LEN-2:`D_NF],1'b1,Z[`D_NF-2:0]})))))) begin
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
          if (errors === 1) $stop;
        end
      // single
        if((FmtRead==4'b00) & ~((FMAFlgM === flags[4:0]) | (FMAResM === ans) | (wnan & (FMAResM[`S_LEN-2:0] === ans[`S_LEN-2:0] | (XNaNE&(FMAResM[`S_LEN-2:0] === {X[`S_LEN-2:`S_NF],1'b1,X[`S_NF-2:0]})) | (YNaNE&(FMAResM[`S_LEN-2:0] === {Y[`S_LEN-2:`S_NF],1'b1,Y[`S_NF-2:0]})) | (ZNaNE&(FMAResM[`S_LEN-2:0] === {Z[`S_LEN-2:`S_NF],1'b1,Z[`S_NF-2:0]})))))) begin
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
          if (errors === 1) $stop;
        end
      // half
        if((FmtRead==4'b01) & ~((FMAFlgM === flags[4:0]) | (FMAResM === ans) | (wnan & (FMAResM[`H_LEN-2:0] === ans[`H_LEN-2:0] | (XNaNE&(FMAResM[`H_LEN-2:0] === {X[`H_LEN-2:`H_NF],1'b1,X[`H_NF-2:0]})) | (YNaNE&(FMAResM[`H_LEN-2:0] === {Y[`H_LEN-2:`H_NF],1'b1,Y[`H_NF-2:0]})) | (ZNaNE&(FMAResM[`H_LEN-2:0] === {Z[`H_LEN-2:`H_NF],1'b1,Z[`H_NF-2:0]})))))) begin
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
          if (errors === 1) $stop;
        end
        
	    // if ( vectornum === 3165862) $stop; // uncomment for specific test
      vectornum = vectornum + 1; // increment test
      if (testvectors[vectornum][0] === 1'bx) begin // if reached the end of file
        if (errors) begin // if there were errors
          $display("%s completed with %d tests and %d errors", tests[i], vectornum, errors);
          $stop;
        end
        else begin // if no errors
          if(tests[i] === "") begin // if no more tests
            $display("\nAll tests completed with %d errors\n", errors);
            $stop;
          end

          $display("%s completed successfully with %d tests and %d errors (across all tests)\n", tests[i], vectornum, errors);

          // increment tests - skip some precisions if needed
          if ((i === 4 & ~`F_SUPPORTED) | (i === 9 & ~`D_SUPPORTED) | (i === 14 & ~`Q_SUPPORTED)) i = i+5;
          if ((i === 9 & ~`D_SUPPORTED) | (i === 14 & ~`Q_SUPPORTED)) i = i+5;
          if ((i === 14 & ~`Q_SUPPORTED)) i = i+5;
          i = i+1;

          // if no more tests - finish
          if(tests[i] === "") begin
            $display("\nAll tests completed with %d errors\n", errors);
            $stop;
          end 

          // read next files
          $display("Running %s vectors", tests[i]);
          $readmemh({`PATH, tests[i]}, testvectors);
          vectornum = 0;
        end
      end
  end
endmodule
