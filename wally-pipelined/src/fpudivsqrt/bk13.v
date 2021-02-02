// Brent-Kung Carry-save Prefix Adder

module exp_add (cout, sum, a, b, cin);
	 input [12:0] a, b;
	 input cin;
	 output [12:0] sum;
	 output cout;

	 wire [13:0] p,g,t;
	 wire [12:0] c;

// pre-computation
	 assign p={a^b,1'b0};
	 assign g={a&b, cin};
	 assign t[1]=p[1];
	 assign t[2]=p[2];
	 assign t[3]=p[3]^g[2];
	 assign t[4]=p[4];
	 assign t[5]=p[5]^g[4];
	 assign t[6]=p[6];
	 assign t[7]=p[7]^g[6];
	 assign t[8]=p[8];
	 assign t[9]=p[9]^g[8];
	 assign t[10]=p[10];
	 assign t[11]=p[11]^g[10];
	 assign t[12]=p[12];
	 assign t[13]=p[13];

// prefix tree
	 brent_kung_cs prefix_tree(c, p[12:0], g[12:0]);

// post-computation
	 assign sum=p[13:1]^c;
	 assign cout=g[13]|(p[13]&c[12]);

endmodule

module brent_kung_cs (c, p, g);
	
	input [12:0] p;
	input [12:0] g;
	output [13:1] c;


	// parallel-prefix, Brent-Kung

	// Stage 1: Generates G/P pairs that span 1 bits
	grey b_1_0 (G_1_0, {g[1],g[0]}, p[1]);
	black b_3_2 (G_3_2, P_3_2, {g[3],g[2]}, {p[3],p[2]});
	black b_5_4 (G_5_4, P_5_4, {g[5],g[4]}, {p[5],p[4]});
	black b_7_6 (G_7_6, P_7_6, {g[7],g[6]}, {p[7],p[6]});
	black b_9_8 (G_9_8, P_9_8, {g[9],g[8]}, {p[9],p[8]});
	black b_11_10 (G_11_10, P_11_10, {g[11],g[10]}, {p[11],p[10]});
	black b_13_12 (G_13_12, P_13_12, {g[13],g[12]}, {p[13],p[12]});

	// Stage 2: Generates G/P pairs that span 2 bits
	grey g_3_0 (G_3_0, {G_3_2,G_1_0}, P_3_2);
	black b_7_4 (G_7_4, P_7_4, {G_7_6,G_5_4}, {P_7_6,P_5_4});
	black b_11_8 (G_11_8, P_11_8, {G_11_10,G_9_8}, {P_11_10,P_9_8});

	// Stage 3: Generates G/P pairs that span 4 bits
	grey g_7_0 (G_7_0, {G_7_4,G_3_0}, P_7_4);

	// Stage 4: Generates G/P pairs that span 8 bits

	// Stage 5: Generates G/P pairs that span 4 bits
	grey g_11_0 (G_11_0, {G_11_8,G_7_0}, P_11_8);

	// Stage 6: Generates G/P pairs that span 2 bits
	grey g_5_0 (G_5_0, {G_5_4,G_3_0}, P_5_4);
	grey g_9_0 (G_9_0, {G_9_8,G_7_0}, P_9_8);

	// Last grey cell stage 
	grey g_2_0 (G_2_0, {g[2],G_1_0}, p[2]);
	grey g_4_0 (G_4_0, {g[4],G_3_0}, p[4]);
	grey g_6_0 (G_6_0, {g[6],G_5_0}, p[6]);
	grey g_8_0 (G_8_0, {g[8],G_7_0}, p[8]);
	grey g_10_0 (G_10_0, {g[10],G_9_0}, p[10]);
	grey g_12_0 (G_12_0, {g[12],G_11_0}, p[12]);

	// Final Stage: Apply c_k+1=G_k_0
	assign c[1]=g[0];
	assign c[2]=G_1_0;
	assign c[3]=G_2_0;
	assign c[4]=G_3_0;
	assign c[5]=G_4_0;
	assign c[6]=G_5_0;
	assign c[7]=G_6_0;
	assign c[8]=G_7_0;
	assign c[9]=G_8_0;

	assign c[10]=G_9_0;
	assign c[11]=G_10_0;
	assign c[12]=G_11_0;
	assign c[13]=G_12_0;

endmodule


// Black cell
module black(gout, pout, gin, pin);

 input [1:0] gin, pin;
 output gout, pout;

 assign pout=pin[1]&pin[0];
 assign gout=gin[1]|(pin[1]&gin[0]);

endmodule

// Grey cell
module grey(gout, gin, pin);

 input[1:0] gin;
 input pin;
 output gout;

 assign gout=gin[1]|(pin&gin[0]);

endmodule
