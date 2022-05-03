// fma16.sv
// David_Harris@hmc.edu 26 February 2022
// 16-bit floating-point multiply-accumulate

// Operation: general purpose multiply, add, fma, with optional negation
//   If mul=1, p = x * y.  Else p = x.
//   If add=1, result = p + z.  Else result = p.
//   If negr or negz = 1, negate result or z to handle negations and subtractions
//   fadd: mul = 0, add = 1, negr = negz = 0
//   fsub: mul = 0, add = 1, negr = 0, negz = 1
//   fmul: mul = 1, add = 0, negr = 0, negz = 0
//   fmadd:  mul = 1, add = 1, negr = 0, negz = 0
//   fmsub:  mul = 1, add = 1, negr = 0, negz = 1
//   fnmadd: mul = 1, add = 1, negr = 1, negz = 0
//   fnmsub: mul = 1, add = 1, negr = 1, negz = 1

`define FFLEN 16
`define Nf 10
`define Ne 5
`define BIAS 15
`define EMIN (-(2**(`Ne-1)-1))
`define EMAX (2**(`Ne-1)-1)

`define NaN 16'h7E00
`define INF 15'h7C00

// rounding modes *** update
`define RZ  3'b00
`define RNE 3'b01
`define RM  3'b10
`define RP  3'b11

module fma16(
  input  logic [`FFLEN-1:0] x, y, z,
  input  logic        mul, add, negr, negz,
  input  logic [1:0]  roundmode,  // 00: rz, 01: rne, 10: rp, 11: rn
  output logic [`FFLEN-1:0] result);
 
  logic [`Nf:0] xm, ym, zm; // U1.Nf
  logic [`Ne-1:0]  xe, ye, ze; // B_Ne
  logic        xs, ys, zs;
  logic        zs1; // sign before optional negation
  logic [2*`Nf+1:0] pm; // U2.2Nf
  logic [`Ne:0]  pe; // B_Ne+1
  logic        ps;  // sign of product
  logic [22:0] rm;
  logic [`Ne+1:0]  re;
  logic        rs;
  logic        xzero, yzero, zzero, xinf, yinf, zinf, xnan, ynan, znan;
  logic [`Ne+1:0]  re2;

  unpack16 unpack(x, y, z, xm, ym, zm, xe, ye, ze, xs, ys, zs1, xzero, yzero, zzero, xinf, yinf, zinf, xnan, ynan, znan);  // unpack inputs
  //signadj16 signadj(negr, negz, xs, ys, zs1, ps, zs);             // handle negations
  mult16 mult16(mul, xm, ym, xe, ye, xs, ys, pm, pe, ps);                       // p = x * y
  add16 add16(add, pm, zm, pe, ze, ps, zs, negz, rm, re, re2, rs);             // r = z + p
  postproc16 post(roundmode,  xzero, yzero, zzero, xinf, yinf, zinf, xnan, ynan, znan, rm, zm, re, ze, rs, zs, ps, re2, result);                 // normalize, round, pack
endmodule

