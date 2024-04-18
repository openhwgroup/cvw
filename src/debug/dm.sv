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
  input  logic [ADDR_WIDTH-1:0] ReqAddress,
  input  logic [31:0]           ReqData,
  input  logic [1:0]            ReqOP,
  input  logic                  RspReady,
  output logic                  RspValid,
  output logic [31:0]           RspData,
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

  enum {
    INACTIVE,
    IDLE,
    ACK,
    R_DATA,
    W_DATA,
    DMSTATUS,
    W_DMCONTROL,
    R_DMCONTROL,
    W_ABSTRACTCS,
    R_ABSTRACTCS,
    ABST_COMMAND,
    READ_ZERO,
    INVALID
  } State;

  enum {
    AC_IDLE,
    AC_SCAN
  } AcState, NewAcState;

  // AbsCmd internal state
  logic          AcWrite;
  logic          AcTransfer;
  logic [XLEN:0] ScanReg;
  logic [$clog2(SCAN_CHAIN_LEN)-1:0] ShiftCount, Cycle;

  // DMI
  logic                  NewCmd;
  logic [ADDR_WIDTH-1:0] NewCmdAddress;
  logic [31:0]           NewCmdData;
  logic [1:0]            NewCmdOP;
  logic                  CmdComplete;
  logic [31:0]           RspCmdData;
  logic [1:0]            RspCmdOP;

  // message registers
  logic [31:0] Data0;  //0x04
  logic [31:0] Data1;  //0x05
  logic [31:0] Data2;  //0x06
  logic [31:0] Data3;  //0x07
  if (XLEN == 64) begin // 
  end
  if (XLEN == 128) begin
  end

  // debug module registers
  logic [31:0] DMControl;  //0x10
  logic [31:0] DMStatus;   //0x11
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

  // DM register fields
  logic HaltReq;
  logic ResumeReq;
  logic HartReset;
  logic AckHaveReset;
  logic AckUnavail;
  const logic HaSel = 0;
  const logic [9:0] HartSelLo = 0;
  const logic [9:0] HartSelHi = 0;
  logic DmActive; // This bit is used to (de)activate the DM. Toggling acts as reset

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

  const logic [4:0] ProgBufSize = 0;
  logic Busy;
  logic RelaxedPriv; // TODO
  logic [2:0] CmdErr;
  const logic [3:0] DataCount = (XLEN/32);


  // Pack registers
  assign DMControl = {HaltReq, 1'b0, HartReset, 2'b0, HaSel, HartSelLo,
    HartSelHi, 4'b0, NdmReset, DmActive};

  assign DMStatus = {7'b0, NdmResetPending, StickyUnavail, ImpEBreak, 2'b0, 
    AllHaveReset, AnyHaveReset, AllResumeAck, AnyResumeAck, AllNonExistent, 
    AnyNonExistent, AllUnavail, AnyUnavail, AllRunning, AnyRunning, AllHalted, 
    AnyHalted, Authenticated, AuthBusy, HasResetHaltReq, ConfStrPtrValid, Version};

  assign AbstractCS = {3'b0, ProgBufSize, 11'b0, Busy, RelaxedPriv, CmdErr, 4'b0, DataCount};

  // translate internal state to hart connections
  assign CoreHalt = HaltReq;
  assign CoreResume = ResumeReq;
  assign CoreReset = HartReset;

  dmi #(.ADDR_WIDTH(ADDR_WIDTH)) dmi (.*);

  // DMI CmdComplete
  assign CmdComplete = (State == ACK);

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

          RspCmdOP <= `OP_FAILED;
          if (NewCmd && NewCmdAddress == `DMCONTROL && NewCmdOP == `OP_WRITE && NewCmdData[`DMACTIVE]) begin
            DmActive <= NewCmdData[`DMACTIVE];
            RspCmdOP <= `OP_SUCCESS;
            State <= ACK;
          end
        end

        ACK : begin
          NewAcState <= AC_IDLE;
          if (~NewCmd)
            State <= ~DmActive ? INACTIVE : IDLE;
        end

        IDLE : begin
          if (NewCmd)
            case ({NewCmdOP, NewCmdAddress}) inside
              [{`OP_WRITE,`DATA0}:{`OP_WRITE,`DATA11}] : State <= W_DATA;
              [{`OP_READ,`DATA0}:{`OP_READ,`DATA11}]   : State <= R_DATA;
              {`OP_WRITE,`DMCONTROL}                   : State <= W_DMCONTROL;
              {`OP_READ,`DMCONTROL}                    : State <= R_DMCONTROL;
              {`OP_READ,`DMSTATUS}                     : State <= DMSTATUS;
              {`OP_WRITE,`ABSTRACTCS}                  : State <= W_ABSTRACTCS;
              {`OP_READ,`ABSTRACTCS}                   : State <= R_ABSTRACTCS;
              {`OP_WRITE,`COMMAND}                     : State <= ABST_COMMAND;
              {`OP_READ,`COMMAND}                      : State <= READ_ZERO;
              {2'bx,`HARTINFO},
              {2'bx,`ABSTRACTAUTO},
              {2'bx,`NEXTDM}                           : State <= READ_ZERO;
              default                                  : State <= INVALID;
            endcase
        end

        R_DATA : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          case (NewCmdAddress)
            `DATA0  : RspCmdData <= Data0;
            `DATA1  : RspCmdData <= Data1;
            `DATA2  : RspCmdData <= Data2;
            `DATA3  : RspCmdData <= Data3;
            //`DATA4  : RspCmdData <= Data4;
            //`DATA5  : RspCmdData <= Data5;
            //`DATA6  : RspCmdData <= Data6;
            //`DATA7  : RspCmdData <= Data7;
            //`DATA8  : RspCmdData <= Data8;
            //`DATA9  : RspCmdData <= Data9;
            //`DATA10 : RspCmdData <= Data10;
            //`DATA11 : RspCmdData <= Data11;
          endcase
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        W_DATA : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        W_DMCONTROL : begin
          HaltReq <= NewCmdData[`HALTREQ];
          AckUnavail <= NewCmdData[`ACKUNAVAIL];
          NdmReset <= NewCmdData[`NDMRESET];
          DmActive <= NewCmdData[`DMACTIVE]; // Writing 0 here resets the DM
          RspCmdOP <= `OP_SUCCESS;

          // Can only write one of the following at a time
          case ({NewCmdData[`RESUMEREQ],NewCmdData[`HARTRESET],NewCmdData[`ACKHAVERESET],
            NewCmdData[`SETRESETHALTREQ],NewCmdData[`CLRRESETHALTREQ]})
            5'b10000 : ResumeReq <= HartReset ? 0 : 1; // TODO deassert automatically // TODO clear local ResumeACK
            5'b01000 : HartReset <= NewCmdData[`HARTRESET];
            //5'b00100 : HaveReset <= 0; // TODO: clear havereset (resetconfirm)
            5'b00010 : CoreHaltOnReset <= 1;
            5'b00001 : CoreHaltOnReset <= 0;
            default : begin // Failure, dont write any changes
              HaltReq <= HaltReq;
              AckUnavail <= AckUnavail;
              NdmReset <= NdmReset;
              DmActive <= DmActive;
              RspCmdOP <= `OP_FAILED;
            end
          endcase

          State <= ACK;
        end

        R_DMCONTROL : begin
          RspCmdData <= DMControl;
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        DMSTATUS : begin
          RspCmdData <= DMStatus;
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        W_ABSTRACTCS : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          else begin
            RelaxedPriv <= NewCmdData[`RELAXEDPRIV];
            CmdErr <= NewCmdData[`CMDERR] ? `CMDERR_NONE : CmdErr;
          end
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        R_ABSTRACTCS : begin
          RspCmdData <= AbstractCS;
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        ABST_COMMAND : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          else
            case (NewCmdData[`CMDTYPE])
              `ACCESS_REGISTER : begin // TODO: check that hart is halted else cmderr <= `CMDERR_HALTRESUME
                if (NewCmdData[`AARSIZE] > XLEN) begin // TODO: make sure smaller sizes are supported
                  CmdErr <= `CMDERR_EXCEPTION;
                end else if (NewCmdData[`TRANSFER]) begin
                  ShiftCount <= 64; // TODO: calcualte this based on regno NewCmdData[`REGNO]
                  // if REGNO does not exist, cmderr <= `CMDERR_EXCEPTION;
                  AcTransfer <= NewCmdData[`TRANSFER];
                  AcWrite <= NewCmdData[`AARWRITE];
                  NewAcState <= AC_SCAN;
                end
              end
              //`QUICK_ACCESS : State <= QUICK_ACCESS;
              //`ACCESS_MEMORY : State <= ACCESS_MEMORY;
              default : CmdErr <= `CMDERR_NOT_SUPPORTED;
            endcase
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        READ_ZERO : begin // Writes ignored, Read Zero
          RspCmdData <= 0;
          RspCmdOP <= `OP_SUCCESS;
          State <= ACK;
        end

        INVALID : begin
          RspCmdOP <= `OP_FAILED;
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
      case (NewCmdAddress)
        `DATA0  : Data0 <= NewCmdData;
        `DATA1  : Data1 <= NewCmdData;
        `DATA2  : Data2 <= NewCmdData;
        `DATA3  : Data3 <= NewCmdData;
        //`DATA4  : Data4 <= NewCmdData;
        //`DATA5  : Data5 <= NewCmdData;
        //`DATA6  : Data6 <= NewCmdData;
        //`DATA7  : Data7 <= NewCmdData;
        //`DATA8  : Data8 <= NewCmdData;
        //`DATA9  : Data9 <= NewCmdData;
        //`DATA10 : Data10 <= NewCmdData;
        //`DATA11 : Data11 <= NewCmdData;
      endcase
    end
  end

endmodule
