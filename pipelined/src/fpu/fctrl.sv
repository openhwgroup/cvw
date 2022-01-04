
module fctrl (
  input  logic [6:0] Funct7D,   // bits 31:25 of instruction - may contain percision
  input  logic [6:0] OpD,       // bits 6:0 of instruction
  input  logic [4:0] Rs2D,      // bits 24:20 of instruction
  input  logic [2:0] Funct3D,   // bits 14:12 of instruction - may contain rounding mode
  input  logic [2:0] FRM_REGW,  // rounding mode from CSR
  output logic       IllegalFPUInstrD, // Is the instruction an illegal fpu instruction
  output logic       FRegWriteD,  // FP register write enable
  output logic       FDivStartD,  // Start division or squareroot
  output logic [1:0] FResultSelD, // select result to be written to fp register
  output logic [2:0] FOpCtrlD,    // chooses which opperation to do - specifics shown at bottom of module and in each unit
  output logic [2:0] FResSelD,    // select one of the results done in the memory stage
  output logic [1:0] FIntResSelD, // select the result that will be written to the integer register
  output logic       FmtD,        // precision - single-0 double-1
  output logic [2:0] FrmD,        // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
  output logic       FWriteIntD   // is the result written to the integer register
  );

  `define FCTRLW 14
  logic [`FCTRLW-1:0] ControlsD;
  // FPU Instruction Decoder
  always_comb
    case(OpD)
    // FRegWrite_FWriteInt_FResultSel_FOpCtrl_FResSel_FIntResSel_FDivStart_IllegalFPUInstr
      7'b0000111: case(Funct3D)
                    3'b010:  ControlsD = `FCTRLW'b1_0_00_000_000_00_0_0; // flw
                    3'b011:  ControlsD = `FCTRLW'b1_0_00_001_000_00_0_0; // fld
                    default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                  endcase
      7'b0100111: case(Funct3D)
                    3'b010:  ControlsD = `FCTRLW'b0_0_00_010_000_00_0_0; // fsw
                    3'b011:  ControlsD = `FCTRLW'b0_0_00_011_000_00_0_0; // fsd
                    default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                  endcase
      7'b1000011:   ControlsD = `FCTRLW'b1_0_01_000_000_00_0_0; // fmadd
      7'b1000111:   ControlsD = `FCTRLW'b1_0_01_001_000_00_0_0; // fmsub
      7'b1001011:   ControlsD = `FCTRLW'b1_0_01_010_000_00_0_0; // fnmsub
      7'b1001111:   ControlsD = `FCTRLW'b1_0_01_011_000_00_0_0; // fnmadd
      7'b1010011: casez(Funct7D)
                    7'b00000??: ControlsD = `FCTRLW'b1_0_01_110_000_00_0_0; // fadd
                    7'b00001??: ControlsD = `FCTRLW'b1_0_01_111_000_00_0_0; // fsub
                    7'b00010??: ControlsD = `FCTRLW'b1_0_01_100_000_00_0_0; // fmul
                    7'b00011??: ControlsD = `FCTRLW'b1_0_10_000_000_00_1_0; // fdiv
                    7'b01011??: ControlsD = `FCTRLW'b1_0_10_001_000_00_1_0; // fsqrt
                    7'b00100??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_11_000_001_00_0_0; // fsgnj
                                  3'b001:  ControlsD = `FCTRLW'b1_0_11_001_001_00_0_0; // fsgnjn
                                  3'b010:  ControlsD = `FCTRLW'b1_0_11_010_001_00_0_0; // fsgnjx
                                  default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                                endcase
                    7'b00101??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_11_111_010_00_0_0; // fmin
                                  3'b001:  ControlsD = `FCTRLW'b1_0_11_101_010_00_0_0; // fmax
                                  default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                                endcase
                    7'b10100??: case(Funct3D)
                                  3'b010:  ControlsD = `FCTRLW'b0_1_11_010_010_00_0_0; // feq
                                  3'b001:  ControlsD = `FCTRLW'b0_1_11_001_010_00_0_0; // flt
                                  3'b000:  ControlsD = `FCTRLW'b0_1_11_011_010_00_0_0; // fle
                                  default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                                endcase
                    7'b11100??: if (Funct3D == 3'b001) ControlsD = `FCTRLW'b0_1_11_000_000_10_0_0; // fclass
                                else if (Funct3D[1:0] == 2'b00) ControlsD = `FCTRLW'b0_1_11_100_000_01_0_0; // fmv.x.w
                                else if (Funct3D[1:0] == 2'b01) ControlsD = `FCTRLW'b0_1_11_101_000_01_0_0; // fmv.x.d
                                else                            ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                    7'b1101000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_11_000_011_00_0_0; // fcvt.s.w
                                  2'b01:    ControlsD = `FCTRLW'b1_0_11_010_011_00_0_0; // fcvt.s.wu
                                  2'b10:    ControlsD = `FCTRLW'b1_0_11_100_011_00_0_0; // fcvt.s.l
                                  2'b11:    ControlsD = `FCTRLW'b1_0_11_110_011_00_0_0; // fcvt.s.lu
                                  default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                                endcase
                    7'b1100000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_11_001_011_11_0_0; // fcvt.w.s
                                  2'b01:    ControlsD = `FCTRLW'b0_1_11_011_011_11_0_0; // fcvt.wu.s
                                  2'b10:    ControlsD = `FCTRLW'b0_1_11_101_011_11_0_0; // fcvt.l.s
                                  2'b11:    ControlsD = `FCTRLW'b0_1_11_111_011_11_0_0; // fcvt.lu.s
                                  default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                                endcase
                    7'b1111000: ControlsD = `FCTRLW'b1_0_11_000_000_00_0_0; // fmv.w.x
                    7'b010000?: ControlsD = `FCTRLW'b1_0_11_000_100_00_0_0; // fcvt.s.d
                    7'b1101001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_11_000_011_00_0_0; // fcvt.d.w
                                  2'b01:    ControlsD = `FCTRLW'b1_0_11_010_011_00_0_0; // fcvt.d.wu
                                  2'b10:    ControlsD = `FCTRLW'b1_0_11_100_011_00_0_0; // fcvt.d.l
                                  2'b11:    ControlsD = `FCTRLW'b1_0_11_110_011_00_0_0; // fcvt.d.lu
                                  default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                                endcase
                    7'b1100001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_11_001_011_11_0_0; // fcvt.w.d
                                  2'b01:    ControlsD = `FCTRLW'b0_1_11_011_011_11_0_0; // fcvt.wu.d
                                  2'b10:    ControlsD = `FCTRLW'b0_1_11_101_011_11_0_0; // fcvt.l.d
                                  2'b11:    ControlsD = `FCTRLW'b0_1_11_111_011_11_0_0; // fcvt.lu.d
                                  default: ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
                                endcase
                    7'b1111001: ControlsD = `FCTRLW'b1_0_11_001_000_00_0_0; // fmv.d.x
                    //7'b0100001: ControlsD = `FCTRLW'b1_0_11_000_100_00_0_0; // fcvt.d.s
                    default:    ControlsD = `FCTRLW'b0_0_00_000_100_00_0_1; // non-implemented instruction
                  endcase
      default:      ControlsD = `FCTRLW'b0_0_00_000_000_00_0_1; // non-implemented instruction
    endcase

  // unswizzle control bits
  assign {FRegWriteD, FWriteIntD, FResultSelD, FOpCtrlD, FResSelD, FIntResSelD, FDivStartD, IllegalFPUInstrD} = ControlsD;
  
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
  assign FmtD = FResultSelD == 2'b00 ? Funct3D[0] : FResSelD == 3'b100 | OpD[6:1] == 6'b010000 ? ~Funct7D[0] : Funct7D[0];

  // FResultSel:
  //    000 - ReadRes - load
  //    001 - FMARes  - FMA and multiply
  //    010 - FAddRes - add and fp to fp
  //    011 - FDivRes - divide and squareroot
  //    100 - FRes    - anything that is written to the fp register and is ready in the memory stage
  //        FResSel:
  //            00 - SrcA   - move to fp register 
  //            01 - SgnRes - sign injection
  //            10 - CmpRes - min/max
  //            11 - CvtRes - convert to fp
  
  // FIntResSel:
  //    00 - CmpRes   - less than, equal, or less than or equal 
  //    01 - FSrcX    - move to int register
  //    10 - ClassRes - classify
  //    11 - CvtRes   - convert to signed/unsigned int

  // OpCtrl values: 
  // div/sqrt
      //  fdiv  = ???0
      //  fsqrt = ???1

  // cmp		
      //  fmin = ?111
      //  fmax = ?101
      //  feq  = ?010
      //  flt  = ?001
      //  fle  = ?011
      //  {?,  is min or max,   is eq or le,   is lt or le}

  //fma/mult	
      //  fmadd  = ?000
      //  fmsub  = ?001
      //  fnmsub = ?010	-(a*b)+c
      //  fnmadd = ?011 -(a*b)-c
      //  fmul   = ?100
      //	{?, is mul, negate product, negate addend}

  // sgn inj
      //  fsgnj  = ??00
      //  fsgnjn = ??01
      //  fsgnjx = ??10

  // add/sub/cnvt
      //  fadd      = 0000
      //  fsub      = 0001
      //  fcvt.s.d  = 0111
      //  fcvt.d.s  = 0111
      //  Fmt controls the output for fp -> fp
      
  // convert
      //  fcvt.w.s  = 0010
      //  fcvt.wu.s = 0110
      //  fcvt.s.w  = 0001
      //  fcvt.s.wu = 0101
      //  fcvt.l.s  = 1010
      //  fcvt.lu.s = 1110
      //  fcvt.s.l  = 1001
      //  fcvt.s.lu = 1101
      //  fcvt.w.d  = 0010 
      //  fcvt.wu.d = 0110
      //  fcvt.d.w  = 0001
      //  fcvt.d.wu = 0101
      //  fcvt.l.d  = 1010
      //  fcvt.lu.d = 1110
      //  fcvt.d.l  = 1001
      //  fcvt.d.lu = 1101
      //  {long, unsigned, to int, from int}
    

endmodule
