///////////////////////////////////////////
// crsr.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Status register
//          See RISC-V Privileged Mode Specification 20190608 
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module csrsr (
  input  logic             clk, reset, StallW,
  input  logic             WriteMSTATUSM, WriteSSTATUSM, WriteUSTATUSM, 
  input  logic             TrapM, FloatRegWriteW,
  input  logic [1:0]       NextPrivilegeModeM, PrivilegeModeW,
  input  logic             mretM, sretM, uretM,
  input  logic [`XLEN-1:0] CSRWriteValM,
  output logic [`XLEN-1:0] MSTATUS_REGW, SSTATUS_REGW, USTATUS_REGW,
  output logic [1:0]       STATUS_MPP,
  output logic             STATUS_SPP, STATUS_TSR,
  output logic             STATUS_MIE, STATUS_SIE,
  output logic             STATUS_MXR, STATUS_SUM,
  output logic             STATUS_MPRV
);

  logic STATUS_SD, STATUS_TW, STATUS_TVM, STATUS_SUM_INT, STATUS_MPRV_INT;
  logic [1:0] STATUS_SXL, STATUS_UXL, STATUS_XS, STATUS_FS, STATUS_FS_INT, STATUS_MPP_NEXT;
  logic STATUS_MPIE, STATUS_SPIE, STATUS_UPIE, STATUS_UIE;

  // STATUS REGISTER FIELD
  // See Privileged Spec Section 3.1.6
  // Lower privilege status registers are a subset of the full status register
  // *** consider adding MBE, SBE, UBE fields later from 20210108 draft spec
  generate
    if (`XLEN==64) begin// RV64
      assign MSTATUS_REGW = {STATUS_SD, 27'b0, STATUS_SXL, STATUS_UXL, 9'b0,
                            STATUS_TSR, STATUS_TW, STATUS_TVM, STATUS_MXR, STATUS_SUM, STATUS_MPRV,
                            STATUS_XS, STATUS_FS, STATUS_MPP, 2'b0,
                            STATUS_SPP, STATUS_MPIE, 1'b0, STATUS_SPIE, STATUS_UPIE, 
                            STATUS_MIE, 1'b0, STATUS_SIE, STATUS_UIE};
      assign SSTATUS_REGW = {STATUS_SD, /*27'b0, */ 29'b0, /*STATUS_SXL, */ STATUS_UXL, /*9'b0, */ 12'b0,
                            /*STATUS_TSR, STATUS_TW, STATUS_TVM, */STATUS_MXR, STATUS_SUM, /* STATUS_MPRV, */ 1'b0,
                            STATUS_XS, STATUS_FS, /*STATUS_MPP, 2'b0*/ 4'b0,
                            STATUS_SPP, /*STATUS_MPIE, 1'b0*/ 2'b0, STATUS_SPIE, STATUS_UPIE, 
                            /*STATUS_MIE, 1'b0*/ 2'b0, STATUS_SIE, STATUS_UIE};
      assign USTATUS_REGW = {/*STATUS_SD, */ 59'b0, /*STATUS_SXL, STATUS_UXL, 9'b0, */
                            /*STATUS_TSR, STATUS_TW, STATUS_TVM, STATUS_MXR, STATUS_SUM,  STATUS_MPRV, , 1'b0,*/
                            /* STATUS_XS, STATUS_FS, /*STATUS_MPP,  8'b0, */
                            /*STATUS_SPP, STATUS_MPIE, 1'b0 2'b0, STATUS_SPIE,*/ STATUS_UPIE, 
                            /*STATUS_MIE, 1'b0*/ 3'b0, /*STATUS_SIE, */STATUS_UIE};
    end else begin// RV32
      assign MSTATUS_REGW = {STATUS_SD, 8'b0,
                            STATUS_TSR, STATUS_TW, STATUS_TVM, STATUS_MXR, STATUS_SUM, STATUS_MPRV,
                            STATUS_XS, STATUS_FS, STATUS_MPP, 2'b0,
                            STATUS_SPP, STATUS_MPIE, 1'b0, STATUS_SPIE, STATUS_UPIE, STATUS_MIE, 1'b0, STATUS_SIE, STATUS_UIE};
      assign SSTATUS_REGW = {STATUS_SD, 11'b0,
                            /*STATUS_TSR, STATUS_TW, STATUS_TVM, */STATUS_MXR, STATUS_SUM, /* STATUS_MPRV, */ 1'b0,
                            STATUS_XS, STATUS_FS, /*STATUS_MPP, 2'b0*/ 4'b0,
                            STATUS_SPP, /*STATUS_MPIE, 1'b0*/ 2'b0, STATUS_SPIE, STATUS_UPIE, 
                            /*STATUS_MIE, 1'b0*/ 2'b0, STATUS_SIE, STATUS_UIE};
      assign USTATUS_REGW = {/*STATUS_SD, */ 27'b0, /*STATUS_SXL, STATUS_UXL, 9'b0, */
                            /*STATUS_TSR, STATUS_TW, STATUS_TVM, STATUS_MXR, STATUS_SUM,  STATUS_MPRV, , 1'b0,*/
                            /*STATUS_XS, STATUS_FS, STATUS_MPP,  8'b0, */
                            /*STATUS_SPP, STATUS_MPIE, 1'b0 2'b0, STATUS_SPIE,*/ STATUS_UPIE, 
                            /*STATUS_MIE, 1'b0*/ 3'b0, /*STATUS_SIE, */STATUS_UIE};
    end
  endgenerate

  // harwired STATUS bits
  generate
    // SXL and UXL bits only matter for RV64.  Set to 10 for RV64 if mode is supported, or 0 if not
    assign STATUS_SXL = `S_SUPPORTED ? 2'b10 : 2'b00; // 10 if supervisor mode supported
    assign STATUS_UXL = `U_SUPPORTED ? 2'b10 : 2'b00; // 10 if user mode supported
    assign STATUS_SUM = `S_SUPPORTED & STATUS_SUM_INT; // override reigster with 0 if supervisor mode not supported
    assign STATUS_MPRV = `U_SUPPORTED & STATUS_MPRV_INT; // override with 0 if user mode not supported
    assign STATUS_FS = (`S_SUPPORTED && (`F_SUPPORTED || `D_SUPPORTED)) ? STATUS_FS_INT : 2'b00; // off if no FP
  endgenerate
  assign STATUS_SD = (STATUS_FS == 2'b11) || (STATUS_XS == 2'b11); // dirty state logic
  assign STATUS_TSR = 0; // Trap SRET not supported; revisit whether this is necessary for an OS
  assign STATUS_TW = 0; // Timeout Wait not supported
  assign STATUS_TVM = 0; // Trap Virtual Memory not supported (revisit if supporting virtualizations)
  assign STATUS_MXR = 0; // Make Executable Readable (may need to add support for VM later)
  assign STATUS_XS = 2'b00; // No additional user-mode state to be dirty

  always_comb
    if      (CSRWriteValM[12:11] == `U_MODE && `U_SUPPORTED) STATUS_MPP_NEXT = `U_MODE;
    else if (CSRWriteValM[12:11] == `S_MODE && `S_SUPPORTED) STATUS_MPP_NEXT = `S_MODE;
    else                                                     STATUS_MPP_NEXT = `M_MODE;

  // registers for STATUS bits
  // complex register with reset, write enable, and the ability to update other bits in certain cases
  always_ff @(posedge clk, posedge reset)
    if (reset) begin
      STATUS_SUM_INT <= 0;
      STATUS_MPRV_INT <= 0; // Per Priv 3.3
      STATUS_FS_INT <= 0; //2'b01; // busybear: change all these reset values to 0
      STATUS_MPP <= 0; //`M_MODE;
      STATUS_SPP <= 0; //1'b1;
      STATUS_MPIE <= 0; //1;
      STATUS_SPIE <= 0; //`S_SUPPORTED;
      STATUS_UPIE <= 0; // `U_SUPPORTED;
      STATUS_MIE <= 0; // Per Priv 3.3
      STATUS_SIE <= 0; //`S_SUPPORTED;
      STATUS_UIE <= 0; //`U_SUPPORTED;
    end else if (~StallW) begin
      if (WriteMSTATUSM) begin
        STATUS_SUM_INT <= CSRWriteValM[18];
        STATUS_MPRV_INT <= CSRWriteValM[17];
        STATUS_FS_INT <= CSRWriteValM[14:13];
        STATUS_MPP <= STATUS_MPP_NEXT;
        STATUS_SPP <= `S_SUPPORTED & CSRWriteValM[8];
        STATUS_MPIE <= CSRWriteValM[7];
        STATUS_SPIE <= `S_SUPPORTED & CSRWriteValM[5];
        STATUS_UPIE <= `U_SUPPORTED & CSRWriteValM[4];
        STATUS_MIE <= CSRWriteValM[3];
        STATUS_SIE <= `S_SUPPORTED & CSRWriteValM[1];
        STATUS_UIE <= `U_SUPPORTED & CSRWriteValM[0];
      end else if (WriteSSTATUSM) begin // write a subset of the STATUS bits
        STATUS_SUM_INT <= CSRWriteValM[18];
        STATUS_FS_INT <= CSRWriteValM[14:13];
        STATUS_SPP <= `S_SUPPORTED & CSRWriteValM[8];
        STATUS_SPIE <= `S_SUPPORTED & CSRWriteValM[5];
        STATUS_UPIE <= `U_SUPPORTED & CSRWriteValM[4];
        STATUS_SIE <= `S_SUPPORTED & CSRWriteValM[1];
        STATUS_UIE <= `U_SUPPORTED & CSRWriteValM[0];      
      end else if (WriteUSTATUSM) begin // write a subset of the STATUS bits
        STATUS_FS_INT <= CSRWriteValM[14:13];
        STATUS_UPIE <= `U_SUPPORTED & CSRWriteValM[4];
        STATUS_UIE <= `U_SUPPORTED & CSRWriteValM[0];      
      end else begin
        if (FloatRegWriteW) STATUS_FS_INT <=2'b11; // mark Float State dirty
        if (TrapM) begin
          // Update interrupt enables per Privileged Spec p. 21
          // y = PrivilegeModeW
          // x = NextPrivilegeModeM
          // Modes: 11 = Machine, 01 = Supervisor, 00 = User
          if (NextPrivilegeModeM == `M_MODE) begin
            STATUS_MPIE <= STATUS_MIE;
            STATUS_MIE <= 0;
            STATUS_MPP <= PrivilegeModeW;
          end else if (NextPrivilegeModeM == `S_MODE) begin
            STATUS_SPIE <= STATUS_SIE;
            STATUS_SIE <= 0;
            STATUS_SPP <= PrivilegeModeW[0]; // *** seems to disagree with P. 56
          end else begin // user mode
            STATUS_UPIE <= STATUS_UIE;
            STATUS_UIE <= 0;
          end
        end else if (mretM) begin // Privileged 3.1.6.1
          STATUS_MIE <= STATUS_MPIE;
          STATUS_MPIE <= 1;
          STATUS_MPP <= `U_SUPPORTED ? `U_MODE : `M_MODE; // per spec, not sure why
          STATUS_MPRV_INT <= 0; // per 20210108 draft spec
        end else if (sretM) begin
          STATUS_SIE <= STATUS_SPIE;
          STATUS_SPIE <= `S_SUPPORTED;
          STATUS_SPP <= 0; // Privileged 4.1.1
          STATUS_MPRV_INT <= 0; // per 20210108 draft spec
        end else if (uretM) begin
          STATUS_UIE <= STATUS_UPIE;
          STATUS_UPIE <= `U_SUPPORTED;
        end
        // *** add code to track STATUS_FS_INT for dirty floating point registers
      end
    end
endmodule
