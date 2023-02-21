///////////////////////////////////////////
// fctrl.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: floating-point control unit
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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

module fctrl (
  input  logic                clk,
  input  logic                reset,
  // input control signals
  input  logic                StallE, StallM, StallW, // stall signals
  input  logic                FlushE, FlushM, FlushW, // flush signals
  input  logic                IntDivE,                // is inteteger division
  input  logic [2:0]          FRM_REGW,               // rounding mode from CSR
  input  logic [1:0]          STATUS_FS,              // is FPU enabled?
  input  logic                FDivBusyE,              // is the divider busy
  // intruction
  input  logic [31:0]         InstrD,                 // the full instruction
  input  logic [6:0]          Funct7D,                // bits 31:25 of instruction - may contain percision
  input  logic [6:0]          OpD,                    // bits 6:0 of instruction
  input  logic [4:0]          Rs2D,                   // bits 24:20 of instruction
  input  logic [2:0]          Funct3D, Funct3E,       // bits 14:12 of instruction - may contain rounding mode
  // input mux selections
  output logic                XEnD, YEnD, ZEnD,       // enable inputs
  output logic                XEnE, YEnE, ZEnE,       // enable inputs
  // opperation mux selections
  output logic 		            FCvtIntE, FCvtIntW,     // convert to integer opperation
  output logic [2:0] 	        FrmM,                   // FP rounding mode
  output logic [`FMTBITS-1:0] FmtE, FmtM,             // FP format
  output logic [2:0] 	        OpCtrlE, OpCtrlM,       // Select which opperation to do in each component
  output logic                FpLoadStoreM,           // FP load or store instruction
  output logic [1:0] 	        PostProcSelE, PostProcSelM,         // select result in the post processing unit
  output logic [1:0] 	        FResSelE, FResSelM, FResSelW,       // Select one of the results that finish in the memory stage
  // register control signals
  output logic 		            FRegWriteE, FRegWriteM, FRegWriteW, // FP register write enable
  output logic 		            FWriteIntE, FWriteIntM,             // Write to integer register
  output logic [4:0] 	        Adr1D, Adr2D, Adr3D,                // adresses of each input
  output logic [4:0] 	        Adr1E, Adr2E, Adr3E,                // adresses of each input
  // other control signals
  output logic                IllegalFPUInstrD,                   // Is the instruction an illegal fpu instruction
  output logic 		            FDivStartE, IDivStartE              // Start division or squareroot
  );

  `define FCTRLW 12

  logic [`FCTRLW-1:0]   ControlsD;    // control signals
  logic 		            FRegWriteD;   // FP register write enable
  logic 		            FDivStartD;   // start division/sqrt
  logic 		            FWriteIntD;   // integer register write enable
  logic [2:0] 	        OpCtrlD;      // Select which opperation to do in each component
  logic [1:0] 	        PostProcSelD; // select result in the post processing unit
  logic [1:0] 	        FResSelD;     // Select one of the results that finish in the memory stage
  logic [2:0]           FrmD, FrmE;   // FP rounding mode
  logic [`FMTBITS-1:0]  FmtD;         // FP format
  logic [1:0]           Fmt;          // format - before possible reduction
  logic                 SupportedFmt; // is the format supported
  logic                 FCvtIntD, FCvtIntM; // convert to integer opperation

  // FPU Instruction Decoder
  assign Fmt = Funct7D[1:0];

  // Note: only Fmt is checked; fcvt does not check destination format
  assign SupportedFmt = (Fmt == 2'b00 | (Fmt == 2'b01 & `D_SUPPORTED) |
                         (Fmt == 2'b10 & `ZFH_SUPPORTED) | (Fmt == 2'b11 & `Q_SUPPORTED));

  // decode the instruction                       
  always_comb
    if (STATUS_FS == 2'b00) // FPU instructions are illegal when FPU is disabled
      ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0;
    else if (OpD != 7'b0000111 & OpD != 7'b0100111 & ~SupportedFmt) 
      ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // for anything other than loads and stores, check for supported format
    else case(OpD)
    // FRegWrite_FWriteInt_FResSel_PostProcSel_FOpCtrl_FDivStart_IllegalFPUInstr_FCvtInt
      7'b0000111: case(Funct3D)
                    3'b010:                      ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0_0; // flw
                    3'b011:  if (`D_SUPPORTED)   ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0_0; // fld
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1_0; // fld not supported
                    3'b100:  if (`Q_SUPPORTED)   ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0_0; // flq
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1_0; // flq not supported
                    3'b001:  if (`ZFH_SUPPORTED) ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0_0; // flh
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1_0; // flh not supported
                    default:                     ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // non-implemented instruction
                  endcase
      7'b0100111: case(Funct3D)
                    3'b010:                      ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0_0; // fsw
                    3'b011:  if (`D_SUPPORTED)   ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0_0; // fsd
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1_0; // fsd not supported
                    3'b100:  if (`Q_SUPPORTED)   ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0_0; // fsq
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1_0; // fsq not supported
                    3'b001:  if (`ZFH_SUPPORTED) ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0_0; // fsh
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1_0; // fsh not supported
                    default:                     ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // non-implemented instruction
                  endcase
      7'b1000011:   ControlsD = `FCTRLW'b1_0_01_10_000_0_0_0; // fmadd
      7'b1000111:   ControlsD = `FCTRLW'b1_0_01_10_001_0_0_0; // fmsub
      7'b1001011:   ControlsD = `FCTRLW'b1_0_01_10_010_0_0_0; // fnmsub
      7'b1001111:   ControlsD = `FCTRLW'b1_0_01_10_011_0_0_0; // fnmadd
      7'b1010011: casez(Funct7D)
                    7'b00000??: ControlsD = `FCTRLW'b1_0_01_10_110_0_0_0; // fadd
                    7'b00001??: ControlsD = `FCTRLW'b1_0_01_10_111_0_0_0; // fsub
                    7'b00010??: ControlsD = `FCTRLW'b1_0_01_10_100_0_0_0; // fmul
                    7'b00011??: ControlsD = `FCTRLW'b1_0_01_01_xx0_1_0_0; // fdiv
                    7'b01011??: ControlsD = `FCTRLW'b1_0_01_01_xx1_1_0_0; // fsqrt
                    7'b00100??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_00_xx_000_0_0_0; // fsgnj
                                  3'b001:  ControlsD = `FCTRLW'b1_0_00_xx_001_0_0_0; // fsgnjn
                                  3'b010:  ControlsD = `FCTRLW'b1_0_00_xx_010_0_0_0; // fsgnjx
                                  default: ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // non-implemented instruction
                                endcase
                    7'b00101??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_00_xx_110_0_0_0; // fmin
                                  3'b001:  ControlsD = `FCTRLW'b1_0_00_xx_101_0_0_0; // fmax
                                  default: ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // non-implemented instruction
                                endcase
                    7'b10100??: case(Funct3D)
                                  3'b010:  ControlsD = `FCTRLW'b0_1_00_xx_010_0_0_0; // feq
                                  3'b001:  ControlsD = `FCTRLW'b0_1_00_xx_001_0_0_0; // flt
                                  3'b000:  ControlsD = `FCTRLW'b0_1_00_xx_011_0_0_0; // fle
                                  default: ControlsD = `FCTRLW'b0_0_00_xx_000__0_1_0; // non-implemented instruction
                                endcase
                    7'b11100??: if (Funct3D == 3'b001)          ControlsD = `FCTRLW'b0_1_10_xx_000_0_0_0; // fclass
                                else if (Funct3D[1:0] == 2'b00) ControlsD = `FCTRLW'b0_1_11_xx_000_0_0_0; // fmv.x.w   to int reg
                                else if (Funct3D[1:0] == 2'b01) ControlsD = `FCTRLW'b0_1_11_xx_000_0_0_0; // fmv.x.d   to int reg
                                else                            ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // non-implemented instruction
                    7'b1101000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_01_00_101_0_0_0; // fcvt.s.w   w->s
                                  2'b01:    ControlsD = `FCTRLW'b1_0_01_00_100_0_0_0; // fcvt.s.wu wu->s
                                  2'b10:    ControlsD = `FCTRLW'b1_0_01_00_111_0_0_0; // fcvt.s.l   l->s
                                  2'b11:    ControlsD = `FCTRLW'b1_0_01_00_110_0_0_0; // fcvt.s.lu lu->s
                                endcase
                    7'b1100000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_01_00_001_0_0_1; // fcvt.w.s   s->w
                                  2'b01:    ControlsD = `FCTRLW'b0_1_01_00_000_0_0_1; // fcvt.wu.s  s->wu
                                  2'b10:    ControlsD = `FCTRLW'b0_1_01_00_011_0_0_1; // fcvt.l.s   s->l
                                  2'b11:    ControlsD = `FCTRLW'b0_1_01_00_010_0_0_1; // fcvt.lu.s  s->lu
                                endcase
                    7'b1111000: ControlsD = `FCTRLW'b1_0_00_xx_011_0_0_0; // fmv.w.x   to fp reg
                    7'b0100000: ControlsD = `FCTRLW'b1_0_01_00_000_0_0_0; // fcvt.s.d
                    7'b1101001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_01_00_101_0_0_0; // fcvt.d.w   w->d
                                  2'b01:    ControlsD = `FCTRLW'b1_0_01_00_100_0_0_0; // fcvt.d.wu wu->d
                                  2'b10:    ControlsD = `FCTRLW'b1_0_01_00_111_0_0_0; // fcvt.d.l   l->d
                                  2'b11:    ControlsD = `FCTRLW'b1_0_01_00_110_0_0_0; // fcvt.d.lu lu->d
                                endcase
                    7'b1100001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_01_00_001_0_0_1; // fcvt.w.d   d->w
                                  2'b01:    ControlsD = `FCTRLW'b0_1_01_00_000_0_0_1; // fcvt.wu.d  d->wu
                                  2'b10:    ControlsD = `FCTRLW'b0_1_01_00_011_0_0_1; // fcvt.l.d   d->l
                                  2'b11:    ControlsD = `FCTRLW'b0_1_01_00_010_0_0_1; // fcvt.lu.d  d->lu
                                endcase
                    7'b1111001: ControlsD = `FCTRLW'b1_0_00_xx_011_0_0_0; // fmv.d.x   to fp reg
                    7'b0100001: ControlsD = `FCTRLW'b1_0_01_00_001_0_0_0; // fcvt.d.s
                    default:    ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // non-implemented instruction
                  endcase
      default:      ControlsD = `FCTRLW'b0_0_00_xx_000_0_1_0; // non-implemented instruction
    endcase

  // unswizzle control bits
  assign #1 {FRegWriteD, FWriteIntD, FResSelD, PostProcSelD, OpCtrlD, FDivStartD, IllegalFPUInstrD, FCvtIntD} = ControlsD;
  
  // rounding modes:
  //    000 - round to nearest, ties to even
  //    001 - round twords 0 - round to min magnitude
  //    010 - round down - round twords negitive infinity
  //    011 - round up - round twords positive infinity
  //    100 - round to nearest, ties to max magnitude - round to nearest, ties away from zero
  //    111 - dynamic - choose FRM_REGW as rounding mode
  assign FrmD = &Funct3D ? FRM_REGW : Funct3D;

  // Precision
  //    00 - single
  //    01 - double
  //    10 - half
  //    11 - quad
  
    if (`FPSIZES == 1)
      assign FmtD = 0;
    else if (`FPSIZES == 2)begin
      logic [1:0] FmtTmp;
      assign FmtTmp = ((Funct7D[6:3] == 4'b0100)&OpD[4]) ? Rs2D[1:0] : (~OpD[6]&(&OpD[2:0])) ? {~Funct3D[1], ~(Funct3D[1]^Funct3D[0])} : Funct7D[1:0];
      assign FmtD = (`FMT == FmtTmp);
    end
    else if (`FPSIZES == 3|`FPSIZES == 4)
      assign FmtD = ((Funct7D[6:3] == 4'b0100)&OpD[4]) ? Rs2D[1:0] : Funct7D[1:0];

  // Enables indicate that a source register is used and may need stalls. Also indicate special cases for infinity or NaN.
  // When disabled infinity and NaN on source registers are ignored by the unpacker and thus special case logic.
  
  //    X - all except int->fp, store, load, mv int->fp
  assign XEnD = ~(((FResSelD==2'b10)&~FWriteIntD)|                                                 // load/store
                  ((FResSelD==2'b11)&FRegWriteD)|                                                  // mv int to float
                  ((FResSelD==2'b01)&(PostProcSelD==2'b00)&OpCtrlD[2]));                           // cvt int to float

  //    Y - all except cvt, mv, load, class, sqrt
  assign YEnD = ~(((FResSelD==2'b10)&(FWriteIntD|FRegWriteD))|                                     // load or class
                  (FResSelD==2'b11)|                                                               // mv both ways
                  ((FResSelD==2'b01)&((PostProcSelD==2'b00)|((PostProcSelD==2'b01)&OpCtrlD[0])))); // cvt both or sqrt

  //    Z - fma ops only
  assign ZEnD = (PostProcSelD==2'b10)&(FResSelD==2'b01)&(~OpCtrlD[2]|OpCtrlD[1]);                  // fma, add, sub
  

  //  Final Res Sel:
  //        fp      int
  //  00  other     cmp
  //  01  postproc  cvt
  //  10  store     class
  //  11            mv

  //  post processing Sel:
  //  00  cvt
  //  01  div
  //  10  fma

  //  Other Sel:
  //    Ctrl signal = {OpCtrl[2], &FOpctrl[1:0]}
  //        000 - sign            00
  //        001 - negate sign     00
  //        010 - xor sign        00
  //        011 - mv to fp        01
  //        110 - min             10
  //        101 - max             10

  //  OpCtrl:
  //    Fma: {not multiply-add?, negate prod?, negate Z?}
  //        000 - fmadd
  //        001 - fmsub
  //        010 - fnmsub
  //        011 - fnmadd
  //        100 - mul
  //        110 - add
  //        111 - sub
  //    Div: 
  //        0 - div
  //        1 - sqrt
  //    Cvt Int: {Int to Fp?, 64 bit int?, signed int?}
  //    Cvt Fp: output format
  //        10 - to half
  //        00 - to single
  //        01 - to double
  //        11 - to quad
  //    Cmp: {equal?, less than?}
  //        010 - eq
  //        001 - lt
  //        011 - le
  //        110 - min
  //        101 - max
  //    Sgn:
  //        00 - sign
  //        01 - negate sign
  //        10 - xor sign

  // rename input adresses for readability
  assign Adr1D = InstrD[19:15];
  assign Adr2D = InstrD[24:20];
  assign Adr3D = InstrD[31:27];
 
  // D/E pipleine register
  flopenrc #(13+`FMTBITS) DECtrlReg3(clk, reset, FlushE, ~StallE, 
              {FRegWriteD, PostProcSelD, FResSelD, FrmD, FmtD, OpCtrlD, FWriteIntD, FCvtIntD},
              {FRegWriteE, PostProcSelE, FResSelE, FrmE, FmtE, OpCtrlE, FWriteIntE, FCvtIntE});
  flopenrc #(15) DEAdrReg(clk, reset, FlushE, ~StallE, {Adr1D, Adr2D, Adr3D}, {Adr1E, Adr2E, Adr3E});
  flopenrc #(1) DEFDivStartReg(clk, reset, FlushE, ~StallE|FDivBusyE, FDivStartD, FDivStartE);
  flopenrc #(3) DEEnReg(clk, reset, FlushE, ~StallE, {XEnD, YEnD, ZEnD}, {XEnE, YEnE, ZEnE});

  // Integer division on FPU divider
  if (`M_SUPPORTED & `IDIV_ON_FPU) assign IDivStartE = IntDivE;
  else                             assign IDivStartE = 0; 

  // E/M pipleine register
  flopenrc #(13+int'(`FMTBITS)) EMCtrlReg (clk, reset, FlushM, ~StallM,
              {FRegWriteE, FResSelE, PostProcSelE, FrmE, FmtE, OpCtrlE, FWriteIntE, FCvtIntE},
              {FRegWriteM, FResSelM, PostProcSelM, FrmM, FmtM, OpCtrlM, FWriteIntM, FCvtIntM});
  
  // renameing for readability
  assign FpLoadStoreM = FResSelM[1];

  // M/W pipleine register
  flopenrc #(4)  MWCtrlReg(clk, reset, FlushW, ~StallW,
          {FRegWriteM, FResSelM, FCvtIntM},
          {FRegWriteW, FResSelW, FCvtIntW});
  
  //assign FCvtIntW = (FResSelW == 2'b01);

endmodule
