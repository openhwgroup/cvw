module BUFGCE (input logic I, input logic CE, output logic O);

  logic 	CE_Q;
  always_latch begin
    if(~I) begin
      CE_Q <= CE;
    end
  end
  assign O = CE_Q & I;

endmodule