module mult16(
  input  logic        mul,
  input  logic [`Nf:0] xm, ym,
  input  logic [`Ne-1:0]  xe, ye,
  input  logic        xs, ys,
  output logic [2*`Nf+1:0] pm,
  output logic [`Ne:0]  pe,
  output logic        ps);

  // only multiply if mul = 1
  assign pm = mul ? xm * ym : {1'b0, xm, 10'b0};       // multiply mantiassas 
  assign pe = mul ? xe + ye - `BIAS : {1'b0, xe};      // add exponents, account for bias
  assign ps = xs ^ ys;                                 // negative if X xor Y are negative
endmodule

module add16(
  input  logic        add,
  input  logic [2*`Nf+1:0] pm,  // U2.2Nf
  input  logic [`Nf:0] zm, // U1.Nf
  input  logic [`Ne:0]  pe, // B_Ne+1
  input  logic [`Ne-1:0]  ze, // B_Ne
  input  logic        ps, zs, 
  input  logic        negz,
  output logic [22:0] rm,
  output logic [`Ne+1:0]  re, // B_Ne+2
  output logic [`Ne+1:0]  re2,
  output logic        rs);

  logic [`Nf*3+7:0] paligned, zaligned, zalignedaddsub, r, r2, rnormed, rnormed2; // U(Nf+6).(2Nf+2) aligned significands
  logic signed [`Ne:0] ExpDiff; // Q(Ne+2).0
  logic [`Ne:0] AlignCnt; // U(Ne+3) bits to right shift Z for alignment *** check size.  
  logic [`Nf-1:0] prezsticky;
  logic           zsticky;
  logic          effectivesub;
  logic           rs0;
  logic [`Ne:0]     leadingzeros, NormCnt; // *** should paramterize size
  logic [`Ne:0]   re1;

  // Alignment shift
  assign paligned = {{(`Nf+4){1'b0}}, pm, 2'b00}; // constant shift to prepend leading and trailing 0s.
  assign ExpDiff = pe - {1'b0, ze}; // Compute exponent difference as signed number
  always_comb // AlignCount mux; see Muller page 254
    if (ExpDiff <= (-2*`Nf - 1)) begin AlignCnt = 3*`Nf + 7;         re = {1'b0, pe}; end
    else if (ExpDiff <= 2)       begin AlignCnt = `Nf + 4 - ExpDiff; re = {1'b0, pe}; end
    else if (ExpDiff <= `Nf+3)   begin AlignCnt = `Nf + 4 - ExpDiff; re = {2'b0, ze}; end
    else                         begin AlignCnt = 0;                 re = {2'b0, ze}; end
  // Shift Zm right by AlignCnt.  Produce 3Nf+8 bits of Zaligned in U(Nf+6).(2Nf+2) and Nf bits becoming sticky
  assign {zaligned, prezsticky} = {zm, {(3*`Nf+7){1'b0}}} >> AlignCnt; //Right shift
  assign zsticky = |prezsticky; // Sticky bit if any of the discarded bits were 1
  
  // Effective subtraction
  assign effectivesub = ps ^ zs ^ negz; // subtract |z| from |p|
  assign zalignedaddsub = effectivesub ? ~zaligned : zaligned;  // invert zaligned for subtraction

  // Adder
  assign r = paligned + zalignedaddsub + {{`Nf*3+7{1'b0}}, effectivesub}; // add aligned significands
  assign rs0 = r[`Nf*3+7]; // sign of the initial result
  assign r2 = rs0 ? ~r+1 : r; // invert sum if negative; could optimize with end-around carry?

  // Sign Logic
  assign rs = ps ^ rs0; // flip the sign if necessary

  // Leading zero counter
  lzc lzc(r2, leadingzeros); // count number of leading zeros in 2Nf+5 lower digits of r2
  assign re1 = pe +2 - leadingzeros; // *** declare, # of bits

  // Normalization shift
  always_comb // NormCount mux
    if (ExpDiff < 3) begin 
      if (re1 >= `EMIN) begin  NormCnt = `Nf + 3 + leadingzeros;  re2 = {1'b0, re1}; end
      else              begin  NormCnt = `Nf + 5 + pe - `EMIN; re2 = `EMIN;    end
    end else            begin  NormCnt = AlignCnt; re = {2'b00, ze};                  end
  assign rnormed = r2 << NormCnt; // *** update sticky
  /* temporarily comment out to start synth

  // One-bit secondary normalization
  if (ExpDiff <= 2)          begin rnormed2 = rnormed; re2 = re; end // no secondary normalization
  else begin // *** handle sticky
    if (rnormed[***])        begin rnormed2 = rnormed >> 1; re2 = re+1; end
    else if (rnormed[***-1]) begin rnormed2 = rnormed; re2 = re;        end
    else                     begin rnormed2 = rnormed << 1; re2 = re-1; end
  end

  // round
  assign l = rnormed2[***]; // least significant bit 
  assign r = rnormed2[***-1]; // rounding bit
  assign s = ***; // sticky bit
  always_comb
    case (roundmode)
      RZ: roundup = 0;
      RP: roundup = ~rs & (r | s); 
      RM: roundup = rs & (r | s);
      RNE: roundup = r & (s | l);
      default: roundup = 0;
    endcase
  assign {re3, rrounded} = {re2, rnormed2[***]} + roundup; // increment if necessary
*/

  // *** need to handle rounding to MAXNUM vs. INFINITY
  
  // add or pass product through
 /* assign rm = add ? arm : {1'b0, pm};
  assign re = add ? are : {1'b0, pe};
  assign rs = add ? ars : ps; */
endmodule

module lzc(
  input  logic [`Nf*3+7:0] r2,
  output logic [`Ne:0]   leadingzeros
);

endmodule


module postproc16(
  input  logic [1:0] roundmode,
  input  logic        xzero, yzero, zzero, xinf, yinf, zinf, xnan, ynan, znan,
  input  logic [22:0] rm, 
  input  logic [`Nf:0] zm, // U1.Nf
  input  logic [6:0]  re, 
  input  logic [`Ne-1:0]  ze, // B_Ne
  input  logic        rs, zs, ps,
  input  logic [`Ne+1:0]  re2,
  output logic [15:0] result);

  logic [9:0] uf, uff;
  logic [6:0] ue;
  logic [6:0] ueb, uebiased;
  logic       invalid;

    // Special cases
  // *** not handling signaling NaN
  // *** also add overflow/underflow/inexact
  always_comb begin
    if (xnan | ynan | znan)                    begin result = `NaN; invalid = 0; end // propagate NANs
    else if ((xinf | yinf) & zinf & (ps ^ zs)) begin result = `NaN; invalid = 1; end // infinity - infinity
    else if (xzero & yinf | xinf & yzero)      begin result = `NaN; invalid = 1; end // zero times infinity
    else if (xinf | yinf)                      begin result = {ps, `INF}; invalid = 0; end // X or Y
    else if (zinf)                             begin result = {zs, `INF}; invalid = 0; end // infinite Z
    else if (xzero | yzero)                    begin result = {zs, ze, zm[`Nf-1:0]}; invalid = 0; end
    else if (re2 >= `EMAX)                     begin result = {rs, `INF}; invalid = 0; end
    else                                       begin result = {rs, re[`Ne-1:0], rm[`Nf-1:0]}; invalid = 0; end
  end
  
  always_comb 
    if (rm[21]) begin // normalization right shift by 1 and bump up exponent;
        ue = re + 7'b1;
        uf = rm[20:11];
    end else begin // no normalization shift needed
        ue = re;
        uf = rm[19:10];
    end

  // overflow
  always_comb begin
    ueb = ue-7'd15;
    if (ue >= 7'd46) begin // overflow
/*      uebiased = 7'd30;
      uff = 10'h3ff; */
    end else begin
      uebiased = ue-7'd15;
      uff = uf;
    end
  end
  
  assign result = {rs, uebiased[4:0], uff};

  // add special case handling for zeros, NaN, Infinity
endmodule

module signadj16(
  input  logic negr, negz,
  input  logic xs, ys, zs1,
  output logic ps, zs);

  assign ps = xs ^ ys; // sign of product
  assign zs = zs1 ^ negz; // sign of addend
endmodule

module unpack16(
  input  logic [15:0] x, y, z,
  output logic [10:0] xm, ym, zm,
  output logic [4:0]  xe, ye, ze,
  output logic        xs, ys, zs,
  output logic        xzero, yzero, zzero, xinf, yinf, zinf, xnan, ynan, znan);

  unpacknum16 upx(x, xm, xe, xs, xzero, xinf, xnan);
  unpacknum16 upy(y, ym, ye, ys, yzero, yinf, ynan);
  unpacknum16 upz(z, zm, ze, zs, zzero, zinf, znan);
endmodule

module unpacknum16(
  input logic  [15:0] num,
  output logic [10:0] m,
  output logic [4:0]  e,
  output logic        s, 
  output logic        zero, inf, nan);

  logic [9:0] f;  // fraction without leading 1
  logic [4:0] eb; // biased exponent

  assign {s, eb, f} = num; // pull bit fields out of floating-point number
  assign m = {1'b1, f}; // prepend leading 1 to fraction
  assign e = eb;   // leave bias in exponent ***
  assign zero = (e == 0 && f == 0);
  assign inf = (e == 31 && f == 0);
  assign nan = (e == 31 && f != 0);
endmodule


