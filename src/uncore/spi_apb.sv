///////////////////////////////////////////
// spi_apb.sv
//
// Written: Naiche Whyte-Aguayo nwhyteaguayo@g.hmc.edu 11/16/2022
//
// Purpose: SPI peripheral
//
// SPI module is written to the specifications described in FU540-C000-v1.0. At the top level, it is consists of synchronous 8 byte transmit and recieve FIFOs connected to shift registers. 
// The FIFOs are connected to WALLY by an apb control register interface, which includes various control registers for modifying the SPI transmission along with registers for writing
// to the transmit FIFO and reading from the receive FIFO. The transmissions themselves are then controlled by a finite state machine. The SPI module uses 4 tristate pins for SPI input/output, 
// along with a 4 bit Chip Select signal, a clock signal, and an interrupt signal to WALLY.
// Current limitations: Flash read sequencer mode not implemented, dual and quad mode not supported
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

    // register map
    localparam SPI_SCKDIV =  8'h00;
    localparam SPI_SCKMODE = 8'h04;
    localparam SPI_CSID =    8'h10;
    localparam SPI_CSDEF =   8'h14;
    localparam SPI_CSMODE =  8'h18;
    localparam SPI_DELAY0 =  8'h28;
    localparam SPI_DELAY1 =  8'h2C;
    localparam SPI_FMT =     8'h40;
    localparam SPI_TXDATA =  8'h48;
    localparam SPI_RXDATA =  8'h4C;
    localparam SPI_TXMARK =  8'h50;
    localparam SPI_RXMARK =  8'h54;
    localparam SPI_IE =      8'h70;
    localparam SPI_IP =      8'h74;

    // SPI control registers. Refer to SiFive FU540-C000 manual 
    logic [11:0] SckDiv;
    logic [1:0]  SckMode;
    logic [1:0]  ChipSelectID;
    logic [3:0]  ChipSelectDef; 
    logic [1:0]  ChipSelectMode;
    logic [15:0] Delay0, Delay1;
    logic [4:0]  Format;
    logic [7:0]  ReceiveData;
    logic [2:0]  TransmitWatermark, ReceiveWatermark;
    logic [8:0]  TransmitData;
    logic [1:0]  InterruptEnable, InterruptPending;

    // Bus interface signals
    logic [7:0] Entry;
    logic Memwrite;
    logic [31:0] Din,  Dout;
    logic TransmitInactive;                         // High when there is no transmission, used as hardware interlock signal

    // FIFO FSM signals
    // Watermark signals - TransmitReadMark = ip[0], ReceiveWriteMark = ip[1]
    logic TransmitWriteMark, TransmitReadMark, RecieveWriteMark, RecieveReadMark; 
    logic TransmitFIFOWriteFull, TransmitFIFOReadEmpty;
    logic TransmitFIFOWriteIncrement;
    logic ReceiveFIFOReadIncrement;
    logic ReceiveFIFOWriteFull, ReceiveFIFOReadEmpty;
    logic [7:0] TransmitFIFOReadData;
    logic [2:0] TransmitWriteWatermarkLevel, ReceiveReadWatermarkLevel;
    logic [7:0] ReceiveShiftRegEndian;              // Reverses ReceiveShiftReg if Format[2] set (little endian transmission)

    // Transmission signals
    logic sck;
    logic [11:0] DivCounter;                        // Counter for sck 
    logic SCLKenable;                               // Flip flop enable high every sclk edge

    // Delay signals
    logic [8:0] ImplicitDelay1;                     // Adds implicit delay to cs-sck delay counter based on phase  
    logic [8:0] ImplicitDelay2;                     // Adds implicit delay to sck-cs delay counter based on phase 
    logic [8:0] CS_SCKCount;                        // Counter for cs-sck delay
    logic [8:0] SCK_CSCount;                        // Counter for sck-cs delay
    logic [8:0] InterCSCount;                       // Counter for inter cs delay
    logic [8:0] InterXFRCount;                      // Counter for inter xfr delay 
    logic ZeroDelayHoldMode;                        // High when ChipSelectMode is hold and Delay1[15:8] (InterXFR delay) is 0

    // Frame counting signals
    logic [3:0] FrameCount;                         // Counter for number of frames in transmission
    logic ReceivePenultimateFrame;                  // High when penultimate frame in transmission has been reached

    // State fsm signals
    logic Active;                                   // High when state is either Active1 or Active0 (during transmission)
    logic Active0;                                  // High when state is Active0

    // Shift reg signals
    logic ShiftEdge;                                // Determines which edge of sck to shift from TransmitShiftReg
    logic [7:0] TransmitShiftReg;                   // Transmit shift register
    logic [7:0] ReceiveShiftReg;                    // Receive shift register
    logic SampleEdge;                               // Determines which edge of sck to sample from ReceiveShiftReg
    logic [7:0] TransmitDataEndian;                 // Reverses TransmitData from txFIFO if littleendian, since TransmitReg always shifts MSB
    logic TransmitShiftRegLoad;                     // Determines when to load TransmitShiftReg
    logic ReceiveShiftFull;                         // High when receive shift register is full
    logic TransmitShiftEmpty;                       // High when transmit shift register is empty
    logic ShiftIn;                                  // Determines whether to shift from SPIIn or SPIOut (if SPI_LOOPBACK_TEST)  
    logic [3:0] LeftShiftAmount;                    // Determines left shift amount to left-align data when little endian              
    logic [7:0] ASR;                                // AlignedReceiveShiftReg    

    // CS signals
    logic [3:0] ChipSelectAuto;                     // Assigns ChipSelect value to selected CS signal based on CS ID
    logic [3:0] ChipSelectInternal;                 // Defines what each ChipSelect signal should be based on transmission status and ChipSelectDef
    logic DelayMode;                                // Determines where to place implicit half cycle delay based on sck phase for CS assertion

    // Miscellaneous signals delayed/early by 1 PCLK cycle
    logic ReceiveShiftFullDelay;                    // Delays ReceiveShiftFull signal by 1 PCLK cycle
    logic ReceiveShiftFullDelayPCLK;                // ReceiveShiftFull delayed by 1 PCLK cycle
    logic TransmitFIFOReadEmptyDelay;
    logic SCLKenableEarly;                          // SCLKenable 1 PCLK cycle early, needed for on time register changes when ChipSelectMode is hold and Delay1[15:8] (InterXFR delay) is 0

    // APB access
    assign Entry = {PADDR[7:2],2'b00};  //  32-bit word-aligned accesses
    assign Memwrite = PWRITE & PENABLE & PSEL;  // Only write in access phase
    assign PREADY = TransmitInactive; // Tie PREADY to transmission for hardware interlock

    // Account for subword read/write circuitry
    // -- Note SPI registers are 32 bits no matter what; access them with LW SW.
   
    assign Din = PWDATA[31:0]; 
    if (P.XLEN == 64) assign PRDATA = { Dout,  Dout}; 
    else              assign PRDATA =  Dout;  

    // Register access  
    always_ff@(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin 
            SckDiv <= 12'd3;
            SckMode <= 2'b0;
            ChipSelectID <= 2'b0;
            ChipSelectDef <= 4'b1111;
            ChipSelectMode <= 2'b0;
            Delay0 <= {8'b1,8'b1};
            Delay1 <= {8'b0,8'b1};
            Format <= {5'b10000};
            TransmitData <= 9'b0;
            TransmitWatermark <= 3'b0;
            ReceiveWatermark <= 3'b0;
            InterruptEnable <= 2'b0;
            InterruptPending <= 2'b0;
        end else begin // writes
            

            /* verilator lint_off CASEINCOMPLETE */
            if (Memwrite & TransmitInactive)
                case(Entry) // flop to sample inputs
                    SPI_SCKDIV:  SckDiv <= Din[11:0];
                    SPI_SCKMODE: SckMode <= Din[1:0];
                    SPI_CSID:    ChipSelectID <= Din[1:0];
                    SPI_CSDEF:   ChipSelectDef <= Din[3:0];
                    SPI_CSMODE:  ChipSelectMode <= Din[1:0];
                    SPI_DELAY0:  Delay0 <= {Din[23:16], Din[7:0]};
                    SPI_DELAY1:  Delay1 <= {Din[23:16], Din[7:0]};
                    SPI_FMT:     Format <= {Din[19:16], Din[2]};
                    SPI_TXDATA:  if (~TransmitFIFOWriteFull) TransmitData[7:0] <= Din[7:0];
                    SPI_TXMARK:  TransmitWatermark <= Din[2:0];
                    SPI_RXMARK:  ReceiveWatermark <= Din[2:0];
                    SPI_IE:      InterruptEnable <= Din[1:0];
                endcase
            /* verilator lint_off CASEINCOMPLETE */

            // According to FU540 spec: Once interrupt is pending, it will remain set until number 
            // of entries in tx/rx fifo is strictly more/less than tx/rxmark
            InterruptPending[0] <= TransmitReadMark;
            InterruptPending[1] <= RecieveWriteMark;  

            case(Entry) // Flop to sample inputs
                SPI_SCKDIV:  Dout <= {20'b0, SckDiv};
                SPI_SCKMODE: Dout <= {30'b0, SckMode};
                SPI_CSID:    Dout <= {30'b0, ChipSelectID};
                SPI_CSDEF:   Dout <= {28'b0, ChipSelectDef};
                SPI_CSMODE:  Dout <= {30'b0, ChipSelectMode};
                SPI_DELAY0:  Dout <= {8'b0, Delay0[15:8], 8'b0, Delay0[7:0]};
                SPI_DELAY1:  Dout <= {8'b0, Delay1[15:8], 8'b0, Delay1[7:0]};
                SPI_FMT:     Dout <= {12'b0, Format[4:1], 13'b0, Format[0], 2'b0};
                SPI_TXDATA:  Dout <= {23'b0, TransmitFIFOWriteFull, 8'b0};
                SPI_RXDATA:  Dout <= {23'b0, ReceiveFIFOReadEmpty, ReceiveData[7:0]};
                SPI_TXMARK:  Dout <= {29'b0, TransmitWatermark};
                SPI_RXMARK:  Dout <= {29'b0, ReceiveWatermark};
                SPI_IE:      Dout <= {30'b0, InterruptEnable};
                SPI_IP:      Dout <= {30'b0, InterruptPending};
                default:     Dout <= 32'b0;
            endcase
        end

    // SPI enable generation, where SCLK = PCLK/(2*(SckDiv + 1))
    // Asserts SCLKenable at the rising and falling edge of SCLK by counting from 0 to SckDiv
    // Active at 2x SCLK frequency to account for implicit half cycle delays and actions on both clock edges depending on phase
    assign SCLKenable = (DivCounter == SckDiv);
    assign SCLKenableEarly = ((DivCounter + 12'b1) == SckDiv);
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) DivCounter <= '0;
        else if (SCLKenable) DivCounter <= 12'b0;
        else DivCounter <= DivCounter + 12'b1;

    // Asserts when transmission is one frame before complete
    assign ReceivePenultimateFrame = ((FrameCount + 4'b0001) == Format[4:1]);

    // Computing delays
    // When sckmode.pha = 0, an extra half-period delay is implicit in the cs-sck delay, and vice-versa for sck-cs
    assign ImplicitDelay1 = SckMode[0] ? 9'b0 : 9'b1;
    assign ImplicitDelay2 = SckMode[0] ? 9'b1 : 9'b0;

    // Calculate when tx/rx shift registers are full/empty
    TransmitShiftFSM TransmitShiftFSM(PCLK, PRESETn, TransmitFIFOReadEmpty, ReceivePenultimateFrame, Active0, TransmitShiftEmpty);
    ReceiveShiftFSM ReceiveShiftFSM(PCLK, PRESETn, SCLKenable, ReceivePenultimateFrame, SampleEdge, SckMode[0], ReceiveShiftFull);

    // Calculate tx/rx fifo write and recieve increment signals 

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TransmitFIFOWriteIncrement <= 1'b0;
        else TransmitFIFOWriteIncrement <= (Memwrite & (Entry == 8'h48) & ~TransmitFIFOWriteFull & TransmitInactive);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveFIFOReadIncrement <= 1'b0;
        else ReceiveFIFOReadIncrement <= ((Entry == 8'h4C) & ~ReceiveFIFOReadEmpty & PSEL & ~ReceiveFIFOReadIncrement);
    
    // Tx/Rx FIFOs
    SynchFIFO #(3,8) txFIFO(PCLK, 1'b1, SCLKenable, PRESETn, TransmitFIFOWriteIncrement, TransmitShiftEmpty, TransmitData[7:0], TransmitWriteWatermarkLevel, TransmitWatermark[2:0],
                            TransmitFIFOReadData[7:0], TransmitFIFOWriteFull, TransmitFIFOReadEmpty, TransmitWriteMark, TransmitReadMark);
    SynchFIFO #(3,8) rxFIFO(PCLK, SCLKenable, 1'b1, PRESETn, ReceiveShiftFullDelay, ReceiveFIFOReadIncrement, ReceiveShiftRegEndian, ReceiveWatermark[2:0], ReceiveReadWatermarkLevel, 
                            ReceiveData[7:0], ReceiveFIFOWriteFull, ReceiveFIFOReadEmpty, RecieveWriteMark, RecieveReadMark);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TransmitFIFOReadEmptyDelay <= 1'b1;
        else  if (SCLKenable) TransmitFIFOReadEmptyDelay <= TransmitFIFOReadEmpty;

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveShiftFullDelay <= 1'b0;
        else if (SCLKenable) ReceiveShiftFullDelay <= ReceiveShiftFull;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveShiftFullDelayPCLK <= 1'b0;
        else if (SCLKenableEarly) ReceiveShiftFullDelayPCLK <= ReceiveShiftFull; 

    assign TransmitShiftRegLoad = ~TransmitShiftEmpty & ~Active | (((ChipSelectMode == 2'b10) & ~|(Delay1[15:8])) & ((ReceiveShiftFullDelay | ReceiveShiftFull) & ~SampleEdge & ~TransmitFIFOReadEmpty));

    // Main FSM which controls SPI transmission
    typedef enum logic [2:0] {CS_INACTIVE, DELAY_0, ACTIVE_0, ACTIVE_1, DELAY_1,INTER_CS, INTER_XFR} statetype;
    statetype state;

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin 
                        state <= CS_INACTIVE;
                        FrameCount <= 4'b0;                      
        end else if (SCLKenable) begin
            /* verilator lint_off CASEINCOMPLETE */
            case (state)
                CS_INACTIVE: begin
                        CS_SCKCount <= 9'b1;
                        SCK_CSCount <= 9'b10;
                        FrameCount <= 4'b0;
                        InterCSCount <= 9'b10;
                        InterXFRCount <= 9'b1;
                        if ((~TransmitFIFOReadEmpty | ~TransmitShiftEmpty) & ((|(Delay0[7:0])) | ~SckMode[0])) state <= DELAY_0;
                        else if ((~TransmitFIFOReadEmpty | ~TransmitShiftEmpty)) state <= ACTIVE_0;
                        end
                DELAY_0: begin
                        CS_SCKCount <= CS_SCKCount + 9'b1;
                        if (CS_SCKCount >= (({Delay0[7:0], 1'b0}) + ImplicitDelay1)) state <= ACTIVE_0;
                        end
                ACTIVE_0: begin 
                        FrameCount <= FrameCount + 4'b1;
                        state <= ACTIVE_1;
                        end
                ACTIVE_1: begin
                        InterXFRCount <= 9'b1;
                        if (FrameCount < Format[4:1]) state <= ACTIVE_0;
                        else if ((ChipSelectMode[1:0] == 2'b10) & ~|(Delay1[15:8]) & (~TransmitFIFOReadEmpty)) begin
                            state <= ACTIVE_0;
                            CS_SCKCount <= 9'b1;
                            SCK_CSCount <= 9'b10;
                            FrameCount <= 4'b0;
                            InterCSCount <= 9'b10;
                        end
                        else if (ChipSelectMode[1:0] == 2'b10) state <= INTER_XFR;
                        else if (~|(Delay0[15:8]) & (~SckMode[0])) state <= INTER_CS;
                        else state <= DELAY_1;
                        end
                DELAY_1: begin
                        SCK_CSCount <= SCK_CSCount + 9'b1;
                        if (SCK_CSCount >= (({Delay0[15:8], 1'b0}) + ImplicitDelay2)) state <= INTER_CS;
                        end
                INTER_CS: begin
                        InterCSCount <= InterCSCount + 9'b1;
                        if (InterCSCount >= ({Delay1[7:0],1'b0})) state <= CS_INACTIVE;
                        end
                INTER_XFR: begin
                        CS_SCKCount <= 9'b1;
                        SCK_CSCount <= 9'b10;
                        FrameCount <= 4'b0;
                        InterCSCount <= 9'b10;
                        InterXFRCount <= InterXFRCount + 9'b1;
                        if ((InterXFRCount >= ({Delay1[15:8], 1'b0})) & ~TransmitFIFOReadEmptyDelay) state <= ACTIVE_0;
                        else if (~|ChipSelectMode[1:0]) state <= CS_INACTIVE;
                        end
            endcase
            /* verilator lint_off CASEINCOMPLETE */
        end

            

    assign DelayMode = SckMode[0] ? (state == DELAY_1) : (state == ACTIVE_1 & ReceiveShiftFull);
    assign ChipSelectInternal = (state == CS_INACTIVE | state == INTER_CS | DelayMode & ~|(Delay0[15:8])) ? ChipSelectDef : ~ChipSelectDef;
    assign sck = (state == ACTIVE_0) ? ~SckMode[1] : SckMode[1];
    assign Active = (state == ACTIVE_0 | state == ACTIVE_1);
    assign SampleEdge = SckMode[0] ? (state == ACTIVE_1) : (state == ACTIVE_0);
    assign ZeroDelayHoldMode = ((ChipSelectMode == 2'b10) & (~|(Delay1[7:4])));
    assign TransmitInactive = ((state == INTER_CS) | (state == CS_INACTIVE) | (state == INTER_XFR) | (ReceiveShiftFullDelayPCLK & ZeroDelayHoldMode));
    assign Active0 = (state == ACTIVE_0);

    // Signal tracks which edge of sck to shift data
    always_comb
        case(SckMode[1:0])
            2'b00: ShiftEdge = ~sck & SCLKenable;
            2'b01: ShiftEdge = (sck & |(FrameCount) & SCLKenable);
            2'b10: ShiftEdge = sck & SCLKenable;
            2'b11: ShiftEdge = (~sck & |(FrameCount) & SCLKenable);
            default: ShiftEdge = sck & SCLKenable;
        endcase

    // Transmit shift register
    assign TransmitDataEndian = Format[0] ? {TransmitFIFOReadData[0], TransmitFIFOReadData[1], TransmitFIFOReadData[2], TransmitFIFOReadData[3], TransmitFIFOReadData[4], TransmitFIFOReadData[5], TransmitFIFOReadData[6], TransmitFIFOReadData[7]} : TransmitFIFOReadData[7:0];
    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn)                        TransmitShiftReg <= 8'b0; 
        else if (TransmitShiftRegLoad)      TransmitShiftReg <= TransmitDataEndian;
        else if (ShiftEdge & Active)        TransmitShiftReg <= {TransmitShiftReg[6:0], 1'b0};
    
    assign SPIOut = TransmitShiftReg[7];

    // If in loopback mode, receive shift register is connected directly to module's output pins. Else, connected to SPIIn
    // There are no setup/hold time issues because transmit shift register and receive shift register always shift/sample on opposite edges
    assign ShiftIn = P.SPI_LOOPBACK_TEST ? SPIOut : SPIIn;

    // Receive shift register
    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn)  ReceiveShiftReg <= 8'b0;
        else if (SampleEdge & SCLKenable) begin
            if (~Active)    ReceiveShiftReg <= 8'b0;
            else            ReceiveShiftReg <= {ReceiveShiftReg[6:0], ShiftIn};
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

module SynchFIFO #(parameter M=3, N=8)(                 // 2^M entries of N bits each
    input  logic         PCLK, wen, ren, PRESETn,
    input  logic         winc, rinc,
    input  logic [N-1:0] wdata,
    input  logic [M-1:0] wwatermarklevel, rwatermarklevel,
    output logic [N-1:0] rdata,
    output logic         wfull, rempty,
    output logic         wwatermark, rwatermark);

    /* Pointer FIFO using design elements from "Simulation and Synthesis Techniques
       for Asynchronous FIFO Design" by Clifford E. Cummings. Namely, M bit read and write pointers
       are an extra bit larger than address size to determine full/empty conditions. 
       Watermark comparisons use 2's complement subtraction between the M-1 bit pointers,
       which are also used to address memory
    */
       
    logic [N-1:0] mem[2**M];
    logic [M:0] rptr, wptr;
    logic [M:0] rptrnext, wptrnext;
    logic [M-1:0] raddr;
    logic [M-1:0] waddr;
 
    assign rdata = mem[raddr];
    always_ff @(posedge PCLK)
        if (winc & ~wfull) mem[waddr] <= wdata;

    // write and read are enabled 
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin 
            rptr <= '0;
            wptr <= '0;
            wfull <= 1'b0;
            rempty <= 1'b1;
        end else begin 
            if (wen) begin
                wfull <= ({~wptrnext[M], wptrnext[M-1:0]} == rptr);
                wptr  <= wptrnext;
            end
            if (ren) begin 
                rptr <= rptrnext;
                rempty <= (wptr == rptrnext);
            end
        end 
    
    assign raddr = rptr[M-1:0];
    assign rptrnext = rptr + {{(M){1'b0}}, (rinc & ~rempty)};      
    assign rwatermark = ((waddr - raddr) < rwatermarklevel) & ~wfull;
    assign waddr = wptr[M-1:0];
    assign wwatermark = ((waddr - raddr) > wwatermarklevel) | wfull;
    assign wptrnext = wptr + {{(M){1'b0}}, (winc & ~wfull)};
endmodule

module TransmitShiftFSM(
    input  logic PCLK, PRESETn,
    input  logic TransmitFIFOReadEmpty, ReceivePenultimateFrame, Active0,
    output logic TransmitShiftEmpty);

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TransmitShiftEmpty <= 1'b1;
        else if (TransmitShiftEmpty) begin        
            if (TransmitFIFOReadEmpty | (~TransmitFIFOReadEmpty & (ReceivePenultimateFrame & Active0))) TransmitShiftEmpty <= 1'b1;
            else if (~TransmitFIFOReadEmpty) TransmitShiftEmpty <= 1'b0;
        end else begin
            if (ReceivePenultimateFrame & Active0) TransmitShiftEmpty <= 1'b1;
            else TransmitShiftEmpty <= 1'b0;
        end

endmodule

module ReceiveShiftFSM(
    input  logic PCLK, PRESETn, SCLKenable,
    input  logic ReceivePenultimateFrame, SampleEdge, SckMode,
    output logic ReceiveShiftFull
);
    typedef enum logic [1:0] {ReceiveShiftFullState, ReceiveShiftNotFullState, ReceiveShiftDelayState} statetype;
    statetype ReceiveState, ReceiveNextState;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) ReceiveState <= ReceiveShiftNotFullState;
        else if (SCLKenable) begin
            case (ReceiveState)
                ReceiveShiftFullState: ReceiveState <= ReceiveShiftNotFullState;
                ReceiveShiftNotFullState: if (ReceivePenultimateFrame & (SampleEdge)) ReceiveState <= ReceiveShiftDelayState;
                                          else ReceiveState <= ReceiveShiftNotFullState;
                ReceiveShiftDelayState:   ReceiveState <= ReceiveShiftFullState;
            endcase
        end

    assign ReceiveShiftFull = SckMode ? (ReceiveState == ReceiveShiftFullState) : (ReceiveState == ReceiveShiftDelayState);
endmodule

