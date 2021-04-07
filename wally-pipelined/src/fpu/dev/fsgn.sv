//performs the fsgnj/fsgnjn/fsgnjx RISCV instructions

module fpusgn (op_code, Y, Flags, A, B);

	input  [63:0]  A, B;
	input  [1:0]   op_code;
	output [63:0]  Y;
	output [4:0]   Flags;

	wire AonesExp;

	//op code designation:
	//
	//00 - fsgnj - directly copy over sign value of B
	//01 - fsgnjn - negate sign value of B
	//10 - fsgnjx - XOR sign values of A & B
	//
	
	assign Y[63] = op_code[1] ? (A[63] ^ B[63]) : (B[63] ^ op_code[0]);
	assign Y[62:0] = A[62:0];

	//If the exponent is all ones, then the value is either Inf or NaN,
	//both of which will produce a QNaN/SNaN value of some sort. This will 
	//set the invalid flag high.
	assign AonesExp = A[62]&A[61]&A[60]&A[59]&A[58]&A[57]&A[56]&A[55]&A[54]&A[53]&A[52];

	//the only flag that can occur during this operation is invalid
	//due to changing sign on already existing NaN
	assign Flags = {AonesExp & Y[63], 1'b0, 1'b0, 1'b0, 1'b0};

endmodule
