module instrTrackerTB(
  input  logic            clk, reset, FlushE,
  input  logic [31:0]     InstrF, InstrD,
  input  logic [31:0]     InstrE, InstrM,
  input  logic [31:0]     InstrW,
//  output logic [31:0]     InstrW,
  output string           InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);
        
  // stage Instr to Writeback for visualization
  // flopr  #(32) InstrWReg(clk, reset, InstrM, InstrW);

  instrNameDecTB fdec(InstrF, InstrFName);
  instrNameDecTB ddec(InstrD, InstrDName);
  instrNameDecTB edec(InstrE, InstrEName);
  instrNameDecTB mdec(InstrM, InstrMName);
  instrNameDecTB wdec(InstrW, InstrWName);
endmodule
