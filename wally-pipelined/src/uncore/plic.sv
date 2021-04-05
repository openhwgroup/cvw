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
//  Should PLIC also output SEIP or just MEIP?
//  MEIP is the same as ExtIntM, right?
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

module plic (
  input  logic             HCLK, HRESETn,
  input  logic             HSELPLIC,
  input  logic [27:0]      HADDR,
  input  logic             HWRITE,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             UARTIntr,
  output logic [`XLEN-1:0] HREADPLIC,
  output logic             HRESPPLIC, HREADYPLIC,
  output logic             ExtIntM);

  localparam N=`PLIC_NUM_SRC; // should not exceed 63; does not inlcude source 0, which does not connect to anything according to spec

  logic memwrite, initTrans;
  logic [27:0] entry, entryd;
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

  // AHB I/O
  assign entry = {HADDR[27:2],2'b0};
  assign initTrans = HREADY & HSELPLIC & (HTRANS != 2'b00);
  assign memread = initTrans & ~HWRITE;
  // entryd and memwrite are delayed by a cycle because AHB controller waits a cycle before outputting write data
  flopr #(1) memwriteflop(HCLK, ~HRESETn, initTrans & HWRITE, memwrite);
  flopr #(28) entrydflop(HCLK, ~HRESETn, entry, entryd);
  assign HRESPPLIC = 0; // OK
  assign HREADYPLIC = 1'b1; // PLIC never takes >1 cycle to respond

  // account for subword read/write circuitry
  // -- Note PLIC registers are 32 bits no matter what; access them with LW SW.
  generate
    if (`XLEN == 64) begin
      always_comb
        if (entryd[2]) begin
          Din = HWDATA[63:32];
          HREADPLIC = {Dout,32'b0};
        end else begin
          Din = HWDATA[31:0];
          HREADPLIC = {32'b0,Dout};
        end
    end else begin // 32-bit
      always_comb begin
        Din = HWDATA[31:0];
        HREADPLIC = Dout;
      end
    end
  endgenerate

  // register interface
  genvar i;
  generate
    // priority registers
    for (i=1; i<=N; i=i+1)
      always @(posedge HCLK,negedge HRESETn)
        if (~HRESETn)
          intPriority[i] <= 3'b0;
        else begin
          if (entry == 28'hc000000+4*i) // *** make sure this does not synthesize into N 28-bit equality comparators; we want something more decoder-ish 
            Dout <= #1 {{(`XLEN-3){1'b0}},intPriority[i]};
          if ((entryd == 28'hc000000+4*i) && memwrite)
            intPriority[i] <= #1 Din[2:0];
        end

    // pending and enable registers
    if (N<32)
      always @(posedge HCLK,negedge HRESETn)
        if (~HRESETn)
          intEn <= {N{1'b0}};
        else begin
          if (entry == 28'hc001000)
            Dout <= #1 {{(31-N){1'b0}},intPending[N:1],1'b0};
          if (entry == 28'hc002000)
            Dout <= #1 {{(31-N){1'b0}},intEn[N:1],1'b0};
          if ((entryd == 28'hc002000) && memwrite)
            intEn[N:1] <= #1 Din[N:1];
        end
    else // N>=32
      always @(posedge HCLK,negedge HRESETn)
        if (~HRESETn)
          intEn <= {N{1'b0}};
        else begin
          if (entry == 28'hc001000)
            Dout <= #1 {intPending[31:1],1'b0};
          if (entry == 28'hc001004)
            Dout <= #1 {{(63-N){1'b0}},intPending[N:32]};
          if (entry == 28'hc002000)
            Dout <= #1 {intEn[31:1],1'b0};
          if (entry == 28'hc002004)
            Dout <= #1 {{(63-N){1'b0}},intEn[N:32]};
          if ((entryd == 28'hc002000) && memwrite)
            intEn[31:1] <= #1 Din[31:1];
          if ((entryd == 28'hc002004) && memwrite)
            intEn[N:32] <= #1 Din[31:0];
        end

    // threshold and claim/complete registers
    always @(posedge HCLK, negedge HRESETn)
      if (~HRESETn) begin
        intThreshold<=3'b0;
        intInProgress <= {N{1'b0}};
      end else begin
        if (entry == 28'hc200000)
          Dout <= #1 {29'b0,intThreshold[2:0]};
        if ((entryd == 28'hc200000) && memwrite)
          intThreshold[2:0] <= #1 Din[2:0];
        if ((entry == 28'hc200004) && memread) begin // check for memread because reading claim reg. has side effects
          Dout <= #1 {26'b0,intClaim};
          intInProgress <= #1 intInProgress | (1'b1 << (intClaim-1)); // claimed requests are currently in progress of being serviced until they are completed
        end
        if ((entryd == 28'hc200004) && memwrite)
          intInProgress <= #1 intInProgress & ~(1'b1 << (Din[5:0]-1)); // lower "InProgress" to signify completion
      end
  endgenerate

  // connect sources to requests
  `ifdef PLIC_UART_ID
    assign requests[`PLIC_UART_ID] = UARTIntr;
  `endif
  //  or temporarily connect them to nothing
  assign requests[3:1] = 3'b0;
  
  // pending updates
  // *** verify that this matches the expectations of the things that make requests (in terms of timing, edge-triggered vs level-triggered)
  assign nextIntPending = (intPending | (requests & ~intInProgress)) // requests should raise intPending except when their service routine is already in progress
                        & ~(((entry == 28'hc200004) && memread) << (intClaim-1)); // clear pending bit when claim register is read
  flopr #(N) intPendingFlop(HCLK,~HRESETn,nextIntPending,intPending);

  // pending array - indexed by priority_lvl x source_ID
  generate
    for (i=1; i<=N; i=i+1) begin
      // *** make sure that this synthesizes into N decoders, not 7*N 3-bit equality comparators (right?)
      assign pendingArray[7][i] = (intPriority[i]==7) & intEn[i] & intPending[i];
      assign pendingArray[6][i] = (intPriority[i]==6) & intEn[i] & intPending[i];
      assign pendingArray[5][i] = (intPriority[i]==5) & intEn[i] & intPending[i];
      assign pendingArray[4][i] = (intPriority[i]==4) & intEn[i] & intPending[i];
      assign pendingArray[3][i] = (intPriority[i]==3) & intEn[i] & intPending[i];
      assign pendingArray[2][i] = (intPriority[i]==2) & intEn[i] & intPending[i];
      assign pendingArray[1][i] = (intPriority[i]==1) & intEn[i] & intPending[i];
    end
  endgenerate
  // pending array, except grouped by priority
  assign pendingPGrouped[7:1] = {|pendingArray[7],
                                 |pendingArray[6],
                                 |pendingArray[5],
                                 |pendingArray[4],
                                 |pendingArray[3],
                                 |pendingArray[2],
                                 |pendingArray[1]};
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
  integer j;
  // *** verify that this synthesizes to a reasonable priority encoder and that j doesn't actually exist in hardware
  always_comb begin
    intClaim = 6'b0;
    for(j=N; j>0; j=j-1) begin
      if(pendingRequestsAtMaxP[j]) intClaim = j;
    end
  end
  
  // create threshold mask
  //   *** I think this commented out version would be nice, but linter complains about circular logic
  //assign threshMask[7:1] = {~(7==intThreshold),
  //                          ~(6==intThreshold) & threshMask[7],
  //                          ~(5==intThreshold) & threshMask[6],
  //                          ~(4==intThreshold) & threshMask[5],
  //                          ~(3==intThreshold) & threshMask[4],
  //                          ~(2==intThreshold) & threshMask[3],
  //                          ~(1==intThreshold) & threshMask[2]};
  //   *** verify that this alternate version does not synthesize to 7 separate comparators
  assign threshMask[7:1] = {(7>intThreshold),
                            (6>intThreshold),
                            (5>intThreshold),
                            (4>intThreshold),
                            (3>intThreshold),
                            (2>intThreshold),
                            (1>intThreshold)};
  // is the max priority > threshold?
  // *** would it be any better to first priority encode maxPriority into binary and then ">" with threshold?
  assign ExtIntM = |(threshMask & pendingPGrouped);
endmodule

