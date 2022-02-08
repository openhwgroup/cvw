// xz.sv
// David_Harris@hmc.edu 30 January 2022
// Demonstrate impact of x and z.

// load with vsim xz.sv

module xz(
  output logic w, x, y, z);

  logic p, q, r;

  // let p be undriven
  assign q = 1'bz;
  assign r = 1'bx;

  assign w = q & 1'b1;
  assign x = q | 1'b1;
endmodule

