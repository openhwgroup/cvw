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
   input logic  clk;
   input logic  rst,
          
   // Currently implementing NeoRV32 signals. Subject to change if I
   // prefer a different DMI.
   input        dmi_t dmi_req,
   output       dmi_rsp_t dmi_rsp,
   
   // CPU Signals
   output logic NDMReset,
   output logic HaltReq,
   output logic ResumeReq
);

   localparam DATA0 = 7'h04;
   localparam DATA1 = 7'h05;
   localparam DATA2 = 7'h06; 
   localparam DATA3 = 7'h07; 
   localparam DATA4 = 7'h08; 
   localparam DATA5 = 7'h09; 
   localparam DATA6 = 7'h0a; 
   localparam DATA7 = 7'h0b; 
   localparam DATA8 = 7'h0c; 
   localparam DATA9 = 7'h0d; 
   localparam DATA10 = 7'h0e;           
   localparam DATA11 = 7'h0f;
   localparam DMCONTROL = 7'h10;
   localparam DMSTATUS = 7'h11;
   localparam HARTINFO = 7'h12;
   localparam HALTSUM0 = 7'h40;
   localparam HALTSUM1 = 7'h13;
   localparam COMMAND  = 7'h17;
   localparam ABSTRACTCS = 7'h16;
   localparam ABSTRACTAUTO = 7'h18;

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
   
   // Need to implement registers. But first, I need a state machine
   // to handle the DMI requests. If it reads, I want to supply the
   // value of the Debug CSR on the next cycle. If it's a write, that
   // should also take effect on the next cycle.

   // enum logic {IDLE, GRANTED} DMIState;

   assign InitRequest = (dmi_req.op == RD) | (dmi_req.op == WR);
   always_ff @(posedge clk) begin
      if (rst) begin
         dmi_rsp.ack <= 1'b0;
      end else if (InitRequest) begin
         dmi_rsp.ack <= 1'b1;
      end else if (dmi_rsp.ack) begin
         dmi_rsp.ack <= 1'b0;
      end
   end
   
   always_ff @(posedge clk) begin
      if (rst) begin
         DMControl <= '0;
         DMStatus <= {24'b0, 1'b1, 1'b0, 1'b1, 1'b0, 4'b11};
         Data = '{default: '0};
      end else if (InitRequest) begin
         if (dmi_req.op == RD) begin
            case(dmi_req.addr[6:0])
               DATA0: dmi_rsp.data <= Data[0];
               DATA1: dmi_rsp.data <= Data[1];
               DATA2: dmi_rsp.data <= Data[2];
               DATA3: dmi_rsp.data <= Data[3];
               DATA4: dmi_rsp.data <= Data[4];
              
               DMCONTROL: begin
                  dmi_rsp.data[31] <= 1'b0;
                  dmi_rsp.data[30:0] <= DMControl[30:0];
               end
              
               DMSTATUS: dmi_rsp.data <= DMStatus;
               HARTINFO: dmi_rsp.data <= HartInfo;
               HALTSUM0: dmi_rsp.data <= HaltSum0;
               default: dmi_rsp.data <= 32'b0;
            endcase // case (dmi_req.addr[6:0])
         end // if (dmi_rsp.op == RD)

         if (dmi_req.op == WR) begin
            case(dmi_req.addr[6:0])
               DATA0: Data[0] <= dmi_req.data;
               DATA1: Data[1] <= dmi_req.data;
               DATA2: Data[2] <= dmi_req.data;
               DATA3: Data[3] <= dmi_req.data;
               DATA4: Data[4] <= dmi_req.data;
               DMCONTROL: DMControl <= dmi_req.data;
               COMMAND: Command <= dmi_req.data;
               ABSTRACTCS: AbstractCS <= dmi_req.data;
               endcase
         end
      end
   end
   
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
