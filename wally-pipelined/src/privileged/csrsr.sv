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
  output logic             STATUS_SPP, STATUS_TSR, STATUS_TW,
  output logic             STATUS_MIE, STATUS_SIE,
  output logic             STATUS_MXR, STATUS_SUM,
  output logic             STATUS_MPRV, STATUS_TVM
);
  
  logic STATUS_SD, STATUS_TW_INT, STATUS_TSR_INT, STATUS_TVM_INT, STATUS_MXR_INT, STATUS_SUM_INT, STATUS_MPRV_INT;
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
    assign STATUS_TSR = `S_SUPPORTED & STATUS_TSR_INT; // override reigster with 0 if supervisor mode not supported
    assign STATUS_TW = (`S_SUPPORTED | `U_SUPPORTED) & STATUS_TW_INT; // override reigster with 0 if only machine mode supported
    assign STATUS_TVM = `S_SUPPORTED & STATUS_TVM_INT; // override reigster with 0 if supervisor mode not supported
    assign STATUS_MXR = `S_SUPPORTED & STATUS_MXR_INT; // override reigster with 0 if supervisor mode not supported
    // SXL and UXL bits only matter for RV64.  Set to 10 for RV64 if mode is supported, or 0 if not
    assign STATUS_SXL = `S_SUPPORTED ? 2'b10 : 2'b00; // 10 if supervisor mode supported
    assign STATUS_UXL = `U_SUPPORTED ? 2'b10 : 2'b00; // 10 if user mode supported
    assign STATUS_SUM = `S_SUPPORTED & `MEM_VIRTMEM & STATUS_SUM_INT; // override reigster with 0 if supervisor mode not supported
    assign STATUS_MPRV = `U_SUPPORTED & STATUS_MPRV_INT; // override with 0 if user mode not supported
    assign STATUS_FS = (`S_SUPPORTED && (`F_SUPPORTED || `D_SUPPORTED)) ? STATUS_FS_INT : 2'b00; // off if no FP
  endgenerate
  assign STATUS_SD = (STATUS_FS == 2'b11) || (STATUS_XS == 2'b11); // dirty state logic
  assign STATUS_XS = 2'b00; // No additional user-mode state to be dirty

  always_comb
    if      (CSRWriteValM[12:11] == `U_MODE && `U_SUPPORTED) STATUS_MPP_NEXT = `U_MODE;
    else if (CSRWriteValM[12:11] == `S_MODE && `S_SUPPORTED) STATUS_MPP_NEXT = `S_MODE;
    else                                                     STATUS_MPP_NEXT = `M_MODE;

  // registers for STATUS bits
  // complex register with reset, write enable, and the ability to update other bits in certain cases
  always_ff @(posedge clk, posedge reset)
    if (reset) begin
      STATUS_TSR_INT <= #1 0;
      STATUS_TW_INT <= #1 0;
      STATUS_TVM_INT <= #1 0;
      STATUS_MXR_INT <= #1 0;
      STATUS_SUM_INT <= #1 0;
      STATUS_MPRV_INT <= #1 0; // Per Priv 3.3
      STATUS_FS_INT <= #1 0; //2'b01; // busybear: change all these reset values to 0
      STATUS_MPP <= #1 0; //`M_MODE;
      STATUS_SPP <= #1 0; //1'b1;
      STATUS_MPIE <= #1 0; //1;
      STATUS_SPIE <= #1 0; //`S_SUPPORTED;
      STATUS_UPIE <= #1 0; // `U_SUPPORTED;
      STATUS_MIE <= #1 0; // Per Priv 3.3
      STATUS_SIE <= #1 0; //`S_SUPPORTED;
      STATUS_UIE <= #1 0; //`U_SUPPORTED;
    end else if (~StallW) begin
      if (FloatRegWriteW) STATUS_FS_INT <= #12'b11; // mark Float State dirty  *** this should happen in M stage, be part of if/else
      if (TrapM) begin
        // Update interrupt enables per Privileged Spec p. 21
        // y = PrivilegeModeW
        // x = NextPrivilegeModeM
        // Modes: 11 = Machine, 01 = Supervisor, 00 = User
        if (NextPrivilegeModeM == `M_MODE) begin
          STATUS_MPIE <= #1 STATUS_MIE;
          STATUS_MIE <= #1 0;
          STATUS_MPP <= #1 PrivilegeModeW;
        end else if (NextPrivilegeModeM == `S_MODE) begin
          STATUS_SPIE <= #1 STATUS_SIE;
          STATUS_SIE <= #1 0;
          STATUS_SPP <= #1 PrivilegeModeW[0]; // *** seems to disagree with P. 56
        end else begin // user mode
          STATUS_UPIE <= #1 STATUS_UIE;
          STATUS_UIE <= #1 0;
        end
      end else if (mretM) begin // Privileged 3.1.6.1
        STATUS_MIE <= #1 STATUS_MPIE;
        STATUS_MPIE <= #1 1;
        STATUS_MPP <= #1 `U_SUPPORTED ? `U_MODE : `M_MODE; // per spec, not sure why
        STATUS_MPRV_INT <= #1 0; // per 20210108 draft spec
      end else if (sretM) begin
        STATUS_SIE <= #1 STATUS_SPIE;
        STATUS_SPIE <= #1 `S_SUPPORTED;
        STATUS_SPP <= #1 0; // Privileged 4.1.1
        STATUS_MPRV_INT <= #1 0; // per 20210108 draft spec
      end else if (uretM) begin
        STATUS_UIE <= #1 STATUS_UPIE;
        STATUS_UPIE <= #1 `U_SUPPORTED;
      end else if (WriteMSTATUSM) begin
        STATUS_TSR_INT <= #1 CSRWriteValM[22];
        STATUS_TW_INT <= #1 CSRWriteValM[21];
        STATUS_TVM_INT <= #1 CSRWriteValM[20];
        STATUS_MXR_INT <= #1 CSRWriteValM[19];
        STATUS_SUM_INT <= #1 CSRWriteValM[18];
        STATUS_MPRV_INT <= #1 CSRWriteValM[17];
        STATUS_FS_INT <= #1 CSRWriteValM[14:13];
        STATUS_MPP <= #1 STATUS_MPP_NEXT;
        STATUS_SPP <= #1 `S_SUPPORTED & CSRWriteValM[8];
        STATUS_MPIE <= #1 CSRWriteValM[7];
        STATUS_SPIE <= #1 `S_SUPPORTED & CSRWriteValM[5];
        STATUS_UPIE <= #1 `U_SUPPORTED & CSRWriteValM[4];
        STATUS_MIE <= #1 CSRWriteValM[3];
        STATUS_SIE <= #1 `S_SUPPORTED & CSRWriteValM[1];
        STATUS_UIE <= #1 `U_SUPPORTED & CSRWriteValM[0];
      end else if (WriteSSTATUSM) begin // write a subset of the STATUS bits
        STATUS_MXR_INT <= #1 CSRWriteValM[19];
        STATUS_SUM_INT <= #1 CSRWriteValM[18];
        STATUS_FS_INT <= #1 CSRWriteValM[14:13];
        STATUS_SPP <= #1 `S_SUPPORTED & CSRWriteValM[8];
        STATUS_SPIE <= #1 `S_SUPPORTED & CSRWriteValM[5];
        STATUS_UPIE <= #1 `U_SUPPORTED & CSRWriteValM[4];
        STATUS_SIE <= #1 `S_SUPPORTED & CSRWriteValM[1];
        STATUS_UIE <= #1 `U_SUPPORTED & CSRWriteValM[0];      
      end else if (WriteUSTATUSM) begin // write a subset of the STATUS bits
        STATUS_FS_INT <= #1 CSRWriteValM[14:13];
        STATUS_UPIE <= #1 `U_SUPPORTED & CSRWriteValM[4];
        STATUS_UIE <= #1 `U_SUPPORTED & CSRWriteValM[0];      
      end 
    end
endmodule
