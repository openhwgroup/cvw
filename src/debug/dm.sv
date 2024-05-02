///////////////////////////////////////////
// dm.sv
//
// Written: matthew.n.otto@okstate.edu, james.stine@okstate.edu
// Created: 15 March 2024
//
// Purpose: Main debug module (dm) for Debug Specification
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License Version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module dm import cvw::*; #(parameter cvw_t P) (
  input  logic                  clk, 
  input  logic                  rst, // Full hardware reset signal (reset button) //TODO make rst functional

  // External JTAG signals
  input  logic                  tck,
  input  logic                  tdi,
  input  logic                  tms,
  output logic                  tdo,

  // TODO: stubs
  output logic                  HaltReq,
  output logic                  ResumeReq,
  output logic                  ResetReq,
  input  logic                  HaltConfirm,
  input  logic                  ResumeConfirm,
  input  logic                  ResetConfirm,
  output logic                  HaltOnReset,

  // Scan Chain
  output logic                     ScanEn,
  input  logic                     ScanIn,
  output logic                     ScanOut,
  output logic                     GPRSel,
  output logic                     GPRReadEn,
  output logic                     GPRWriteEn,
  output logic [P.E_SUPPORTED+2:0] GPRAddr,
  output logic                     GPRScanEn,
  input  logic                     GPRScanIn,
  output logic                     GPRScanOut
);
  `include "debug.vh"

  // DMI Signals
  logic                   ReqReady;
  logic                   ReqValid;
  logic [`ADDR_WIDTH-1:0] ReqAddress;
  (* mark_debug = "true" *) logic [31:0]            ReqData;
  logic [1:0]             ReqOP;
  logic                   RspReady;
  logic                   RspValid;
  logic [31:0]            RspData;
  logic [1:0]             RspOP;

  localparam JTAG_DEVICE_ID = 32'hdeadbeef; // TODO: put JTAG device ID in parameter struct

  dtm #(`ADDR_WIDTH, JTAG_DEVICE_ID) dtm (.clk, .tck, .tdi, .tms, .tdo,
    .ReqReady, .ReqValid, .ReqAddress, .ReqData, .ReqOP, .RspReady,
    .RspValid, .RspData, .RspOP);

  (* mark_debug = "true" *) enum bit [3:0] {
    INACTIVE, // 0
    IDLE, // 1
    ACK, // 2
    R_DATA, // 3
    W_DATA, // 4
    DMSTATUS, // 5
    W_DMCONTROL, // 6
    R_DMCONTROL, // 7
    W_ABSTRACTCS, // 8
    R_ABSTRACTCS, // 9
    ABST_COMMAND, // a
    R_SYSBUSCS, // b
    READ_ZERO, // c
    INVALID // d
  } State;

  (* mark_debug = "true" *) enum bit [1:0] {
    AC_IDLE,
    AC_GPRUPDATE,
    AC_SCAN,
    AC_GPRCAPTURE
  } AcState, NewAcState;

  // AbsCmd internal state
  (* mark_debug = "true" *) logic              AcWrite;
  (* mark_debug = "true" *) logic [P.XLEN:0]   ScanReg;
  (* mark_debug = "true" *) logic [P.XLEN-1:0] ARMask;
  (* mark_debug = "true" *) logic [9:0]        ShiftCount, ScanChainLen, Cycle;
  (* mark_debug = "true" *) logic              InvalidRegNo;
  (* mark_debug = "true" *) logic              GPRRegNo;
  (* mark_debug = "true" *) logic              GPRSel;

  // message registers
  (* mark_debug = "true" *) logic [31:0] Data0;  // 0x04
  (* mark_debug = "true" *) logic [31:0] Data1;  // 0x05
  logic [31:0] Data2;  // 0x06
  logic [31:0] Data3;  // 0x07

  // debug module registers
  logic [31:0] DMControl;  // 0x10
  logic [31:0] DMStatus;   // 0x11
  logic [31:0] AbstractCS; // 0x16
  logic [31:0] SysBusCS;   // 0x38

  //// DM register fields
  //DMControl
  logic HartReset;
  logic AckHaveReset;
  logic AckUnavail;
  const logic HaSel = 0;
  const logic [9:0] HartSelLo = 0;
  const logic [9:0] HartSelHi = 0;
  logic NdmReset;
  logic DmActive; // This bit is used to (de)activate the DM. Toggling acts as reset
  //DMStatus
  logic NdmResetPending;
  logic StickyUnavail;
  logic ImpEBreak;
  logic AllHaveReset;
  logic AnyHaveReset;
  logic AllResumeAck;
  logic AnyResumeAck;
  logic AllNonExistent;
  logic AnyNonExistent;
  logic AllUnavail;
  logic AnyUnavail;
  logic AllRunning;
  logic AnyRunning;
  logic AllHalted;
  logic AnyHalted;
  const logic Authenticated = 1;
  logic AuthBusy;
  const logic HasResetHaltReq = 1; // TODO update
  logic ConfStrPtrValid;
  const logic [3:0] Version = 3; // DM Version
  //AbstractCS
  const logic [4:0] ProgBufSize = 0;
  logic Busy;
  logic RelaxedPriv; // TODO
  logic [2:0] CmdErr;
  const logic [3:0] DataCount = (P.XLEN/32);
  //SysBusCS
  const logic [2:0] SBVersion = 1;
  const logic SBBusyError = 0;
  const logic SBBusy = 0;
  const logic SBReadOnAddr = 0;
  const logic [2:0] SBAccess = 0;
  const logic SBAutoincrement = 0;
  const logic SBReadOnData = 0;
  const logic [2:0] SBError = 0;
  const logic [6:0] SBASize = 0;
  const logic SBAccess128 = 0;
  const logic SBAccess64 = 0;
  const logic SBAccess32 = 0;
  const logic SBAccess16 = 0;
  const logic SBAccess8 = 0;


  // Pack registers
  assign DMControl = {HaltReq, 1'b0, HartReset, 2'b0, HaSel, HartSelLo,
    HartSelHi, 4'b0, NdmReset, DmActive};

  assign DMStatus = {7'b0, NdmResetPending, StickyUnavail, ImpEBreak, 2'b0, 
    AllHaveReset, AnyHaveReset, AllResumeAck, AnyResumeAck, AllNonExistent, 
    AnyNonExistent, AllUnavail, AnyUnavail, AllRunning, AnyRunning, AllHalted, 
    AnyHalted, Authenticated, AuthBusy, HasResetHaltReq, ConfStrPtrValid, Version};

  assign AbstractCS = {3'b0, ProgBufSize, 11'b0, Busy, RelaxedPriv, CmdErr, 4'b0, DataCount};

  assign SysBusCS = {SBVersion, 6'b0, SBBusyError, SBBusy, SBReadOnAddr, SBAccess, 
    SBAutoincrement, SBReadOnData, SBError, SBASize, SBAccess128, SBAccess64, 
    SBAccess32, SBAccess16, SBAccess8};

  // translate internal state to hart connections
  assign ResetReq = HartReset;

  // TODO: implement core state logic
  assign AllRunning = ~HaltConfirm;
  assign AnyRunning = ~HaltConfirm;
  assign AllHalted = HaltConfirm;
  assign AnyHalted = HaltConfirm;
  assign AllResumeAck = ResumeConfirm;
  assign AnyResumeAck = ResumeConfirm;

  assign RspValid = (State == ACK);
  assign ReqReady = (State != ACK);

  always_ff @(posedge clk) begin
    if (rst) begin
      DmActive <= 0;
      State <= INACTIVE;
    end else begin
      case (State)
        INACTIVE : begin
          // Reset Values
          RspData <= 0;
          HaltReq <= 0;
          HartReset <= 0;
          NdmReset <= 0;
          StickyUnavail <= 0;
          ImpEBreak <= 0;
          AuthBusy <= 0;
          ConfStrPtrValid <= 0;
          RelaxedPriv <= 0; // TODO
          CmdErr <= 0;
          if (ReqValid) begin
            if (ReqAddress == `DMCONTROL && ReqOP == `OP_WRITE && ReqData[`DMACTIVE]) begin
              DmActive <= ReqData[`DMACTIVE];
              RspOP <= `OP_SUCCESS;
            end
            State <= ACK; // acknowledge all Reqs even if they don't activate DM
          end
        end

        ACK : begin
          NewAcState <= AC_IDLE;
          if (~ReqValid)
            State <= ~DmActive ? INACTIVE : IDLE;
        end

        IDLE : begin
          if (ReqValid)
            case ({ReqOP, ReqAddress}) inside
              {`OP_WRITE,`DATA0}                       : State <= W_DATA;
              {`OP_READ,`DATA0}                        : State <= R_DATA;
              {`OP_WRITE,`DATA1}                       : State <= (P.XLEN >= 64) ? W_DATA : INVALID;
              {`OP_READ,`DATA1}                        : State <= (P.XLEN >= 64) ? R_DATA : INVALID;
              [{`OP_WRITE,`DATA2}:{`OP_WRITE,`DATA3}]  : State <= (P.XLEN >= 128) ? W_DATA : INVALID;
              [{`OP_READ,`DATA2}:{`OP_READ,`DATA3}]    : State <= (P.XLEN >= 128) ? R_DATA : INVALID;
              {`OP_WRITE,`DMCONTROL}                   : State <= W_DMCONTROL;
              {`OP_READ,`DMCONTROL}                    : State <= R_DMCONTROL;
              {`OP_READ,`DMSTATUS}                     : State <= DMSTATUS;
              {`OP_WRITE,`ABSTRACTCS}                  : State <= W_ABSTRACTCS;
              {`OP_READ,`ABSTRACTCS}                   : State <= R_ABSTRACTCS;
              {`OP_WRITE,`COMMAND}                     : State <= ABST_COMMAND;
              {`OP_READ,`COMMAND}                      : State <= READ_ZERO;
              {`OP_WRITE,`SBCS}                        : State <= READ_ZERO;
              {`OP_READ,`SBCS}                         : State <= R_SYSBUSCS;
              {2'bx,`HARTINFO},
              {2'bx,`ABSTRACTAUTO},
              {2'bx,`NEXTDM}                           : State <= READ_ZERO;
              default                                  : State <= INVALID;
            endcase
        end

        R_DATA : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          case (ReqAddress)
            `DATA0  : RspData <= Data0;
            `DATA1  : RspData <= Data1;
            `DATA2  : RspData <= Data2;
            `DATA3  : RspData <= Data3;
          endcase
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        W_DATA : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        W_DMCONTROL : begin
          HaltReq <= ReqData[`HALTREQ];
          AckUnavail <= ReqData[`ACKUNAVAIL];
          NdmReset <= ReqData[`NDMRESET];
          DmActive <= ReqData[`DMACTIVE]; // Writing 0 here resets the DM
          
          // Can only write one of the following at a time
          case ({ReqData[`RESUMEREQ],ReqData[`HARTRESET],ReqData[`ACKHAVERESET],
            ReqData[`SETRESETHALTREQ],ReqData[`CLRRESETHALTREQ]})
            5'b00000 :; // None
            5'b10000 : ResumeReq <= HartReset ? 0 : 1; // TODO deassert automatically // TODO clear local ResumeACK
            5'b01000 : HartReset <= ReqData[`HARTRESET];
            //5'b00100 : HaveReset <= 0; // TODO: clear havereset (resetconfirm)
            5'b00010 : HaltOnReset <= 1;
            5'b00001 : HaltOnReset <= 0;
            default : begin // Failure (not onehot), dont write any changes
              HaltReq <= HaltReq;
              AckUnavail <= AckUnavail;
              NdmReset <= NdmReset;
              DmActive <= DmActive;
              RspOP <= `OP_FAILED;
            end
          endcase
        
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        R_DMCONTROL : begin
          RspData <= DMControl;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        DMSTATUS : begin
          RspData <= DMStatus;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        W_ABSTRACTCS : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          else begin
            RelaxedPriv <= ReqData[`RELAXEDPRIV];
            CmdErr <= |ReqData[`CMDERR] ? `CMDERR_NONE : CmdErr; // clear CmdErr
          end
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        R_ABSTRACTCS : begin
          RspData <= AbstractCS;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        ABST_COMMAND : begin // TODO: clean this up
          if (CmdErr != `CMDERR_NONE); // If CmdErr, do nothing
          else if (Busy)
            CmdErr <= `CMDERR_BUSY; // If Busy, set CmdErr, do nothing
          //else if (~CoreHaltConfirm) // TODO: this check may be undesired
          //  CmdErr <= `CMDERR_HALTRESUME; // If not halted, do nothing
          else begin
            case (ReqData[`CMDTYPE])
              `ACCESS_REGISTER : begin
                if (ReqData[`AARSIZE] > $clog2(P.XLEN/8)) // if AARSIZE (encoded) is greater than P.XLEN, set CmdErr, do nothing
                  CmdErr <= `CMDERR_BUS;
                else if (~ReqData[`TRANSFER]); // If not TRANSFER, do nothing
                else if (InvalidRegNo)
                  CmdErr <= `CMDERR_EXCEPTION; // If InvalidRegNo, set CmdErr, do nothing
                else begin
                  AcWrite <= ReqData[`AARWRITE];
                  NewAcState <= AC_SCAN;
                end
              end
              //`QUICK_ACCESS : State <= QUICK_ACCESS;
              //`ACCESS_MEMORY : State <= ACCESS_MEMORY;
              default : CmdErr <= `CMDERR_NOT_SUPPORTED;
            endcase
          end
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        R_SYSBUSCS : begin
          RspData <= SysBusCS;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        READ_ZERO : begin // Writes ignored, Read Zero
          RspData <= 0;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        INVALID : begin
          RspOP <= `OP_FAILED;
          State <= ACK;
        end
      endcase
    end
  end


  // Abstract command engine
  // Due to length of the register scan chain,
  // abstract commands execute independently of other DM operations
  always_ff @(posedge clk) begin
    if (rst)
      AcState <= AC_IDLE;
    else begin
      case (AcState)
        AC_IDLE : begin
          Cycle <= 0;
          case (NewAcState)
            AC_SCAN : AcState <= (GPRSel && ~AcWrite) ? AC_GPRCAPTURE : AC_SCAN;
          endcase
        end

        AC_GPRCAPTURE : begin
          AcState <= AC_SCAN;
        end

        AC_SCAN : begin
          if (Cycle == ScanChainLen)
            AcState <= (GPRSel && AcWrite) ? AC_GPRUPDATE : AC_IDLE;
          else
            Cycle <= Cycle + 1;
        end

        AC_GPRUPDATE : begin
          AcState <= AC_IDLE;
        end
      endcase
    end
  end

  assign Busy = ~(AcState == AC_IDLE);
  assign GPRReadEn = (AcState == AC_GPRCAPTURE);
  assign GPRWriteEn = (AcState == AC_GPRUPDATE);

  // Scan Chain
  assign GPRSel = GPRRegNo && (AcState != AC_IDLE);
  assign ScanReg[P.XLEN] = GPRSel ? GPRScanIn : ScanIn;
  assign ScanOut = GPRSel ? 1'b0 : ScanReg[0];
  assign GPRScanOut = GPRSel ? ScanReg[0] : 1'b0;
  assign ScanEn = ~GPRSel && (AcState == AC_SCAN);
  assign GPRScanEn = GPRSel && (AcState == AC_SCAN);
  // ARMask is used as write enable for subword overwrites (basic mask would overwrite neighbors)
  genvar i;
  for (i=0; i<P.XLEN; i=i+1) begin
    always_ff @(posedge clk) begin
      if (ScanEn)
        if (Cycle == ShiftCount && AcWrite) begin
          if (P.XLEN == 32)
            ScanReg[i] <= ARMask[i] ? Data0[i] : ScanReg[i+1];
          else if (P.XLEN == 64)
            ScanReg[i] <= ARMask[i] ? {Data1,Data0}[i] : ScanReg[i+1];
          else if (P.XLEN == 128)
            ScanReg[i] <= ARMask[i] ? {Data3,Data2,Data1,Data0}[i] : ScanReg[i+1];
        end else
          ScanReg[i] <= ScanReg[i+1];
    end
  end

  // Message Registers
  always_ff @(posedge clk) begin
    if (AcState == AC_SCAN) begin
      if (Cycle == ShiftCount && ~AcWrite) // Read
        if (P.XLEN == 32)
          Data0 <= ARMask & ScanReg[P.XLEN:1];
        else if (P.XLEN == 64)
          {Data1,Data0} <= ARMask & ScanReg[P.XLEN:1];
        else if (P.XLEN == 128)
          {Data3,Data2,Data1,Data0} <= ARMask & ScanReg[P.XLEN:1];
        
    end else if (State == W_DATA && ~Busy) begin // TODO: should these be zeroed if rst?
      if (P.XLEN == 32)
        case (ReqAddress)
          `DATA0  : Data0 <= ReqData;
        endcase
      else if (P.XLEN == 64)
        case (ReqAddress)
          `DATA0  : Data0 <= ReqData;
          `DATA1  : Data1 <= ReqData;
        endcase
      else if (P.XLEN == 128)
        case (ReqAddress)
          `DATA0  : Data0 <= ReqData;
          `DATA1  : Data1 <= ReqData;
          `DATA2  : Data2 <= ReqData;
          `DATA3  : Data3 <= ReqData;
        endcase
    end
  end

  rad #(P) regnodecode(.AarSize(ReqData[`AARSIZE]),.Regno(ReqData[`REGNO]),.GPRRegNo,.ScanChainLen,.ShiftCount,.InvalidRegNo,.GPRAddr,.ARMask);

endmodule
