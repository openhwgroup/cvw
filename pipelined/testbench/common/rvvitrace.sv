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
  logic 						 IntrF, IntrD, IntrE, IntrM, IntrW;
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
  logic [`XLEN-1:0] 			 CSRArray [logic[11:0]];
  logic 						 CSRWriteM, CSRWriteW;
  logic [11:0] 					 CSRAdrM, CSRAdrW;

  // tracer signals
  logic 						 clk;
  logic 						 valid;
  logic [63:0] 					 order      [(NHART-1):0][(RETIRE-1):0];
  logic [ILEN-1:0] 				 insn [(NHART-1):0][(RETIRE-1):0];
  logic 						 intr       [(NHART-1):0][(RETIRE-1):0];
  logic [(XLEN-1):0] 			 pc_rdata   [(NHART-1):0][(RETIRE-1):0];
  logic [(XLEN-1):0] 			 pc_wdata   [(NHART-1):0][(RETIRE-1):0];
  logic 						 trap       [(NHART-1):0][(RETIRE-1):0];
  logic 						 halt       [(NHART-1):0][(RETIRE-1):0];
  logic [1:0] 					 mode       [(NHART-1):0][(RETIRE-1):0];
  logic [1:0] 					 ixl        [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0][(XLEN-1):0] x_wdata    [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0] 			x_wb       [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0][(XLEN-1):0] f_wdata    [(NHART-1):0][(RETIRE-1):0];
  logic [`NUM_REGS-1:0] 			f_wb       [(NHART-1):0][(RETIRE-1):0];
  logic [4095:0][(XLEN-1):0] 		csr        [(NHART-1):0][(RETIRE-1):0];
  logic [4095:0] 					csr_wb     [(NHART-1):0][(RETIRE-1):0];
  logic 							lrsc_cancel[(NHART-1):0][(RETIRE-1):0];
  
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

  always_comb begin
	// machine CSRs
	// *** missing PMP and performance counters.
	CSRArray[12'h300] = testbench.dut.core.priv.priv.csr.csrm.MSTATUS_REGW;
	CSRArray[12'h310] = testbench.dut.core.priv.priv.csr.csrm.MSTATUSH_REGW;
	CSRArray[12'h305] = testbench.dut.core.priv.priv.csr.csrm.MTVEC_REGW;
	CSRArray[12'h341] = testbench.dut.core.priv.priv.csr.csrm.MEPC_REGW;
	CSRArray[12'h306] = testbench.dut.core.priv.priv.csr.csrm.MCOUNTEREN_REGW;
	CSRArray[12'h320] = testbench.dut.core.priv.priv.csr.csrm.MCOUNTINHIBIT_REGW;
	CSRArray[12'h302] = testbench.dut.core.priv.priv.csr.csrm.MEDELEG_REGW;
	CSRArray[12'h303] = testbench.dut.core.priv.priv.csr.csrm.MIDELEG_REGW;
	CSRArray[12'h344] = testbench.dut.core.priv.priv.csr.csrm.MIP_REGW;
	CSRArray[12'h304] = testbench.dut.core.priv.priv.csr.csrm.MIE_REGW;
	CSRArray[12'h301] = testbench.dut.core.priv.priv.csr.csrm.MISA_REGW;
	CSRArray[12'hF14] = testbench.dut.core.priv.priv.csr.csrm.MHARTID_REGW;
	CSRArray[12'h340] = testbench.dut.core.priv.priv.csr.csrm.MSCRATCH_REGW;
	CSRArray[12'h342] = testbench.dut.core.priv.priv.csr.csrm.MCAUSE_REGW;
	CSRArray[12'h343] = testbench.dut.core.priv.priv.csr.csrm.MTVAL_REGW;
	CSRArray[12'hF11] = 0;
	CSRArray[12'hF12] = 0;
	CSRArray[12'hF13] = `XLEN'h100;
	CSRArray[12'hF15] = 0;
	CSRArray[12'h34A] = 0;
	// MCYCLE and MINSTRET
	CSRArray[12'hB00] = testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[0];
	CSRArray[12'hB02] = testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2];
	// supervisor CSRs
	CSRArray[12'h100] = testbench.dut.core.priv.priv.csr.csrs.SSTATUS_REGW;
	CSRArray[12'h104] = testbench.dut.core.priv.priv.csr.csrm.MIE_REGW & 12'h222;
	CSRArray[12'h105] = testbench.dut.core.priv.priv.csr.csrs.STVEC_REGW;
	CSRArray[12'h141] = testbench.dut.core.priv.priv.csr.csrs.SEPC_REGW;
	CSRArray[12'h106] = testbench.dut.core.priv.priv.csr.csrs.SCOUNTEREN_REGW;
	CSRArray[12'h180] = testbench.dut.core.priv.priv.csr.csrs.SATP_REGW;
	CSRArray[12'h140] = testbench.dut.core.priv.priv.csr.csrs.csrs.SSCRATCH_REGW;
	CSRArray[12'h143] = testbench.dut.core.priv.priv.csr.csrs.csrs.STVAL_REGW;
	CSRArray[12'h142] = testbench.dut.core.priv.priv.csr.csrs.csrs.SCAUSE_REGW;
	CSRArray[12'h144] = testbench.dut.core.priv.priv.csr.csrm.MIP_REGW & & 12'h222 & testbench.dut.core.priv.priv.csr.csrm.MIDELEG_REGW;
	// user CSRs
	CSRArray[12'h001] = testbench.dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW;
	CSRArray[12'h002] = testbench.dut.core.priv.priv.csr.csru.FRM_REGW;
	CSRArray[12'h003] = {testbench.dut.core.priv.priv.csr.csru.FRM_REGW, testbench.dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW};
  end

  genvar 							index;
  assign rf[0] = '0;
  for(index = 1; index < NUMREGS; index += 1) 
	assign rf[index] = testbench.dut.core.ieu.dp.regf.rf[index];

  assign rf_a3 = testbench.dut.core.ieu.dp.regf.a3;
  assign rf_we3 = testbench.dut.core.ieu.dp.regf.we3;
  
  always_comb begin
	rf_wb <= '0;
	if(rf_we3)
	  rf_wb[rf_a3] <= 1'b1;
  end

  for(index = 0; index < NUMREGS; index += 1) 
	assign frf[index] = testbench.dut.core.fpu.fpu.fregfile.rf[index];
  
  assign frf_a4 = testbench.dut.core.fpu.fpu.fregfile.a4;
  assign frf_we4 = testbench.dut.core.fpu.fpu.fregfile.we4;
  
  always_comb begin
	frf_wb <= '0;
	if(frf_we4)
	  frf_wb[frf_a4] <= 1'b1;
  end

  assign CSRAdrM = testbench.dut.core.priv.priv.csr.CSRAdrM;
  assign CSRWriteM = testbench.dut.core.priv.priv.csr.CSRWriteM;
  
  // pipeline to writeback stage
  flopenrc #(`XLEN) InstrRawEReg (clk, reset, FlushE, ~StallE, InstrRawD, InstrRawE);
  flopenrc #(`XLEN) InstrRawMReg (clk, reset, FlushM, ~StallM, InstrRawE, InstrRawM);
  flopenrc #(`XLEN) InstrRawWReg (clk, reset, FlushW, ~StallW, InstrRawM, InstrRawW);
  flopenrc #(`XLEN) PCWReg (clk, reset, FlushW, ~StallW, PCM, PCW);
  flopenrc #(1)     InstrValidMReg (clk, reset, FlushW, ~StallW, InstrValidM, InstrValidW);
  flopenrc #(1)     TrapWReg (clk, reset, 1'b0, ~StallW, TrapM, TrapW);
  flopenrc #(1)     HaltWReg (clk, reset, 1'b0, ~StallW, HaltM, HaltW);

  flopenrc #(1)     IntrFReg (clk, reset, 1'b0, ~StallF, TrapM, IntrF);
  flopenrc #(1)     IntrDReg (clk, reset, FlushD, ~StallD, IntrF, IntrD);
  flopenrc #(1)     IntrEReg (clk, reset, FlushE, ~StallE, IntrD, IntrE);
  flopenrc #(1)     IntrMReg (clk, reset, FlushM, ~StallM, IntrE, IntrM);
  flopenrc #(1)     IntrWReg (clk, reset, FlushW, ~StallW, IntrM, IntrW);

  flopenrc #(12) CSRAdrWReg (clk, reset, FlushW, ~StallW, CSRAdrM, CSRAdrW);
  flopenrc #(1) CSRWriteWReg (clk, reset, FlushW, ~StallW, CSRWriteM, CSRWriteW);

  // Initially connecting the writeback stage signals, but may need to use M stage
  // and gate on ~FlushW.

  assign valid = InstrValidW & ~StallW & ~FlushW;
  assign order[0][0] = CSRArray[12'hB02];
  assign insn[0][0] = InstrRawW;
  assign pc_rdata[0][0] = PCW;
  assign trap[0][0] = TrapW;
  assign halt[0][0] = HaltW;
  assign intr[0][0] = IntrW;
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

  always_comb begin
	csr_wb[0][0] <= '0;
	if(CSRWriteW)
	  csr_wb[0][0][CSRAdrW] <= 1'b1;
  end

  integer index3;

  always_comb begin
	for(index3 = 0; index3 < `NUM_CSRS; index3 += 1) begin
	  if(CSRArray.exists(index3)) 
		csr[0][0][index3] = CSRArray[index3];
	  else 
		csr[0][0][index3] = '0;
	end
  end

  // *** implementation only cancel? so sc does not clear?
  assign lrsc_cancel[0][0] = '0;

  integer index2;

  always_ff @(posedge clk) begin
	if(valid) begin
	  if(`PRINT_PC_INSTR & !(`PRINT_ALL | `PRINT_MOST))
		$display("order = %08d, PC = %08x, insn = %08x", order[0][0], pc_rdata[0][0], insn[0][0]);
	  else if(`PRINT_MOST & !`PRINT_ALL)
		$display("order = %08d, PC = %010x, insn = %08x, trap = %1d, halt = %1d, intr = %1d, mode = %1x, ixl = %1x, pc_wdata = %010x, x%02d = %016x, f%02d = %016x, csr%03x = %016x", 
				 order[0][0], pc_rdata[0][0], insn[0][0], trap[0][0], halt[0][0], intr[0][0], mode[0][0], ixl[0][0], pc_wdata[0][0], rf_a3, x_wdata[0][0][rf_a3], frf_a4, f_wdata[0][0][frf_a4], CSRAdrW, csr[0][0][CSRAdrW]);
	  else if(`PRINT_ALL) begin
		$display("order = %08d, PC = %08x, insn = %08x, trap = %1d, halt = %1d, intr = %1d, mode = %1x, ixl = %1x, pc_wdata = %08x", 
				 order[0][0], pc_rdata[0][0], insn[0][0], trap[0][0], halt[0][0], intr[0][0], mode[0][0], ixl[0][0], pc_wdata[0][0]);
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

