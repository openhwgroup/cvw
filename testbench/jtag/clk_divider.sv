module clk_divider #(parameter DIV) (
  input  logic clk_in, reset,
  output logic clk_out
);
  integer count;

  always_ff @(posedge clk_in) begin
    if (reset) begin
      count <= 0;
      clk_out <= 0;
    end else if (count == DIV) begin
      clk_out <= ~clk_out;
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end

endmodule