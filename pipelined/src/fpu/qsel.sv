///////////////////////////////////////////
// srt.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module qsel2 ( // *** eventually just change to 4 bits
  input  logic [3:0] ps, pc, 
  output logic         qp, qz, qn
);
 
  logic [3:0]  p, g;
  logic          magnitude, sign, cout;

  // The quotient selection logic is presented for simplicity, not
  // for efficiency.  You can probably optimize your logic to
  // select the proper divisor with less delay.

  // Qmient equations from EE371 lecture notes 13-20
  assign p = ps ^ pc;
  assign g = ps & pc;

  //assign magnitude = ~(&p[2:0]);
  assign cout = g[2] | (p[2] & (g[1] | p[1] & g[0]));
  //assign sign = p[3] ^ cout;
  assign magnitude = ~((ps[2]^pc[2]) & (ps[1]^pc[1]) & 
			  (ps[0]^pc[0]));
  assign sign = (ps[3]^pc[3])^
      (ps[2] & pc[2] | ((ps[2]^pc[2]) &
			    (ps[1]&pc[1] | ((ps[1]^pc[1]) &
						(ps[0]&pc[0])))));

  // Produce quotient = +1, 0, or -1
  assign qp = magnitude & ~sign;
  assign qz = ~magnitude;
  assign qn = magnitude & sign;
endmodule

////////////////////////////////////
// Adder Input Generation, Radix 2 //
////////////////////////////////////
module fgen2 (
  input  logic sp, sz,
  input  logic [`DIVb-1:0] C,
  input  logic [`DIVb:0] S, SM,
  output logic [`DIVb+3:0] F
);
  logic [`DIVb+3:0] FP, FN, FZ;
  logic [`DIVb+3:0] SExt, SMExt, CExt;

  assign SExt = {3'b0, S};
  assign SMExt = {3'b0, SM};
  assign CExt = {4'hf, C}; // extend C from U0.k to Q4.k

  // Generate for both positive and negative bits
  assign FP = ~(SExt << 1) & CExt;
  assign FN = (SMExt << 1) | (CExt & ~(CExt << 2));
  assign FZ = '0;

  // Choose which adder input will be used

  always_comb
    if (sp)       F = FP;
    else if (sz)  F = FZ;
    else          F = FN;

endmodule

module qsel4 (
	input logic [`DIVN-2:0] D,
  input logic [4:0] Smsbs,
	input logic [`DIVb+3:0] WS, WC,
  input logic Sqrt, j1,
	output logic [3:0] q
);
	logic [6:0] Wmsbs;
	logic [7:0] PreWmsbs;
	logic [2:0] Dmsbs, A;

	assign PreWmsbs = WC[`DIVb+3:`DIVb-4] + WS[`DIVb+3:`DIVb-4];
	assign Wmsbs = PreWmsbs[7:1];
	assign Dmsbs = D[`DIVN-2:`DIVN-4];//|{3{D[`DIVN-2]&Sqrt}};
	// D = 0001.xxx...
	// Dmsbs = |   |
  // W =      xxxx.xxx...
	// Wmsbs = |        |

	logic [3:0] QSel4[1023:0];

  always_comb begin 
    integer a, w, i, w2;
    for(a=0; a<8; a++)
      for(w=0; w<128; w++)begin
        i = a*128+w;
        w2 = w-128*(w>=64); // convert to two's complement
        case(a)
          0: if($signed(w2)>=$signed(12))      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-4)  QSel4[i] = 4'b0000; 
            else if(w2>=-13) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          1: if(w2>=14)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100;  
            else if(w2>=-4)  QSel4[i] = 4'b0000; 
            else if(w2>=-14) QSel4[i] = 4'b0010;  
            else             QSel4[i] = 4'b0001; 
          2: if(w2>=16)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-16) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          3: if(w2>=16)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-17) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          4: if(w2>=18)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-18) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          5: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-20) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          6: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-22) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          7: if(w2>=24)      QSel4[i] = 4'b1000; 
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-22) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
        endcase
      end
  end
  always_comb
    if (Sqrt) begin 
      if (j1) A = 3'b101;
      else if (Smsbs == 5'b10000) A = 3'b111;
      else A = Smsbs[2:0];
    end else A = Dmsbs;
	assign q = QSel4[{A,Wmsbs}];
	
endmodule

// qsel4old was working for divide
module qsel4old (
	input logic [`DIVN-2:0] D,
	input logic [`DIVb+3:0] WS, WC,
  input logic Sqrt,
	output logic [3:0] q
);
	logic [6:0] Wmsbs;
	logic [7:0] PreWmsbs;
	logic [2:0] Dmsbs;
	assign PreWmsbs = WC[`DIVb+3:`DIVb-4] + WS[`DIVb+3:`DIVb-4];
	assign Wmsbs = PreWmsbs[7:1];
	assign Dmsbs = D[`DIVN-2:`DIVN-4];//|{3{D[`DIVN-2]&Sqrt}};
	// D = 0001.xxx...
	// Dmsbs = |   |
  // W =      xxxx.xxx...
	// Wmsbs = |        |

	logic [3:0] QSel4[1023:0];

  always_comb begin 
    integer d, w, i, w2;
    for(d=0; d<8; d++)
      for(w=0; w<128; w++)begin
        i = d*128+w;
        w2 = w-128*(w>=64); // convert to two's complement
        case(d)
          0: if($signed(w2)>=$signed(12))      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-4)  QSel4[i] = 4'b0000; 
            else if(w2>=-13) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          1: if(w2>=14)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-5)  QSel4[i] = 4'b0000; // was -6
            else if(~Sqrt&(w2>=-15)) QSel4[i] = 4'b0010; // divide case
            else if( Sqrt&(w2>=-14)) QSel4[i] = 4'b0010; // sqrt case
            else             QSel4[i] = 4'b0001; 
          2: if(w2>=15)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-16) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          3: if(w2>=16)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-17) QSel4[i] = 4'b0010; // was -18
            else             QSel4[i] = 4'b0001; 
          4: if(w2>=18)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; // was -8
            else if(~Sqrt&(w2>=-20)) QSel4[i] = 4'b0010; // divide case
            else if( Sqrt&(w2>=-18)) QSel4[i] = 4'b0010; // sqrt case
            else             QSel4[i] = 4'b0001; 
          5: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-20) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          6: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-22) QSel4[i] = 4'b0010; 
            else             QSel4[i] = 4'b0001; 
          7: if(w2>=22)      QSel4[i] = 4'b1000; // was 24
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-23) QSel4[i] = 4'b0010; // was -24 ***use -22
            else             QSel4[i] = 4'b0001; 
        endcase
      end
  end
	assign q = QSel4[{Dmsbs,Wmsbs}];
	
endmodule

////////////////////////////////////
// Adder Input Generation, Radix 4 //
////////////////////////////////////
module fgen4 (
  input  logic [3:0] s,
  input  logic [`DIVb+3:0] C, S, SM,
  output logic [`DIVb+3:0] F
);
  logic [`DIVb+3:0] F2, F1, F0, FN1, FN2;
  
  // Generate for both positive and negative bits
  assign F2  = (~S << 2) & (C << 2);
  assign F1  = ~(S << 1) & C;
  assign F0  = '0;
  assign FN1 = (SM << 1) | (C & ~(C << 3));
  assign FN2 = (SM << 2) | ((C << 2)&~(C << 4));

  // Choose which adder input will be used

  always_comb
    if (s[3])       F = F2;
    else if (s[2])  F = F1;
    else if (s[1])  F = FN1;
    else if (s[0])  F = FN2;
    else            F = F0;
endmodule