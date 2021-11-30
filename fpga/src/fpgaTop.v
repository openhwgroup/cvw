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

`include "wally-config.vh"

module fpgaTop 
  (input        default_250mhz_clk1_0_n,
   input 	   default_250mhz_clk1_0_p, 
   input 	   reset,
   input 	   south_rst,

   input [3:0] 	   GPI,
   output [4:0]    GPO,

   input 	   UARTSin,
   output 	   UARTSout,

   input [3:0] 	   SDCDat,
   output 	   SDCCLK,
   inout 	   SDCCmd,

   output 	   calib,
   output 	   cpu_reset,
   output 	   ddr4_sdram_c1_062,
   output 	   ahblite_resetn,

   output [16 : 0] c0_ddr4_adr,
   output [1 : 0]  c0_ddr4_ba,
   output [0 : 0]  c0_ddr4_cke,
   output [0 : 0]  c0_ddr4_cs_n,
   inout [7 : 0]  c0_ddr4_dm_dbi_n,
   inout [63 : 0] c0_ddr4_dq,
   inout [7 : 0]  c0_ddr4_dqs_c,
   inout [7 : 0]  c0_ddr4_dqs_t,
   output [0 : 0]  c0_ddr4_odt,
   output [0 : 0]  c0_ddr4_bg,
   output 	   c0_ddr4_reset_n,
   output 	   c0_ddr4_act_n,
   output [0 : 0]  c0_ddr4_ck_c,
   output [0 : 0]  c0_ddr4_ck_t
);

  wire 		CPUCLK;
  wire 		c0_ddr4_ui_clk_sync_rst;
  wire 		bus_struct_reset;
  wire 		peripheral_reset;
  wire 		interconnect_aresetn;
  wire 		peripheral_aresetn;

  wire [`AHBW-1:0] HRDATAEXT;
  wire 		   HREADYEXT;
  wire 		   HRESPEXT;
  wire 		   HSELEXT;
  wire 		   HCLKOpen;
  wire 		   HRESETnOpen;
  wire [31:0] 	   HADDR;
  wire [`AHBW-1:0] HWDATA;
  wire 		   HWRITE;
  wire [2:0] 	   HSIZE;
  wire [2:0] 	   HBURST;
  wire [3:0] 	   HPROT;
  wire [1:0] 	   HTRANS;
  wire 		   HMASTLOCK;
  wire 		   HREADY;
  
  

  wire [31:0] 	   GPIOPinsIn, GPIOPinsOut, GPIOPinsEn;

  wire 		   SDCCmdIn;
  wire 		   SDCCmdOE;
  wire 		   SDCCmdOut;

  wire [3:0] 	   m_axi_awid;
  wire [7:0] 	   m_axi_awlen;
  wire [2:0] 	   m_axi_awsize;
  wire [1:0] 	   m_axi_awburst;
  wire [3:0] 	   m_axi_awcache;
  wire [31:0] 	   m_axi_awaddr;
  wire [2:0] 	   m_axi_awprot;
  wire 		   m_axi_awvalid;
  wire 		   m_axi_awready;
  wire 		   m_axi_awlock;
  wire [63:0] 	   m_axi_wdata;
  wire [7:0] 	   m_axi_wstrb;
  wire 		   m_axi_wlast;
  wire 		   m_axi_wvalid;
  wire 		   m_axi_wready;
  wire [3:0] 	   m_axi_bid;
  wire [1:0] 	   m_axi_bresp;
  wire 		   m_axi_bvalid;
  wire 		   m_axi_bready;
  wire [3:0] 	   m_axi_arid;
  wire [7:0] 	   m_axi_arlen;
  wire [2:0] 	   m_axi_arsize;
  wire [1:0] 	   m_axi_arburst;
  wire [2:0] 	   m_axi_arprot;
  wire [3:0] 	   m_axi_arcache;
  wire 		   m_axi_arvalid;
  wire [31:0] 	   m_axi_araddr;
  wire 		   m_axi_arlock;
  wire 		   m_axi_arready;
  wire [3:0] 	   m_axi_rid;
  wire [63:0] 	   m_axi_rdata;
  wire [1:0] 	   m_axi_rresp;
  wire 		   m_axi_rvalid;
  wire 		   m_axi_rlast;
  wire 		   m_axi_rready;

  wire [3:0] 	   BUS_axi_awid;
  wire [7:0] 	   BUS_axi_awlen;
  wire [2:0] 	   BUS_axi_awsize;
  wire [1:0] 	   BUS_axi_awburst;
  wire [3:0] 	   BUS_axi_awcache;
  wire [31:0] 	   BUS_axi_awaddr;
  wire [2:0] 	   BUS_axi_awprot;
  wire 		   BUS_axi_awvalid;
  wire 		   BUS_axi_awready;
  wire 		   BUS_axi_awlock;
  wire [63:0] 	   BUS_axi_wdata;
  wire [7:0] 	   BUS_axi_wstrb;
  wire 		   BUS_axi_wlast;
  wire 		   BUS_axi_wvalid;
  wire 		   BUS_axi_wready;
  wire [3:0] 	   BUS_axi_bid;
  wire [1:0] 	   BUS_axi_bresp;
  wire 		   BUS_axi_bvalid;
  wire 		   BUS_axi_bready;
  wire [3:0] 	   BUS_axi_arid;
  wire [7:0] 	   BUS_axi_arlen;
  wire [2:0] 	   BUS_axi_arsize;
  wire [1:0] 	   BUS_axi_arburst;
  wire [2:0] 	   BUS_axi_arprot;
  wire [3:0] 	   BUS_axi_arcache;
  wire 		   BUS_axi_arvalid;
  wire [31:0] 	   BUS_axi_araddr;
  wire 		   BUS_axi_arlock;
  wire 		   BUS_axi_arready;
  wire [3:0] 	   BUS_axi_rid;
  wire [63:0] 	   BUS_axi_rdata;
  wire [1:0] 	   BUS_axi_rresp;
  wire 		   BUS_axi_rvalid;
  wire 		   BUS_axi_rlast;
  wire 		   BUS_axi_rready;
  
  wire 		   BUSCLK;
  

  wire 		   c0_init_calib_complete;
  wire 		   dbg_clk;
  wire [511 : 0]   dbg_bus;

  wire 		   CLK208;
  

  

  assign GPIOPinsIn = {28'b0, GPI};
  assign GPO = GPIOPinsOut[4:0];
  assign ahblite_resetn = peripheral_aresetn;
  assign cpu_reset = bus_struct_reset;
  assign calib = c0_init_calib_complete;
  
  
  // SD Card Tristate
  IOBUF iobufSDCMD(.T(~SDCCmdOE), // iobuf's T is active low
		   .I(SDCCmdIn),
		   .O(SDCCmdOut),
		   .IO(SDCmd));

  // reset controller XILINX IP
  wrapper_proc_sys_reset_0_0 wrapper_proc_sys_reset_0_0
    (.slowest_sync_clk(CPUCLK),
     .ext_reset_in(c0_ddr4_ui_clk_sync_rst),
     .aux_reset_in(south_rst),
     .mb_debug_sys_rst(1'b0),
     .dcm_locked(c0_init_calib_complete),
     //.mb_reset,  //open
     .bus_struct_reset(bus_struct_reset),
     .peripheral_reset(peripheral_reset), //open
     .interconnect_aresetn(interconnect_aresetn), //open
     .peripheral_aresetn(peripheral_aresetn));
  

  // wally
  wallypipelinedsoc wallypipelinedsoc
    (.clk(CPUCLK),
     .reset(bus_struct_reset),
     // bus interface
     .HRDATAEXT(HRDATAEXT),
     .HREADYEXT(HREADYEXT),
     .HRESPEXT(HRESPEXT),
     .HSELEXT(HSELEXT),
     .HCLK(HCLKOpen), // open
     .HRESETn(HRESETnOpen), // open
     .HADDR(HADDR),
     .HWDATA(HWDATA),
     .HWRITE(HWRITE),
     .HSIZE(HSIZE),
     .HBURST(HBURST),
     .HPROT(HPROT),
     .HTRANS(HTRANS),
     .HMASTLOCK(HMASTLOCK),
     .HREADY(HREADY),
     // GPIO
     .GPIOPinsIn(GPIOPinsIn),
     .GPIOPinsOut(GPIOPinsOut),
     .GPIOPinsEn(GPIOPinsEn),
     // UART
     .UARTSin(UARTSin),
     .UARTSout(UARTSout),  
     // SD Card   
     .SDCDatIn(SDCDat),
     .SDCCmdIn(SDCCmdIn),     
     .SDCCmdOut(SDCCmdOut),
     .SDCCmdOE(SDCCmdOE),
     
     );

  // ahb lite to axi bridge
  xlnx_ahblite_axi_bridge xlnx_ahblite_axi_bridge_0
    (.s_ahb_hclk(CPUCLK),
     .s_ahb_hresetn(peripheral_aresetn)
     .s_ahb_hsel(HSELEXT),
     .s_ahb_haddr(HADDR),
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

  xlnx_axi_clock_converter xlnx_axi_clock_converter_0
    (.s_axi_aclk(CPUCLK),
     .s_axi_aresetn(peripheral_aresetn),
     .s_axi_awid(m_axi_awid),
     .s_axi_awlen(m_axi_awlen),
     .s_axi_awsize(m_axi_awsize),
     .s_axi_awburst(m_axi_awburst),
     .s_axi_awcache(m_axi_awcache),
     .s_axi_awaddr(m_axi_awaddr),
     .s_axi_awprot(m_axi_awprot),
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
     .s_axi_arcache(m_axi_arcache),
     .s_axi_arvalid(m_axi_arvalid),
     .s_axi_araddr(m_axi_araddr),
     .s_axi_arlock(m_axi_arlock),
     .s_axi_arready(m_axi_arready),
     .s_axi_rid(m_axi_rid),
     .s_axi_rdata(m_axi_rdata),
     .s_axi_rresp(m_axi_rresp),
     .s_axi_rvalid(m_axi_rvalid),
     .s_axi_rlast(m_axi_rlast),
     .s_axi_rready(m_axi_rready),

     .m_axi_aclk(BUSCLK),
     .m_axi_aresetn(~reset),
     .m_axi_awid(BUS_axi_awid),
     .m_axi_awlen(BUS_axi_awlen),
     .m_axi_awsize(BUS_axi_awsize),
     .m_axi_awburst(BUS_axi_awburst),
     .m_axi_awcache(BUS_axi_awcache),
     .m_axi_awaddr(BUS_axi_awaddr),
     .m_axi_awprot(BUS_axi_awprot),
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

  xlnx_ddr4 xlnx_ddr4_c0
    (.c0_init_calib_complete(c0_init_calib_complete),
     .dbg_clk(dbg_clk), // open
     .c0_sys_clk_p(default_250mhz_clk1_0_p),
     .c0_sys_clk_n(default_250mhz_clk1_0_n),
     .sys_rst(reset),
     .dbg_bus(dbg_bus), // open

     // ddr4 I/O
     .c0_ddr4_adr(c0_ddr4_adr),
     .c0_ddr4_ba(c0_ddr4_ba),
     .c0_ddr4_cke(c0_ddr4_cke),
     .c0_ddr4_cs_n(c0_ddr4_cs_n),
     .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),
     .c0_ddr4_dq(c0_ddr4_dq),
     .c0_ddr4_dqs_c(c0_ddr4_dqs_c),
     .c0_ddr4_dqs_t(c0_ddr4_dqs_t),
     .c0_ddr4_odt(c0_ddr4_odt),
     .c0_ddr4_bg(c0_ddr4_bg),
     .c0_ddr4_reset_n(c0_ddr4_reset_n),
     .c0_ddr4_act_n(c0_ddr4_act_n),
     .c0_ddr4_ck_c(c0_ddr4_ck_c),
     .c0_ddr4_ck_t(c0_ddr4_ck_t),
     .c0_ddr4_ui_clk(BUSCLK),
     .c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst),
     .c0_ddr4_aresetn(~reset),

     // axi
     .c0_ddr4_s_axi_awid(BUS_axi_awid),
     .c0_ddr4_s_axi_awaddr(BUS_axi_awaddr),
     .c0_ddr4_s_axi_awlen(BUS_axi_awlen),
     .c0_ddr4_s_axi_awsize(BUS_axi_awsize),
     .c0_ddr4_s_axi_awburst(BUS_axi_awburst),
     .c0_ddr4_s_axi_awlock(BUS_axi_awlock),
     .c0_ddr4_s_axi_awcache(BUS_axi_awcache),
     .c0_ddr4_s_axi_awprot(BUS_axi_awprot),
     .c0_ddr4_s_axi_awqos(BUS_axi_awqos),
     .c0_ddr4_s_axi_awvalid(BUS_axi_awvalid),
     .c0_ddr4_s_axi_awready(BUS_axi_awready),
     .c0_ddr4_s_axi_wdata(BUS_axi_wdata),
     .c0_ddr4_s_axi_wstrb(BUS_axi_wstrb),
     .c0_ddr4_s_axi_wlast(BUS_axi_wlast),
     .c0_ddr4_s_axi_wvalid(BUS_axi_wvalid),
     .c0_ddr4_s_axi_wready(BUS_axi_wready),
     .c0_ddr4_s_axi_bready(BUS_axi_bready),
     .c0_ddr4_s_axi_bid(BUS_axi_bid),
     .c0_ddr4_s_axi_bresp(BUS_axi_bresp),
     .c0_ddr4_s_axi_bvalid(BUS_axi_bvalid),
     .c0_ddr4_s_axi_arid(BUS_axi_arid),
     .c0_ddr4_s_axi_araddr(BUS_axi_araddr),
     .c0_ddr4_s_axi_arlen(BUS_axi_arlen),
     .c0_ddr4_s_axi_arsize(BUS_axi_arsize),
     .c0_ddr4_s_axi_arburst(BUS_axi_arburst),
     .c0_ddr4_s_axi_arlock(BUS_axi_arlock),
     .c0_ddr4_s_axi_arcache(BUS_axi_arcache),
     .c0_ddr4_s_axi_arprot(BUS_axi_arprot),
     .c0_ddr4_s_axi_arqos(BUS_axi_arqos),
     .c0_ddr4_s_axi_arvalid(BUS_axi_arvalid),
     .c0_ddr4_s_axi_arready(BUS_axi_arready),
     .c0_ddr4_s_axi_rready(BUS_axi_rready),
     .c0_ddr4_s_axi_rlast(BUS_axi_rlast),
     .c0_ddr4_s_axi_rvalid(BUS_axi_rvalid),
     .c0_ddr4_s_axi_rresp(BUS_axi_rresp),
     .c0_ddr4_s_axi_rid(BUS_axi_rid),
     .c0_ddr4_s_axi_rdata(BUS_axi_rdata),

     .addn_ui_clkout1(CPUCLK),
     .addn_ui_clkout2(CLK208));
  

  

endmodule

