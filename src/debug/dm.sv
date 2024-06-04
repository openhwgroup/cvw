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
  input  logic                     clk, 
  input  logic                     rst,

  // External JTAG signals
  input  logic                     tck,
  input  logic                     tdi,
  input  logic                     tms,
  output logic                     tdo,

  // Platform reset signal
  output logic                     NdmReset,
  // Core hazard signal
  output logic                     DebugStall,

  // Scan Chain
  output logic                     ScanEn,
  input  logic                     ScanIn,
  output logic                     ScanOut,
  output logic                     GPRSel,
  output logic                     DebugCapture,
  output logic                     DebugGPRUpdate,
  output logic [P.E_SUPPORTED+3:0] GPRAddr,
  output logic                     GPRScanEn,
  input  logic                     GPRScanIn,
  output logic                     GPRScanOut
);
  `include "debug.vh"

  // DMI Signals
  logic                   ReqReady;
  logic                   ReqValid;
  logic [`ADDR_WIDTH-1:0] ReqAddress;
  logic [31:0]            ReqData;
  logic [1:0]             ReqOP;
  logic                   RspReady;
  logic                   RspValid;
  logic [31:0]            RspData;
  logic [1:0]             RspOP;

  // JTAG ID:  [31:27] ver [27:12] part number [11:1] JEDEC number [0] set to 1
  localparam JTAG_DEVICE_ID = 32'h1000_1005; 

  dtm #(`ADDR_WIDTH, JTAG_DEVICE_ID) dtm (.clk, .tck, .tdi, .tms, .tdo,
    .ReqReady, .ReqValid, .ReqAddress, .ReqData, .ReqOP, .RspReady,
    .RspValid, .RspData, .RspOP);

  // Core control signals
  logic                  HaltReq;
  logic                  ResumeReq;
  logic                  HaltOnReset;
  logic                  Halted;

  hartcontrol hartcontrol(.clk, .rst(rst | ~DmActive), .NdmReset, .HaltReq,
    .ResumeReq, .HaltOnReset, .DebugStall, .Halted, .AllRunning,
    .AnyRunning, .AllHalted, .AnyHalted, .AllResumeAck, .AnyResumeAck);


  enum logic [3:0] {INACTIVE, IDLE, ACK, R_DATA, W_DATA, DMSTATUS, W_DMCONTROL, R_DMCONTROL, 
		    W_ABSTRACTCS, R_ABSTRACTCS, ABST_COMMAND, R_SYSBUSCS, READ_ZERO,
		    INVALID} State;

  enum logic [1:0] {AC_IDLE, AC_GPRUPDATE, AC_SCAN, AC_CAPTURE} AcState, NewAcState;

  // AbsCmd internal state
  logic              AcWrite;        // Abstract Command write state
  logic [P.XLEN:0]   ScanReg;        // The part of the debug scan chain located within DM
  logic [P.XLEN-1:0] ScanNext;       // New ScanReg value
  logic [P.XLEN-1:0] ARMask;         // Masks which bits of the ScanReg get updated
  logic [P.XLEN-1:0] PackedDataReg;  // Combines DataX msg registers into a single XLEN wide register
  logic [P.XLEN-1:0] MaskedScanReg;  // Masks which bits of the ScanReg get written to DataX
  logic [9:0]        ShiftCount;     // Position of the selected register on the debug scan chain
  logic [9:0]        ScanChainLen;   // Total length of currently selected scan chain
  logic [9:0]        Cycle;          // DM's current position in the scan chain
  logic              InvalidRegNo;   // Requested RegNo is invalid
  logic              RegReadOnly;    // Current RegNo points to a readonly register
  logic              GPRRegNo;       // Requested RegNo is a GPR
  logic              StoreScanChain; // Store current value of ScanReg into DataX
  logic              WriteMsgReg;    // Write to DataX
  logic              WriteScanReg;   // Insert data from DataX into ScanReg
  logic [31:0]       Data0Wr;        // Muxed inputs to DataX regs
  logic [31:0]       Data1Wr;        // Muxed inputs to DataX regs
  logic [31:0]       Data2Wr;        // Muxed inputs to DataX regs
  logic [31:0]       Data3Wr;        // Muxed inputs to DataX regs
  // message registers
  logic [31:0] Data0;  // 0x04
  logic [31:0] Data1;  // 0x05
  logic [31:0] Data2;  // 0x06
  logic [31:0] Data3;  // 0x07

  // debug module registers
  logic [31:0] DMControl;  // 0x10
  logic [31:0] DMStatus;   // 0x11
  logic [31:0] AbstractCS; // 0x16
  logic [31:0] SysBusCS;   // 0x38

  //// DM register fields
  // DMControl
  logic AckUnavail;
  logic DmActive; // This bit is used to (de)activate the DM. Toggling acts as reset
  // DMStatus
  logic StickyUnavail;
  logic ImpEBreak;
  logic AllResumeAck;
  logic AnyResumeAck;
  logic AllNonExistent;
  logic AnyNonExistent;
  logic AllUnavail; // TODO
  logic AnyUnavail;
  logic AllRunning;
  logic AnyRunning;
  logic AllHalted;
  logic AnyHalted;
  const logic Authenticated = 1;
  logic AuthBusy;
  const logic HasResetHaltReq = 1;
  logic ConfStrPtrValid;
  const logic [3:0] Version = 3; // DM Version
  // AbstractCS
  const logic [4:0] ProgBufSize = 0;
  logic Busy;
  const logic RelaxedPriv = 1;
  logic [2:0] CmdErr;
  const logic [3:0] DataCount = (P.XLEN/32);


  // Pack registers
  assign DMControl = {2'b0, 1'b0, 2'b0, 1'b0, 10'b0,
    10'b0, 4'b0, NdmReset, DmActive};

  assign DMStatus = {7'b0, 1'b0, StickyUnavail, ImpEBreak, 2'b0, 
    2'b0, AllResumeAck, AnyResumeAck, AllNonExistent, 
    AnyNonExistent, AllUnavail, AnyUnavail, AllRunning, AnyRunning, AllHalted, 
    AnyHalted, Authenticated, AuthBusy, HasResetHaltReq, ConfStrPtrValid, Version};

  assign AbstractCS = {3'b0, ProgBufSize, 11'b0, Busy, RelaxedPriv, CmdErr, 4'b0, DataCount};

  assign SysBusCS = 32'h20000000; // SBVersion = 1

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
          HaltOnReset <= 0;
          NdmReset <= 0;
          StickyUnavail <= 0;
          ImpEBreak <= 0;
          AuthBusy <= 0;
          ConfStrPtrValid <= 0;
          CmdErr <= 0;
          if (ReqValid) begin
            if (ReqAddress == `DMCONTROL & ReqOP == `OP_WRITE & ReqData[`DMACTIVE]) begin
              DmActive <= ReqData[`DMACTIVE];
              RspOP <= `OP_SUCCESS;
            end
            State <= ACK; // acknowledge all Reqs even if they don't activate DM
          end
        end

        ACK : begin
          NewAcState <= AC_IDLE;
          ResumeReq <= 0;
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
          // While an abstract command is executing (busy in abstractcs is high), a debugger must not change
          // hartsel, and must not write 1 to haltreq, resumereq, ackhavereset, setresethaltreq, or clrresethaltreq
          if (Busy & (ReqData[`HALTREQ] | ReqData[`RESUMEREQ] | ReqData[`SETRESETHALTREQ] | ReqData[`CLRRESETHALTREQ]))
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          else begin
            HaltReq <= ReqData[`HALTREQ];
            AckUnavail <= ReqData[`ACKUNAVAIL];
            NdmReset <= ReqData[`NDMRESET];
            DmActive <= ReqData[`DMACTIVE]; // Writing 0 here resets the DM
            
            // On any given write, a debugger may only write 1 to at most one of the following bits: resumereq,
            //  hartreset, ackhavereset, setresethaltreq, and clrresethaltreq. The others must be written 0
            case ({ReqData[`RESUMEREQ],ReqData[`SETRESETHALTREQ],ReqData[`CLRRESETHALTREQ]})
              3'b000 :; // None
              3'b100 : ResumeReq <= 1;
              3'b010 : HaltOnReset <= 1;
              3'b001 : HaltOnReset <= 0;
              default : begin // Invalid (not onehot), dont write any changes
                HaltReq <= HaltReq;
                AckUnavail <= AckUnavail;
                NdmReset <= NdmReset;
                DmActive <= DmActive;
              end
            endcase
          end
        
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
          else
            CmdErr <= |ReqData[`CMDERR] ? `CMDERR_NONE : CmdErr; // clear CmdErr
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        R_ABSTRACTCS : begin
          RspData <= AbstractCS;
          RspOP <= `OP_SUCCESS;
          State <= ACK;
        end

        ABST_COMMAND : begin
          if (CmdErr != `CMDERR_NONE); // If CmdErr, do nothing
          else if (Busy)
            CmdErr <= `CMDERR_BUSY; // If Busy, set CmdErr, do nothing
          else if (~Halted)
            CmdErr <= `CMDERR_HALTRESUME; // If not halted, set CmdErr, do nothing
          else begin
            case (ReqData[`CMDTYPE])
              `ACCESS_REGISTER : begin
                if (ReqData[`AARSIZE] > $clog2(P.XLEN/8)) // if AARSIZE (encoded) is greater than P.XLEN, set CmdErr, do nothing
                  CmdErr <= `CMDERR_BUS;
                else if (~ReqData[`TRANSFER]); // If not TRANSFER, do nothing
                else if (InvalidRegNo)
                  CmdErr <= `CMDERR_EXCEPTION; // If InvalidRegNo, set CmdErr, do nothing
                else if (ReqData[`AARWRITE] & RegReadOnly)
                  CmdErr <= `CMDERR_NOT_SUPPORTED; // If writing to a read only register, set CmdErr, do nothing
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
            AC_SCAN : AcState <= ~AcWrite ? AC_CAPTURE : AC_SCAN;
          endcase
        end

        AC_CAPTURE : begin
          AcState <= AC_SCAN;
        end

        AC_SCAN : begin
          if (Cycle == ScanChainLen)
            AcState <= (GPRRegNo & AcWrite) ? AC_GPRUPDATE : AC_IDLE;
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
  assign DebugCapture = (AcState == AC_CAPTURE);
  assign DebugGPRUpdate = (AcState == AC_GPRUPDATE);

  // Scan Chain
  assign GPRSel = GPRRegNo & (AcState != AC_IDLE);
  assign ScanReg[P.XLEN] = GPRSel ? GPRScanIn : ScanIn;
  assign ScanOut = GPRSel ? 1'b0 : ScanReg[0];
  assign GPRScanOut = GPRSel ? ScanReg[0] : 1'b0;
  assign ScanEn = ~GPRSel & (AcState == AC_SCAN);
  assign GPRScanEn = GPRSel & (AcState == AC_SCAN);  
  
  // Load data from message registers into scan chain
  if (P.XLEN == 32)
    assign PackedDataReg = Data0;
  else if (P.XLEN == 64)
    assign PackedDataReg = {Data1,Data0};
  else if (P.XLEN == 128)
    assign PackedDataReg = {Data3,Data2,Data1,Data0};
  
  assign WriteScanReg = AcWrite & (~GPRRegNo & (Cycle == ShiftCount) | GPRRegNo & (Cycle == 0));
  genvar i;
  for (i=0; i<P.XLEN; i=i+1) begin
    // ARMask is used as write enable for subword overwrites (basic mask would overwrite neighbors in the chain)
    assign ScanNext[i] = WriteScanReg & ARMask[i] ? PackedDataReg[i] : ScanReg[i+1];
    flopenr #(1) scanreg (.clk, .reset(rst), .en(AcState == AC_SCAN), .d(ScanNext[i]), .q(ScanReg[i]));
  end
  
  // Message Registers
  assign MaskedScanReg = ARMask & ScanReg[P.XLEN:1];
  assign WriteMsgReg = (State == W_DATA) & ~Busy;
  assign StoreScanChain = (AcState == AC_SCAN) & (Cycle == ShiftCount) & ~AcWrite;
  
  assign Data0Wr = StoreScanChain ? MaskedScanReg[31:0] : ReqData;;
  flopenr #(32) data0reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA0)), .d(Data0Wr), .q(Data0));
  if (P.XLEN >= 64) begin
    assign Data1Wr = StoreScanChain ?  MaskedScanReg[63:32] : ReqData;
    flopenr #(32) data1reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA1)), .d(Data1Wr), .q(Data1));
  end 
  if (P.XLEN == 128) begin
    assign Data2Wr = StoreScanChain ?  MaskedScanReg[95:64] : ReqData;
    assign Data3Wr = StoreScanChain ?  MaskedScanReg[127:96] : ReqData;
    flopenr #(32) data2reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA2)), .d(Data2Wr), .q(Data2));
    flopenr #(32) data3reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA3)), .d(Data3Wr), .q(Data3));
  end

  rad #(P) regnodecode(.AarSize(ReqData[`AARSIZE]),.Regno(ReqData[`REGNO]),.GPRRegNo,.ScanChainLen,.ShiftCount,.InvalidRegNo,.RegReadOnly,.GPRAddr,.ARMask);

endmodule
