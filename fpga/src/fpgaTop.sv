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
  (input           default_250mhz_clk1_0_n,
   input           default_250mhz_clk1_0_p, 
   input           reset,
   input           south_rst,

   input [3:0]     GPI,
   output [4:0]    GPO,

   input           UARTSin,
   output          UARTSout,

   inout [3:0]     SDCDat,
   output          SDCCLK,
   inout           SDCCmd,
   input           SDCCD,

   output          calib,
   output          cpu_reset,
   output          ahblite_resetn,

   output [16 : 0] c0_ddr4_adr,
   output [1 : 0]  c0_ddr4_ba,
   output [0 : 0]  c0_ddr4_cke,
   output [0 : 0]  c0_ddr4_cs_n,
   inout [7 : 0]   c0_ddr4_dm_dbi_n,
   inout [63 : 0]  c0_ddr4_dq,
   inout [7 : 0]   c0_ddr4_dqs_c,
   inout [7 : 0]   c0_ddr4_dqs_t,
   output [0 : 0]  c0_ddr4_odt,
   output [0 : 0]  c0_ddr4_bg,
   output          c0_ddr4_reset_n,
   output          c0_ddr4_act_n,
   output [0 : 0]  c0_ddr4_ck_c,
   output [0 : 0]  c0_ddr4_ck_t
   );

  wire 			   CPUCLK;
  wire 			   c0_ddr4_ui_clk_sync_rst;
  wire 			   bus_struct_reset;
  wire 			   peripheral_reset;
  wire 			   interconnect_aresetn;
  wire 			   peripheral_aresetn;
  wire 			   mb_reset;
  
  wire 			   HCLKOpen;
  wire 			   HRESETnOpen;
  wire [64-1:0]    HRDATAEXT;
  wire 			   HREADYEXT;
  wire 			   HRESPEXT;
  (* mark_debug = "true" *) wire 			   HSELEXT;
  (* mark_debug = "true" *) wire             HSELEXTSDC; // TEMP BOOT SIGNAL - JACOB
  wire [55:0] 	   HADDR;
  wire [64-1:0]    HWDATA;
  wire [64/8-1:0]  HWSTRB;
  wire 			   HWRITE;
  wire [2:0] 	   HSIZE;
  wire [2:0] 	   HBURST;
  wire [1:0] 	   HTRANS;
  wire 			   HREADY;
  wire [3:0] 	   HPROT;
  wire 			   HMASTLOCK;
  
  

  wire [31:0] 	   GPIOIN, GPIOOUT, GPIOEN;

  // Old SDC connections
  // wire 			   SDCCmdIn;
  // wire 			   SDCCmdOE;
  // wire 			   SDCCmdOut;

 (* mark_debug = "true" *)wire [3:0] 	   m_axi_awid;
 (* mark_debug = "true" *)wire [7:0] 	   m_axi_awlen;
 (* mark_debug = "true" *)wire [2:0] 	   m_axi_awsize;
 (* mark_debug = "true" *)wire [1:0] 	   m_axi_awburst;
 (* mark_debug = "true" *)wire [3:0] 	   m_axi_awcache;
 (* mark_debug = "true" *)wire [31:0] 	   m_axi_awaddr;
 (* mark_debug = "true" *)wire [2:0] 	   m_axi_awprot;
 (* mark_debug = "true" *)wire 		   m_axi_awvalid;
 (* mark_debug = "true" *)wire 		   m_axi_awready;
 (* mark_debug = "true" *)wire 		   m_axi_awlock;
 (* mark_debug = "true" *)wire [63:0] 	   m_axi_wdata;
 (* mark_debug = "true" *)wire [7:0] 	   m_axi_wstrb;
 (* mark_debug = "true" *)wire 		   m_axi_wlast;
 (* mark_debug = "true" *)wire 		   m_axi_wvalid;
 (* mark_debug = "true" *)wire 		   m_axi_wready;
 (* mark_debug = "true" *)wire [3:0] 	   m_axi_bid;
 (* mark_debug = "true" *)wire [1:0] 	   m_axi_bresp;
 (* mark_debug = "true" *)wire 		   m_axi_bvalid;
 (* mark_debug = "true" *)wire 		   m_axi_bready;
 (* mark_debug = "true" *)wire [3:0] 	   m_axi_arid;
 (* mark_debug = "true" *)wire [7:0] 	   m_axi_arlen;
 (* mark_debug = "true" *)wire [2:0] 	   m_axi_arsize;
 (* mark_debug = "true" *)wire [1:0] 	   m_axi_arburst;
 (* mark_debug = "true" *)wire [2:0] 	   m_axi_arprot;
 (* mark_debug = "true" *)wire [3:0] 	   m_axi_arcache;
 (* mark_debug = "true" *)wire 		   m_axi_arvalid;
 (* mark_debug = "true" *)wire [31:0] 	   m_axi_araddr;
 (* mark_debug = "true" *)wire 			   m_axi_arlock;
 (* mark_debug = "true" *)wire 		   m_axi_arready;
 (* mark_debug = "true" *)wire [3:0] 	   m_axi_rid;
 (* mark_debug = "true" *)wire [63:0] 	   m_axi_rdata;
 (* mark_debug = "true" *)wire [1:0] 	   m_axi_rresp;
 (* mark_debug = "true" *)wire 		   m_axi_rvalid;
 (* mark_debug = "true" *)wire 		   m_axi_rlast;
 (* mark_debug = "true" *)wire 		   m_axi_rready;

  // Extra Bus signals
  wire [3:0] 	   BUS_axi_arregion;
  wire [3:0] 	   BUS_axi_arqos;
  wire [3:0] 	   BUS_axi_awregion;
  wire [3:0] 	   BUS_axi_awqos;

  // Bus signals
  wire [3:0] 	   BUS_axi_awid;
  wire [7:0] 	   BUS_axi_awlen;
  wire [2:0] 	   BUS_axi_awsize;
  wire [1:0] 	   BUS_axi_awburst;
  wire [3:0] 	   BUS_axi_awcache;
  wire [30:0] 	   BUS_axi_awaddr;
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
  wire [30:0] 	   BUS_axi_araddr;
  wire 			   BUS_axi_arlock;
  wire 			   BUS_axi_arready;
  wire [3:0] 	   BUS_axi_rid;
  wire [63:0] 	   BUS_axi_rdata;
  wire [1:0] 	   BUS_axi_rresp;
  wire 			   BUS_axi_rvalid;
  wire 			   BUS_axi_rlast;
  wire 			   BUS_axi_rready;

  wire 			   BUSCLK;
  

  wire 			   c0_init_calib_complete;
  wire 			   dbg_clk;
  wire [511 : 0]   dbg_bus;

  wire 			   CLK208;


  // Crossbar to Bus ------------------------------------------------

  (* mark_debug = "true" *)wire s00_axi_aclk;
  (* mark_debug = "true" *)wire s00_axi_aresetn;
  (* mark_debug = "true" *)wire [3:0] s00_axi_awid;
  (* mark_debug = "true" *)wire [31:0]s00_axi_awaddr;
  (* mark_debug = "true" *)wire [7:0]s00_axi_awlen;
  (* mark_debug = "true" *)wire [2:0]s00_axi_awsize;
  (* mark_debug = "true" *)wire [1:0]s00_axi_awburst;
  (* mark_debug = "true" *)wire [0:0]s00_axi_awlock;
  (* mark_debug = "true" *)wire [3:0]s00_axi_awcache;
  (* mark_debug = "true" *)wire [2:0]s00_axi_awprot;
  (* mark_debug = "true" *)wire [3:0]s00_axi_awregion;
  (* mark_debug = "true" *)wire [3:0]s00_axi_awqos;
  (* mark_debug = "true" *) wire s00_axi_awvalid;
  (* mark_debug = "true" *) wire s00_axi_awready;
  (* mark_debug = "true" *)wire [63:0]s00_axi_wdata;
  (* mark_debug = "true" *)wire [7:0]s00_axi_wstrb;
  (* mark_debug = "true" *)wire s00_axi_wlast;
  (* mark_debug = "true" *)wire s00_axi_wvalid;
  (* mark_debug = "true" *)wire s00_axi_wready;
  (* mark_debug = "true" *)wire [1:0]s00_axi_bresp;
  (* mark_debug = "true" *)wire s00_axi_bvalid;
  (* mark_debug = "true" *)wire s00_axi_bready;
  (* mark_debug = "true" *)wire [31:0]s00_axi_araddr;
  (* mark_debug = "true" *)wire [7:0]s00_axi_arlen;
  (* mark_debug = "true" *)wire [2:0]s00_axi_arsize;
  (* mark_debug = "true" *)wire [1:0]s00_axi_arburst;
  (* mark_debug = "true" *)wire [0:0]s00_axi_arlock;
  (* mark_debug = "true" *)wire [3:0]s00_axi_arcache;
  (* mark_debug = "true" *)wire [2:0]s00_axi_arprot;
  (* mark_debug = "true" *)wire [3:0]s00_axi_arregion;
  (* mark_debug = "true" *)wire [3:0]s00_axi_arqos;
  (* mark_debug = "true" *)wire s00_axi_arvalid;
  (* mark_debug = "true" *)wire s00_axi_arready;
  (* mark_debug = "true" *)wire [63:0]s00_axi_rdata;
  (* mark_debug = "true" *)wire [1:0]s00_axi_rresp;
  (* mark_debug = "true" *)wire s00_axi_rlast;
  (* mark_debug = "true" *)wire s00_axi_rvalid;
  (* mark_debug = "true" *)wire s00_axi_rready;

  (* mark_debug = "true" *)wire [3:0] s00_axi_bid;
  (* mark_debug = "true" *)wire [3:0] s00_axi_rid;
   
  // 64to32 dwidth converter input interface-------------------------
  wire s01_axi_aclk;
  wire s01_axi_aresetn;
  wire [3:0]s01_axi_awid;
  wire [31:0]s01_axi_awaddr;
  wire [7:0]s01_axi_awlen;
  wire [2:0]s01_axi_awsize;
  wire [1:0]s01_axi_awburst;
  wire [0:0]s01_axi_awlock;
  wire [3:0]s01_axi_awcache;
  wire [2:0]s01_axi_awprot;
  wire [3:0]s01_axi_awregion;
  wire [3:0]s01_axi_awqos; // qos signals need to be 0 for SDC
  (* mark_debug = "true" *) wire s01_axi_awvalid;
  (* mark_debug = "true" *) wire s01_axi_awready;
  wire [63:0]s01_axi_wdata;
  wire [7:0]s01_axi_wstrb;
  wire s01_axi_wlast;
  wire s01_axi_wvalid;
  wire s01_axi_wready;
  wire [1:0]s01_axi_bresp;
  wire s01_axi_bvalid;
  wire s01_axi_bready;
  wire [31:0]s01_axi_araddr;
  wire [7:0]s01_axi_arlen;
  wire [2:0]s01_axi_arsize;
  wire [1:0]s01_axi_arburst;
  wire [0:0]s01_axi_arlock;
  wire [3:0]s01_axi_arcache;
  wire [2:0]s01_axi_arprot;
  wire [3:0]s01_axi_arregion;
  wire [3:0]s01_axi_arqos; //
  wire s01_axi_arvalid;
  wire s01_axi_arready;
  wire [63:0]s01_axi_rdata;
  wire [1:0]s01_axi_rresp;
  wire s01_axi_rlast;
  wire s01_axi_rvalid;
  wire s01_axi_rready;

  // Output Interface
  wire [31:0]axi4in_axi_awaddr;
  wire [7:0]axi4in_axi_awlen;
  wire [2:0]axi4in_axi_awsize;
  wire [1:0]axi4in_axi_awburst;
  wire [0:0]axi4in_axi_awlock;
  wire [3:0]axi4in_axi_awcache;
  wire [2:0]axi4in_axi_awprot;
  wire [3:0]axi4in_axi_awregion;
  wire [3:0]axi4in_axi_awqos;
  (* mark_debug = "true" *) wire axi4in_axi_awvalid;
  (* mark_debug = "true" *) wire axi4in_axi_awready;
  wire [31:0]axi4in_axi_wdata;
  wire [3:0]axi4in_axi_wstrb;
  wire axi4in_axi_wlast;
  wire axi4in_axi_wvalid;
  wire axi4in_axi_wready;
  wire [1:0]axi4in_axi_bresp;
  wire axi4in_axi_bvalid;
  wire axi4in_axi_bready;
  wire [31:0]axi4in_axi_araddr;
  wire [7:0]axi4in_axi_arlen;
  wire [2:0]axi4in_axi_arsize;
  wire [1:0]axi4in_axi_arburst;
  wire [0:0]axi4in_axi_arlock;
  wire [3:0]axi4in_axi_arcache;
  wire [2:0]axi4in_axi_arprot;
  wire [3:0]axi4in_axi_arregion;
  wire [3:0]axi4in_axi_arqos;
  wire axi4in_axi_arvalid;
  wire axi4in_axi_arready;
  wire [31:0]axi4in_axi_rdata;
  wire [1:0]axi4in_axi_rresp;
  wire axi4in_axi_rlast;
  wire axi4in_axi_rvalid;
  wire axi4in_axi_rready;

  // AXI4 to AXI4-Lite Protocol converter output
  (* mark_debug = "true" *) wire [31:0]SDCin_axi_awaddr;
  (* mark_debug = "true" *) wire [2:0]SDCin_axi_awprot;
  (* mark_debug = "true" *) wire SDCin_axi_awvalid;
  (* mark_debug = "true" *) wire SDCin_axi_awready;
  (* mark_debug = "true" *) wire [31:0]SDCin_axi_wdata;
  (* mark_debug = "true" *) wire [3:0]SDCin_axi_wstrb;
  (* mark_debug = "true" *) wire SDCin_axi_wvalid;
  (* mark_debug = "true" *) wire SDCin_axi_wready;
  (* mark_debug = "true" *) wire [1:0]SDCin_axi_bresp;
  (* mark_debug = "true" *) wire SDCin_axi_bvalid;
  (* mark_debug = "true" *) wire SDCin_axi_bready;
  (* mark_debug = "true" *) wire [31:0]SDCin_axi_araddr;
  (* mark_debug = "true" *) wire [2:0]SDCin_axi_arprot;
  (* mark_debug = "true" *) wire SDCin_axi_arvalid;
  (* mark_debug = "true" *) wire SDCin_axi_arready;
  (* mark_debug = "true" *) wire [31:0]SDCin_axi_rdata;
  (* mark_debug = "true" *) wire [1:0]SDCin_axi_rresp;
  (* mark_debug = "true" *) wire SDCin_axi_rvalid;
  (* mark_debug = "true" *) wire SDCin_axi_rready;
  // ----------------------------------------------------------------

  // 32to64 dwidth converter input interface -----------------------
  (* mark_debug = "true" *) wire [31:0]SDCout_axi_awaddr;
  (* mark_debug = "true" *) wire [7:0]SDCout_axi_awlen;
  wire [2:0]SDCout_axi_awsize;
  wire [1:0]SDCout_axi_awburst;
  wire [0:0]SDCout_axi_awlock;
  wire [3:0]SDCout_axi_awcache;
  wire [2:0]SDCout_axi_awprot;
  wire [3:0]SDCout_axi_awregion;
  wire [3:0]SDCout_axi_awqos;
  (* mark_debug = "true" *) wire SDCout_axi_awvalid;
  (* mark_debug = "true" *) wire SDCout_axi_awready;
  (* mark_debug = "true" *) wire [31:0]SDCout_axi_wdata;
  wire [3:0]SDCout_axi_wstrb;
  (* mark_debug = "true" *) wire SDCout_axi_wlast;
  (* mark_debug = "true" *) wire SDCout_axi_wvalid;
  (* mark_debug = "true" *)wire SDCout_axi_wready;
  (* mark_debug = "true" *) wire [1:0]SDCout_axi_bresp;
  (* mark_debug = "true" *) wire SDCout_axi_bvalid;
  (* mark_debug = "true" *) wire SDCout_axi_bready;
  wire [31:0]SDCout_axi_araddr;
  wire [7:0]SDCout_axi_arlen;
  wire [2:0]SDCout_axi_arsize;
  wire [1:0]SDCout_axi_arburst;
  wire [0:0]SDCout_axi_arlock;
  wire [3:0]SDCout_axi_arcache;
  wire [2:0]SDCout_axi_arprot;
  wire [3:0]SDCout_axi_arregion;
  wire [3:0]SDCout_axi_arqos;
  wire SDCout_axi_arvalid;
  wire SDCout_axi_arready;
  wire [31:0]SDCout_axi_rdata;
  wire [1:0]SDCout_axi_rresp;
  wire SDCout_axi_rlast;
  wire SDCout_axi_rvalid;
  wire SDCout_axi_rready;

  // Output Interface
  (* mark_debug = "true" *) wire [3:0]m01_axi_awid;
  (* mark_debug = "true" *)  wire [31:0]m01_axi_awaddr;
  (* mark_debug = "true" *)  wire [7:0]m01_axi_awlen;
  (* mark_debug = "true" *)  wire [2:0]m01_axi_awsize;
  (* mark_debug = "true" *)  wire [1:0]m01_axi_awburst;
  (* mark_debug = "true" *)  wire [0:0]m01_axi_awlock;
  (* mark_debug = "true" *)  wire [3:0]m01_axi_awcache;
  (* mark_debug = "true" *)  wire [2:0]m01_axi_awprot;
  (* mark_debug = "true" *)  wire [3:0]m01_axi_awregion;
  (* mark_debug = "true" *)  wire [3:0]m01_axi_awqos;
  (* mark_debug = "true" *) wire m01_axi_awvalid;
  (* mark_debug = "true" *) wire m01_axi_awready;
  (* mark_debug = "true" *)  wire [63:0]m01_axi_wdata;
  (* mark_debug = "true" *)  wire [7:0]m01_axi_wstrb;
  (* mark_debug = "true" *)  wire m01_axi_wlast;
  (* mark_debug = "true" *)  wire m01_axi_wvalid;
  (* mark_debug = "true" *)  wire m01_axi_wready;
  (* mark_debug = "true" *)  wire [3:0] m01_axi_bid;
  (* mark_debug = "true" *)  wire [1:0]m01_axi_bresp;
  (* mark_debug = "true" *)  wire m01_axi_bvalid;
  (* mark_debug = "true" *)  wire m01_axi_bready;
  (* mark_debug = "true" *)  wire [3:0] m01_axi_arid;
  (* mark_debug = "true" *)  wire [31:0]m01_axi_araddr;
  (* mark_debug = "true" *)  wire [7:0]m01_axi_arlen;
  (* mark_debug = "true" *)  wire [2:0]m01_axi_arsize;
  (* mark_debug = "true" *)  wire [1:0]m01_axi_arburst;
  (* mark_debug = "true" *)  wire [0:0]m01_axi_arlock;
  (* mark_debug = "true" *)  wire [3:0]m01_axi_arcache;
  (* mark_debug = "true" *)  wire [2:0]m01_axi_arprot;
  (* mark_debug = "true" *)  wire [3:0]m01_axi_arregion;
  (* mark_debug = "true" *)  wire [3:0]m01_axi_arqos;
  (* mark_debug = "true" *)  wire m01_axi_arvalid;
  (* mark_debug = "true" *)  wire m01_axi_arready;
  (* mark_debug = "true" *)  wire [3:0] m01_axi_rid;
  (* mark_debug = "true" *)  wire [63:0]m01_axi_rdata;
  (* mark_debug = "true" *)  wire [1:0]m01_axi_rresp;
  (* mark_debug = "true" *)  wire m01_axi_rlast;
  (* mark_debug = "true" *)  wire m01_axi_rvalid;
  (* mark_debug = "true" *) wire m01_axi_rready;

  // Old SDC input
  // wire [3:0] SDCDatIn;

  // New SDC Command IOBUF connections
  wire       sd_cmd_i;
  wire        sd_cmd_reg_o;
  wire        sd_cmd_reg_t;

  // SD Card Interrupt signal
 (* mark_debug = "true" *)  wire        SDCIntr;

  // New SDC Data IOBUF connections
  wire [3:0] sd_dat_i;
  wire  [3:0] sd_dat_reg_o;
  wire        sd_dat_reg_t;
  
  assign GPIOIN = {28'b0, GPI};
  assign GPO = GPIOOUT[4:0];
  assign ahblite_resetn = peripheral_aresetn;
  assign cpu_reset = bus_struct_reset;
  assign calib = c0_init_calib_complete;
  

   
  // SD Card Tristate
  /*
  IOBUF iobufSDCMD(.T(~SDCCmdOE), // iobuf's T is active low
				   .I(SDCCmdOut),
				   .O(SDCCmdIn),
				   .IO(SDCCmd));

  genvar i;
  generate
	 for (i = 0; i < 4; i = i + 1) begin
		 IOBUF iobufSDCDat(.T(1'b1),
						   .I(1'b0),
						   .O(SDCDatIn[i]),
						   .IO(SDCDat[i]));
	 end
  endgenerate
  */
   
   // IOBUFS for new SDC peripheral
   IOBUF IOBUF_cmd (.O(sd_cmd_i), .IO(SDCCmd), .I(sd_cmd_reg_o), .T(sd_cmd_reg_t));
   genvar    i;
   generate
      for (i = 0; i < 4; i = i + 1) begin
         IOBUF iobufSDCDat(.T(sd_dat_reg_t),
                           .I(sd_dat_reg_o[i]),
                           .O(sd_dat_i[i]),
                           .IO(SDCDat[i]) );
      end
   endgenerate
   
  // IOBUF IOBUF_dat0 (.O(sd_dat_i[0]), .IO(sdio_dat[0]), .I(sd_dat_reg_o[0]), .T(sd_dat_reg_t));
  // IOBUF IOBUF_dat1 (.O(sd_dat_i[1]), .IO(sdio_dat[1]), .I(sd_dat_reg_o[1]), .T(sd_dat_reg_t));
  // IOBUF IOBUF_dat2 (.O(sd_dat_i[2]), .IO(sdio_dat[2]), .I(sd_dat_reg_o[2]), .T(sd_dat_reg_t));
  // IOBUF IOBUF_dat3 (.O(sd_dat_i[3]), .IO(sdio_dat[3]), .I(sd_dat_reg_o[3]), .T(sd_dat_reg_t));

  
   
  // reset controller XILINX IP
  xlnx_proc_sys_reset xlnx_proc_sys_reset_0
    (.slowest_sync_clk(CPUCLK),
     .ext_reset_in(c0_ddr4_ui_clk_sync_rst),
     .aux_reset_in(south_rst),
     .mb_debug_sys_rst(1'b0),
     .dcm_locked(c0_init_calib_complete),
     .mb_reset(mb_reset),  //open
     .bus_struct_reset(bus_struct_reset),
     .peripheral_reset(peripheral_reset), //open
     .interconnect_aresetn(interconnect_aresetn), //open
     .peripheral_aresetn(peripheral_aresetn));

  `include "parameter-defs.vh"

  wallypipelinedsoc  #(P) 
  wallypipelinedsoc(.clk(CPUCLK), .reset_ext(bus_struct_reset), .reset(), 
                    .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HSELEXT,
                    .HSELEXTSDC, .HCLK(HCLKOpen), .HRESETn(HRESETnOpen), 
                    .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
                    .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), 
                    .GPIOIN, .GPIOOUT, .GPIOEN,
                    .UARTSin, .UARTSout, .SDCIntr); 
  

  // // wally
  // // *** FIXME add sdc interrupt and HSELEXTSDC, remove old sdc
  // wallypipelinedsocwrapper wallypipelinedsocwrapper
  //   (.clk(CPUCLK),
  //    .reset_ext(bus_struct_reset),
  //    // bus interface
  //    .HRDATAEXT(HRDATAEXT),
  //    .HREADYEXT(HREADYEXT),
  //    .HRESPEXT(HRESPEXT),
  //    .HSELEXT(HSELEXT),
  //    .HSELEXTSDC(HSELEXTSDC),
  //    .HCLK(HCLKOpen), // open
  //    .HRESETn(HRESETnOpen), // open
  //    .HADDR(HADDR),
  //    .HWDATA(HWDATA),
  //    .HWRITE(HWRITE),
  //    .HSIZE(HSIZE),
  //    .HBURST(HBURST),
  //    .HPROT(HPROT),
  //    .HTRANS(HTRANS),
  //    .HMASTLOCK(HMASTLOCK),
  //    .HREADY(HREADY),
  //    // GPIO
  //    .GPIOIN(GPIOIN),
  //    .GPIOOUT(GPIOOUT),
  //    .GPIOEN(GPIOEN),
  //    // UART
  //    .UARTSin(UARTSin),
  //    .UARTSout(UARTSout),
  //    .SDCIntr(SDCIntr)
  //    // SD Card   
  //    /*.SDCDatIn(SDCDatIn),
  //    .SDCCmdIn(SDCCmdIn),     
  //    .SDCCmdOut(SDCCmdOut),
  //    .SDCCmdOE(SDCCmdOE),
  //    .SDCCLK(SDCCLK));*/
  //    );
  
  // ahb lite to axi bridge
  xlnx_ahblite_axi_bridge xlnx_ahblite_axi_bridge_0
    (.s_ahb_hclk(CPUCLK),
     .s_ahb_hresetn(peripheral_aresetn),
     .s_ahb_hsel(HSELEXT | HSELEXTSDC),
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

  // AXI Crossbar for arbitrating the SDC and CPU --------------
  xlnx_axi_crossbar xlnx_axi_crossbar_0
   	(.aclk(CPUCLK),
	 .aresetn(peripheral_aresetn),

	 // Connect Masters
	 .s_axi_awid({4'b1000, m_axi_awid}),
	 .s_axi_awaddr({m01_axi_awaddr, m_axi_awaddr}),
	 .s_axi_awlen({m01_axi_awlen, m_axi_awlen}),
	 .s_axi_awsize({m01_axi_awsize, m_axi_awsize}),
	 .s_axi_awburst({m01_axi_awburst, m_axi_awburst}),
	 .s_axi_awlock({m01_axi_awlock, m_axi_awlock}),
	 .s_axi_awcache({m01_axi_awcache, m_axi_awcache}),
	 .s_axi_awprot({m01_axi_awprot, m_axi_awprot}),
	 .s_axi_awqos(8'b0),
	 .s_axi_awvalid({m01_axi_awvalid, m_axi_awvalid}),
	 .s_axi_awready({m01_axi_awready, m_axi_awready}),
	 .s_axi_wdata({m01_axi_wdata, m_axi_wdata}),
	 .s_axi_wstrb({m01_axi_wstrb, m_axi_wstrb}),
	 .s_axi_wlast({m01_axi_wlast, m_axi_wlast}),
	 .s_axi_wvalid({m01_axi_wvalid, m_axi_wvalid}),
	 .s_axi_wready({m01_axi_wready, m_axi_wready}),
	 .s_axi_bid({m01_axi_bid, m_axi_bid}),
	 .s_axi_bresp({m01_axi_bresp, m_axi_bresp}),
	 .s_axi_bvalid({m01_axi_bvalid, m_axi_bvalid}),
	 .s_axi_bready({m01_axi_bready, m_axi_bready}),
	 .s_axi_arid({4'b1000, m_axi_arid}),
	 .s_axi_araddr({m01_axi_araddr, m_axi_araddr}),
	 .s_axi_arlen({m01_axi_arlen, m_axi_arlen}),
	 .s_axi_arsize({m01_axi_arsize, m_axi_arsize}),
	 .s_axi_arburst({m01_axi_arburst, m_axi_arburst}),
	 .s_axi_arlock({m01_axi_arlock, m_axi_arlock}),
	 .s_axi_arcache({m01_axi_arcache, m_axi_arcache}),
	 .s_axi_arprot({m01_axi_arprot, m_axi_arprot}),
	 .s_axi_arqos(8'b0),
	 .s_axi_arvalid({m01_axi_arvalid, m_axi_arvalid}),
	 .s_axi_arready({m01_axi_arready, m_axi_arready}),
	 .s_axi_rid({m01_axi_rid, m_axi_rid}),
	 .s_axi_rdata({m01_axi_rdata, m_axi_rdata}),
	 .s_axi_rresp({m01_axi_rresp, m_axi_rresp}),
	 .s_axi_rlast({m01_axi_rlast, m_axi_rlast}),
	 .s_axi_rvalid({m01_axi_rvalid, m_axi_rvalid}),
	 .s_axi_rready({m01_axi_rready, m_axi_rready}),
	 
	 // Connect Slaves
     .m_axi_awid({s01_axi_awid, s00_axi_awid}),
     .m_axi_awlen({s01_axi_awlen, s00_axi_awlen}),
     .m_axi_awsize({s01_axi_awsize, s00_axi_awsize}),
     .m_axi_awburst({s01_axi_awburst, s00_axi_awburst}),
     .m_axi_awcache({s01_axi_awcache, s00_axi_awcache}),
     .m_axi_awaddr({s01_axi_awaddr, s00_axi_awaddr}),
     .m_axi_awprot({s01_axi_awprot, s00_axi_awprot}),
     .m_axi_awregion({s01_axi_awregion, s00_axi_awregion}),
     .m_axi_awqos({s01_axi_awqos, s00_axi_awqos}),
     .m_axi_awvalid({s01_axi_awvalid, s00_axi_awvalid}),
     .m_axi_awready({s01_axi_awready, s00_axi_awready}),
     .m_axi_awlock({s01_axi_awlock, s00_axi_awlock}),
     .m_axi_wdata({s01_axi_wdata, s00_axi_wdata}),
     .m_axi_wstrb({s01_axi_wstrb, s00_axi_wstrb}),
     .m_axi_wlast({s01_axi_wlast, s00_axi_wlast}),
     .m_axi_wvalid({s01_axi_wvalid, s00_axi_wvalid}),
     .m_axi_wready({s01_axi_wready, s00_axi_wready}),
     .m_axi_bid({4'b1000, s00_axi_bid}),
     .m_axi_bresp({s01_axi_bresp, s00_axi_bresp}),
     .m_axi_bvalid({s01_axi_bvalid, s00_axi_bvalid}),
     .m_axi_bready({s01_axi_bready, s00_axi_bready}),
     .m_axi_arid({s01_axi_arid, s00_axi_arid}),
     .m_axi_arlen({s01_axi_arlen, s00_axi_arlen}),
     .m_axi_arsize({s01_axi_arsize, s00_axi_arsize}),
     .m_axi_arburst({s01_axi_arburst, s00_axi_arburst}),
     .m_axi_arprot({s01_axi_arprot, s00_axi_arprot}),
     .m_axi_arregion({s01_axi_arregion, s00_axi_arregion}),
     .m_axi_arqos({s01_axi_arqos, s00_axi_arqos}),
     .m_axi_arcache({s01_axi_arcache, s00_axi_arcache}),
     .m_axi_arvalid({s01_axi_arvalid, s00_axi_arvalid}),
     .m_axi_araddr({s01_axi_araddr, s00_axi_araddr}),
     .m_axi_arlock({s01_axi_arlock, s00_axi_arlock}),
     .m_axi_arready({s01_axi_arready, s00_axi_arready}),
     .m_axi_rid({4'b1000, s00_axi_rid}),
     .m_axi_rdata({s01_axi_rdata, s00_axi_rdata}),
     .m_axi_rresp({s01_axi_rresp, s00_axi_rresp}),
     .m_axi_rvalid({s01_axi_rvalid, s00_axi_rvalid}),
     .m_axi_rlast({s01_axi_rlast, s00_axi_rlast}),
     .m_axi_rready({s01_axi_rready, s00_axi_rready})
	 );
   
   // -----------------------------------------------------

   // SDC Implementation ----------------------------------
   //
   // The SDC peripheral from Eugene Tarassov takes in an AXI4Lite
   // interface and outputs an AXI4 interface. In order to convert from
   // one to the other, we use these dwidth converters to make sure the
   // bit widths match the rest of the bus.
   
   xlnx_axi_dwidth_conv_64to32 axi_conv_down
	(.s_axi_aclk(CPUCLK),
	 .s_axi_aresetn(peripheral_aresetn),

	 // Slave interface
	 .s_axi_awaddr(s01_axi_awaddr),
	 .s_axi_awlen(s01_axi_awlen),
	 .s_axi_awsize(s01_axi_awsize),
	 .s_axi_awburst(s01_axi_awburst),
	 .s_axi_awlock(s01_axi_awlock),
	 .s_axi_awcache(s01_axi_awcache),
	 .s_axi_awprot(s01_axi_awprot),
	 .s_axi_awregion(s01_axi_awregion),
	 .s_axi_awqos(4'b0),
	 .s_axi_awvalid(s01_axi_awvalid),
	 .s_axi_awready(s01_axi_awready),
	 .s_axi_wdata(s01_axi_wdata),
	 .s_axi_wstrb(s01_axi_wstrb),
	 .s_axi_wlast(s01_axi_wlast),
	 .s_axi_wvalid(s01_axi_wvalid),
	 .s_axi_wready(s01_axi_wready),
	 .s_axi_bresp(s01_axi_bresp),
	 .s_axi_bvalid(s01_axi_bvalid),
	 .s_axi_bready(s01_axi_bready),
	 .s_axi_araddr(s01_axi_araddr),
	 .s_axi_arlen(s01_axi_arlen),
	 .s_axi_arsize(s01_axi_arsize),
	 .s_axi_arburst(s01_axi_arburst),
	 .s_axi_arlock(s01_axi_arlock),
	 .s_axi_arcache(s01_axi_arcache),
	 .s_axi_arprot(s01_axi_arprot),
	 .s_axi_arregion(s01_axi_arregion),
	 .s_axi_arqos(4'b0),
	 .s_axi_arvalid(s01_axi_arvalid),
	 .s_axi_arready(s01_axi_arready),
	 .s_axi_rdata(s01_axi_rdata),
	 .s_axi_rresp(s01_axi_rresp),
	 .s_axi_rlast(s01_axi_rlast),
	 .s_axi_rvalid(s01_axi_rvalid),
	 .s_axi_rready(s01_axi_rready),

	 // Master interface
	 .m_axi_awaddr(axi4in_axi_awaddr),
	 .m_axi_awlen(axi4in_axi_awlen),
	 .m_axi_awsize(axi4in_axi_awsize),
	 .m_axi_awburst(axi4in_axi_awburst),
	 .m_axi_awlock(axi4in_axi_awlock),
	 .m_axi_awcache(axi4in_axi_awcache),
	 .m_axi_awprot(axi4in_axi_awprot),
	 .m_axi_awregion(axi4in_axi_awregion),
	 .m_axi_awqos(axi4in_axi_awqos),
	 .m_axi_awvalid(axi4in_axi_awvalid),
	 .m_axi_awready(axi4in_axi_awready),
	 .m_axi_wdata(axi4in_axi_wdata),
	 .m_axi_wstrb(axi4in_axi_wstrb),
	 .m_axi_wlast(axi4in_axi_wlast),
	 .m_axi_wvalid(axi4in_axi_wvalid),
	 .m_axi_wready(axi4in_axi_wready),
	 .m_axi_bresp(axi4in_axi_bresp),
	 .m_axi_bvalid(axi4in_axi_bvalid),
	 .m_axi_bready(axi4in_axi_bready),
	 .m_axi_araddr(axi4in_axi_araddr),
	 .m_axi_arlen(axi4in_axi_arlen),
	 .m_axi_arsize(axi4in_axi_arsize),
	 .m_axi_arburst(axi4in_axi_arburst),
	 .m_axi_arlock(axi4in_axi_arlock),
	 .m_axi_arcache(axi4in_axi_arcache),
	 .m_axi_arprot(axi4in_axi_arprot),
	 .m_axi_arregion(axi4in_axi_arregion),
	 .m_axi_arqos(axi4in_axi_arqos),
	 .m_axi_arvalid(axi4in_axi_arvalid),
	 .m_axi_arready(axi4in_axi_arready),
	 .m_axi_rdata(axi4in_axi_rdata),
	 .m_axi_rresp(axi4in_axi_rresp),
	 .m_axi_rlast(axi4in_axi_rlast),
	 .m_axi_rvalid(axi4in_axi_rvalid),
	 .m_axi_rready(axi4in_axi_rready)
	 );
   
  xlnx_axi_prtcl_conv axi4tolite
    (.aclk(CPUCLK),
     .aresetn(peripheral_aresetn),

     // AXI4 In
     .s_axi_awaddr(axi4in_axi_awaddr),
     .s_axi_awlen(axi4in_axi_awlen),
     .s_axi_awsize(axi4in_axi_awsize),
     .s_axi_awburst(axi4in_axi_awburst),
     .s_axi_awlock(axi4in_axi_awlock),
     .s_axi_awcache(axi4in_axi_awcache),
     .s_axi_awprot(axi4in_axi_awprot),
     .s_axi_awregion(axi4in_axi_awregion),
     .s_axi_awqos(axi4in_axi_awqos),
     .s_axi_awvalid(axi4in_axi_awvalid),
     .s_axi_awready(axi4in_axi_awready),
     .s_axi_wdata(axi4in_axi_wdata),
     .s_axi_wstrb(axi4in_axi_wstrb),
     .s_axi_wlast(axi4in_axi_wlast),
     .s_axi_wvalid(axi4in_axi_wvalid),
     .s_axi_wready(axi4in_axi_wready),
     .s_axi_bresp(axi4in_axi_bresp),
     .s_axi_bvalid(axi4in_axi_bvalid),
     .s_axi_bready(axi4in_axi_bready),
     .s_axi_araddr(axi4in_axi_araddr),
     .s_axi_arlen(axi4in_axi_arlen),
     .s_axi_arsize(axi4in_axi_arsize),
     .s_axi_arburst(axi4in_axi_arburst),
     .s_axi_arlock(axi4in_axi_arlock),
     .s_axi_arcache(axi4in_axi_arcache),
     .s_axi_arprot(axi4in_axi_arprot),
     .s_axi_arregion(axi4in_axi_arregion),
     .s_axi_arqos(axi4in_axi_arqos),
     .s_axi_arvalid(axi4in_axi_arvalid),
     .s_axi_arready(axi4in_axi_arready),
     .s_axi_rdata(axi4in_axi_rdata),
     .s_axi_rresp(axi4in_axi_rresp),
     .s_axi_rlast(axi4in_axi_rlast),
     .s_axi_rvalid(axi4in_axi_rvalid),
     .s_axi_rready(axi4in_axi_rready),

     // AXI4Lite Out
     .m_axi_awaddr(SDCin_axi_awaddr),
     .m_axi_awprot(SDCin_axi_awprot),
     .m_axi_awvalid(SDCin_axi_awvalid),
     .m_axi_awready(SDCin_axi_awready),
     .m_axi_wdata(SDCin_axi_wdata),
     .m_axi_wstrb(SDCin_axi_wstrb),
     .m_axi_wvalid(SDCin_axi_wvalid),
     .m_axi_wready(SDCin_axi_wready),
     .m_axi_bresp(SDCin_axi_bresp),
     .m_axi_bvalid(SDCin_axi_bvalid),
     .m_axi_bready(SDCin_axi_bready),
     .m_axi_araddr(SDCin_axi_araddr),
     .m_axi_arprot(SDCin_axi_arprot),
     .m_axi_arvalid(SDCin_axi_arvalid),
     .m_axi_arready(SDCin_axi_arready),
     .m_axi_rdata(SDCin_axi_rdata),
     .m_axi_rresp(SDCin_axi_rresp),
     .m_axi_rvalid(SDCin_axi_rvalid),
     .m_axi_rready(SDCin_axi_rready)
     
     );
   

  sdc_controller axiSDC
	(.clock(CPUCLK),
	 .async_resetn(peripheral_aresetn),
	 
	 // Slave Interface
	 .s_axi_awaddr({8'b0, SDCin_axi_awaddr[7:0]}),
	 .s_axi_awvalid(SDCin_axi_awvalid),
	 .s_axi_awready(SDCin_axi_awready),
	 .s_axi_wdata(SDCin_axi_wdata),
	 .s_axi_wvalid(SDCin_axi_wvalid),
	 .s_axi_wready(SDCin_axi_wready),
	 .s_axi_bresp(SDCin_axi_bresp),
	 .s_axi_bvalid(SDCin_axi_bvalid),
	 .s_axi_bready(SDCin_axi_bready),
	 .s_axi_araddr({8'b0, SDCin_axi_araddr[7:0]}),
	 .s_axi_arvalid(SDCin_axi_arvalid),
	 .s_axi_arready(SDCin_axi_arready),
	 .s_axi_rdata(SDCin_axi_rdata),
	 .s_axi_rresp(SDCin_axi_rresp),
	 .s_axi_rvalid(SDCin_axi_rvalid),
	 .s_axi_rready(SDCin_axi_rready),
	 
	 // Master Interface
	 .m_axi_awaddr(SDCout_axi_awaddr),
	 .m_axi_awlen(SDCout_axi_awlen),
	 .m_axi_awvalid(SDCout_axi_awvalid),
	 .m_axi_awready(SDCout_axi_awready),
	 .m_axi_wdata(SDCout_axi_wdata),
	 .m_axi_wlast(SDCout_axi_wlast),
	 .m_axi_wvalid(SDCout_axi_wvalid),
	 .m_axi_wready(SDCout_axi_wready),
	 .m_axi_bresp(SDCout_axi_bresp),
	 .m_axi_bvalid(SDCout_axi_bvalid),
	 .m_axi_bready(SDCout_axi_bready),
	 .m_axi_araddr(SDCout_axi_araddr),
	 .m_axi_arlen(SDCout_axi_arlen),
	 .m_axi_arvalid(SDCout_axi_arvalid),
	 .m_axi_arready(SDCout_axi_arready),
	 .m_axi_rdata(SDCout_axi_rdata),
	 .m_axi_rlast(SDCout_axi_rlast),
	 .m_axi_rresp(SDCout_axi_rresp),
	 .m_axi_rvalid(SDCout_axi_rvalid),
	 .m_axi_rready(SDCout_axi_rready),

	 // SDC interface
	 //.sdio_cmd(1'b0),
	 //.sdio_dat(4'b0),
	 //.sdio_cd(1'b0)

     .sd_dat_reg_t(sd_dat_reg_t),
     .sd_dat_reg_o(sd_dat_reg_o),
     .sd_dat_i(sd_dat_i),
     
     .sd_cmd_reg_t(sd_cmd_reg_t),
     .sd_cmd_reg_o(sd_cmd_reg_o),
     .sd_cmd_i(sd_cmd_i),

     .sdio_clk(SDCCLK),
     .sdio_cd(SDCCD),

     .interrupt(SDCIntr)
	 );

  xlnx_axi_dwidth_conv_32to64 axi_conv_up
	(.s_axi_aclk(CPUCLK),
	 .s_axi_aresetn(peripheral_aresetn),
	 
	 // Slave interface
	 .s_axi_awaddr(SDCout_axi_awaddr),
	 .s_axi_awlen(SDCout_axi_awlen),
	 .s_axi_awsize(3'b010),
	 .s_axi_awburst(2'b01),
	 .s_axi_awlock(1'b0),
	 .s_axi_awcache(4'b0),
	 .s_axi_awprot(3'b0),
	 .s_axi_awregion(4'b0),
	 .s_axi_awqos(4'b0),
	 .s_axi_awvalid(SDCout_axi_awvalid),
	 .s_axi_awready(SDCout_axi_awready),
	 .s_axi_wdata(SDCout_axi_wdata),
	 .s_axi_wstrb(8'b11111111),
	 .s_axi_wlast(SDCout_axi_wlast),
	 .s_axi_wvalid(SDCout_axi_wvalid),
	 .s_axi_wready(SDCout_axi_wready),
	 .s_axi_bresp(SDCout_axi_bresp),
	 .s_axi_bvalid(SDCout_axi_bvalid),
	 .s_axi_bready(SDCout_axi_bready),
	 .s_axi_araddr(SDCout_axi_araddr),
	 .s_axi_arlen(SDCout_axi_arlen),
	 .s_axi_arsize(3'b010),
	 .s_axi_arburst(2'b01),
	 .s_axi_arlock(1'b0),
	 .s_axi_arcache(4'b0),
	 .s_axi_arprot(3'b0),
	 .s_axi_arregion(4'b0),
	 .s_axi_arqos(4'b0),
	 .s_axi_arvalid(SDCout_axi_arvalid),
	 .s_axi_arready(SDCout_axi_arready),
	 .s_axi_rdata(SDCout_axi_rdata),
	 .s_axi_rresp(SDCout_axi_rresp),
	 .s_axi_rlast(SDCout_axi_rlast),
	 .s_axi_rvalid(SDCout_axi_rvalid),
	 .s_axi_rready(SDCout_axi_rready),

	 // Master interface
	 .m_axi_awaddr(m01_axi_awaddr),
	 .m_axi_awlen(m01_axi_awlen),
	 .m_axi_awsize(m01_axi_awsize),
	 .m_axi_awburst(m01_axi_awburst),
	 .m_axi_awlock(m01_axi_awlock),
	 .m_axi_awcache(m01_axi_awcache),
	 .m_axi_awprot(m01_axi_awprot),
	 .m_axi_awregion(m01_axi_awregion),
	 .m_axi_awqos(m01_axi_awqos),
	 .m_axi_awvalid(m01_axi_awvalid),
	 .m_axi_awready(m01_axi_awready),
	 .m_axi_wdata(m01_axi_wdata),
	 .m_axi_wstrb(m01_axi_wstrb),
	 .m_axi_wlast(m01_axi_wlast),
	 .m_axi_wvalid(m01_axi_wvalid),
	 .m_axi_wready(m01_axi_wready),
	 .m_axi_bresp(m01_axi_bresp),
	 .m_axi_bvalid(m01_axi_bvalid),
	 .m_axi_bready(m01_axi_bready),
	 .m_axi_araddr(m01_axi_araddr),
	 .m_axi_arlen(m01_axi_arlen),
	 .m_axi_arsize(m01_axi_arsize),
	 .m_axi_arburst(m01_axi_arburst),
	 .m_axi_arlock(m01_axi_arlock),
	 .m_axi_arcache(m01_axi_arcache),
	 .m_axi_arprot(m01_axi_arprot),
	 .m_axi_arregion(m01_axi_arregion),
	 .m_axi_arqos(m01_axi_arqos),
	 .m_axi_arvalid(m01_axi_arvalid),
	 .m_axi_arready(m01_axi_arready),
	 .m_axi_rdata(m01_axi_rdata),
	 .m_axi_rresp(m01_axi_rresp),
	 .m_axi_rlast(m01_axi_rlast),
	 .m_axi_rvalid(m01_axi_rvalid),
	 .m_axi_rready(m01_axi_rready)
	 );

  // End SDC signals --------------------------------------------
   
  xlnx_axi_clock_converter xlnx_axi_clock_converter_0
    (.s_axi_aclk(CPUCLK),
     .s_axi_aresetn(peripheral_aresetn),
     .s_axi_awid(s00_axi_awid),
     .s_axi_awlen(s00_axi_awlen),
     .s_axi_awsize(s00_axi_awsize),
     .s_axi_awburst(s00_axi_awburst),
     .s_axi_awcache(s00_axi_awcache),
     .s_axi_awaddr(s00_axi_awaddr[30:0] ),
     .s_axi_awprot(s00_axi_awprot),
     .s_axi_awregion(4'b0), // this could be a bug. bridge does not have these outputs
     .s_axi_awqos(4'b0),    // this could be a bug. bridge does not have these outputs
     .s_axi_awvalid(s00_axi_awvalid),
     .s_axi_awready(s00_axi_awready),
     .s_axi_awlock(s00_axi_awlock),
     .s_axi_wdata(s00_axi_wdata),
     .s_axi_wstrb(s00_axi_wstrb),
     .s_axi_wlast(s00_axi_wlast),
     .s_axi_wvalid(s00_axi_wvalid),
     .s_axi_wready(s00_axi_wready),
     .s_axi_bid(s00_axi_bid),
     .s_axi_bresp(s00_axi_bresp),
     .s_axi_bvalid(s00_axi_bvalid),
     .s_axi_bready(s00_axi_bready),
     .s_axi_arid(s00_axi_arid),
     .s_axi_arlen(s00_axi_arlen),
     .s_axi_arsize(s00_axi_arsize),
     .s_axi_arburst(s00_axi_arburst),
     .s_axi_arprot(s00_axi_arprot),
     .s_axi_arregion(4'b0), // this could be a bug. bridge does not have these outputs
     .s_axi_arqos(4'b0),    // this could be a bug. bridge does not have these outputs
     .s_axi_arcache(s00_axi_arcache),
     .s_axi_arvalid(s00_axi_arvalid),
     .s_axi_araddr(s00_axi_araddr[30:0]),
     .s_axi_arlock(s00_axi_arlock),
     .s_axi_arready(s00_axi_arready),
     .s_axi_rid(s00_axi_rid),
     .s_axi_rdata(s00_axi_rdata),
     .s_axi_rresp(s00_axi_rresp),
     .s_axi_rvalid(s00_axi_rvalid),
     .s_axi_rlast(s00_axi_rlast),
     .s_axi_rready(s00_axi_rready),

     .m_axi_aclk(BUSCLK),
     .m_axi_aresetn(~reset),
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
     .c0_ddr4_s_axi_awaddr(BUS_axi_awaddr[30:0]),
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
     .c0_ddr4_s_axi_araddr(BUS_axi_araddr[30:0]),
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

