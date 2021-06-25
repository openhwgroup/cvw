//performs the fsgnj/fsgnjn/fsgnjx RISCV instructions

module fpusgn (SgnOpCodeE, SgnResultE, SgnFlagsE, SrcXE, SrcYE);

	input  [63:0]  SrcXE, SrcYE;
	input  [1:0]   SgnOpCodeE;
	output [63:0]  SgnResultE;
	output [4:0]   SgnFlagsE;

	wire AonesExp;

	//op code designation:
	//
	//00 - fsgnj - directly copy over sign value of SrcYE
	//01 - fsgnjn - negate sign value of SrcYE
	//10 - fsgnjx - XOR sign values of SrcXE & SrcYE
	//
	
	assign SgnResultE[63] = SgnOpCodeE[1] ? (SrcXE[63] ^ SrcYE[63]) : (SrcYE[63] ^ SgnOpCodeE[0]);
	assign SgnResultE[62:0] = SrcXE[62:0];

	//If the exponent is all ones, then the value is either Inf or NaN,
	//both of which will produce a QNaN/SNaN value of some sort. This will 
	//set the invalid flag high.
	assign AonesExp = SrcXE[62]&SrcXE[61]&SrcXE[60]&SrcXE[59]&SrcXE[58]&SrcXE[57]&SrcXE[56]&SrcXE[55]&SrcXE[54]&SrcXE[53]&SrcXE[52];

	//the only flag that can occur during this operation is invalid
	//due to changing sign on already existing NaN
	assign SgnFlagsE = {AonesExp & SgnResultE[63], 1'b0, 1'b0, 1'b0, 1'b0};

endmodule
