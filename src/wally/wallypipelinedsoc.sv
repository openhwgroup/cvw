///////////////////////////////////////////
// wally-pipelinedsoc.sv
//
// Written: David_Harris@hmc.edu 6 November 2020
// Modified: 
//
// Purpose: System on chip including pipelined processor and uncore memories/peripherals
//
// Documentation: RISC-V System on Chip Design (Figure 6.20)
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

module wallypipelinedsoc import cvw::*; #(parameter cvw_t P)  (
  input  logic                clk, 
  input  logic                reset_ext,        // external asynchronous reset pin
  output logic                reset,            // reset synchronized to clk to prevent races on release
  // AHB Interface
  input  logic [P.AHBW-1:0]     HRDATAEXT,
  input  logic                HREADYEXT, HRESPEXT,
  output logic                HSELEXT,
  output logic                HSELEXTSDC, 
  // outputs to external memory, shared with uncore memory
  output logic                HCLK, HRESETn,
  output logic [P.PA_BITS-1:0]  HADDR,
  output logic [P.AHBW-1:0]     HWDATA,
  output logic [P.XLEN/8-1:0]   HWSTRB,
  output logic                HWRITE,
  output logic [2:0]          HSIZE,
  output logic [2:0]          HBURST,
  output logic [3:0]          HPROT,
  output logic [1:0]          HTRANS,
  output logic                HMASTLOCK,
  output logic                HREADY,
  // I/O Interface
  input  logic                TIMECLK,          // optional for CLINT MTIME counter
  input  logic [31:0]         GPIOIN,           // inputs from GPIO
  output logic [31:0]         GPIOOUT,          // output values for GPIO
  output logic [31:0]         GPIOEN,           // output enables for GPIO
  input  logic                UARTSin,          // UART serial data input
  output logic                UARTSout,         // UART serial data output
  input  logic                SDCIntr,
  input  logic                SPIIn,            // SPI pins in
  output logic                SPIOut,           // SPI pins out
  output logic [3:0]          SPICS             // SPI chip select pins                    
);

  // Uncore signals
  logic [P.AHBW-1:0]          HRDATA;           // from AHB mux in uncore
  logic                       HRESP;            // response from AHB
  logic                       MTimerInt, MSwInt;// timer and software interrupts from CLINT
  logic [63:0]                MTIME_CLINT;      // from CLINT to CSRs
  logic                       MExtInt,SExtInt;  // from PLIC

  localparam MAX_CSRS = 3;
  logic                       valid;
  logic                       RVVIStall;
  logic [187+(3*P.XLEN) + MAX_CSRS*(P.XLEN+12)-1:0] rvvi;

  // synchronize reset to SOC clock domain
  synchronizer resetsync(.clk, .d(reset_ext), .q(reset)); 
   
  // instantiate processor and internal memories
  wallypipelinedcore #(P) core(.clk, .reset,
    .MTimerInt, .MExtInt, .SExtInt, .MSwInt, .MTIME_CLINT,
    .HRDATA, .HREADY, .HRESP, .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB,
    .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK, .RVVIStall
   );

  // instantiate uncore if a bus interface exists
  if (P.BUS_SUPPORTED) begin : uncoregen // Hack to work around Verilator bug https://github.com/verilator/verilator/issues/4769
    uncore #(P) uncore(.HCLK, .HRESETn, .TIMECLK,
      .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK, .HRDATAEXT,
      .HREADYEXT, .HRESPEXT, .HRDATA, .HREADY, .HRESP, .HSELEXT, .HSELEXTSDC,
      .MTimerInt, .MSwInt, .MExtInt, .SExtInt, .GPIOIN, .GPIOOUT, .GPIOEN, .UARTSin, 
      .UARTSout, .MTIME_CLINT, .SDCIntr, .SPIIn, .SPIOut, .SPICS);
  end else begin
    assign {HRDATA, HREADY, HRESP, HSELEXT, HSELEXTSDC, MTimerInt, MSwInt, MExtInt, SExtInt,
            MTIME_CLINT, GPIOOUT, GPIOEN, UARTSout, SPIOut, SPICS} = '0; 
  end



  rvvisynth #(P, MAX_CSRS) rvvisynth(.clk, .reset, .valid, .rvvi);

  logic [3:0]                                       m_axi_awid;
  logic [12:0]                                      m_axi_awaddr;
  logic [7:0]                                       m_axi_awlen;
  logic [2:0]                                       m_axi_awsize;
  logic [1:0]                                       m_axi_awburst;
  logic [3:0]                                       m_axi_awcache;
  logic                                             m_axi_awvalid;
  logic                                             m_axi_awready;
  // axi 4 write data channel
  logic [31:0]                                      m_axi_wdata;
  logic [3:0]                                       m_axi_wstrb;
  logic                                             m_axi_wlast;
  logic                                             m_axi_wvalid;
  logic                                             m_axi_wready;
  // axi 4 write response channel
  logic [3:0]                                       m_axi_bid;
  logic [1:0]                                       m_axi_bresp;
  logic                                             m_axi_bvalid;
  logic                                             m_axi_bready;
  // axi 4 read address channel
  logic [3:0]                                       m_axi_arid;
  logic [12:0]                                      m_axi_araddr;
  logic [7:0]                                       m_axi_arlen;
  logic [2:0]                                       m_axi_arsize;
  logic [1:0]                                       m_axi_arburst;
  logic [3:0]                                       m_axi_arcache;
  logic                                             m_axi_arvalid;
  logic                                             m_axi_arready;
 // axi 4 read data channel
  logic [3:0]                                       m_axi_rid;
  logic [31:0]                                      m_axi_rdata;
  logic [1:0]                                       m_axi_rresp;
  logic                                             m_axi_rlast;
  logic                                             m_axi_rvalid;
  logic                                             m_axi_rready;

  logic [3:0]                                       mii_txd;
  logic                                             mii_tx_en, mii_tx_er;
  
  logic                                             tx_error_underflow, tx_fifo_overflow, tx_fifo_bad_frame, tx_fifo_good_frame, rx_error_bad_frame;
  logic                                             rx_error_bad_fcs, rx_fifo_overflow, rx_fifo_bad_frame, rx_fifo_good_frame;
  
  

  packetizer #(P, MAX_CSRS) packetizer(.rvvi, .valid, .m_axi_aclk(clk), .m_axi_aresetn(~reset), .RVVIStall,
    .m_axi_awid, .m_axi_awaddr, .m_axi_awlen, .m_axi_awsize, .m_axi_awburst, .m_axi_awcache, .m_axi_awvalid,
    .m_axi_awready, .m_axi_wdata, .m_axi_wstrb, .m_axi_wlast, .m_axi_wvalid, .m_axi_wready, .m_axi_bid,
    .m_axi_bresp, .m_axi_bvalid, .m_axi_bready, .m_axi_arid, .m_axi_araddr, .m_axi_arlen, .m_axi_arsize,
    .m_axi_arburst, .m_axi_arcache, .m_axi_arvalid, .m_axi_arready, .m_axi_rid, .m_axi_rdata, .m_axi_rresp,
    .m_axi_rlast, .m_axi_rvalid, .m_axi_rready);

  eth_mac_mii_fifo #("GENERIC", "BUFG", 32) ethernet(.rst(reset), .logic_clk(clk), .logic_rst(reset),
    .tx_axis_tdata(m_axi_wdata), .tx_axis_tkeep(m_axi_wstrb), .tx_axis_tvalid(m_axi_wvalid), .tx_axis_tready(m_axi_wready),
    .tx_axis_tlast(m_axi_wlast), .tx_axis_tuser('0), .rx_axis_tdata(), .rx_axis_tkeep(), .rx_axis_tvalid(), .rx_axis_tready(1'b1),
    .rx_axis_tlast(), .rx_axis_tuser(),

    // *** update these
    .mii_rx_clk(clk), // *** need to be the mii clock
    .mii_rxd('0),
    .mii_rx_dv('0),
    .mii_rx_er('0),
    .mii_tx_clk(clk), // *** needs to be the mii clock
    .mii_txd,
    .mii_tx_en,
    .mii_tx_er,

    // status
    .tx_error_underflow, .tx_fifo_overflow, .tx_fifo_bad_frame, .tx_fifo_good_frame, .rx_error_bad_frame,
    .rx_error_bad_fcs, .rx_fifo_overflow, .rx_fifo_bad_frame, .rx_fifo_good_frame, 
    .cfg_ifg(8'd12), .cfg_tx_enable(1'b1), .cfg_rx_enable(1'b1)
    );
  


  // *** finally fake the axi4 interface
  assign m_axi_awready = '1;
  //assign m_axi_wready = '1;
  
endmodule
