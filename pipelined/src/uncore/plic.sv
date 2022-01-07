///////////////////////////////////////////
// plic.sv
//
// Written: bbracker@hmc.edu 18 January 2021
// Modified: 
//
// Purpose: Platform-Level Interrupt Controller
//   Based on RISC-V spec (https://github.com/riscv/riscv-plic-spec/blob/master/riscv-plic.adoc)
//   With clarifications from ROA's existing implementation (https://roalogic.github.io/plic/docs/AHB-Lite_PLIC_Datasheet.pdf)
//   Supports only 1 target core and only a global threshold.
// 
// *** Big questions:
//  Do we detect requests as level-triggered or edge-trigged?
//  If edge-triggered, do we want to allow 1 source to be able to make a number of repeated requests?
//
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
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

`include "wally-config.vh"

module plic (
  input  logic             HCLK, HRESETn,
  input  logic             HSELPLIC,
  input  logic [27:0]      HADDR, // *** could factor out entryd into HADDRd at the level of uncore
  input  logic             HWRITE,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             UARTIntr,GPIOIntr,
  output logic [`XLEN-1:0] HREADPLIC,
  output logic             HRESPPLIC, HREADYPLIC,
  output logic             ExtIntM);

  localparam N=`PLIC_NUM_SRC; // should not exceed 63; does not inlcude source 0, which does not connect to anything according to spec

  logic memwrite, memread, initTrans;
  logic [23:0] entry, entryd;
  logic [31:0] Din, Dout;
  logic [N:1] requests;

  logic [2:0] intPriority[N:1];
  logic [2:0] intThreshold;
  logic [N:1] intPending, nextIntPending, intEn, intInProgress;
  logic [5:0] intClaim; // ID's are 6 bits if we stay within 63 sources

  logic [N:1] pendingArray[7:1];
  logic [7:1] pendingPGrouped;
  logic [7:1] pendingMaxP;
  logic [N:1] pendingRequestsAtMaxP;
  logic [7:1] threshMask;

  // =======
  // AHB I/O
  // =======
  assign entry = {HADDR[23:2],2'b0};
  assign initTrans = HREADY & HSELPLIC & (HTRANS != 2'b00);
  assign memread = initTrans & ~HWRITE;
  // entryd and memwrite are delayed by a cycle because AHB controller waits a cycle before outputting write data
  flopr #(1) memwriteflop(HCLK, ~HRESETn, initTrans & HWRITE, memwrite);
  flopr #(24) entrydflop(HCLK, ~HRESETn, entry, entryd);
  assign HRESPPLIC = 0; // OK
  assign HREADYPLIC = 1'b1; // PLIC never takes >1 cycle to respond

  // account for subword read/write circuitry
  // -- Note PLIC registers are 32 bits no matter what; access them with LW SW.
    if (`XLEN == 64) begin
    assign Din       = entryd[2] ? HWDATA[63:32] : HWDATA[31:0];
    assign HREADPLIC = entryd[2] ? {Dout,32'b0}  : {32'b0,Dout};
  end else begin // 32-bit
    assign Din       = HWDATA[31:0];
    assign HREADPLIC = Dout;
  end

  // ==================
  // Register Interface
  // ==================
  always @(posedge HCLK,negedge HRESETn) begin
    // resetting
    if (~HRESETn) begin
      intPriority <= #1 '{default:3'b0};
      intEn <= #1 {N{1'b0}};
      intThreshold <= #1 3'b0;
      intInProgress <= #1 {N{1'b0}};
    // writing
    end else begin
      if (memwrite)
        casez(entryd)
          24'h0000??: intPriority[entryd[7:2]] <= #1 Din[2:0];
          `ifdef PLIC_NUM_SRC_LT_32
          24'h002000: intEn[N:1] <= #1 Din[N:1];
          `endif
          `ifndef PLIC_NUM_SRC_LT_32
          24'h002000: intEn[31:1] <= #1 Din[31:1];
          24'h002004: intEn[N:32] <= #1 Din[31:0];
          `endif
          24'h200000: intThreshold[2:0] <= #1 Din[2:0];       
          24'h200004: intInProgress <= #1 intInProgress & ~(4'b1 << (Din[5:0]-1)); // lower "InProgress" to signify completion 
        endcase
      // reading
      if (memread)
        casez(entry)
          24'h0000??: Dout <= #1 {29'b0,intPriority[entry[7:2]]};
          `ifdef PLIC_NUM_SRC_LT_32
          24'h001000: Dout <= #1 {{(31-N){1'b0}},intPending[N:1],1'b0};
          24'h002000: Dout <= #1 {{(31-N){1'b0}},intEn[N:1],1'b0};
          `endif
          `ifndef PLIC_NUM_SRC_LT_32
          24'h001000: Dout <= #1 {intPending[31:1],1'b0};
          24'h001004: Dout <= #1 {{(63-N){1'b0}},intPending[N:32]};
          24'h002000: Dout <= #1 {intEn[31:1],1'b0};
          24'h002004: Dout <= #1 {{(63-N){1'b0}},intEn[N:32]};
          `endif
          24'h200000: Dout <= #1 {29'b0,intThreshold[2:0]};
          24'h200004: begin
            Dout <= #1 {26'b0,intClaim};
            intInProgress <= #1 intInProgress | (4'b1 << (intClaim-1)); // claimed requests are currently in progress of being serviced until they are completed
          end
          default: Dout <= #1 32'h0; // invalid access
        endcase
      else
        Dout <= #1 32'h0;
    end
  end

  // connect sources to requests
  always_comb begin
    requests = {N{1'b0}};
    `ifdef PLIC_GPIO_ID
      requests[`PLIC_GPIO_ID] = GPIOIntr;
    `endif
    `ifdef PLIC_UART_ID
      requests[`PLIC_UART_ID] = UARTIntr;
    `endif
  end

  // pending updates
  // *** verify that this matches the expectations of the things that make requests (in terms of timing, edge-triggered vs level-triggered)
  assign nextIntPending = (intPending | (requests & ~intInProgress)) & // requests should raise intPending except when their service routine is already in progress
                          ~({4{((entry == 24'h200004) & memread)}} << (intClaim-1)); // clear pending bit when claim register is read
  flopr #(N) intPendingFlop(HCLK,~HRESETn,nextIntPending,intPending);

  // pending array - indexed by priority_lvl x source_ID
  genvar i, j;
  for (j=1; j<=7; j++) begin: pending
    for (i=1; i<=N; i=i+1) begin: pendingbit
      assign pendingArray[j][i] = (intPriority[i]==j) & intEn[i] & intPending[i];
    end
  end
  // pending array, except grouped by priority
  assign pendingPGrouped[7:1] = {|pendingArray[7],
                                 |pendingArray[6],
                                 |pendingArray[5],
                                 |pendingArray[4],
                                 |pendingArray[3],
                                 |pendingArray[2],
                                 |pendingArray[1]}; 
  //assign pendingPGrouped = pendingArray.or;

  // pendingPGrouped, except only topmost priority is active
  assign pendingMaxP[7:1] = {pendingPGrouped[7],
                             pendingPGrouped[6] & ~|pendingPGrouped[7],
                             pendingPGrouped[5] & ~|pendingPGrouped[7:6],
                             pendingPGrouped[4] & ~|pendingPGrouped[7:5],
                             pendingPGrouped[3] & ~|pendingPGrouped[7:4],
                             pendingPGrouped[2] & ~|pendingPGrouped[7:3],
                             pendingPGrouped[1] & ~|pendingPGrouped[7:2]};
  // select the pending requests at that priority
  assign pendingRequestsAtMaxP[N:1] = ({N{pendingMaxP[7]}} & pendingArray[7])
                                    | ({N{pendingMaxP[6]}} & pendingArray[6])
                                    | ({N{pendingMaxP[5]}} & pendingArray[5])
                                    | ({N{pendingMaxP[4]}} & pendingArray[4])
                                    | ({N{pendingMaxP[3]}} & pendingArray[3])
                                    | ({N{pendingMaxP[2]}} & pendingArray[2])
                                    | ({N{pendingMaxP[1]}} & pendingArray[1]);
  // find the lowest ID amongst active interrupts at the highest priority
  logic [5:0] k;
  always_comb begin
    intClaim = 6'b0;
    for (k=N; k>0; k=k-1) begin
      if (pendingRequestsAtMaxP[k]) intClaim = k;
    end
  end
  
  // create threshold mask
   always_comb begin
    threshMask[7] = (intThreshold != 7);
    threshMask[6] = (intThreshold != 6) & threshMask[7];
    threshMask[5] = (intThreshold != 5) & threshMask[6];
    threshMask[4] = (intThreshold != 4) & threshMask[5];
    threshMask[3] = (intThreshold != 3) & threshMask[4];
    threshMask[2] = (intThreshold != 2) & threshMask[3];
    threshMask[1] = (intThreshold != 1) & threshMask[2];
  end
  // is the max priority > threshold?
  // *** would it be any better to first priority encode maxPriority into binary and then ">" with threshold?
  assign ExtIntM = |(threshMask & pendingPGrouped);
endmodule

