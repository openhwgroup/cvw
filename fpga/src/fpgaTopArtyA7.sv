///////////////////////////////////////////
// fpgaTop.sv
//
// Written: ross1728@gmail.com November 17, 2021
// Modified: 
//
// Purpose: This is a top level for the fpga's implementation of wally.
//          Instantiates wallysoc, ddr4, abh lite to axi converters, pll, etc
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

`include "config.vh"

import cvw::*;

module fpgaTop 
  (input         default_100mhz_clk,
   input         resetn,
   input         south_reset,

   // GPIO signals
   input [3:0]   GPI,
   output [4:0]  GPO,

   // UART Signals
   input         UARTSin,
   output        UARTSout,

   // SDC Signals connecting to an SPI peripheral
   input [3:0]   SDCDat,
   output        SDCCLK,
   output        SDCCmd,
   output        SDCCD,

   // Memory signals
   inout [15:0]  ddr3_dq,
   inout [1:0]   ddr3_dqs_n,
   inout [1:0]   ddr3_dqs_p,
   output [13:0] ddr3_addr,
   output [2:0]  ddr3_ba,
   output        ddr3_ras_n,
   output        ddr3_cas_n,
   output        ddr3_we_n,
   output        ddr3_reset_n,
   output [0:0]  ddr3_ck_p,
   output [0:0]  ddr3_ck_n,
   output [0:0]  ddr3_cke,
   output [0:0]  ddr3_cs_n,
   output [1:0]  ddr3_dm,
   output [0:0]  ddr3_odt
   );

  // MMCM Signals
  wire 			   CPUCLK;
  wire 			   c0_ddr4_ui_clk_sync_rst;
  wire 			   bus_struct_reset;
  wire 			   peripheral_reset;
  wire 			   interconnect_aresetn;
  wire 			   peripheral_aresetn;
  wire 			   mb_reset;
  
  // AHB Signals from Wally
  wire 			   HCLKOpen;
  wire 			   HRESETnOpen;
  wire [63:0]      HRDATAEXT;
  wire 			   HREADYEXT;
  wire 			   HRESPEXT;
  wire 			   HSELEXT;
  wire [55:0] 	   HADDR;
  wire [63:0]      HWDATA;
  wire [64/8-1:0]  HWSTRB;
  wire 			   HWRITE;
  wire [2:0] 	   HSIZE;
  wire [2:0] 	   HBURST;
  wire [1:0] 	   HTRANS;
  wire 			   HREADY;
  wire [3:0] 	   HPROT;
  wire 			   HMASTLOCK;

  // GPIO Signals
  wire [31:0] 	   GPIOIN, GPIOOUT, GPIOEN;

  // AHB to AXI Bridge Signals
  wire [3:0] 	   m_axi_awid;
  wire [7:0] 	   m_axi_awlen;
  wire [2:0] 	   m_axi_awsize;
  wire [1:0] 	   m_axi_awburst;
  wire [3:0] 	   m_axi_awcache;
  wire [31:0] 	   m_axi_awaddr;
  wire [2:0] 	   m_axi_awprot;
  wire             m_axi_awvalid;
  wire             m_axi_awready;
  wire             m_axi_awlock;
  wire [63:0] 	   m_axi_wdata;
  wire [7:0] 	   m_axi_wstrb;
  wire             m_axi_wlast;
  wire             m_axi_wvalid;
  wire             m_axi_wready;
  wire [3:0] 	   m_axi_bid;
  wire [1:0] 	   m_axi_bresp;
  wire             m_axi_bvalid;
  wire             m_axi_bready;
  wire [3:0] 	   m_axi_arid;
  wire [7:0] 	   m_axi_arlen;
  wire [2:0] 	   m_axi_arsize;
  wire [1:0] 	   m_axi_arburst;
  wire [2:0] 	   m_axi_arprot;
  wire [3:0] 	   m_axi_arcache;
  wire             m_axi_arvalid;
  wire [31:0] 	   m_axi_araddr;
  wire 			   m_axi_arlock;
  wire             m_axi_arready;
  wire [3:0] 	   m_axi_rid;
  wire [63:0] 	   m_axi_rdata;
  wire [1:0] 	   m_axi_rresp;
  wire             m_axi_rvalid;
  wire             m_axi_rlast;
  wire             m_axi_rready;

  // AXI Signals going out of Clock Converter
  wire [3:0] 	   BUS_axi_arregion;
  wire [3:0] 	   BUS_axi_arqos;
  wire [3:0] 	   BUS_axi_awregion;
  wire [3:0] 	   BUS_axi_awqos;
  wire [3:0] 	   BUS_axi_awid;
  wire [7:0] 	   BUS_axi_awlen;
  wire [2:0] 	   BUS_axi_awsize;
  wire [1:0] 	   BUS_axi_awburst;
  wire [3:0] 	   BUS_axi_awcache;
  wire [31:0] 	   BUS_axi_awaddr;
  wire [2:0] 	   BUS_axi_awprot;
  wire 			   BUS_axi_awvalid;
  wire 			   BUS_axi_awready;
  wire 			   BUS_axi_awlock;
  wire [63:0] 	   BUS_axi_wdata;
  wire [7:0] 	   BUS_axi_wstrb;
  wire 			   BUS_axi_wlast;
  wire 			   BUS_axi_wvalid;
  wire 			   BUS_axi_wready;
  wire [3:0] 	   BUS_axi_bid;
  wire [1:0] 	   BUS_axi_bresp;
  wire 			   BUS_axi_bvalid;
  wire 			   BUS_axi_bready;
  wire [3:0] 	   BUS_axi_arid;
  wire [7:0] 	   BUS_axi_arlen;
  wire [2:0] 	   BUS_axi_arsize;
  wire [1:0] 	   BUS_axi_arburst;
  wire [2:0] 	   BUS_axi_arprot;
  wire [3:0] 	   BUS_axi_arcache;
  wire 			   BUS_axi_arvalid;
  wire [31:0] 	   BUS_axi_araddr;
  wire 			   BUS_axi_arlock;
  wire 			   BUS_axi_arready;
  wire [3:0] 	   BUS_axi_rid;
  wire [63:0] 	   BUS_axi_rdata;
  wire [1:0] 	   BUS_axi_rresp;
  wire 			   BUS_axi_rvalid;
  wire 			   BUS_axi_rlast;
  wire 			   BUS_axi_rready;
  
  wire 			   BUSCLK;
  wire             sdio_reset_open;
  
  wire             c0_init_calib_complete;
  wire 			   dbg_clk;
  wire [511 : 0]   dbg_bus;
  wire             ui_clk_sync_rst;
  
  wire 			   CLK208;
  wire             clk167;
  wire             clk200;

  wire             app_sr_active;
  wire             app_ref_ack;
  wire             app_zq_ack;
  wire             mmcm_locked;
  wire [11:0]      device_temp;
  wire             mmcm1_locked;
  

  assign GPIOIN = {28'b0, GPI};
  assign GPO = GPIOOUT[4:0];
  assign ahblite_resetn = peripheral_aresetn;
  assign cpu_reset = bus_struct_reset;
  assign calib = c0_init_calib_complete;

  logic [3:0] SDCCS;
  assign SDCCD = SDCCS[0];
  logic SDCIn;
  assign SDCIn = SDCDat[0];

  // mmcm

  // the ddr3 mig7 requires 2 input clocks 
  // 1. sys clock which is 167 MHz = ddr3 clock / 4
  // 2. a second clock which is 200 MHz
  // Wally requires a slower clock.  At this point I don't know what speed the atrix 7 will run so I'm initially targetting 25Mhz.
  // the mig will output a clock at 1/4 the sys clock or 41Mhz which might work with wally so we may be able to simplify the logic a lot.
  xlnx_mmcm xln_mmcm(.clk_out1(clk167),
                     .clk_out2(clk200),
                     .clk_out3(CPUCLK),
                     .reset(1'b0),
                     .locked(mmcm1_locked),
                     .clk_in1(default_100mhz_clk));

  

  // reset controller XILINX IP
  xlnx_proc_sys_reset xlnx_proc_sys_reset_0
    (.slowest_sync_clk(CPUCLK),
     .ext_reset_in(1'b0),
     .aux_reset_in(south_reset),
     .mb_debug_sys_rst(1'b0),
     .dcm_locked(c0_init_calib_complete),
     .mb_reset(mb_reset),  //open
     .bus_struct_reset(bus_struct_reset),
     .peripheral_reset(peripheral_reset), //open
     .interconnect_aresetn(interconnect_aresetn), //open
     .peripheral_aresetn(peripheral_aresetn));

  `include "parameter-defs.vh"
  
  // Wally 
  wallypipelinedsoc  #(P) 
  wallypipelinedsoc(.clk(CPUCLK), .reset_ext(bus_struct_reset), .reset(), 
                    .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HSELEXT,
                    .HCLK(HCLKOpen), .HRESETn(HRESETnOpen), 
                    .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
                    .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), 
                    .GPIOIN, .GPIOOUT, .GPIOEN,
                    .UARTSin, .UARTSout, .SDCIn, .SDCCmd, .SDCCS, .SDCCLK); 


  // ahb lite to axi bridge
  xlnx_ahblite_axi_bridge xlnx_ahblite_axi_bridge_0
    (.s_ahb_hclk(CPUCLK),
     .s_ahb_hresetn(peripheral_aresetn),
     .s_ahb_hsel(HSELEXT | HSELEXTSDC),
     .s_ahb_haddr(HADDR[31:0]),
     .s_ahb_hprot(HPROT),
     .s_ahb_htrans(HTRANS),
     .s_ahb_hsize(HSIZE),
     .s_ahb_hwrite(HWRITE),
     .s_ahb_hburst(HBURST),
     .s_ahb_hwdata(HWDATA),
     .s_ahb_hready_out(HREADYEXT),
     .s_ahb_hready_in(HREADY),
     .s_ahb_hrdata(HRDATAEXT),
     .s_ahb_hresp(HRESPEXT),
     .m_axi_awid(m_axi_awid),
     .m_axi_awlen(m_axi_awlen),
     .m_axi_awsize(m_axi_awsize),
     .m_axi_awburst(m_axi_awburst),
     .m_axi_awcache(m_axi_awcache),
     .m_axi_awaddr(m_axi_awaddr),
     .m_axi_awprot(m_axi_awprot),
     .m_axi_awvalid(m_axi_awvalid),
     .m_axi_awready(m_axi_awready),
     .m_axi_awlock(m_axi_awlock),
     .m_axi_wdata(m_axi_wdata),
     .m_axi_wstrb(m_axi_wstrb),
     .m_axi_wlast(m_axi_wlast),
     .m_axi_wvalid(m_axi_wvalid),
     .m_axi_wready(m_axi_wready),
     .m_axi_bid(m_axi_bid),
     .m_axi_bresp(m_axi_bresp),
     .m_axi_bvalid(m_axi_bvalid),
     .m_axi_bready(m_axi_bready),
     .m_axi_arid(m_axi_arid),
     .m_axi_arlen(m_axi_arlen),
     .m_axi_arsize(m_axi_arsize),
     .m_axi_arburst(m_axi_arburst),
     .m_axi_arprot(m_axi_arprot),
     .m_axi_arcache(m_axi_arcache),
     .m_axi_arvalid(m_axi_arvalid),
     .m_axi_araddr(m_axi_araddr),
     .m_axi_arlock(m_axi_arlock),
     .m_axi_arready(m_axi_arready),
     .m_axi_rid(m_axi_rid),
     .m_axi_rdata(m_axi_rdata),
     .m_axi_rresp(m_axi_rresp),
     .m_axi_rvalid(m_axi_rvalid),
     .m_axi_rlast(m_axi_rlast),
     .m_axi_rready(m_axi_rready));

  // AXI Clock Converter
  xlnx_axi_clock_converter xlnx_axi_clock_converter_0
    (.s_axi_aclk(CPUCLK),
     .s_axi_aresetn(peripheral_aresetn),
     .s_axi_awid(m_axi_awid),
     .s_axi_awlen(m_axi_awlen),
     .s_axi_awsize(m_axi_awsize),
     .s_axi_awburst(m_axi_awburst),
     .s_axi_awcache(m_axi_awcache),
     .s_axi_awaddr(m_axi_awaddr[30:0] ),
     .s_axi_awprot(m_axi_awprot),
     .s_axi_awregion(4'b0), // this could be a bug. bridge does not have these outputs
     .s_axi_awqos(4'b0),    // this could be a bug. bridge does not have these outputs
     .s_axi_awvalid(m_axi_awvalid),
     .s_axi_awready(m_axi_awready),
     .s_axi_awlock(m_axi_awlock),
     .s_axi_wdata(m_axi_wdata),
     .s_axi_wstrb(m_axi_wstrb),
     .s_axi_wlast(m_axi_wlast),
     .s_axi_wvalid(m_axi_wvalid),
     .s_axi_wready(m_axi_wready),
     .s_axi_bid(m_axi_bid),
     .s_axi_bresp(m_axi_bresp),
     .s_axi_bvalid(m_axi_bvalid),
     .s_axi_bready(m_axi_bready),
     .s_axi_arid(m_axi_arid),
     .s_axi_arlen(m_axi_arlen),
     .s_axi_arsize(m_axi_arsize),
     .s_axi_arburst(m_axi_arburst),
     .s_axi_arprot(m_axi_arprot),
     .s_axi_arregion(4'b0), // this could be a bug. bridge does not have these outputs
     .s_axi_arqos(4'b0),    // this could be a bug. bridge does not have these outputs
     .s_axi_arcache(m_axi_arcache),
     .s_axi_arvalid(m_axi_arvalid),
     .s_axi_araddr(m_axi_araddr[30:0]),
     .s_axi_arlock(m_axi_arlock),
     .s_axi_arready(m_axi_arready),
     .s_axi_rid(m_axi_rid),
     .s_axi_rdata(m_axi_rdata),
     .s_axi_rresp(m_axi_rresp),
     .s_axi_rvalid(m_axi_rvalid),
     .s_axi_rlast(m_axi_rlast),
     .s_axi_rready(m_axi_rready),

     .m_axi_aclk(BUSCLK),
     .m_axi_aresetn(resetn),
     .m_axi_awid(BUS_axi_awid),
     .m_axi_awlen(BUS_axi_awlen),
     .m_axi_awsize(BUS_axi_awsize),
     .m_axi_awburst(BUS_axi_awburst),
     .m_axi_awcache(BUS_axi_awcache),
     .m_axi_awaddr(BUS_axi_awaddr),
     .m_axi_awprot(BUS_axi_awprot),
     .m_axi_awregion(BUS_axi_awregion),
     .m_axi_awqos(BUS_axi_awqos),
     .m_axi_awvalid(BUS_axi_awvalid),
     .m_axi_awready(BUS_axi_awready),
     .m_axi_awlock(BUS_axi_awlock),
     .m_axi_wdata(BUS_axi_wdata),
     .m_axi_wstrb(BUS_axi_wstrb),
     .m_axi_wlast(BUS_axi_wlast),
     .m_axi_wvalid(BUS_axi_wvalid),
     .m_axi_wready(BUS_axi_wready),
     .m_axi_bid(BUS_axi_bid),
     .m_axi_bresp(BUS_axi_bresp),
     .m_axi_bvalid(BUS_axi_bvalid),
     .m_axi_bready(BUS_axi_bready),
     .m_axi_arid(BUS_axi_arid),
     .m_axi_arlen(BUS_axi_arlen),
     .m_axi_arsize(BUS_axi_arsize),
     .m_axi_arburst(BUS_axi_arburst),
     .m_axi_arprot(BUS_axi_arprot),
     .m_axi_arregion(BUS_axi_arregion),
     .m_axi_arqos(BUS_axi_arqos),
     .m_axi_arcache(BUS_axi_arcache),
     .m_axi_arvalid(BUS_axi_arvalid),
     .m_axi_araddr(BUS_axi_araddr),
     .m_axi_arlock(BUS_axi_arlock),
     .m_axi_arready(BUS_axi_arready),
     .m_axi_rid(BUS_axi_rid),
     .m_axi_rdata(BUS_axi_rdata),
     .m_axi_rresp(BUS_axi_rresp),
     .m_axi_rvalid(BUS_axi_rvalid),
     .m_axi_rlast(BUS_axi_rlast),
     .m_axi_rready(BUS_axi_rready));

  // DDR3 Controller
  xlnx_ddr3 xlnx_ddr3_c0
    (
     // ddr3 I/O
     .ddr3_dq(ddr3_dq),
     .ddr3_dqs_n(ddr3_dqs_n),
     .ddr3_dqs_p(ddr3_dqs_p),
     .ddr3_addr(ddr3_addr),
     .ddr3_ba(ddr3_ba),
     .ddr3_ras_n(ddr3_ras_n),
     .ddr3_cas_n(ddr3_cas_n),
     .ddr3_we_n(ddr3_we_n),
     .ddr3_reset_n(ddr3_reset_n),
     .ddr3_ck_p(ddr3_ck_p),
     .ddr3_ck_n(ddr3_ck_n),
     .ddr3_cke(ddr3_cke),
     .ddr3_cs_n(ddr3_cs_n),
     .ddr3_dm(ddr3_dm),
     .ddr3_odt(ddr3_odt),

     .sys_clk_i(clk167),
     .clk_ref_i(clk200),

     .ui_clk(BUSCLK),
     .ui_clk_sync_rst(ui_clk_sync_rst),
     .aresetn(resetn),
     .sys_rst(resetn),    // omg. this is active low?!?!?? 
     .mmcm_locked(mmcm_locked),

     .app_sr_req(1'b0),  // reserved command
     .app_ref_req(1'b0), // refresh command
     .app_zq_req(1'b0),  // recalibrate command
     .app_sr_active(app_sr_active), // reserved response
     .app_ref_ack(app_ref_ack),     // refresh ack
     .app_zq_ack(app_zq_ack),       // recalibrate ack

     // axi
     .s_axi_awid(BUS_axi_awid),
     .s_axi_awaddr(BUS_axi_awaddr[27:0]),
     .s_axi_awlen(BUS_axi_awlen),
     .s_axi_awsize(BUS_axi_awsize),
     .s_axi_awburst(BUS_axi_awburst),
     .s_axi_awlock(BUS_axi_awlock),
     .s_axi_awcache(BUS_axi_awcache),
     .s_axi_awprot(BUS_axi_awprot),
     .s_axi_awqos(BUS_axi_awqos),
     .s_axi_awvalid(BUS_axi_awvalid),
     .s_axi_awready(BUS_axi_awready),
     .s_axi_wdata(BUS_axi_wdata),
     .s_axi_wstrb(BUS_axi_wstrb),
     .s_axi_wlast(BUS_axi_wlast),
     .s_axi_wvalid(BUS_axi_wvalid),
     .s_axi_wready(BUS_axi_wready),
     .s_axi_bready(BUS_axi_bready),
     .s_axi_bid(BUS_axi_bid),
     .s_axi_bresp(BUS_axi_bresp),
     .s_axi_bvalid(BUS_axi_bvalid),
     .s_axi_arid(BUS_axi_arid),
     .s_axi_araddr(BUS_axi_araddr[27:0]),
     .s_axi_arlen(BUS_axi_arlen),
     .s_axi_arsize(BUS_axi_arsize),
     .s_axi_arburst(BUS_axi_arburst),
     .s_axi_arlock(BUS_axi_arlock),
     .s_axi_arcache(BUS_axi_arcache),
     .s_axi_arprot(BUS_axi_arprot),
     .s_axi_arqos(BUS_axi_arqos),
     .s_axi_arvalid(BUS_axi_arvalid),
     .s_axi_arready(BUS_axi_arready),
     .s_axi_rready(BUS_axi_rready),
     .s_axi_rlast(BUS_axi_rlast),
     .s_axi_rvalid(BUS_axi_rvalid),
     .s_axi_rresp(BUS_axi_rresp),
     .s_axi_rid(BUS_axi_rid),
     .s_axi_rdata(BUS_axi_rdata),

     .init_calib_complete(c0_init_calib_complete),
     .device_temp(device_temp));
  

endmodule

