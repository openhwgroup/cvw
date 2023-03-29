///////////////////////////////////////////
// spi_apb.sv
//
// Written: nwhyteaguayo@g.hmc.edu 11/16/2022

//
// Purpose: SPI peripheral
//   See FU540-C000-v1.0 for specifications
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2022 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

// CREATE HARDWARE INTERLOCKS FOR MODE CHANGES / CONTROL REGISTER UPDATES
// figure out cs off mode
// simplify cs auto/hold logic
//simply sck phase select logic


`include "wally-config.vh"

module spi_apb (
    input  logic             PCLK, PRESETn,
    input  logic             PSEL,
    input  logic [7:0]       PADDR,
    input  logic [`XLEN-1:0] PWDATA,
    input  logic [`XLEN/8-1:0] PSTRB,
    input  logic             PWRITE,
    input  logic             PENABLE,
    output logic             PREADY,
    output logic [`XLEN-1:0] PRDATA,
    output logic [3:0]          SPIOut,
    input  logic [3:0]          SPIIn,
    output logic [3:0]          SPICS,
    output logic                SPIIntr

    );

    //SPI registers

    logic [31:0] sck_div, sck_mode;
    logic [31:0] cs_id, cs_def, cs_mode;
    logic [31:0] delay0, delay1;
    logic [31:0] fmt;
    logic [31:0] rx_data, tx_mark, rx_mark;
    logic [7:0] tx_data;
    //logic [31:0] f_ctrl, f_fmt;
    logic [31:0] ie, ip;

    logic [7:0] entry;
    logic memwrite;
    logic [31:0] Din, Dout;
    logic busy;
    logic txWMark, txRMark, rxWMark, rxRMark;
    logic TXwfull, TXrempty;

    //APB IO
    //NEED TO UNDERSTAND BENS SUBWORD READ WRITE MORE BEFORE I DO this
    assign entry = {PADDR[7:2],2'b00};  // 32-bit word-aligned accesses
    assign memwrite = PWRITE & PENABLE & PSEL;  // only write in access phase
    assign PREADY = 1'b1; // spi never takes >1 cycle to respond (float module)

    // account for subword read/write circuitry
    // -- Note GPIO registers are 32 bits no matter what; access them with LW SW.
    //    (At least that's what I think when FE310 spec says "only naturally aligned 32-bit accesses are supported")
    if (`XLEN == 64) begin
        assign Din =    entry[2] ? PWDATA[63:32] : PWDATA[31:0];
        assign PRDATA = entry[2] ? {Dout,32'b0}  : {32'b0,Dout};
    end else begin // 32-bit
        assign Din = PWDATA[31:0];
        assign PRDATA = Dout;
    end

    // register access
    //starting with single lane module no flash control
    always_ff@(posedge PCLK, negedge PRESETn)
        if (~PRESETn) begin 
            sck_div <= #1 32'd3;
            sck_mode <= #1 0;
            cs_id <= #1 32'b0;
            cs_def <= #1 32'b1;
            cs_mode <= #1 0;
            delay0 <= #1 {8'b0,8'b1,8'b0,8'b1};
            delay1 <= #1 {8'b0,8'b0,8'b0,8'b1};
            fmt <= #1 {12'b0,4'd8,16'b0};
            tx_data <= #1 8'b0;
            tx_mark <= #1 0;
            rx_mark <= #1 0;
            //f_ctrl <= #1 32'b1;
            //f_fmt <= #1 {8'b0,8'd3,12'b0,3'b3,1'b1};
            ie <= #1 0;
            ip <= #1 0;
        end else begin //writes
            //According to FU540 spec: Once interrupt is pending, it will remain set until number 
            //of entries in tx/rx fifo is strictly more/less than tx/rxmark

            //From spec. "Hardware interlocks ensure that the current transfer completes before mode transitions and control register updates take effect"
            // Interpreting 'current transfer' as everything in FIFO, otherwise control register bits have to be added to each FIFO frame
            /* verilator lint_off CASEINCOMPLETE */
            if (memwrite)
                case(entry) //flop to sample inputs
                    8'h00: sck_div <= Din;
                    8'h04: sck_mode <= Din;
                    8'h10: cs_id <= Din;
                    8'h14: cs_def <= Din;
                    8'h18: cs_mode <= Din;
                    8'h28: delay0 <= Din;
                    8'h2C: delay1 <= Din;
                    8'h40: fmt <= Din;
                    8'h48: if (~TXwfull) tx_data <= Din[7:0];
                    8'h50: tx_mark <= Din;
                    8'h54: rx_mark <= Din;
                    8'h70: ie <= Din;
                endcase
            /* verilator lint_off CASEINCOMPLETE */
            //interrupt clearance
            ip[0] <= ie[0] & txRMark;
            ip[1] <= ie[1] & rxWMark;  
            case(entry) // flop to sample inputs
                8'h00: Dout <= #1 sck_div;
                8'h04: Dout <= #1 sck_mode;
                8'h10: Dout <= #1 cs_id;
                8'h14: Dout <= #1 cs_def;
                8'h18: Dout <= #1 cs_mode;
                8'h28: Dout <= #1 delay0;
                8'h2C: Dout <= #1 delay1;
                8'h40: Dout <= #1 fmt;
                8'h48: Dout <= #1 {TXwfull, 31'b0};
                8'h4C: if (~rx_data[31]) Dout <= #1 rx_data;
                8'h50: Dout <= #1 tx_mark;
                8'h54: Dout <= #1 rx_mark;
                8'h70: Dout <= #1 ie;
                8'h74: Dout <= #1 ip;
                default: Dout <= #1 0;
            endcase
        end

    //SCK_CONTROL
    logic sck;
    logic [12:0] div_counter, div_counter_edge;
    logic tx_empty;
    logic sclk_edge;
    logic sclk_duty;
    logic [8:0] delay0_cnt;
    logic [8:0] delay1_cnt;
    logic delay0_cmp;
    logic delay1_cmp;
    logic intercs_cmp;
    logic [8:0] intercs_cnt;
    logic interxfr_cmp;
    logic [8:0] interxfr_cnt;
    logic [3:0] cs_internal;
    logic [5:0] frame_cnt;
    logic [5:0] frame_cmp;
    logic active;
    logic frame_cmp_bool;
    logic [5:0] frame_cnt_shifted;
    logic [5:0] tx_frame_cnt_shift_pre;
    logic [5:0] tx_penultimate_frame;
    logic [5:0] rx_penultimate_frame;
    logic [5:0] rx_frame_cnt_shifted_pre;
    logic tx_frame_cmp_pre_bool;
    logic rx_frame_cmp_pre_bool;
    logic [5:0] frame_cmp_protocol;
    logic rxShiftFull;
    //assign frame_cnt_shifted = (frame_cnt << fmt[1:0]);
    always_comb
        case(fmt[1:0])
            2'b00: frame_cnt_shifted = frame_cnt;
            2'b01: frame_cnt_shifted = {frame_cnt[4:0], 1'b0};
            2'b10: frame_cnt_shifted = {frame_cnt[3:0], 2'b0};
        endcase
    
    //assign penultimate_frame = fmt[1] ? {4'b0,fmt[1:0]} : {4'b0, 2'b01};
    //generates the correct value to determine if current frame is second to last
    always_comb
        case(fmt[1:0])
            2'b00: tx_penultimate_frame = 6'b000001;
            2'b01: tx_penultimate_frame = 6'b000010;
            2'b10: tx_penultimate_frame = 6'b000011;
            default: tx_penultimate_frame = 6'b000001;
        endcase
    
    assign frame_cmp_bool = (frame_cnt_shifted < frame_cmp);
    assign tx_frame_cnt_shift_pre = frame_cnt_shifted + tx_penultimate_frame;
    assign frame_cmp_protocol = (fmt[1] | fmt[0]) ? {1'b0, frame_cmp[5:1]} : frame_cmp;
    assign tx_frame_cmp_pre_bool = (tx_frame_cnt_shift_pre >= frame_cmp_protocol);
    assign rx_frame_cmp_pre_bool = (tx_frame_cnt_shift_pre >= frame_cmp);



    // definitions for FIFO
    logic TXwinc, TXrinc;
    logic RXwinc, RXrinc;
    
    logic RXwfull, RXrempty;
    logic [7:0] TXrdata, RXwdata;
    logic [2:0] txWWatermarkLevel, rxRWatermarkLevel;

    logic sclk_reset_0, sclk_reset_1;



    assign sclk_edge = (div_counter_edge >= (({sck_div[11:0], 1'b0}) + 13'b1));
    //assign tx_empty = ~|(tx_data);
    //incorrect way to assess this, replace FSM assign at end
    assign sclk_duty = (div_counter >= (sck_div[11:0]));
    assign delay0_cmp = sck_mode[0] ? (delay0_cnt == ({delay0[7:0], 1'b0})) : (delay0_cnt == ({delay0[7:0], 1'b0} + 9'b1));
    assign delay1_cmp = sck_mode[0] ? (delay1_cnt == (({delay0[23:16], 1'b0}) + 9'b1)) : (delay1_cnt == ({delay0[23:16], 1'b0}));
    assign intercs_cmp = (intercs_cnt >= ({delay1[7:0],1'b0}));
    assign interxfr_cmp = (interxfr_cnt >= ({delay1[23:16], 1'b0}));
    // double number of frames in dual or quad mode because we must wait for peripheral to send back
    assign frame_cmp = (fmt[0] | fmt[1]) ? ({1'b0,fmt[19:16], 1'b0}) : {2'b0,fmt[19:16]};

    typedef enum logic [2:0] {CS_INACTIVE, DELAY_0, ACTIVE_0, ACTIVE_1,DELAY_1,INTER_CS, INTER_XFR} statetype;
    statetype state;

    //producing signal high every (2*scc_div)+1) cycles
    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn | sclk_duty ) begin
            div_counter <= #1 0;
        end

        else begin
            div_counter <= div_counter + 13'b1;
            sclk_reset_0 <= 1;
        end
    always_ff @(posedge PCLK, negedge PRESETn)
        if(~PRESETn | sclk_edge ) begin
            div_counter_edge <= #1 0;
        end
        else begin
            div_counter_edge <= div_counter_edge + 13'b1;
            sclk_reset_1 <= 1;
        end

    
    logic txShiftEmpty, rxShiftEmpty;
    always_ff @(posedge sclk_duty, negedge PRESETn)
        if (~PRESETn) begin state <= CS_INACTIVE;
                            frame_cnt <= 6'b0;
        
        /* verilator lint_off CASEINCOMPLETE */
        end else case (state)
                CS_INACTIVE: begin
                        delay0_cnt <= 9'b1;
                        delay1_cnt <= 9'b1;
                        frame_cnt <= 6'b0;
                        intercs_cnt <= 9'b10;
                        interxfr_cnt <= 9'b1;
                        if ((~TXrempty | ~txShiftEmpty) & ((|(delay0[7:0])) | ~sck_mode[0])) state <= DELAY_0;
                        else if ((~TXrempty | ~txShiftEmpty)) state <= ACTIVE_0;
                        end
                DELAY_0: begin
                        delay0_cnt <= delay0_cnt + 9'b1;
                        if (delay0_cmp) state <= ACTIVE_0;
                        end
                ACTIVE_0: begin 
                        frame_cnt <= frame_cnt + 6'b1;
                        state <= ACTIVE_1;
                        end
                ACTIVE_1: begin
                        interxfr_cnt <= 9'b1;
                        if (frame_cmp_bool) state <= ACTIVE_0;
                        else if ((cs_mode[1:0] == 2'b10) & ~|(delay1[23:17]) & (~TXrempty)) begin
                            state <= ACTIVE_0;
                            delay0_cnt <= 9'b1;
                            delay1_cnt <= 9'b1;
                            frame_cnt <= 6'b0;
                            intercs_cnt <= 9'b10;
                        end
                        else if (cs_mode[1:0] == 2'b10) state <= INTER_XFR;
                        else if ((~|(delay0[23:17])) & ~sck_mode[0]) state <= INTER_CS;
                        else state <= DELAY_1;
                        end
                DELAY_1: begin
                        delay1_cnt <= delay1_cnt + 9'b1;
                        if (delay1_cmp) state <= INTER_CS;
                        end
                INTER_CS: begin
                        intercs_cnt <= intercs_cnt + 9'b1;
                        if (intercs_cmp ) state <= CS_INACTIVE;
                        end
                INTER_XFR: begin
                        delay0_cnt <= 9'b1;
                        delay1_cnt <= 9'b1;
                        frame_cnt <= 6'b0;
                        intercs_cnt <= 9'b10;
                        interxfr_cnt <= interxfr_cnt + 9'b1;
                        if ((entry == (8'h18 | 8'h10) | ((entry == 8'h14) & ((PWDATA[cs_id]) != cs_def[cs_id])))) state <= CS_INACTIVE;
                        if (interxfr_cmp & ~TXrempty) state <= ACTIVE_0;
                        else if (~|cs_mode[1:0]) state <= CS_INACTIVE;
                        
                        end
            endcase
            /* verilator lint_off CASEINCOMPLETE */
    assign cs_internal = ((state == CS_INACTIVE | state == INTER_CS) ? cs_def[3:0] : ~cs_def[3:0]);
    assign sck = (state == ACTIVE_0) ? ~sck_mode[1] : sck_mode[1];
    assign busy = (state == DELAY_0 | state == ACTIVE_0 | ((state == ACTIVE_1) & ~((|(delay1[23:17]) & (cs_mode[1:0]) == 2'b10) & ((frame_cnt << fmt[1:0]) >= frame_cmp))) | state == DELAY_1);
    assign active = (state == ACTIVE_0 | state == ACTIVE_1);

    logic active0;

    assign active0 = (state == ACTIVE_0);




    //FIFOs CURRENTLY SRAM BASED ON "The existence of fall-through architecture has a historical basis. New developments no longer use this principle."
    //https://www.ti.com/lit/an/scaa042a/scaa042a.pdf
    //However, 8 byte is very small, may adjust based on synthesis results.
    //FIFO design based on Simulation and Synthesis Techniques for Asynchronous FIFO Design Clifford E. Cummings SNUG 2002
    //modules fifomem, syncr2w, syncw2r, rptrempty, wptrfull
    //address space 8 bytes, needs n-1 = 3 bits, n szed ptrs to determine full/tx_empty

    //TXFIFO
    //fifomem asynch ram

    logic TXrempty_delay;
    logic TXwinc_delay;

    logic sck_phase_sel;
    assign TXwinc = (memwrite & (entry == 8'h48) & ~TXwfull);
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TXwinc_delay <= 0;
        else TXwinc_delay <= TXwinc;
    assign TXrinc = txShiftEmpty;
    /*
    
    always_ff@(posedge PCLK)
        tx_data[31] <= TXwfull;
  
    */

    assign RXwinc = rxShiftFull;
    assign RXrinc = ((entry == 8'h4C) & ~rx_data[31]);
    assign rx_data[31] = RXrempty;

    logic [7:0] txShift;
    logic [7:0] rxShift;
    logic sample_edge;
    assign sample_edge = sck_mode[0] ? (state == ACTIVE_1) : (state == ACTIVE_0);
    

    FIFO_async #(3,8) txFIFO(PCLK, sclk_duty, PRESETn, TXwinc_delay, TXrinc, tx_data,fmt[2], txWWatermarkLevel, tx_mark[2:0], TXrdata[7:0], TXwfull, TXrempty, txWMark, txRMark);
    FIFO_async #(3,8) rxFIFO(sclk_duty, PCLK, PRESETn, RXwinc, RXrinc, rxShift, fmt[2], rx_mark[2:0], rxRWatermarkLevel, rx_data[7:0], RXwfull, RXrempty, rxWMark, rxRMark);

    txShiftFSM txShiftFSM_1 (sclk_duty, PRESETn, TXrempty_delay, rx_frame_cmp_pre_bool, active0, txShiftEmpty);
    rxShiftFSM rxShiftFSM_1 (sclk_duty, PRESETn, rx_frame_cmp_pre_bool, sample_edge, rxShiftFull);

    always_ff @(posedge sclk_duty, negedge PRESETn)
        if (~PRESETn) TXrempty_delay <= 1;
        else TXrempty_delay <= TXrempty;
    






    //SHIFT REGISTER CONTROL. NEED TO ADJUST TO ADJUST FOR CHANGE FROM FIFO TO SHIFT REGISTER THAT TAKES FIFO AS INPUT

    

    //assign sck_phase_sel = sck_mode[0] ? (sck_mode[1] ? sck : ~sck) : (sck_mode[1] ? ~sck : sck);
    //assign sck_phase_sel = sck_mode[0] ? (sck_mode[1] ? ~sck : sck) : (sck_mode[1] ? sck : ~sck);

    always_comb
        case(sck_mode[1:0])
            2'b00: sck_phase_sel = ~sck;
            2'b01: sck_phase_sel = (sck & |(frame_cnt));
            2'b10: sck_phase_sel = sck;
            2'b11: sck_phase_sel = (~sck & |(frame_cnt));
            default: sck_phase_sel = sck;
        endcase
        
    always_ff @(posedge sck_phase_sel, negedge PRESETn, posedge (sclk_duty & ~active))
        if(~PRESETn) begin 
                txShift <= 8'b0;
            end
        else begin
           // txShiftEmpty <= (~active & ~txShiftEmpty);
            
            if (~active & ~TXrempty) txShift <= TXrdata;
            else if (active) begin
                case (fmt[1:0])
                    2'b00: txShift <= {txShift[6:0], 1'b0};
                    2'b01: txShift <= {txShift[5:0], 2'b0};
                    2'b10: txShift <= {txShift[3:0], 4'b0};
                    default: txShift <= {txShift[6:0], 1'b0}; 
                endcase
            end
        end
    always_comb
        if (active | delay0_cmp) begin
            case(fmt[1:0])
                2'b00: SPIOut = {3'b0,txShift[7]}; 
                2'b01: SPIOut = {2'b0,txShift[6], txShift[7]};
                // assuming SPIOut[0] is first bit transmitted etc
                2'b10: SPIOut = {txShift[3], txShift[2], txShift[1], txShift[0]};
                default: SPIOut = {3'b0, txShift[7]};
            endcase
        end else SPIOut = 4'b0;
    always_ff @(posedge sample_edge, negedge PRESETn)
        if(~PRESETn) begin  
                rxShift <= 8'b0;
                rxShiftEmpty <= 1'b1;
            end
        else if(~fmt[3]) begin
            //rxShiftEmpty <= (~active & ~rxShiftEmpty);
            if(`SPI_LOOPBACK_TEST) begin
                case(fmt[1:0])
                    2'b00: rxShift <= { rxShift[6:0], SPIOut[0]};
                    2'b01: rxShift <= { rxShift[5:0], SPIOut[0],SPIOut[1]};
                    2'b10: rxShift <= { rxShift[3:0], SPIOut[0], SPIOut[1], SPIOut[2], SPIOut[3]};
                    default: rxShift <= { rxShift[6:0], SPIOut[0]};
                endcase

            end else begin
                case(fmt[1:0])
                    2'b00: rxShift <= { rxShift[6:0], SPIIn[0]};
                    2'b01: rxShift <= { rxShift[5:0], SPIIn[0],SPIIn[1]};
                    2'b10: rxShift <= { rxShift[3:0], SPIIn[0], SPIIn[1], SPIIn[2], SPIIn[3]};
                    default: rxShift <= { rxShift[6:0], SPIIn[0]};
                endcase
            end
        end
    // the state== ACTIVE_0 isn't going to work if phase is reversed (? not true actually) or if protocol is dual or quad
    // need to determine state condition based on phase and need to add protocol protection
    //logic sample_edge;
    //assign sample_edge = sck_mode[0] ? (state == ACTIVE_0) : (state == ACTIVE_1)'

    




                

    // trying to turn into FSMs
    /*
    always_ff @(posedge sclk_duty, negedge PRESETn)
        if (~PRESETn) begin
            txShiftEmpty <= 1'b1;
            rxShiftFull <= 1'b0;
        end else begin
            // edge case where first frame is last frame might cause contention
            if (rxShiftFull) rxShiftFull <= 0;
            if ((~|(frame_cnt) | txShiftEmpty) & ~TXrempty) txShiftEmpty <= 0;
            else if (rx_frame_cmp_pre_bool & (state == ACTIVE_0)) begin
                txShiftEmpty <= 1;
                rxShiftFull <= 1;
            end

        end
    */
    assign SPIIntr = ((ip[0] & ie[0]) | (ip[1] & ie[1]));
    logic [3:0] CSauto, CShold, CSoff;
    logic CShold_single;
    always_comb
        case(cs_id[1:0])
            2'b00: begin CSauto = {cs_def[3], cs_def[2], cs_def[1], cs_internal[0]};
                         CShold = {cs_def[3], cs_def[2], cs_def[1], CShold_single};
                    end
            2'b01: begin CSauto = {cs_def[3],cs_def[2], cs_internal[1], cs_def[0]};
                         CShold = {cs_def[3],cs_def[2], CShold_single, cs_def[0]};
                    end
            2'b10: begin CSauto = {cs_def[3],cs_internal[2], cs_def[1], cs_def[0]};
                         CShold = {cs_def[3], CShold_single, cs_def[1], cs_def[0]};
                    end
            2'b11: begin CSauto = {cs_internal[3],cs_def[2], cs_def[1], cs_def[0]};
                         CShold = {CShold_single, cs_def[2], cs_def[1], cs_def[0]};
                    end
        endcase
    
    assign CShold_single = (state == CS_INACTIVE);
    //placeholder before i determine what "disable hardware control means" (leave floating, leave as last set, change to default etc)
    assign SPICS = cs_mode[0] ? 4'b1111 : CSauto;


endmodule

module FIFO_async #(parameter M = 3, N = 8)(
    input logic wclk, rclk, PRESETn,
    input logic winc,rinc,
    input logic [N-1:0] wdata,
    input logic endian,
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
        if(winc & ~wfull) mem[waddr] <= (~endian) ? wdata : {wdata[0], wdata[1], wdata[2], wdata[3], wdata[4], wdata[5], wdata[6], wdata[7] };

    always_ff @(posedge wclk, negedge PRESETn)
        if (~PRESETn) begin
            wq2_rptr <= 0;
            wq1_rptr <= 0;
        end
        else begin
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
/*
module txShiftFSM(
    input logic sclk_duty, PRESETn,
    input logic [5:0] frame_cnt,
    input logic TXrempty, rx_frame_cmp_pre_bool, active0,
    output logic txShiftEmpty);


    typedef enum logic {txShiftEmptyState, txShiftNotEmptyState} statetype;
    statetype tx_state, tx_nextstate;
    always_ff @(posedge sclk_duty, negedge PRESETn)
        if (~PRESETn) tx_state <= txShiftEmptyState;
        else          tx_state <= tx_nextstate;

        always_comb
            case(tx_state)
                txShiftEmptyState: begin
                    if (((~|(frame_cnt) & ~TXrempty)) & ~(rx_frame_cmp_pre_bool & (active0))) tx_nextstate <= txShiftEmptyState;
                    else if (|(frame_cnt)) tx_nextstate <= txShiftNotEmptyState;
                end
                txShiftNotEmptyState: begin
                    if (rx_frame_cmp_pre_bool & (active0)) tx_nextstate <= txShiftEmptyState;
                    else tx_nextstate <= txShiftNotEmptyState;
                end
            endcase
            assign txShiftEmpty = (tx_nextstate == txShiftEmptyState);
endmodule
*/
module txShiftFSM(
    input logic sclk_duty, PRESETn,
    input logic TXrempty, rx_frame_cmp_pre_bool, active0,
    output logic txShiftEmpty);

    typedef enum logic [1:0] {txShiftEmptyState, txShiftHoldState, txShiftNotEmptyState} statetype;
    statetype tx_state, tx_nextstate;
    always_ff @(posedge sclk_duty, negedge PRESETn)
        if (~PRESETn) tx_state <= txShiftEmptyState;
        else          tx_state <= tx_nextstate;

        always_comb
            case(tx_state)
                txShiftEmptyState: begin
                    if (TXrempty | (~TXrempty & (rx_frame_cmp_pre_bool & active0))) tx_nextstate <= txShiftEmptyState;
                    else if (~TXrempty) tx_nextstate <= txShiftNotEmptyState;
                end
                txShiftNotEmptyState: begin
                    if (rx_frame_cmp_pre_bool & active0) tx_nextstate <= txShiftEmptyState;
                    else tx_nextstate <= txShiftNotEmptyState;
                end
            endcase
        assign txShiftEmpty = (tx_nextstate == txShiftEmptyState);
endmodule



module rxShiftFSM(
    input logic sclk_duty, PRESETn,
    input logic rx_frame_cmp_pre_bool, sample_edge,
    output logic rxShiftFull
);

    typedef enum logic [1:0] {rxShiftFullState, rxShiftNotFullState, rxShiftDelayState} statetype;
    statetype rx_state, rx_nextstate;
    always_ff @(posedge sclk_duty, negedge PRESETn)
        if (~PRESETn) rx_state <= rxShiftNotFullState;
        else          rx_state <= rx_nextstate;
        
        always_comb
            case(rx_state)
                rxShiftFullState: rx_nextstate <= rxShiftNotFullState;
                rxShiftNotFullState: if (rx_frame_cmp_pre_bool & (sample_edge)) rx_nextstate <= rxShiftDelayState;
                                     else rx_nextstate <= rxShiftNotFullState;
                rxShiftDelayState: rx_nextstate <= rxShiftFullState;
            endcase

        assign rxShiftFull = (rx_nextstate == rxShiftFullState);
endmodule







            /*
        always_comb
            case(state)
                CS_INACTIVE: begin
                             if(tx_empty) nextstate <= CS_INACTIVE;
                             elseif ((~|(delay0[7:0])) | (~sck_mode[0])) nextstate <= DELAY_0;
                             else                  nextstate <= ACTIVE_0;
                             delay0_cnt <= 9'b0;
                             delay1_cnt <= 9'b0;
                             intercs_cnt <= 9'b0;
                             frame_cnt <= 6'b0;
                             end
                DELAY_0: begin
                        delay0_cnt = delay0_cnt + 8'b1;
                        if (delay0_cmp) nextstate <= ACTIVE_0;
                        else nextstate <= DELAY_0;
                        
                    end
                ACTIVE_0: begin
                          if (~(frame_cnt == fmt[19:16])) nextstate <= ACTIVE_1;
                          elseif ((~|(delay0[23:16])) | (~sck_mode[0])) nextstate <= INTER_CS; 
                          else           nextstate = DELAY_1;
                          end
                ACTIVE_1: begin
                          nextstate <= ACTIVE_0
                          frame_cnt <= frame_cnt + 6'b1;
                DELAY_1: begin
                        delay1_cnt = delay1_cnt + 8'b1;
                        if (delay1_cmp & ~|(cs_mode)) nextstate <= INTER_CS;
                        elseif (delay1_cmp & |(cs_mode) & |(delay1[32:16])) nextstate <= INTER_XFR;
                        elseif (delay1_cmp & |(cs_mode) & ~|(delay1[32:16])) nextstate <= INTER_XFR;
                        else nextstate <= DELAY_1;
                        end
                INTER_CS: begin
                        intercs_cnt = intercs_cnt + 8'b1;
                        if (intercs_cmp) nextstate <= CS_INACTIVE;
                        else             nextstate <= INTER_CS;
                        end
                INTER_XFR: begin
                        delay0_cnt <= 8'b0;
                        delay1_cnt <= 8'b0;
                        intercs_cnt <= 8'b0;
                        frame_cnt <= 6'b0;
                        interxfr_cnt = interxfr_cnt + 1;
                        if (interxfr_cmp) nextstate <= DELAY_0;
                        else nextstate <= INTER_XFR;
                        end
            endcase
        assign cs_internal = ((state == CS_INACTIVE | state == INTER_CS) ? ~cs_def : cs_def);
        assign sck = (state == ACTIVE_1) ? ~sck_mode[1] : sck_mode[1];
        */
        
    



    /*
    logic [7:0] TXmem[8];
    logic [7:0] TXrdata, TXwdata;
    logic [2:0] TXraddr, TXwaddr;
    kogic TXwfull, TXwclken;
    assign TXrdata = TXmem[TXraddr];
    always_ff @(posedge PCLK)
        if (TXwclken & !TXwfull) mem(TXwaddr) <= TXwdata;
    
    //sync r2w
    logic [3:0] TXwq1_rptr, TXwq2_rptr, TXrptr;
    always_ff @(posedge PCL, negedge PRESETn)
        if(~PRESETn) {TXwq2_rptr, TXwq1_rptr} <= 0;
        else {TXwq2_rptr, TXwq1_rptr} <= {TXwq1_rptr, TXrptr};

    //sync w2r
    logic [3:0] TXrq1_wptr, TXrq2_wptr, TXwptr;
    always_ff @(posedge PCL, negedge PRESETn)
        if(~PRESETn) {TXrq2_wptr, TXrq1_wptr} <= 0;
        else {TXrq2_wptr, TXrq1_wptr} <= {TXrq1_wptr, TXwptr};
    
    // TXrptr_empty
    logic [3:0] TXrbin, TXrgraynext, TXrbinnext;
    logic TXrinc, TXrempty, TXrempty_val;
    //gray style 2 pointer
    always_ff @(posedge sck_phase_sel, negedge PRESETn)
        if (!PRESETn) {TXrbin, TXrptr} <= 0;
        else          {TXrbin, TXrptr} <= {TXrbinnext, TXrgraynext};

    assign TXraddr = TXrbin[2:0];
    assign TXrbinnext = TXrbin + (TXrinc & ~TXrempty)
    assign TXrgraynext = (TXrbinnext >> 1) ^ TXrbinnext;
    assign TXrempty_val = (TXrgraynext = TXrq2_wptr);

    always_ff @(posedge sck_phase_sel, negedge PRESETn)
        if (~PRESETn) TXrempty <= 1'b1;
        else          TXrempty <= TXrempty_val;

    
    //wptr_empty
    logic [3:0] TXwbin, TXwgraynext, TXwbinnext;
    logic TXwfull, TXwfull_val, TXwinc;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn)       {TXwbin, TXwptr} <=0;
        else                {TXwbin, TXwptr} <= {TXwbinnext, TXwgraynext};
    assign TXwaddr = TXwbin[2:0];

    assign TXwbinnext = TXwbin + (TXwinc & ~TXwfull);
    assign TXwgraynext = (TXwbinnext >> 1) ^ TXwbinnext;

    assign TXwfull_val = (TXwgraynext == (~TXwq2_rptr[3:2], TXwq2_rptr[1:0]));

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) TXwfull <= 1'b0;
        else          TXwfull <= TXwfull_val;


     //RXFIFO
    //fifomem asynch ram

    logic [7:0] RXmem[8];
    logic [7:0] RXrdata, RXwdata;
    logic [2:0] RXraddr, RXwaddr;
    logic RXwfull, RXwclken;
    assign RXrdata = RXmem[RXraddr];
    always_ff @(posedge PCLK)
        if (RXwclken & !RXwfull) mem(RXwaddr) <= RXwdata;
    
    //sync r2w
    logic [3:0] RXwq1_rptr, RXwq2_rptr, RXrptr;
    always_ff @(posedge PCL, negedge PRESETn)
        if(~PRESETn) {RXwq2_rptr, RXwq1_rptr} <= 0;
        else {RXwq2_rptr, RXwq1_rptr} <= {RXwq1_rptr, RXrptr};

    //sync w2r
    logic [3:0] RXrq1_wptr, RXrq2_wptr, RXwptr;
    always_ff @(posedge PCL, negedge PRESETn)
        if(~PRESETn) {RXrq2_wptr, RXrq1_wptr} <= 0;
        else {RXrq2_wptr, RXrq1_wptr} <= {RXrq1_wptr, RXwptr};
    
    // RXrptr_empty
    logic [3:0] RXrbin, RXrgraynext, RXrbinnext;
    logic RXrempty, RXrempty_val, RXrinc;
    //gray style 2 pointer
    always_ff @(posedge sck_phase_sel, negedge PRESETn)
        if (!PRESETn) {RXrbin, RXrptr} <= 0;
        else          {RXrbin, RXrptr} <= {RXrbinnext, RXrgraynext};

    assign RXraddr = RXrbin[2:0];
    assign RXrbinnext = RXrbin + (RXrinc & ~RXrempty)
    assign RXrgraynext = (RXrbinnext >> 1) ^ RXrbinnext;
    assign RXrempty_val = (RXrgraynext = RXrq2_wptr);

    always_ff @(posedge sck_phase_sel, negedge PRESETn)
        if (~PRESETn) RXrempty <= 1'b1;
        else          RXrempty <= RXrempty_val;

    
    //wptr_empty
    logic [3:0] RXwbin, RXwgraynext, RXwbinnext;
    logic RXwinc, RXwfull, RXwfull_val;
    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn)       {RXwbin, RXwptr} <=0;
        else                {RXwbin, RXwptr} <= {RXwbinnext, RXwgraynext};
    assign RXwaddr = RXwbin[2:0];

    assign RXwbinnext = RXwbin + (RXwinc & ~RXwfull);
    assign RXwgraynext = (RXwbinnext >> 1) ^ RXwbinnext;

    assign RXwfull_val = (RXwgraynext == (~RXwq2_rptr[3:2], RXwq2_rptr[1:0]));

    always_ff @(posedge PCLK, negedge PRESETn)
        if (~PRESETn) RXwfull <= 1'b0;
        else          RXwfull <= RXwfull_val;
    
    logic sck_phase_sel;
    logic [7:0] txShift;
    logic [7:0] rxShift;
    logic txShiftEmpty, rxShiftEmpty;
    assign sck_phase_sel = sck_mode[0] ? (sck_mode[1] ? sck : ~sck) : (sck_mode[1] ? ~sck : sck);
    always_ff @(posedge sck_phase_sel, negedge PRESETn)
        if(~PRESETn) txShift <= 8'b0;
        else begin
            if (~TXrempty) begin
                tx_fifo <= (fmt[2] ? ({tx_fifo[0], tx_fifo[1] , tx_fifo[2], tx_fifo[3], tx_data[4], tx_data[5], tx_data[6], tx_data[7]}) : tx_data);
            end else begin
                case (fmt[1:0])
                    2'b00: tx_fifo <= {tx_fifo[6:0], 1'b0};
                    2'b01: tx_fifo <= {tx_fifo[5:0], 2'b0};
                    2'b10: tx_fifo <= {tx_fifo[3:0], 4'b0};
                    default: tx_fifo <= {tx_fifo[6:0], 1'b0}; 
                endcase
            end
        
            case (fmt[1:0])
                2'b00: SPIOut[0] <= tx_fifo[7]; 
                2'b01: {SPIOut[0], SPIOut[1]} <= tx_fifo[7:6];
                2'b10: {SPIOut[0],SPIOut[1],SPIOut[2],SPIOut[3]} <= tx_fifo[7:4];
                default: SPIOut[0] <= tx_fifo[7];
            endcase
        end
    always_ff @(posedge sck_phase_sel, negedge PRESETn)
        if(~PRESETn) rx_fifo <= 8'b0;
        else if(~fmt[3]) begin
            case(fmt[1:0])
                2'b00: rx_fifo <= {SPIIn[0], rx_fifo[6:0]};
                2'b01: rx_fifo <= {SPIIn[0],SPIIn[1], rx_fifo[5:0]};
                2'b10: rx_fifo <= {SPIIn, rx_fifo[3:0]};
                default: rx_fifo <= {SPIIn, rx_fifo[6:0]};
            endcase
        end


always_ff @(posedge sclk_duty, negedge PRESETn)
        if (~PRESETn) state <= CS_INACTIVE;
        else case (state)
                CS_INACTIVE: begin
                            delay0_cnt <= 9'b1;
                            delay1_cnt <= 9'b1;
                            interxfr_cnt <= 9'b1;
                            frame_cnt <= 6'b0;
                            
                            if (TXwfull) state <= DELAY_0;
                            end
                DELAY_0: begin
                        intercs_cnt <= 9'b0;
                        delay0_cnt <= delay0_cnt + 9'b1;
                        if (delay0_cmp) state <= ACTIVE_0;
                        end
                ACTIVE_0: begin 
                        frame_cnt <= frame_cnt + 6'b1;
                        state <= ACTIVE_1;
                        end
                ACTIVE_1: begin
                        intercs_cnt <= 9'b0;
                        if ((frame_cnt << fmt[1:0]) < frame_cmp) state <= ACTIVE_0;
                        else if (cs_mode == 2'b10) begin
                                                state <= INTER_XFR;
                                                end
                        else state <= DELAY_1;
                        end
                DELAY_1: begin
                        intercs_cnt <= 9'b0;
                        delay1_cnt <= delay1_cnt + 9'b1;
                        if (delay1_cmp) state = INTER_CS;
                        end
                INTER_CS: begin
                        delay0_cnt <= 9'b1;
                        delay1_cnt <= 9'b1;
                        interxfr_cnt <= 9'b1;
                        frame_cnt <= 6'b0;
                        intercs_cnt <= intercs_cnt + 9'b1;
                        if (intercs_cmp ) state <= DELAY_0;
                        end
                INTER_XFR: begin
                        frame_cnt <= 6'b0;
                        delay0_cnt <= 9'b0;
                        delay1_cnt <= 9'b0;
                        interxfr_cnt <= interxfr_cnt + 9'b1;
                        if (interxfr_cmp) state <= ACTIVE_0;
                        end
            endcase
        */



    
    



             
