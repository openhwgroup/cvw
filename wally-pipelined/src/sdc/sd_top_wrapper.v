

module sd_top_wrapper #(parameter g_COUNT_WIDTH = 8)
  (
   input 		     clk_in1_p,
   input 		     clk_in1_n,   
   input 		     a_RST, // Reset signal (Must be held for minimum of 24 clock cycles)
   // a_RST MUST COME OUT OF RESET SYNCHRONIZED TO THE 1.2 GHZ CLOCK!
   // io_SD_CMD_z    : inout std_logic;   // SD CMD Bus
   inout 		     SD_CMD, // CMD Response from card
   input [3:0] 		     i_SD_DAT, // SD DAT Bus
   output 		     o_SD_CLK, // SD CLK Bus
   // For communication with core cpu
   output 		     o_READY_FOR_READ, // tells core that initialization sequence is completed and
   // sd card is ready to read a 512 byte block to the core.
   // Held high during idle until i_READ_REQUEST is received
   output 		     o_SD_RESTARTING, // inform core the need to restart
  
   input 		     i_READ_REQUEST, // After Ready for read is sent to the core, the core will
   // pulse this bit high to indicate it wants the block at this address
   output [3:0] 	     o_DATA_TO_CORE, // nibble being sent to core when DATA block is
   // being published
   output 		     o_DATA_VALID // held high while data being read to core to indicate that it is valid
   );

  wire 		     CLK;
  wire 		     LIMIT_SD_TIMERS;
  wire [g_COUNT_WIDTH-1:0] i_COUNT_IN_MAX;
  (* mark_debug = "true" *) wire [4095:0] 	   ReadData; // full 512 bytes to Bus
  wire [32:9] 		   i_BLOCK_ADDR; // see "Addressing" in parts.fods (only 8GB total capacity is used)
  wire 			   o_SD_CMD; // CMD Command from host
  wire 			   i_SD_CMD; // CMD Command from host  
  wire 			   o_SD_CMD_OE; // Direction of SD_CMD
  (* mark_debug = "true" *) wire [2:0] 		   o_ERROR_CODE_Q; // indicates which error occured
  (* mark_debug = "true" *) wire 			   o_FATAL_ERROR; // indicates that the FATAL ERROR register has updated
  (* mark_debug = "true" *) wire 			   o_LAST_NIBBLE; // pulse when last nibble is sent

  assign LIMIT_SD_TIMERS = 1'b0;
  assign i_COUNT_IN_MAX = -8'd62;
  assign i_BLOCK_ADDR = 23'h0;
  
  clk_wiz_0 clk_wiz_0(.clk_in1_p(clk_in1_p),
		      .clk_in1_n(clk_in1_n),
		      .reset(1'b0),
		      .clk_out1(CLK),
		      .locked(locked));

  IOBUF SDCMDIODriver(.T(~o_SD_CMD_OE),
		      .I(o_SD_CMD),
		      .O(i_SD_CMD),
		      .IO(SD_CMD));
  

  sd_top #(g_COUNT_WIDTH)
  sd_top(.CLK(CLK),
	 .a_RST(a_RST),
	 .i_SD_CMD(i_SD_CMD), // CMD Response from card
	 .o_SD_CMD(o_SD_CMD), // CMD Command from host
	 .o_SD_CMD_OE(o_SD_CMD_OE), // Direction of SD_CMD
	 .i_SD_DAT(i_SD_DAT), // SD DAT Bus
	 .o_SD_CLK(o_SD_CLK), // SD CLK Bus
	 .i_BLOCK_ADDR(i_BLOCK_ADDR), // see "Addressing" in parts.fods (only 8GB total capacity is used)
	 .o_READY_FOR_READ(o_READY_FOR_READ), // tells core that initialization sequence is completed and
	 .o_SD_RESTARTING(o_SD_RESTARTING), // inform core the need to restart
	 .i_READ_REQUEST(i_READ_REQUEST), // After Ready for read is sent to the core, the core will
	 .o_DATA_TO_CORE(o_DATA_TO_CORE), // nibble being sent to core when DATA block is
	 .ReadData(ReadData), // full 512 bytes to Bus
	 .o_DATA_VALID(o_DATA_VALID), // held high while data being read to core to indicate that it is valid
	 .o_LAST_NIBBLE(o_LAST_NIBBLE), // pulse when last nibble is sent
	 .o_ERROR_CODE_Q(o_ERROR_CODE_Q), // indicates which error occured
	 .o_FATAL_ERROR(o_FATAL_ERROR), // indicates that the FATAL ERROR register has updated
	 .i_COUNT_IN_MAX(i_COUNT_IN_MAX),
	 .LIMIT_SD_TIMERS(LIMIT_SD_TIMERS)
	 );
  
endmodule
