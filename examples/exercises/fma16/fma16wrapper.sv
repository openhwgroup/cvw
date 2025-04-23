// fma16wrapper.sv
// David_Harris@hmc.edu 21 April 2025
//  synthesis wrapper for fma providing clock and registers for timing analysis

module fma16wrapper(
  input  logic        clk,
  input  logic [15:0] x, y, z,
  input  logic        mul, add, negp, negz,
  input  logic [1:0]  roundmode,  // 00: rz, 01: rne, 10: rp, 11: rn
  output logic [15:0] result,
  output logic [3:0]  flags // invalid, overflow, underflow, inexact
);

  logic [15:0] xint, yint, zint;
  logic        mulint, addint, negpint, negzint;
  logic [1:0]  roundmodeint;
  logic [15:0] resultint;
  logic [3:0]  flagsint;

  // flip-flops to put timing constraints on inputs
  always_ff @(posedge clk) begin
    {xint, yint, zint} <= {x, y, z};
    {mulint, addint, negpint, negzint} <= {mul, add, negp, negz};
    roundmodeint <= roundmode;
  end

  // module being synthesized
  fma16 fma16(xint, yint, zint,
              mulint, addint, negpint, negzint,
              roundmodeint,
              resultint, flagsint);

  // flip-flops to put timing constraints on outputs
  always_ff @(posedge clk) begin
    {result, flags} <= {resultint, flagsint};
  end

endmodule  
