
`include "wally-config.vh"
`include "tests-fp.vh"

// steps to run FMA Tests
//    1) create test vectors in riscv-wally/Tests/fp with: ./run-all.sh
//    2) go to riscv-wally/pipelined/testbench/fp/Tests
//    3) run ./sim-fma-batch
module testbenchfp;
  parameter TEST="none";

  string      Tests[];        // list of tests to be run
  string      FmaRneTests[];  // list of FMA round to nearest even tests to run
  string      FmaRuTests[];   // list of FMA round up tests to run
  string      FmaRdTests[];   // list of FMA round down tests to run
  string      FmaRzTests[];   // list of FMA round twords zero
  string      FmaRnmTests[];  // list of FMA round to nearest max magnitude
  logic [2:0] OpCtrl[];       // list of op controls
  logic [2:0] Unit[];         // list of units being tested
  logic WriteInt[];           // Is being written to integer resgiter
  logic [2:0] Frm[4:0] = {3'b100, 3'b010, 3'b011, 3'b001, 3'b000}; // rounding modes: rne-000, rz-001, ru-011, rd-010, rnm-100
  logic [1:0] Fmt[];          // list of formats for the other units
  logic [1:0] FmaFmt[];       // list of formats for the FMA
  

  logic               clk=0;
  logic [31:0]        TestNum=0;    // index for the test
  logic [31:0]        OpCtrlNum=0;  // index for OpCtrl
  logic [31:0]        errors=0;     // how many errors
  logic [31:0]        VectorNum=0;  // index for test vector
  logic [31:0]        FrmNum=0;     // index for rounding mode
  logic [`FLEN*4+7:0] TestVectors[46464:0];     // list of test vectors
  logic [`FLEN*4+7:0] FmaRneVectors[6133248:0]; // list of fma rne test vectors
  logic [`FLEN*4+7:0] FmaRuVectors[6133248:0];  // list of fma ru test vectors
  logic [`FLEN*4+7:0] FmaRdVectors[6133248:0];  // list of fma rd test vectors
  logic [`FLEN*4+7:0] FmaRzVectors[6133248:0];  // list of fma rz test vectors
  logic [`FLEN*4+7:0] FmaRnmVectors[6133248:0]; // list of fma rnm test vectors

  logic [1:0]           FmaFmtVal, FmtVal;          // value of the current Fmt
  logic [2:0]           UnitVal, OpCtrlVal, FrmVal; // vlaue of the currnet Unit/OpCtrl/FrmVal
  logic                 WriteIntVal;                // value of the current WriteInt
  logic [`FLEN-1:0]     X, Y, Z;                    // inputs read from TestFloat
  logic [`FLEN-1:0]     FmaRneX, FmaRneY, FmaRneZ;  // inputs read from TestFloat
  logic [`FLEN-1:0]     FmaRzX, FmaRzY, FmaRzZ;     // inputs read from TestFloat
  logic [`FLEN-1:0]     FmaRuX, FmaRuY, FmaRuZ;     // inputs read from TestFloat
  logic [`FLEN-1:0]     FmaRdX, FmaRdY, FmaRdZ;     // inputs read from TestFloat
  logic [`FLEN-1:0]     FmaRnmX, FmaRnmY, FmaRnmZ;  // inputs read from TestFloat
  logic [`XLEN-1:0]     SrcA;                       // integer input
  logic [`FLEN-1:0]	    Ans;                        // correct answer from TestFloat
  logic [`FLEN-1:0]     FmaRneAns, FmaRzAns, FmaRuAns, FmaRdAns, FmaRnmAns; // flags read form testfloat
  logic [`FLEN-1:0]	    Res;                                                // result from other units
  logic [`FLEN-1:0]	    FmaRneRes, FmaRzRes, FmaRuRes, FmaRdRes, FmaRnmRes; // results from FMA
  logic [4:0]	 	        AnsFlg;                                             // correct flags read from testfloat
  logic [4:0]           FmaRneAnsFlg, FmaRzAnsFlg, FmaRuAnsFlg, FmaRdAnsFlg, FmaRnmAnsFlg; // flags read form testfloat
  logic [4:0]	 	        ResFlg;                                                            // Result flags
  logic [4:0]           FmaRneResFlg, FmaRzResFlg, FmaRuResFlg, FmaRdResFlg, FmaRnmResFlg; // flags read form testfloat
  logic	[`FMTBITS-1:0]  ModFmt, FmaModFmt;  // format - 10 = half, 00 = single, 01 = double, 11 = quad
  logic [`FLEN-1:0]     FmaRes, DivRes, CmpRes, CvtRes;  // Results from each unit
  logic [`XLEN-1:0]     CvtIntRes;  // Results from each unit
  logic [4:0]           FmaFlg, CvtFlg, DivFlg, CmpFlg;  // Outputed flags
  logic                 ResNaN, FmaRneResNaN, FmaRzResNaN, FmaRuResNaN, FmaRdResNaN, FmaRnmResNaN;   // is the outputed result NaN
  logic                 AnsNaN, FmaRneAnsNaN, FmaRzAnsNaN, FmaRuAnsNaN, FmaRdAnsNaN, FmaRnmAnsNaN;   // is the correct answer NaN
  logic                 NaNGood, FmaRneNaNGood, FmaRzNaNGood, FmaRuNaNGood, FmaRdNaNGood, FmaRnmNaNGood; // is the NaN answer correct
  logic                 XSgn, YSgn, ZSgn;                     // sign of the inputs
  logic                 FmaRneXSgn, FmaRneYSgn, FmaRneZSgn;
  logic                 FmaRzXSgn, FmaRzYSgn, FmaRzZSgn;
  logic                 FmaRuXSgn, FmaRuYSgn, FmaRuZSgn;
  logic                 FmaRdXSgn, FmaRdYSgn, FmaRdZSgn;
  logic                 FmaRnmXSgn, FmaRnmYSgn, FmaRnmZSgn;
  logic [`NE-1:0]       XExp, YExp, ZExp;                     // exponent of the inputs
  logic [`NE-1:0]       FmaRneXExp, FmaRneYExp, FmaRneZExp;
  logic [`NE-1:0]       FmaRzXExp, FmaRzYExp, FmaRzZExp;
  logic [`NE-1:0]       FmaRuXExp, FmaRuYExp, FmaRuZExp;
  logic [`NE-1:0]       FmaRdXExp, FmaRdYExp, FmaRdZExp;
  logic [`NE-1:0]       FmaRnmXExp, FmaRnmYExp, FmaRnmZExp;
  logic [`NF:0]         XMan, YMan, ZMan;                     // mantissas of the inputs
  logic [`NF:0]         FmaRneXMan, FmaRneYMan, FmaRneZMan;
  logic [`NF:0]         FmaRzXMan, FmaRzYMan, FmaRzZMan;
  logic [`NF:0]         FmaRuXMan, FmaRuYMan, FmaRuZMan;
  logic [`NF:0]         FmaRdXMan, FmaRdYMan, FmaRdZMan;
  logic [`NF:0]         FmaRnmXMan, FmaRnmYMan, FmaRnmZMan;
  logic                 XNaN, YNaN, ZNaN;                     // is the input NaN
  logic                 FmaRneXNaN, FmaRneYNaN, FmaRneZNaN;
  logic                 FmaRzXNaN, FmaRzYNaN, FmaRzZNaN;
  logic                 FmaRuXNaN, FmaRuYNaN, FmaRuZNaN;
  logic                 FmaRdXNaN, FmaRdYNaN, FmaRdZNaN;
  logic                 FmaRnmXNaN, FmaRnmYNaN, FmaRnmZNaN;
  logic                 XSNaN, YSNaN, ZSNaN;                  // is the input a signaling NaN
  logic                 FmaRneXSNaN, FmaRneYSNaN, FmaRneZSNaN;
  logic                 FmaRzXSNaN, FmaRzYSNaN, FmaRzZSNaN;
  logic                 FmaRuXSNaN, FmaRuYSNaN, FmaRuZSNaN;
  logic                 FmaRdXSNaN, FmaRdYSNaN, FmaRdZSNaN;
  logic                 FmaRnmXSNaN, FmaRnmYSNaN, FmaRnmZSNaN;
  logic                 XDenorm, ZDenorm;            // is the input denormalized
  logic                 FmaRneXDenorm, FmaRneZDenorm;
  logic                 FmaRzXDenorm, FmaRzZDenorm;
  logic                 FmaRuXDenorm, FmaRuZDenorm;
  logic                 FmaRdXDenorm, FmaRdZDenorm;
  logic                 FmaRnmXDenorm, FmaRnmZDenorm;
  logic                 XInf, YInf, ZInf;                   // is the input infinity
  logic                 FmaRneXInf, FmaRneYInf, FmaRneZInf;
  logic                 FmaRzXInf, FmaRzYInf, FmaRzZInf;
  logic                 FmaRuXInf, FmaRuYInf, FmaRuZInf;
  logic                 FmaRdXInf, FmaRdYInf, FmaRdZInf;
  logic                 FmaRnmXInf, FmaRnmYInf, FmaRnmZInf;
  logic                 XZero, YZero, ZZero;                // is the input zero
  logic                 FmaRneXZero, FmaRneYZero, FmaRneZZero;
  logic                 FmaRzXZero, FmaRzYZero, FmaRzZZero;
  logic                 FmaRuXZero, FmaRuYZero, FmaRuZZero;
  logic                 FmaRdXZero, FmaRdYZero, FmaRdZZero;
  logic                 FmaRnmXZero, FmaRnmYZero, FmaRnmZZero;
  logic                 XExpMax, YExpMax, ZExpMax;         // is the input's exponent all ones  

  // in-between FMA signals
  logic                 Mult;
  logic [`NE+1:0]	      ProdExpE, FmaRneProdExp, FmaRzProdExp, FmaRuProdExp, FmaRdProdExp, FmaRnmProdExp;
  logic 				        AddendStickyE, FmaRneAddendSticky, FmaRzAddendSticky, FmaRuAddendSticky, FmaRdAddendSticky, FmaRnmAddendSticky;
  logic 					      KillProdE, FmaRneKillProd, FmaRzKillProd, FmaRuKillProd, FmaRdKillProd, FmaRnmKillProd; 
  logic [$clog2(3*`NF+7)-1:0]	NormCntE, FmaRneNormCnt, FmaRzNormCnt, FmaRuNormCnt, FmaRdNormCnt, FmaRnmNormCnt;
  logic [3*`NF+5:0]	    SumE, FmaRneSum, FmaRzSum, FmaRuSum, FmaRdSum, FmaRnmSum;       
  logic 			          InvZE, FmaRneInvZ, FmaRzInvZ, FmaRuInvZ, FmaRdInvZ, FmaRnmInvZ;
  logic 			          NegSumE, FmaRneNegSum, FmaRzNegSum, FmaRuNegSum, FmaRdNegSum, FmaRnmNegSum;
  logic 			          ZSgnEffE, FmaRneZSgnEff, FmaRzZSgnEff, FmaRuZSgnEff, FmaRdZSgnEff, FmaRnmZSgnEff;
  logic 			          PSgnE, FmaRnePSgn, FmaRzPSgn, FmaRuPSgn, FmaRdPSgn, FmaRnmPSgn;


  ///////////////////////////////////////////////////////////////////////////////////////////////

  //     ||||||||| |||||||| ||||||| |||||||||   ||||||| |||||||| |||
  //        |||    |||      |||        |||      |||     |||      |||
  //        |||    |||||||| |||||||    |||      ||||||| |||||||| |||
  //        |||    |||          |||    |||          ||| |||      |||
  //        |||    |||||||| |||||||    |||      ||||||| |||||||| |||||||||

  ///////////////////////////////////////////////////////////////////////////////////////////////

  // select tests relevent to the specified configuration
  //    cvtint - test integer conversion unit (fcvtint)
  //    cvtfp  - test floating-point conversion unit (fcvtfp)
  //    cmp    - test comparison unit's LT, LE, EQ opperations (fcmp)
  //    add    - test addition
  //    sub    - test subtraction
  //    div    - test division
  //    sqrt   - test square root
  //    all    - test all of the above
  initial begin
    $display("TEST is %s", TEST);
    if (`Q_SUPPORTED) begin // if Quad percision is supported
      if (TEST === "cvtint"| TEST === "all") begin  // if testing integer conversion
                                              // add the 128-bit cvtint tests to the to-be-tested list
                                              Tests = {Tests, f128rv32cvtint};
                                              // add the op-codes for these tests to the op-code list
                                              OpCtrl = {OpCtrl, `FROM_UI_OPCTRL, `FROM_I_OPCTRL, `TO_UI_OPCTRL, `TO_I_OPCTRL};
                                              WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                              // add what unit is used and the fmt to their lists (one for each test)
                                              for(int i = 0; i<20; i++) begin
                                                Unit = {Unit, `CVTINTUNIT};
                                                Fmt = {Fmt, 2'b11};
                                              end
                                              if (`XLEN == 64) begin // if 64-bit integers are supported add their conversions
                                                Tests = {Tests, f128rv64cvtint};
                                              // add the op-codes for these tests to the op-code list
                                                OpCtrl = {OpCtrl, `FROM_UL_OPCTRL, `FROM_L_OPCTRL, `TO_UL_OPCTRL, `TO_L_OPCTRL};
                                                WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                              // add what unit is used and the fmt to their lists (one for each test)
                                              for(int i = 0; i<20; i++) begin
                                                Unit = {Unit, `CVTINTUNIT};
                                                Fmt = {Fmt, 2'b11};
                                              end
                                              end
                                            end
      if (TEST === "cvtfp" | TEST === "all") begin  // if the floating-point conversions are being tested
        if(`D_SUPPORTED) begin // if double precision is supported
          // add the 128 <-> 64 bit conversions to the to-be-tested list
          Tests = {Tests, f128f64cvt};
          // add the op-ctrls (i.e. the format of the result)
          OpCtrl = {OpCtrl, 3'b01, 3'b11};
          WriteInt = {WriteInt, 1'b0, 1'b0};
          // add the unit being tested and fmt (input format)
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b11};
          end
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b01};
          end
        end
        if(`F_SUPPORTED) begin // if single precision is supported
          // add the 128 <-> 32 bit conversions to the to-be-tested list
          Tests = {Tests, f128f32cvt};
          // add the op-ctrls (i.e. the format of the result)
          OpCtrl = {OpCtrl, 3'b00, 3'b11};
          WriteInt = {WriteInt, 1'b0, 1'b0};
          // add the unit being tested and fmt (input format)
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b11};
          end
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b00};
          end
        end
        if(`ZFH_SUPPORTED) begin // if half precision is supported
          // add the 128 <-> 16 bit conversions to the to-be-tested list
          Tests = {Tests, f128f16cvt};
          // add the op-ctrls (i.e. the format of the result)
          OpCtrl = {OpCtrl, 3'b10, 3'b11};
          WriteInt = {WriteInt, 1'b0, 1'b0};
          // add the unit being tested and fmt (input format)
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b11};
          end
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b10};
          end
        end
      end
      if (TEST === "cmp"   | TEST === "all") begin// if comparisons are being tested
        // add the compare tests/op-ctrls/unit/fmt
        Tests = {Tests, f128cmp};
        OpCtrl = {OpCtrl, `EQ_OPCTRL, `LE_OPCTRL, `LT_OPCTRL};
          WriteInt = {WriteInt, 1'b0, 1'b0, 1'b0};
          for(int i = 0; i<15; i++) begin
            Unit = {Unit, `CMPUNIT};
            Fmt = {Fmt, 2'b11};
          end
      end
      if (TEST === "add"   | TEST === "all") begin // if addition is being tested
        // add the addition tests/op-ctrls/unit/fmt
        Tests = {Tests, f128add};
        OpCtrl = {OpCtrl, `ADD_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `FMAUNIT};
            Fmt = {Fmt, 2'b11};
          end
      end
      if (TEST === "sub"   | TEST === "all") begin // if subtraction is being tested
        // add the subtraction tests/op-ctrls/unit/fmt
        Tests = {Tests, f128sub};
        OpCtrl = {OpCtrl, `SUB_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `FMAUNIT};
            Fmt = {Fmt, 2'b11};
          end
      end
      if (TEST === "mul"   | TEST === "all") begin // if multiplication is being tested
        // add the multiply tests/op-ctrls/unit/fmt
        Tests = {Tests, f128mul};
        OpCtrl = {OpCtrl, `MUL_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `FMAUNIT};
            Fmt = {Fmt, 2'b11};
          end
      end
      if (TEST === "div"   | TEST === "all") begin // if division is being tested
        // add the divide tests/op-ctrls/unit/fmt
        Tests = {Tests, f128div};
        OpCtrl = {OpCtrl, `DIV_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `DIVUNIT};
            Fmt = {Fmt, 2'b11};
          end
      end
      if (TEST === "sqrt"  | TEST === "all") begin // if square-root is being tested
        // add the square-root tests/op-ctrls/unit/fmt
        Tests = {Tests, f128sqrt};
        OpCtrl = {OpCtrl, `SQRT_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `DIVUNIT};
            Fmt = {Fmt, 2'b11};
          end
      end
      if (TEST === "fma"   | TEST === "all") begin  // if fused-mutliply-add is being tested
        // add each rounding mode to it's own list of tests
        //    - fma tests are very long, so run all rounding modes in parallel
        FmaRneTests = {FmaRneTests, "f128_mulAdd_rne.tv"};
        FmaRzTests  = {FmaRzTests,  "f128_mulAdd_rz.tv"};
        FmaRuTests  = {FmaRuTests,  "f128_mulAdd_ru.tv"};
        FmaRdTests  = {FmaRdTests,  "f128_mulAdd_rd.tv"};
        FmaRnmTests = {FmaRnmTests, "f128_mulAdd_rnm.tv"};
        // add the format for the Fma
        FmaFmt = {FmaFmt, 2'b11};
      end
    end
    if (`D_SUPPORTED) begin // if double precision is supported
      if (TEST === "cvtint"| TEST === "all") begin // if integer conversion is being tested
                                              Tests = {Tests, f64rv32cvtint};
                                              // add the op-codes for these tests to the op-code list
                                              OpCtrl = {OpCtrl, `FROM_UI_OPCTRL, `FROM_I_OPCTRL, `TO_UI_OPCTRL, `TO_I_OPCTRL};
                                              WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                              // add what unit is used and the fmt to their lists (one for each test)
                                              for(int i = 0; i<20; i++) begin
                                                Unit = {Unit, `CVTINTUNIT};
                                                Fmt = {Fmt, 2'b01};
                                              end
                                              if (`XLEN == 64) begin // if 64-bit integers are being supported
                                                Tests = {Tests, f64rv64cvtint};
                                                // add the op-codes for these tests to the op-code list
                                                OpCtrl = {OpCtrl, `FROM_UL_OPCTRL, `FROM_L_OPCTRL, `TO_UL_OPCTRL, `TO_L_OPCTRL};
                                                WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                                // add what unit is used and the fmt to their lists (one for each test)
                                                for(int i = 0; i<20; i++) begin
                                                  Unit = {Unit, `CVTINTUNIT};
                                                  Fmt = {Fmt, 2'b01};
                                                end
                                              end
                                            end
      if (TEST === "cvtfp" | TEST === "all") begin // if floating point conversions are being tested
        if(`F_SUPPORTED) begin // if single precision is supported
          // add the 64 <-> 32 bit conversions to the to-be-tested list
          Tests = {Tests, f64f32cvt};
          // add the op-ctrls (i.e. the format of the result)
          OpCtrl = {OpCtrl, 3'b00, 3'b01};
          WriteInt = {WriteInt, 1'b0, 1'b0};
          // add the unit being tested and fmt (input format)
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b01};
          end
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b00};
          end
        end
        if(`ZFH_SUPPORTED) begin // if half precision is supported
          // add the 64 <-> 16 bit conversions to the to-be-tested list
          Tests = {Tests, f64f16cvt};
          // add the op-ctrls (i.e. the format of the result)
          OpCtrl = {OpCtrl, 3'b10, 3'b01};
          WriteInt = {WriteInt, 1'b0, 1'b0};
          // add the unit being tested and fmt (input format)
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b01};
          end
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b10};
          end
        end
      end
      if (TEST === "cmp"   | TEST === "all") begin // if comparisions are being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f64cmp};
        OpCtrl = {OpCtrl, `EQ_OPCTRL, `LE_OPCTRL, `LT_OPCTRL};
        WriteInt = {WriteInt, 1'b0, 1'b0, 1'b0};
        for(int i = 0; i<15; i++) begin
          Unit = {Unit, `CMPUNIT};
          Fmt = {Fmt, 2'b01};
        end
      end
      if (TEST === "add"   | TEST === "all") begin // if addition is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f64add};
        OpCtrl = {OpCtrl, `ADD_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b01};
        end
      end
      if (TEST === "sub"   | TEST === "all") begin // if subtration is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f64sub};
        OpCtrl = {OpCtrl, `SUB_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b01};
        end
      end
      if (TEST === "mul"   | TEST === "all") begin // if multiplication is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f64mul};
        OpCtrl = {OpCtrl, `MUL_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b01};
        end
      end
      if (TEST === "div"   | TEST === "all") begin // if division is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f64div};
        OpCtrl = {OpCtrl, `DIV_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b01};
        end
      end
      if (TEST === "sqrt"  | TEST === "all") begin // if square-root is being tessted
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f64sqrt};
        OpCtrl = {OpCtrl, `SQRT_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b01};
        end
      end
      if (TEST === "fma"   | TEST === "all") begin // if the fused multiply add is being tested
        // add each rounding mode to it's own list of tests
        //    - fma tests are very long, so run all rounding modes in parallel
        FmaRneTests = {FmaRneTests, "f64_mulAdd_rne.tv"};
        FmaRzTests  = {FmaRzTests,  "f64_mulAdd_rz.tv"};
        FmaRuTests  = {FmaRuTests,  "f64_mulAdd_ru.tv"};
        FmaRdTests  = {FmaRdTests,  "f64_mulAdd_rd.tv"};
        FmaRnmTests = {FmaRnmTests, "f64_mulAdd_rnm.tv"};
        FmaFmt = {FmaFmt, 2'b01};
      end
    end
    if (`F_SUPPORTED) begin // if single precision being supported
      if (TEST === "cvtint"| TEST === "all") begin // if integer conversion is being tested
                                              Tests = {Tests, f32rv32cvtint};
                                              // add the op-codes for these tests to the op-code list
                                              OpCtrl = {OpCtrl, `FROM_UI_OPCTRL, `FROM_I_OPCTRL, `TO_UI_OPCTRL, `TO_I_OPCTRL};
                                              WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                              // add what unit is used and the fmt to their lists (one for each test)
                                              for(int i = 0; i<20; i++) begin
                                                Unit = {Unit, `CVTINTUNIT};
                                                Fmt = {Fmt, 2'b00};
                                              end
                                              if (`XLEN == 64) begin // if 64-bit integers are supported
                                                Tests = {Tests, f32rv64cvtint};
                                                // add the op-codes for these tests to the op-code list
                                                OpCtrl = {OpCtrl, `FROM_UL_OPCTRL, `FROM_L_OPCTRL, `TO_UL_OPCTRL, `TO_L_OPCTRL};
                                                WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                                // add what unit is used and the fmt to their lists (one for each test)
                                              for(int i = 0; i<20; i++) begin
                                                Unit = {Unit, `CVTINTUNIT};
                                                Fmt = {Fmt, 2'b00};
                                              end
                                              end
                                            end
      if (TEST === "cvtfp" | TEST === "all") begin  // if floating point conversion is being tested
        if(`ZFH_SUPPORTED) begin 
          // add the 32 <-> 16 bit conversions to the to-be-tested list
          Tests = {Tests, f32f16cvt};
          // add the op-ctrls (i.e. the format of the result)
          OpCtrl = {OpCtrl, 3'b10, 3'b00};
          WriteInt = {WriteInt, 1'b0, 1'b0};
          // add the unit being tested and fmt (input format)
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b00};
          end
          for(int i = 0; i<5; i++) begin
            Unit = {Unit, `CVTFPUNIT};
            Fmt = {Fmt, 2'b10};
          end
        end
      end
      if (TEST === "cmp"   | TEST === "all") begin // if comparision is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f32cmp};
        OpCtrl = {OpCtrl, `EQ_OPCTRL, `LE_OPCTRL, `LT_OPCTRL};
        WriteInt = {WriteInt, 1'b0, 1'b0, 1'b0};
        for(int i = 0; i<15; i++) begin
          Unit = {Unit, `CMPUNIT};
          Fmt = {Fmt, 2'b00};
        end
      end
      if (TEST === "add"   | TEST === "all") begin // if addition is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f32add};
        OpCtrl = {OpCtrl, `ADD_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b00};
        end
      end
      if (TEST === "sub"   | TEST === "all") begin // if subtration is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f32sub};
        OpCtrl = {OpCtrl, `SUB_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b00};
        end
      end
      if (TEST === "mul"   | TEST === "all") begin // if multiply is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f32mul};
        OpCtrl = {OpCtrl, `MUL_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b00};
        end
      end
      if (TEST === "div"   | TEST === "all") begin // if division is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f32div};
        OpCtrl = {OpCtrl, `DIV_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b00};
        end
      end
      if (TEST === "sqrt"  | TEST === "all") begin // if sqrt is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f32sqrt};
        OpCtrl = {OpCtrl, `SQRT_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b00};
        end
      end
      if (TEST === "fma"   | TEST === "all")  begin // if fma is being tested
        // add each rounding mode to it's own list of tests
        //    - fma tests are very long, so run all rounding modes in parallel
        FmaRneTests = {FmaRneTests, "f32_mulAdd_rne.tv"};
        FmaRzTests  = {FmaRzTests,  "f32_mulAdd_rz.tv"};
        FmaRuTests  = {FmaRuTests,  "f32_mulAdd_ru.tv"};
        FmaRdTests  = {FmaRdTests,  "f32_mulAdd_rd.tv"};
        FmaRnmTests = {FmaRnmTests, "f32_mulAdd_rnm.tv"};
        FmaFmt = {FmaFmt, 2'b00};
      end
    end
    if (`ZFH_SUPPORTED) begin // if half precision supported
      if (TEST === "cvtint"| TEST === "all") begin // if in conversions are being tested
                                              Tests = {Tests, f16rv32cvtint};
                                              // add the op-codes for these tests to the op-code list
                                              OpCtrl = {OpCtrl, `FROM_UI_OPCTRL, `FROM_I_OPCTRL, `TO_UI_OPCTRL, `TO_I_OPCTRL};
                                              WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                              // add what unit is used and the fmt to their lists (one for each test)
                                              for(int i = 0; i<20; i++) begin
                                                Unit = {Unit, `CVTINTUNIT};
                                                Fmt = {Fmt, 2'b10};
                                              end
                                              if (`XLEN == 64) begin // if 64-bit integers are supported
                                                Tests = {Tests, f16rv64cvtint};
                                                // add the op-codes for these tests to the op-code list
                                                OpCtrl = {OpCtrl, `FROM_UL_OPCTRL, `FROM_L_OPCTRL, `TO_UL_OPCTRL, `TO_L_OPCTRL};
                                                WriteInt = {WriteInt, 1'b0, 1'b0, 1'b1, 1'b1};
                                                // add what unit is used and the fmt to their lists (one for each test)
                                                for(int i = 0; i<20; i++) begin
                                                  Unit = {Unit, `CVTINTUNIT};
                                                  Fmt = {Fmt, 2'b10};
                                                end
                                              end
                                            end
      if (TEST === "cmp"   | TEST === "all") begin // if comparisions are being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f16cmp};
        OpCtrl = {OpCtrl, `EQ_OPCTRL, `LE_OPCTRL, `LT_OPCTRL};
        WriteInt = {WriteInt, 1'b0, 1'b0, 1'b0};
        for(int i = 0; i<15; i++) begin
          Unit = {Unit, `CMPUNIT};
          Fmt = {Fmt, 2'b10};
        end
      end
      if (TEST === "add"   | TEST === "all") begin //  if addition is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f16add};
        OpCtrl = {OpCtrl, `ADD_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b10};
        end
      end
      if (TEST === "sub"   | TEST === "all") begin // if subtraction is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f16sub};
        OpCtrl = {OpCtrl, `SUB_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b10};
        end
      end
      if (TEST === "mul"   | TEST === "all") begin // if multiplication is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f16mul};
        OpCtrl = {OpCtrl, `MUL_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b10};
        end
      end
      if (TEST === "div"   | TEST === "all") begin // if division is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f16div};
        OpCtrl = {OpCtrl, `DIV_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b10};
        end
      end
      if (TEST === "sqrt"  | TEST === "all") begin // if sqrt is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        Tests = {Tests, f16sqrt};
        OpCtrl = {OpCtrl, `SQRT_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b10};
        end
      end
      if (TEST === "fma"   | TEST === "all") begin // if fma is being tested
        // add each rounding mode to it's own list of tests
        //    - fma tests are very long, so run all rounding modes in parallel
        FmaRneTests = {FmaRneTests, "f16_mulAdd_rne.tv"};
        FmaRzTests  = {FmaRzTests,  "f16_mulAdd_rz.tv"};
        FmaRuTests  = {FmaRuTests,  "f16_mulAdd_ru.tv"};
        FmaRdTests  = {FmaRdTests,  "f16_mulAdd_rd.tv"};
        FmaRnmTests = {FmaRnmTests, "f16_mulAdd_rnm.tv"};
        FmaFmt = {FmaFmt, 2'b10};
      end
    end

    // check if nothing is being tested
    if (Tests.size() == 0 & FmaRneTests.size() == 0 & FmaRuTests.size() == 0 & FmaRdTests.size() == 0 & FmaRzTests.size() == 0 & FmaRnmTests.size() == 0) begin
      $display("TEST %s not supported in this configuration", TEST);
      $stop;
    end
  end

  ///////////////////////////////////////////////////////////////////////////////////////////////

  //     ||||||||| |||||||| ||||||||| |||||||     ||||||||| |||||||| ||||||| |||||||||   
  //     |||   ||| |||      |||   ||| ||   ||        |||    |||      |||        |||      
  //     ||||||||  |||||||| ||||||||| ||   ||        |||    |||||||| |||||||    |||      
  //     |||  ||   |||      |||   ||| ||   ||        |||    |||          |||    |||      
  //     |||   ||| |||||||| |||   ||| |||||||        |||    |||||||| |||||||    |||      

  ///////////////////////////////////////////////////////////////////////////////////////////////

  // Read the first test
  initial begin
    $display("\n\nRunning %s vectors", Tests[TestNum]);
    $readmemh({`PATH, Tests[TestNum]}, TestVectors);
    $readmemh({`PATH, FmaRneTests[TestNum]}, FmaRneVectors);
    $readmemh({`PATH, FmaRuTests[TestNum]}, FmaRuVectors);
    $readmemh({`PATH, FmaRdTests[TestNum]}, FmaRdVectors);
    $readmemh({`PATH, FmaRzTests[TestNum]}, FmaRzVectors);
    $readmemh({`PATH, FmaRnmTests[TestNum]}, FmaRnmVectors);
    // set the test index to 0
    TestNum = 0;
  end

  // set a the signals for all tests
  always_comb FmaFmtVal = FmaFmt[TestNum];
  always_comb UnitVal = Unit[TestNum];
  always_comb FmtVal = Fmt[TestNum];
  always_comb OpCtrlVal = OpCtrl[OpCtrlNum];
  always_comb WriteIntVal = WriteInt[OpCtrlNum];
  always_comb FrmVal = Frm[FrmNum];
  assign Mult = OpCtrlVal === 3'b100;

  // modify the format signal if only 2 percisions supported
  //    - 1 for the larger precision
  //    - 0 for the smaller precision
  always_comb begin
    if(`FMTBITS == 2) ModFmt = FmtVal;
    else ModFmt = FmtVal === `FMT;
    if(`FMTBITS == 2) FmaModFmt = FmaFmtVal;
    else FmaModFmt = FmaFmtVal === `FMT;
  end

  // extract the inputs (X, Y, Z, SrcA) and the output (Ans, AnsFlg) from the current test vector
  readfmavectors readfmarnevectors (.clk, .TestVector(FmaRneVectors[VectorNum]), .Ans(FmaRneAns), .AnsFlg(FmaRneAnsFlg), 
                                    .XSgnE(FmaRneXSgn), .YSgnE(FmaRneYSgn), .ZSgnE(FmaRneZSgn),
                                    .XExpE(FmaRneXExp), .YExpE(FmaRneYExp), .ZExpE(FmaRneZExp), 
                                    .XManE(FmaRneXMan), .YManE(FmaRneYMan), .ZManE(FmaRneZMan), 
                                    .XNaNE(FmaRneXNaN), .YNaNE(FmaRneYNaN), .ZNaNE(FmaRneZNaN),
                                    .XSNaNE(FmaRneXSNaN), .YSNaNE(FmaRneYSNaN), .ZSNaNE(FmaRneZSNaN), 
                                    .XDenormE(FmaRneXDenorm), .ZDenormE(FmaRneZDenorm), 
                                    .XZeroE(FmaRneXZero), .YZeroE(FmaRneYZero), .ZZeroE(FmaRneZZero),
                                    .XInfE(FmaRneXInf), .YInfE(FmaRneYInf), .ZInfE(FmaRneZInf), .FmaModFmt, .FmaFmt(FmaFmtVal),
                                    .X(FmaRneX), .Y(FmaRneY), .Z(FmaRneZ));
  readfmavectors readfmarzvectors (.clk, .TestVector(FmaRzVectors[VectorNum]), .Ans(FmaRzAns), .AnsFlg(FmaRzAnsFlg), 
                                    .XSgnE(FmaRzXSgn), .YSgnE(FmaRzYSgn), .ZSgnE(FmaRzZSgn), .FmaModFmt,
                                    .XExpE(FmaRzXExp), .YExpE(FmaRzYExp), .ZExpE(FmaRzZExp), 
                                    .XManE(FmaRzXMan), .YManE(FmaRzYMan), .ZManE(FmaRzZMan), 
                                    .XNaNE(FmaRzXNaN), .YNaNE(FmaRzYNaN), .ZNaNE(FmaRzZNaN),
                                    .XSNaNE(FmaRzXSNaN), .YSNaNE(FmaRzYSNaN), .ZSNaNE(FmaRzZSNaN), 
                                    .XDenormE(FmaRzXDenorm), .ZDenormE(FmaRzZDenorm), 
                                    .XZeroE(FmaRzXZero), .YZeroE(FmaRzYZero), .ZZeroE(FmaRzZZero),
                                    .XInfE(FmaRzXInf), .YInfE(FmaRzYInf), .ZInfE(FmaRzZInf), .FmaFmt(FmaFmtVal),
                                    .X(FmaRzX), .Y(FmaRzY), .Z(FmaRzZ));
  readfmavectors readfmaruvectors (.clk, .TestVector(FmaRuVectors[VectorNum]), .Ans(FmaRuAns), .AnsFlg(FmaRuAnsFlg), 
                                    .XSgnE(FmaRuXSgn), .YSgnE(FmaRuYSgn), .ZSgnE(FmaRuZSgn), .FmaModFmt,
                                    .XExpE(FmaRuXExp), .YExpE(FmaRuYExp), .ZExpE(FmaRuZExp), 
                                    .XManE(FmaRuXMan), .YManE(FmaRuYMan), .ZManE(FmaRuZMan), 
                                    .XNaNE(FmaRuXNaN), .YNaNE(FmaRuYNaN), .ZNaNE(FmaRuZNaN),
                                    .XSNaNE(FmaRuXSNaN), .YSNaNE(FmaRuYSNaN), .ZSNaNE(FmaRuZSNaN), 
                                    .XDenormE(FmaRuXDenorm), .ZDenormE(FmaRuZDenorm), 
                                    .XZeroE(FmaRuXZero), .YZeroE(FmaRuYZero), .ZZeroE(FmaRuZZero),
                                    .XInfE(FmaRuXInf), .YInfE(FmaRuYInf), .ZInfE(FmaRuZInf), .FmaFmt(FmaFmtVal),
                                    .X(FmaRuX), .Y(FmaRuY), .Z(FmaRuZ));
  readfmavectors readfmardvectors (.clk, .TestVector(FmaRdVectors[VectorNum]), .Ans(FmaRdAns), .AnsFlg(FmaRdAnsFlg), 
                                    .XSgnE(FmaRdXSgn), .YSgnE(FmaRdYSgn), .ZSgnE(FmaRdZSgn), .FmaModFmt,
                                    .XExpE(FmaRdXExp), .YExpE(FmaRdYExp), .ZExpE(FmaRdZExp), 
                                    .XManE(FmaRdXMan), .YManE(FmaRdYMan), .ZManE(FmaRdZMan), 
                                    .XNaNE(FmaRdXNaN), .YNaNE(FmaRdYNaN), .ZNaNE(FmaRdZNaN),
                                    .XSNaNE(FmaRdXSNaN), .YSNaNE(FmaRdYSNaN), .ZSNaNE(FmaRdZSNaN), 
                                    .XDenormE(FmaRdXDenorm), .ZDenormE(FmaRdZDenorm), 
                                    .XZeroE(FmaRdXZero), .YZeroE(FmaRdYZero), .ZZeroE(FmaRdZZero),
                                    .XInfE(FmaRdXInf), .YInfE(FmaRdYInf), .ZInfE(FmaRdZInf), .FmaFmt(FmaFmtVal),
                                    .X(FmaRdX), .Y(FmaRdY), .Z(FmaRdZ));
  readfmavectors readfmarnmvectors (.clk, .TestVector(FmaRnmVectors[VectorNum]), .Ans(FmaRnmAns), .AnsFlg(FmaRnmAnsFlg), 
                                    .XSgnE(FmaRnmXSgn), .YSgnE(FmaRnmYSgn), .ZSgnE(FmaRnmZSgn), .FmaModFmt,
                                    .XExpE(FmaRnmXExp), .YExpE(FmaRnmYExp), .ZExpE(FmaRnmZExp), 
                                    .XManE(FmaRnmXMan), .YManE(FmaRnmYMan), .ZManE(FmaRnmZMan),
                                    .XNaNE(FmaRnmXNaN), .YNaNE(FmaRnmYNaN), .ZNaNE(FmaRnmZNaN),
                                    .XSNaNE(FmaRnmXSNaN), .YSNaNE(FmaRnmYSNaN), .ZSNaNE(FmaRnmZSNaN), 
                                    .XDenormE(FmaRnmXDenorm), .ZDenormE(FmaRnmZDenorm), 
                                    .XZeroE(FmaRnmXZero), .YZeroE(FmaRnmYZero), .ZZeroE(FmaRnmZZero),
                                    .XInfE(FmaRnmXInf), .YInfE(FmaRnmYInf), .ZInfE(FmaRnmZInf), .FmaFmt(FmaFmtVal),
                                    .X(FmaRnmX), .Y(FmaRnmY), .Z(FmaRnmZ));
  readvectors readvectors          (.clk, .Fmt(FmtVal), .ModFmt, .TestVector(TestVectors[VectorNum]), .VectorNum, .Ans(Ans), .AnsFlg(AnsFlg), .SrcA, 
                                    .XSgnE(XSgn), .YSgnE(YSgn), .ZSgnE(ZSgn), .Unit (UnitVal),
                                    .XExpE(XExp), .YExpE(YExp), .ZExpE(ZExp), .TestNum, .OpCtrl(OpCtrlVal),
                                    .XManE(XMan), .YManE(YMan), .ZManE(ZMan),
                                    .XNaNE(XNaN), .YNaNE(YNaN), .ZNaNE(ZNaN),
                                    .XSNaNE(XSNaN), .YSNaNE(YSNaN), .ZSNaNE(ZSNaN), 
                                    .XDenormE(XDenorm), .ZDenormE(ZDenorm), 
                                    .XZeroE(XZero), .YZeroE(YZero), .ZZeroE(ZZero),
                                    .XInfE(XInf), .YInfE(YInf), .ZInfE(ZInf), .XExpMaxE(XExpMax),
                                    .X, .Y, .Z);



  ///////////////////////////////////////////////////////////////////////////////////////////////

  //     |||||||   |||   ||| ||||||||| 
  //     |||   ||| |||   |||    |||    
  //     |||   ||| |||   |||    |||    
  //     |||   ||| |||   |||    |||         
  //     |||||||   |||||||||    |||    

  ///////////////////////////////////////////////////////////////////////////////////////////////

  // instantiate devices under test
  //    - one fma for each precison
  //    - all the units for the other tests (including fma for add/sub/mul)
  fma1 fma1rne(.XSgnE(FmaRneXSgn), .YSgnE(FmaRneYSgn), .ZSgnE(FmaRneZSgn), 
              .XExpE(FmaRneXExp), .YExpE(FmaRneYExp), .ZExpE(FmaRneZExp), 
              .XManE(FmaRneXMan), .YManE(FmaRneYMan), .ZManE(FmaRneZMan),
              .XZeroE(FmaRneXZero), .YZeroE(FmaRneYZero), .ZZeroE(FmaRneZZero),
              .FOpCtrlE(3'b0), .FmtE(FmaModFmt), .SumE(FmaRneSum), .NegSumE(FmaRneNegSum), .InvZE(FmaRneInvZ), 
              .NormCntE(FmaRneNormCnt), .ZSgnEffE(FmaRneZSgnEff), .PSgnE(FmaRnePSgn),
              .ProdExpE(FmaRneProdExp), .AddendStickyE(FmaRneAddendSticky), .KillProdE(FmaRneSumKillProd)); 
  fma2 fma2rne(.XSgnM(FmaRneXSgn), .YSgnM(FmaRneYSgn), 
              .ZExpM(FmaRneZExp), .ZDenormM(FmaRneZDenorm),
              .XManM(FmaRneXMan), .YManM(FmaRneYMan), .ZManM(FmaRneZMan), 
              .XNaNM(FmaRneXNaN), .YNaNM(FmaRneYNaN), .ZNaNM(FmaRneZNaN), 
              .XZeroM(FmaRneXZero), .YZeroM(FmaRneYZero), .ZZeroM(FmaRneZZero), 
              .XInfM(FmaRneXInf), .YInfM(FmaRneYInf), .ZInfM(FmaRneZInf), 
              .XSNaNM(FmaRneXSNaN), .YSNaNM(FmaRneYSNaN), .ZSNaNM(FmaRneZSNaN), 
              .KillProdM(FmaRneSumKillProd), .AddendStickyM(FmaRneAddendSticky), .ProdExpM(FmaRneProdExp), 
              .SumM((FmaRneSum)), .NegSumM(FmaRneNegSum), .InvZM(FmaRneInvZ), .NormCntM(FmaRneNormCnt), .ZSgnEffM(FmaRneZSgnEff), 
              .PSgnM(FmaRnePSgn), .FmtM(FmaModFmt), .FrmM(`RNE), 
              .FMAFlgM(FmaRneResFlg), .FMAResM(FmaRneRes), .Mult(1'b0));
  fma1 fma1rz(.XSgnE(FmaRzXSgn), .YSgnE(FmaRzYSgn), .ZSgnE(FmaRzZSgn), 
              .XExpE(FmaRzXExp), .YExpE(FmaRzYExp), .ZExpE(FmaRzZExp), 
              .XManE(FmaRzXMan), .YManE(FmaRzYMan), .ZManE(FmaRzZMan),
              .XZeroE(FmaRzXZero), .YZeroE(FmaRzYZero), .ZZeroE(FmaRzZZero),
              .FOpCtrlE(3'b0), .FmtE(FmaModFmt), .SumE(FmaRzSum), .NegSumE(FmaRzNegSum), .InvZE(FmaRzInvZ), 
              .NormCntE(FmaRzNormCnt), .ZSgnEffE(FmaRzZSgnEff), .PSgnE(FmaRzPSgn),
              .ProdExpE(FmaRzProdExp), .AddendStickyE(FmaRzAddendSticky), .KillProdE(FmaRzSumKillProd)); 
  fma2 fma2rz(.XSgnM(FmaRzXSgn), .YSgnM(FmaRzYSgn), 
              .ZExpM(FmaRzZExp),  .ZDenormM(FmaRzZDenorm),
              .XManM(FmaRzXMan), .YManM(FmaRzYMan), .ZManM(FmaRzZMan), 
              .XNaNM(FmaRzXNaN), .YNaNM(FmaRzYNaN), .ZNaNM(FmaRzZNaN), 
              .XZeroM(FmaRzXZero), .YZeroM(FmaRzYZero), .ZZeroM(FmaRzZZero), 
              .XInfM(FmaRzXInf), .YInfM(FmaRzYInf), .ZInfM(FmaRzZInf), 
              .XSNaNM(FmaRzXSNaN), .YSNaNM(FmaRzYSNaN), .ZSNaNM(FmaRzZSNaN), 
              .KillProdM(FmaRzSumKillProd), .AddendStickyM(FmaRzAddendSticky), .ProdExpM(FmaRzProdExp), 
              .SumM((FmaRzSum)), .NegSumM(FmaRzNegSum), .InvZM(FmaRzInvZ), .NormCntM(FmaRzNormCnt), .ZSgnEffM(FmaRzZSgnEff), 
              .PSgnM(FmaRzPSgn), .FmtM(FmaModFmt), .FrmM(`RZ), 
              .FMAFlgM(FmaRzResFlg), .FMAResM(FmaRzRes), .Mult(1'b0));
  fma1 fma1ru(.XSgnE(FmaRuXSgn), .YSgnE(FmaRuYSgn), .ZSgnE(FmaRuZSgn), 
              .XExpE(FmaRuXExp), .YExpE(FmaRuYExp), .ZExpE(FmaRuZExp), 
              .XManE(FmaRuXMan), .YManE(FmaRuYMan), .ZManE(FmaRuZMan),
              .XZeroE(FmaRuXZero), .YZeroE(FmaRuYZero), .ZZeroE(FmaRuZZero),
              .FOpCtrlE(3'b0), .FmtE(FmaModFmt), .SumE(FmaRuSum), .NegSumE(FmaRuNegSum), .InvZE(FmaRuInvZ), 
              .NormCntE(FmaRuNormCnt), .ZSgnEffE(FmaRuZSgnEff), .PSgnE(FmaRuPSgn),
              .ProdExpE(FmaRuProdExp), .AddendStickyE(FmaRuAddendSticky), .KillProdE(FmaRuSumKillProd)); 
  fma2 fma2ru(.XSgnM(FmaRuXSgn), .YSgnM(FmaRuYSgn), 
              .ZExpM(FmaRuZExp),  .ZDenormM(FmaRuZDenorm),
              .XManM(FmaRuXMan), .YManM(FmaRuYMan), .ZManM(FmaRuZMan), 
              .XNaNM(FmaRuXNaN), .YNaNM(FmaRuYNaN), .ZNaNM(FmaRuZNaN), 
              .XZeroM(FmaRuXZero), .YZeroM(FmaRuYZero), .ZZeroM(FmaRuZZero), 
              .XInfM(FmaRuXInf), .YInfM(FmaRuYInf), .ZInfM(FmaRuZInf), 
              .XSNaNM(FmaRuXSNaN), .YSNaNM(FmaRuYSNaN), .ZSNaNM(FmaRuZSNaN), 
              .KillProdM(FmaRuSumKillProd), .AddendStickyM(FmaRuAddendSticky), .ProdExpM(FmaRuProdExp), 
              .SumM((FmaRuSum)), .NegSumM(FmaRuNegSum), .InvZM(FmaRuInvZ), .NormCntM(FmaRuNormCnt), .ZSgnEffM(FmaRuZSgnEff), 
              .PSgnM(FmaRuPSgn), .FmtM(FmaModFmt), .FrmM(`RU), 
              .FMAFlgM(FmaRuResFlg), .FMAResM(FmaRuRes), .Mult(1'b0));
  fma1 fma1rd(.XSgnE(FmaRdXSgn), .YSgnE(FmaRdYSgn), .ZSgnE(FmaRdZSgn), 
              .XExpE(FmaRdXExp), .YExpE(FmaRdYExp), .ZExpE(FmaRdZExp), 
              .XManE(FmaRdXMan), .YManE(FmaRdYMan), .ZManE(FmaRdZMan), 
              .XZeroE(FmaRdXZero), .YZeroE(FmaRdYZero), .ZZeroE(FmaRdZZero),
              .FOpCtrlE(3'b0), .FmtE(FmaModFmt), .SumE(FmaRdSum), .NegSumE(FmaRdNegSum), .InvZE(FmaRdInvZ), 
              .NormCntE(FmaRdNormCnt), .ZSgnEffE(FmaRdZSgnEff), .PSgnE(FmaRdPSgn),
              .ProdExpE(FmaRdProdExp), .AddendStickyE(FmaRdAddendSticky), .KillProdE(FmaRdSumKillProd)); 
  fma2 fma2rd(.XSgnM(FmaRdXSgn), .YSgnM(FmaRdYSgn), 
              .ZExpM(FmaRdZExp),  .ZDenormM(FmaRdZDenorm),
              .XManM(FmaRdXMan), .YManM(FmaRdYMan), .ZManM(FmaRdZMan), 
              .XNaNM(FmaRdXNaN), .YNaNM(FmaRdYNaN), .ZNaNM(FmaRdZNaN), 
              .XZeroM(FmaRdXZero), .YZeroM(FmaRdYZero), .ZZeroM(FmaRdZZero), 
              .XInfM(FmaRdXInf), .YInfM(FmaRdYInf), .ZInfM(FmaRdZInf), 
              .XSNaNM(FmaRdXSNaN), .YSNaNM(FmaRdYSNaN), .ZSNaNM(FmaRdZSNaN), 
              .KillProdM(FmaRdSumKillProd), .AddendStickyM(FmaRdAddendSticky), .ProdExpM(FmaRdProdExp), 
              .SumM((FmaRdSum)), .NegSumM(FmaRdNegSum), .InvZM(FmaRdInvZ), .NormCntM(FmaRdNormCnt), .ZSgnEffM(FmaRdZSgnEff), 
              .PSgnM(FmaRdPSgn), .FmtM(FmaModFmt), .FrmM(`RD), 
              .FMAFlgM(FmaRdResFlg), .FMAResM(FmaRdRes), .Mult(1'b0));
  fma1 fma1rnm(.XSgnE(FmaRnmXSgn), .YSgnE(FmaRnmYSgn), .ZSgnE(FmaRnmZSgn), 
              .XExpE(FmaRnmXExp), .YExpE(FmaRnmYExp), .ZExpE(FmaRnmZExp), 
              .XManE(FmaRnmXMan), .YManE(FmaRnmYMan), .ZManE(FmaRnmZMan),
              .XZeroE(FmaRnmXZero), .YZeroE(FmaRnmYZero), .ZZeroE(FmaRnmZZero),
              .FOpCtrlE(3'b0), .FmtE(FmaModFmt), .SumE(FmaRnmSum), .NegSumE(FmaRnmNegSum), .InvZE(FmaRnmInvZ), 
              .NormCntE(FmaRnmNormCnt), .ZSgnEffE(FmaRnmZSgnEff), .PSgnE(FmaRnmPSgn),
              .ProdExpE(FmaRnmProdExp), .AddendStickyE(FmaRnmAddendSticky), .KillProdE(FmaRnmSumKillProd)); 
  fma2 fma2rnm(.XSgnM(FmaRnmXSgn), .YSgnM(FmaRnmYSgn), 
              .ZExpM(FmaRnmZExp),  .ZDenormM(FmaRnmZDenorm),
              .XManM(FmaRnmXMan), .YManM(FmaRnmYMan), .ZManM(FmaRnmZMan), 
              .XNaNM(FmaRnmXNaN), .YNaNM(FmaRnmYNaN), .ZNaNM(FmaRnmZNaN), 
              .XZeroM(FmaRnmXZero), .YZeroM(FmaRnmYZero), .ZZeroM(FmaRnmZZero), 
              .XInfM(FmaRnmXInf), .YInfM(FmaRnmYInf), .ZInfM(FmaRnmZInf), 
              .XSNaNM(FmaRnmXSNaN), .YSNaNM(FmaRnmYSNaN), .ZSNaNM(FmaRnmZSNaN), 
              .KillProdM(FmaRnmSumKillProd), .AddendStickyM(FmaRnmAddendSticky), .ProdExpM(FmaRnmProdExp), 
              .SumM((FmaRnmSum)), .NegSumM(FmaRnmNegSum), .InvZM(FmaRnmInvZ), .NormCntM(FmaRnmNormCnt), .ZSgnEffM(FmaRnmZSgnEff), 
              .PSgnM(FmaRnmPSgn), .FmtM(FmaModFmt), .FrmM(`RNM), 
              .FMAFlgM(FmaRnmResFlg), .FMAResM(FmaRnmRes), .Mult(1'b0));  
  fma1 fma1(.XSgnE(XSgn), .YSgnE(YSgn), .ZSgnE(ZSgn), 
              .XExpE(XExp), .YExpE(YExp), .ZExpE(ZExp), 
              .XManE(XMan), .YManE(YMan), .ZManE(ZMan),
              .XZeroE(XZero), .YZeroE(YZero), .ZZeroE(ZZero),
              .FOpCtrlE(OpCtrlVal), .FmtE(ModFmt), .SumE, .NegSumE, .InvZE, .NormCntE, .ZSgnEffE, .PSgnE,
              .ProdExpE, .AddendStickyE, .KillProdE); 
  fma2 fma2(.XSgnM(XSgn), .YSgnM(YSgn), 
              .ZExpM(ZExp),  .ZDenormM(ZDenorm),
              .XManM(XMan), .YManM(YMan), .ZManM(ZMan), 
              .XNaNM(XNaN), .YNaNM(YNaN), .ZNaNM(ZNaN), 
              .XZeroM(XZero), .YZeroM(YZero), .ZZeroM(ZZero), 
              .XInfM(XInf), .YInfM(YInf), .ZInfM(ZInf), 
              .XSNaNM(XSNaN), .YSNaNM(YSNaN), .ZSNaNM(ZSNaN), 
              .KillProdM(KillProdE), .AddendStickyM(AddendStickyE), .ProdExpM(ProdExpE), 
              .SumM(SumE), .NegSumM(NegSumE), .InvZM(InvZE), .NormCntM(NormCntE), .ZSgnEffM(ZSgnEffE), .PSgnM(PSgnE), .FmtM(ModFmt), .FrmM(FrmVal), 
              .FMAFlgM(FmaFlg), .FMAResM(FmaRes), .Mult);
  // fcvtfp fcvtfp (.XExpE(XExp), .XManE(XMan), .XSgnE(XSgn), .XZeroE(XZero), .XDenormE(XDenorm), .XInfE(XInf), 
  //             .XNaNE(XNaN), .XSNaNE(XSNaN), .FrmE(FrmVal), .FmtE(ModFmt), .CvtFpResE(CvtFpRes), .CvtFpFlgE(CvtFpFlg));
  
fcvt fcvt (.XSgnE(XSgn), .XExpE(XExp), .XManE(XMan), .ForwardedSrcAE(SrcA), .FWriteIntE(WriteIntVal), 
            .XZeroE(XZero), .XDenormE(XDenorm), .FOpCtrlE(OpCtrlVal),
            .XInfE(XInf), .XNaNE(XNaN), .XSNaNE(XSNaN), .FrmE(FrmVal), .FmtE(ModFmt), 
            .CvtResE(CvtRes), .CvtIntResE(CvtIntRes), .CvtFlgE(CvtFlg));
  fcmp fcmp   (.FmtE(ModFmt), .FOpCtrlE(OpCtrlVal), .XSgnE(XSgn), .YSgnE(YSgn), .XExpE(XExp), .YExpE(YExp), 
              .XManE(XMan), .YManE(YMan), .XZeroE(XZero), .YZeroE(YZero), 
              .XNaNE(XNaN), .YNaNE(YNaN), .XSNaNE(XSNaN), .YSNaNE(YSNaN), .FSrcXE(X), .FSrcYE(Y), .CmpNVE(CmpFlg[4]), .CmpResE(CmpRes));
  // fcvtint fcvtint (.XSgnE(XSgn), .XExpE(XExp), .XManE(XMan), .XZeroE(XZero), .XNaNE(XNaN), .XInfE(XInf), 
  //                 .XDenormE(XDenorm), .ForwardedSrcAE(SrcA), .FOpCtrlE, .FmtE(ModFmt), .FrmE(Frmal),
  //                 .CvtRes, .CvtFlgE);
  // *** integrade divide and squareroot
  //  fpdiv_pipe fdivsqrt (.op1(DivInput1E), .op2(DivInput2E), .rm(FrmVal[1:0]), .op_type(FOpCtrlQ), 
  //        .reset, .clk(clk), .start(FDivStartE), .P(~FmtQ), .OvEn(1'b1), .UnEn(1'b1),
  //        .XNaNQ, .YNaNQ, .XInfQ, .YInfQ, .XZeroQ, .YZeroQ, .load_preload,
  //        .FDivBusyE, .done(FDivSqrtDoneE), .AS_Res(FDivRes), .Flg(FDivFlg));

  assign CmpFlg[3:0] = 0;

  // produce clock
  always begin
    clk = 1; #5; clk = 0; #5;
  end
  
///////////////////////////////////////////////////////////////////////////////////////////////

//          |||||      |||  ||||||||||  |||||      |||
//          |||||||    |||  |||    |||  |||||||    |||
//          |||| |||   |||  ||||||||||  |||| |||   |||
//          ||||  |||  |||  |||    |||  ||||  |||  |||
//          ||||   ||| |||  |||    |||  ||||   ||| |||
//          ||||    ||||||  |||    |||  ||||    ||||||

///////////////////////////////////////////////////////////////////////////////////////////////

  //Check if the correct answer and result is a NaN
  always_comb begin
    case (FmaFmtVal)
        4'b11: begin // quad             
          FmaRneAnsNaN = &FmaRneAns[`Q_LEN-2:`Q_NF]&(|FmaRneAns[`Q_NF-1:0]);
          FmaRneResNaN = &FmaRneRes[`Q_LEN-2:`Q_NF]&(|FmaRneRes[`Q_NF-1:0]);
          FmaRzAnsNaN = &FmaRzAns[`Q_LEN-2:`Q_NF]&(|FmaRzAns[`Q_NF-1:0]);
          FmaRzResNaN = &FmaRzRes[`Q_LEN-2:`Q_NF]&(|FmaRzRes[`Q_NF-1:0]);
          FmaRuAnsNaN = &FmaRuAns[`Q_LEN-2:`Q_NF]&(|FmaRuAns[`Q_NF-1:0]);
          FmaRuResNaN = &FmaRuRes[`Q_LEN-2:`Q_NF]&(|FmaRuRes[`Q_NF-1:0]);
          FmaRdAnsNaN = &FmaRdAns[`Q_LEN-2:`Q_NF]&(|FmaRdAns[`Q_NF-1:0]);
          FmaRdResNaN = &FmaRdRes[`Q_LEN-2:`Q_NF]&(|FmaRdRes[`Q_NF-1:0]);
          FmaRnmAnsNaN = &FmaRnmAns[`Q_LEN-2:`Q_NF]&(|FmaRnmAns[`Q_NF-1:0]);
          FmaRnmResNaN = &FmaRnmRes[`Q_LEN-2:`Q_NF]&(|FmaRnmRes[`Q_NF-1:0]);
        end
        4'b01: begin // double                 
          FmaRneAnsNaN = &FmaRneAns[`D_LEN-2:`D_NF]&(|FmaRneAns[`D_NF-1:0]);
          FmaRneResNaN = &FmaRneRes[`D_LEN-2:`D_NF]&(|FmaRneRes[`D_NF-1:0]);
          FmaRzAnsNaN = &FmaRzAns[`D_LEN-2:`D_NF]&(|FmaRzAns[`D_NF-1:0]);
          FmaRzResNaN = &FmaRzRes[`D_LEN-2:`D_NF]&(|FmaRzRes[`D_NF-1:0]);
          FmaRuAnsNaN = &FmaRuAns[`D_LEN-2:`D_NF]&(|FmaRuAns[`D_NF-1:0]);
          FmaRuResNaN = &FmaRuRes[`D_LEN-2:`D_NF]&(|FmaRuRes[`D_NF-1:0]);
          FmaRdAnsNaN = &FmaRdAns[`D_LEN-2:`D_NF]&(|FmaRdAns[`D_NF-1:0]);
          FmaRdResNaN = &FmaRdRes[`D_LEN-2:`D_NF]&(|FmaRdRes[`D_NF-1:0]);
          FmaRnmAnsNaN = &FmaRnmAns[`D_LEN-2:`D_NF]&(|FmaRnmAns[`D_NF-1:0]);
          FmaRnmResNaN = &FmaRnmRes[`D_LEN-2:`D_NF]&(|FmaRnmRes[`D_NF-1:0]);
        end
        4'b00: begin // single
          FmaRneAnsNaN = &FmaRneAns[`S_LEN-2:`S_NF]&(|FmaRneAns[`S_NF-1:0]);
          FmaRneResNaN = &FmaRneRes[`S_LEN-2:`S_NF]&(|FmaRneRes[`S_NF-1:0]);
          FmaRzAnsNaN = &FmaRzAns[`S_LEN-2:`S_NF]&(|FmaRzAns[`S_NF-1:0]);
          FmaRzResNaN = &FmaRzRes[`S_LEN-2:`S_NF]&(|FmaRzRes[`S_NF-1:0]);
          FmaRuAnsNaN = &FmaRuAns[`S_LEN-2:`S_NF]&(|FmaRuAns[`S_NF-1:0]);
          FmaRuResNaN = &FmaRuRes[`S_LEN-2:`S_NF]&(|FmaRuRes[`S_NF-1:0]);
          FmaRdAnsNaN = &FmaRdAns[`S_LEN-2:`S_NF]&(|FmaRdAns[`S_NF-1:0]);
          FmaRdResNaN = &FmaRdRes[`S_LEN-2:`S_NF]&(|FmaRdRes[`S_NF-1:0]);
          FmaRnmAnsNaN = &FmaRnmAns[`S_LEN-2:`S_NF]&(|FmaRnmAns[`S_NF-1:0]);
          FmaRnmResNaN = &FmaRnmRes[`S_LEN-2:`S_NF]&(|FmaRnmRes[`S_NF-1:0]);
        end
        4'b10: begin // half
          FmaRneAnsNaN = &FmaRneAns[`H_LEN-2:`H_NF]&(|FmaRneAns[`H_NF-1:0]);
          FmaRneResNaN = &FmaRneRes[`H_LEN-2:`H_NF]&(|FmaRneRes[`H_NF-1:0]);
          FmaRzAnsNaN = &FmaRzAns[`H_LEN-2:`H_NF]&(|FmaRzAns[`H_NF-1:0]);
          FmaRzResNaN = &FmaRzRes[`H_LEN-2:`H_NF]&(|FmaRzRes[`H_NF-1:0]);
          FmaRuAnsNaN = &FmaRuAns[`H_LEN-2:`H_NF]&(|FmaRuAns[`H_NF-1:0]);
          FmaRuResNaN = &FmaRuRes[`H_LEN-2:`H_NF]&(|FmaRuRes[`H_NF-1:0]);
          FmaRdAnsNaN = &FmaRdAns[`H_LEN-2:`H_NF]&(|FmaRdAns[`H_NF-1:0]);
          FmaRdResNaN = &FmaRdRes[`H_LEN-2:`H_NF]&(|FmaRdRes[`H_NF-1:0]);
          FmaRnmAnsNaN = &FmaRnmAns[`H_LEN-2:`H_NF]&(|FmaRnmAns[`H_NF-1:0]);
          FmaRnmResNaN = &FmaRnmRes[`H_LEN-2:`H_NF]&(|FmaRnmRes[`H_NF-1:0]);
        end
    endcase
  end


  always_comb begin
    if(UnitVal === `CVTINTUNIT | UnitVal === `CMPUNIT) begin
      // an integer output can't be a NaN
      AnsNaN = 1'b0;
      ResNaN = 1'b0;
    end
    else if (UnitVal === `CVTFPUNIT) begin
      case (OpCtrlVal[1:0])
          4'b11: begin // quad             
            AnsNaN = &Ans[`Q_LEN-2:`NF]&(|Ans[`Q_NF-1:0]);
            ResNaN = &Res[`Q_LEN-2:`NF]&(|Res[`Q_NF-1:0]);
          end
          4'b01: begin // double                 
            AnsNaN = &Ans[`D_LEN-2:`D_NF]&(|Ans[`D_NF-1:0]);
            ResNaN = &Res[`D_LEN-2:`D_NF]&(|Res[`D_NF-1:0]);
          end
          4'b00: begin // single
            AnsNaN = &Ans[`S_LEN-2:`S_NF]&(|Ans[`S_NF-1:0]);
            ResNaN = &Res[`S_LEN-2:`S_NF]&(|Res[`S_NF-1:0]);
          end
          4'b10: begin // half
            AnsNaN = &Ans[`H_LEN-2:`H_NF]&(|Ans[`H_NF-1:0]);
            ResNaN = &Res[`H_LEN-2:`H_NF]&(|Res[`H_NF-1:0]);
          end
      endcase
    end
    else begin
      case (FmtVal)
          4'b11: begin // quad             
            AnsNaN = &Ans[`Q_LEN-2:`Q_NF]&(|Ans[`Q_NF-1:0]);
            ResNaN = &Res[`Q_LEN-2:`Q_NF]&(|Res[`Q_NF-1:0]);
          end
          4'b01: begin // double                 
            AnsNaN = &Ans[`D_LEN-2:`D_NF]&(|Ans[`D_NF-1:0]);
            ResNaN = &Res[`D_LEN-2:`D_NF]&(|Res[`D_NF-1:0]);
          end
          4'b00: begin // single
            AnsNaN = &Ans[`S_LEN-2:`S_NF]&(|Ans[`S_NF-1:0]);
            ResNaN = &Res[`S_LEN-2:`S_NF]&(|Res[`S_NF-1:0]);
          end
          4'b10: begin // half
            AnsNaN = &Ans[`H_LEN-2:`H_NF]&(|Ans[`H_NF-1:0]);
            ResNaN = &Res[`H_LEN-2:`H_NF]&(|Res[`H_NF-1:0]);
          end
      endcase
    end
  end
always_comb begin
    // select the result to check
    case (UnitVal)
      `FMAUNIT: Res = FmaRes;
      `DIVUNIT: Res = DivRes;
      `CMPUNIT: Res = CmpRes;
      `CVTINTUNIT: if(WriteIntVal) Res = CvtIntRes; else Res = CvtRes;
      `CVTFPUNIT: Res = CvtRes;
    endcase

    // select the flag to check
    case (UnitVal)
      `FMAUNIT: ResFlg = FmaFlg;
      `DIVUNIT: ResFlg = DivFlg;
      `CMPUNIT: ResFlg = CmpFlg;
      `CVTINTUNIT: ResFlg = CvtFlg;
      `CVTFPUNIT: ResFlg = CvtFlg;
    endcase
end
  // check results on falling edge of clk
  always @(negedge clk) begin


    // check if the NaN value is good. IEEE754-2019 sections 6.3 and 6.2.3 specify:
    //    - the sign of the NaN does not matter for the opperations being tested
    //    - when 2 or more NaNs are inputed the NaN that is propigated doesn't matter
    case (FmaFmtVal)
      4'b11: FmaRneNaNGood =((FmaRneAnsFlg[4]&(FmaRneRes[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                            (FmaRneXNaN&(FmaRneRes[`Q_LEN-2:0] === {FmaRneX[`Q_LEN-2:`Q_NF],1'b1,FmaRneX[`Q_NF-2:0]})) | 
                            (FmaRneYNaN&(FmaRneRes[`Q_LEN-2:0] === {FmaRneY[`Q_LEN-2:`Q_NF],1'b1,FmaRneY[`Q_NF-2:0]})) | 
                            (FmaRneZNaN&(FmaRneRes[`Q_LEN-2:0] === {FmaRneZ[`Q_LEN-2:`Q_NF],1'b1,FmaRneZ[`Q_NF-2:0]})));
      4'b01: FmaRneNaNGood =((FmaRneAnsFlg[4]&(FmaRneRes[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                            (FmaRneXNaN&(FmaRneRes[`D_LEN-2:0] === {FmaRneX[`D_LEN-2:`D_NF],1'b1,FmaRneX[`D_NF-2:0]})) | 
                            (FmaRneYNaN&(FmaRneRes[`D_LEN-2:0] === {FmaRneY[`D_LEN-2:`D_NF],1'b1,FmaRneY[`D_NF-2:0]})) | 
                            (FmaRneZNaN&(FmaRneRes[`D_LEN-2:0] === {FmaRneZ[`D_LEN-2:`D_NF],1'b1,FmaRneZ[`D_NF-2:0]})));
      4'b00: FmaRneNaNGood =((FmaRneAnsFlg[4]&(FmaRneRes[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                            (FmaRneXNaN&(FmaRneRes[`S_LEN-2:0] === {FmaRneX[`S_LEN-2:`S_NF],1'b1,FmaRneX[`S_NF-2:0]})) | 
                            (FmaRneYNaN&(FmaRneRes[`S_LEN-2:0] === {FmaRneY[`S_LEN-2:`S_NF],1'b1,FmaRneY[`S_NF-2:0]})) | 
                            (FmaRneZNaN&(FmaRneRes[`S_LEN-2:0] === {FmaRneZ[`S_LEN-2:`S_NF],1'b1,FmaRneZ[`S_NF-2:0]})));
      4'b10: FmaRneNaNGood =((FmaRneAnsFlg[4]&(FmaRneRes[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                            (FmaRneXNaN&(FmaRneRes[`H_LEN-2:0] === {FmaRneX[`H_LEN-2:`H_NF],1'b1,FmaRneX[`H_NF-2:0]})) | 
                            (FmaRneYNaN&(FmaRneRes[`H_LEN-2:0] === {FmaRneY[`H_LEN-2:`H_NF],1'b1,FmaRneY[`H_NF-2:0]})) | 
                            (FmaRneZNaN&(FmaRneRes[`H_LEN-2:0] === {FmaRneZ[`H_LEN-2:`H_NF],1'b1,FmaRneZ[`H_NF-2:0]})));
    endcase
    case (FmaFmtVal)
      4'b11: FmaRzNaNGood = ((FmaRzAnsFlg[4]&(FmaRzRes[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                            (FmaRzXNaN&(FmaRzRes[`Q_LEN-2:0] === {FmaRzX[`Q_LEN-2:`Q_NF],1'b1,FmaRzX[`Q_NF-2:0]})) | 
                            (FmaRzYNaN&(FmaRzRes[`Q_LEN-2:0] === {FmaRzY[`Q_LEN-2:`Q_NF],1'b1,FmaRzY[`Q_NF-2:0]})) | 
                            (FmaRzZNaN&(FmaRzRes[`Q_LEN-2:0] === {FmaRzZ[`Q_LEN-2:`Q_NF],1'b1,FmaRzZ[`Q_NF-2:0]})));
      4'b01: FmaRzNaNGood = ((FmaRzAnsFlg[4]&(FmaRzRes[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                            (FmaRzXNaN&(FmaRzRes[`D_LEN-2:0] === {FmaRzX[`D_LEN-2:`D_NF],1'b1,FmaRzX[`D_NF-2:0]})) | 
                            (FmaRzYNaN&(FmaRzRes[`D_LEN-2:0] === {FmaRzY[`D_LEN-2:`D_NF],1'b1,FmaRzY[`D_NF-2:0]})) | 
                            (FmaRzZNaN&(FmaRzRes[`D_LEN-2:0] === {FmaRzZ[`D_LEN-2:`D_NF],1'b1,FmaRzZ[`D_NF-2:0]})));
      4'b00: FmaRzNaNGood = ((FmaRzAnsFlg[4]&(FmaRzRes[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                            (FmaRzXNaN&(FmaRzRes[`S_LEN-2:0] === {FmaRzX[`S_LEN-2:`S_NF],1'b1,FmaRzX[`S_NF-2:0]})) | 
                            (FmaRzYNaN&(FmaRzRes[`S_LEN-2:0] === {FmaRzY[`S_LEN-2:`S_NF],1'b1,FmaRzY[`S_NF-2:0]})) | 
                            (FmaRzZNaN&(FmaRzRes[`S_LEN-2:0] === {FmaRzZ[`S_LEN-2:`S_NF],1'b1,FmaRzZ[`S_NF-2:0]})));
      4'b10: FmaRzNaNGood = ((FmaRzAnsFlg[4]&(FmaRzRes[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                            (FmaRzXNaN&(FmaRzRes[`H_LEN-2:0] === {FmaRzX[`H_LEN-2:`H_NF],1'b1,FmaRzX[`H_NF-2:0]})) | 
                            (FmaRzYNaN&(FmaRzRes[`H_LEN-2:0] === {FmaRzY[`H_LEN-2:`H_NF],1'b1,FmaRzY[`H_NF-2:0]})) | 
                            (FmaRzZNaN&(FmaRzRes[`H_LEN-2:0] === {FmaRzZ[`H_LEN-2:`H_NF],1'b1,FmaRzZ[`H_NF-2:0]})));
    endcase
    case (FmaFmtVal)
      4'b11: FmaRuNaNGood = ((FmaRuAnsFlg[4]&(FmaRuRes[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                            (FmaRuXNaN&(FmaRuRes[`Q_LEN-2:0] === {FmaRuX[`Q_LEN-2:`Q_NF],1'b1,FmaRuX[`Q_NF-2:0]})) | 
                            (FmaRuYNaN&(FmaRuRes[`Q_LEN-2:0] === {FmaRuY[`Q_LEN-2:`Q_NF],1'b1,FmaRuY[`Q_NF-2:0]})) | 
                            (FmaRuZNaN&(FmaRuRes[`Q_LEN-2:0] === {FmaRuZ[`Q_LEN-2:`Q_NF],1'b1,FmaRuZ[`Q_NF-2:0]})));
      4'b01: FmaRuNaNGood = ((FmaRuAnsFlg[4]&(FmaRuRes[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                            (FmaRuAnsFlg[4]&(FmaRuRes[`Q_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF{1'b0}}})) |
                            (FmaRuXNaN&(FmaRuRes[`D_LEN-2:0] === {FmaRuX[`D_LEN-2:`D_NF],1'b1,FmaRuX[`D_NF-2:0]})) | 
                            (FmaRuYNaN&(FmaRuRes[`D_LEN-2:0] === {FmaRuY[`D_LEN-2:`D_NF],1'b1,FmaRuY[`D_NF-2:0]})) | 
                            (FmaRuZNaN&(FmaRuRes[`D_LEN-2:0] === {FmaRuZ[`D_LEN-2:`D_NF],1'b1,FmaRuZ[`D_NF-2:0]})));
      4'b00: FmaRuNaNGood = ((FmaRuAnsFlg[4]&(FmaRuRes[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                            (FmaRuXNaN&(FmaRuRes[`S_LEN-2:0] === {FmaRuX[`S_LEN-2:`S_NF],1'b1,FmaRuX[`S_NF-2:0]})) | 
                            (FmaRuYNaN&(FmaRuRes[`S_LEN-2:0] === {FmaRuY[`S_LEN-2:`S_NF],1'b1,FmaRuY[`S_NF-2:0]})) | 
                            (FmaRuZNaN&(FmaRuRes[`S_LEN-2:0] === {FmaRuZ[`S_LEN-2:`S_NF],1'b1,FmaRuZ[`S_NF-2:0]})));
      4'b10: FmaRuNaNGood = ((FmaRuAnsFlg[4]&(FmaRuRes[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                            (FmaRuXNaN&(FmaRuRes[`H_LEN-2:0] === {FmaRuX[`H_LEN-2:`H_NF],1'b1,FmaRuX[`H_NF-2:0]})) | 
                            (FmaRuYNaN&(FmaRuRes[`H_LEN-2:0] === {FmaRuY[`H_LEN-2:`H_NF],1'b1,FmaRuY[`H_NF-2:0]})) | 
                            (FmaRuZNaN&(FmaRuRes[`H_LEN-2:0] === {FmaRuZ[`H_LEN-2:`H_NF],1'b1,FmaRuZ[`H_NF-2:0]})));
    endcase
    case (FmaFmtVal)
      4'b11: FmaRdNaNGood = ((FmaRdAnsFlg[4]&(FmaRdRes[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                            (FmaRdXNaN&(FmaRdRes[`Q_LEN-2:0] === {FmaRdX[`Q_LEN-2:`Q_NF],1'b1,FmaRdX[`Q_NF-2:0]})) | 
                            (FmaRdYNaN&(FmaRdRes[`Q_LEN-2:0] === {FmaRdY[`Q_LEN-2:`Q_NF],1'b1,FmaRdY[`Q_NF-2:0]})) | 
                            (FmaRdZNaN&(FmaRdRes[`Q_LEN-2:0] === {FmaRdZ[`Q_LEN-2:`Q_NF],1'b1,FmaRdZ[`Q_NF-2:0]})));
      4'b01: FmaRdNaNGood = ((FmaRdAnsFlg[4]&(FmaRdRes[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                            (FmaRdXNaN&(FmaRdRes[`D_LEN-2:0] === {FmaRdX[`D_LEN-2:`D_NF],1'b1,FmaRdX[`D_NF-2:0]})) | 
                            (FmaRdYNaN&(FmaRdRes[`D_LEN-2:0] === {FmaRdY[`D_LEN-2:`D_NF],1'b1,FmaRdY[`D_NF-2:0]})) | 
                            (FmaRdZNaN&(FmaRdRes[`D_LEN-2:0] === {FmaRdZ[`D_LEN-2:`D_NF],1'b1,FmaRdZ[`D_NF-2:0]})));
      4'b00: FmaRdNaNGood = ((FmaRdAnsFlg[4]&(FmaRdRes[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                            (FmaRdXNaN&(FmaRdRes[`S_LEN-2:0] === {FmaRdX[`S_LEN-2:`S_NF],1'b1,FmaRdX[`S_NF-2:0]})) | 
                            (FmaRdYNaN&(FmaRdRes[`S_LEN-2:0] === {FmaRdY[`S_LEN-2:`S_NF],1'b1,FmaRdY[`S_NF-2:0]})) | 
                            (FmaRdZNaN&(FmaRdRes[`S_LEN-2:0] === {FmaRdZ[`S_LEN-2:`S_NF],1'b1,FmaRdZ[`S_NF-2:0]})));
      4'b10: FmaRdNaNGood = ((FmaRdAnsFlg[4]&(FmaRdRes[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                            (FmaRdXNaN&(FmaRdRes[`H_LEN-2:0] === {FmaRdX[`H_LEN-2:`H_NF],1'b1,FmaRdX[`H_NF-2:0]})) | 
                            (FmaRdYNaN&(FmaRdRes[`H_LEN-2:0] === {FmaRdY[`H_LEN-2:`H_NF],1'b1,FmaRdY[`H_NF-2:0]})) | 
                            (FmaRdZNaN&(FmaRdRes[`H_LEN-2:0] === {FmaRdZ[`H_LEN-2:`H_NF],1'b1,FmaRdZ[`H_NF-2:0]})));
    endcase
    case (FmaFmtVal)
      4'b11: FmaRnmNaNGood =((FmaRnmAnsFlg[4]&(FmaRnmRes[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                            (FmaRnmXNaN&(FmaRnmRes[`Q_LEN-2:0] === {FmaRnmX[`Q_LEN-2:`Q_NF],1'b1,FmaRnmX[`Q_NF-2:0]})) | 
                            (FmaRnmYNaN&(FmaRnmRes[`Q_LEN-2:0] === {FmaRnmY[`Q_LEN-2:`Q_NF],1'b1,FmaRnmY[`Q_NF-2:0]})) | 
                            (FmaRnmZNaN&(FmaRnmRes[`Q_LEN-2:0] === {FmaRnmZ[`Q_LEN-2:`Q_NF],1'b1,FmaRnmZ[`Q_NF-2:0]})));
      4'b01: FmaRnmNaNGood =((FmaRnmAnsFlg[4]&(FmaRnmRes[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                            (FmaRnmXNaN&(FmaRnmRes[`D_LEN-2:0] === {FmaRnmX[`D_LEN-2:`D_NF],1'b1,FmaRnmX[`D_NF-2:0]})) | 
                            (FmaRnmYNaN&(FmaRnmRes[`D_LEN-2:0] === {FmaRnmY[`D_LEN-2:`D_NF],1'b1,FmaRnmY[`D_NF-2:0]})) | 
                            (FmaRnmZNaN&(FmaRnmRes[`D_LEN-2:0] === {FmaRnmZ[`D_LEN-2:`D_NF],1'b1,FmaRnmZ[`D_NF-2:0]})));
      4'b00: FmaRnmNaNGood =((FmaRnmAnsFlg[4]&(FmaRnmRes[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                            (FmaRnmXNaN&(FmaRnmRes[`S_LEN-2:0] === {FmaRnmX[`S_LEN-2:`S_NF],1'b1,FmaRnmX[`S_NF-2:0]})) | 
                            (FmaRnmYNaN&(FmaRnmRes[`S_LEN-2:0] === {FmaRnmY[`S_LEN-2:`S_NF],1'b1,FmaRnmY[`S_NF-2:0]})) | 
                            (FmaRnmZNaN&(FmaRnmRes[`S_LEN-2:0] === {FmaRnmZ[`S_LEN-2:`S_NF],1'b1,FmaRnmZ[`S_NF-2:0]})));
      4'b10: FmaRnmNaNGood =((FmaRnmAnsFlg[4]&(FmaRnmRes[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                            (FmaRnmXNaN&(FmaRnmRes[`H_LEN-2:0] === {FmaRnmX[`H_LEN-2:`H_NF],1'b1,FmaRnmX[`H_NF-2:0]})) | 
                            (FmaRnmYNaN&(FmaRnmRes[`H_LEN-2:0] === {FmaRnmY[`H_LEN-2:`H_NF],1'b1,FmaRnmY[`H_NF-2:0]})) | 
                            (FmaRnmZNaN&(FmaRnmRes[`H_LEN-2:0] === {FmaRnmZ[`H_LEN-2:`H_NF],1'b1,FmaRnmZ[`H_NF-2:0]})));
    endcase
    if (UnitVal !== `CVTFPUNIT & UnitVal !== `CVTINTUNIT)
      case (FmtVal)
        4'b11: NaNGood =  ((AnsFlg[4]&(Res[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                          (XNaN&(Res[`Q_LEN-2:0] === {X[`Q_LEN-2:`Q_NF],1'b1,X[`Q_NF-2:0]})) | 
                          (YNaN&(Res[`Q_LEN-2:0] === {Y[`Q_LEN-2:`Q_NF],1'b1,Y[`Q_NF-2:0]})) |
                          (ZNaN&(Res[`Q_LEN-2:0] === {Z[`Q_LEN-2:`Q_NF],1'b1,Z[`Q_NF-2:0]})));
        4'b01: NaNGood =  ((AnsFlg[4]&(Res[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                          (XNaN&(Res[`D_LEN-2:0] === {X[`D_LEN-2:`D_NF],1'b1,X[`D_NF-2:0]})) | 
                          (YNaN&(Res[`D_LEN-2:0] === {Y[`D_LEN-2:`D_NF],1'b1,Y[`D_NF-2:0]})) |
                          (ZNaN&(Res[`D_LEN-2:0] === {Z[`D_LEN-2:`D_NF],1'b1,Z[`D_NF-2:0]})));
        4'b00: NaNGood =  ((AnsFlg[4]&(Res[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                          (XNaN&(Res[`S_LEN-2:0] === {X[`S_LEN-2:`S_NF],1'b1,X[`S_NF-2:0]})) | 
                          (YNaN&(Res[`S_LEN-2:0] === {Y[`S_LEN-2:`S_NF],1'b1,Y[`S_NF-2:0]})) |
                          (ZNaN&(Res[`S_LEN-2:0] === {Z[`S_LEN-2:`S_NF],1'b1,Z[`S_NF-2:0]})));
        4'b10: NaNGood =  ((AnsFlg[4]&(Res[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                          (XNaN&(Res[`H_LEN-2:0] === {X[`H_LEN-2:`H_NF],1'b1,X[`H_NF-2:0]})) | 
                          (YNaN&(Res[`H_LEN-2:0] === {Y[`H_LEN-2:`H_NF],1'b1,Y[`H_NF-2:0]})) |
                          (ZNaN&(Res[`H_LEN-2:0] === {Z[`H_LEN-2:`H_NF],1'b1,Z[`H_NF-2:0]})));
      endcase
    else if (UnitVal === `CVTFPUNIT) // if converting from floating point to floating point OpCtrl contains the final FP format
      case (OpCtrlVal[1:0]) 
        2'b11: NaNGood = ((AnsFlg[4]&(Res[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                          (AnsNaN&(Res[`Q_LEN-2:0] === Ans[`Q_LEN-2:0])) | 
                          (XNaN&(Res[`Q_LEN-2:0] === {X[`Q_LEN-2:`Q_NF],1'b1,X[`Q_NF-2:0]})) | 
                          (YNaN&(Res[`Q_LEN-2:0] === {Y[`Q_LEN-2:`Q_NF],1'b1,Y[`Q_NF-2:0]})));
        2'b01: NaNGood = ((AnsFlg[4]&(Res[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                          (AnsNaN&(Res[`D_LEN-2:0] === Ans[`D_LEN-2:0])) | 
                          (XNaN&(Res[`D_LEN-2:0] === {X[`D_LEN-2:`D_NF],1'b1,X[`D_NF-2:0]})) | 
                          (YNaN&(Res[`D_LEN-2:0] === {Y[`D_LEN-2:`D_NF],1'b1,Y[`D_NF-2:0]})));
        2'b00: NaNGood = ((AnsFlg[4]&(Res[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                          (AnsNaN&(Res[`S_LEN-2:0] === Ans[`S_LEN-2:0])) | 
                          (XNaN&(Res[`S_LEN-2:0] === {X[`S_LEN-2:`S_NF],1'b1,X[`S_NF-2:0]})) | 
                          (YNaN&(Res[`S_LEN-2:0] === {Y[`S_LEN-2:`S_NF],1'b1,Y[`S_NF-2:0]})));
        2'b10: NaNGood = ((AnsFlg[4]&(Res[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                          (AnsNaN&(Res[`H_LEN-2:0] === Ans[`H_LEN-2:0])) | 
                          (XNaN&(Res[`H_LEN-2:0] === {X[`H_LEN-2:`H_NF],1'b1,X[`H_NF-2:0]})) | 
                          (YNaN&(Res[`H_LEN-2:0] === {Y[`H_LEN-2:`H_NF],1'b1,Y[`H_NF-2:0]})));
      endcase
    else NaNGood = 1'b0; // integers can't be NaNs

    
  ///////////////////////////////////////////////////////////////////////////////////////////////

  //     ||||||| |||    ||| ||||||| ||||||| |||   |||
  //     |||     |||    ||| |||     |||     |||  |||
  //     |||     |||||||||| ||||||| |||     ||||||
  //     |||     |||    ||| |||     |||     |||  |||
  //     ||||||| |||    ||| ||||||| ||||||| |||    |||

  ///////////////////////////////////////////////////////////////////////////////////////////////

    // check if the non-fma test is correct
    if(~((Res === Ans | NaNGood | NaNGood === 1'bx) & (ResFlg === AnsFlg | AnsFlg === 5'bx))&(UnitVal !== `CVTINTUNIT)&(UnitVal !== `CMPUNIT)) begin
      errors += 1;
      $display("There is an error in %s", Tests[TestNum]);
      $display("inputs: %h %h %h\nSrcA: %h\n Res: %h %h\n Ans: %h %h", X, Y, Z, SrcA, Res, ResFlg, Ans, AnsFlg);
      $stop;
    end
    
    // TestFloat sets the result to all 1's when there is an invalid result, however in 
    // http://www.jhauser.us/arithmetic/TestFloat-3/doc/TestFloat-general.html it says
    // for an unsigned integer result 0 is also okay

    // Testfloat outputs 800... for both the largest integer values for both positive and negitive numbers but 
    // the riscv spec specifies 2^31-1 for positive values out of range and NaNs ie 7fff...
    else if ((UnitVal === `CVTINTUNIT) & ~(((WriteIntVal&~OpCtrlVal[0]&AnsFlg[4]&XSgn&(Res[`XLEN-1:0] === (`XLEN)'(0))) | 
            (WriteIntVal&OpCtrlVal[0]&AnsFlg[4]&(~XSgn|XNaN)&OpCtrlVal[1]&(Res[`XLEN-1:0] === {1'b0, {`XLEN-1{1'b1}}})) | 
            (WriteIntVal&OpCtrlVal[0]&AnsFlg[4]&(~XSgn|XNaN)&~OpCtrlVal[1]&(Res[`XLEN-1:0] === {{`XLEN-32{1'b0}}, 1'b0, {31{1'b1}}})) | 
            (~(WriteIntVal&~OpCtrlVal[0]&AnsFlg[4]&XSgn)&(Res === Ans | NaNGood | NaNGood === 1'bx))) & (ResFlg === AnsFlg | AnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in %s", Tests[TestNum]);
      $display("inputs: %h %h %h\nSrcA: %h\n Res: %h %h\n Ans: %h %h", X, Y, Z, SrcA, Res, ResFlg, Ans, AnsFlg);
      $stop;
    end

    // check if the fma tests are correct
    if(~((FmaRneRes === FmaRneAns | FmaRneNaNGood | FmaRneNaNGood === 1'bx)  & (FmaRneResFlg === FmaRneAnsFlg | FmaRneAnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in FMA - RNE");
      $display("inputs: %h %h %h\n Res: %h %h\n Ans: %h %h", FmaRneX, FmaRneY, FmaRneZ, FmaRneRes, FmaRneResFlg, FmaRneAns, FmaRneAnsFlg);
      $stop;
    end
    if(~((FmaRzRes === FmaRzAns | FmaRzNaNGood | FmaRzNaNGood === 1'bx) & (FmaRzResFlg === FmaRzAnsFlg | FmaRzAnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in FMA - RZ");
      $display("inputs: %h %h %h\n Res: %h %h\n Ans: %h %h", FmaRzX, FmaRzY, FmaRzZ, FmaRzRes, FmaRzResFlg, FmaRzAns, FmaRzAnsFlg);
      $stop;
    end
    if(~((FmaRuRes === FmaRuAns | FmaRuNaNGood | FmaRuNaNGood === 1'bx) & (FmaRuResFlg === FmaRuAnsFlg | FmaRuAnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in FMA - RU");
      $display("inputs: %h %h %h\n Res: %h %h\n Ans: %h %h", FmaRuX, FmaRuY, FmaRuZ, FmaRuRes, FmaRuResFlg, FmaRuAns, FmaRuAnsFlg);
      $stop;
    end
    if(~((FmaRdRes === FmaRdAns | FmaRdNaNGood | FmaRdNaNGood === 1'bx) & (FmaRdResFlg === FmaRdAnsFlg | FmaRdAnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in FMA - RD");
      $display("inputs: %h %h %h\n Res: %h %h\n Ans: %h %h", FmaRdX, FmaRdY, FmaRdZ, FmaRdRes, FmaRdResFlg, FmaRdAns, FmaRdAnsFlg);
      $stop;
    end
    if(~((FmaRnmRes === FmaRnmAns | FmaRnmNaNGood | FmaRnmNaNGood === 1'bx) & (FmaRnmResFlg === FmaRnmAnsFlg | FmaRnmAnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in FMA - RNM");
      $display("inputs: %h %h %h\n Res: %h %h\n Ans: %h %h", FmaRnmX, FmaRnmY, FmaRnmZ, FmaRnmRes, FmaRnmResFlg, FmaRnmAns, FmaRnmAnsFlg);
      $stop;
    end

    VectorNum += 1; // increment the vector

    // check to see if there more vectors in this test
    // *** fix this so that fma and other run sepratly - re-add fma num
    if (TestVectors[VectorNum][0] === 1'bx & 
        FmaRneVectors[VectorNum][0] === 1'bx & 
        FmaRzVectors[VectorNum][0] === 1'bx & 
        FmaRuVectors[VectorNum][0] === 1'bx & 
        FmaRdVectors[VectorNum][0] === 1'bx & 
        FmaRnmVectors[VectorNum][0] === 1'bx) begin // if reached the end of file

      // increment the test
      TestNum += 1;

      // clear the vectors
      for(int i=0; i<46465; i++) TestVectors[i] = {`FLEN*4+8{1'bx}};
      // read next files
      $readmemh({`PATH, Tests[TestNum]}, TestVectors);
      $readmemh({`PATH, FmaRneTests[TestNum]}, FmaRneVectors);
      $readmemh({`PATH, FmaRuTests[TestNum]}, FmaRuVectors);
      $readmemh({`PATH, FmaRdTests[TestNum]}, FmaRdVectors);
      $readmemh({`PATH, FmaRzTests[TestNum]}, FmaRzVectors);
      $readmemh({`PATH, FmaRnmTests[TestNum]}, FmaRnmVectors);

      // set the vector index back to 0
      VectorNum = 0;
      // incemet the operation if all the rounding modes have been tested
      if(FrmNum === 4) OpCtrlNum += 1;
      // increment the rounding mode or loop back to rne 
      if(FrmNum < 4) FrmNum += 1;
      else FrmNum = 0; 

      // if no more Tests - finish
      if(Tests[TestNum] === "" & 
        FmaRneTests[TestNum] === "" & 
        FmaRzTests[TestNum] === "" & 
        FmaRuTests[TestNum] === "" & 
        FmaRdTests[TestNum] === "" & 
        FmaRnmTests[TestNum] === "") begin
        $display("\nAll Tests completed with %d errors\n", errors);
        $stop;
      end 

      $display("Running %s vectors", Tests[TestNum]);
    end
  end
endmodule













module readfmavectors (
  input logic                 clk,
  input logic [`FMTBITS-1:0]  FmaModFmt,              // the modified format
  input logic [1:0]           FmaFmt,                 // the format of the FMA inputs
  input logic [`FLEN*4+7:0]   TestVector,             // the test vector
  output logic [`FLEN-1:0]    Ans,                    // the correct answer
  output logic [4:0]          AnsFlg,                 // the correct flag
  output logic                XSgnE, YSgnE, ZSgnE,    // sign bits of XYZ
  output logic [`NE-1:0]      XExpE, YExpE, ZExpE,    // exponents of XYZ (converted to largest supported precision)
  output logic [`NF:0]        XManE, YManE, ZManE,    // mantissas of XYZ (converted to largest supported precision)
  output logic                XNaNE, YNaNE, ZNaNE,    // is XYZ a NaN
  output logic                XSNaNE, YSNaNE, ZSNaNE, // is XYZ a signaling NaN
  output logic                XDenormE, ZDenormE,   // is XYZ denormalized
  output logic                XZeroE, YZeroE, ZZeroE,         // is XYZ zero
  output logic                XInfE, YInfE, ZInfE,            // is XYZ infinity
  output logic [`FLEN-1:0]    X, Y, Z                 // inputs
);

  logic XExpMaxE; // signals the unpacker outputs but isn't used in FMA
  // apply test vectors on rising edge of clk
  // Format of vectors Inputs(1/2/3)_AnsFlg
  always @(posedge clk) begin
    #1; 
    AnsFlg = TestVector[4:0];
    case (FmaFmt)
      2'b11: begin       // quad
        X = TestVector[8+4*(`Q_LEN)-1:8+3*(`Q_LEN)];
        Y = TestVector[8+3*(`Q_LEN)-1:8+2*(`Q_LEN)];
        Z = TestVector[8+2*(`Q_LEN)-1:8+`Q_LEN];
        Ans = TestVector[8+(`Q_LEN-1):8];
      end
      2'b01:	begin	  // double
          X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+4*(`D_LEN)-1:8+3*(`D_LEN)]};
          Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+3*(`D_LEN)-1:8+2*(`D_LEN)]};
          Z = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+`D_LEN]};
          Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
      end
      2'b00:	begin	  // single
          X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+4*(`S_LEN)-1:8+3*(`S_LEN)]};
          Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+3*(`S_LEN)-1:8+2*(`S_LEN)]};
          Z = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+`S_LEN]};
          Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
      end
      2'b10:	begin	  // half
          X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+4*(`H_LEN)-1:8+3*(`H_LEN)]};
          Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+3*(`H_LEN)-1:8+2*(`H_LEN)]};
          Z = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+`H_LEN]};
          Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
      end
    endcase
  end
  
  unpack unpack(.X, .Y, .Z, .FmtE(FmaModFmt), .XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XDenormE,
                .XManE, .YManE, .ZManE, .XNaNE, .YNaNE, .ZNaNE, .XSNaNE, .YSNaNE, .ZSNaNE,
                .XZeroE, .YZeroE, .ZZeroE, .XInfE, .YInfE, .ZInfE,
                .XExpMaxE, .ZDenormE);
endmodule

















module readvectors (
  input logic clk,
  input logic [`FLEN*4+7:0] TestVector,
  input logic [`FMTBITS-1:0] ModFmt,
  input logic [1:0] Fmt,
  input logic [2:0] Unit,
  input logic [31:0] VectorNum,
  input logic [31:0] TestNum,
  input logic [2:0] OpCtrl,
  output logic [`FLEN-1:0] Ans,
  output logic [`XLEN-1:0] SrcA,
  output logic [4:0] AnsFlg,
  output logic                    XSgnE, YSgnE, ZSgnE,    // sign bits of XYZ
  output logic [`NE-1:0]          XExpE, YExpE, ZExpE,    // exponents of XYZ (converted to largest supported precision)
  output logic [`NF:0]            XManE, YManE, ZManE,    // mantissas of XYZ (converted to largest supported precision)
  output logic                    XNaNE, YNaNE, ZNaNE,    // is XYZ a NaN
  output logic                    XSNaNE, YSNaNE, ZSNaNE, // is XYZ a signaling NaN
  output logic                    XDenormE, ZDenormE,   // is XYZ denormalized
  output logic                    XZeroE, YZeroE, ZZeroE,         // is XYZ zero
  output logic                    XInfE, YInfE, ZInfE,            // is XYZ infinity
  output logic XExpMaxE,
  output logic [`FLEN-1:0] X, Y, Z
);

  // apply test vectors on rising edge of clk
  // Format of vectors Inputs(1/2/3)_AnsFlg
  always @(posedge clk) begin
    #1; 
    AnsFlg = TestVector[4:0];
    case (Unit)
      `FMAUNIT:
        case (Fmt)
          2'b11: begin       // quad
            X = TestVector[8+3*(`Q_LEN)-1:8+2*(`Q_LEN)];
            if(OpCtrl === `MUL_OPCTRL) Y = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)]; else Y = {2'b0, {`Q_NE-1{1'b1}}, `Q_NF'h0};
            if(OpCtrl === `MUL_OPCTRL) Z = 0; else Z = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)];
            Ans = TestVector[8+(`Q_LEN-1):8];
          end
          2'b01:	begin	  // double
            X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+3*(`D_LEN)-1:8+2*(`D_LEN)]};
            if(OpCtrl === `MUL_OPCTRL) Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]}; 
            else Y = {{`FLEN-`D_LEN{1'b1}}, 2'b0, {`D_NE-1{1'b1}}, `D_NF'h0};
            if(OpCtrl === `MUL_OPCTRL) Z = {{`FLEN-`D_LEN{1'b1}}, {`D_LEN{1'b0}}}; 
            else Z = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]};
            Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
          end
          2'b00:	begin	  // single
            X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+3*(`S_LEN)-1:8+2*(`S_LEN)]};
            if(OpCtrl === `MUL_OPCTRL) Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+(`S_LEN)]}; 
            else Y = {{`FLEN-`S_LEN{1'b1}}, 2'b0, {`S_NE-1{1'b1}}, `S_NF'h0};
            if(OpCtrl === `MUL_OPCTRL) Z = {{`FLEN-`S_LEN{1'b1}}, {`S_LEN{1'b0}}}; 
            else Z = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+(`S_LEN)]};
            Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
          end
          2'b10:	begin	  // half
            X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+3*(`H_LEN)-1:8+2*(`H_LEN)]};
            if(OpCtrl === `MUL_OPCTRL) Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]}; 
            else Y = {{`FLEN-`H_LEN{1'b1}}, 2'b0, {`H_NE-1{1'b1}}, `H_NF'h0};
            if(OpCtrl === `MUL_OPCTRL) Z = {{`FLEN-`H_LEN{1'b1}}, {`H_LEN{1'b0}}}; 
            else Z = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]};
            Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
          end
        endcase
      `DIVUNIT:
        case (Fmt)
          2'b11: begin       // quad
            X = TestVector[8+3*(`Q_LEN)-1:8+2*(`Q_LEN)];
            Y = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)];
            Ans = TestVector[8+(`Q_LEN-1):8];
          end
          2'b01:	begin	  // double
            X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+3*(`D_LEN)-1:8+2*(`D_LEN)]};
            Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]};
            Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
          end
          2'b00:	begin	  // single
            X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+3*(`S_LEN)-1:8+2*(`S_LEN)]};
            Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+1*(`S_LEN)]};
            Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
          end
          2'b10:	begin	  // half
            X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+3*(`H_LEN)-1:8+2*(`H_LEN)]};
            Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]};
            Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
          end
        endcase
      `CMPUNIT:
        case (Fmt)        
          2'b11: begin       // quad
            X = TestVector[12+2*(`Q_LEN)-1:12+(`Q_LEN)];
            Y = TestVector[12+(`Q_LEN)-1:12];
            Ans = TestVector[8];
          end
          2'b01:	begin	  // double
            X = {{`FLEN-`D_LEN{1'b1}}, TestVector[12+2*(`D_LEN)-1:12+(`D_LEN)]};
            Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[12+(`D_LEN)-1:12]};
            Ans = TestVector[8];
          end
          2'b00:	begin	  // single
            X = {{`FLEN-`S_LEN{1'b1}}, TestVector[12+2*(`S_LEN)-1:12+(`S_LEN)]};
            Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[12+(`S_LEN)-1:12]};
            Ans = TestVector[8];
          end
          2'b10:	begin	  // half
            X = {{`FLEN-`H_LEN{1'b1}}, TestVector[12+2*(`H_LEN)-1:12+(`H_LEN)]};
            Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[12+(`H_LEN)-1:12]};
            Ans = TestVector[8];
          end
        endcase
      `CVTFPUNIT:
        case (Fmt)
          2'b11: begin       // quad
          case (OpCtrl[1:0])
            2'b11: begin       // quad
              X = {{`FLEN-`Q_LEN{1'b1}}, TestVector[8+`Q_LEN+`Q_LEN-1:8+(`Q_LEN)]};
              Ans = TestVector[8+(`Q_LEN-1):8];
            end
            2'b01:	begin	  // double
              X = {{`FLEN-`Q_LEN{1'b1}}, TestVector[8+`Q_LEN+`D_LEN-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
            end
            2'b00:	begin	  // single
              X = {{`FLEN-`Q_LEN{1'b1}}, TestVector[8+`Q_LEN+`S_LEN-1:8+(`S_LEN)]};
              Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
            end
            2'b10:	begin	  // half
              X = {{`FLEN-`Q_LEN{1'b1}}, TestVector[8+`Q_LEN+`H_LEN-1:8+(`H_LEN)]};
              Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
            end
          endcase
          end
          2'b01:	begin	  // double
          case (OpCtrl[1:0])
            2'b11: begin       // quad
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+`D_LEN+`Q_LEN-1:8+(`Q_LEN)]};
              Ans = TestVector[8+(`Q_LEN-1):8];
            end
            2'b01:	begin	  // double
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+`D_LEN+`D_LEN-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
            end
            2'b00:	begin	  // single
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+`D_LEN+`S_LEN-1:8+(`S_LEN)]};
              Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
            end
            2'b10:	begin	  // half
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+`D_LEN+`H_LEN-1:8+(`H_LEN)]};
              Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
            end
          endcase
          end
          2'b00:	begin	  // single
          case (OpCtrl[1:0])
            2'b11: begin       // quad
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+`S_LEN+`Q_LEN-1:8+(`Q_LEN)]};
              Ans = TestVector[8+(`Q_LEN-1):8];
            end
            2'b01:	begin	  // double
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+`S_LEN+`D_LEN-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
            end
            2'b00:	begin	  // single
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+`S_LEN+`S_LEN-1:8+(`S_LEN)]};
              Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
            end
            2'b10:	begin	  // half
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+`S_LEN+`H_LEN-1:8+(`H_LEN)]};
              Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
            end
          endcase
          end
          2'b10:	begin	  // half
          case (OpCtrl[1:0])
            2'b11: begin       // quad
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+`H_LEN+`Q_LEN-1:8+(`Q_LEN)]};
              Ans = TestVector[8+(`Q_LEN-1):8];
            end
            2'b01:	begin	  // double
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+`H_LEN+`D_LEN-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
            end
            2'b00:	begin	  // single
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+`H_LEN+`S_LEN-1:8+(`S_LEN)]};
              Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
            end
            2'b10:	begin	  // half
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+`H_LEN+`H_LEN-1:8+(`H_LEN)]};
              Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
            end
          endcase
          end
        endcase
        
      `CVTINTUNIT:
        case (Fmt)
          2'b11: begin       // quad
            //     {is the integer a long,     is the opperation to an integer}
            casex ({OpCtrl[2:1]})
              2'b11: begin       // long -> quad
                X = {`FLEN{1'bx}};
                SrcA = TestVector[8+`Q_LEN+`XLEN-1:8+(`Q_LEN)];
                Ans = TestVector[8+(`Q_LEN-1):8];
              end
              2'b10:	begin	  // int -> quad
                // correctly sign extend the integer depending on if it's a signed/unsigned test
                X = {`FLEN{1'bx}};
                SrcA = {{`XLEN-32{TestVector[8+`Q_LEN+32-1]}}, TestVector[8+`Q_LEN+32-1:8+(`Q_LEN)]};
                Ans = TestVector[8+(`Q_LEN-1):8];
              end
              2'b01:	begin	  // quad -> long
                X = {{`FLEN-`Q_LEN{1'b1}}, TestVector[8+`XLEN+`Q_LEN-1:8+(`XLEN)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {TestVector[8+(`XLEN-1):8]};
              end
              2'b00:	begin	  // quad -> int
                X = {{`FLEN-`Q_LEN{1'b1}}, TestVector[8+32+`Q_LEN-1:8+(32)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {{`XLEN-32{TestVector[8+32-1]}},TestVector[8+(32-1):8]};
              end
            endcase
          end
          2'b01:	begin	  // double
            //     {Int->Fp?, is the integer a long}
            casex ({OpCtrl[2:1]})
              2'b11: begin       // long -> double
                X = {`FLEN{1'bx}};
                SrcA = TestVector[8+`D_LEN+`XLEN-1:8+(`D_LEN)];
                Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
              end
              2'b10:	begin	  // int -> double
                // correctly sign extend the integer depending on if it's a signed/unsigned test
                X = {`FLEN{1'bx}};
                SrcA = {{`XLEN-32{TestVector[8+`D_LEN+32-1]}}, TestVector[8+`D_LEN+32-1:8+(`D_LEN)]};
                Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
              end
              2'b01:	begin	  // double -> long
                X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+`XLEN+`D_LEN-1:8+(`XLEN)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {TestVector[8+(`XLEN-1):8]};
              end
              2'b00:	begin	  // double -> int
                X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+32+`D_LEN-1:8+(32)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {{`XLEN-32{TestVector[8+32-1]}},TestVector[8+(32-1):8]};
              end
            endcase
          end
          2'b00:	begin	  // single
            //     {is the integer a long,     is the opperation to an integer}
            casex ({OpCtrl[2:1]})
              2'b11: begin       // long -> single
                X = {`FLEN{1'bx}};
                SrcA = TestVector[8+`S_LEN+`XLEN-1:8+(`S_LEN)];
                Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
              end
              2'b10:	begin	  // int -> single
                // correctly sign extend the integer depending on if it's a signed/unsigned test
                X = {`FLEN{1'bx}};
                SrcA = {{`XLEN-32{TestVector[8+`S_LEN+32-1]}}, TestVector[8+`S_LEN+32-1:8+(`S_LEN)]};
                Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
              end
              2'b01:	begin	  // single -> long
                X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+`XLEN+`S_LEN-1:8+(`XLEN)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {TestVector[8+(`XLEN-1):8]};
              end
              2'b00:	begin	  // single -> int
                X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+32+`S_LEN-1:8+(32)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {{`XLEN-32{TestVector[8+32-1]}},TestVector[8+(32-1):8]};
              end
            endcase
          end
          2'b10:	begin	  // half
            //     {is the integer a long,     is the opperation to an integer}
            casex ({OpCtrl[2:1]})
              2'b11: begin       // long -> half
                X = {`FLEN{1'bx}};
                SrcA = TestVector[8+`H_LEN+`XLEN-1:8+(`H_LEN)];
                Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
              end
              2'b10:	begin	  // int -> half
                // correctly sign extend the integer depending on if it's a signed/unsigned test
                X = {`FLEN{1'bx}};
                SrcA = {{`XLEN-32{TestVector[8+`H_LEN+32-1]}}, TestVector[8+`H_LEN+32-1:8+(`H_LEN)]};
                Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
              end
              2'b01:	begin	  // half -> long
                X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+`XLEN+`H_LEN-1:8+(`XLEN)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {TestVector[8+(`XLEN-1):8]};
              end
              2'b00:	begin	  // half -> int
                X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+32+`H_LEN-1:8+(32)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {{`XLEN-32{TestVector[8+32-1]}}, TestVector[8+(32-1):8]};
              end
            endcase
          end
        endcase
    endcase  
  end
  
  unpack unpack(.X, .Y, .Z, .FmtE(ModFmt), .XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE,
                .XManE, .YManE, .ZManE, .XNaNE, .YNaNE, .ZNaNE, .XSNaNE, .YSNaNE, .ZSNaNE,
                .XDenormE, .ZDenormE, .XZeroE, .YZeroE, .ZZeroE, .XInfE, .YInfE, .ZInfE,
                .XExpMaxE);
endmodule