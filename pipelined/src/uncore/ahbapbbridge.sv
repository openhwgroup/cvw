///////////////////////////////////////////
// ahbapbbridge.sv
//
// Written: David_Harris@hmc.edu & Nic Lucio 7 June 2022
//
// Purpose: AHB to APB bridge
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

module ahbapbbridge #(PERIPHS = 2) (
  input  logic             HCLK, HRESETn,
  input  logic [PERIPHS-1:0] HSEL,  
  input  logic [31:0]      HADDR, 
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             HWRITE,
  input  logic [1:0]       HTRANS,
  input  logic             HREADY,
  output logic [`XLEN-1:0] HRDATA,
  output logic             HRESP, HREADYOUT,
  output logic             PCLK, PRESETn,
  output logic [PERIPHS-1:0] PSEL,
  output logic             PWRITE,
  output logic             PENABLE,
  output logic [31:0]      PADDR,
  output logic [`XLEN-1:0] PWDATA,
  input  logic [PERIPHS-1:0] PREADY,
  input  var   [`XLEN-1:0][PERIPHS-1:0] PRDATA
);

  logic activeTrans;
  logic initTrans, initTransSel, initTransSelD;
  logic nextPENABLE;

  // convert AHB to APB signals
  assign PCLK = HCLK;
  assign PRESETn = HRESETn;

  // identify start of a transaction
  assign activeTrans = (HTRANS == 2'b10); // only accept nonsequential transactions
  assign initTrans = activeTrans & HREADY;  // start a transaction when the bus is ready and an active transaction is requested
  assign initTransSel = initTrans & |HSEL; // capture data and address if any of the peripherals are selected

  // delay AHB Address phase signals to align with AHB Data phase because APB expects them at the same time
  flopenr #(32) addrreg(HCLK, ~HRESETn, initTransSel, HADDR, PADDR);
  flopenr #(1) writereg(HCLK, ~HRESETn, initTransSel, HWRITE, PWRITE);
  // enable selreg with iniTrans rather than initTransSel so PSEL can turn off
  flopenr #(PERIPHS) selreg(HCLK, ~HRESETn, initTrans, HSEL & {PERIPHS{activeTrans}}, PSEL); 
  // AHB Data phase signal doesn't need delay.  Note that HWDATA is guaranteed to remain stable until READY is asserted
  assign PWDATA = HWDATA;

  // enable logic: goes high a cycle after initTrans, then back low on cycle after desired PREADY is asserted
  // cycle1: AHB puts HADDR, HWRITE, HSEL on bus.  initTrans is 1, and these are captured
  // cycle2: AHB puts HWDATA on the bus.  This effectively extends the setup phase
  // cycle3: bridge raises PENABLE.  Peripheral typically responds with PREADY.  
  //         Read occurs by end of cycle.  Write occurs at end of cycle.
  flopr #(1) inittransreg(HCLK, ~HRESETn, initTransSel, initTransSelD);
  assign nextPENABLE = PENABLE ? ~HREADY : initTransSelD; 
  flopr #(1) enablereg(HCLK, ~HRESETn, nextPENABLE, PENABLE);

  // result and ready multiplexer 
  int i;
  always_comb
    for (i=0; i<PERIPHS; i++)  begin
      // no peripheral selected: read 0, indicate ready
      HRDATA = 0;
      HREADYOUT = 1;
      if (PSEL[i]) begin // highest numbered peripheral has priority, but multiple PSEL should never be asserted
          HRDATA = PRDATA[i];
          HREADYOUT = PREADY[i];
      end
    end

  // resp logic
  assign HRESP = 0; // bridge never indicates errors
endmodule

