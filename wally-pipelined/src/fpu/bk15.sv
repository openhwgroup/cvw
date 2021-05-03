// Kogge-Stone Prefix Adder
module bk15 (cout, sum, a, b, cin);
   
   input [14:0] a, b;
   input 	cin;
   
   output [14:0] sum;
   output 	 cout;

   wire [15:0] 	 p,g;
   wire [15:1] 	 h,c;

   // pre-computation
   assign p={a|b,1'b1};
   assign g={a&b, cin};

   // prefix tree
   kogge_stone prefix_tree(h, c, p[14:0], g[14:0]);

   // post-computation
   assign h[15]=g[15]|c[15];
   assign sum=p[15:1]^h|g[15:1]&c;
   assign cout=p[15]&h[15];

endmodule // bk15

module kogge_stone (h, c, p, g);
   
   input [14:0] p;
   input [14:0] g;
   
   output [15:1] h;
   output [15:1] c;
   logic H_1_0,H_2_1,I_2_1,H_3_2,I_3_2,H_4_3,I_4_3,H_5_4,I_5_4,H_6_5,I_6_5,H_7_6,I_7_6,H_8_7,I_8_7,H_9_8,I_9_8,H_10_9
      ,I_10_9,H_11_10,I_11_10,H_12_11,I_12_11,H_13_12,I_13_12,H_14_13,I_14_13,H_2_0,H_3_0,H_4_1,I_4_1,H_5_2,I_5_2,H_6_3
      ,I_6_3,H_7_4,I_7_4,H_8_5,I_8_5,H_9_6,I_9_6,H_10_7,I_10_7,H_11_8,I_11_8,H_12_9,I_12_9,H_13_10,I_13_10,H_14_11,I_14_11
      ,H_4_0,H_5_0,H_6_0,H_7_0,H_8_1,I_8_1,H_9_2,I_9_2,H_10_3,I_10_3,H_11_4,I_11_4,H_12_5,I_12_5,H_13_6,I_13_6,H_14_7
      ,I_14_7,H_8_0,H_9_0,H_10_0,H_11_0,H_12_0,H_13_0,H_14_0;

   // parallel-prefix, Kogge-Stone

   // Stage 1: Generates G/P pairs that span 1 bits
   rgry g_1_0 (H_1_0, {g[1],g[0]});
   rblk b_2_1 (H_2_1, I_2_1, {g[2],g[1]}, {p[1],p[0]});
   rblk b_3_2 (H_3_2, I_3_2, {g[3],g[2]}, {p[2],p[1]});
   rblk b_4_3 (H_4_3, I_4_3, {g[4],g[3]}, {p[3],p[2]});
   rblk b_5_4 (H_5_4, I_5_4, {g[5],g[4]}, {p[4],p[3]});
   rblk b_6_5 (H_6_5, I_6_5, {g[6],g[5]}, {p[5],p[4]});
   rblk b_7_6 (H_7_6, I_7_6, {g[7],g[6]}, {p[6],p[5]});
   rblk b_8_7 (H_8_7, I_8_7, {g[8],g[7]}, {p[7],p[6]});

   rblk b_9_8 (H_9_8, I_9_8, {g[9],g[8]}, {p[8],p[7]});
   rblk b_10_9 (H_10_9, I_10_9, {g[10],g[9]}, {p[9],p[8]});
   rblk b_11_10 (H_11_10, I_11_10, {g[11],g[10]}, {p[10],p[9]});
   rblk b_12_11 (H_12_11, I_12_11, {g[12],g[11]}, {p[11],p[10]});
   rblk b_13_12 (H_13_12, I_13_12, {g[13],g[12]}, {p[12],p[11]});
   rblk b_14_13 (H_14_13, I_14_13, {g[14],g[13]}, {p[13],p[12]});

   // Stage 2: Generates G/P pairs that span 2 bits
   grey g_2_0 (H_2_0, {H_2_1,g[0]}, I_2_1);
   grey g_3_0 (H_3_0, {H_3_2,H_1_0}, I_3_2);
   black b_4_1 (H_4_1, I_4_1, {H_4_3,H_2_1}, {I_4_3,I_2_1});
   black b_5_2 (H_5_2, I_5_2, {H_5_4,H_3_2}, {I_5_4,I_3_2});
   black b_6_3 (H_6_3, I_6_3, {H_6_5,H_4_3}, {I_6_5,I_4_3});
   black b_7_4 (H_7_4, I_7_4, {H_7_6,H_5_4}, {I_7_6,I_5_4});
   black b_8_5 (H_8_5, I_8_5, {H_8_7,H_6_5}, {I_8_7,I_6_5});
   black b_9_6 (H_9_6, I_9_6, {H_9_8,H_7_6}, {I_9_8,I_7_6});

   black b_10_7 (H_10_7, I_10_7, {H_10_9,H_8_7}, {I_10_9,I_8_7});
   black b_11_8 (H_11_8, I_11_8, {H_11_10,H_9_8}, {I_11_10,I_9_8});
   black b_12_9 (H_12_9, I_12_9, {H_12_11,H_10_9}, {I_12_11,I_10_9});
   black b_13_10 (H_13_10, I_13_10, {H_13_12,H_11_10}, {I_13_12,I_11_10});
   black b_14_11 (H_14_11, I_14_11, {H_14_13,H_12_11}, {I_14_13,I_12_11});

   // Stage 3: Generates G/P pairs that span 4 bits
   grey g_4_0 (H_4_0, {H_4_1,g[0]}, I_4_1);
   grey g_5_0 (H_5_0, {H_5_2,H_1_0}, I_5_2);
   grey g_6_0 (H_6_0, {H_6_3,H_2_0}, I_6_3);
   grey g_7_0 (H_7_0, {H_7_4,H_3_0}, I_7_4);
   black b_8_1 (H_8_1, I_8_1, {H_8_5,H_4_1}, {I_8_5,I_4_1});
   black b_9_2 (H_9_2, I_9_2, {H_9_6,H_5_2}, {I_9_6,I_5_2});
   black b_10_3 (H_10_3, I_10_3, {H_10_7,H_6_3}, {I_10_7,I_6_3});
   black b_11_4 (H_11_4, I_11_4, {H_11_8,H_7_4}, {I_11_8,I_7_4});

   black b_12_5 (H_12_5, I_12_5, {H_12_9,H_8_5}, {I_12_9,I_8_5});
   black b_13_6 (H_13_6, I_13_6, {H_13_10,H_9_6}, {I_13_10,I_9_6});
   black b_14_7 (H_14_7, I_14_7, {H_14_11,H_10_7}, {I_14_11,I_10_7});

   // Stage 4: Generates G/P pairs that span 8 bits
   grey g_8_0 (H_8_0, {H_8_1,g[0]}, I_8_1);
   grey g_9_0 (H_9_0, {H_9_2,H_1_0}, I_9_2);
   grey g_10_0 (H_10_0, {H_10_3,H_2_0}, I_10_3);
   grey g_11_0 (H_11_0, {H_11_4,H_3_0}, I_11_4);
   grey g_12_0 (H_12_0, {H_12_5,H_4_0}, I_12_5);
   grey g_13_0 (H_13_0, {H_13_6,H_5_0}, I_13_6);
   grey g_14_0 (H_14_0, {H_14_7,H_6_0}, I_14_7);

   // Final Stage: Apply c_k+1=p_k&H_k_0
   assign c[1]=g[0];

   assign h[1]=H_1_0;		assign c[2]=p[1]&H_1_0;
   assign h[2]=H_2_0;		assign c[3]=p[2]&H_2_0;
   assign h[3]=H_3_0;		assign c[4]=p[3]&H_3_0;
   assign h[4]=H_4_0;		assign c[5]=p[4]&H_4_0;
   assign h[5]=H_5_0;		assign c[6]=p[5]&H_5_0;
   assign h[6]=H_6_0;		assign c[7]=p[6]&H_6_0;
   assign h[7]=H_7_0;		assign c[8]=p[7]&H_7_0;
   assign h[8]=H_8_0;		assign c[9]=p[8]&H_8_0;

   assign h[9]=H_9_0;		assign c[10]=p[9]&H_9_0;
   assign h[10]=H_10_0;		assign c[11]=p[10]&H_10_0;
   assign h[11]=H_11_0;		assign c[12]=p[11]&H_11_0;
   assign h[12]=H_12_0;		assign c[13]=p[12]&H_12_0;
   assign h[13]=H_13_0;		assign c[14]=p[13]&H_13_0;
   assign h[14]=H_14_0;		assign c[15]=p[14]&H_14_0;

endmodule // kogge_stone
