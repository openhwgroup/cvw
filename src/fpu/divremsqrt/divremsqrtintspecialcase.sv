module divremsqrtintspecialcase import cvw::*; #(parameter cvw_t P) (
    input logic BZeroM,RemOpM, ALTBM, SIGNOVERFLOWM,
    input logic [P.XLEN-1:0] AM,
    input  signed [P.XLEN-1:0] PreIntResultM,
    output logic [P.XLEN-1:0] IntDivResultM
);
always_comb
      if (BZeroM) begin         // Divide by zero
        if (RemOpM) IntDivResultM = AM;  
        else        IntDivResultM = {(P.XLEN){1'b1}};
      end else if (SIGNOVERFLOWM) begin
         if (RemOpM) IntDivResultM = 0;
         else        IntDivResultM = AM;
     end else if (ALTBM) begin // Numerator is small
        if (RemOpM) IntDivResultM = AM;
        else        IntDivResultM = 0;
     end else       IntDivResultM = PreIntResultM;
endmodule