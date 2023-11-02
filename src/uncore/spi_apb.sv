///////////////////////////////////////////
// spi_apb.sv
//
// Written: Naiche Whyte-Aguayo nwhyteaguayo@g.hmc.edu 11/16/2022

//
// Purpose: SPI peripheral
//   See FU540-C000-v1.0 for specifications
// 
// A component of the Wally configurable RISC-V project.
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

// Current limitations: Flash read sequencer mode not implemented, dual and quad modes untestable with current test plan.
// Hardware interlock change to busy signal
// write tests for fifo full and empty watermark edge cases
// HoldModeDeassert make sure still works
// Comment on FIFOs: watermark calculations
// Comment all interface and internal signals on the lines they are declared
// Get tabs correct so things line up
// Relook at frame compare/ Delay count logic w/o multibit 
// look at ReadIncrement/WriteIncrement delay necessity 
// test case for two's complement rollover on fifo watermark calculation + watermark calc redesign
/* high level explanation of architecture
SPI module is written to the specifications described in FU540-C000-v1.0. At the top level, it is consists of synchronous 8 byte transmit and recieve FIFOs connected to shift registers. 
The FIFOs are connected to WALLY by an apb bus control register interface, which includes various control registers for modifying the SPI transmission along with registers for writing
to the transmit FIFO and reading from the receive FIFO. The transmissions themselves are then controlled by a finite state machine. The SPI module uses 4 tristate pins for SPI input/output, 
along with a 4 bit Chip Select signal, a clock signal, and an interrupt signal to WALLY. 
*/

