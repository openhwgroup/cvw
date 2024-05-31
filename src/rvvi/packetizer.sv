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
  // axi 4 write data channel
  output logic [31:0]      RvviAxiWdata,
  output logic [3:0] 	   RvviAxiWstrb,
  output logic  		   RvviAxiWlast,
  output logic  		   RvviAxiWvalid,
  input  logic  		   RvviAxiWready
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
  logic [15:0]             EthType;
  logic [TotalFrameLengthBits-1:0] TotalFrame;
  logic [31:0] TotalFrameWords [TotalFrameLengthBytes/4-1:0];

  logic [187+(3*P.XLEN) + MAX_CSRS*(P.XLEN+12)-1:0] rvviDelay;
  
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
      else                        NextState = STATE_RDY;
      STATE_WAIT: if(TransReady)   NextState = STATE_TRANS;
      else NextState = STATE_WAIT;
      STATE_TRANS: if(BurstDone) NextState = STATE_RDY;
      else NextState = STATE_TRANS;
      default: NextState = STATE_RDY;
    endcase
  end

  assign RVVIStall = CurrState != STATE_RDY;
  assign TransReady = RvviAxiWready;
  assign WordCountEnable = (CurrState == STATE_RDY & valid) | (CurrState == STATE_TRANS & TransReady);
  assign WordCountReset = CurrState == STATE_RDY;

  flopenr #(187+(3*P.XLEN) + MAX_CSRS*(P.XLEN+12)) rvvireg(m_axi_aclk, ~m_axi_aresetn, valid, rvvi, rvviDelay);


  counter #(10) WordCounter(m_axi_aclk, WordCountReset, WordCountEnable, WordCount);
  // *** BUG BytesInFrame will eventually depend on the length of the data stored into the ethernet frame
  // for now this will be exactly 608 bits (76 bytes, 19 words)
  assign BytesInFrame = 12'd76;
  assign BurstDone = WordCount == (BytesInFrame[11:2] - 1'b1);

  genvar index;
  for (index = 0; index < TotalFrameLengthBytes/4; index++) begin 
    assign TotalFrameWords[index] = TotalFrame[(index*32)+32-1 : (index*32)];
  end

  assign TotalFrame = {rvviDelay, EthType, Tag, DstMac, SrcMac};

  // *** fix me later
  assign SrcMac = 48'h8F54_0000_1654; // made something up
  assign DstMac = 48'h4502_1111_6843;
  assign Tag = '0;
  assign Length = 16'h0801;
  
  assign RvviAxiWdata = TotalFrameWords[WordCount];
  assign RvviAxiWstrb = '1;
  assign RvviAxiWlast = BurstDone;
  assign RvviAxiWvalid = (CurrState == STATE_TRANS);
  
endmodule
 
