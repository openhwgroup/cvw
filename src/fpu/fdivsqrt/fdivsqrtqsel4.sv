///////////////////////////////////////////
// fdivsqrtqsel4.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 4 Quotient Digit Selection
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module fdivsqrtqsel4 (
  input  logic [2:0] Dmsbs,
  input  logic [4:0] Smsbs,
  input  logic [7:0] WSmsbs, WCmsbs,
  input  logic       Sqrt, j1,
  output logic [3:0] udigit
);
  logic [6:0] Wmsbs;
  logic [7:0] PreWmsbs;
  logic [2:0] A;

  assign PreWmsbs = WCmsbs + WSmsbs;
  assign Wmsbs = PreWmsbs[7:1];
  // D = 0001.xxx...
  // Dmsbs = |   |
  // W =      xxxx.xxx...
  // Wmsbs = |        |

  logic [3:0] USel4[1023:0];

  // Prepopulate selection table; this is constant at compile time
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

  // Select A
  always_comb
    if (Sqrt) begin 
      if (j1) A = 3'b101;
      else if (Smsbs == 5'b10000) A = 3'b111;
      else A = Smsbs[2:0];
    end else A = Dmsbs;

  // Select quotient digit from lookup table based on A and W
  assign udigit = USel4[{A,Wmsbs}];
endmodule
