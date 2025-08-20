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
   logic [31:0] Data [11:0]; // Abstract Data Registers
   logic [31:0] HartInfo;
   logic [31:0] HaltSum0;
   logic [31:0] AbstractCS;
   logic [31:0] Command;
   logic [31:0] AbstractAuto;

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

   // Abstract Register signals
   logic [7:0]  cmdtype;
   logic [2:0]  aarsize;
   logic        aarpostincrement;

   logic StartCommand;
   logic NextValid;
   
   
   // Abstract Commands:
   // 0: Access Register Command
   // 1: 
   
   // Need to implement registers. But first, I need a state machine
   // to handle the DMI requests. If it reads, I want to supply the
   // value of the Debug CSR on the next cycle. If it's a write, that
   // should also take effect on the next cycle.

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
      end

      if ((dmi_req.op == WR) & dmi_req.valid) begin
         case(dmi_req.addr[6:0])
            COMMAND: begin
               NextValid = DebugMode & StartCommand;
            end
            default: NextValid = 1'b1;
         endcase
      end    
   end
  
   always_ff @(posedge clk) begin
      if (rst) begin
         DMControl <= '0;
         Command <= '0;
         DMStatus <= {24'b0, 1'b1, 1'b0, 1'b1, 1'b0, 4'b11};
         Data = '{default: '0};
         dmi_rsp.ready <= 1'b1;
         dmi_rsp.op <= 2'b0;
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
               
               DMSTATUS: dmi_rsp.data <= DMStatus;
               HARTINFO: dmi_rsp.data <= HartInfo;
               HALTSUM0: dmi_rsp.data <= HaltSum0;
               ABSTRACTCS: dmi_rsp.data <= AbstractCS;
               default: dmi_rsp.data <= 32'b0;
            endcase // case (dmi_req.addr[6:0])
         end // if (dmi_rsp.op == RD)

         // Writes
         if ((dmi_req.op == WR) & dmi_req.valid) begin
            case(dmi_req.addr[6:0])
               DATA0: Data[0] <= dmi_req.data;
               DATA1: Data[1] <= dmi_req.data;
               
               DMCONTROL: begin
                  if (HaltReq) DMControl <= {dmi_req.data[31], 1'b0, dmi_req.data[29:0]};
                  else DMControl <= dmi_req.data;
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
      end
   end
   
   

   // --------------------------------------------------------------------------
   // Halt FSM
   // --------------------------------------------------------------------------
   
   assign HaltReq = DMControl[31];
   assign ResumeReq = DMControl[30];
   assign resethaltreq = 1'b0;
   
   enum logic [1:0] {RUNNING, HALTING, HALTED, RESUMING} HaltState;

   // see Figure 2 Debug Specification (2/21/25)
   always_ff @(posedge clk) begin
      if (rst) begin
         if (resethaltreq) HaltState <= HALTED;
         else HaltState <= RUNNING;
      end else begin
         case(HaltState)
           RUNNING: begin
              if (HaltReq) HaltState <= HALTING;
           end	   
           HALTING: begin
              if (DebugMode) HaltState <= HALTED;
           end	   
           HALTED: begin
              if (ResumeReq) HaltState <= RESUMING;
           end	   
           RESUMING: begin
              if (~DebugMode) HaltState <= RUNNING;
           end           
           default: HaltState <= RUNNING;
         endcase
      end
   end

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
   end // always_ff @ (posedge clk)

   assign aarsize = Command[22:20];
   assign StartCommand = dmi_req.valid & dmi_rsp.ready & (dmi_req.addr == COMMAND);
   assign DebugControl = StartCommand;
   assign RegAddr = Command[4:0];
   assign DebugRegWrite = Command[16] & dmi_rsp.valid;
   assign RegOut = Data[0]; // Needs to expand with 64 bit numbers

   // Another FSM for managing Abstract Access commands (cmdtype == 0)
   // always_ff @(posedge clk) begin
   //    if (rst) begin
   //       StartCommand <= 1'b0;
   //    end else begin
   //       if (dmi_req.addr == COMMAND & (AbstractState == IDLE) ) begin
   //          StartCommand <= 1'b1;
   //       end else begin
   //          cmderr = 3'b1;
   //       end
   // end
   
   /*
    if (command read register)
      address regfile
      store data on clock edge.
      
    
    
    
    
    
    
    */
   
   
   
   // always @(posedge clk) begin
   //    if (rst) begin
   //       DMIState <= 0;
   //       dmi_rsp.data <= '0;
   //       dmi_rsp.ack <= 0;
   
   //       // Register resets
   //       DMControl <= {};
   //       // Should work. We'll see. 
   //       // https://electronics.stackexchange.com/questions/520746/understanding-verilog-default-1
   //       Data = '{default: '0};
   //    end else begin
   //       case(DMIState)
   //          IDLE: begin
   //             if (dmi_req.op == RD | dmi_req.op == WR) begin
   //                dmi_rsp.ack <= 1'b1;
   //                DMIState <= GRANTED;
   //             end

   //             if (dmi_req.op == RD) begin
   //                case(dmi_req.addr)
   //                   // Abstract Data Registers
   //                   7'h04: dmi_rsp.data <= Data[0];
   //                   7'h10: dmi_rsp.data <= DMControl;
   //                   7'h11: dmi_rsp.data <= DMStatus;
   //                   7'h12: dmi_rsp.data <= HartInfo;
   //                   7'h13: dmi_rsp.data <= HaltSum0;
   //                   default: dmi_rsp.data <= '0;
   //                endcase
   //             end // if (dmi_req.op == RD)

   //             if (dmi_req.op == WR) begin
   //                 case(dmi_req.addr)
   //                   // Abstract Data Registers
   //                   7'h04: Data[0] <= dmi_req.data; // Needs to be conditional
   //                   7'h10: DMControl <= dmi_req.data;
   //                   7'h11: DMStatus <= dmi_req.data;
   //                   7'h12: HartInfo <= dmi_req.data;
   //                   7'h13: HaltSum0 <= dmi_req.data;
   //                   default: ;
   //                endcase
   //             end
   //          end

   //          GRANTED: begin
   //             dmi_rsp.ack <= 1'b0;
   //             DMIState <= IDLE;
   //          end
   //          default: DMIState <= IDLE;
   //       endcase
   //    end
   // end
   
endmodule
