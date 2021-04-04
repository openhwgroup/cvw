//performs the fsgnj/fsgnjn/fsgnjx RISCV instructions

module fpusgn (SgnOpCodeE, SgnResultE, SgnFlagsE, SgnOp1E, SgnOp2E);

	input  [63:0]  SgnOp1E, SgnOp2E;
	input  [1:0]   SgnOpCodeE;
	output [63:0]  SgnResultE;
	output [4:0]   SgnFlagsE;

	wire AonesExp;

	//op code designation:
	//
	//00 - fsgnj - directly copy over sign value of SgnOp2E
	//01 - fsgnjn - negate sign value of SgnOp2E
	//10 - fsgnjx - XOR sign values of SgnOp1E & SgnOp2E
	//
	
	assign SgnResultE[63] = SgnOpCodeE[1] ? (SgnOp1E[63] ^ SgnOp2E[63]) : (SgnOp2E[63] ^ SgnOpCodeE[0]);
	assign SgnResultE[62:0] = SgnOp1E[62:0];

	//If the exponent is all ones, then the value is either Inf or NaN,
	//both of which will produce a QNaN/SNaN value of some sort. This will 
	//set the invalid flag high.
	assign AonesExp = SgnOp1E[62]&SgnOp1E[61]&SgnOp1E[60]&SgnOp1E[59]&SgnOp1E[58]&SgnOp1E[57]&SgnOp1E[56]&SgnOp1E[55]&SgnOp1E[54]&SgnOp1E[53]&SgnOp1E[52];

	//the only flag that can occur during this operation is invalid
	//due to changing sign on already existing NaN
	assign SgnFlagsE = {AonesExp & SgnResultE[63], 1'b0, 1'b0, 1'b0, 1'b0};

endmodule
