///////////////////////////////////////////
// packetizer.sv
//
// Written: Rose Thompson ross1728@gmail.com
// Created: 21 May 2024
// Modified: 21 May 2024
//
// Purpose: Converts the compressed RVVI format into AXI 4 burst write transactions.
//
// Documentation: 
//
// A component of the CORE-V-WALLY configurable RISC-V project.
//
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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

module packetizer import cvw::*; #(parameter cvw_t P,
                                   parameter integer MAX_CSRS)(
  input  logic [187+(3*P.XLEN) + MAX_CSRS*(P.XLEN+12)-1:0] rvvi,
  input  logic valid,
  input  logic m_axi_aclk, m_axi_aresetn,
  output logic RVVIStall,
  // axi 4 write address channel
  output logic [3:0] 	   m_axi_awid,
  output logic [12:0] 	   m_axi_awaddr,
  output logic [7:0] 	   m_axi_awlen,
  output logic [2:0] 	   m_axi_awsize,
  output logic [1:0] 	   m_axi_awburst,
  output logic [3:0] 	   m_axi_awcache,
  output logic             m_axi_awvalid,
  input  logic  		   m_axi_awready,
  // axi 4 write data channel
  output logic [31:0]      m_axi_wdata,
  output logic [3:0] 	   m_axi_wstrb,
  output logic  		   m_axi_wlast,
  output logic  		   m_axi_wvalid,
  input  logic  		   m_axi_wready,
  // axi 4 write response channel
  input  logic [3:0] 	   m_axi_bid,
  input  logic [1:0] 	   m_axi_bresp,
  input  logic  		   m_axi_bvalid,
  output logic  		   m_axi_bready,
  // axi 4 read address channel
  output logic [3:0] 	   m_axi_arid,
  output logic [12:0] 	   m_axi_araddr,
  output logic [7:0] 	   m_axi_arlen,
  output logic [2:0] 	   m_axi_arsize,
  output logic [1:0] 	   m_axi_arburst,
  output logic [3:0] 	   m_axi_arcache,
  output logic  		   m_axi_arvalid,
  input  logic   		   m_axi_arready,
 // axi 4 read data channel
  input  logic [3:0] 	   m_axi_rid,
  input  logic [31:0] 	   m_axi_rdata,
  input  logic [1:0] 	   m_axi_rresp,
  input  logic  		   m_axi_rlast,
  input  logic  		   m_axi_rvalid,
  output logic  		   m_axi_rready
  );

  localparam TotalFrameLengthBits = 2*48+32+16+187+(3*P.XLEN) + MAX_CSRS*(P.XLEN+12);
  localparam TotalFrameLengthBytes = TotalFrameLengthBits / 8;

  logic [9:0]              WordCount;
  logic [11:0]             BytesInFrame;
  logic                    TransReady;
  logic                    BurstDone;
  logic                    WordCountReset;
  logic                    WordCountEnable;
  logic [47:0]             SrcMac, DstMac;
  logic [31:0]             Tag;
  logic [15:0]             Length;
  logic [TotalFrameLengthBits-1:0] TotalFrame;
  logic [31:0] TotalFrameWords [TotalFrameLengthBytes/4-1:0];
  
  typedef enum              {STATE_RDY, STATE_WAIT, STATE_TRANS, STATE_TRANS_DONE} statetype;
  statetype CurrState, NextState;

  always_ff @(posedge m_axi_aclk) begin
    if(~m_axi_aresetn) CurrState <= STATE_RDY;
    else               CurrState <= NextState;
  end

  always_comb begin
    case(CurrState)
      STATE_RDY: if (TransReady & valid) NextState = STATE_TRANS;
      else if(~TransReady & valid) NextState = STATE_WAIT;
      STATE_WAIT: if(TransReady) NextState = STATE_TRANS;
      else NextState = STATE_WAIT;
      STATE_TRANS: if(BurstDone) NextState = STATE_RDY;
      else NextState = STATE_TRANS;
      default: NextState = STATE_RDY;
    endcase
  end

  assign RVVIStall = CurrState != STATE_RDY;
  assign TransReady = m_axi_awready & m_axi_wready;
  assign WordCountEnable = (CurrState == STATE_RDY & valid) | (CurrState == STATE_TRANS & TransReady);
  assign WordCountReset = CurrState == STATE_RDY;


  counter #(10) WordCounter(m_axi_aclk, WordCountReset, WordCountEnable, WordCount);
  // *** BUG BytesInFrame will eventually depend on the length of the data stored into the ethernet frame
  // for now this will be exactly 608 bits (76 bytes, 19 words)
  assign BytesInFrame = 12'd76;
  assign BurstDone = WordCount == BytesInFrame[11:2];

  assign m_axi_awid = '0;
  assign m_axi_awaddr = '0; // *** bug update to be based on the correct address during each beat.
  assign m_axi_awlen = BytesInFrame[11:2];
  assign m_axi_awsize = 3'b010; // 4 bytes
  assign m_axi_awburst = 2'b01; // increment
  assign m_axi_awcache = '0;
  assign m_axi_awvalid = (CurrState == STATE_RDY & valid) | CurrState == STATE_TRANS;
  genvar index;
  for (index = 0; index < TotalFrameLengthBytes/4; index++) begin 
    assign TotalFrameWords[index] = TotalFrame[(index*32)+32-1 : (index*32)];
  end

  assign TotalFrame = {rvvi, Length, Tag, DstMac, SrcMac};

  // *** fix me later
  assign SrcMac = '0;
  assign DstMac = '0;
  assign Tag = '0;
  assign Length = BytesInFrame + 16'd6 + 16'd6 + 16'd4 + 16'd2;
  
  assign m_axi_wdata = TotalFrameWords[WordCount];
  assign m_axi_wstrb = '1;
  assign m_axi_wlast = BurstDone;
  assign m_axi_wvalid = (CurrState == STATE_RDY & valid) | (CurrState == STATE_TRANS);
  

  assign m_axi_bready = 1'b1; // *** probably wrong.

  // we aren't using the read channels. This ethernet device isn't going to read anything for now
  assign {m_axi_arid, m_axi_araddr, m_axi_arlen, m_axi_arsize, m_axi_arburst, m_axi_arcache, m_axi_arvalid, m_axi_rready} = '0;
    
endmodule
 
