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
// Hardware interlock cs_mode hold interaction 
// relook at fifo empty full logic; might be that watermark level is low when full








module spi_apb import cvw::*; #(parameter cvw_t P) (
    input  logic             PCLK, PRESETn,
    input  logic             PSEL,
    input  logic [7:0]       PADDR,
    input  logic [P.XLEN-1:0] PWDATA,
    input  logic [P.XLEN/8-1:0] PSTRB,
    input  logic             PWRITE,
    input  logic             PENABLE,
    output logic             PREADY,
    output logic [P.XLEN-1:0] PRDATA,
    output logic [3:0]          SPIOut,
    input  logic [3:0]          SPIIn,
    output logic [3:0]          SPICS,
    output logic                SPIIntr

);

    //SPI registers

    logic [11:0] SckDiv, HISckDiv;
    logic [1:0] SckMode, HISckMode;
    logic [1:0] ChipSelectID, HIChipSelectID;
    logic [3:0] ChipSelectDef, HIChipSelectDef; 
    logic [1:0] ChipSelectMode, HIChipSelectMode;
    logic [15:0] Delay0, Delay1, HIDelay0, HIDelay1;
    logic [7:0] Format, HIFormat;
    logic [8:0] ReceiveData;
    logic [8:0] ReceiveDataPlaceholder;
    logic [2:0] TransmitWatermark, ReceiveWatermark, HITransmitWatermark, HIReceiveWatermark;
    logic [8:0] TransmitData;
    logic [1:0] InterruptEnable, InterruptPending, HIInterruptEnable;

    //bus interface signals
    logic [7:0] Entry;
    logic Memwrite;
    logic [31:0] Din, Dout;
    logic busy;

    //FIFO FSM signals
    logic TransmitWriteMark, TransmitReadMark, RecieveWriteMark, RecieveReadMark;
    logic TransmitFIFOWriteFull, TransmitFIFOReadEmpty;
    logic TransmitFIFOWriteIncrement, TransmitFIFOReadIncrement;
    logic ReceiveFIFOWriteIncrement, ReceiveFIFOReadIncrement;

    logic ReceiveFIFOWriteFull, ReceiveFIFOReadEmpty;
    logic [7:0] TransmitFIFOReadData, ReceiveFIFOWriteData;
    logic [2:0] TransmitWriteWatermarkLevel, ReceiveReadWatermarkLevel;

    logic TransmitFIFOReadEmptyDelay;
    logic [7:0] ReceiveShiftRegEndian;

    //transmission signals
    logic sck;
    logic [12:0] DivCounter;
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
    logic [4:0] FrameCountShifted;
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
    logic [3:0] shiftin;
    logic [7:0] ReceiveShiftRegInvert;
    logic ZeroDelayHoldMode;
    logic TransmitInactive;
    logic SCLKenableEarly;
    logic ReceiveShiftFullDelayPCLK;

    
    assign Entry = {PADDR[7:2],2'b00};  // 32-bit word-aligned accesses
    assign Memwrite = PWRITE & PENABLE & PSEL;  // only write in access phase
    assign PREADY = 1'b1; // tie high if hardware interlock solution doesn't involve bus
    //assign PREADY = TransmitInactive; // tie PREADY to transmission for hardware interlock




    // account for subword read/write circuitry
    // -- Note GPIO registers are 32 bits no matter what; access them with LW SW.
    //    (At least that's what I think when FE310 spec says "only naturally aligned 32-bit accesses are supported")
    if (P.XLEN == 64) begin
        assign Din =    Entry[2] ? PWDATA[63:32] : PWDATA[31:0];
        assign PRDATA = Entry[2] ? {Dout,32'b0}  : {32'b0,Dout};
    end else begin // 32-bit
        assign Din = PWDATA[31:0];
        assign PRDATA = Dout;
    end

    // register access
    always_ff@(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin 
            SckDiv <= #1 12'd3;
            SckMode <= #1 2'b0;
            ChipSelectID <= #1 2'b0;
            ChipSelectDef <= #1 4'b1111;
            ChipSelectMode <= #1 0;
            Delay0 <= #1 {8'b1,8'b1};
            Delay1 <= #1 {8'b0,8'b1};
            Format <= #1 {8'b10000000};
            TransmitData <= #1 9'b0;
            //ReceiveData <= #1 9'b100000000;
            TransmitWatermark <= #1 3'b0;
            ReceiveWatermark <= #1 3'b0;
            InterruptEnable <= #1 2'b0;
            InterruptPending <= #1 2'b0;
            HISckDiv <= #1 12'd3;
            HISckMode <= #1 2'b0;
            HIChipSelectID <= #1 2'b0;
            HIChipSelectDef <= #1 4'b1111;
            HIChipSelectMode <= #1 0;
            HIDelay0 <= #1 {8'b1,8'b1};
            HIDelay1 <= #1 {8'b0,8'b1};
            HIFormat <= #1 {8'b10000000};
            HITransmitWatermark <= #1 3'b0;
            HIReceiveWatermark <= #1 3'b0;
            HIInterruptEnable <= #1 2'b0;
        end else begin //writes
            //According to FU540 spec: Once interrupt is pending, it will remain set until number 
            //of entries in tx/rx fifo is strictly more/less than tx/rxmark

            //From spec. "Hardware interlocks ensure that the current transfer completes before mode transitions and control register updates take effect"
            // Interpreting 'current transfer' as one frame
            /* verilator lint_off CASEINCOMPLETE */
            if (Memwrite)
                case(Entry) //flop to sample inputs
                    8'h00: HISckDiv <= Din[11:0];
                    8'h04: HISckMode <= Din[1:0];
                    8'h10: HIChipSelectID <= Din[1:0];
                    8'h14: HIChipSelectDef <= Din[3:0];
                    8'h18: HIChipSelectMode <= Din[1:0];
                    8'h28: HIDelay0 <= {Din[23:16], Din[7:0]};
                    8'h2C: HIDelay1 <= {Din[23:16], Din[7:0]};
                    8'h40: HIFormat <= {Din[19:16], Din[3:0]};
                    8'h48: if (~TransmitFIFOWriteFull) TransmitData[7:0] <= Din[7:0];
                    8'h50: HITransmitWatermark <= Din[2:0];
                    8'h54: HIReceiveWatermark <= Din[2:0];
                    8'h70: HIInterruptEnable <= Din[1:0];
                endcase
            if (TransmitInactive) begin
                SckDiv <= HISckDiv;
                SckMode <= HISckMode;
                ChipSelectID <= HIChipSelectID;
                ChipSelectDef <= HIChipSelectDef;
                ChipSelectMode <= HIChipSelectMode;
                Delay0 <= HIDelay0;
                Delay1 <= HIDelay1;
                Format <= HIFormat;
                TransmitWatermark <= HITransmitWatermark;
                ReceiveWatermark <= HIReceiveWatermark;
                InterruptEnable <= HIInterruptEnable;
            end
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
                8'h40: Dout <= {12'b0, Format[7:4], 12'b0, Format[3:0]};
                8'h48: Dout <= #1 {23'b0, TransmitFIFOWriteFull, 8'b0};
                8'h4C: Dout <= #1 {23'b0, ReceiveFIFOReadEmpty, ReceiveData[7:0]};
                8'h50: Dout <= #1 {29'b0, TransmitWatermark};
                8'h54: Dout <= #1 {29'b0, ReceiveWatermark};
                8'h70: Dout <= #1 {30'b0, InterruptEnable};
                8'h74: Dout <= #1 {30'b0, InterruptPending};
                default: Dout <= #1 32'b0;
            endcase
        end
    
    
    

    assign SCLKenable = (DivCounter >= {1'b0,SckDiv});
    assign SCLKenableEarly = ((DivCounter + 13'b1) >= {1'b0, SckDiv});

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) DivCounter <= #1 0;
        else if (SCLKenable) DivCounter <= 0;
        else DivCounter <= DivCounter + 13'b1;

    
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) SCLKenableDelay <= 0;
        else SCLKenableDelay <= SCLKenable;


    //SCK_CONTROL
    //multiplies frame count by 2 or 4 if in dual or quad mode

    always_comb
        case(Format[1:0])
            2'b00: FrameCountShifted = FrameCount;
            2'b01: FrameCountShifted = {FrameCount[3:0], 1'b0};
            2'b10: FrameCountShifted = {FrameCount[2:0], 2'b0};
            default: FrameCountShifted = FrameCount;
        endcase

    //Calculates penultimate frame 
    //Frame compare doubles number of frames in dual or qyad mode to account for half-duplex communication
    //FrameCompareProtocol further adjusts comparison according to dual or quad mode

    always_comb
        case(Format[1:0])
            2'b00: begin
                    ReceivePenultimateFrame = 5'b00001;
                    FrameCompareProtocol = FrameCompare;
                    end
            2'b01: begin
                    ReceivePenultimateFrame = 5'b00010;
                    //add 1 to count if # of bits is odd so doubled # will be correct 
                    // for ex. 5 bits needs 3 frames, 5*2 = 10 which will be reached in 5 frames not 3*2.
                    FrameCompareProtocol = Format[4] ? FrameCompare + 5'b1 : FrameCompare;
                    end
            2'b10: begin 
                    ReceivePenultimateFrame = 5'b00100;
                    //if frame len =< 4, need 2 frames (one to send 1-4 bits, one to recieve)
                    //else, 4 < frame len =<8 8, which by same logic needs 4 frames
                    if (Format[7:4] > 4'b0100) FrameCompareProtocol = 5'b10000;
                    else FrameCompareProtocol = 5'b01000;
                    end
            default: begin
                    ReceivePenultimateFrame = 5'b00001;
                    FrameCompareProtocol = FrameCompare;
                    end

        endcase

    //Signals that track frame count comparisons

    assign FrameCompareBoolean = (FrameCountShifted < FrameCompareProtocol);
    assign ReceivePenultimateFrameCount = FrameCountShifted + ReceivePenultimateFrame;
    assign ReceivePenultimateFrameBoolean = (ReceivePenultimateFrameCount >= FrameCompareProtocol);

    // Computing delays
    // When sckmode.pha = 0, an extra half-period delay is implicit in the cs-sck delay, and vice-versa for sck-cs


    assign Delay0Compare = SckMode[0] ? (Delay0Count >= ({Delay0[7:0], 1'b0})) : (Delay0Count >= ({Delay0[7:0], 1'b0} + 9'b1));
    assign Delay1Compare = SckMode[0] ? (Delay1Count >= (({Delay0[15:8], 1'b0}) + 9'b1)) : (Delay1Count >= ({Delay0[15:8], 1'b0}));
    assign InterCSCompare = (InterCSCount >= ({Delay1[7:0],1'b0}));
    assign InterXFRCompare = (InterXFRCount >= ({Delay1[15:8], 1'b0}));


    // double number of frames in dual or quad mode because we must wait for peripheral to send back
    assign FrameCompare = (Format[0] | Format[1]) ? ({Format[7:4], 1'b0}) : {1'b0,Format[7:4]};

    // Transmit and Receive FIFOs

    //calculate when tx/rx shift registers are full/empty
    TransmitShiftFSM TransmitShiftFSM_1 (PCLK, PRESETn, TransmitFIFOReadEmpty, ReceivePenultimateFrameBoolean, Active0, TransmitShiftEmpty);
    ReceiveShiftFSM ReceiveShiftFSM_1 (PCLK, PRESETn, SCLKenable, ReceivePenultimateFrameBoolean, SampleEdge, SckMode[0], ReceiveShiftFull);

    //calculate tx/rx fifo write and recieve increment signals 
    assign TransmitFIFOWriteIncrement = (Memwrite & (Entry == 8'h48) & ~TransmitFIFOWriteFull);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TransmitFIFOWriteIncrementDelay <= 0;
        else TransmitFIFOWriteIncrementDelay <= TransmitFIFOWriteIncrement;

    assign TransmitFIFOReadIncrement = TransmitShiftEmpty;
    assign ReceiveFIFOWriteIncrement = ReceiveShiftFullDelay;

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveFIFOReadIncrement <= 0;
        else if (~ReceiveFIFOReadIncrement)    ReceiveFIFOReadIncrement <= ((Entry == 8'h4C) & ~ReceiveFIFOReadEmpty & PSEL);
        else            ReceiveFIFOReadIncrement <= 0;

    
    assign TransmitDataEndian =  Format[2] ? {TransmitData[0], TransmitData[1], TransmitData[2], TransmitData[3], TransmitData[4], TransmitData[5], TransmitData[6], TransmitData[7]} : TransmitData[7:0];

    TransmitSynchFIFO #(3,8) txFIFO(PCLK, SCLKenable, PRESETn, TransmitFIFOWriteIncrementDelay, TransmitFIFOReadIncrement, TransmitDataEndian, TransmitWriteWatermarkLevel, TransmitWatermark[2:0], TransmitFIFOReadData[7:0], TransmitFIFOWriteFull, TransmitFIFOReadEmpty, TransmitWriteMark, TransmitReadMark);
    ReceiveSynchFIFO #(3,8) rxFIFO(PCLK, SCLKenable, PRESETn, ReceiveFIFOWriteIncrement, ReceiveFIFOReadIncrement, ReceiveShiftRegEndian, ReceiveWatermark[2:0], ReceiveReadWatermarkLevel, ReceiveData[7:0], ReceiveFIFOWriteFull, ReceiveFIFOReadEmpty, RecieveWriteMark, RecieveReadMark);

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


    assign ChipSelectInternal = SckMode[0] ? ((state == CS_INACTIVE | state == INTER_CS | (state == DELAY_1 & ~|(Delay0[15:8]))) ? ChipSelectDef : ~ChipSelectDef) : ((state == CS_INACTIVE | state == INTER_CS | (state == ACTIVE_1 & ~|(Delay0[15:8]) & ReceiveShiftFull)) ? ChipSelectDef : ~ChipSelectDef);
    assign sck = (state == ACTIVE_0) ? ~SckMode[1] : SckMode[1];
    assign busy = (state == DELAY_0 | state == ACTIVE_0 | ((state == ACTIVE_1) & ~((|(Delay1[15:8]) & (ChipSelectMode[1:0]) == 2'b10) & ((FrameCount << Format[1:0]) >= FrameCompare))) | state == DELAY_1);
    assign Active = (state == ACTIVE_0 | state == ACTIVE_1);
    assign SampleEdge = SckMode[0] ? (state == ACTIVE_1) : (state == ACTIVE_0);
    assign ZeroDelayHoldMode = ((ChipSelectMode == 2'b10) & (~|(Delay1[7:4])));
    assign TransmitInactive = ((state == INTER_CS) | (state == CS_INACTIVE) | (state == INTER_XFR) | (ReceiveShiftFullDelayPCLK & ZeroDelayHoldMode));
    assign Active0 = (state == ACTIVE_0);
    assign Inactive = (state == CS_INACTIVE);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) HoldModeDeassert <= 0;
        else if (Inactive) HoldModeDeassert <= 0;
        /* verilator lint_off WIDTH */
        else if (((ChipSelectMode[1:0] == 2'b10) & (Entry == (8'h18 | 8'h10) | ((Entry == 8'h14) & ((PWDATA[ChipSelectID]) != ChipSelectDef[ChipSelectID])))) & Memwrite) HoldModeDeassert <= 1;
         /* verilator lint_on WIDTH */




    always_comb
        case(SckMode[1:0])
            2'b00: sckPhaseSelect = ~sck & SCLKenable;
            2'b01: sckPhaseSelect = (sck & |(FrameCount) & SCLKenable);
            2'b10: sckPhaseSelect = sck & SCLKenable;
            2'b11: sckPhaseSelect = (~sck & |(FrameCount) & SCLKenable);
            default: sckPhaseSelect = sck & SCLKenable;
        endcase


    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn) begin 
                TransmitShiftReg <= 8'b0;
            end
        else if (TransmitShiftRegLoad) TransmitShiftReg <= TransmitFIFOReadData;
        else if (sckPhaseSelect) begin
            //if ((ChipSelectMode[1:0] == 2'b10) & ~|(Delay1[15:8]) & (~TransmitFIFOReadEmpty) & TransmitShiftEmpty) TransmitShiftReg <= TransmitFIFOReadData;
            if (Active) begin
                case (Format[1:0])
                    2'b00: TransmitShiftReg <= {TransmitShiftReg[6:0], 1'b0};
                    2'b01: TransmitShiftReg <= {TransmitShiftReg[5:0], 2'b0};
                    2'b10: TransmitShiftReg <= {TransmitShiftReg[3:0], 4'b0};
                    default: TransmitShiftReg <= {TransmitShiftReg[6:0], 1'b0}; 
                endcase
            end
        end
    always_comb
    if (Active | Delay0Compare | ~TransmitShiftEmpty) begin
            case(Format[1:0])
                2'b00: SPIOut = {3'b0,TransmitShiftReg[7]}; 
                2'b01: SPIOut = {2'b0,TransmitShiftReg[6], TransmitShiftReg[7]};
                // assuming SPIOut[0] is first bit transmitted etc
                2'b10: SPIOut = {TransmitShiftReg[3], TransmitShiftReg[2], TransmitShiftReg[1], TransmitShiftReg[0]};
                default: SPIOut = {3'b0, TransmitShiftReg[7]};
            endcase
        end else SPIOut = 4'b0;
    
    assign shiftin = P.SPI_LOOPBACK_TEST ? SPIOut : SPIIn;
    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn)  ReceiveShiftReg <= 8'b0;
        else if (SampleEdge & SCLKenable) begin
            if (~Active) ReceiveShiftReg <= 8'b0;
            else if (~Format[3]) begin
                    case(Format[1:0])
                        2'b00: ReceiveShiftReg <= { ReceiveShiftReg[6:0], shiftin[0]};
                        2'b01: ReceiveShiftReg <= { ReceiveShiftReg[5:0], shiftin[0],shiftin[1]};
                        2'b10: ReceiveShiftReg <= { ReceiveShiftReg[3:0], shiftin[0], shiftin[1], shiftin[2], shiftin[3]};
                        default: ReceiveShiftReg <= { ReceiveShiftReg[6:0], shiftin[0]};
                    endcase
            end
        end
    
    assign ReceiveShiftRegInvert = (Format[2]) ? {ReceiveShiftReg[0], ReceiveShiftReg[1], ReceiveShiftReg[2], ReceiveShiftReg[3], ReceiveShiftReg[4], ReceiveShiftReg[5], ReceiveShiftReg[6], ReceiveShiftReg[7]} : ReceiveShiftReg[7:0];

    always_comb
        if (Format[2]) begin 
            case(Format[7:4])
                4'b0001: ReceiveShiftRegEndian = {7'b0, ReceiveShiftRegInvert[7]};
                4'b0010: ReceiveShiftRegEndian = {6'b0, ReceiveShiftRegInvert[7:6]};
                4'b0011: ReceiveShiftRegEndian = {5'b0, ReceiveShiftRegInvert[7:5]};
                4'b0100: ReceiveShiftRegEndian = {4'b0, ReceiveShiftRegInvert[7:4]};
                4'b0101: ReceiveShiftRegEndian = {3'b0, ReceiveShiftRegInvert[7:3]};
                4'b0110: ReceiveShiftRegEndian = {2'b0, ReceiveShiftRegInvert[7:2]};
                4'b0111: ReceiveShiftRegEndian = {1'b0, ReceiveShiftRegInvert[7:1]};
                4'b1000: ReceiveShiftRegEndian = ReceiveShiftRegInvert;
                default: ReceiveShiftRegEndian = ReceiveShiftRegInvert;
            endcase
        end else begin
            case(Format[7:4])
                4'b0001: ReceiveShiftRegEndian = {ReceiveShiftRegInvert[0], 7'b0};
                4'b0010: ReceiveShiftRegEndian = {ReceiveShiftRegInvert[1:0], 6'b0};
                4'b0011: ReceiveShiftRegEndian = {ReceiveShiftRegInvert[2:0], 5'b0};
                4'b0100: ReceiveShiftRegEndian = {ReceiveShiftRegInvert[3:0], 4'b0};
                4'b0101: ReceiveShiftRegEndian = {ReceiveShiftRegInvert[4:0], 3'b0};
                4'b0110: ReceiveShiftRegEndian = {ReceiveShiftRegInvert[5:0], 2'b0};
                4'b0111: ReceiveShiftRegEndian = {ReceiveShiftRegInvert[6:0], 1'b0};
                4'b1000: ReceiveShiftRegEndian = ReceiveShiftRegInvert;
                default: ReceiveShiftRegEndian = ReceiveShiftRegInvert;
            endcase
        end

    assign SPIIntr = |(InterruptPending & InterruptEnable);

    always_comb
        case(ChipSelectID[1:0])
            2'b00: ChipSelectAuto = {ChipSelectDef[3], ChipSelectDef[2], ChipSelectDef[1], ChipSelectInternal[0]};

            2'b01: ChipSelectAuto = {ChipSelectDef[3],ChipSelectDef[2], ChipSelectInternal[1], ChipSelectDef[0]};

            2'b10: ChipSelectAuto = {ChipSelectDef[3],ChipSelectInternal[2], ChipSelectDef[1], ChipSelectDef[0]};

            2'b11: ChipSelectAuto = {ChipSelectInternal[3],ChipSelectDef[2], ChipSelectDef[1], ChipSelectDef[0]};
        endcase

    assign SPICS = ChipSelectMode[0] ? ChipSelectDef : ChipSelectAuto;


endmodule

module TransmitSynchFIFO #(parameter M =3 , N= 8)(
    input logic PCLK, ren, PRESETn,
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

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) rptr <= 0;
        else if (ren) rptr <= rptrnext;
    

    assign raddr = rptr[M-1:0];
    assign rptrnext = rptr + {3'b0, (rinc & ~rempty)};      


    
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) wptr <= 0;
        else wptr <= wptrnext;

    assign waddr = wptr[M-1:0];
    assign wwatermark = ((wptr[M-1:0] - rptr[M-1:0]) > wwatermarklevel);
    assign wptrnext = wptr + {3'b0, (winc & ~wfull)};

    assign rempty_val = (wptr == rptrnext);
    assign wfull_val = ({~wptrnext[M], wptrnext[M-1:0]} == rptr);

    assign rwatermark = ((rptr[M-1:0] - wptr[M-1:0]) < rwatermarklevel);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) wfull <= 1'b0;
        else          wfull <= wfull_val;

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) rempty <= 1'b1;
        else if (ren)         rempty <= rempty_val;


endmodule


module ReceiveSynchFIFO #(parameter M =3 , N= 8)(
    input logic PCLK, ren, PRESETn,
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
        if(winc & ~wfull & PCLK) mem[waddr] <= wdata;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) rptr <= 0;
        else rptr <= rptrnext;
    assign rwatermark = ((rptr[M-1:0] - wptr[M-1:0]) < rwatermarklevel);
    assign raddr = rptr[M-1:0];
    assign rptrnext = rptr + {3'b0, (rinc & ~rempty)};
    assign rempty_val = (wptr == rptrnext);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) rempty <= 1'b1;
        else rempty <= rempty_val;

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) wptr <= 0;
        else if (ren) wptr <= wptrnext;

    assign waddr = wptr[M-1:0];
    assign wwatermark = ((wptr[M-1:0] - rptr[M-1:0]) > wwatermarklevel);
    assign wptrnext = wptr + {3'b0, (winc & ~wfull)};

    assign wfull_val = ({~wptrnext[M], wptrnext[M-1:0]} == rptr);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) wfull <= 1'b0;
        else if (ren) wfull <= wfull_val;
    
