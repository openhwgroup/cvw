///////////////////////////////////////////
// fctrl.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: control unit
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////
`include "wally-config.vh"

module fctrl (
  input  logic       clk,
  input  logic       reset,
  input  logic       StallE, StallM, StallW, // stall signals
  input  logic       FlushE, FlushM, FlushW, // flush signals
  input  logic [31:0] InstrD,
  input  logic [6:0] Funct7D,   // bits 31:25 of instruction - may contain percision
  input  logic [6:0] OpD,       // bits 6:0 of instruction
  input  logic [4:0] Rs2D,      // bits 24:20 of instruction
  input  logic [2:0] Funct3D, Funct3E,   // bits 14:12 of instruction - may contain rounding mode
  input  logic       MDUE,
  input  logic [2:0] FRM_REGW,  // rounding mode from CSR
  input  logic [1:0] STATUS_FS, // is FPU enabled?
  input  logic       FDivBusyE,  // is the divider busy
  output logic       IllegalFPUInstrM, // Is the instruction an illegal fpu instruction
  output logic 		         FRegWriteM, FRegWriteW, // FP register write enable
  output logic [2:0] 	      FrmM,                   // FP rounding mode
  output logic [`FMTBITS-1:0] FmtE, FmtM,             // FP format
  output logic 		         DivStartE,             // Start division or squareroot
  output logic              XEnE, YEnE, ZEnE,
  output logic              YEnForwardE, ZEnForwardE,
  output logic 		         FWriteIntE, FCvtIntE, FWriteIntM,                         // Write to integer register
  output logic [2:0] 	      OpCtrlE, OpCtrlM,       // Select which opperation to do in each component
  output logic [1:0] 	      FResSelE, FResSelM, FResSelW,       // Select one of the results that finish in the memory stage
  output logic [1:0] 	      PostProcSelE, PostProcSelM, // select result in the post processing unit
  output logic              FCvtIntW,
  output logic [4:0] 	      Adr1E, Adr2E, Adr3E                // adresses of each input
  );

  `define FCTRLW 11
  logic [`FCTRLW-1:0] ControlsD;
  logic       IllegalFPUInstrD, IllegalFPUInstrE;
  logic 		  FRegWriteD; // FP register write enable
  logic 		  FDivStartD, FDivStartE, IDivStartE; // integer register write enable
  logic 		  FWriteIntD; // integer register write enable
  logic 		         FRegWriteE; // FP register write enable
  logic [2:0] 	      OpCtrlD;       // Select which opperation to do in each component
  logic [1:0] 	      PostProcSelD; // select result in the post processing unit
  logic [1:0] 	      FResSelD;       // Select one of the results that finish in the memory stage
  logic [2:0] FrmD, FrmE;                   // FP rounding mode
  logic [`FMTBITS-1:0] FmtD;             // FP format
  logic [1:0] Fmt;
  logic       SupportedFmt;

  // FPU Instruction Decoder
  assign Fmt = Funct7D[1:0];
  // Note: only Fmt is checked; fcvt does not check destination format
  assign SupportedFmt = (Fmt == 2'b00 | (Fmt == 2'b01 & `D_SUPPORTED) |
                         (Fmt == 2'b10 & `ZFH_SUPPORTED) | (Fmt == 2'b11 & `Q_SUPPORTED));
  always_comb
    if (STATUS_FS == 2'b00) // FPU instructions are illegal when FPU is disabled
      ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1;
    else if (OpD != 7'b0000111 & OpD != 7'b0100111 & ~SupportedFmt) 
      ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // for anything other than loads and stores, check for supported format
    else case(OpD)
    // FRegWrite_FWriteInt_FResSel_PostProcSel_FOpCtrl_FDivStart_IllegalFPUInstr
      7'b0000111: case(Funct3D)
                    3'b010:                      ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0; // flw
                    3'b011:  if (`D_SUPPORTED)   ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0; // fld
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // fld not supported
                    3'b100:  if (`Q_SUPPORTED)   ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0; // flq
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // flq not supported
                    3'b001:  if (`ZFH_SUPPORTED) ControlsD = `FCTRLW'b1_0_10_xx_0xx_0_0; // flh
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // flh not supported
                    default:                     ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // non-implemented instruction
                  endcase
      7'b0100111: case(Funct3D)
                    3'b010:                      ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0; // fsw
                    3'b011:  if (`D_SUPPORTED)   ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0; // fsd
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // fsd not supported
                    3'b100:  if (`Q_SUPPORTED)   ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0; // fsq
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // fsq not supported
                    3'b001:  if (`ZFH_SUPPORTED) ControlsD = `FCTRLW'b0_0_10_xx_0xx_0_0; // fsh
                             else                ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // fsh not supported
                    default:                     ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // non-implemented instruction
                  endcase
      7'b1000011:   ControlsD = `FCTRLW'b1_0_01_10_000_0_0; // fmadd
      7'b1000111:   ControlsD = `FCTRLW'b1_0_01_10_001_0_0; // fmsub
      7'b1001011:   ControlsD = `FCTRLW'b1_0_01_10_010_0_0; // fnmsub
      7'b1001111:   ControlsD = `FCTRLW'b1_0_01_10_011_0_0; // fnmadd
      7'b1010011: casez(Funct7D)
                    7'b00000??: ControlsD = `FCTRLW'b1_0_01_10_110_0_0; // fadd
                    7'b00001??: ControlsD = `FCTRLW'b1_0_01_10_111_0_0; // fsub
                    7'b00010??: ControlsD = `FCTRLW'b1_0_01_10_100_0_0; // fmul
                    7'b00011??: ControlsD = `FCTRLW'b1_0_01_01_xx0_1_0; // fdiv
                    7'b01011??: ControlsD = `FCTRLW'b1_0_01_01_xx1_1_0; // fsqrt
                    7'b00100??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_00_xx_000_0_0; // fsgnj
                                  3'b001:  ControlsD = `FCTRLW'b1_0_00_xx_001_0_0; // fsgnjn
                                  3'b010:  ControlsD = `FCTRLW'b1_0_00_xx_010_0_0; // fsgnjx
                                  default: ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // non-implemented instruction
                                endcase
                    7'b00101??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_00_xx_110_0_0; // fmin
                                  3'b001:  ControlsD = `FCTRLW'b1_0_00_xx_101_0_0; // fmax
                                  default: ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // non-implemented instruction
                                endcase
                    7'b10100??: case(Funct3D)
                                  3'b010:  ControlsD = `FCTRLW'b0_1_00_xx_010_0_0; // feq
                                  3'b001:  ControlsD = `FCTRLW'b0_1_00_xx_001_0_0; // flt
                                  3'b000:  ControlsD = `FCTRLW'b0_1_00_xx_011_0_0; // fle
                                  default: ControlsD = `FCTRLW'b0_0_00_xx_0xx__0_1; // non-implemented instruction
                                endcase
                    7'b11100??: if (Funct3D == 3'b001)          ControlsD = `FCTRLW'b0_1_10_xx_000_0_0; // fclass
                                else if (Funct3D[1:0] == 2'b00) ControlsD = `FCTRLW'b0_1_11_xx_000_0_0; // fmv.x.w   to int reg
                                else if (Funct3D[1:0] == 2'b01) ControlsD = `FCTRLW'b0_1_11_xx_000_0_0; // fmv.x.d   to int reg
                                else                            ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // non-implemented instruction
                    7'b1101000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_01_00_101_0_0; // fcvt.s.w   w->s
                                  2'b01:    ControlsD = `FCTRLW'b1_0_01_00_100_0_0; // fcvt.s.wu wu->s
                                  2'b10:    ControlsD = `FCTRLW'b1_0_01_00_111_0_0; // fcvt.s.l   l->s
                                  2'b11:    ControlsD = `FCTRLW'b1_0_01_00_110_0_0; // fcvt.s.lu lu->s
                                endcase
                    7'b1100000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_01_00_001_0_0; // fcvt.w.s   s->w
                                  2'b01:    ControlsD = `FCTRLW'b0_1_01_00_000_0_0; // fcvt.wu.s  s->wu
                                  2'b10:    ControlsD = `FCTRLW'b0_1_01_00_011_0_0; // fcvt.l.s   s->l
                                  2'b11:    ControlsD = `FCTRLW'b0_1_01_00_010_0_0; // fcvt.lu.s  s->lu
                                endcase
                    7'b1111000: ControlsD = `FCTRLW'b1_0_00_xx_011_0_0; // fmv.w.x   to fp reg
                    7'b0100000: ControlsD = `FCTRLW'b1_0_01_00_000_0_0; // fcvt.s.d
                    7'b1101001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_01_00_101_0_0; // fcvt.d.w   w->d
                                  2'b01:    ControlsD = `FCTRLW'b1_0_01_00_100_0_0; // fcvt.d.wu wu->d
                                  2'b10:    ControlsD = `FCTRLW'b1_0_01_00_111_0_0; // fcvt.d.l   l->d
                                  2'b11:    ControlsD = `FCTRLW'b1_0_01_00_110_0_0; // fcvt.d.lu lu->d
                                endcase
                    7'b1100001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_01_00_001_0_0; // fcvt.w.d   d->w
                                  2'b01:    ControlsD = `FCTRLW'b0_1_01_00_000_0_0; // fcvt.wu.d  d->wu
                                  2'b10:    ControlsD = `FCTRLW'b0_1_01_00_011_0_0; // fcvt.l.d   d->l
                                  2'b11:    ControlsD = `FCTRLW'b0_1_01_00_010_0_0; // fcvt.lu.d  d->lu
                                endcase
                    7'b1111001: ControlsD = `FCTRLW'b1_0_00_xx_011_0_0; // fmv.d.x   to fp reg
                    7'b0100001: ControlsD = `FCTRLW'b1_0_01_00_001_0_0; // fcvt.d.s
                    default:    ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // non-implemented instruction
                  endcase
      default:      ControlsD = `FCTRLW'b0_0_00_xx_0xx_0_1; // non-implemented instruction
    endcase

  // unswizzle control bits
  assign {FRegWriteD, FWriteIntD, FResSelD, PostProcSelD, OpCtrlD, FDivStartD, IllegalFPUInstrD} = ControlsD;
  
  // rounding modes:
  //    000 - round to nearest, ties to even
  //    001 - round twords 0 - round to min magnitude
  //    010 - round down - round twords negitive infinity
  //    011 - round up - round twords positive infinity
  //    100 - round to nearest, ties to max magnitude - round to nearest, ties away from zero
  //    111 - dynamic - choose FRM_REGW as rounding mode
  assign FrmD = &Funct3D ? FRM_REGW : Funct3D;

  // Precision
  //    0-single
  //    1-double
  
    if (`FPSIZES == 1)
      assign FmtD = 0;
    else if (`FPSIZES == 2)begin
      logic [1:0] FmtTmp;
      assign FmtTmp = ((Funct7D[6:3] == 4'b0100)&OpD[4]) ? Rs2D[1:0] : (~OpD[6]&(&OpD[2:0])) ? {~Funct3D[1], ~(Funct3D[1]^Funct3D[0])} : Funct7D[1:0];
      assign FmtD = (`FMT == FmtTmp);
    end
    else if (`FPSIZES == 3|`FPSIZES == 4)
      assign FmtD = ((Funct7D[6:3] == 4'b0100)&OpD[4]) ? Rs2D[1:0] : Funct7D[1:0];

      

// enables:
//    X - all except int->fp, store, load, mv int->fp
//    Y - all except cvt, mv, load, class, sqrt
//    Z - fma ops only
//                  load/store                        mv int->fp                      cvt int->fp
    assign XEnE = ~(((FResSelE==2'b10)&~FWriteIntE)|((FResSelE==2'b11)&FRegWriteE)|((FResSelE==2'b01)&(PostProcSelE==2'b00)&OpCtrlE[2]));
//                  load/class                                    mv               cvt
    assign YEnE = ~(((FResSelE==2'b10)&(FWriteIntE|FRegWriteE))|(FResSelE==2'b11)|((FResSelE==2'b01)&((PostProcSelE==2'b00)|((PostProcSelE==2'b01)&OpCtrlE[0]))));    
    assign ZEnE = (PostProcSelE==2'b10)&(FResSelE==2'b01)&(~OpCtrlE[2]|OpCtrlE[1]);
    assign YEnForwardE = ~(((FResSelE==2'b10)&(FWriteIntE|FRegWriteE))|(FResSelE==2'b11)|((FResSelE==2'b01)&((PostProcSelE==2'b00)|((PostProcSelE==2'b01)&OpCtrlE[0]))));    
    assign ZEnForwardE = (PostProcSelE==2'b10)&(FResSelE==2'b01)&~OpCtrlE[2];

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
    
  // D/E pipleine register
  flopenrc #(13+`FMTBITS) DECtrlReg3(clk, reset, FlushE, ~StallE, 
              {FRegWriteD, PostProcSelD, FResSelD, FrmD, FmtD, OpCtrlD, FWriteIntD, IllegalFPUInstrD},
              {FRegWriteE, PostProcSelE, FResSelE, FrmE, FmtE, OpCtrlE, FWriteIntE, IllegalFPUInstrE});
  flopenrc #(15) DEAdrReg(clk, reset, FlushE, ~StallE, {InstrD[19:15], InstrD[24:20], InstrD[31:27]}, 
                           {Adr1E, Adr2E, Adr3E});
  flopenrc #(1) DEFDivStartReg(clk, reset, FlushE, ~StallE|FDivBusyE, FDivStartD, FDivStartE);
  if (`M_SUPPORTED) begin
    assign IDivStartE = MDUE & Funct3E[2];
    assign DivStartE = FDivStartE | IDivStartE; // integer or floating-point division
  end else assign DivStartE = FDivStartE;

  assign FCvtIntE = (FResSelE == 2'b01);

  // E/M pipleine register
  flopenrc #(13+int'(`FMTBITS)) EMCtrlReg (clk, reset, FlushM, ~StallM,
              {FRegWriteE, FResSelE, PostProcSelE, FrmE, FmtE, OpCtrlE, FWriteIntE, IllegalFPUInstrE},
              {FRegWriteM, FResSelM, PostProcSelM, FrmM, FmtM, OpCtrlM, FWriteIntM, IllegalFPUInstrM});
  // M/W pipleine register
  flopenrc #(3)  MWCtrlReg(clk, reset, FlushW, ~StallW,
          {FRegWriteM, FResSelM},
          {FRegWriteW, FResSelW});
  
  assign FCvtIntW = (FResSelW == 2'b01);

endmodule
