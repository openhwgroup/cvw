
module arithrightshift import cvw::*;  #(parameter cvw_t P) (
  input logic signed [P.XLEN+3:0] shiftin,
  output logic signed [P.XLEN+3:0] shifted
);
  assign shifted = $signed(shiftin) >>> P.LOGR;

endmodule

