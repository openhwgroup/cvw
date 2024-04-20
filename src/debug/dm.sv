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

module dm #(parameter ADDR_WIDTH, parameter XLEN) (
  input  logic                  clk, 
  input  logic                  rst, // Full hardware reset signal (reset button) //TODO make rst functional
  output logic                  NdmReset, // Debugger controlled hardware reset (resets everything except DM, DMI, DTM)

  // DMI Signals
  output logic                  ReqReady,
  input  logic                  ReqValid,
  (* mark_debug = "true" *) input  logic [ADDR_WIDTH-1:0] ReqAddress,
  (* mark_debug = "true" *) input  logic [31:0]           ReqData,
  (* mark_debug = "true" *) input  logic [1:0]            ReqOP,
  input  logic                  RspReady,
  output logic                  RspValid,
  (* mark_debug = "true" *) output logic [31:0]           RspData,
  output logic [1:0]            RspOP,

  // TODO: stubs
  output logic                  CoreHalt,
  output logic                  CoreResume,
  output logic                  CoreReset,
  input  logic                  CoreHaltConfirm,
  input  logic                  CoreResumeConfirm,
  input  logic                  CoreResetConfirm,
  output logic                  CoreHaltOnReset,

  // Scan Chain
  output logic                  ScanEn,
  input  logic                  ScanIn,
  output logic                  ScanOut
);
  `include "debug.vh"

  localparam SCANNABLE_REG_COUNT = 2;
  localparam SCAN_CHAIN_LEN = (SCANNABLE_REG_COUNT+1)*XLEN-1;

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

  enum bit [0:0] {
    AC_IDLE,
    AC_SCAN
  } AcState, NewAcState;

  // AbsCmd internal state
  logic          AcWrite;
  logic          AcTransfer;
  logic [XLEN:0] ScanReg;
  logic [$clog2(SCAN_CHAIN_LEN)-1:0] ShiftCount, Cycle;
  logic          InvalidRegNo;

  // message registers
  logic [31:0] Data0;  //0x04
  logic [31:0] Data1;  //0x05
  logic [31:0] Data2;  //0x06
  logic [31:0] Data3;  //0x07
  if (XLEN == 64) begin // TODO: parameterize register based on XLEN
  end
  if (XLEN == 128) begin
  end

  // debug module registers
  logic [31:0] DMControl;  //0x10
  (* mark_debug = "true" *) logic [31:0] DMStatus;   //0x11
  //logic [31:0] hartinfo;   //0x12
  //logic [31:0] haltsum1;   //0x13
  //logic [31:0] hawindowsel;  // 0x14
  //logic [31:0] hawindow;   // 0x15
  logic [31:0] AbstractCS;   // 0x16
  //logic [31:0] command;    // 0x17
  //logic [31:0] abstractauto; // 0x18
  //logic [31:0] confstrptr0;  // 0x19
  //logic [31:0] confstrptr1;  // 0x1a
  //logic [31:0] confstrptr2;  // 0x1b
  //logic [31:0] confstrptr3;  // 0x1c
  logic [31:0] SysBusCS;

  //// DM register fields
  //DMControl
  logic HaltReq;
  logic ResumeReq;
  logic HartReset;
  logic AckHaveReset;
  logic AckUnavail;
  const logic HaSel = 0;
  const logic [9:0] HartSelLo = 0;
  const logic [9:0] HartSelHi = 0;
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
  const logic [3:0] DataCount = (XLEN/32);
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
  assign CoreHalt = HaltReq;
  assign CoreResume = ResumeReq;
  assign CoreReset = HartReset;

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
          HaltReq <= 0;
          HartReset <= 0;
          NdmReset <= 0;

          StickyUnavail <= 0;
          ImpEBreak <= 0;
          AuthBusy <= 0;
          ConfStrPtrValid <= 0;

          //abstractcs
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
              [{`OP_WRITE,`DATA0}:{`OP_WRITE,`DATA11}] : State <= W_DATA;
              [{`OP_READ,`DATA0}:{`OP_READ,`DATA11}]   : State <= R_DATA;
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
          RspOP <= `OP_SUCCESS;

          // Can only write one of the following at a time
          case ({ReqData[`RESUMEREQ],ReqData[`HARTRESET],ReqData[`ACKHAVERESET],
            ReqData[`SETRESETHALTREQ],ReqData[`CLRRESETHALTREQ]})
            5'b00000 :; // None
            5'b10000 : ResumeReq <= HartReset ? 0 : 1; // TODO deassert automatically // TODO clear local ResumeACK
            5'b01000 : HartReset <= ReqData[`HARTRESET];
            //5'b00100 : HaveReset <= 0; // TODO: clear havereset (resetconfirm)
            5'b00010 : CoreHaltOnReset <= 1;
            5'b00001 : CoreHaltOnReset <= 0;
            default : begin // Failure (not onehot), dont write any changes
              HaltReq <= HaltReq;
              AckUnavail <= AckUnavail;
              NdmReset <= NdmReset;
              DmActive <= DmActive;
              RspOP <= `OP_FAILED;
            end
          endcase

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
            CmdErr <= ReqData[`CMDERR] ? `CMDERR_NONE : CmdErr;
          end
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        R_ABSTRACTCS : begin
          RspData <= AbstractCS;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        ABST_COMMAND : begin
          case (ReqData[`CMDTYPE])
            `ACCESS_REGISTER : begin // TODO: check that hart is halted else cmderr <= `CMDERR_HALTRESUME
              if (ReqData[`AARSIZE] > XLEN) begin // TODO: make sure smaller sizes are supported
                CmdErr <= `CMDERR_EXCEPTION;
              end else if (ReqData[`TRANSFER]) begin
                //ShiftCount <= 64; // TODO: calcualte this based on regno ReqData[`REGNO]
                // if REGNO does not exist, cmderr <= `CMDERR_EXCEPTION;
                // InvalidRegNo
                AcTransfer <= ReqData[`TRANSFER];
                AcWrite <= ReqData[`AARWRITE];
                NewAcState <= AC_SCAN;
              end
            end
            //`QUICK_ACCESS : State <= QUICK_ACCESS;
            //`ACCESS_MEMORY : State <= ACCESS_MEMORY;
            default : CmdErr <= `CMDERR_NOT_SUPPORTED;
          endcase

          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
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
            AC_SCAN : AcState <= AC_SCAN;
          endcase
        end

        AC_SCAN : begin
          if (Cycle == SCAN_CHAIN_LEN)
            AcState <= AC_IDLE;
          else
            Cycle <= Cycle + 1;
        end
      endcase
    end
  end

  assign Busy = ~(AcState == AC_IDLE);


  // Scan Chain
  assign ScanReg[XLEN] = ScanIn;
  assign ScanOut = ScanReg[0];
  assign ScanEn = (AcState == AC_SCAN);
  genvar i;
  for (i=0; i<XLEN; i=i+1) begin
    always_ff @(posedge clk) begin
      if (Cycle == ShiftCount-1 && AcWrite) begin
        if (XLEN == 32)
          ScanReg[i] <= Data0[i];
        else if (XLEN == 64)
          ScanReg[i] <= {Data1,Data0}[i];
        else if (XLEN == 128)
          ScanReg[i] <= {Data3,Data2,Data1,Data0}[i];
      end else if (ScanEn)
        ScanReg[i] <= ScanReg[i+1];
    end
  end


  // Message Registers
  always_ff @(posedge clk) begin
    if (AcState == AC_SCAN) begin
      if (Cycle == ShiftCount && AcTransfer && ~AcWrite) // Read
        if (XLEN == 32)
          Data0 <= ScanReg;
        else if (XLEN == 64)
          {Data1,Data0} <= ScanReg;
        else if (XLEN == 128)
          {Data3,Data2,Data1,Data0} <= ScanReg;
        
    end else if (State == W_DATA && ~Busy) begin // TODO: should these be zeroed if rst?
      case (ReqAddress)
        `DATA0  : Data0 <= ReqData;
        `DATA1  : Data1 <= ReqData;
        `DATA2  : Data2 <= ReqData;
        `DATA3  : Data3 <= ReqData;
        //`DATA4  : Data4 <= ReqData;
        //`DATA5  : Data5 <= ReqData;
        //`DATA6  : Data6 <= ReqData;
        //`DATA7  : Data7 <= ReqData;
        //`DATA8  : Data8 <= ReqData;
        //`DATA9  : Data9 <= ReqData;
        //`DATA10 : Data10 <= ReqData;
        //`DATA11 : Data11 <= ReqData;
      endcase
    end
  end



  // Register decoder
  always_comb begin
    InvalidRegNo = 0;
    case (ReqData[`REGNO])
      `X1  : ShiftCount = `P_X1 * XLEN;
      `X2  : ShiftCount = `P_X2 * XLEN;
      `X3  : ShiftCount = `P_X3 * XLEN;
      `X4  : ShiftCount = `P_X4 * XLEN;
      `X5  : ShiftCount = `P_X5 * XLEN;
      `X6  : ShiftCount = `P_X6 * XLEN;
      `X7  : ShiftCount = `P_X7 * XLEN;
      `X8  : ShiftCount = `P_X8 * XLEN;
      `X9  : ShiftCount = `P_X9 * XLEN;
      `X10 : ShiftCount = `P_X10 * XLEN;
      `X11 : ShiftCount = `P_X11 * XLEN;
      `X12 : ShiftCount = `P_X12 * XLEN;
      `X13 : ShiftCount = `P_X13 * XLEN;
      `X14 : ShiftCount = `P_X14 * XLEN;
      `X15 : ShiftCount = `P_X15 * XLEN;
      `X16 : ShiftCount = `P_X16 * XLEN;
      `X17 : ShiftCount = `P_X17 * XLEN;
      `X18 : ShiftCount = `P_X18 * XLEN;
      `X19 : ShiftCount = `P_X19 * XLEN;
      `X20 : ShiftCount = `P_X20 * XLEN;
      `X21 : ShiftCount = `P_X21 * XLEN;
      `X22 : ShiftCount = `P_X22 * XLEN;
      `X23 : ShiftCount = `P_X23 * XLEN;
      `X24 : ShiftCount = `P_X24 * XLEN;
      `X25 : ShiftCount = `P_X25 * XLEN;
      `X26 : ShiftCount = `P_X26 * XLEN;
      `X27 : ShiftCount = `P_X27 * XLEN;
      `X28 : ShiftCount = `P_X28 * XLEN;
      `X29 : ShiftCount = `P_X29 * XLEN;
      `X30 : ShiftCount = `P_X30 * XLEN;
      `X31 : ShiftCount = `P_X31 * XLEN;
      default : begin
        ShiftCount = 'x;
        InvalidRegNo = 1;
      end
    endcase
  end

endmodule