endmodule

module TransmitFIFO #(parameter M = 3, N = 8)(
    input logic wclk, rclk, PRESETn,
    input logic winc,rinc,
    input logic [N-1:0] wdata,
    input logic [M-1:0] wwatermarklevel, rwatermarklevel,
    output logic [N-1:0] rdata,
    output logic wfull, rempty,
    output logic wwatermark, rwatermark);

    logic [N-1:0] mem[2**M];
    logic [M:0] wq1_rptr, wq2_rptr, rptr;
    logic [M:0] rq1_wptr, rq2_wptr, wptr;
    logic [M:0] rbin, rgraynext, rbinnext;
    logic [M:0] wbin, wgraynext, wbinnext;
    logic rempty_val;
    logic wfull_val;
    logic [M:0]  wq2_rptr_bin, rq2_wptr_bin;
    logic [M-1:0] raddr;
    logic [M-1:0] waddr;

    assign rdata = mem[raddr];
    always_ff @(posedge wclk)
        if(winc & ~wfull) mem[waddr] <= wdata;


    always_ff @(posedge wclk, negedge PRESETn)
        if (~PRESETn) begin
            wq2_rptr <= 0;
            wq1_rptr <= 0;
        end
        else begin
            wq2_rptr <= wq1_rptr;
            wq1_rptr <= rptr;
        end

    always_ff @(posedge wclk, negedge PRESETn)
        if (~PRESETn) begin
            rq2_wptr <= 0;
            rq1_wptr <= 0;
        end
        else if (rclk) begin 

            rq2_wptr <= rq1_wptr;
            rq1_wptr <= wptr;
        end

    always_ff @(posedge wclk, negedge PRESETn)
        if(~PRESETn) begin
            rbin <= 0;
            rptr <= 0;
        end
        else if (rclk) begin
            rbin <= rbinnext;
            rptr <= rgraynext;
        end
    assign rq2_wptr_bin = {rq2_wptr[3], (rq2_wptr[3]^rq2_wptr[2]),(rq2_wptr[3]^rq2_wptr[2]^rq2_wptr[1]), (rq2_wptr[3]^rq2_wptr[2]^rq2_wptr[1]^rq2_wptr[0]) };
    assign rwatermark = ((rbin[M-1:0] - rq2_wptr_bin[M-1:0]) < rwatermarklevel);
    assign raddr = rbin[M-1:0];
    assign rbinnext = rbin + {3'b0, (rinc & ~rempty)};
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;
    assign rempty_val = (rgraynext == rq2_wptr);

    always_ff @(posedge wclk, negedge PRESETn)
        if (~PRESETn) rempty <= 1'b1;
        else if (rclk)         rempty <= rempty_val;

    always_ff @(posedge wclk, negedge PRESETn)
        if (~PRESETn) begin 
            wbin <= 0;
            wptr <= 0;
        end else begin               
            wbin <= wbinnext;
            wptr <= wgraynext;
        end
    assign waddr = wbin[M-1:0];
    assign wq2_rptr_bin = {wq2_rptr[3], (wq2_rptr[3]^wq2_rptr[2]),(wq2_rptr[3]^wq2_rptr[2]^wq2_rptr[1]), (wq2_rptr[3]^wq2_rptr[2]^wq2_rptr[1]^wq2_rptr[0]) };
    assign wwatermark = ((wbin[M-1:0] - wq2_rptr_bin[M-1:0]) > wwatermarklevel);
    assign wbinnext = wbin + {3'b0, (winc & ~wfull)};
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    assign wfull_val = (wgraynext == {(~wq2_rptr[M:M-1]),wq2_rptr[M-2:0]});

    always_ff @(posedge wclk, negedge PRESETn)
        if (~PRESETn) wfull <= 1'b0;
        else          wfull <= wfull_val;

endmodule

module ReceiveFIFO #(parameter M = 3, N = 8)(
    input logic wclk, rclk, PRESETn,
    input logic winc,rinc,
    input logic [N-1:0] wdata,
    input logic [M-1:0] wwatermarklevel, rwatermarklevel,
    output logic [N-1:0] rdata,
    output logic wfull, rempty,
    output logic wwatermark, rwatermark);

    logic [N-1:0] mem[2**M];
    logic [M:0] wq1_rptr, wq2_rptr, rptr;
    logic [M:0] rq1_wptr, rq2_wptr, wptr;
    logic [M:0] rbin, rgraynext, rbinnext;
    logic [M:0] wbin, wgraynext, wbinnext;
    logic rempty_val;
    logic wfull_val;
    logic [M:0]  wq2_rptr_bin, rq2_wptr_bin;
    logic [M-1:0] raddr;
    logic [M-1:0] waddr;

    assign rdata = mem[raddr];
    always_ff @(posedge rclk)
        if(winc & ~wfull & wclk) mem[waddr] <= wdata;


    always_ff @(posedge rclk, negedge PRESETn)
        if (~PRESETn) begin
            wq2_rptr <= 0;
            wq1_rptr <= 0;
        end
        else if (wclk) begin
            wq2_rptr <= wq1_rptr;
            wq1_rptr <= rptr;
        end

    always_ff @(posedge rclk, negedge PRESETn)
        if (~PRESETn) begin
            rq2_wptr <= 0;
            rq1_wptr <= 0;
        end
        else begin
            rq2_wptr <= rq1_wptr;
            rq1_wptr <= wptr;
        end

    always_ff @(posedge rclk, negedge PRESETn)
        if(~PRESETn) begin
            rbin <= 0;
            rptr <= 0;
        end
        else begin
            rbin <= rbinnext;
            rptr <= rgraynext;
        end
    assign rq2_wptr_bin = {rq2_wptr[3], (rq2_wptr[3]^rq2_wptr[2]),(rq2_wptr[3]^rq2_wptr[2]^rq2_wptr[1]), (rq2_wptr[3]^rq2_wptr[2]^rq2_wptr[1]^rq2_wptr[0]) };
    assign rwatermark = ((rbin[M-1:0] - rq2_wptr_bin[M-1:0]) < rwatermarklevel);
    assign raddr = rbin[M-1:0];
    assign rbinnext = rbin + {3'b0, (rinc & ~rempty)};
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;
    assign rempty_val = (rgraynext == rq2_wptr);

    always_ff @(posedge rclk, negedge PRESETn)
        if (~PRESETn) rempty <= 1'b1;
        else          rempty <= rempty_val;

    always_ff @(posedge rclk, negedge PRESETn)
        if (~PRESETn) begin 
            wbin <= 0;
            wptr <= 0;
        end else if (wclk) begin               
            wbin <= wbinnext;
            wptr <= wgraynext;
        end
    assign waddr = wbin[M-1:0];
    assign wq2_rptr_bin = {wq2_rptr[3], (wq2_rptr[3]^wq2_rptr[2]),(wq2_rptr[3]^wq2_rptr[2]^wq2_rptr[1]), (wq2_rptr[3]^wq2_rptr[2]^wq2_rptr[1]^wq2_rptr[0]) };
    assign wwatermark = ((wbin[M-1:0] - wq2_rptr_bin[M-1:0]) > wwatermarklevel);
    assign wbinnext = wbin + {3'b0, (winc & ~wfull)};
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    assign wfull_val = (wgraynext == {(~wq2_rptr[M:M-1]),wq2_rptr[M-2:0]});

    always_ff @(posedge rclk, negedge PRESETn)
        if (~PRESETn) wfull <= 1'b0;
        else if (wclk)        wfull <= wfull_val;

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






