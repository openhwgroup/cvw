module shifter_right(input logic signed [63:0] a,
		     input logic [ 5:0] 	shamt,
		     output logic signed [63:0] y);


   y = a >> shamt;

endmodule // shifter_right

module shifter_left(input logic signed [63:0] a,
		    input logic [ 5:0] 	       shamt,
		    output logic signed [63:0] y);


   y = a << shamt;

endmodule // shifter_right

