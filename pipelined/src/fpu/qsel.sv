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
  input  logic [`DIVLEN+3:`DIVLEN] ps, pc, 
  output logic         qp, qz//, qn
);
 
  logic [`DIVLEN+3:`DIVLEN]  p, g;
  logic          magnitude, sign, cout;

  // The quotient selection logic is presented for simplicity, not
  // for efficiency.  You can probably optimize your logic to
  // select the proper divisor with less delay.

  // Qmient equations from EE371 lecture notes 13-20
  assign p = ps ^ pc;
  assign g = ps & pc;

  assign magnitude = ~(&p[`DIVLEN+2:`DIVLEN]);
  assign cout = g[`DIVLEN+2] | (p[`DIVLEN+2] & (g[`DIVLEN+1] | p[`DIVLEN+1] & g[`DIVLEN]));
  assign sign = p[`DIVLEN+3] ^ cout;
/*  assign #1 magnitude = ~((ps[54]^pc[54]) & (ps[53]^pc[53]) & 
			  (ps[52]^pc[52]));
  assign #1 sign = (ps[55]^pc[55])^
      (ps[54] & pc[54] | ((ps[54]^pc[54]) &
			    (ps[53]&pc[53] | ((ps[53]^pc[53]) &
						(ps[52]&pc[52]))))); */

  // Produce quotient = +1, 0, or -1
  assign qp = magnitude & ~sign;
  assign qz = ~magnitude;
//   assign #1 qn = magnitude & sign;
endmodule

module qsel4 (
	input logic [`DIVLEN+3:0] D,
	input logic [`DIVLEN+3:0] WS, WC,
	output logic [3:0] q
);
	logic [6:0] Wmsbs;
	logic [7:0] PreWmsbs;
	logic [2:0] Dmsbs;
	assign PreWmsbs = WC[`DIVLEN+3:`DIVLEN-4] + WS[`DIVLEN+3:`DIVLEN-4];
	assign Wmsbs = PreWmsbs[7:1];
	assign Dmsbs = D[`DIVLEN-1:`DIVLEN-3];
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
            else            QSel4[i] = 4'b0001; 
          1: if(w2>=14)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-15) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          2: if(w2>=15)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-16) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          3: if(w2>=16)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-18) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          4: if(w2>=18)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-20) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          5: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-20) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          6: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-22) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          7: if(w2>=24)      QSel4[i] = 4'b1000;
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-24) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
        endcase
      end
  end
	assign q = QSel4[{Dmsbs,Wmsbs}];
	
endmodule
