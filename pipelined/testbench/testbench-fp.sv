
`include "wally-config.vh"
`include "tests-fp.vh"

// steps to run FMA Tests
//    1) create test vectors in riscv-wally/Tests/fp with: ./run-all.sh
//    2) go to riscv-wally/pipelined/testbench/fp/Tests
//    3) run ./sim-fma-batch
module testbenchfp;
  parameter TEST="none";

  string      Tests[];        // list of tests to be run
  logic [2:0] OpCtrl[];       // list of op controls
  logic [2:0] Unit[];         // list of units being tested
  logic WriteInt[];           // Is being written to integer resgiter
  logic [2:0] Frm[4:0] = {3'b100, 3'b010, 3'b011, 3'b001, 3'b000}; // rounding modes: rne-000, rz-001, ru-011, rd-010, rnm-100
  logic [1:0] Fmt[];          // list of formats for the other units
  

  logic               clk=0;
  logic [31:0]        TestNum=0;    // index for the test
  logic [31:0]        OpCtrlNum=0;  // index for OpCtrl
  logic [31:0]        errors=0;     // how many errors
  logic [31:0]        VectorNum=0;  // index for test vector
  logic [31:0]        FrmNum=0;     // index for rounding mode
  logic [`FLEN*4+7:0] TestVectors[6133248:0];     // list of test vectors

  logic [1:0]           FmtVal;          // value of the current Fmt
  logic [2:0]           UnitVal, OpCtrlVal, FrmVal; // vlaue of the currnet Unit/OpCtrl/FrmVal
  logic                 WriteIntVal;                // value of the current WriteInt
  logic [`FLEN-1:0]     X, Y, Z;                    // inputs read from TestFloat
  logic [`XLEN-1:0]     SrcA;                       // integer input
  logic [`FLEN-1:0]	    Ans;                        // correct answer from TestFloat
  logic [`FLEN-1:0]	    Res;                                                // result from other units
  logic [4:0]	 	        AnsFlg;                                             // correct flags read from testfloat
  logic [4:0]	 	        ResFlg, Flg;                                                            // Result flags
  logic	[`FMTBITS-1:0]  ModFmt;  // format - 10 = half, 00 = single, 01 = double, 11 = quad
  logic [`FLEN-1:0]     FpRes, FpCmpRes;  // Results from each unit
  logic [`XLEN-1:0]     IntRes, CmpRes;  // Results from each unit
  logic [4:0]           FmaFlg, CvtFlg, DivFlg, CmpFlg;  // Outputed flags
  logic                 AnsNaN, ResNaN, NaNGood;
  logic                 XSgn, YSgn, ZSgn;                     // sign of the inputs
  logic [`NE-1:0]       XExp, YExp, ZExp;                     // exponent of the inputs
  logic [`NF:0]         XMan, YMan, ZMan;                     // mantissas of the inputs
  logic                 XNaN, YNaN, ZNaN;                     // is the input NaN
  logic                 XSNaN, YSNaN, ZSNaN;                  // is the input a signaling NaN
  logic                 XDenorm, ZDenorm;            // is the input denormalized
  logic                 XInf, YInf, ZInf;                   // is the input infinity
  logic                 XZero, YZero, ZZero;                // is the input zero
  logic                 XExpMax, YExpMax, ZExpMax;         // is the input's exponent all ones  
  logic  [`CVTLEN-1:0]      CvtLzcInE;      // input to the Leading Zero Counter (priority encoder)
  logic        IntZeroE;
  logic CvtResSgnE;
  logic [`NE:0]           CvtCalcExpE;    // the calculated expoent
	logic [`LOGCVTLEN-1:0] CvtShiftAmtE;  // how much to shift by
  logic CvtResDenormUfE;
  logic DivStart, DivDone;
  

  // in-between FMA signals
  logic                 Mult;
  logic [`NE+1:0]	      ProdExpE;
  logic 				        AddendStickyE;
  logic 					      KillProdE; 
  logic [$clog2(3*`NF+7)-1:0]	FmaNormCntE;
  logic [3*`NF+5:0]	    SumE;       
  logic 			          InvZE;
  logic 			          NegSumE;
  logic 			          ZSgnEffE;
  logic 			          PSgnE;
  logic       DivSgn;
  logic [`DIVLEN-1:0] Quot;
  logic [`NE-1:0] DivExp;


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
      // if (TEST === "sqrt"  | TEST === "all") begin // if square-root is being tested
      //   // add the square-root tests/op-ctrls/unit/fmt
      //   Tests = {Tests, f128sqrt};
      //   OpCtrl = {OpCtrl, `SQRT_OPCTRL};
      //   WriteInt = {WriteInt, 1'b0};
      //     for(int i = 0; i<5; i++) begin
      //       Unit = {Unit, `DIVUNIT};
      //       Fmt = {Fmt, 2'b11};
      //     end
      // end
      if (TEST === "fma"   | TEST === "all") begin  // if fused-mutliply-add is being tested
        Tests = {Tests, f128fma};
        OpCtrl = {OpCtrl, `FMA_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b11};
        end
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
      // if (TEST === "sqrt"  | TEST === "all") begin // if square-root is being tessted
      //   // add the correct tests/op-ctrls/unit/fmt to their lists
      //   Tests = {Tests, f64sqrt};
      //   OpCtrl = {OpCtrl, `SQRT_OPCTRL};
      //   WriteInt = {WriteInt, 1'b0};
      //   for(int i = 0; i<5; i++) begin
      //     Unit = {Unit, `DIVUNIT};
      //     Fmt = {Fmt, 2'b01};
      //   end
      // end
      if (TEST === "fma"   | TEST === "all") begin // if the fused multiply add is being tested
        Tests = {Tests, f64fma};
        OpCtrl = {OpCtrl, `FMA_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b01};
        end
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
      // if (TEST === "sqrt"  | TEST === "all") begin // if sqrt is being tested
      //   // add the correct tests/op-ctrls/unit/fmt to their lists
      //   Tests = {Tests, f32sqrt};
      //   OpCtrl = {OpCtrl, `SQRT_OPCTRL};
      //   WriteInt = {WriteInt, 1'b0};
      //   for(int i = 0; i<5; i++) begin
      //     Unit = {Unit, `DIVUNIT};
      //     Fmt = {Fmt, 2'b00};
      //   end
      // end
      if (TEST === "fma"   | TEST === "all")  begin // if fma is being tested
        Tests = {Tests, f32fma};
        OpCtrl = {OpCtrl, `FMA_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b00};
        end
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
      // if (TEST === "sqrt"  | TEST === "all") begin // if sqrt is being tested
      //   // add the correct tests/op-ctrls/unit/fmt to their lists
      //   Tests = {Tests, f16sqrt};
      //   OpCtrl = {OpCtrl, `SQRT_OPCTRL};
      //   WriteInt = {WriteInt, 1'b0};
      //   for(int i = 0; i<5; i++) begin
      //     Unit = {Unit, `DIVUNIT};
      //     Fmt = {Fmt, 2'b10};
      //   end
      // end
      if (TEST === "fma"   | TEST === "all") begin // if fma is being tested
        Tests = {Tests, f16fma};
        OpCtrl = {OpCtrl, `FMA_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `FMAUNIT};
          Fmt = {Fmt, 2'b10};
        end
      end
    end

    // check if nothing is being tested
    if (Tests.size() == 0) begin
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
    // set the test index to 0
    TestNum = 0;
  end

  // set a the signals for all tests
  always_comb UnitVal = Unit[TestNum];
  always_comb FmtVal = Fmt[TestNum];
  always_comb OpCtrlVal = OpCtrl[OpCtrlNum];
  always_comb WriteIntVal = WriteInt[OpCtrlNum];
  always_comb FrmVal = Frm[FrmNum];

  // modify the format signal if only 2 percisions supported
  //    - 1 for the larger precision
  //    - 0 for the smaller precision
  always_comb begin
    if(`FMTBITS == 1) ModFmt = FmtVal == `FMT;
    else ModFmt = FmtVal;
  end

  // extract the inputs (X, Y, Z, SrcA) and the output (Ans, AnsFlg) from the current test vector
  readvectors readvectors          (.clk, .Fmt(FmtVal), .ModFmt, .TestVector(TestVectors[VectorNum]), .VectorNum, .Ans(Ans), .AnsFlg(AnsFlg), .SrcA, 
                                    .XSgnE(XSgn), .YSgnE(YSgn), .ZSgnE(ZSgn), .Unit (UnitVal),
                                    .XExpE(XExp), .YExpE(YExp), .ZExpE(ZExp), .TestNum, .OpCtrl(OpCtrlVal),
                                    .XManE(XMan), .YManE(YMan), .ZManE(ZMan), .DivStart,
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
  fma fma(.XSgnE(XSgn), .YSgnE(YSgn), .ZSgnE(ZSgn), 
              .XExpE(XExp), .YExpE(YExp), .ZExpE(ZExp), 
              .XManE(XMan), .YManE(YMan), .ZManE(ZMan),
              .XZeroE(XZero), .YZeroE(YZero), .ZZeroE(ZZero),
              .FOpCtrlE(OpCtrlVal), .FmtE(ModFmt), .SumE, .NegSumE, .InvZE, .FmaNormCntE, .ZSgnEffE, .PSgnE,
              .ProdExpE, .AddendStickyE, .KillProdE); 
              
  postprocess postprocess(.XSgnM(XSgn), .YSgnM(YSgn), .PostProcSelM(UnitVal[1:0]),
              .ZExpM(ZExp),  .ZDenormM(ZDenorm), .FOpCtrlM(OpCtrlVal), .Quot,
              .XManM(XMan), .YManM(YMan), .ZManM(ZMan), .CvtCalcExpM(CvtCalcExpE),
              .XNaNM(XNaN), .YNaNM(YNaN), .ZNaNM(ZNaN), .CvtResDenormUfM(CvtResDenormUfE),
              .XZeroM(XZero), .YZeroM(YZero), .ZZeroM(ZZero), .CvtShiftAmtM(CvtShiftAmtE),
              .XInfM(XInf), .YInfM(YInf), .ZInfM(ZInf), .CvtResSgnM(CvtResSgnE), .FWriteIntM(WriteIntVal),
              .XSNaNM(XSNaN), .YSNaNM(YSNaN), .ZSNaNM(ZSNaN), .CvtLzcInM(CvtLzcInE), .IntZeroM(IntZeroE),
              .KillProdM(KillProdE), .AddendStickyM(AddendStickyE), .ProdExpM(ProdExpE), 
              .SumM(SumE), .NegSumM(NegSumE), .InvZM(InvZE), .FmaNormCntM(FmaNormCntE), .ZSgnEffM(ZSgnEffE), .PSgnM(PSgnE), .FmtM(ModFmt), .FrmM(FrmVal), 
              .PostProcFlgM(Flg), .PostProcResM(FpRes), .FCvtIntResM(IntRes));
  
  fcvt fcvt (.XSgnE(XSgn), .XExpE(XExp), .XManE(XMan), .ForwardedSrcAE(SrcA), .FWriteIntE(WriteIntVal), 
            .XZeroE(XZero), .XDenormE(XDenorm), .FOpCtrlE(OpCtrlVal), .IntZeroE,
            .FmtE(ModFmt), .CvtCalcExpE, .CvtShiftAmtE, .CvtResDenormUfE, .CvtResSgnE, .CvtLzcInE);
  fcmp fcmp   (.FmtE(ModFmt), .FOpCtrlE(OpCtrlVal), .XSgnE(XSgn), .YSgnE(YSgn), .XExpE(XExp), .YExpE(YExp), 
              .XManE(XMan), .YManE(YMan), .XZeroE(XZero), .YZeroE(YZero), .CmpIntResE(CmpRes),
              .XNaNE(XNaN), .YNaNE(YNaN), .XSNaNE(XSNaN), .YSNaNE(YSNaN), .FSrcXE(X), .FSrcYE(Y), .CmpNVE(CmpFlg[4]), .CmpFpResE(FpCmpRes));
  srtradix4 srtradix4(.clk, .DivStart, .XExpE(XExp), .YExpE(YExp), .DivExp,
                .XFrac(XMan[`NF-1:0]), .YFrac(YMan[`NF-1:0]), .SrcA('0), .SrcB('0), .W64(1'b0), .Signed(1'b0), .Int(1'b0), .Sqrt(OpCtrlVal[0]), 
                .DivDone, .Quot, .Rem());
                
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
      `FMAUNIT: Res = FpRes;
      `DIVUNIT: Res = FpRes;
      `CMPUNIT: Res = CmpRes;
      `CVTINTUNIT: if(WriteIntVal) Res = IntRes; else Res = FpRes;
      `CVTFPUNIT: Res = FpRes;
    endcase

    // select the flag to check
    case (UnitVal)
      `FMAUNIT: ResFlg = Flg;
      `DIVUNIT: ResFlg = Flg;
      `CMPUNIT: ResFlg = CmpFlg;
      `CVTINTUNIT: ResFlg = Flg;
      `CVTFPUNIT: ResFlg = Flg;
    endcase
end
  // check results on falling edge of clk
  always @(negedge clk) begin


    // check if the NaN value is good. IEEE754-2019 sections 6.3 and 6.2.3 specify:
    //    - the sign of the NaN does not matter for the opperations being tested
    //    - when 2 or more NaNs are inputed the NaN that is propigated doesn't matter
    if (UnitVal !== `CVTFPUNIT & UnitVal !== `CVTINTUNIT)
      case (FmtVal)
        4'b11: NaNGood =  (((`IEEE754==0)&AnsNaN&(Res === {1'b0, {`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                          (XNaN&(Res[`Q_LEN-2:0] === {X[`Q_LEN-2:`Q_NF],1'b1,X[`Q_NF-2:0]})) | 
                          (YNaN&(Res[`Q_LEN-2:0] === {Y[`Q_LEN-2:`Q_NF],1'b1,Y[`Q_NF-2:0]})) |
                          (ZNaN&(Res[`Q_LEN-2:0] === {Z[`Q_LEN-2:`Q_NF],1'b1,Z[`Q_NF-2:0]})));
        4'b01: NaNGood =  (((`IEEE754==0)&AnsNaN&(Res[`D_LEN-1:0] === {1'b0, {`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                          (XNaN&(Res[`D_LEN-2:0] === {X[`D_LEN-2:`D_NF],1'b1,X[`D_NF-2:0]})) | 
                          (YNaN&(Res[`D_LEN-2:0] === {Y[`D_LEN-2:`D_NF],1'b1,Y[`D_NF-2:0]})) |
                          (ZNaN&(Res[`D_LEN-2:0] === {Z[`D_LEN-2:`D_NF],1'b1,Z[`D_NF-2:0]})));
        4'b00: NaNGood =  (((`IEEE754==0)&AnsNaN&(Res[`S_LEN-1:0] === {1'b0, {`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                          (XNaN&(Res[`S_LEN-2:0] === {X[`S_LEN-2:`S_NF],1'b1,X[`S_NF-2:0]})) | 
                          (YNaN&(Res[`S_LEN-2:0] === {Y[`S_LEN-2:`S_NF],1'b1,Y[`S_NF-2:0]})) |
                          (ZNaN&(Res[`S_LEN-2:0] === {Z[`S_LEN-2:`S_NF],1'b1,Z[`S_NF-2:0]})));
        4'b10: NaNGood =  (((`IEEE754==0)&AnsNaN&(Res[`H_LEN-1:0] === {1'b0, {`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                          (XNaN&(Res[`H_LEN-2:0] === {X[`H_LEN-2:`H_NF],1'b1,X[`H_NF-2:0]})) | 
                          (YNaN&(Res[`H_LEN-2:0] === {Y[`H_LEN-2:`H_NF],1'b1,Y[`H_NF-2:0]})) |
                          (ZNaN&(Res[`H_LEN-2:0] === {Z[`H_LEN-2:`H_NF],1'b1,Z[`H_NF-2:0]})));
      endcase
    else if (UnitVal === `CVTFPUNIT) // if converting from floating point to floating point OpCtrl contains the final FP format
      case (OpCtrlVal[1:0]) 
        2'b11: NaNGood = (((`IEEE754==0)&AnsNaN&(Res === {1'b0, {`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`Q_LEN-2:0] === {{`Q_NE+1{1'b1}}, {`Q_NF-1{1'b0}}})) |
                          (AnsNaN&(Res[`Q_LEN-2:0] === Ans[`Q_LEN-2:0])) | 
                          (XNaN&(Res[`Q_LEN-2:0] === {X[`Q_LEN-2:`Q_NF],1'b1,X[`Q_NF-2:0]})) | 
                          (YNaN&(Res[`Q_LEN-2:0] === {Y[`Q_LEN-2:`Q_NF],1'b1,Y[`Q_NF-2:0]})));
        2'b01: NaNGood = (((`IEEE754==0)&AnsNaN&(Res[`D_LEN-1:0] === {1'b0, {`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`D_LEN-2:0] === {{`D_NE+1{1'b1}}, {`D_NF-1{1'b0}}})) |
                          (AnsNaN&(Res[`D_LEN-2:0] === Ans[`D_LEN-2:0])) | 
                          (XNaN&(Res[`D_LEN-2:0] === {X[`D_LEN-2:`D_NF],1'b1,X[`D_NF-2:0]})) | 
                          (YNaN&(Res[`D_LEN-2:0] === {Y[`D_LEN-2:`D_NF],1'b1,Y[`D_NF-2:0]})));
        2'b00: NaNGood = (((`IEEE754==0)&AnsNaN&(Res[`S_LEN-1:0] === {1'b0, {`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`S_LEN-2:0] === {{`S_NE+1{1'b1}}, {`S_NF-1{1'b0}}})) |
                          (AnsNaN&(Res[`S_LEN-2:0] === Ans[`S_LEN-2:0])) | 
                          (XNaN&(Res[`S_LEN-2:0] === {X[`S_LEN-2:`S_NF],1'b1,X[`S_NF-2:0]})) | 
                          (YNaN&(Res[`S_LEN-2:0] === {Y[`S_LEN-2:`S_NF],1'b1,Y[`S_NF-2:0]})));
        2'b10: NaNGood = (((`IEEE754==0)&AnsNaN&(Res[`H_LEN-1:0] === {1'b0, {`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
                          (AnsFlg[4]&(Res[`H_LEN-2:0] === {{`H_NE+1{1'b1}}, {`H_NF-1{1'b0}}})) |
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
    if(~((Res === Ans | NaNGood | NaNGood === 1'bx) & (ResFlg === AnsFlg | AnsFlg === 5'bx))&(DivDone&(UnitVal == `DIVUNIT))&(UnitVal !== `CVTINTUNIT)&(UnitVal !== `CMPUNIT)) begin
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
            (~(WriteIntVal&~OpCtrlVal[0]&AnsFlg[4]&XSgn&~XNaN)&(Res === Ans | NaNGood | NaNGood === 1'bx))) & (ResFlg === AnsFlg | AnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in %s", Tests[TestNum]);
      $display("inputs: %h %h %h\nSrcA: %h\n Res: %h %h\n Ans: %h %h", X, Y, Z, SrcA, Res, ResFlg, Ans, AnsFlg);
      $stop;
    end

    if(DivDone|(UnitVal != `DIVUNIT)) VectorNum += 1; // increment the vector

    if (TestVectors[VectorNum][0] === 1'bx & Tests[TestNum] !== "") begin // if reached the end of file

      // increment the test
      TestNum += 1;

      // clear the vectors
      for(int i=0; i<6133248; i++) TestVectors[i] = {`FLEN*4+8{1'bx}};
      // read next files
      $readmemh({`PATH, Tests[TestNum]}, TestVectors);

      // set the vector index back to 0
      VectorNum = 0;
      // incemet the operation if all the rounding modes have been tested
      if(FrmNum === 4) OpCtrlNum += 1;
      // increment the rounding mode or loop back to rne 
      if(FrmNum < 4) FrmNum += 1;
      else FrmNum = 0; 

      // if no more Tests - finish
      if(Tests[TestNum] === "") begin
        $display("\nAll Tests completed with %d errors\n", errors);
        $stop;
      end 

      $display("Running %s vectors", Tests[TestNum]);
    end
  end
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
  output logic                    XExpMaxE,
  output logic                    DivStart,
  output logic [`FLEN-1:0] X, Y, Z
);

  // apply test vectors on rising edge of clk
  // Format of vectors Inputs(1/2/3)_AnsFlg
  always @(TestNum) begin
    #1; 
    AnsFlg = TestVector[4:0];
    DivStart = 1'b0;
    case (Unit)
      `FMAUNIT:
        case (Fmt)
          2'b11: begin       // quad
            if(OpCtrl === `FMA_OPCTRL) begin
              X = TestVector[8+4*(`Q_LEN)-1:8+3*(`Q_LEN)];
              Y = TestVector[8+3*(`Q_LEN)-1:8+2*(`Q_LEN)];
              Z = TestVector[8+2*(`Q_LEN)-1:8+`Q_LEN];
            end
            else begin
              X = TestVector[8+3*(`Q_LEN)-1:8+2*(`Q_LEN)];
              if(OpCtrl === `MUL_OPCTRL) Y = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)]; else Y = {2'b0, {`Q_NE-1{1'b1}}, (`Q_NF)'(0)};
              if(OpCtrl === `MUL_OPCTRL) Z = 0; else Z = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)];
            end
            Ans = TestVector[8+(`Q_LEN-1):8];
          end
          2'b01:	begin	  // double
            if(OpCtrl === `FMA_OPCTRL) begin
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+4*(`D_LEN)-1:8+3*(`D_LEN)]};
              Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+3*(`D_LEN)-1:8+2*(`D_LEN)]};
              Z = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+`D_LEN]};
            end
            else begin
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+3*(`D_LEN)-1:8+2*(`D_LEN)]};
              if(OpCtrl === `MUL_OPCTRL) Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]}; 
              else Y = {{`FLEN-`D_LEN{1'b1}}, 2'b0, {`D_NE-1{1'b1}}, (`D_NF)'(0)};
              if(OpCtrl === `MUL_OPCTRL) Z = {{`FLEN-`D_LEN{1'b1}}, {`D_LEN{1'b0}}}; 
              else Z = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]};
            end
            Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
          end
          2'b00:	begin	  // single
            if(OpCtrl === `FMA_OPCTRL) begin
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+4*(`S_LEN)-1:8+3*(`S_LEN)]};
              Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+3*(`S_LEN)-1:8+2*(`S_LEN)]};
              Z = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+`S_LEN]};
            end
            else begin
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+3*(`S_LEN)-1:8+2*(`S_LEN)]};
              if(OpCtrl === `MUL_OPCTRL) Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+(`S_LEN)]}; 
              else Y = {{`FLEN-`S_LEN{1'b1}}, 2'b0, {`S_NE-1{1'b1}}, (`S_NF)'(0)};
              if(OpCtrl === `MUL_OPCTRL) Z = {{`FLEN-`S_LEN{1'b1}}, {`S_LEN{1'b0}}}; 
              else Z = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+(`S_LEN)]};
            end
            Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
          end
          2'b10:	begin	  // half
            if(OpCtrl === `FMA_OPCTRL) begin
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+4*(`H_LEN)-1:8+3*(`H_LEN)]};
              Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+3*(`H_LEN)-1:8+2*(`H_LEN)]};
              Z = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+`H_LEN]};
            end
            else begin
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+3*(`H_LEN)-1:8+2*(`H_LEN)]};
              if(OpCtrl === `MUL_OPCTRL) Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]}; 
              else Y = {{`FLEN-`H_LEN{1'b1}}, 2'b0, {`H_NE-1{1'b1}}, (`H_NF)'(0)};
              if(OpCtrl === `MUL_OPCTRL) Z = {{`FLEN-`H_LEN{1'b1}}, {`H_LEN{1'b0}}}; 
              else Z = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]};
            end
            Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
          end
        endcase
      `DIVUNIT:
        case (Fmt)
          2'b11: begin       // quad
            X = TestVector[8+3*(`Q_LEN)-1:8+2*(`Q_LEN)];
            Y = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)];
            Ans = TestVector[8+(`Q_LEN-1):8];
            DivStart = 1'b1; #10 // one clk cycle
            DivStart = 1'b0;
          end
          2'b01:	begin	  // double
            X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+3*(`D_LEN)-1:8+2*(`D_LEN)]};
            Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]};
            Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
            DivStart = 1'b1; #10
            DivStart = 1'b0;
          end
          2'b00:	begin	  // single
            X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+3*(`S_LEN)-1:8+2*(`S_LEN)]};
            Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+1*(`S_LEN)]};
            Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
            DivStart = 1'b1; #10
            DivStart = 1'b0;
          end
          2'b10:	begin	  // half
            X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+3*(`H_LEN)-1:8+2*(`H_LEN)]};
            Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]};
            Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
            DivStart = 1'b1; #10
            DivStart = 1'b0;
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
              X = {TestVector[8+`Q_LEN+`Q_LEN-1:8+(`Q_LEN)]};
              Ans = TestVector[8+(`Q_LEN-1):8];
            end
            2'b01:	begin	  // double
              X = {TestVector[8+`Q_LEN+`D_LEN-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
            end
            2'b00:	begin	  // single
              X = {TestVector[8+`Q_LEN+`S_LEN-1:8+(`S_LEN)]};
              Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
            end
            2'b10:	begin	  // half
              X = {TestVector[8+`Q_LEN+`H_LEN-1:8+(`H_LEN)]};
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
                X = {TestVector[8+`XLEN+`Q_LEN-1:8+(`XLEN)]};
                SrcA = {`XLEN{1'bx}};
                Ans = {TestVector[8+(`XLEN-1):8]};
              end
              2'b00:	begin	  // quad -> int
                X = {TestVector[8+32+`Q_LEN-1:8+(32)]};
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