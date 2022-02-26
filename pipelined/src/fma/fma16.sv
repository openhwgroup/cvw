// fma16.sv
// David_Harris@hmc.edu 26 February 2022
// 16-bit floating-point multiply-accumulate

// Operation: general purpose multiply, add, fma, with optional negation
//   If mul=1, p = x * y.  Else p = x.
//   If add=1, result = p + z.  Else result = p.
//   If negp or negz = 1, negate p or z to handle negations and subtractions
//   fadd: mul = 0, add = 1, negp = negz = 0
//   fsub: mul = 0, add = 1, negp = 0, negz = 1
//   fmul: mul = 1, add = 0, negp = 0, negz = 0
//   fma:  mul = 1, add = 1, negp = 0, negz = 0

module fma16(
  input  logic [15:0] x, y, z,
  input  logic        add, mul, negp, negz,
  input  logic [1:0]  roundmode,  // 00: rz, 01: rne, 10: rp, 11: rn
  output logic [15:0] result);
 
  logic [10:0] xm, ym, zm;
  logic [4:0] xe, ye, ze;
  logic       xs, ys, zs;
  logic       zs1; // sign before optional negation
  logic       ps;  // sign of product

  unpack unpack(x, y, z, xm, ym, zm, xe, ye, ze, xs, ys, zs1);  // unpack inputs
  signadj signadj(negp, negz, xs, ys, zs1, ps, zs);             // handle negations
  mult mult(mul, xm, ym, xe, ye, pm, pe);                       // p = x * y
  add add(add, pm, zm, pe, ze, ps, zs, rm, re, rs);             // r = z + p
  postproc post(roundmode, rm, re, rs, result);                 // normalize, round, pack
endmodule

module mult(
  input  logic        mul,
  input  logic [10:0] xm, ym,
  input  logic [4:0]  xe, ye,
  input  logic        xs, ys,
  output logic [21:0] pm,
  output logic [5:0]  pe);

  // only multiply if mul = 1
  assign pm = mul ? xm * ym : xm;       // multiply mantiassas 
  assign pe = mul ? xe + ye : xe;  
endmodule

module add(
  input  logic        add,
  input  logic [21:0] pm, 
  input  logic [10:0] zm,
  input  logic [5:0]  pe, 
  input  logic [4:0]  ze,
  input  logic        ps, zs,
  output logic [22:0] rm,
  output logic [6:0]  re,
  output logic        rs);

  logic [22:0] arm;
  logic [6:0]  are;
  logic        ars;

  alignshift as(pe, ze, zm, zmaligned);
  condneg cnp(pm, ps, pmn);
  condneg cnz(zm, zs, zmn);
  
  // add or pass product through
  assign rm = add ? arm : pm;
  assign re = add ? are : pe;
  assign rs = add ? ars : ps;
);

module postproc(
  input  logic [1:0] roundmode,
  input  logic [22:0] rm,
  input  logic [6:0]  re,
  input  logic        rs,
  output logic [15:0] result);

  // add special case handling for zeros, NaN, Infinity
endmodule

module signadj(
  input  logic negx, negz,
  input  logic xs, ys, zs1,
  output logic ps, zs);

  assign ps = xs ^ ys ^ negx; // sign of product
  assign zs = zs1 ^ negz; // 
endmodule

module unpack(
  input  logic [15:0] x, y, z,
  output logic [10:0] xm, ym, zm,
  output logic [4:0]  xe, ye, ze,
  output logic        xs, ys, zs);

  unpacknum upx(x, xm, xe, xs);
  unpacknum upy(y, ym, ye, ys);
  unpacknum upz(z, zm, ze, zs);
endmodule

module unpacknum(
  input logic  [15:0] num,
  output logic [10:0] m,
  output logic [4:0]  e,
  output logic        s);

  logic [9:0] f;  // fraction without leading 1
  logic [4:0] eb; // biased exponent

  assign {f, eb, s} = num; // pull bit fields out of floating-point number
  assign m = {1'b1, f}; // prepend leading 1 to fraction
  assign e = eb - 15;   // remove bias from exponent
endmodule


// Tests:
// Every permutation for x, y, z of 
//    mantissa = {1.0, 1.0000000001, 1.1, 1.1111111110, 1.1111111111}
//    biased exponent = {1, 2, 14, 15, 16, 21, 29, 30}
//    sign = {0, 1}
//    special case: [normal, 0, INF, NaN]