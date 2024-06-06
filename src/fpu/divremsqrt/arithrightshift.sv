
module arithrightshift import cvw::*;  #(parameter cvw_t P) (
  input logic signed [P.INTDIVb+3:0] shiftin,
  output logic signed [P.INTDIVb+3:0] shifted
);
  assign shifted = $signed(shiftin) >>> P.LOGR;

endmodule

