module ha (C, S, A, B) ;
   
   input  A, B;
   output S, C;

   assign S = A^B;
   assign C = A&B;

endmodule // HA

// module fa (input logic a, b, c, output logic sum, carry);
   
//    assign sum = a^b^c;
//    assign carry = a&b|a&c|b&c;   
   
// endmodule // fa

// module csa #(parameter WIDTH=8) (a, b,c, sum, carry, cout);

//    input logic [WIDTH-1:0] a, b, c;
   
//    output logic [WIDTH-1:0] sum, carry;
//    output logic 	    cout;   

//    logic [WIDTH:0] 	    carry_temp;   
//    genvar 		    i;
//    generate
//       for (i=0;i<WIDTH;i=i+1)
// 	begin : genbit
// 	   fa fa_inst (a[i], b[i], c[i], sum[i], carry_temp[i+1]);
// 	end
//    endgenerate
//    assign carry = {1'b0, carry_temp[WIDTH-1:1], 1'b0};
//    assign cout = carry_temp[WIDTH];   
   
// endmodule // csa

module FA_array (S, C, A, B, Ci) ;
   parameter n = 32;
   input  [n-1:0] A;
   input  [n-1:0] B;
   input  [n-1:0] Ci;
   output [n-1:0] S;
   output [n-1:0] C;

   wire   [n-1:0] n0;
   wire   [n-1:0] n1;
   wire   [n-1:0] n2;

   genvar 	  i;
   generate
      for (i = 0; i < n; i = i + 1) begin : index
	 fa FA1(.sum(S[i]), .carry(C[i]), .a(A[i]), .b(B[i]), .c(Ci[i]));
      end
   endgenerate
   
endmodule // FA_array

module HA_array (S, C, A, B) ;
   parameter n = 32;
   input  [n-1:0] A, B;
   output [n-1:0] S, C;
   genvar 	  i;
   generate
      for (i = 0; i < n; i = i + 1) begin : index
	 ha ha1(.S(S[i]), .C(C[i]), .A(A[i]), .B(B[i]));
      end
   endgenerate
   
endmodule // HA_array