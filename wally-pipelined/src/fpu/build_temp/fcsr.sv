`include "../../config/rv64icfd/wally-config.vh"

module fcsr(
  input  logic [2:0]       frm,
  input  logic             reset,
  input  logic             clear,
  input  logic             clk,
  input  logic             write,
  input  logic [4:0]       flags,
  output logic [31:0] readData);

  //register I/O assignment
  logic [31:0] regInput;
  logic [31:0] regOutput;

  //no L instruction support
  //only last 8 bits used for FCSR
  
  //latching input to write signal
  //AND clk and write and remove latch
  //for clk-based write
  assign regInput = (write) ? {24'h0,frm,flags} : regInput;

  floprc #(32) (.clk(clk), .reset(reset), .clear(clear), .d(regInput), .q(regOutput));

  assign readData = regOutput;


endmodule
