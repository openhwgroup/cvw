// Instructions
// `define BYPASS 5'b11111
// `define IDCODE 5'b00001
// `define DTMCS 5'b10000
// `define DMIREG 5'b10001

`include "debug.vh"
  
module inst_reg #(parameter ADRWIDTH=5) (
    input logic  tdi,
    input logic  resetn, ShiftIR, ClockIR, UpdateIR,
    output logic tdo,
    output logic [ADRWIDTH-1:0] instreg
    //output logic bypass
);
    logic [ADRWIDTH-1:0] shiftreg;
    
    always @(posedge ClockIR)
      shiftreg <= ShiftIR ? {tdi, shiftreg[ADRWIDTH-1:1]} : IDCODE;

    always @(posedge UpdateIR, negedge resetn)
      if (~resetn) instreg <= BYPASS;
      else instreg <= shiftreg;

    assign tdo = shiftreg[0];

    //assign bypass = (instreg == DTMINST.BYPASS);

endmodule
