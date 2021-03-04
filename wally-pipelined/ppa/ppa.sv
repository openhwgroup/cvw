// ppa.sv
// Teo Ene & David_Harris@hmc.edu 25 Feb 2021
// Measure PPA of various building blocks

// replace this with the tools setting a library path to a config/skl130 directory containing config.vh
`define LIB SKL130

module top(
    input  logic       a1,
    input  logic [7:0] a8, b8,
    input  logic [15:0] a16, b16,
    input  logic [31:0] a32, b32,
    input  logic [63:0] a64, b64,
    output logic        yinv,
    output logic [63:0] y1, y2, y3, y4
);

  // fo4 inverter
  myinv myinv(a1, yinv);)

    // adders
  add #(8) add8(a8, b8, yadd8);
  add #(16) add16(a16, b16, yadd16);
  add #(32) add32(a32, b32, yadd32);
  add #(64) add64(a64, b64, yadd64);

  // mux2, mux3, mux4 of 1, 8, 16, 32, 64
  
endmodule

module myinv(input a, output y);
  driver #(1) drive(a, in1);
  assign out = ~in;
  load #(1) load(out, y);
endmodule

module add #(parameter WIDTH=8) (
    input logic [7:0] a, b,
    output logic [7:0] y
);
  logic [WIDTH-1:0] in1, in2, out;

  driver #(WIDTH) drive1(a, in1);
  driver #(WIDTH) drive2(b, in2);
  assign out = in1 + in2;
  load #(WIDTH) load(out, y);
endmodule


module INVX2(input logic a, output logic y);
    generate
        if (LIB == SKL130)
            sky130_osu_sc_12T_ms__inv_2 inv(a, y);
        else if (LIB == SKL90)
            scc9gena_inv_2 inv(a, y)
        else if (LIB == GF14)
             INV_X2N_A10P5PP84TSL_C14(a, y)
    endgenerate
endmodule

module driver #(parameter WDITH=1) (
    input  [WIDTH-1:0] logic a,
    output [WIDTH-1:0] logic y
);
  logic [WIDTH-1:0] ab;

  INVX2 i1[WIDTH-1:0](a, ab);
  INVX2 i2[WIDTH-1:0](ab, y);
endmodule

module inv4(input logic a, output logic y);
  logic [3:0] b
  INVX2 i0(a, b[0]);
  INVX2 i1(a, b[1]);
  INVX2 i2(a, b[2]);
  INVX2 i3(a, b[3]);
  INVX2 i00(b[0], y;
  INVX2 i01(b[0], y);
  INVX2 i02(b[0], y);
  INVX2 i03(b[0], y);
  INVX2 i10(b[1], y;
  INVX2 i11(b[1], y);
  INVX2 i12(b[1], y);
  INVX2 i13(b[1], y);
  INVX2 i20(b[2], y;
  INVX2 i21(b[2], y);
  INVX2 i22(b[2], y);
  INVX2 i23(b[2], y);
  INVX2 i30(b[3], y;
  INVX2 i31(b[3], y);
  INVX2 i32(b[3], y);
  INVX2 i33(b[3], y);
endmodule

module load #(parameter WDITH=1) (
    input  [WIDTH-1:0] logic a,
    output [WIDTH-1:0] logic y
);
  logic [WIDTH-1:0] ab;

  inv4 load[WIDTH-1:0](a, y);
endmodule
