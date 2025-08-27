///////////////////////////////////////////
// dm.sv
//
// Written: Jacob Pease jacobpease@protonmail.com,
//          James E. Stine james.stine@okstate.edu
// Created: August 12th, 2025
// Modified: 
//
// Purpose: The Debug Module (DM)
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "debug.vh"

module dm(
   input logic         clk,
   input logic         rst,
          
   // Currently implementing NeoRV32 signals. Subject to change if I
   // prefer a different DMI.
   input               dmi_req_t dmi_req,
   output              dmi_rsp_t dmi_rsp,
   
   // CPU Signals
   output logic        NDMReset,
   output logic        HaltReq,
   output logic        ResumeReq,
   input logic         DebugMode,
   output logic        DebugControl,
   
   // Reading and Writing Registers
   input logic [31:0]  RegIn,
   output logic [31:0] RegOut,
   output logic [4:0]  RegAddr,
   output logic        DebugRegWrite
);

   typedef enum logic [6:0] {
      DATA0 = 7'h04,       
      DATA1 = 7'h05,       
      DATA2 = 7'h06,       
      DATA3 = 7'h07,       
      DATA4 = 7'h08,       
      DATA5 = 7'h09,       
      DATA6 = 7'h0a,       
      DATA7 = 7'h0b,       
      DATA8 = 7'h0c,       
      DATA9 = 7'h0d,       
      DATA10 = 7'h0e,      
      DATA11 = 7'h0f,      
      DMCONTROL = 7'h10,   
      DMSTATUS = 7'h11,    
      HARTINFO = 7'h12,    
      HALTSUM0 = 7'h40,    
      HALTSUM1 = 7'h13,                           
      COMMAND  = 7'h17,    
      ABSTRACTCS = 7'h16,  
      ABSTRACTAUTO = 7'h18                       
   } DMADDR;

   logic      InitRequest;
           
   // Registers
   logic [31:0] DMControl;
   logic [31:0] DMStatus;
   logic [31:0] DMCSR2;
   logic [31:0] Data [1:0]; // Abstract Data Registers
   logic [31:0] HartInfo;
   logic [31:0] HaltSum0;
   logic [31:0] AbstractCS;
   logic [31:0] Command;
   logic [31:0] AbstractAuto;

   logic [31:0] NextDMControl;
   logic [31:0] NextDMStatus;
   logic [31:0] NextDMCSR2;
   logic [31:0] NextData [1:0];
   logic [31:0] NextHartInfo;
   logic [31:0] NextHaltSum0;
   logic [31:0] NextAbstractCS;
   logic [31:0] NextCommand;
   logic [31:0] NextAbstractAuto;

   // DMControl fields
   logic        resethaltreq;

   // AbstractCS fields
   logic [4:0] progbufsize;  
   logic        busy;        
   logic        relaxedpriv; 
   logic [2:0]  cmderr;      
   logic [3:0]  datacount;   
   
   // typedef struct packed {
   //    logic haltreq;
   //    logic resumereq;
   //    logic hartreset;
   //    logic ackhavereset;
   //    logic ackunavail;
   //    logic hasel;
   //    logic [9:0] hartsello;
   //    logic [9:0] hartselhi;
   //    logic       setkeepalive;
   //    logic       clrkeepalive;
   //    logic       setresethaltreq;
   //    logic       clrresethaltreq;
   //    logic ndmreset;
   //    logic dmactive;
   // } DMControl_t;
   
   // typedef struct packed {
   //    logic [31:25] reserved0;
   //    logic ndmresetpending;
   //    logic stickyunavail;
   //    logic impebreak;
   //    logic reserved1;
   //    logic allhavereset;
   //    logic anyhavereset;
   //    logic allresumeack;
   //    logic anyresumeack;
   //    logic allnonexistent;
   //    logic anynonexistent;
   //    logic allunavail;
   //    logic anyunavail;
   //    logic allrunning;
   //    logic anyrunning;
   //    logic allhalted;
   //    logic anyhalted;
   //    logic authenticated;
   //    logic authbusy;
   //    logic hasresethaltreq;
   //    logic confstrptrvalid;
   //    logic [3:0] version;
   // } DMStatus_t;

   // typedef struct packed {
   //    logic [2:0] reserved0;
   //    logic [4:0] progbufsize;
   //    logic [10:0] reserved1;
   //    logic        busy;
   //    logic        relaxedpriv;
   //    logic [2:0]  cmderr;
   //    logic [3:0]  reserved2;
   //    logic [3:0]  datacount;
   // } AbstractCS_t;

   // typedef struct packed {
   //    logic [7:0] cmdtype;
   //    logic reserved0;
   //    logic [2:0] aarsize;
   //    logic    aarpostincrement;
   //    logic    postexec;
   //    logic    transfer;
   //    logic    write;
   //    logic    regno;
   // } AbstractReg;

   // DMStatus Signals
   // logic ndmresetpending;
   // logic stickyunavail;
   // logic impebreak;
   // logic reserved1;
   // logic allhavereset;
   // logic anyhavereset;
   logic allresumeack;
   logic anyresumeack;
   // logic allnonexistent;
   // logic anynonexistent;
   // logic allunavail;
   // logic anyunavail;
   logic allrunning;
   logic anyrunning;
   logic allhalted;
   logic anyhalted;
   // logic authenticated;
   // logic authbusy;
   // logic hasresethaltreq;
   // logic confstrptrvalid;
   // logic [3:0] version;
   
   // Abstract Register signals
   logic [7:0]  cmdtype;
   logic [2:0]  aarsize;
   logic        aarpostincrement;

   logic StartCommand;
   logic NextValid;   
   
   // Abstract Commands:
   // 0: Access Register Command
   // 1: Quick Access
   // 2: Access Memory Command
   
   // Need to implement registers. But first, I need a state machine
   // to handle the DMI requests. If it reads, I want to supply the
   // value of the Debug CSR on the next cycle. If it's a write, that
   // should also take effect on the next cycle.

   // The DM must, I believe (jes) :
   // 1.) Handle DMI requests (read/write operations) to access Debug CSRs and abstract commands.
   // 2.) Respond to read requests by supplying the requested register value.
   // 3.) Apply write operations to update registers, typically taking effect in a predictable manner (e.g., on the next clock cycle).
   // 4.) Manage the state of the debug process, including hart control (e.g., halting, resuming, or resetting harts).

   // Some FSM thoughts (jes)
   // A simple state machine might have states like:
   // * Idle: Waiting for dmi_en to assert.
   // * Decode: Decode dmi_addr and dmi_op.
   // * Read Response: Fetch and output register data on the next cycle.
   // * Write Update: Update the register with dmi_data on the next cycle.
   // * Complete: Assert dmi_resp to signal completion.
   // Consider adding an Error State for handling invalid requests (e.g., accessing a non-existent register).
   // If the DM supports abstract commands (e.g., for accessing hart registers or memory), we may need 
   // additional states to manage the command execution pipeline, as these can take multiple cycles. - could be wrong here

   // enum logic {IDLE, GRANTED} DMIState;

   // --------------------------------------------------------------------------
   // DMI Interface with Registers
   // --------------------------------------------------------------------------
   assign InitRequest = ((dmi_req.op == RD) | (dmi_req.op == WR)) & dmi_req.valid;
   always_ff @(posedge clk) begin
      if (rst) begin
         dmi_rsp.valid <= 1'b0;
      end else if (InitRequest) begin
         dmi_rsp.valid <= NextValid;
      end else if (dmi_rsp.valid) begin
         dmi_rsp.valid <= 1'b0;
      end
   end

   always_comb begin
      if ((dmi_req.op == RD) & dmi_req.valid) begin
         NextValid = 1'b1;
      end else if ((dmi_req.op == WR) & dmi_req.valid) begin
         case(dmi_req.addr[6:0])
            COMMAND: begin
               NextValid = DebugMode & StartCommand;
            end
            default: NextValid = 1'b1;
         endcase
      end else begin
         NextValid = 1'b0;
      end    
   end
  
   always_ff @(posedge clk) begin
      if (rst) begin
         DMControl <= '0;
         Command <= '0;
         DMStatus <= {14'b0, 2'b11, 8'b0, 1'b1, 1'b0, 1'b0, 1'b0, 4'b11}; // ResumeAck's start high
         Data = '{default: '0};
         dmi_rsp.ready <= 1'b1;
         dmi_rsp.op <= 2'b0;
         AbstractCS <= 32'h0000_0001;
      end else begin
         // Reads
         if ((dmi_req.op == RD) & dmi_req.valid) begin
            case(dmi_req.addr[6:0])
               DATA0: dmi_rsp.data <= Data[0];
               DATA1: dmi_rsp.data <= Data[1];
               
               DMCONTROL: begin
                  dmi_rsp.data[31] <= 1'b0;
                  dmi_rsp.data[30:0] <= DMControl[30:0];
               end
              
               DMSTATUS: begin
                  // Might need a separate always_comb for every register.
                  dmi_rsp.data <= {DMStatus[31:18],
                                   allrunning, allrunning, // Shouldn't be necessary, check FIXME
                                   DMStatus[15:12],
                                   allrunning, anyrunning, allhalted, anyhalted,
                                   DMStatus[7:0]};
               end
              
               HARTINFO: dmi_rsp.data <= HartInfo;
               HALTSUM0: dmi_rsp.data <= HaltSum0;
               ABSTRACTCS: dmi_rsp.data <= {AbstractCS[31:11], cmderr, AbstractCS[7:0]};
               default: dmi_rsp.data <= 32'b0;
            endcase 
         end 

         // Writes
         if ((dmi_req.op == WR) & dmi_req.valid) begin
            case(dmi_req.addr[6:0])
               DATA0: Data[0] <= dmi_req.data;
               DATA1: Data[1] <= dmi_req.data;
               
               DMCONTROL: begin
                  if (HaltReq) begin 
                     DMControl <= {dmi_req.data[31], 1'b0, dmi_req.data[29], 25'b0, dmi_req.data[3:0]};
                  end else begin
                     DMControl <= {dmi_req.data[31:29], 25'b0, dmi_req.data[3:0]};
                     
                     // Force AllResumeACK and AnyResumeACK low if
                     // we're writing to ResumeReq p. 28. There will
                     // always be at least 1 cycle of latency after
                     // receving the ResumeReq
                     if (dmi_req.data[30]) DMStatus <= {DMStatus[31:18], 2'b0, DMStatus[15:0]};
                  end
               end
               
               COMMAND: begin 
                  Command <= dmi_req.data;
               end
              
              ABSTRACTCS: begin 
                 AbstractCS <= {AbstractCS[31:12],
                                dmi_req.data[11], // Relaxedpriv
                                dmi_req.data[8] == 1'b1 ? 3'b0 : AbstractCS[10:8], // cmderr -> R/W1C
                                 AbstractCS[7:0]}; // Only relaxedpriv and cmderr are writeable
              end
            endcase            
         end

         if (StartCommand & ~Command[17]) begin
            Data[0] <= RegIn;
         end

         // if (ResumeReq) begin
         //    DMStatus[31] <= 1'b1; // This is seen by OpenOCD
         //    DMStatus[17] <= allrunning; // These are not - Vivado Synthesis issue? FIXME
         //    DMStatus[16] <= allrunning;
         // end

         
      end
   end

   

    // always_ff @(posedge clk) begin
    //   if (rst) begin
    //      DMControl <= '0;
    //      Command <= '0;
    //      DMStatus <= {14'b0, 2'b11, 8'b0, 1'b1, 1'b0, 1'b0, 1'b0, 4'b11}; // ResumeAck's start high
    //      Data = '{default: '0};
    //      dmi_rsp.ready <= 1'b1;
    //      dmi_rsp.op <= 2'b0;
    //      AbstractCS <= 32'h0000_0001;
    //   end else begin
    //      DMStatus <= NextDMStatus;
    //      DMControl <= NextDMControl;
    //      Data[0] <= NextData[0];
    //      Data[1] <= NextData[1];
    //      AbstractCS <= NextAbstractCS;
    //      Command <= NextCommand;
    //   end
    // end

   // --------------------------------------------------------------------------
   // Halt FSM
   // --------------------------------------------------------------------------
   
   assign HaltReq = DMControl[31];
   assign ResumeReq = DMControl[30];
   assign resethaltreq = 1'b0;
   
   typedef enum logic [1:0] {RUNNING, HALTING, HALTED, RESUMING} HaltState;
   HaltState CurrHaltState;
   HaltState NextHaltState;
   
   // see Figure 2 Debug Specification (2/21/25)
   always_ff @(posedge clk) begin
      if (rst) begin
         if (resethaltreq) CurrHaltState <= HALTED;
         else CurrHaltState <= RUNNING;
      end else begin
         CurrHaltState <= NextHaltState;
      end
   end

   always_comb begin
      case(CurrHaltState)
         RUNNING: begin
            if (HaltReq) NextHaltState = HALTING;
            else NextHaltState = RUNNING;
         end	   
         HALTING: begin
            if (DebugMode) NextHaltState = HALTED;
            else NextHaltState = HALTING;
         end	   
         HALTED: begin
            if (ResumeReq) NextHaltState = RESUMING;
            else NextHaltState = HALTED;
         end	   
         RESUMING: begin
            if (~DebugMode) NextHaltState = RUNNING;
            else NextHaltState = RESUMING;
         end           
         default: NextHaltState = RUNNING;
      endcase
   end
                                 
   assign allrunning = NextHaltState == RUNNING | CurrHaltState == RUNNING;
   assign anyrunning = NextHaltState == RUNNING | CurrHaltState == RUNNING;
   assign allhalted = NextHaltState == HALTED | CurrHaltState == HALTED;
   assign anyhalted = NextHaltState == HALTED | CurrHaltState == HALTED;

   // --------------------------------------------------------------------------
   // Abstract Command FSM
   // --------------------------------------------------------------------------
   
   enum logic [1:0] {IDLE, BUSY, ERRORWAIT, ERRORBUSY} AbstractState;

   // Abstract Command FSM
   always_ff @(posedge clk) begin
      if (rst) begin
         AbstractState <= IDLE;
      end else begin
         case(AbstractState)
            IDLE: begin
               if (Command[31:24] == 8'b0) begin
                  AbstractState <= IDLE; // Reading and writing to registers should be immediate.
               end else begin
                  AbstractState <= BUSY; // This would be for Quick Access or Memory Access conditions 
               end
            end

            BUSY: begin
               
            end

            ERRORWAIT: begin

            end

            ERRORBUSY: begin
               
            end
            default: AbstractState <= IDLE;
         endcase
      end
   end

   logic ValidCommand;
   
   assign aarsize = Command[22:20];
   assign StartCommand = dmi_req.valid & dmi_rsp.ready & (dmi_req.addr == COMMAND) & ~|cmderr;
   assign DebugControl = StartCommand;
   assign RegAddr = Command[4:0];
   assign DebugRegWrite = Command[16] & dmi_rsp.valid;
   assign RegOut = Data[0]; // Needs to expand with 64 bit numbers

   //assign cmderr = 3'd2;

   // Refer to Debug Specification pg. 19 for register ranges.
   always_comb begin
      case(Command[15:0])
         16'b0001_0000_000x_xxxx: ValidCommand = 1; // GPRs
         16'h0300: ValidCommand = 1; // mstatus
         16'h0301: ValidCommand = 1; // misa
         16'h0305: ValidCommand = 1; // mtvec
         16'h0341: ValidCommand = 1; // mepc
         16'h0342: ValidCommand = 1; // mcause
         16'h0343: ValidCommand = 1; // mtval
         16'h07B0: ValidCommand = 1; // dcsr
         16'h07B1: ValidCommand = 1; // dpc
         16'h07B2: ValidCommand = 1; // dscratch0
         default: ValidCommand = 0;
      endcase
   end
   
   always_comb begin
      if (ValidCommand & aarsize != 3'd3 & aarsize != 3'd4) cmderr = 3'd0;
      else cmderr = 3'd2;
   end 
endmodule
