// scannable register
module scan_reg #(parameter WIDTH) (
  input  logic clk, se, en,
  input  logic scan_in,
  output logic scan_out,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);

  logic [WIDTH:0] scan_chain;

  assign scan_chain[WIDTH] = scan_in;
  assign scan_out = scan_chain[0];
  assign q = scan_chain[WIDTH-1:0];

  genvar i;
  for (i=0; i<WIDTH; i=i+1) begin
    flopscan f (.clk, .en, .se, .d(d[i]),
      .scan_in(scan_chain[i+1]),
      .q(scan_chain[i]));
  end

endmodule


// scannable_flop
module flopscan (
  input  logic clk, en, se,
  input  logic scan_in,
  input  logic d,
  output logic q
);

  logic d_in;
  assign d_in = se ? scan_in : d;

  always_ff @(posedge clk)
    if (en || se)
      q <= d_in;

endmodule
