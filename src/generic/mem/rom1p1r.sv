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

`include "wally-config.vh"

module rom1p1r #(parameter ADDR_WIDTH = 8,
		 parameter DATA_WIDTH = 32, 
		 parameter PRELOAD_ENABLED = 0)
  (input  logic                  clk,
   input  logic                  ce,
   input  logic [ADDR_WIDTH-1:0] addr,
   output logic [DATA_WIDTH-1:0] dout
);

   // Core Memory
   logic [DATA_WIDTH-1:0] 	 ROM [(2**ADDR_WIDTH)-1:0];
   if (`USE_SRAM == 1 && DATA_WIDTH == 64) begin
      rom1p1r_128x64 rom1 (.CLK(clk), .CEB(~ce), .A(addr[6:0]), .Q(dout));

   end if (`USE_SRAM == 1 && DATA_WIDTH == 32) begin
      rom1p1r_128x32 rom1 (.CLK(clk), .CEB(~ce), .A(addr[6:0]), .Q(dout));      

   end else begin
      always @ (posedge clk) begin
	 if(ce) dout <= ROM[addr];    
      end
   
   // for FPGA, initialize with zero-stage bootloader
   if(PRELOAD_ENABLED) begin
      initial begin
	 /*ROM[0] =  64'h9581819300002197; 
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
	 ROM[22] = 64'h11010002806702fe; 
	 ROM[23] = 64'h84b2842ae426e822; 
	 ROM[24] = 64'h892ee04aec064511; 
	 ROM[25] = 64'h06e000ef07e000ef; 
	 ROM[26] = 64'h979334fd02905563; 
	 ROM[27] = 64'h07930177d4930204; 
	 ROM[28] = 64'h4089093394be2004; 
	 ROM[29] = 64'h04138522008905b3; 
	 ROM[30] = 64'h19e3014000ef2004; 
	 ROM[31] = 64'h64a2644260e2fe94; 
	 ROM[32] = 64'h6749808261056902; 
	 ROM[33] = 64'hdfed8b8510472783; 
	 ROM[34] = 64'h2423479110a73823; 
	 ROM[35] = 64'h10472783674910f7; 
	 ROM[36] = 64'h20058693ffed8b89; 
	 ROM[37] = 64'h05a1118737836749; 
	 ROM[38] = 64'hfed59be3fef5bc23; 
	 ROM[39] = 64'h1047278367498082; 
	 ROM[40] = 64'h47858082dfed8b85; 
	 ROM[41] = 64'h40a7853b4015551b;   
	 ROM[42] = 64'h808210a7a02367c9;*/

        ROM[0]  = 64'h8001819300002197;
        ROM[1]  = 64'h4281420141014081;
        ROM[2]  = 64'h4481440143814301;
        ROM[3]  = 64'h4681460145814501;
        ROM[4]  = 64'h4881480147814701;
        ROM[5]  = 64'h4a814a0149814901;
        ROM[6]  = 64'h4c814c014b814b01;
        ROM[7]  = 64'h4e814e014d814d01;
        ROM[8]  = 64'h0110011b4f814f01;
        ROM[9]  = 64'h059b45011161016e;
        ROM[10] = 64'h0004063705fe0010;
        ROM[11] = 64'h1f6000ef8006061b;
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
        ROM[22] = 64'h68110002806702fe;
        ROM[23] = 64'h0085179bf0080813;
        ROM[24] = 64'h038008130107f7b3;
        ROM[25] = 64'h480508a86c632781;
        ROM[26] = 64'h1533357902a87963;
        ROM[27] = 64'h38030000181700a8;
        ROM[28] = 64'h1c6301057833f268;
        ROM[29] = 64'h081a403018370808;
        ROM[30] = 64'h0105783342280813;
        ROM[31] = 64'h1815751308081063;
        ROM[32] = 64'h00367513c295e14d;
        ROM[33] = 64'h654ded510207e793;
        ROM[34] = 64'hc1701ff00613f130;
        ROM[35] = 64'h0637c530fff6861b;
        ROM[36] = 64'h664dcd10167d0200;
        ROM[37] = 64'h17fd001007b7c25c;
        ROM[38] = 64'h859b5a5cc20cd21c;
        ROM[39] = 64'h02062a23dfed0007;
        ROM[40] = 64'h4785fffd561c664d;
        ROM[41] = 64'h4501461c06f59063;
        ROM[42] = 64'h4a1cc35c465cc31c;
        ROM[43] = 64'he29dc75c4a5cc71c;
        ROM[44] = 64'h0c63086008138082;
        ROM[45] = 64'h1ae30a9008130105;
        ROM[46] = 64'hb7710017e793f905;
        ROM[47] = 64'he793b75901d7e793;
        ROM[48] = 64'h5f5c674db7410197;
        ROM[49] = 64'h66cd02072e23dffd;
        ROM[50] = 64'hfff78513ff7d5698;
        ROM[51] = 64'h40a0053300a03533;
        ROM[52] = 64'hbfb100a7e7938082;
        ROM[53] = 64'he0a2715d8082557d;
        ROM[54] = 64'he486f052f44ef84a;
        ROM[55] = 64'hfa13e85aec56fc26;
        ROM[56] = 64'h843289ae892a0086;
        ROM[57] = 64'h00959993000a1463;
        ROM[58] = 64'h864ac4396b054a85;
        ROM[59] = 64'h0009859b4549870a;
        ROM[60] = 64'h0004049b05540363;
        ROM[61] = 64'h86a66485008b7363;
        ROM[62] = 64'h870a87aaec7ff0ef;
        ROM[63] = 64'h4531458146014681;
        ROM[64] = 64'hf0ef0207c9639c05;
        ROM[65] = 64'h17820094979beb1f;
        ROM[66] = 64'h873e020541639381;
        ROM[67] = 64'h993e99ba020a1963;
        ROM[68] = 64'h870aa8094501f85d;
        ROM[69] = 64'he8bff0ef45454685;
        ROM[70] = 64'h60a64505fe0559e3;
        ROM[71] = 64'h79a2794274e26406;
        ROM[72] = 64'h61616b426ae27a02;
        ROM[73] = 64'h9301020497138082;
        ROM[74] = 64'hf426f8227139b7f1;
        ROM[75] = 64'hec4efc064705f04a;
        ROM[76] = 64'h84aad79867cde852;
        ROM[77] = 64'h571c674d8932842e;
        ROM[78] = 64'h03600793dff58b85;
        ROM[79] = 64'h674d02072423d35c;
        ROM[80] = 64'hb00026f3fffd571c;
        ROM[81] = 64'h11f707130007a737;
        ROM[82] = 64'h7de38f95b00027f3;
        ROM[83] = 64'h8b895b1c674dfef7;
        ROM[84] = 64'h0027e7934f5ccf9d;
        ROM[85] = 64'he737b00026f3cf5c;
        ROM[86] = 64'h27f30ff7071305f5;
        ROM[87] = 64'hfef77de38f95b000;
        ROM[88] = 64'hcf5c9bf54f5c674d;
        ROM[89] = 64'h00989737b00026f3;
        ROM[90] = 64'hb00027f367f70713;
        ROM[91] = 64'h4681fef77de38f95;
        ROM[92] = 64'h4501870a45814601;
        ROM[93] = 64'h4681870adcfff0ef;
        ROM[94] = 64'h45211aa005934601;
        ROM[95] = 64'h4782e12ddbfff0ef;
        ROM[96] = 64'h17d249911aa00713;
        ROM[97] = 64'h099302e7876393d1;
        ROM[98] = 64'h70e2744285220ff0;
        ROM[99] = 64'h69e2864a86ce6a42;
        ROM[100]= 64'h612174a285a67902;
        ROM[101]= 64'h40e3d8dff0efb551;
        ROM[102]= 64'h0207c7634782fe05;
        ROM[103]= 64'h458146014681870a;
        ROM[104]= 64'hd73ff0ef03700513;
        ROM[105]= 64'h46014681870a87aa;
        ROM[106]= 64'h0a900513403005b7;
        ROM[107]= 64'h4989bf4dfc07d9e3;
        ROM[108]= 64'hc3998b8583f9bfe1;
        ROM[109]= 64'h4681870a0089e993;
        ROM[110]= 64'hf0ef450945814601;
        ROM[111]= 64'h870af8054ae3d41f;
        ROM[112]= 64'h123405b746014681;
        ROM[113]= 64'h40e3d2dff0ef450d;
        ROM[114]= 64'h870a77c14a02f805;
        ROM[115]= 64'h4601468100fa7a33;
        ROM[116]= 64'hd13ff0ef451d85d2;
        ROM[117]= 64'h470567cdf60543e3;
        ROM[118]= 64'h4737b00026f3d3d8;
        ROM[119]= 64'h27f323f70713000f;
        ROM[120]= 64'hfef77de38f95b000;
        ROM[121]= 64'h870a0007ae2367cd;
        ROM[122]= 64'h051385d246014681;
        ROM[123]= 64'h48e3cddff0ef0370;
        ROM[124]= 64'h46014681870af205;
        ROM[125]= 64'hf0ef086005134581;
        ROM[126]= 64'h870af0054ee3cc9f;
        ROM[127]= 64'h2000059346014681;
        ROM[128]= 64'h56e3cb5ff0ef4541;
        ROM[129]= 64'h00000000b711f005;
     end // initial begin
   end // if (PRELOAD_ENABLED)  
  end 

endmodule 
