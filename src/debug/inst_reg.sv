// Instructions
`define BYPASS 5'b11111
`define IDCODE 5'b00001
`define DTMCS 5'b10000
`define DMIREG 5'b10001
  
module inst_reg #(parameter ADRWIDTH=5) (
    input logic  tdi,
    input logic  resetn, ClockIR, UpdateIR, ShiftIR,
    output logic tdo, bypass
);
    logic [WIDTH-1:0] shiftreg;
    logic [WIDTH-1:0] instreg;
    
    always @(posedge ClockDR)
      shiftreg <= ShiftDR ? {tdi, shiftreg[ADRWIDTH-1:1]} : `IDCODE;

    always @(posedge UpdateDR, negedge resetn)
      if (~resetn) instreg <= `BYPASS;
      else instreg <= shiftreg;

    assign tdo = shiftreg[0];

endmodule
