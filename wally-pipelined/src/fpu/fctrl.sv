
module fctrl (
  input  logic [6:0] Funct7D,
  input  logic [6:0] OpD,
  input  logic [4:0] Rs2D,
  input  logic [2:0] Funct3D,
  input  logic [2:0] FRM_REGW,
  output logic       IllegalFPUInstrD,
  output logic       FWriteEnD,
  output logic       FDivStartD,
  output logic [2:0] FResultSelD,
  output logic [3:0] FOpCtrlD,
  output logic [1:0] FResSelD,
  output logic [1:0] FIntResSelD,
  output logic       FmtD,
  output logic [2:0] FrmD,
  output logic       FWriteIntD);

  `define FCTRLW 15
  logic [`FCTRLW-1:0] ControlsD;
  // FPU Instruction Decoder
  always_comb
    case(OpD)
    // FWriteEn_FWriteInt_FResultSel_FOpCtrl_FResSel_FIntResSel_FDivStart_IllegalFPUInstr
      7'b0000111: case(Funct3D)
                    3'b010:  ControlsD = `FCTRLW'b1_0_000_0000_00_00_0_0; // flw
                    3'b011:  ControlsD = `FCTRLW'b1_0_000_0001_00_00_0_0; // fld
                    default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                  endcase
      7'b0100111: case(Funct3D)
                    3'b010:  ControlsD = `FCTRLW'b0_0_000_0010_00_00_0_0; // fsw
                    3'b011:  ControlsD = `FCTRLW'b0_0_000_0011_00_00_0_0; // fsd
                    default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                  endcase
      7'b1000011:   ControlsD = `FCTRLW'b1_0_001_0000_00_00_0_0; // fmadd
      7'b1000111:   ControlsD = `FCTRLW'b1_0_001_0001_00_00_0_0; // fmsub
      7'b1001011:   ControlsD = `FCTRLW'b1_0_001_0010_00_00_0_0; // fnmsub
      7'b1001111:   ControlsD = `FCTRLW'b1_0_001_0011_00_00_0_0; // fnmadd
      7'b1010011: casez(Funct7D)
                    7'b00000??: ControlsD = `FCTRLW'b1_0_010_0000_00_00_0_0; // fadd
                    7'b00001??: ControlsD = `FCTRLW'b1_0_010_0001_00_00_0_0; // fsub
                    7'b00010??: ControlsD = `FCTRLW'b1_0_001_0100_00_00_0_0; // fmul
                    7'b00011??: ControlsD = `FCTRLW'b1_0_011_0000_00_00_1_0; // fdiv
                    7'b01011??: ControlsD = `FCTRLW'b1_0_011_0001_00_00_1_0; // fsqrt
                    7'b00100??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_100_0000_01_00_0_0; // fsgnj
                                  3'b001:  ControlsD = `FCTRLW'b1_0_100_0001_01_00_0_0; // fsgnjn
                                  3'b010:  ControlsD = `FCTRLW'b1_0_100_0010_01_00_0_0; // fsgnjx
                                  default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                                endcase
                    7'b00101??: case(Funct3D)
                                  3'b000:  ControlsD = `FCTRLW'b1_0_100_0111_10_00_0_0; // fmin
                                  3'b001:  ControlsD = `FCTRLW'b1_0_100_0101_10_00_0_0; // fmax
                                  default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                                endcase
                    7'b10100??: case(Funct3D)
                                  3'b010:  ControlsD = `FCTRLW'b0_1_100_0010_00_00_0_0; // feq
                                  3'b001:  ControlsD = `FCTRLW'b0_1_100_0001_00_00_0_0; // flt
                                  3'b000:  ControlsD = `FCTRLW'b0_1_100_0011_00_00_0_0; // fle
                                  default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                                endcase
                    7'b11100??: if (Funct3D == 3'b001)
                                  ControlsD = `FCTRLW'b0_1_100_0000_00_10_0_0; // fclass
                                else if (Funct3D[1:0] == 2'b00) ControlsD = `FCTRLW'b0_1_100_0100_00_01_0_0; // fmv.x.w
                                else if (Funct3D[1:0] == 2'b01) ControlsD = `FCTRLW'b0_1_100_0101_00_01_0_0; // fmv.x.d
                                else                            ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                    7'b1101000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_100_0001_11_00_0_0; // fcvt.s.w
                                  2'b01:    ControlsD = `FCTRLW'b1_0_100_0101_11_00_0_0; // fcvt.s.wu
                                  2'b10:    ControlsD = `FCTRLW'b1_0_100_1001_11_00_0_0; // fcvt.s.l
                                  2'b11:    ControlsD = `FCTRLW'b1_0_100_1101_11_00_0_0; // fcvt.s.lu
                                  default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                                endcase
                    7'b1100000: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_100_0010_11_11_0_0; // fcvt.w.s
                                  2'b01:    ControlsD = `FCTRLW'b0_1_100_0110_11_11_0_0; // fcvt.wu.s
                                  2'b10:    ControlsD = `FCTRLW'b0_1_100_1010_11_11_0_0; // fcvt.l.s
                                  2'b11:    ControlsD = `FCTRLW'b0_1_100_1110_11_11_0_0; // fcvt.lu.s
                                  default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                                endcase
                    7'b1111000: ControlsD = `FCTRLW'b1_0_100_0000_00_00_0_0; // fmv.w.x
                    7'b0100000: ControlsD = `FCTRLW'b1_0_010_0111_00_00_0_0; // fcvt.s.d
                    7'b1101001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b1_0_100_0001_11_00_0_0; // fcvt.d.w
                                  2'b01:    ControlsD = `FCTRLW'b1_0_100_0101_11_00_0_0; // fcvt.d.wu
                                  2'b10:    ControlsD = `FCTRLW'b1_0_100_1001_11_00_0_0; // fcvt.d.l
                                  2'b11:    ControlsD = `FCTRLW'b1_0_100_1101_11_00_0_0; // fcvt.d.lu
                                  default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                                endcase
                    7'b1100001: case(Rs2D[1:0])
                                  2'b00:    ControlsD = `FCTRLW'b0_1_100_0010_11_11_0_0; // fcvt.w.d
                                  2'b01:    ControlsD = `FCTRLW'b0_1_100_0110_11_11_0_0; // fcvt.wu.d
                                  2'b10:    ControlsD = `FCTRLW'b0_1_100_1010_11_11_0_0; // fcvt.l.d
                                  2'b11:    ControlsD = `FCTRLW'b0_1_100_1110_11_11_0_0; // fcvt.lu.d
                                  default: ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                                endcase
                    7'b1111001: ControlsD = `FCTRLW'b1_0_100_0001_00_00_0_0; // fmv.d.x
                    7'b0100001: ControlsD = `FCTRLW'b1_0_010_0111_00_00_0_0; // fcvt.d.s
                    default:    ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
                  endcase
      default:      ControlsD = `FCTRLW'b0_0_000_0000_00_00_0_1; // non-implemented instruction
    endcase
  // unswizzle control bits
  assign {FWriteEnD, FWriteIntD, FResultSelD, FOpCtrlD, FResSelD, FIntResSelD, FDivStartD, IllegalFPUInstrD} = ControlsD;
  
  // if dynamic rounding, choose FRM_REGW
  assign FrmD = &Funct3D ? FRM_REGW : Funct3D;

  // Precision
  //  0-single
  //  1-double
  assign FmtD = FResultSelD == 3'b000 ? Funct3D[0] : OpD[6:1] == 6'b010000 ? ~Funct7D[0] : Funct7D[0];
  // div/sqrt
      //  fdiv  = ???0
      //  fsqrt = ???1

  // cmp		
      //  fmin = ?111
      //  fmax = ?101
      //  feq  = ?010
      //  flt  = ?001
      //  fle  = ?011
      //		   {?,    is min or max, is eq or le, is lt or le}

  //fma/mult	
      //  fmadd  = ?000
      //  fmsub  = ?001
      //  fnmsub = ?010	-(a*b)+c
      //  fnmadd = ?011 -(a*b)-c
      //  fmul   = ?100
      //		  {?, is mul, is negitive, is sub}

  // sgn inj
      //  fsgnj  = ??00
      //  fsgnjn = ??01
      //  fsgnjx = ??10

  // add/sub/cnvt
      //  fadd      = 0000
      //  fsub      = 0001
  // cnvt
      //  fcvt.w.s  = 0010
      //  fcvt.wu.s = 0110
      //  fcvt.s.w  = 0001
      //  fcvt.s.wu = 0101
      //  fcvt.s.d  = 0000
      //  fcvt.l.s  = 1010
      //  fcvt.lu.s = 1110
      //  fcvt.s.l  = 1001
      //  fcvt.s.lu = 1101
      //  fcvt.w.d  = 0010
      //  fcvt.wu.d = 0110
      //  fcvt.d.w  = 0001
      //  fcvt.d.wu = 0101
      //  fcvt.d.s  = 0000
      //  fcvt.l.d  = 1010
      //  fcvt.lu.d = 1110
      //  fcvt.d.l  = 1001
      //  fcvt.d.lu = 1101
      //  {long, unsigned, to int, from int} Fmt controls the output for fp -> fp

      //  fmv.w.x = ???0
      //  fmv.w.d = ???1

      //  flw       = ?000
      //  fld       = ?001 
      //  fsw       = ?010
      //  fsd       = ?011
      //  fmv.x.w  = ?100
      //  fmv.x.d  = ?101
      //		   {?, is mv, is store, is double or fmv}
    

endmodule
