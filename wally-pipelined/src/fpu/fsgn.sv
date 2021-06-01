//performs the fsgnj/fsgnjn/fsgnjx RISCV instructions

module fpusgn (SgnOpCodeE, SgnResultE, SgnFlagsE, FInput1E, FInput2E);

	input  [63:0]  FInput1E, FInput2E;
	input  [1:0]   SgnOpCodeE;
	output [63:0]  SgnResultE;
	output [4:0]   SgnFlagsE;

	wire AonesExp;

	//op code designation:
	//
	//00 - fsgnj - directly copy over sign value of FInput2E
	//01 - fsgnjn - negate sign value of FInput2E
	//10 - fsgnjx - XOR sign values of FInput1E & FInput2E
	//
	
	assign SgnResultE[63] = SgnOpCodeE[1] ? (FInput1E[63] ^ FInput2E[63]) : (FInput2E[63] ^ SgnOpCodeE[0]);
	assign SgnResultE[62:0] = FInput1E[62:0];

	//If the exponent is all ones, then the value is either Inf or NaN,
	//both of which will produce a QNaN/SNaN value of some sort. This will 
	//set the invalid flag high.
	assign AonesExp = FInput1E[62]&FInput1E[61]&FInput1E[60]&FInput1E[59]&FInput1E[58]&FInput1E[57]&FInput1E[56]&FInput1E[55]&FInput1E[54]&FInput1E[53]&FInput1E[52];

	//the only flag that can occur during this operation is invalid
	//due to changing sign on already existing NaN
	assign SgnFlagsE = {AonesExp & SgnResultE[63], 1'b0, 1'b0, 1'b0, 1'b0};

endmodule
