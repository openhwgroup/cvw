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

// TODO List:
// Ignore wfi instructions in debug mode (overwrite with NOP?)
// mask all interrupts/ignore all traps (except ebreak) in debug mode
// capture CSR read/write failures as convert them to cmderr


module dm import cvw::*; #(parameter cvw_t P) (
  input  logic            clk, 
  input  logic            rst,

  // External JTAG signals
  input  logic            tck,
  input  logic            tdi,
  input  logic            tms,
  output logic            tdo,

  // Platform reset signal
  output logic            NdmReset,
  // Core control signals
  input  logic            ResumeAck,      // Signals Hart has been resumed
  input  logic            HaveReset,      // Signals Hart has been reset
  input  logic            DebugStall,     // Signals core is halted
  output logic            HaltReq,        // Initiates core halt
  output logic            ResumeReq,      // Initiates core resume
  output logic            HaltOnReset,    // Halts core immediately on hart reset
  output logic            AckHaveReset,   // Clears HaveReset status

  // Scan Chain
  output logic            DebugScanEn,    // puts scannable flops into scan mode
  input  logic            DebugScanIn,    // (misc) scan chain data in
  input  logic            GPRScanIn,      // (GPR) scan chain data in
  input  logic            FPRScanIn,      // (FPR) scan chain data in
  input  logic            CSRScanIn,      // (CSR) scan chain data in
  output logic            DebugScanOut,   // scan chain data out
  output logic            MiscSel,        // selects general scan chain
  output logic            GPRSel,         // selects GPR scan chain
  output logic            FPRSel,         // selects FPR scan chain
  output logic            CSRSel,         // selects CSR scan chain
  output logic [11:0]     RegAddr,        // address for scanable regfiles (GPR, FPR, CSR)
  output logic            DebugCapture,   // latches values into scan register before scanning out
  output logic            DebugRegUpdate, // writes values from scan register after scanning in			
  
  // Program Buffer
  output logic [$clog2(PROGBUF_SIZE)-1:0]      ProgBufAddr,
  output logic            ProgBuffScanEn,
  output logic            ExecProgBuf
);
  `include "debug.vh"

  localparam PROGBUF_SIZE = (P.PROGBUF_RANGE+1)/4;
  localparam DATA_COUNT = (P.LLEN/32);
  localparam AARSIZE_ENC = $clog2(P.LLEN/8);

  // DMI Signals
  logic                       ReqReady;
  logic                       ReqValid;
  logic [`DMI_ADDR_WIDTH-1:0] ReqAddress;
  logic [31:0]                ReqData;
  logic [1:0]                 ReqOP;
  logic                       RspReady;
  logic                       RspValid;
  logic [31:0]                RspData;
  logic [1:0]                 RspOP;

  // JTAG ID for Wally:  
  // Version [31:28] = 0x1 : 0001
  // PartNumber [27:12] = 0x2A : Wally (00000000_00101010)
  // JEDEC number [11:1] = 0x602 : Bank 13 (1100) Open HW Group (0000010) 
  // [0] = 1
  localparam JTAG_DEVICE_ID = 32'h1002AC05; 

  dtm #(`DMI_ADDR_WIDTH, JTAG_DEVICE_ID) dtm (.clk, .rst, .tck, .tdi, .tms, .tdo,
    .ReqReady, .ReqValid, .ReqAddress, .ReqData, .ReqOP, .RspReady,
    .RspValid, .RspData, .RspOP);

  enum logic [3:0] {INACTIVE, IDLE, ACK, R_DATA, W_DATA, DMSTATUS, W_DMCONTROL, R_DMCONTROL, 
		    W_ABSTRACTCS, R_ABSTRACTCS, ABST_COMMAND, R_SYSBUSCS, W_PROGBUF, READ_ZERO,
		    INVALID, EXEC_PROGBUF} State;

  enum logic [2:0] {AC_IDLE, AC_UPDATE, AC_SCAN, AC_CAPTURE, PROGBUFF_WRITE} AcState, NewAcState;

  // AbsCmd internal state
  logic              AcWrite;        // Abstract Command write state
  logic [P.LLEN:0]   ScanReg;        // The part of the debug scan chain located within DM
  logic [P.LLEN-1:0] ScanNext;       // New ScanReg value
  logic [P.LLEN-1:0] ARMask;         // Masks which bits of the ScanReg get updated
  logic [P.LLEN-1:0] PackedDataReg;  // Combines DataX msg registers into a single LLEN wide register
  logic [P.LLEN-1:0] MaskedScanReg;  // Masks which bits of the ScanReg get written to DataX
  logic [9:0]        ShiftCount;     // Position of the selected register on the debug scan chain
  logic [9:0]        ScanChainLen;   // Total length of currently selected scan chain
  logic [9:0]        Cycle;          // DM's current position in the scan chain
  logic              InvalidRegNo;   // Requested RegNo is invalid
  logic              RegReadOnly;    // Current RegNo points to a readonly register
  logic              MiscRegNo;      // Requested RegNo is on the Misc scan chain
  logic              GPRegNo;        // Requested RegNo is a GPR
  logic              FPRegNo;        // Requested RegNo is a FPR
  logic              CSRegNo;        // Requested RegNo is a CSR
  logic              StoreScanChain; // Store current value of ScanReg into DataX
  logic              WriteMsgReg;    // Write to DataX
  logic              WriteScanReg;   // Insert data from DataX into ScanReg
  logic              WriteProgBuff;  // Insert data from DMI into ScanReg
  logic [31:0]       Data0Wr;        // Muxed inputs to DataX regs
  logic [31:0]       Data1Wr;        // Muxed inputs to DataX regs
  logic [31:0]       Data2Wr;        // Muxed inputs to DataX regs
  logic [31:0]       Data3Wr;        // Muxed inputs to DataX regs
  // message registers
  logic [31:0]       Data0;          // 0x04
  logic [31:0]       Data1;          // 0x05
  logic [31:0]       Data2;          // 0x06
  logic [31:0]       Data3;          // 0x07

  // debug module registers
  logic [31:0]       DMControl;      // 0x10
  logic [31:0]       DMStatus;       // 0x11
  logic [31:0]       AbstractCS;     // 0x16
  logic [31:0]       SysBusCS;       // 0x38

  //// DM register fields
  // DMControl
  logic              AckUnavail;
  logic              DmActive;       // This bit is used to (de)activate the DM. Toggling off-on acts as reset
  // DMStatus
  const logic        NdmResetPending = 0;
  const logic        StickyUnavail = 0;
  const logic        ImpEBreak = 0;
  logic              AllHaveReset;
  logic              AnyHaveReset;
  logic              AllResumeAck;
  logic              AnyResumeAck;
  const logic        AllNonExistent = 0;
  const logic        AnyNonExistent = 0;
  const logic        AllUnavail = 0;
  const logic        AnyUnavail = 0;
  logic              AllRunning;
  logic              AnyRunning;
  logic              AllHalted;
  logic              AnyHalted;
  const logic        Authenticated = 1;
  const logic        AuthBusy = 0;
  const logic        HasResetHaltReq = 1;
  const logic        ConfStrPtrValid = 0; // Used with SysBusAccess
  const logic [3:0]  Version = 3;    // DM Version
  // AbstractCS
  const logic [4:0]  ProgBufSize = PROGBUF_SIZE[4:0];
  logic              Busy;
  const logic        RelaxedPriv = 1;
  logic [2:0]        CmdErr;
  const logic [3:0]  DataCount = DATA_COUNT[3:0];

  // Core control signals
  assign AllHaveReset = HaveReset;
  assign AnyHaveReset = HaveReset;
  assign AnyHalted = DebugStall;
  assign AllHalted = DebugStall;
  assign AnyRunning = ~DebugStall;
  assign AllRunning = ~DebugStall;
  // I believe resumeack is used to determine when a resume is requested but never completes
  // It's pretty worthless in this implementation (complain to the riscv debug working group)
  assign AllResumeAck = ResumeAck;
  assign AnyResumeAck = ResumeAck;
  
  assign DMControl = {2'b0, 1'b0, 2'b0, 1'b0, 10'b0, 10'b0, 4'b0, NdmReset, DmActive};

  assign DMStatus = {7'b0, NdmResetPending, StickyUnavail, ImpEBreak, 2'b0, 
    AllHaveReset, AnyHaveReset, AllResumeAck, AnyResumeAck, AllNonExistent, 
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
        default : begin  // INACTIVE
          // Reset Values
          {HaltReq, ResumeReq, AckHaveReset, HaltOnReset, NdmReset} <= 0;
          RspData <= 0;
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
          AckHaveReset <= 0;
          if (~ReqValid)
            State <= ~DmActive ? INACTIVE : IDLE;
        end

        IDLE : begin
          if (ReqValid)
            case ({ReqOP, ReqAddress}) inside
              {`OP_WRITE,`DATA0}                            : State <= W_DATA;
              {`OP_READ,`DATA0}                             : State <= R_DATA;
              {`OP_WRITE,`DATA1}                            : State <= (P.LLEN >= 64) ? W_DATA : INVALID;
              {`OP_READ,`DATA1}                             : State <= (P.LLEN >= 64) ? R_DATA : INVALID;
              [{`OP_WRITE,`DATA2}:{`OP_WRITE,`DATA3}]       : State <= (P.LLEN >= 128) ? W_DATA : INVALID;
              [{`OP_READ,`DATA2}:{`OP_READ,`DATA3}]         : State <= (P.LLEN >= 128) ? R_DATA : INVALID;
              {`OP_WRITE,`DMCONTROL}                        : State <= W_DMCONTROL;
              {`OP_READ,`DMCONTROL}                         : State <= R_DMCONTROL;
              {`OP_READ,`DMSTATUS}                          : State <= DMSTATUS;
              {`OP_WRITE,`ABSTRACTCS}                       : State <= W_ABSTRACTCS;
              {`OP_READ,`ABSTRACTCS}                        : State <= R_ABSTRACTCS;
              {`OP_WRITE,`COMMAND}                          : State <= ABST_COMMAND;
              {`OP_READ,`COMMAND}                           : State <= READ_ZERO;
              {`OP_WRITE,`SBCS}                             : State <= READ_ZERO;
              {`OP_READ,`SBCS}                              : State <= R_SYSBUSCS;
              [{`OP_WRITE,`PROGBUF0}:{`OP_WRITE,`PROGBUF3}] : State <= W_PROGBUF; // TODO: update decode range dynamically using PROGBUF_RANGE
              [{`OP_READ,`PROGBUF0}:{`OP_READ,`PROGBUFF}],
              {2'b??,`HARTINFO},
              {2'b??,`ABSTRACTAUTO},
              {2'b??,`NEXTDM}                               : State <= READ_ZERO;
              default                                       : State <= INVALID;
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
            default : RspData <= 32'b0;
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
          if (Busy & (ReqData[`HALTREQ] | ReqData[`RESUMEREQ] | ReqData[`ACKHAVERESET] | ReqData[`SETRESETHALTREQ] | ReqData[`CLRRESETHALTREQ]))
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          else begin
            HaltReq <= ReqData[`HALTREQ];
            AckUnavail <= ReqData[`ACKUNAVAIL];
            NdmReset <= ReqData[`NDMRESET];
            DmActive <= ReqData[`DMACTIVE]; // Writing 0 here resets the DM
            
            // On any given write, a debugger may only write 1 to at most one of the following bits: resumereq,
            //  hartreset, ackhavereset, setresethaltreq, and clrresethaltreq. The others must be written 0
            case ({ReqData[`RESUMEREQ],ReqData[`ACKHAVERESET],ReqData[`SETRESETHALTREQ],ReqData[`CLRRESETHALTREQ]})
              4'b0000 :; // None
              4'b1000 : ResumeReq <= ~ReqData[`HALTREQ]; // Ignore ResumeReq if HaltReq
              4'b0100 : AckHaveReset <= 1;
              4'b0010 : HaltOnReset <= 1;
              4'b0001 : HaltOnReset <= 0;
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
          RspOP <= `OP_SUCCESS;
          State <= ACK;

          if (CmdErr != `CMDERR_NONE); // If CmdErr, do nothing
          else if (Busy)
            CmdErr <= `CMDERR_BUSY; // If Busy, set CmdErr, do nothing
          else if (~DebugStall)
            CmdErr <= `CMDERR_HALTRESUME; // If not halted, set CmdErr, do nothing
          else begin
            case (ReqData[`CMDTYPE])
              `ACCESS_REGISTER : begin
                if (~ReqData[`TRANSFER])
                  State <= ReqData[`POSTEXEC] ? EXEC_PROGBUF : ACK;  // If not transfer, exec progbuf or do nothing
                else if (ReqData[`AARSIZE] > AARSIZE_ENC[2:0])
                  CmdErr <= `CMDERR_BUS;                             // If AARSIZE (encoded) is greater than P.LLEN, set CmdErr, do nothing
                else if (InvalidRegNo)
                  CmdErr <= `CMDERR_EXCEPTION;                       // If InvalidRegNo, set CmdErr, do nothing
                else if (ReqData[`AARWRITE] & RegReadOnly)
                  CmdErr <= `CMDERR_NOT_SUPPORTED;                   // If writing to a read only register, set CmdErr, do nothing
                else begin
                  AcWrite <= ReqData[`AARWRITE];
                  NewAcState <= ~ReqData[`AARWRITE] ? AC_CAPTURE : AC_SCAN;
                  State <= ReqData[`POSTEXEC] ? EXEC_PROGBUF : ACK;
                end
              end
              //`QUICK_ACCESS : State <= QUICK_ACCESS;
              //`ACCESS_MEMORY : State <= ACCESS_MEMORY;
              default : CmdErr <= `CMDERR_NOT_SUPPORTED;
            endcase
          end
        end

        W_PROGBUF : begin
          if (Busy)
            CmdErr <= ~|CmdErr ? `CMDERR_BUSY : CmdErr;
          else begin
            NewAcState <= PROGBUFF_WRITE;
            ProgBufAddr <= ReqAddress[$clog2(PROGBUF_SIZE)-1:0];
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
          RspOP <= `OP_SUCCESS;  // openocd cannot recover from `OP_FAILED;
          State <= ACK;
        end

        EXEC_PROGBUF : begin
          NewAcState <= AC_IDLE;
          if (~Busy)
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
          AcState <= NewAcState;
        end

        AC_CAPTURE : begin
          AcState <= AC_SCAN;
        end

        AC_SCAN : begin
          if (~MiscRegNo & AcWrite & (Cycle == ScanChainLen)) // Writes to CSR/GPR/FPR are shifted in len(CSR/GPR) or len(FPR) cycles
            AcState <= AC_UPDATE;
          else if (~MiscRegNo & ~AcWrite & (Cycle == P.LLEN[9:0])) // Reads from CSR/GPR/FPR are shifted in len(ScanReg) cycles
            AcState <= AC_IDLE;
          else if (MiscRegNo & (Cycle == ScanChainLen)) // Misc scanchain must be scanned completely
            AcState <= AC_IDLE;
          else
            Cycle <= Cycle + 1;
        end

        AC_UPDATE : begin
          AcState <= AC_IDLE;
        end

        PROGBUFF_WRITE : begin
          if (Cycle == 32)
            AcState <= AC_IDLE;
          else
            Cycle <= Cycle + 1;
        end

        default:;
      endcase
    end
  end

  assign Busy = ~(AcState == AC_IDLE);
  assign ExecProgBuf = (State == EXEC_PROGBUF) & ~Busy;

  // Program Buffer
  assign ProgBuffScanEn = (AcState == PROGBUFF_WRITE);

  // Scan Chain
  assign DebugScanOut = ScanReg[0];
  assign DebugScanEn = (AcState == AC_SCAN);
  assign DebugCapture = (AcState == AC_CAPTURE);
  assign DebugRegUpdate = (AcState == AC_UPDATE);

  assign MiscRegNo = ~(CSRegNo | GPRegNo | FPRegNo);
  assign MiscSel = MiscRegNo & (AcState != AC_IDLE);
  assign CSRSel = CSRegNo & (AcState != AC_IDLE);
  assign GPRSel = GPRegNo & (AcState != AC_IDLE);
  assign FPRSel = FPRegNo & (AcState != AC_IDLE);


  always_comb begin
    case ({CSRSel, GPRSel, FPRSel})
      3'b100  : ScanReg[P.LLEN] = CSRScanIn;
      3'b010  : ScanReg[P.LLEN] = GPRScanIn;
      3'b001  : ScanReg[P.LLEN] = FPRScanIn;
      default : ScanReg[P.LLEN] = DebugScanIn;
    endcase
  end
  
  if (P.LLEN == 32)
    assign PackedDataReg = Data0;
  else if (P.LLEN == 64)
    assign PackedDataReg = {Data1,Data0};
  else if (P.LLEN == 128)
    assign PackedDataReg = {Data3,Data2,Data1,Data0};
  
  // Load data from DMI into scan chain
  assign WriteProgBuff = (AcState == PROGBUFF_WRITE) & (Cycle == 0);
  // Load data from message registers into scan chain
  assign WriteScanReg = AcWrite & (MiscRegNo & (Cycle == ShiftCount) | ~MiscRegNo & (Cycle == 0));
  genvar i;
  for (i=0; i<P.LLEN; i=i+1) begin
    // ARMask is used as write enable for subword overwrites (basic mask would overwrite neighbors in the chain)
    if (i < 32)
      assign ScanNext[i] = WriteProgBuff ? ReqData[i] : WriteScanReg & ARMask[i] ? PackedDataReg[i] : ScanReg[i+1];
    else
      assign ScanNext[i] = WriteScanReg & ARMask[i] ? PackedDataReg[i] : ScanReg[i+1];
    flopenr #(1) scanreg (.clk, .reset(rst), .en(DebugScanEn | ProgBuffScanEn), .d(ScanNext[i]), .q(ScanReg[i]));
  end
  
  // Message Registers
  assign MaskedScanReg = ARMask & ScanReg[P.LLEN:1];
  assign WriteMsgReg = (State == W_DATA) & ~Busy;
  assign StoreScanChain = (AcState == AC_SCAN) & (Cycle == ShiftCount) & ~AcWrite;
  
  assign Data0Wr = WriteMsgReg ? ReqData : MaskedScanReg[31:0];
  flopenr #(32) data0reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA0)), .d(Data0Wr), .q(Data0));
  if (P.LLEN >= 64) begin
    assign Data1Wr = WriteMsgReg ? ReqData : MaskedScanReg[63:32];
    flopenr #(32) data1reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA1)), .d(Data1Wr), .q(Data1));
  end else
    assign Data1 = '0;
  if (P.LLEN == 128) begin
    assign Data2Wr = WriteMsgReg ? ReqData : MaskedScanReg[95:64];
    assign Data3Wr = WriteMsgReg ? ReqData : MaskedScanReg[127:96];
    flopenr #(32) data2reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA2)), .d(Data2Wr), .q(Data2));
    flopenr #(32) data3reg (.clk, .reset(rst), .en(StoreScanChain | WriteMsgReg & (ReqAddress == `DATA3)), .d(Data3Wr), .q(Data3));
  end else
    assign {Data3,Data2} = '0;

  rad #(P) regnodecode(.AarSize(ReqData[`AARSIZE]),.Regno(ReqData[`REGNO]),.CSRegNo,.GPRegNo,.FPRegNo,.ScanChainLen,.ShiftCount,.InvalidRegNo,.RegReadOnly,.RegAddr,.ARMask);

endmodule
