///////////////////////////////////////////
// spi_controller.sv
//
// Written: jacobpease@protonmail.com
// Created: October 28th, 2024
// Modified: 
//
// Purpose: Controller logic for SPI
// 
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
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


module spi_controller (
  input logic        PCLK,
  input logic        PRESETn,
  input logic        TransmitStart,
  input logic [11:0] SckDiv,
  input logic [1:0]  SckMode,
  input logic [1:0]  CSMode,
  input logic [15:0]  Delay0,
  input logic [15:0]  Delay1,
  input logic [7:0]  txFIFORead,
  input logic        txFIFOReadEmpty,
  output logic       SPICLK,
  output logic       SPIOUT,
  output logic       CS
);
  
  // CSMode Stuff
  localparam         HOLDMODE = 2'b10;
  localparam         AUTOMODE = 2'b00;
  localparam         OFFMODE = 2'b11;         

  typedef enum       logic [2:0] {INACTIVE, CSSCK, TRANSMIT, SCKCS, HOLD, INTERCS, INTERXFR} statetype;
  statetype CurrState, NextState;
  
  // SCLKenable stuff
  logic [11:0]       DivCounter;
  logic              SCLKenable;
  logic              SCLKenableEarly;
  logic              SCLKenableLate;
  logic              EdgeTiming;
  logic              ZeroDiv;
  logic              Clock0;
  logic              Clock1;
  logic              SCK; // SUPER IMPORTANT, THIS CAN'T BE THE SAME AS SPICLK!
  

  // Shift and Sample Edges
  logic PreShiftEdge;
  logic PreSampleEdge;
  logic ShiftEdge;
  logic SampleEdge;

  // Frame stuff
  logic [2:0] BitNum;
  logic       LastBit;
  logic       EndOfFrame;
  logic       EndOfFrameDelay;
  logic       PhaseOneOffset;

  // Transmit Stuff
  logic       ContinueTransmit;       

  // SPIOUT Stuff
  logic       TransmitLoad;
  logic [7:0] TransmitReg;
  logic       Transmitting;
  logic       EndTransmission;

  logic       HoldMode;

  // Delay Stuff
  logic [7:0] cssck;
  logic [7:0] sckcs;
  logic [7:0] intercs;
  logic [7:0] interxfr;
  
  logic       HasCSSCK;
  logic       HasSCKCS;
  logic       HasINTERCS;
  logic       HasINTERXFR;
  
  logic       EndOfCSSCK;
  logic       EndOfSCKCS;
  logic       EndOfINTERCS;
  logic       EndOfINTERXFR;
  
  logic [7:0] CSSCKCounter;
  logic [7:0] SCKCSCounter;
  logic [7:0] INTERCSCounter;
  logic [7:0] INTERXFRCounter;

  logic       DelayIsNext;

  // Convenient Delay Reg Names
  assign cssck = Delay0[7:0];
  assign sckcs = Delay0[15:8];
  assign intercs = Delay1[7:0];
  assign interxfr = Delay1[15:8];

  // Do we have delay for anything?
  assign HasCSSCK = cssck > 8'b0;
  assign HasSCKCS = sckcs > 8'b0;
  assign HasINTERCS = intercs > 8'b0;
  assign HasINTERXFR = interxfr > 8'b0;

  // Have we hit full delay for any of the delays?
  assign EndOfCSSCK = CSSCKCounter == cssck;
  assign EndOfSCKCS = SCKCSCounter == sckcs;
  assign EndOfINTERCS = INTERCSCounter == intercs;
  assign EndOfINTERXFR = INTERXFRCounter == interxfr;
  
  // Clock Signal Stuff -----------------------------------------------
  // I'm going to handle all clock stuff here, including ShiftEdge and
  // SampleEdge. This makes sure that SPICLK is an output of a register
  // and it properly synchronizes signals.
  
  assign SCLKenableLate = DivCounter > SckDiv;
  assign SCLKenable = DivCounter == SckDiv;
  assign SCLKenableEarly = (DivCounter + 1'b1) == SckDiv;
  assign LastBit = BitNum == 3'd7;
  assign EdgeTiming = SckDiv > 12'b0 ? SCLKenableEarly : SCLKenable;

  //assign SPICLK = Clock0;

  assign ContinueTransmit = ~txFIFOReadEmpty & EndOfFrame;
  assign EndTransmission = txFIFOReadEmpty & EndOfFrameDelay;
  
  always_ff @(posedge PCLK) begin
    if (~PRESETn) begin
      DivCounter <= 12'b0;
      SPICLK <= SckMode[1];
      SCK <= 0;
      BitNum <= 3'h0;
      PreShiftEdge <= 0;
      PreSampleEdge <= 0;
      EndOfFrame <= 0;
    end else begin
      // TODO: Consolidate into one delay counter since none of the
      // delays happen at the same time?
      if (TransmitStart) begin
        SCK <= 0;
      end else if (SCLKenable) begin
        SCK <= ~SCK;
      end
      
      if ((CurrState == CSSCK) & SCK) begin
        CSSCKCounter <= CSSCKCounter + 8'd1;
      end else begin
        CSSCKCounter <= 8'd0;
      end
      
      if ((CurrState == SCKCS) & SCK) begin
        SCKCSCounter <= SCKCSCounter + 8'd1;
      end else begin
        SCKCSCounter <= 8'd0;
      end
      
      if ((CurrState == INTERCS) & SCK) begin
        INTERCSCounter <= INTERCSCounter + 8'd1;
      end else begin
        INTERCSCounter <= 8'd0;
      end
      
      if ((CurrState == INTERXFR) & SCK) begin
        INTERXFRCounter <= INTERXFRCounter + 8'd1;
      end else begin
        INTERXFRCounter <= 8'd0;
      end
      
      // SPICLK Logic
      if (TransmitStart) begin
        SPICLK <= SckMode[1];
      end else if (SCLKenable & Transmitting) begin
        SPICLK <= (~EndTransmission & ~DelayIsNext) ? ~SPICLK : SckMode[1];
      end
      
      // Reset divider 
      if (SCLKenable | TransmitStart) begin
        DivCounter <= 12'b0;
      end else begin
        DivCounter = DivCounter + 12'd1;
      end
      
      // EndOfFrame controller
      // if (SckDiv > 0 ? SCLKenableEarly & LastBit & SPICLK : LastBit & ~SPICLK) begin
      //   EndOfFrame <= 1'b1;
      // end else begin
      //   EndOfFrame <= 1'b0;  
      // end

      if (~TransmitStart) begin
        EndOfFrame <= (SckMode[1] ^ SckMode[0] ^ SPICLK) & SCLKenable & LastBit & Transmitting;
      end
      
      // Increment BitNum
      if (ShiftEdge & Transmitting) begin
        BitNum <= BitNum + 3'd1;
      end else if (EndOfFrameDelay) begin
        BitNum <= 3'b0;  
      end
    end
  end

  // Delay ShiftEdge and SampleEdge by a half PCLK period
  // Aligned EXACTLY ON THE MIDDLE of the leading and trailing edges.
  // Sweeeeeeeeeet...
  always_ff @(posedge ~PCLK) begin
    if (~PRESETn | TransmitStart) begin
      ShiftEdge <= 0;
      PhaseOneOffset <= 0;
      SampleEdge <= 0;
      EndOfFrameDelay <= 0;
    end else begin
      ShiftEdge <= ((SckMode[1] ^ SckMode[0] ^ SPICLK) & SCLKenable & ~LastBit & Transmitting) & PhaseOneOffset;
      PhaseOneOffset <= PhaseOneOffset == 0 ? Transmitting & SCLKenable : PhaseOneOffset;
      SampleEdge <= (SckMode[1] ^ SckMode[0] ^ ~SPICLK) & SCLKenable & Transmitting;
      EndOfFrameDelay <= (SckMode[1] ^ SckMode[0] ^ SPICLK) & SCLKenable & LastBit & Transmitting;
    end
  end

  // typedef enum logic [2:0] {INACTIVE, CSSCK, TRANSMIT, SCKCS, HOLD, INTERCS, INTERXFR} statetype;
  // statetype CurrState, NextState;

  assign HoldMode = CSMode == 2'b10;
  assign TransmitLoad = TransmitStart | (EndOfFrameDelay & ~txFIFOReadEmpty);

  always_ff @(posedge PCLK) begin
    if (~PRESETn) begin
      CurrState <= INACTIVE;
    end else if (SCLKenable) begin
      CurrState <= NextState;
    end
  end
  
  always_comb begin
    case (CurrState)  
      INACTIVE: begin // INACTIVE case --------------------------------
        if (TransmitStart) begin
          if (~HasCSSCK) begin
            NextState = TRANSMIT;
          end else begin
            NextState = CSSCK;  
          end
        end else begin
          NextState = INACTIVE;
        end
      end 
      CSSCK: begin // DELAY0 case -------------------------------------
        if (EndOfCSSCK) begin
          NextState = TRANSMIT;  
        end
      end
      TRANSMIT: begin // TRANSMIT case --------------------------------
        case(CSMode)
          AUTOMODE: begin  
            if (EndTransmission) begin
              NextState = INACTIVE;
            end else if (ContinueTransmit) begin
              NextState = SCKCS;
            end
          end
          HOLDMODE: begin  
            if (EndTransmission) begin
              NextState = HOLD;  
            end else if (ContinueTransmit) begin
              if (HasINTERXFR) NextState = INTERXFR;
            end
          end
          OFFMODE: begin
              
          end
                
        endcase
      end
      SCKCS: begin // SCKCS case --------------------------------------
        if (EndOfSCKCS) begin
          if (EndTransmission) begin
            if (CSMode == AUTOMODE) NextState = INACTIVE;
            else if (CSMode == HOLDMODE) NextState = HOLD;
          end else if (ContinueTransmit) begin
            if (HasINTERCS) NextState = INTERCS;
            else NextState = TRANSMIT;
          end
        end
      end
      HOLD: begin // HOLD mode case -----------------------------------
        if (CSMode == AUTOMODE) begin
          NextState = INACTIVE;
        end else if (TransmitStart) begin // If FIFO is written to, start again.
          NextState = TRANSMIT;
        end
      end
      INTERCS: begin // INTERCS case ----------------------------------
        if (EndOfINTERCS) begin
          if (HasCSSCK) NextState = CSSCK;
          else NextState = TRANSMIT;
        end
      end
      INTERXFR: begin // INTERXFR case --------------------------------
        if (EndOfINTERXFR) begin
          NextState = TRANSMIT;
        end
      end
      default: begin
        NextState = INACTIVE;
      end
    endcase
  end

  assign Transmitting = CurrState == TRANSMIT;
  assign DelayIsNext = (NextState == CSSCK | NextState == SCKCS | NextState == INTERCS | NextState == INTERXFR);

  // 
  always_ff @(posedge PCLK) begin
    if (~PRESETn) begin
      TransmitReg <= 8'b0;
    end else if (TransmitLoad) begin
      TransmitReg <= txFIFORead;
    end else if (ShiftEdge) begin
      TransmitReg <= {TransmitReg[6:0], TransmitReg[0]};
    end
  end

  assign SPIOUT = TransmitReg[7];
  assign CS = CurrState == INACTIVE | CurrState == INTERCS;
  
endmodule
