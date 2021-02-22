module mux2 #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] d0, d1, 
    input logic 	     s, 
    output logic [WIDTH-1:0] y);
   
   assign y = s ? d1 : d0;
   
endmodule // mux2

module mux3 #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] d0, d1, d2,
    input logic [1:0] 	     s, 
    output logic [WIDTH-1:0] y);
   
   assign y = s[1] ? d2 : (s[0] ? d1 : d0);
   
endmodule // mux3

module mux4 #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] d0, d1, d2, d3,
    input logic [1:0] 	     s, 
    output logic [WIDTH-1:0] y);
   
   assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0);
   
endmodule // mux4

module mux21x32 (Z, A, B, Sel);

   input logic [31:0]  A;
   input logic [31:0]  B;
   input logic	       Sel;

   output logic [31:0] Z;
   
   assign Z = Sel ? B : A;
   
endmodule // mux21x32

module mux21x64 (Z, A, B, Sel);

   input logic [63:0]  A;
   input logic [63:0]  B;
   input logic 	       Sel;

   output logic [63:0] Z;
   
   assign Z = Sel ? B : A;
   
endmodule // mux21x64