module spi_apb import cvw::*; #(parameter cvw_t P) (
    input  logic                PCLK, PRESETn,
    input  logic                PSEL,
    input  logic [7:0]          PADDR,
    input  logic [P.XLEN-1:0]   PWDATA,
    input  logic [P.XLEN/8-1:0] PSTRB,
    input  logic                PWRITE,
    input  logic                PENABLE,
    output logic                PREADY,
    output logic [P.XLEN-1:0]   PRDATA,
    output logic                SPIOut,
    input  logic                SPIIn,
    output logic [3:0]          SPICS,
    output logic                SPIIntr
);

    //SPI registers

    logic [11:0] SckDiv;
    logic [1:0] SckMode;
    logic [1:0] ChipSelectID;
    logic [3:0] ChipSelectDef; 
    logic [1:0] ChipSelectMode;
    logic [15:0] Delay0, Delay1;
    logic [4:0] Format;
    logic [8:0] ReceiveData;
    logic [8:0] ReceiveDataPlaceholder;
    logic [2:0] TransmitWatermark, ReceiveWatermark;
    logic [8:0] TransmitData;
    logic [1:0] InterruptEnable, InterruptPending;

    //bus interface signals
    logic [7:0] Entry;
    logic Memwrite;
    logic [31:0] Din, Dout;

    //FIFO FSM signals
    logic TransmitWriteMark, TransmitReadMark, RecieveWriteMark, RecieveReadMark;
    logic TransmitFIFOWriteFull, TransmitFIFOReadEmpty;
    logic TransmitFIFOReadIncrement;
    logic TransmitFIFOWriteIncrement;
    logic ReceiveFIFOReadIncrement;

    logic ReceiveFIFOWriteFull, ReceiveFIFOReadEmpty;
    logic [7:0] TransmitFIFOReadData, ReceiveFIFOWriteData;
    logic [2:0] TransmitWriteWatermarkLevel, ReceiveReadWatermarkLevel;

    logic TransmitFIFOReadEmptyDelay;
    logic [7:0] ReceiveShiftRegEndian;

    //transmission signals
    logic sck;
    logic [11:0] DivCounter;
    logic SCLKenable;
    logic [8:0] Delay0Count;
    logic [8:0] Delay1Count;
    logic Delay0Compare;
    logic Delay1Compare;
    logic InterCSCompare;
    logic [8:0] InterCSCount;
    logic InterXFRCompare;
    logic [8:0] InterXFRCount;
    logic [3:0] ChipSelectInternal;
    logic [4:0] FrameCount;
    logic [4:0] FrameCompare;

    logic FrameCompareBoolean;
    logic [4:0] ReceivePenultimateFrame;
    logic [4:0] ReceivePenultimateFrameCount;
    logic ReceivePenultimateFrameBoolean;
    logic [4:0] FrameCompareProtocol;
    logic ReceiveShiftFull;
    logic TransmitShiftEmpty;
    logic HoldModeDeassert;


    //state fsm signals
    logic Active;
    logic Active0;
    logic Inactive;

    //shift reg signals
    logic TransmitFIFOWriteIncrementDelay;
    logic sckPhaseSelect;
    logic [7:0] TransmitShiftReg;
    logic [7:0] ReceiveShiftReg;
    logic SampleEdge;
    logic [7:0] TransmitDataEndian;
    logic TransmitShiftRegLoad;

    //CS signals
    logic [3:0] ChipSelectAuto, ChipSelectHold, CSoff;
    logic ChipSelectHoldSingle;

    logic ReceiveShiftFullDelay;

    logic SCLKenableDelay;
    logic shiftin;
    logic [7:0] ReceiveShiftRegInvert;
    logic ZeroDelayHoldMode;
    logic TransmitInactive;
    logic SCLKenableEarly;
    logic ReceiveShiftFullDelayPCLK;
    logic [3:0] LeftShiftAmount;
    logic [7:0] ASR; // AlignedReceiveShiftReg
    logic DelayMode;
    logic [3:0] PWChipSelect;

    // APB access
    assign Entry = {PADDR[7:2],2'b00};  // 32-bit word-aligned accesses
    assign Memwrite = PWRITE & PENABLE & PSEL;  // only write in access phase
    assign PREADY = 1'b1; // tie high if hardware interlock solution doesn't involve bus
    //assign PREADY = TransmitInactive; // tie PREADY to transmission for hardware interlock

    // account for subword read/write circuitry
    // -- Note SPI registers are 32 bits no matter what; access them with LW SW.
   
    assign Din = PWDATA[31:0]; 
    if (P.XLEN == 64) assign PRDATA = {Dout, Dout}; 
    else              assign PRDATA = Dout;  

    // register access  *** clean this up
    always_ff@(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin 
            SckDiv <= #1 12'd3;
            SckMode <= #1 2'b0;
            ChipSelectID <= #1 2'b0;
            ChipSelectDef <= #1 4'b1111;
            ChipSelectMode <= #1 0;
            Delay0 <= #1 {8'b1,8'b1};
            Delay1 <= #1 {8'b0,8'b1};
            Format <= #1 {5'b10000};
            TransmitData <= #1 9'b0;
            TransmitWatermark <= #1 3'b0;
            ReceiveWatermark <= #1 3'b0;
            InterruptEnable <= #1 2'b0;
            InterruptPending <= #1 2'b0;
        end else begin //writes
            //According to FU540 spec: Once interrupt is pending, it will remain set until number 
            //of entries in tx/rx fifo is strictly more/less than tx/rxmark

            /* verilator lint_off CASEINCOMPLETE */
            if (Memwrite)
                case(Entry) //flop to sample inputs
                    8'h00: SckDiv <= Din[11:0];
                    8'h04: SckMode <= Din[1:0];
                    8'h10: ChipSelectID <= Din[1:0];
                    8'h14: ChipSelectDef <= Din[3:0];
                    8'h18: ChipSelectMode <= Din[1:0];
                    8'h28: Delay0 <= {Din[23:16], Din[7:0]};
                    8'h2C: Delay1 <= {Din[23:16], Din[7:0]};
                    8'h40: Format <= {Din[19:16], Din[2]};
                    8'h48: if (~TransmitFIFOWriteFull) TransmitData[7:0] <= Din[7:0];
                    8'h50: TransmitWatermark <= Din[2:0];
                    8'h54: ReceiveWatermark <= Din[2:0];
                    8'h70: InterruptEnable <= Din[1:0];
                endcase
            /* verilator lint_off CASEINCOMPLETE */
            //interrupt clearance
            InterruptPending[0] <= TransmitReadMark;
            InterruptPending[1] <= RecieveWriteMark;  
            case(Entry) // flop to sample inputs
                8'h00: Dout <= #1 {20'b0, SckDiv};
                8'h04: Dout <= #1 {30'b0, SckMode};
                8'h10: Dout <= #1 {30'b0, ChipSelectID};
                8'h14: Dout <= #1 {28'b0, ChipSelectDef};
                8'h18: Dout <= #1 {30'b0, ChipSelectMode};
                8'h28: Dout <= {8'b0, Delay0[15:8], 8'b0, Delay0[7:0]};
                8'h2C: Dout <= {8'b0, Delay1[15:8], 8'b0, Delay1[7:0]};
                8'h40: Dout <= {12'b0, Format[4:1], 13'b0, Format[0], 2'b0};
                8'h48: Dout <= #1 {23'b0, TransmitFIFOWriteFull, 8'b0};
                8'h4C: Dout <= #1 {23'b0, ReceiveFIFOReadEmpty, ReceiveData[7:0]};
                8'h50: Dout <= #1 {29'b0, TransmitWatermark};
                8'h54: Dout <= #1 {29'b0, ReceiveWatermark};
                8'h70: Dout <= #1 {30'b0, InterruptEnable};
                8'h74: Dout <= #1 {30'b0, InterruptPending};
                default: Dout <= #1 32'b0;
            endcase
        end

    // SPI enable generation, where SCLK = PCLK/(2*(SckDiv + 1))
    // generates a high signal at the rising and falling edge of SCLK by counting from 0 to SckDiv
    assign SCLKenable = (DivCounter == SckDiv);
    assign SCLKenableEarly = ((DivCounter + 12'b1) == SckDiv);
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) DivCounter <= #1 0;
        else if (SCLKenable) DivCounter <= 0;
        else DivCounter <= DivCounter + 12'b1;

    //Boolean logic that tracks frame progression
    assign FrameCompare = {1'b0,Format[4:1]};
    assign FrameCompareBoolean = (FrameCount < FrameCompare);
    assign ReceivePenultimateFrameCount = FrameCount + 5'b00001;
    assign ReceivePenultimateFrameBoolean = (ReceivePenultimateFrameCount >= FrameCompare);

    // Computing delays
    // When sckmode.pha = 0, an extra half-period delay is implicit in the cs-sck delay, and vice-versa for sck-cs
    assign Delay0Compare = SckMode[0] ? (Delay0Count >= ({Delay0[7:0], 1'b0})) : (Delay0Count >= ({Delay0[7:0], 1'b0} + 9'b1));
    assign Delay1Compare = SckMode[0] ? (Delay1Count >= (({Delay0[15:8], 1'b0}) + 9'b1)) : (Delay1Count >= ({Delay0[15:8], 1'b0}));
    assign InterCSCompare = (InterCSCount >= ({Delay1[7:0],1'b0}));
    assign InterXFRCompare = (InterXFRCount >= ({Delay1[15:8], 1'b0}));

    //calculate when tx/rx shift registers are full/empty
    TransmitShiftFSM TransmitShiftFSM_1 (PCLK, PRESETn, TransmitFIFOReadEmpty, ReceivePenultimateFrameBoolean, Active0, TransmitShiftEmpty);
    ReceiveShiftFSM ReceiveShiftFSM_1 (PCLK, PRESETn, SCLKenable, ReceivePenultimateFrameBoolean, SampleEdge, SckMode[0], ReceiveShiftFull);

    //calculate tx/rx fifo write and recieve increment signals 
    assign TransmitFIFOWriteIncrement = (Memwrite & (Entry == 8'h48) & ~TransmitFIFOWriteFull);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TransmitFIFOWriteIncrementDelay <= 0;
        else TransmitFIFOWriteIncrementDelay <= TransmitFIFOWriteIncrement;

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveFIFOReadIncrement <= 0;
        else ReceiveFIFOReadIncrement <= ((Entry == 8'h4C) & ~ReceiveFIFOReadEmpty & PSEL & ~ReceiveFIFOReadIncrement);
    
    //tx/rx FIFOs
    SynchFIFO #(3,8) txFIFO(PCLK, 1'b1, SCLKenable, PRESETn, TransmitFIFOWriteIncrementDelay, TransmitShiftEmpty, TransmitData[7:0], TransmitWriteWatermarkLevel, TransmitWatermark[2:0], TransmitFIFOReadData[7:0], TransmitFIFOWriteFull, TransmitFIFOReadEmpty, TransmitWriteMark, TransmitReadMark);
    SynchFIFO #(3,8) rxFIFO(PCLK, SCLKenable, 1'b1, PRESETn, ReceiveShiftFullDelay, ReceiveFIFOReadIncrement, ReceiveShiftRegEndian, ReceiveWatermark[2:0], ReceiveReadWatermarkLevel, ReceiveData[7:0], ReceiveFIFOWriteFull, ReceiveFIFOReadEmpty, RecieveWriteMark, RecieveReadMark);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TransmitFIFOReadEmptyDelay <= 1;
        else  if (SCLKenable) TransmitFIFOReadEmptyDelay <= TransmitFIFOReadEmpty;

    
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveShiftFullDelay <= 0;
        else if (SCLKenable) ReceiveShiftFullDelay <= ReceiveShiftFull;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveShiftFullDelayPCLK <= 0;
        else if (SCLKenableEarly) ReceiveShiftFullDelayPCLK <= ReceiveShiftFull; 

    assign TransmitShiftRegLoad = ~TransmitShiftEmpty & ~Active | (((ChipSelectMode == 2'b10) & ~|(Delay1[15:8])) & ((ReceiveShiftFullDelay | ReceiveShiftFull) & ~SampleEdge & ~TransmitFIFOReadEmpty));

    //Main FSM which controls SPI transmission
    typedef enum logic [2:0] {CS_INACTIVE, DELAY_0, ACTIVE_0, ACTIVE_1, DELAY_1,INTER_CS, INTER_XFR} statetype;
    statetype state;

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin state <= CS_INACTIVE;
                            FrameCount <= 5'b0;                      

        /* verilator lint_off CASEINCOMPLETE */
        end else if (SCLKenable) begin
            case (state)
                CS_INACTIVE: begin
                        Delay0Count <= 9'b1;
                        Delay1Count <= 9'b10;
                        FrameCount <= 5'b0;
                        InterCSCount <= 9'b10;
                        InterXFRCount <= 9'b1;
                        if ((~TransmitFIFOReadEmpty | ~TransmitShiftEmpty) & ((|(Delay0[7:0])) | ~SckMode[0])) state <= DELAY_0;
                        else if ((~TransmitFIFOReadEmpty | ~TransmitShiftEmpty)) state <= ACTIVE_0;
                        end
                DELAY_0: begin
                        Delay0Count <= Delay0Count + 9'b1;
                        if (Delay0Compare) state <= ACTIVE_0;
                        end
                ACTIVE_0: begin 
                        FrameCount <= FrameCount + 5'b1;
                        state <= ACTIVE_1;
                        end
                ACTIVE_1: begin
                        InterXFRCount <= 9'b1;
                        if (FrameCompareBoolean) state <= ACTIVE_0;
                        else if (HoldModeDeassert) state <= CS_INACTIVE;
                        else if ((ChipSelectMode[1:0] == 2'b10) & ~|(Delay1[15:8]) & (~TransmitFIFOReadEmpty)) begin
                            state <= ACTIVE_0;
                            Delay0Count <= 9'b1;
                            Delay1Count <= 9'b10;
                            FrameCount <= 5'b0;
                            InterCSCount <= 9'b10;
                        end
                        else if (ChipSelectMode[1:0] == 2'b10) state <= INTER_XFR;
                        else if (~|(Delay0[15:8]) & (~SckMode[0])) state <= INTER_CS;
                        else state <= DELAY_1;
                        end
                DELAY_1: begin
                        Delay1Count <= Delay1Count + 9'b1;
                        if (Delay1Compare) state <= INTER_CS;
                        end
                INTER_CS: begin
                        InterCSCount <= InterCSCount + 9'b1;
                        if (InterCSCompare ) state <= CS_INACTIVE;
                        end
                INTER_XFR: begin
                        Delay0Count <= 9'b1;
                        Delay1Count <= 9'b10;
                        FrameCount <= 5'b0;
                        InterCSCount <= 9'b10;
                        InterXFRCount <= InterXFRCount + 9'b1;
                        if (HoldModeDeassert) state <= CS_INACTIVE;
                        else if (InterXFRCompare & ~TransmitFIFOReadEmptyDelay) state <= ACTIVE_0;
                        else if (~|ChipSelectMode[1:0]) state <= CS_INACTIVE;
                        end
            endcase
        end

            /* verilator lint_off CASEINCOMPLETE */

    assign DelayMode = SckMode[0] ? (state == DELAY_1) : (state == ACTIVE_1 & ReceiveShiftFull);
    assign ChipSelectInternal = (state == CS_INACTIVE | state == INTER_CS | DelayMode & ~|(Delay0[15:8])) ? ChipSelectDef : ~ChipSelectDef;
    assign sck = (state == ACTIVE_0) ? ~SckMode[1] : SckMode[1];
    assign Active = (state == ACTIVE_0 | state == ACTIVE_1);
    assign SampleEdge = SckMode[0] ? (state == ACTIVE_1) : (state == ACTIVE_0);
    assign ZeroDelayHoldMode = ((ChipSelectMode == 2'b10) & (~|(Delay1[7:4])));
    assign TransmitInactive = ((state == INTER_CS) | (state == CS_INACTIVE) | (state == INTER_XFR) | (ReceiveShiftFullDelayPCLK & ZeroDelayHoldMode));
    assign Active0 = (state == ACTIVE_0);
    assign Inactive = (state == CS_INACTIVE);

    // Ensures that when ChipSelectMode = hold, CS pin is deasserted only when a different value is written to csmode or csid or a write to csdeg changes the state
    // of the selected pin
    assign PWChipSelect = PWDATA[3:0];
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) HoldModeDeassert <= 0;
        else if (~Inactive & ((ChipSelectMode[1:0] == 2'b10) & (Entry == (8'h18 | 8'h10) | ((Entry == 8'h14) & (PWChipSelect[ChipSelectID] != ChipSelectDef[ChipSelectID])))) & Memwrite) HoldModeDeassert <= 1;

    // Signal tracks which edge of sck to shift data
    always_comb
        case(SckMode[1:0])
            2'b00: sckPhaseSelect = ~sck & SCLKenable;
            2'b01: sckPhaseSelect = (sck & |(FrameCount) & SCLKenable);
            2'b10: sckPhaseSelect = sck & SCLKenable;
            2'b11: sckPhaseSelect = (~sck & |(FrameCount) & SCLKenable);
            default: sckPhaseSelect = sck & SCLKenable;
        endcase

    //Transmit shift register
    assign TransmitDataEndian =  Format[0] ? {TransmitFIFOReadData[0], TransmitFIFOReadData[1], TransmitFIFOReadData[2], TransmitFIFOReadData[3], TransmitFIFOReadData[4], TransmitFIFOReadData[5], TransmitFIFOReadData[6], TransmitFIFOReadData[7]} : TransmitFIFOReadData[7:0];
    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn)                        TransmitShiftReg <= 8'b0; 
        else if (TransmitShiftRegLoad)      TransmitShiftReg <= TransmitDataEndian;
        else if (sckPhaseSelect & Active)   TransmitShiftReg <= {TransmitShiftReg[6:0], 1'b0};
    
    assign SPIOut = TransmitShiftReg[7];

    //If in loopback mode, receive shift register is connected directly to module's output pins. Else, connected to SPIIn
    //There are no setup/hold time issues because transmit shift register and receive shift register always shift/sample on opposite edges
    assign shiftin = P.SPI_LOOPBACK_TEST ? SPIOut : SPIIn;

    // Receive shift register
    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn)  ReceiveShiftReg <= 8'b0;
        else if (SampleEdge & SCLKenable) begin
            if (~Active) ReceiveShiftReg <= 8'b0;
            else ReceiveShiftReg <= {ReceiveShiftReg[6:0], shiftin};
        end

    // Aligns received data and reverses if little-endian
    assign LeftShiftAmount = 4'h8 - Format[4:1];
    assign ASR = ReceiveShiftReg << LeftShiftAmount[2:0];
    assign ReceiveShiftRegEndian = Format[0] ? {ASR[0], ASR[1], ASR[2], ASR[3], ASR[4], ASR[5], ASR[6], ASR[7]} : ASR[7:0];

    // Interrupt logic: raise interrupt if any enabled interrupts are pending
    assign SPIIntr = |(InterruptPending & InterruptEnable);

    // Chip select logic
    
    always_comb
        case(ChipSelectID[1:0])
            2'b00: ChipSelectAuto = {ChipSelectDef[3], ChipSelectDef[2], ChipSelectDef[1], ChipSelectInternal[0]};
            2'b01: ChipSelectAuto = {ChipSelectDef[3],ChipSelectDef[2], ChipSelectInternal[1], ChipSelectDef[0]};
            2'b10: ChipSelectAuto = {ChipSelectDef[3],ChipSelectInternal[2], ChipSelectDef[1], ChipSelectDef[0]};
            2'b11: ChipSelectAuto = {ChipSelectInternal[3],ChipSelectDef[2], ChipSelectDef[1], ChipSelectDef[0]};
        endcase

    assign SPICS = ChipSelectMode[0] ? ChipSelectDef : ChipSelectAuto;
endmodule

module SynchFIFO #(parameter M =3 , N= 8)(
    input logic PCLK, wen, ren, PRESETn,
    input logic winc,rinc,
    input logic [N-1:0] wdata,
    input logic [M-1:0] wwatermarklevel, rwatermarklevel,
    output logic [N-1:0] rdata,
    output logic wfull, rempty,
    output logic wwatermark, rwatermark);

    logic [N-1:0] mem[2**M];
    logic [M:0] rptr, wptr;
    logic [M:0] rptrnext, wptrnext;
    logic rempty_val;
    logic wfull_val;
    logic [M-1:0] raddr;
    logic [M-1:0] waddr;

    assign rdata = mem[raddr];
    always_ff @(posedge PCLK)
        if (winc & ~wfull) mem[waddr] <= wdata;

    // write and read are enabled 
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin 
            rptr <= 0;
            wptr <= 0;
            wfull <= 1'b0;
            rempty <= 1'b1;
        end
        else begin 
            if (wen) begin
                wfull <= wfull_val;
                wptr  <= wptrnext;
            end
            if (ren) begin 
                rptr <= rptrnext;
                rempty <= rempty_val;
            end
        end 

    assign raddr = rptr[M-1:0];
    assign rptrnext = rptr + {3'b0, (rinc & ~rempty)};      
    assign rempty_val = (wptr == rptrnext);
    assign rwatermark = ((raddr - waddr) < rwatermarklevel);

    assign waddr = wptr[M-1:0];
    assign wwatermark = ((waddr - raddr) > wwatermarklevel);
    assign wptrnext = wptr + {3'b0, (winc & ~wfull)};
    assign wfull_val = ({~wptrnext[M], wptrnext[M-1:0]} == rptr);
endmodule

module TransmitShiftFSM(
    input logic PCLK, PRESETn,
    input logic TransmitFIFOReadEmpty, ReceivePenultimateFrameBoolean, Active0,
    output logic TransmitShiftEmpty);

    typedef enum logic [1:0] {TransmitShiftEmptyState, TransmitShiftHoldState, TransmitShiftNotEmptyState} statetype;
    statetype TransmitState, TransmitNextState;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TransmitState <= TransmitShiftEmptyState;
        else          TransmitState <= TransmitNextState;

        always_comb
            case(TransmitState)
                TransmitShiftEmptyState: begin
                    if (TransmitFIFOReadEmpty | (~TransmitFIFOReadEmpty & (ReceivePenultimateFrameBoolean & Active0))) TransmitNextState = TransmitShiftEmptyState;
                    else if (~TransmitFIFOReadEmpty) TransmitNextState = TransmitShiftNotEmptyState;
                end
                TransmitShiftNotEmptyState: begin
                    if (ReceivePenultimateFrameBoolean & Active0) TransmitNextState = TransmitShiftEmptyState;
                    else TransmitNextState = TransmitShiftNotEmptyState;
                end
            endcase
        assign TransmitShiftEmpty = (TransmitNextState == TransmitShiftEmptyState);
endmodule

module ReceiveShiftFSM(
    input logic PCLK, PRESETn, SCLKenable,
    input logic ReceivePenultimateFrameBoolean, SampleEdge, SckMode,
    output logic ReceiveShiftFull
);
    typedef enum logic [1:0] {ReceiveShiftFullState, ReceiveShiftNotFullState, ReceiveShiftDelayState} statetype;
    statetype ReceiveState, ReceiveNextState;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveState <= ReceiveShiftNotFullState;
        else if (SCLKenable) begin
            case (ReceiveState)
                ReceiveShiftFullState: ReceiveState <= ReceiveShiftNotFullState;
                ReceiveShiftNotFullState: if (ReceivePenultimateFrameBoolean & (SampleEdge)) ReceiveState <= ReceiveShiftDelayState;
                                          else ReceiveState <= ReceiveShiftNotFullState;
                ReceiveShiftDelayState: ReceiveState <= ReceiveShiftFullState;
            endcase
        end

        assign ReceiveShiftFull = SckMode ? (ReceiveState == ReceiveShiftFullState) : (ReceiveState == ReceiveShiftDelayState);
endmodule






