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

  // Start Transmission
  input logic        TransmitStart,
  input logic        TransmitStartD,
  input logic        ResetSCLKenable, 

  // Registers
  input logic [11:0] SckDiv,
  input logic [1:0]  SckMode,
  input logic [1:0]  CSMode,
  input logic [15:0] Delay0,
  input logic [15:0] Delay1,
  input logic [3:0]  FrameLength,

  // Is the Transmit FIFO Empty?
  input logic        txFIFOReadEmpty,

  // Control signals
  output logic       SCLKenable,
  output logic       ShiftEdge,
  output logic       SampleEdge,
  output logic       EndOfFrame,
  output logic       EndOfFrameDelay, 
  output logic       Transmitting,
  output logic       InactiveState,
  output logic       SPICLK
);
  
  // CSMode Stuff
  localparam         HOLDMODE = 2'b10;
  localparam         AUTOMODE = 2'b00;
  localparam         OFFMODE = 2'b11;         

  typedef enum       logic [2:0] {INACTIVE, CSSCK, TRANSMIT, SCKCS, HOLD, INTERCS, INTERXFR} statetype;
  statetype CurrState, NextState;
  
  // SCLKenable stuff
  logic [11:0]       DivCounter;
  // logic              SCLKenable;
  // logic              SCLKenableEarly;
  logic              ZeroDiv;
  logic              SCK; // SUPER IMPORTANT, THIS CAN'T BE THE SAME AS SPICLK!
  

  // Shift and Sample Edges
  logic PreShiftEdge;
  logic PreSampleEdge;
  // logic ShiftEdge;
  // logic SampleEdge;

  // Frame stuff
  logic [3:0] BitNum;
  logic       LastBit;
  //logic       EndOfFrame;
  //logic       EndOfFrameDelay;
  logic       PhaseOneOffset;

  // Transmit Stuff
  logic       ContinueTransmit;       

  // SPIOUT Stuff
  // logic       TransmitLoad;
  logic [7:0] TransmitReg;
  //logic       Transmitting;
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
  
  assign SCLKenable = DivCounter == SckDiv;
  // assign SCLKenableEarly = (DivCounter + 1'b1) == SckDiv;
  assign LastBit = (BitNum == FrameLength - 4'b1);

  //assign EndOfFrame = SCLKenable & LastBit & Transmitting;
  assign ContinueTransmit = ~txFIFOReadEmpty & EndOfFrameDelay;
  assign EndTransmission = txFIFOReadEmpty & EndOfFrameDelay;
  
  always_ff @(posedge PCLK) begin
    if (~PRESETn) begin
      DivCounter <= 12'b0;
      SPICLK <= SckMode[1];
      SCK <= 0;
      BitNum <= 4'h0;
      PreShiftEdge <= 0;
      PreSampleEdge <= 0;
      EndOfFrame <= 0;
      CSSCKCounter <= 0;
      SCKCSCounter <= 0;
      INTERCSCounter <= 0;
      INTERXFRCounter <= 0;
    end else begin
      // TODO: Consolidate into one delay counter since none of the
      // delays happen at the same time?
      if (TransmitStart) begin
        SCK <= 0;
      end else if (SCLKenable) begin
        SCK <= ~SCK;
      end
      
      if ((CurrState == CSSCK) & SCK & SCLKenable) begin
        CSSCKCounter <= CSSCKCounter + 8'd1;
      end else if (SCLKenable & EndOfCSSCK) begin
        CSSCKCounter <= 8'd0;
      end
      
      if ((CurrState == SCKCS) & SCK & SCLKenable) begin
        SCKCSCounter <= SCKCSCounter + 8'd1;
      end else if (SCLKenable & EndOfSCKCS) begin
        SCKCSCounter <= 8'd0;
      end
      
      if ((CurrState == INTERCS) & SCK & SCLKenable) begin
        INTERCSCounter <= INTERCSCounter + 8'd1;
      end else if (SCLKenable & EndOfINTERCS) begin
        INTERCSCounter <= 8'd0;
      end
      
      if ((CurrState == INTERXFR) & SCK & SCLKenable) begin
        INTERXFRCounter <= INTERXFRCounter + 8'd1;
      end else if (SCLKenable & EndOfINTERXFR) begin
        INTERXFRCounter <= 8'd0;
      end
      
      // SPICLK Logic
      if (TransmitStart) begin
        SPICLK <= SckMode[1];
      end else if (SCLKenable & Transmitting) begin
        SPICLK <= (~EndTransmission & ~DelayIsNext) ? ~SPICLK : SckMode[1];
      end
      
      // Reset divider 
      if (SCLKenable | TransmitStart | ResetSCLKenable) begin
        DivCounter <= 12'b0;
      end else begin
        DivCounter <= DivCounter + 12'd1;
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
        BitNum <= BitNum + 4'd1;
      end else if (EndOfFrameDelay) begin
        BitNum <= 4'b0;  
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
      case(SckMode)
        2'b00: begin
          ShiftEdge <= SPICLK & SCLKenable & ~LastBit & Transmitting;
          SampleEdge <= ~SPICLK & SCLKenable & Transmitting & ~DelayIsNext;
          EndOfFrameDelay <= SPICLK & SCLKenable & LastBit & Transmitting;
        end
        2'b01: begin
          ShiftEdge <= ~SPICLK & SCLKenable & ~LastBit & Transmitting & PhaseOneOffset;
          SampleEdge <= SPICLK & SCLKenable & Transmitting & ~DelayIsNext;
          EndOfFrameDelay <= ~SPICLK & SCLKenable & LastBit & Transmitting;
          PhaseOneOffset <= (PhaseOneOffset == 0) ? Transmitting & SCLKenable : ~EndOfFrameDelay;
        end
        2'b10: begin
          ShiftEdge <= ~SPICLK & SCLKenable & ~LastBit & Transmitting;
          SampleEdge <= SPICLK & SCLKenable & Transmitting & ~DelayIsNext;
          EndOfFrameDelay <= ~SPICLK & SCLKenable & LastBit & Transmitting;
        end
        2'b11: begin
          ShiftEdge <= SPICLK & SCLKenable & ~LastBit & Transmitting & PhaseOneOffset;
          SampleEdge <= ~SPICLK & SCLKenable & Transmitting & ~DelayIsNext;
          EndOfFrameDelay <= SPICLK & SCLKenable & LastBit & Transmitting;
          PhaseOneOffset <= (PhaseOneOffset == 0) ? Transmitting & SCLKenable : ~EndOfFrameDelay;
        end
      // ShiftEdge <= ((SckMode[1] ^ SckMode[0] ^ SPICLK) & SCLKenable & ~LastBit & Transmitting) & PhaseOneOffset;
      // PhaseOneOffset <= PhaseOneOffset == 0 ? Transmitting & SCLKenable : ~EndOfFrameDelay;
      // SampleEdge <= (SckMode[1] ^ SckMode[0] ^ ~SPICLK) & SCLKenable & Transmitting & ~DelayIsNext;
        // EndOfFrameDelay <= (SckMode[1] ^ SckMode[0] ^ SPICLK) & SCLKenable & LastBit & Transmitting;
      endcase
    end
  end

  // typedef enum logic [2:0] {INACTIVE, CSSCK, TRANSMIT, SCKCS, HOLD, INTERCS, INTERXFR} statetype;
  // statetype CurrState, NextState;

  assign HoldMode = CSMode == HOLDMODE;
  // assign TransmitLoad = TransmitStart | (EndOfFrameDelay & ~txFIFOReadEmpty);

  logic ContinueTransmitD;
  logic NextEndDelay;
  logic CurrentEndDelay;

  assign NextEndDelay = NextState == SCKCS | NextState == INTERCS | NextState == INTERXFR;
  assign CurrentEndDelay = CurrState == SCKCS | CurrState == INTERCS | CurrState == INTERXFR;
  
  always_ff @(posedge PCLK) begin
    if (~PRESETn) begin
      ContinueTransmitD <= 1'b0;
    end else if (NextEndDelay & ~CurrentEndDelay) begin
      ContinueTransmitD <= ContinueTransmit;
    end else if (EndOfSCKCS & SCLKenable) begin
      ContinueTransmitD <= 1'b0;  
    end
  end
  
  always_ff @(posedge PCLK) begin
    if (~PRESETn) begin
      CurrState <= INACTIVE;
    end else if (SCLKenable) begin
      CurrState <= NextState;
    end
  end
  
  always_comb begin
    case (CurrState)  
      INACTIVE: if (TransmitStartD) begin
                  if (~HasCSSCK) NextState = TRANSMIT;
                  else NextState = CSSCK;
                end else begin
                  NextState = INACTIVE;
                end
      CSSCK: if (EndOfCSSCK) NextState = TRANSMIT;
             else NextState = CSSCK;
      TRANSMIT: begin // TRANSMIT case --------------------------------
        case(CSMode)
          AUTOMODE: begin  
            if (EndTransmission) NextState = INACTIVE;
            else if (EndOfFrameDelay) NextState = SCKCS;
            else NextState = TRANSMIT;
          end
          HOLDMODE: begin  
            if (EndTransmission) NextState = HOLD;  
            else if (ContinueTransmit & HasINTERXFR) NextState = INTERXFR;
            else NextState = TRANSMIT;
          end
          OFFMODE: begin
            if (EndTransmission) NextState = INACTIVE;
            else if (ContinueTransmit & HasINTERXFR) NextState = INTERXFR;
            else NextState = TRANSMIT;
          end
          default: NextState = TRANSMIT;
        endcase
      end
      SCKCS: begin // SCKCS case --------------------------------------
        if (EndOfSCKCS) begin
          if (~ContinueTransmitD) begin
            // if (CSMode == AUTOMODE) NextState = INACTIVE;
            if (CSMode == HOLDMODE) NextState = HOLD;
            else NextState = INACTIVE;
          end else begin
            if (HasINTERCS) NextState = INTERCS;
            else NextState = TRANSMIT;
          end
        end else begin
          NextState = SCKCS;
        end
      end
      HOLD: begin // HOLD mode case -----------------------------------
        if (CSMode == AUTOMODE) begin
          NextState = INACTIVE;
        end else if (TransmitStartD) begin // If FIFO is written to, start again.
          NextState = TRANSMIT;
        end else NextState = HOLD;
      end
      INTERCS: begin // INTERCS case ----------------------------------
        if (EndOfINTERCS) begin
          if (HasCSSCK) NextState = CSSCK;
          else NextState = TRANSMIT;
        end else begin
          NextState = INTERCS;  
        end
      end
      INTERXFR: begin // INTERXFR case --------------------------------
        if (EndOfINTERXFR) begin
          NextState = TRANSMIT;
        end else begin
          NextState = INTERXFR;  
        end
      end
      default: begin
        NextState = INACTIVE;
      end
    endcase
  end

  assign Transmitting = CurrState == TRANSMIT;
  assign DelayIsNext = (NextState == CSSCK | NextState == SCKCS | NextState == INTERCS | NextState == INTERXFR);
  assign InactiveState = CurrState == INACTIVE | CurrState == INTERCS;
  
endmodule
