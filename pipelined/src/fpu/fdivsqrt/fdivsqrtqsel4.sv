///////////////////////////////////////////
// fdivsqrtqsel4.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 4 Quotient Digit Selection
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

module fdivsqrtqsel4 (
  input logic [`DIVN-2:0] D,
  input logic [4:0] Smsbs,
  input logic [`DIVb+3:0] WS, WC,
  input logic Sqrt, j1,
  output logic [3:0] u
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

	logic [3:0] USel4[1023:0];

  always_comb begin 
    integer a, w, i, w2;
    for(a=0; a<8; a++)
      for(w=0; w<128; w++)begin
        i = a*128+w;
        w2 = w-128*(w>=64); // convert to two's complement
        case(a)
          0: if($signed(w2)>=$signed(12))      USel4[i] = 4'b1000;
            else if(w2>=4)   USel4[i] = 4'b0100; 
            else if(w2>=-4)  USel4[i] = 4'b0000; 
            else if(w2>=-13) USel4[i] = 4'b0010; 
            else             USel4[i] = 4'b0001; 
          1: if(w2>=14)      USel4[i] = 4'b1000;
            else if(w2>=4)   USel4[i] = 4'b0100;  
            else if(w2>=-4)  USel4[i] = 4'b0000; 
            else if(w2>=-14) USel4[i] = 4'b0010;  
            else             USel4[i] = 4'b0001; 
          2: if(w2>=16)      USel4[i] = 4'b1000;
            else if(w2>=4)   USel4[i] = 4'b0100; 
            else if(w2>=-6)  USel4[i] = 4'b0000; 
            else if(w2>=-16) USel4[i] = 4'b0010; 
            else             USel4[i] = 4'b0001; 
          3: if(w2>=16)      USel4[i] = 4'b1000;
            else if(w2>=4)   USel4[i] = 4'b0100; 
            else if(w2>=-6)  USel4[i] = 4'b0000; 
            else if(w2>=-17) USel4[i] = 4'b0010; 
            else             USel4[i] = 4'b0001; 
          4: if(w2>=18)      USel4[i] = 4'b1000;
            else if(w2>=6)   USel4[i] = 4'b0100; 
            else if(w2>=-6)  USel4[i] = 4'b0000; 
            else if(w2>=-18) USel4[i] = 4'b0010; 
            else             USel4[i] = 4'b0001; 
          5: if(w2>=20)      USel4[i] = 4'b1000;
            else if(w2>=6)   USel4[i] = 4'b0100; 
            else if(w2>=-8)  USel4[i] = 4'b0000; 
            else if(w2>=-20) USel4[i] = 4'b0010; 
            else             USel4[i] = 4'b0001; 
          6: if(w2>=20)      USel4[i] = 4'b1000;
            else if(w2>=8)   USel4[i] = 4'b0100; 
            else if(w2>=-8)  USel4[i] = 4'b0000; 
            else if(w2>=-22) USel4[i] = 4'b0010; 
            else             USel4[i] = 4'b0001; 
          7: if(w2>=24)      USel4[i] = 4'b1000; 
            else if(w2>=8)   USel4[i] = 4'b0100; 
            else if(w2>=-8)  USel4[i] = 4'b0000; 
            else if(w2>=-22) USel4[i] = 4'b0010; 
            else             USel4[i] = 4'b0001; 
        endcase
      end
  end
  always_comb
    if (Sqrt) begin 
      if (j1) A = 3'b101;
      else if (Smsbs == 5'b10000) A = 3'b111;
      else A = Smsbs[2:0];
    end else A = Dmsbs;
	assign u = USel4[{A,Wmsbs}];
	
endmodule
