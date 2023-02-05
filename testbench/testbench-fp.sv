///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Testbench for Testfloat
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////
`include "wally-config.vh"
`include "tests-fp.vh"

// steps to run FMA Tests
//    1) create test vectors in riscv-wally/Tests/fp with: ./run-all.sh
//    2) go to cvw/testbench/fp/Tests
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
  logic [`FLEN*4+7:0] TestVectors[8388609:0];     // list of test vectors

  logic [1:0]           FmtVal;          // value of the current Fmt
  logic [2:0]           UnitVal, OpCtrlVal, FrmVal; // value of the currnet Unit/OpCtrl/FrmVal
  logic                 WriteIntVal;                // value of the current WriteInt
  logic [`FLEN-1:0]     X, Y, Z;                    // inputs read from TestFloat
  logic [`XLEN-1:0]     SrcA;                       // integer input
  logic [`FLEN-1:0]	    Ans;                        // correct answer from TestFloat
  logic [`FLEN-1:0]	    Res;                        // result from other units
  logic [4:0]	 	        AnsFlg;                     // correct flags read from testfloat
  logic [4:0]	 	        ResFlg, Flg;                // Result flags
  logic	[`FMTBITS-1:0]  ModFmt;                     // format - 10 = half, 00 = single, 01 = double, 11 = quad
  logic [`FLEN-1:0]     FpRes, FpCmpRes;            // Results from each unit
  logic [`XLEN-1:0]     IntRes, CmpRes;             // Results from each unit
  logic [4:0]           FmaFlg, CvtFlg, DivFlg, CmpFlg;  // Outputed flags
  logic                 AnsNaN, ResNaN, NaNGood;
  logic                 Xs, Ys, Zs;                 // sign of the inputs
  logic [`NE-1:0]       Xe, Ye, Ze;                 // exponent of the inputs
  logic [`NF:0]         Xm, Ym, Zm;                 // mantissas of the inputs
  logic                 XNaN, YNaN, ZNaN;           // is the input NaN
  logic                 XSNaN, YSNaN, ZSNaN;        // is the input a signaling NaN
  logic                 XSubnorm, ZSubnorm;           // is the input denormalized
  logic                 XInf, YInf, ZInf;           // is the input infinity
  logic                 XZero, YZero, ZZero;        // is the input zero
  logic                 XExpMax, YExpMax, ZExpMax;  // is the input's exponent all ones  
  logic  [`CVTLEN-1:0]  CvtLzcInE;                  // input to the Leading Zero Counter (priority encoder)
  logic                 IntZero;
  logic                 CvtResSgnE;
  logic [`NE:0]         CvtCalcExpE;    // the calculated expoent
	logic [`LOGCVTLEN-1:0] CvtShiftAmtE;  // how much to shift by
	logic [`DIVb:0]       Quot;
  logic                 CvtResSubnormUfE;
  logic                 DivStart, FDivBusyE, OldFDivBusyE;
  logic                 reset = 1'b0;
  logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt;
  logic [`DURLEN-1:0]   Dur;

  // in-between FMA signals
  logic                 Mult;
  logic                 Ss;
  logic [`NE+1:0]	      Pe;
  logic [`NE+1:0]	      Se;
  logic 				        ASticky;
  logic 					      KillProd; 
  logic [$clog2(3*`NF+5)-1:0]	SCnt;
  logic [3*`NF+3:0]	    Sm;       
  logic 			          InvA;
  logic 			          NegSum;
  logic 			          As;
  logic 			          Ps;
  logic                 DivSticky;
  logic                 DivDone;
  logic                 DivNegSticky;
  logic [`NE+1:0]       DivCalcExp;
  logic                 divsqrtop;


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
        Tests = {f16div, Tests};
        OpCtrl = {`DIV_OPCTRL, OpCtrl};
        WriteInt = {1'b0, WriteInt};
        for(int i = 0; i<5; i++) begin
          Unit = {`DIVUNIT, Unit};
          Fmt = {2'b10, Fmt};
        end
        /* Tests = {Tests, f16div};
        OpCtrl = {OpCtrl, `DIV_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b10};
        end */
      end
      if (TEST === "sqrt"  | TEST === "all") begin // if sqrt is being tested
        // add the correct tests/op-ctrls/unit/fmt to their lists
        // reverse order
        Tests = {f16sqrt, Tests};
        OpCtrl = {`SQRT_OPCTRL, OpCtrl};
        WriteInt = {1'b0, WriteInt};
        for(int i = 0; i<5; i++) begin
          Unit = {`DIVUNIT, Unit};
          Fmt = {2'b10, Fmt};
        end
/*        Tests = {Tests, f16sqrt};
        OpCtrl = {OpCtrl, `SQRT_OPCTRL};
        WriteInt = {WriteInt, 1'b0};
        for(int i = 0; i<5; i++) begin
          Unit = {Unit, `DIVUNIT};
          Fmt = {Fmt, 2'b10};
        end */
      end
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
                                    .Xs, .Ys, .Zs, .Unit(UnitVal),
                                    .Xe, .Ye, .Ze, .TestNum, .OpCtrl(OpCtrlVal),
                                    .Xm, .Ym, .Zm, .DivStart,
                                    .XNaN, .YNaN, .ZNaN,
                                    .XSNaN, .YSNaN, .ZSNaN, 
                                    .XSubnorm, .ZSubnorm, 
                                    .XZero, .YZero, .ZZero,
                                    .XInf, .YInf, .ZInf, .XExpMax,
                                    .X, .Y, .Z);



  ///////////////////////////////////////////////////////////////////////////////////////////////

  //     |||||||   |||   ||| ||||||||| 
  //     |||   ||| |||   |||    |||    
  //     |||   ||| |||   |||    |||    
  //     |||   ||| |||   |||    |||         
  //     |||||||   |||||||||    |||    

  ///////////////////////////////////////////////////////////////////////////////////////////////

  // instantiate devices under test
  if (TEST === "fma"| TEST === "mul" | TEST === "add" | TEST === "all") begin : fma
    fma fma(.Xs(Xs), .Ys(Ys), .Zs(Zs), 
            .Xe(Xe), .Ye(Ye), .Ze(Ze), 
            .Xm(Xm), .Ym(Ym), .Zm(Zm),
            .XZero, .YZero, .ZZero, .Ss, .Se,
            .OpCtrl(OpCtrlVal), .Sm, .InvA, .SCnt, .As, .Ps,
            .ASticky); 
  end
              
  postprocess postprocess(.Xs(Xs), .Ys(Ys), .PostProcSel(UnitVal[1:0]),
              .OpCtrl(OpCtrlVal), .DivQm(Quot), .DivQe(DivCalcExp),
              .Xm(Xm), .Ym(Ym), .Zm(Zm), .CvtCe(CvtCalcExpE), .DivSticky(DivSticky), .FmaSs(Ss),
              .XNaN(XNaN), .YNaN(YNaN), .ZNaN(ZNaN), .CvtResSubnormUf(CvtResSubnormUfE),
              .XZero(XZero), .YZero(YZero), .CvtShiftAmt(CvtShiftAmtE),
              .XInf(XInf), .YInf(YInf), .ZInf(ZInf), .CvtCs(CvtResSgnE), .ToInt(WriteIntVal),
              .XSNaN(XSNaN), .YSNaN(YSNaN), .ZSNaN(ZSNaN), .CvtLzcIn(CvtLzcInE), .IntZero,
              .FmaASticky(ASticky), .FmaSe(Se),
              .FmaSm(Sm), .FmaSCnt(SCnt), .FmaAs(As), .FmaPs(Ps), .Fmt(ModFmt), .Frm(FrmVal), 
              .PostProcFlg(Flg), .PostProcRes(FpRes), .FCvtIntRes(IntRes));
  
  if (TEST === "cvtfp" | TEST === "cvtint" | TEST === "all") begin : fcvt
    fcvt fcvt (.Xs(Xs), .Xe(Xe), .Xm(Xm), .Int(SrcA), .ToInt(WriteIntVal), 
              .XZero(XZero), .XSubnorm(XSubnorm), .OpCtrl(OpCtrlVal), .IntZero,
              .Fmt(ModFmt), .Ce(CvtCalcExpE), .ShiftAmt(CvtShiftAmtE), .ResSubnormUf(CvtResSubnormUfE), .Cs(CvtResSgnE), .LzcIn(CvtLzcInE));
  end

  if (TEST === "cmp" | TEST === "all") begin: fcmp
    fcmp fcmp   (.Fmt(ModFmt), .OpCtrl(OpCtrlVal), .Xs, .Ys, .Xe, .Ye, 
                .Xm, .Ym, .XZero, .YZero, .CmpIntRes(CmpRes),
                .XNaN, .YNaN, .XSNaN, .YSNaN, .X, .Y, .CmpNV(CmpFlg[4]), .CmpFpRes(FpCmpRes));
  end
  if (TEST === "div" | TEST === "sqrt" | TEST === "all") begin: fdivsqrt
    fdivsqrt fdivsqrt(.clk, .reset, .XsE(Xs), .FmtE(ModFmt), .XmE(Xm), .YmE(Ym), .XeE(Xe), .YeE(Ye), .SqrtE(OpCtrlVal[0]), .SqrtM(OpCtrlVal[0]),
                    .XInfE(XInf), .YInfE(YInf), .XZeroE(XZero), .YZeroE(YZero), .XNaNE(XNaN), .YNaNE(YNaN), 
                    .FDivStartE(DivStart), .IDivStartE(1'b0), .MDUE(1'b0), .W64E(1'b0),
                    .StallM(1'b0), .DivSM(DivSticky), .FDivBusyE, .QeM(DivCalcExp),
                    .QmM(Quot));
  end

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

  logic ResMatch, FlagMatch, CheckNow;

always @(posedge clk) 
  OldFDivBusyE = FDivBusyE;

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

    // check if result is correct
    //  - wait till the division result is done or one extra cylcle for early termination (to simulate the EM pipline stage)
   // if(~((Res === Ans | NaNGood | NaNGood === 1'bx) & (ResFlg === AnsFlg | AnsFlg === 5'bx))&~((FDivBusyE===1'b1)|DivStart)&(UnitVal !== `CVTINTUNIT)&(UnitVal !== `CMPUNIT)) begin
    ResMatch = (Res === Ans | NaNGood | NaNGood === 1'bx);
    FlagMatch = (ResFlg === AnsFlg | AnsFlg === 5'bx);
    divsqrtop = OpCtrlVal == `SQRT_OPCTRL | OpCtrlVal == `DIV_OPCTRL;
    assign DivDone = OldFDivBusyE & ~FDivBusyE;

    //assign divsqrtop = OpCtrl[TestNum] == `SQRT_OPCTRL | OpCtrl[TestNum] == `DIV_OPCTRL;
    CheckNow = (DivDone | ~divsqrtop) & (UnitVal !== `CVTINTUNIT)&(UnitVal !== `CMPUNIT);
    if(~(ResMatch & FlagMatch) & CheckNow) begin
//    if(~((Res === Ans | NaNGood | NaNGood === 1'bx) & (ResFlg === AnsFlg | AnsFlg === 5'bx))&(DivDone | (TEST != "sqrt" & TEST != "div"))&(UnitVal !== `CVTINTUNIT)&(UnitVal !== `CMPUNIT)) begin
      errors += 1;
      $display("TestNum %d OpCtrl %d", TestNum, OpCtrl[TestNum]);
      $display("Error in %s", Tests[TestNum]);
      $display("inputs: %h %h %h\nSrcA: %h\n Res: %h %h\n Expected: %h %h", X, Y, Z, SrcA, Res, ResFlg, Ans, AnsFlg);
      $stop;
    end
    
    // TestFloat sets the result to all 1's when there is an invalid result, however in 
    // http://www.jhauser.us/arithmetic/TestFloat-3/doc/TestFloat-general.html it says
    // for an unsigned integer result 0 is also okay

    // Testfloat outputs 800... for both the largest integer values for both positive and negitive numbers but 
    // the riscv spec specifies 2^31-1 for positive values out of range and NaNs ie 7fff...
    else if ((UnitVal === `CVTINTUNIT) & ~(((WriteIntVal&~OpCtrlVal[0]&AnsFlg[4]&Xs&(Res[`XLEN-1:0] === (`XLEN)'(0))) | 
            (WriteIntVal&OpCtrlVal[0]&AnsFlg[4]&(~Xs|XNaN)&OpCtrlVal[1]&(Res[`XLEN-1:0] === {1'b0, {`XLEN-1{1'b1}}})) | 
            (WriteIntVal&OpCtrlVal[0]&AnsFlg[4]&(~Xs|XNaN)&~OpCtrlVal[1]&(Res[`XLEN-1:0] === {{`XLEN-32{1'b0}}, 1'b0, {31{1'b1}}})) | 
            (~(WriteIntVal&~OpCtrlVal[0]&AnsFlg[4]&Xs&~XNaN)&(Res === Ans | NaNGood | NaNGood === 1'bx))) & (ResFlg === AnsFlg | AnsFlg === 5'bx))) begin
      errors += 1;
      $display("There is an error in %s", Tests[TestNum]);
      $display("inputs: %h %h %h\nSrcA: %h\n Res: %h %h\n Ans: %h %h", X, Y, Z, SrcA, Res, ResFlg, Ans, AnsFlg);
      $stop;
    end

    if(~(FDivBusyE|DivStart)|(UnitVal != `DIVUNIT)) VectorNum += 1; // increment the vector

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
  output logic                    Xs, Ys, Zs,    // sign bits of XYZ
  output logic [`NE-1:0]          Xe, Ye, Ze,    // exponents of XYZ (converted to largest supported precision)
  output logic [`NF:0]            Xm, Ym, Zm,    // mantissas of XYZ (converted to largest supported precision)
  output logic                    XNaN, YNaN, ZNaN,    // is XYZ a NaN
  output logic                    XSNaN, YSNaN, ZSNaN, // is XYZ a signaling NaN
  output logic                    XSubnorm, ZSubnorm,   // is XYZ denormalized
  output logic                    XZero, YZero, ZZero,         // is XYZ zero
  output logic                    XInf, YInf, ZInf,            // is XYZ infinity
  output logic                    XExpMax,
  output logic                    DivStart,
  output logic [`FLEN-1:0] X, Y, Z
);
  logic XEn, YEn, ZEn;

  // apply test vectors on rising edge of clk
  // Format of vectors Inputs(1/2/3)_AnsFlg
  always @(VectorNum) begin
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
          2'b01:	if (`D_SUPPORTED)begin	  // double
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
          2'b00:	if (`S_SUPPORTED)begin	  // single
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
        if(OpCtrl[0])
          case (Fmt)
            2'b11: begin       // quad
              X = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)];
              Ans = TestVector[8+(`Q_LEN-1):8];
              if (~clk) #5;
              DivStart = 1'b1; #10 // one clk cycle
              DivStart = 1'b0;
            end
            2'b01:	if (`D_SUPPORTED)begin	  // double
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
              if (~clk) #5;
              DivStart = 1'b1; #10
              DivStart = 1'b0;
            end
            2'b00:	if (`S_SUPPORTED)begin	  // single
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+1*(`S_LEN)]};
              Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
              if (~clk) #5;
              DivStart = 1'b1; #10
              DivStart = 1'b0;
            end
            2'b10:	begin	  // half
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]};
              Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
              if (~clk) #5;
              DivStart = 1'b1; #10
              DivStart = 1'b0;
            end
          endcase
        else
          case (Fmt)
            2'b11: begin       // quad
              X = TestVector[8+3*(`Q_LEN)-1:8+2*(`Q_LEN)];
              Y = TestVector[8+2*(`Q_LEN)-1:8+(`Q_LEN)];
              Ans = TestVector[8+(`Q_LEN-1):8];
              if (~clk) #5;
              DivStart = 1'b1; #10 // one clk cycle
              DivStart = 1'b0;
            end
            2'b01:	if (`D_SUPPORTED)begin	  // double
              X = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+3*(`D_LEN)-1:8+2*(`D_LEN)]};
              Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+2*(`D_LEN)-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
              if (~clk) #5;
              DivStart = 1'b1; #10
              DivStart = 1'b0;
            end
            2'b00:	if (`S_SUPPORTED)begin	  // single
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+3*(`S_LEN)-1:8+2*(`S_LEN)]};
              Y = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+2*(`S_LEN)-1:8+1*(`S_LEN)]};
              Ans = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+(`S_LEN-1):8]};
              if (~clk) #5;
              DivStart = 1'b1; #10
              DivStart = 1'b0;
            end
            2'b10:	begin	  // half
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+3*(`H_LEN)-1:8+2*(`H_LEN)]};
              Y = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+2*(`H_LEN)-1:8+(`H_LEN)]};
              Ans = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+(`H_LEN-1):8]};
              if (~clk) #5;
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
          2'b01:	if (`D_SUPPORTED)begin	  // double
            X = {{`FLEN-`D_LEN{1'b1}}, TestVector[12+2*(`D_LEN)-1:12+(`D_LEN)]};
            Y = {{`FLEN-`D_LEN{1'b1}}, TestVector[12+(`D_LEN)-1:12]};
            Ans = TestVector[8];
          end
          2'b00:	if (`S_SUPPORTED)begin	  // single
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
            2'b01:	if (`D_SUPPORTED)begin	  // double
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
          2'b01:	if (`D_SUPPORTED)begin	  // double
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
          2'b00:	if (`S_SUPPORTED)begin	  // single
          case (OpCtrl[1:0])
            2'b11: begin       // quad
              X = {{`FLEN-`S_LEN{1'b1}}, TestVector[8+`S_LEN+`Q_LEN-1:8+(`Q_LEN)]};
              Ans = TestVector[8+(`Q_LEN-1):8];
            end
            2'b01:	if (`D_SUPPORTED)begin	  // double
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
            2'b01:	if (`D_SUPPORTED)begin	  // double
              X = {{`FLEN-`H_LEN{1'b1}}, TestVector[8+`H_LEN+`D_LEN-1:8+(`D_LEN)]};
              Ans = {{`FLEN-`D_LEN{1'b1}}, TestVector[8+(`D_LEN-1):8]};
            end
            2'b00:	if (`S_SUPPORTED)begin	  // single
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
          2'b01:	if (`D_SUPPORTED)begin	  // double
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
          2'b00:	if (`S_SUPPORTED)begin	  // single
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
  
  assign XEn = ~((Unit == `CVTINTUNIT)&OpCtrl[2]);
  assign YEn = ~((Unit == `CVTINTUNIT)|(Unit == `CVTFPUNIT)|((Unit == `DIVUNIT)&OpCtrl[0]));
  assign ZEn = (Unit == `FMAUNIT);
  
  unpack unpack(.X, .Y, .Z, .Fmt(ModFmt), .Xs, .Ys, .Zs, .Xe, .Ye, .Ze,
                .Xm, .Ym, .Zm, .XNaN, .YNaN, .ZNaN, .XSNaN, .YSNaN, .ZSNaN,
                .XSubnorm, .XZero, .YZero, .ZZero, .XInf, .YInf, .ZInf,
                .XEn, .YEn, .ZEn, .XExpMax);
endmodule