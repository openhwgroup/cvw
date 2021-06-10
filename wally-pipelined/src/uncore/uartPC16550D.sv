///////////////////////////////////////////
// uart.sv
//
// Written: David_Harris@hmc.edu 21 January 2021
// Modified: 
//
// Purpose: Universial Asynchronous Receiver/ Transmitter with FIFOs
//          Emulates interface of Texas Instruments PC16550D
//          https://media.digikey.com/pdf/Data%20Sheets/Texas%20Instruments%20PDFs/PC16550D.pdf
//          Compatible with UART in Imperas Virtio model ***
//
//  Compatible with most of PC16550D with the following known exceptions:
//   Generates 2 rather than 1.5 stop bits when 5-bit word length is slected and LCR[2] = 1
//   Timeout not ye implemented***
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"
  /* verilator lint_off UNOPTFLAT */

module uartPC16550D(
  // Processor Interface
  input  logic       HCLK, HRESETn,
  input  logic [2:0] A,
  input  logic [7:0] Din,
  output logic [7:0] Dout,
  input  logic       MEMRb, MEMWb, 
  output logic       INTR, TXRDYb, RXRDYb,
  // Clocks
  output  logic      BAUDOUTb,
  input   logic      RCLK,
  // E1A Driver
  input  logic       SIN, DSRb, DCDb, CTSb, RIb,
  output logic       SOUT, RTSb, DTRb, OUT1b, OUT2b
);

  // transmit and receive states // *** neeed to work on synth warning -- it wants to make enums 32 bits by default
  typedef enum {UART_IDLE, UART_ACTIVE, UART_DONE, UART_BREAK} statetype;

  // Registers
  logic [10:0] RBR;
  logic [7:0] FCR, LCR, LSR, SCR, DLL, DLM;
  logic [3:0] IER, MSR;
  logic [4:0] MCR;

  // Syncrhonized and delayed UART signals
  logic SINd, DSRbd, DCDbd, CTSbd, RIbd;
  logic SINsync, DSRbsync, DCDbsync, CTSbsync, RIbsync;
  logic DSRb2, DCDb2, CTSb2, RIb2;
  logic SOUTbit;

  // Control signals
  logic loop; // loopback mode
  logic DLAB; // Divisor Latch Access Bit (LCR bit 7)

  // Baud and rx/tx timing
  logic baudpulse, txbaudpulse, rxbaudpulse; // high one system clk cycle each baud/16 period
  logic [23:0] baudcount;
  logic [3:0] rxoversampledcnt, txoversampledcnt; // count oversampled-by-16
  logic [3:0] rxbitsreceived, txbitssent;
  statetype rxstate, txstate;

  // shift registrs and FIFOs
  logic [9:0] rxshiftreg;
  logic [10:0] rxfifo[15:0];
  logic [7:0] txfifo[15:0];
  logic [3:0] rxfifohead, rxfifotail, txfifohead, txfifotail, rxfifotriggerlevel;
  logic [3:0] rxfifoentries, txfifoentries;
  logic [3:0] rxbitsexpected, txbitsexpected;

  // receive data
  logic [10:0] RXBR;
  logic [6:0] rxtimeoutcnt;
  logic rxcentered;
  logic rxparity, rxparitybit, rxstopbit;
  logic rxparityerr, rxoverrunerr, rxframingerr, rxbreak, rxfifohaserr;
  logic rxdataready;
  logic rxfifoempty, rxfifotriggered, rxfifotimeout;
  logic rxfifodmaready;
  logic [8:0] rxdata9;
  logic [7:0] rxdata;
  logic [15:0] RXerrbit, rxfullbit;

  // transmit data
  logic [11:0] TXHR, txdata, nexttxdata, txsr;
  logic txnextbit, txhrfull, txsrfull;
  logic txparity;
  logic txfifoempty, txfifofull, txfifodmaready;

  // control signals
  logic fifoenabled, fifodmamodesel, evenparitysel;

  // interrupts
  logic RXerr, RXerrIP, squashRXerrIP, prevSquashRXerrIP, setSquashRXerrIP, resetSquashRXerrIP;
  logic THRE, THRE_IP, squashTHRE_IP, prevSquashTHRE_IP, setSquashTHRE_IP, resetSquashTHRE_IP;
  logic rxdataavailintr, modemstatusintr, intrpending;
  logic [2:0] intrID;

  ///////////////////////////////////////////
  // Input synchronization: 2-stage synchronizer
  ///////////////////////////////////////////
  always_ff @(posedge HCLK) begin
    {SINd, DSRbd, DCDbd, CTSbd, RIbd} <= #1 {SIN, DSRb, DCDb, CTSb, RIb};
    {SINsync, DSRbsync, DCDbsync, CTSbsync, RIbsync} <= #1 loop ? {SOUTbit, ~MCR[0], ~MCR[3], ~MCR[1], ~MCR[2]} : 
        {SINd, DSRbd, DCDbd, CTSbd, RIbd}; // syncrhonized signals, handle loopback testing
    {DSRb2, DCDb2, CTSb2, RIb2} <= #1 {DSRbsync, DCDbsync, CTSbsync, RIbsync}; // for detecting state changes
  end

  ///////////////////////////////////////////
  // Register interface (Table 1, note some are read only and some write only)
  ///////////////////////////////////////////
  always_ff @(posedge HCLK, negedge HRESETn) 
    if (~HRESETn) begin // Table 3 Reset Configuration
      IER <= #1 4'b0;
      FCR <= #1 8'b0;
      LCR <= #1 8'b0;
      MCR <= #1 5'b0;
      LSR <= #1 8'b01100000;
      MSR <= #1 4'b0;
      DLL <= #1 8'b0;
      DLM <= #1 8'b0;
      SCR <= #1 8'b0; // not strictly necessary to reset
    end else begin
      if (~MEMWb) begin
        case (A)
          3'b000: if (DLAB) DLL <= #1 Din; // else TXHR <= #1 Din; // TX handled in TX register/FIFO section
          3'b001: if (DLAB) DLM <= #1 Din; else IER <= #1 Din[3:0];
          3'b010: FCR <= #1 {Din[7:6], 2'b0, Din[3], 2'b0, Din[0]}; // Write only FIFO Control Register; 4:5 reserved and 2:1 self-clearing
          3'b011: LCR <= #1 Din;
          3'b100: MCR <= #1 Din[4:0];
          3'b101: LSR[6:1] <= #1 Din[6:1];  // recommended only for test, see 8.6.3
          3'b110: MSR <= #1 Din[3:0];
          3'b111: SCR <= #1 Din;
        endcase
      end
      
      // Line Status Register (8.6.3)
      //   Ben 6/9/21 I don't like how this is a register. A lot of the individual bits have clocked components, so this just adds unecessary delay.
      LSR[0] <= #1 rxdataready; // Data ready
      LSR[1] <= #1 (LSR[1] | RXBR[10]) & ~squashRXerrIP;; // overrun error
      LSR[2] <= #1 (LSR[2] | RXBR[9]) & ~squashRXerrIP; // parity error
      LSR[3] <= #1 (LSR[3] | RXBR[8]) & ~squashRXerrIP; // framing error
      LSR[4] <= #1 (LSR[4] | rxbreak) & ~squashRXerrIP; // break indicator
      LSR[5] <= #1 THRE; // THRE
      LSR[6] <= #1 ~txsrfull & THRE; //  TEMT
      if (rxfifohaserr) LSR[7] <= #1 1; // any bits in FIFO have error

      // Modem Status Register (8.6.8)
      MSR[0] <= #1 MSR[0] | CTSb2 ^ CTSbsync; // Delta Clear to Send
      MSR[1] <= #1 MSR[1] | DSRb2 ^ DSRbsync; // Delta Data Set Ready
      MSR[2] <= #1 MSR[2] | (~RIb2 & RIbsync); // Trailing Edge of Ring Indicator
      MSR[3] <= #1 MSR[3] | DCDb2 ^ DCDbsync; // Delta Data Carrier Detect
    end
  always_comb
    if (~MEMRb)
      case (A)
        3'b000: if (DLAB) Dout = DLL; else Dout = RBR;
        3'b001: if (DLAB) Dout = DLM; else Dout = {4'b0, IER[3:0]};
        3'b010: Dout = {{2{fifoenabled}}, 2'b00, intrID[2:0], ~intrpending}; // Read only Interupt Ident Register
        3'b011: Dout = LCR;
        3'b100: Dout = {3'b000, MCR};
        3'b101: Dout = LSR;
        3'b110: Dout = {~CTSbsync, ~DSRbsync, ~RIbsync, ~DCDbsync, MSR[3:0]}; 
        3'b111: Dout = SCR;      
      endcase
    else Dout = 8'b0;

  ///////////////////////////////////////////
  // Baud rate generator
  // consider switching to same fixed-frequency reference clock used for TIME register
  // prescale by factor of 2^UART_PRESCALE to allow for high-frequency reference clock
  // Unlike PC16550D, this unit is hardwired with same rx and tx baud clock
  // *** add table of scale factors to get 16x uart clk
  ///////////////////////////////////////////
  always_ff @(posedge HCLK, negedge HRESETn) 
    if (~HRESETn) begin
      baudcount <= #1 0;
      baudpulse <= #1 0;
    end else begin
      baudpulse <= #1 (baudcount == {DLM, DLL, {(`UART_PRESCALE){1'b0}}});
      baudcount <= #1 baudpulse ? 0 :  baudcount +1;
    end
  assign txbaudpulse = baudpulse;
  assign BAUDOUTb = ~baudpulse;
  assign rxbaudpulse = ~RCLK; // usually BAUDOUTb tied to RCLK externally

  ///////////////////////////////////////////
  // receive timing and control
  ///////////////////////////////////////////
  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) begin
      rxoversampledcnt <= #1 0;
      rxstate <= #1 UART_IDLE;
      rxbitsreceived <= #1 0;
      rxtimeoutcnt <= #1 0;
    end else begin
      if (rxstate == UART_IDLE & ~SINsync) begin // got start bit
        rxstate <= #1 UART_ACTIVE;
        rxoversampledcnt <= #1 0;
        rxbitsreceived <= #1 0;
        rxtimeoutcnt <= #1 0; // reset timeout when new character is arriving
      end else if (rxbaudpulse & (rxstate == UART_ACTIVE)) begin
        rxoversampledcnt <= #1 rxoversampledcnt + 1;  // 16x oversampled counter
        if (rxcentered) rxbitsreceived <= #1 rxbitsreceived + 1;
        if (rxbitsreceived == rxbitsexpected) rxstate <= #1 UART_DONE; // pulse rxdone for a cycle
      end else if (rxstate == UART_DONE || rxstate == UART_BREAK) begin
        if (rxbreak & ~SINsync) rxstate <= #1 UART_BREAK;
        else rxstate <= #1 UART_IDLE;
      end
      // timeout counting
      if (~MEMRb && A == 3'b000 && ~DLAB) rxtimeoutcnt <= #1 0; // reset timeout on read
      else if (fifoenabled & ~rxfifoempty & rxbaudpulse & ~rxfifotimeout) rxtimeoutcnt <= #1 rxtimeoutcnt+1; // *** not right
    end

  assign rxcentered = rxbaudpulse && (rxoversampledcnt == 4'b1000);  // implies rxstate = UART_ACTIVE
  assign rxbitsexpected = 1 + (5 + LCR[1:0]) + LCR[3] + 1; // start bit + data bits + (parity bit) + stop bit 
  
  ///////////////////////////////////////////
  // receive shift register, buffer register, FIFO
  ///////////////////////////////////////////
  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) rxshiftreg <= #1 9'b000000001; // initialize so that there is a valid stop bit
    else if (rxcentered) rxshiftreg <= #1 {rxshiftreg[8:0], SINsync}; // capture bit
  assign rxparitybit = rxshiftreg[1]; // parity, if it exists, in bit 1 when all done
  assign rxstopbit = rxshiftreg[0];
  always_comb
    case(LCR[1:0]) // check how many bits used.  Grab all bits including possible parity
      2'b00: rxdata9 = {3'b0, rxshiftreg[6:1]}; // 5-bit character
      2'b01: rxdata9 = {2'b0, rxshiftreg[7:1]}; // 6-bit 
      2'b10: rxdata9 = {1'b0, rxshiftreg[8:1]}; // 7-bit
      2'b11: rxdata9 = rxshiftreg[9:1];
    endcase
  assign rxdata = LCR[3] ? rxdata9[8:1] : rxdata9[7:0]; // discard parity bit

  // ERROR CONDITIONS
  assign rxparity = ^rxdata;
  assign rxparityerr = rxparity ^ rxparitybit ^ ~evenparitysel; // Check even/odd parity (*** check if LCR needs to be inverted)
  assign rxoverrunerr = fifoenabled ? (rxfifoentries == 15) : rxdataready; // overrun if FIFO or receive buffer register full 
  assign rxframingerr = ~rxstopbit; // framing error if no stop bit
  assign rxbreak = rxframingerr & (rxdata9 == 9'b0); // break when 0 for start + data + parity + stop time

  // receive FIFO and register
  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) begin
      rxfifohead <= #1 0; rxfifotail <= #1 0; rxdataready <= #1 0; RXBR <= #1 0;
    end else begin
      if (rxstate == UART_DONE) begin
        RXBR <= #1 {rxoverrunerr, rxparityerr, rxframingerr, rxdata}; // load recevive buffer register
        if (fifoenabled) begin
          rxfifo[rxfifohead] <= #1 {rxoverrunerr, rxparityerr, rxframingerr, rxdata};
          rxfifohead <= #1 rxfifohead + 1;
        end
        rxdataready <= #1 1;
      end else if (~MEMRb && A == 3'b000 && ~DLAB) begin // reading RBR updates ready / pops fifo 
        if (fifoenabled) begin
          rxfifotail <= #1 rxfifotail + 1;
          if (rxfifohead == rxfifotail +1) rxdataready <= #1 0;
        end else rxdataready <= #1 0;
      end else if (~MEMWb && A == 3'b010)  // writes to FIFO Control Register
        if (Din[1] | ~Din[0]) begin // rx FIFO reset or FIFO disable clears FIFO contents
          rxfifohead <= #1 0; rxfifotail <= #1 0;
        end
    end

  assign rxfifoempty = (rxfifohead == rxfifotail);
  assign rxfifoentries = (rxfifohead >= rxfifotail) ? (rxfifohead-rxfifotail) : 
                                                      (rxfifohead + 16 - rxfifotail);
  assign rxfifotriggered = rxfifoentries >= rxfifotriggerlevel;
  //assign rxfifotimeout = rxtimeoutcnt[6]; // time out after 4 character periods; *** probably not right yet
  assign rxfifotimeout = 0; // disabled pending fix

  // detect any errors in rx fifo
  // although rxfullbit looks like a combinational loop, in one bit rxfifotail == i and breaks the loop
  generate
    genvar i;
    for (i=0; i<16; i++) begin
      assign RXerrbit[i] = |rxfifo[i][10:8]; // are any of the error conditions set?
      if (i > 0)
        assign rxfullbit[i] = ((rxfifohead==i) | rxfullbit[i-1]) & (rxfifotail != i);
      else
        assign rxfullbit[0] = ((rxfifohead==i) | rxfullbit[15]) & (rxfifotail != i);
    end
  endgenerate
  assign rxfifohaserr = |(RXerrbit & rxfullbit);

  // receive buffer register and ready bit
  always_ff @(posedge HCLK, negedge HRESETn) // track rxrdy for DMA mode (FCR3 = FCR0 = 1)
    if (~HRESETn) rxfifodmaready <= #1 0;
    else if (rxfifotriggered | rxfifotimeout) rxfifodmaready <= #1 1;
    else if (rxfifoempty) rxfifodmaready <= #1 0;

  always_comb
    if (fifoenabled) begin
      if (rxfifoempty) RBR = 11'b0;
      else             RBR = rxfifo[rxfifotail];
      if (fifodmamodesel) RXRDYb = ~rxfifodmaready;
      else                RXRDYb = rxfifoempty;
    end else begin
      RBR = RXBR;
      RXRDYb = ~rxdataready;
    end

  ///////////////////////////////////////////
  // transmit timing and control
  ///////////////////////////////////////////
  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) begin
      txoversampledcnt <= #1 0;
      txstate <= #1 UART_IDLE;
      txbitssent <= #1 0;
    end else if ((txstate == UART_IDLE) && txsrfull) begin // start transmitting
      txstate <= #1 UART_ACTIVE;
      txoversampledcnt <= #1 1;
      txbitssent <= #1 0;
    end else if (txbaudpulse & (txstate == UART_ACTIVE)) begin
      txoversampledcnt <= #1 txoversampledcnt + 1; 
      if (txnextbit) begin // transmit at end of phase
        txbitssent <= #1 txbitssent+1;
        if (txbitssent == txbitsexpected) txstate <= #1 UART_DONE;
      end
    end else if (txstate == UART_DONE) begin
      txstate <= #1 UART_IDLE;
    end

  assign txbitsexpected = 1 + (5 + LCR[1:0]) + LCR[3] + 1 + LCR[2] - 1; // start bit + data bits + (parity bit) + stop bit(s)
  assign txnextbit = txbaudpulse && (txoversampledcnt == 4'b0000);  // implies txstate = UART_ACTIVE

  ///////////////////////////////////////////
  // transmit holding register, shift register, FIFO
  ///////////////////////////////////////////
  always_comb begin // compute value for parity and tx holding register
    nexttxdata = fifoenabled ? txfifo[txfifotail] : TXHR; // pick from FIFO or holding register
    case (LCR[1:0]) // compute parity from appropriate number of bits
      2'b00: txparity = ^nexttxdata[4:0] ^ ~evenparitysel; // *** check polarity
      2'b01: txparity = ^nexttxdata[5:0] ^ ~evenparitysel; 
      2'b10: txparity = ^nexttxdata[6:0] ^ ~evenparitysel; 
      2'b11: txparity = ^nexttxdata[7:0] ^ ~evenparitysel; 
    endcase
    case({LCR[3], LCR[1:0]}) // parity, data bits
      // load up start bit (0), 5-8 data bits, 0-1 parity bits, 2 stop bits (only one sometimes used), padding
      3'b000: txdata = {1'b0, nexttxdata[4:0], 6'b111111};          // 5 data, no parity
      3'b001: txdata = {1'b0, nexttxdata[5:0], 5'b11111};           // 6 data, no parity
      3'b010: txdata = {1'b0, nexttxdata[6:0], 4'b1111};            // 7 data, no parity
      3'b011: txdata = {1'b0, nexttxdata[7:0], 3'b111};             // 8 data, no parity
      3'b100: txdata = {1'b0, nexttxdata[4:0], txparity, 5'b11111}; // 5 data, parity
      3'b101: txdata = {1'b0, nexttxdata[5:0], txparity, 4'b1111};  // 6 data, parity
      3'b110: txdata = {1'b0, nexttxdata[6:0], txparity, 3'b111};   // 7 data, parity
      3'b111: txdata = {1'b0, nexttxdata[7:0], txparity, 2'b11};    // 8 data, parity
    endcase
  end
       
  // registers & FIFO
  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) begin
      txfifohead <= #1 0; txfifotail <= #1 0; txhrfull <= #1 0; txsrfull <= #1 0; TXHR <= #1 0; txsr <= #1 12'hfff;
    end else begin
      if (~MEMWb && A == 3'b000 && ~DLAB) begin // writing transmit holding register or fifo
        if (fifoenabled) begin
          txfifo[txfifohead] <= #1 Din;
          txfifohead <= #1 txfifohead + 1;          
        end else begin 
          TXHR <= #1 Din;
          txhrfull <= #1 1;
        end
        $write("%c",Din); // for testbench
       end
      if (txstate == UART_IDLE) begin // move data into tx shift register if available
        if (fifoenabled) begin 
          if (~txfifoempty) begin
            txsr <= #1 txdata;
            txfifotail <= #1 txfifotail+1;
            txsrfull <= #1 1;
          end
        end else if (txhrfull) begin
          txsr <= #1 txdata;
          txhrfull <= #1 0;
          txsrfull <= #1 1;
        end
      end else if (txstate == UART_DONE) txsrfull <= #1 0; // done transmitting shift register
      else if (txstate == UART_ACTIVE && txnextbit) txsr <= #1 {txsr[10:0], 1'b1}; // shift txhr
      if (!MEMWb && A == 3'b010) // writes to FIFO control register
        if (Din[2] | ~Din[0]) begin // tx FIFO reste or FIFO disable clears FIFO contents
          txfifohead <= #1 0; txfifotail <= #1 0;
        end
    end

  assign txfifoempty = (txfifohead == txfifotail);
  assign txfifoentries = (txfifohead >= txfifotail) ? (txfifohead-txfifotail) : 
                                                      (txfifohead + 16 - txfifotail);
  assign txfifofull = (txfifoentries == 4'b1111);

  // transmit buffer ready bit
  always_ff @(posedge HCLK, negedge HRESETn) // track txrdy for DMA mode (FCR3 = FCR0 = 1)
    if (~HRESETn) txfifodmaready <= #1 0;
    else if (txfifoempty) txfifodmaready <= #1 1;
    else if (txfifofull)  txfifodmaready <= #1 0;

  always_comb
    if (fifoenabled & fifodmamodesel) TXRDYb = ~txfifodmaready;
    else TXRDYb  = ~THRE;

  // Transmitter pin 
  assign SOUTbit = txsr[11]; // transmit most significant bit
  assign SOUT = loop ? 1 : (LCR[6] ? 0 : SOUTbit); // tied to 1 during loopback or 0 during break 

  ///////////////////////////////////////////
  // interrupts
  ///////////////////////////////////////////
  assign RXerr = |LSR[4:1]; // LS interrupt if any of the flags are true
  assign RXerrIP = RXerr & ~squashRXerrIP; // intr squashed upon reading LSR
  assign rxdataavailintr = fifoenabled ? rxfifotriggered : rxdataready; 
  assign THRE = fifoenabled ? txfifoempty : ~txhrfull;
  assign THRE_IP = THRE & ~squashTHRE_IP; // THRE_IP squashed upon reading IIR
  assign modemstatusintr = |MSR[3:0]; // set interrupt when modem pins change
 
  // IIR: interrupt priority (Table 5)
  // set intrID based on highest priority pending interrupt source; otherwise, no interrupt is pending
  always_comb begin
    intrpending = 1;
    if      (RXerrIP & IER[2])                     intrID = 3'b011;
    else if (rxdataavailintr & IER[0])             intrID = 3'b010;
    else if (rxfifotimeout & fifoenabled & IER[0]) intrID = 3'b110;
    else if (THRE_IP & IER[1])                     intrID = 3'b001;
    else if (modemstatusintr & IER[3])             intrID = 3'b000;
    else begin
      intrID = 3'b000;
      intrpending = 0;
    end
  end
  always @(posedge HCLK) INTR <= #1 intrpending; // prevent glitches on interrupt pin

  // Side effect of reading LSR is lowering overrun, parity, framing, break intr's
  assign setSquashRXerrIP = ~MEMRb & (A==3'b101);
  assign resetSquashRXerrIP = (rxstate == UART_DONE);
  assign squashRXerrIP = (prevSquashRXerrIP | setSquashRXerrIP) & ~resetSquashRXerrIP;
  flopr #(1) squashRXerrIPreg(HCLK, ~HRESETn, squashRXerrIP, prevSquashRXerrIP);
  // Side effect of reading IIR is lowering THRE_IP if most significant intr
  assign setSquashTHRE_IP = ~MEMRb & (A==3'b010) & (intrID==2'h1); // there's a 1-cycle delay on set squash so that THRE_IP doesn't change during the process of reading IIR (otherwise combinational loop)
  assign resetSquashTHRE_IP = ~THRE;
  assign squashTHRE_IP = prevSquashTHRE_IP & ~resetSquashTHRE_IP;
  flopr #(1) squashTHRE_IPreg(HCLK, ~HRESETn, squashTHRE_IP | setSquashTHRE_IP, prevSquashTHRE_IP);

  ///////////////////////////////////////////
  // modem control logic
  ///////////////////////////////////////////

  assign loop = MCR[4]; 
  assign DTRb  = ~MCR[0] | loop; // disable modem signals in loopback mode
  assign RTSb  = ~MCR[1] | loop;
  assign OUT1b = ~MCR[2] | loop;
  assign OUT2b = ~MCR[3] | loop;

  assign DLAB = LCR[7];
  assign evenparitysel = LCR[4];
  assign fifoenabled = FCR[0];
  assign fifodmamodesel = FCR[3];
  always_comb
    case (FCR[7:6]) 
      2'b00: rxfifotriggerlevel = 1;
      2'b01: rxfifotriggerlevel = 4;
      2'b10: rxfifotriggerlevel = 8;
      2'b11: rxfifotriggerlevel = 14;
    endcase

endmodule

  /* verilator lint_on UNOPTFLAT */
