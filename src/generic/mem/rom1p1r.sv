///////////////////////////////////////////
// rom1p1r
//
// Written: David_Harris@hmc.edu 8/24/22
//
// Purpose: Single-ported ROM
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

// This model actually works correctly with vivado.

module rom1p1r #(parameter ADDR_WIDTH = 8,
     parameter DATA_WIDTH = 32, 
     parameter PRELOAD_ENABLED = 0)
  (input  logic                  clk,
   input  logic                  ce,
   input  logic [ADDR_WIDTH-1:0] addr,
   output logic [DATA_WIDTH-1:0] dout
);

   // Core Memory
   logic [DATA_WIDTH-1:0]    ROM [(2**ADDR_WIDTH)-1:0];
/*   if ((`USE_SRAM == 1) & (ADDR_WDITH == 7) & (DATA_WIDTH == 64)) begin
      rom1p1r_128x64 rom1 (.CLK(clk), .CEB(~ce), .A(addr[6:0]), .Q(dout));

   end if ((`USE_SRAM == 1) & (ADDR_WDITH == 7) & (DATA_WIDTH == 32)) begin
      rom1p1r_128x32 rom1 (.CLK(clk), .CEB(~ce), .A(addr[6:0]), .Q(dout));      

   end else begin */
   always @ (posedge clk) begin
   if(ce) dout <= ROM[addr];    
   end
   
   // for FPGA, initialize with zero-stage bootloader
   if(PRELOAD_ENABLED) 
     initial begin
       ROM[0] =  64'h95c1819300002197; 
       ROM[1] =  64'h4281420141014081; 
       ROM[2] =  64'h4481440143814301; 
       ROM[3] =  64'h4681460145814501; 
       ROM[4] =  64'h4881480147814701; 
       ROM[5] =  64'h4a814a0149814901; 
       ROM[6] =  64'h4c814c014b814b01; 
       ROM[7] =  64'h4e814e014d814d01; 
       ROM[8] =  64'h0110011b4f814f01; 
       ROM[9] =  64'h059b45011161016e; 
       ROM[10] = 64'h0004063705fe0010; 
       ROM[11] = 64'h05a000ef8006061b; 
       ROM[12] = 64'h0ff003930000100f; 
       ROM[13] = 64'h4e952e3110060e37; 
       ROM[14] = 64'hc602829b0053f2b7; 
       ROM[15] = 64'h2023fe02dfe312fd; 
       ROM[16] = 64'h829b0053f2b7007e; 
       ROM[17] = 64'hfe02dfe312fdc602; 
       ROM[18] = 64'h4de31efd000e2023; 
       ROM[19] = 64'h059bf1402573fdd0; 
       ROM[20] = 64'h0000061705e20870; 
       ROM[21] = 64'h0010029b01260613; 
       ROM[22] = 64'h71790002806702fe; 
       ROM[23] = 64'h89aa84b2e44eec26; 
       ROM[24] = 64'h892ee84af4064511; 
       ROM[25] = 64'h072000ef084000ef; 
       ROM[26] = 64'hf02204a602905263; 
       ROM[27] = 64'h41390933844e94ce; 
       ROM[28] = 64'h04138522008905b3; 
       ROM[29] = 64'h19e3016000ef2004; 
       ROM[30] = 64'h64e270a27402fe94; 
       ROM[31] = 64'h8082614569a26942; 
       ROM[32] = 64'h431c104707136749; 
       ROM[33] = 64'hb82366c9dff58b85; 
       ROM[34] = 64'h4691674967c910a6; 
       ROM[35] = 64'h1047071310d7a423; 
       ROM[36] = 64'h6749fff58b89431c; 
       ROM[37] = 64'h1187071320058693; 
       ROM[38] = 64'hfef5bc2305a1631c; 
       ROM[39] = 64'h67498082fed59ce3; 
       ROM[40] = 64'h8b85431c10470713; 
       ROM[41] = 64'h4015551b8082dff5;   
       ROM[42] = 64'ha0239f0967c94705;
       ROM[43] = 64'h00000000808210e7;
     end 

endmodule 
