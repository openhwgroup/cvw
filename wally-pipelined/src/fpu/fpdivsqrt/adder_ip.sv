module adder_ip #(parameter WIDTH=8)
   (input  logic [WIDTH-1:0] a, b,
    input logic 	     cin,
    output logic [WIDTH-1:0] y,
    output logic 	     cout);
   
   assign {cout, y} = a + b + cin;
   
endmodule // adder
