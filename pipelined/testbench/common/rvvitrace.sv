`include "wally-config.vh"

`define NUM_REGS 32
`define NUM_CSRS 4096

`define PRINT_PC_INSTR 1
`define PRINT_MOST 1
`define PRINT_ALL 0

module rvviTrace #(
				   parameter int ILEN = `XLEN, // Instruction length in bits
				   parameter int XLEN = `XLEN, // GPR length in bits
				   parameter int FLEN = `FLEN, // FPR length in bits
				   parameter int VLEN = 0, // Vector register size in bits
				   parameter int NHART = 1, // Number of harts reported
				   parameter int RETIRE = 1)    // Number of instructions that can retire during valid event
  ();

  localparam NUMREGS = `E_SUPPORTED ? 16 : 32;
  
  // wally specific signals
  logic 						 reset;
  
  logic [`XLEN-1:0] 			 PCNextF, PCF, PCD, PCE, PCM, PCW;
  logic [`XLEN-1:0] 			 InstrRawD, InstrRawE, InstrRawM, InstrRawW;
  logic 						 InstrValidM, InstrValidW;
  logic 						 StallE, StallM, StallW;
  logic 						 FlushD, FlushE, FlushM, FlushW;
  logic 						 TrapM, TrapW;
  logic 						 HaltM, HaltW;
  logic [1:0] 					 PrivilegeModeW;
  logic [`XLEN-1:0] 			 rf[NUMREGS];
  logic [NUMREGS-1:0] 			 rf_wb;
  logic [4:0] 					 rf_a3;
  logic 						 rf_we3;
  logic [`XLEN-1:0] 			 frf[32];
  logic [`NUM_REGS-1:0] 		 frf_wb;
  logic [4:0] 					 frf_a4;
  logic 						 frf_we4;
  
  

  // tracer signals
  logic 						 clk;
  logic 						 valid;
  logic [63:0] 					 order      [(NHART-1):0][(RETIRE-1):0];
  logic [ILEN-1:0] 				 insn [(NHART-1):0][(RETIRE-1):0];
  logic [(XLEN-1):0] 			 pc_rdata   [(NHART-1):0][(RETIRE-1):0];
  logic [(XLEN-1):0] 			 pc_wdata   [(NHART-1):0][(RETIRE-1):0];
  logic 						 trap       [(NHART-1):0][(RETIRE-1):0];
  logic 						 halt       [(NHART-1):0][(RETIRE-1):0];
  logic 						 intr       [(NHART-1):0][(RETIRE-1):0];
  logic [1:0] 					 mode       [(NHART-1):0][(RETIRE-1):0];
  logic [1:0] 					 ixl        [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0][(XLEN-1):0] x_wdata    [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0] 			x_wb       [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0][(XLEN-1):0] f_wdata    [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0] 			f_wb       [(NHART-1):0][(RETIRE-1):0];
  
  assign clk = testbench.dut.clk;
  //  assign InstrValidF = testbench.dut.core.ieu.InstrValidF;  // not needed yet
  assign InstrValidD = testbench.dut.core.ieu.c.InstrValidD;
  assign InstrValidE = testbench.dut.core.ieu.c.InstrValidE;
  assign InstrValidM = testbench.dut.core.ieu.InstrValidM;
  assign InstrRawD = testbench.dut.core.ifu.InstrRawD;
  assign PCNextF = testbench.dut.core.ifu.PCNextF;
  assign PCF = testbench.dut.core.ifu.PCF;
  assign PCD = testbench.dut.core.ifu.PCD;
  assign PCE = testbench.dut.core.ifu.PCE;
  assign PCM = testbench.dut.core.ifu.PCM;
  assign reset = testbench.reset;
  assign StallE = testbench.dut.core.StallE;
  assign StallM = testbench.dut.core.StallM;
  assign StallW = testbench.dut.core.StallW;
  assign FlushD = testbench.dut.core.FlushD;
  assign FlushE = testbench.dut.core.FlushE;
  assign FlushM = testbench.dut.core.FlushM;
  assign FlushW = testbench.dut.core.FlushW;
  assign TrapM = testbench.dut.core.TrapM;
  assign HaltM = testbench.DCacheFlushStart;
  assign PrivilegeModeW = testbench.dut.core.priv.priv.privmode.PrivilegeModeW;
  assign STATUS_SXL = testbench.dut.core.priv.priv.csr.csrsr.STATUS_SXL;
  assign STATUS_UXL = testbench.dut.core.priv.priv.csr.csrsr.STATUS_UXL;

  genvar 							index;
  assign rf[0] = '0;
  for(index = 1; index < NUMREGS; index += 1) 
	assign rf[index] = testbench.dut.core.ieu.dp.regf.rf[index];

  assign rf_a3 = testbench.dut.core.ieu.dp.regf.a3;
  assign rf_we3 = testbench.dut.core.ieu.dp.regf.we3;
  
  always_comb begin
	rf_wb = '0;
	if(rf_we3)
	  rf_wb[rf_a3] = 1'b1;
  end

  for(index = 0; index < NUMREGS; index += 1) 
	assign frf[index] = testbench.dut.core.fpu.fpu.fregfile.rf[index];
  
  assign frf_a4 = testbench.dut.core.fpu.fpu.fregfile.a4;
  assign frf_we4 = testbench.dut.core.fpu.fpu.fregfile.we4;
  
  always_comb begin
	frf_wb = '0;
	if(frf_we4)
	  frf_wb[frf_a4] = 1'b1;
  end

  // pipeline to writeback stage
  flopenrc #(`XLEN) InstrRawEReg (clk, reset, FlushE, ~StallE, InstrRawD, InstrRawE);
  flopenrc #(`XLEN) InstrRawMReg (clk, reset, FlushM, ~StallM, InstrRawE, InstrRawM);
  flopenrc #(`XLEN) InstrRawWReg (clk, reset, FlushW, ~StallW, InstrRawM, InstrRawW);
  flopenrc #(`XLEN) PCWReg (clk, reset, FlushW, ~StallW, PCM, PCW);
  flopenrc #(1)     InstrValidMReg (clk, reset, FlushW, ~StallW, InstrValidM, InstrValidW);
  flopenrc #(1)     TrapWReg (clk, reset, 1'b0, ~StallW, TrapM, TrapW);
  flopenrc #(1)     HaltWReg (clk, reset, 1'b0, ~StallW, HaltM, HaltW);

  // Initially connecting the writeback stage signals, but may need to use M stage
  // and gate on ~FlushW.

  assign valid = InstrValidW & ~StallW & ~FlushW;
  assign insn[0][0] = InstrRawW;
  assign pc_rdata[0][0] = PCW;
  assign trap[0][0] = TrapW;
  assign halt[0][0] = HaltW;
  assign intr[0][0] = '0;    // *** first retired instruction of trap handler.  Not sure how i'm going to get this yet.
  assign mode[0][0] = PrivilegeModeW;
  assign ixl[0][0] = PrivilegeModeW == 2'b11 ? 2'b10 :
					 PrivilegeModeW == 2'b01 ? STATUS_SXL : STATUS_UXL;
  assign pc_wdata[0][0] = ~FlushW ? PCM :
						  ~FlushM ? PCE :
						  ~FlushE ? PCD :
						  ~FlushD ? PCF : PCNextF;

  for(index = 0; index < `NUM_REGS; index += 1) begin
	assign x_wdata[0][0][index] = rf[index];
	assign x_wb[0][0][index] = rf_wb[index];
	assign f_wdata[0][0][index] = frf[index];
	assign f_wb[0][0][index] = frf_wb[index];
  end

  integer index2;
  
  always_ff @(posedge clk) begin
	if(valid) begin
	  if(`PRINT_PC_INSTR & !(`PRINT_ALL | `PRINT_MOST))
		$display("PC = %08x, insn = %08x", pc_rdata[0][0], insn[0][0]);
	  else if(`PRINT_MOST & !`PRINT_ALL)
		$display("PC = %08x, insn = %08x, trap = %1d, halt = %1d, mode = %1x, ixl = %1x, pc_wdata = %08x, x%02d = %08x", pc_rdata[0][0], insn[0][0], trap[0][0], halt[0][0], mode[0][0], ixl[0][0], pc_wdata[0][0], rf_a3, x_wdata[0][0][rf_a3]);
	  else if(`PRINT_ALL) begin
		$display("PC = %08x, insn = %08x, trap = %1d, halt = %1d, mode = %1x, ixl = %1x, pc_wdata = %08x", pc_rdata[0][0], insn[0][0], trap[0][0], halt[0][0], mode[0][0], ixl[0][0], pc_wdata[0][0]);
	  	for(index2 = 0; index2 < `NUM_REGS; index2 += 1) begin
		  $display("x%02d = %08x", index2, x_wdata[0][0][index2]);
		end
		for(index2 = 0; index2 < `NUM_REGS; index2 += 1) begin
		  $display("f%02d = %08x", index2, f_wdata[0][0][index2]);
		end
	  end
	end
	if(HaltW) $stop();
  end



endmodule

