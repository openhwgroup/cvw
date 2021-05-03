
`include "wally-config.vh"
//  `include "../../config/rv64icfd/wally-config.vh" //debug

module freg1adr (
  input  logic 	       	   FmtW,
  input  logic             reset,
  input  logic             clear,
  input  logic             clk,
  input  logic [4:0]       rd,
  input  logic             write,
  input  logic [4:0]       adr1,
  input  logic [`XLEN-1:0] writeData,
  output logic [`XLEN-1:0] readData);

  //note - not word aligning based on precision of 
  //operation (FmtW)

  //reg number should remain static, but it doesn't hurt
  //to parameterize
  parameter numRegs = 32;

  //intermediary signals - useful for debugging
  //and easy instatiation of generated modules
  logic [`XLEN-1:0] [numRegs-1:0] regInput;
  logic [`XLEN-1:0] [numRegs-1:0] regOutput;

  //generate fp registers themselves
  genvar i;
  generate
  	for (i = 0; i < numRegs; i = i + 1) begin:register

  		floprc #(`XLEN) freg[i](.clk(clk), .reset(reset), .clear(clear), .d(regInput[i][`XLEN-1:0]), .q(regOutput[i][`XLEN-1:0])); 
	end

  endgenerate

  //this could be done with:
  //
  //assign readData = regOutput[adr1];
  //
  //but always_comb allows for finer control


  //address decoder
  //only 1 for this fp register set
  //used with fpsign
  //defaults to outputting zeroes
  always_comb begin
  	case(adr1)
		5'b00000 : readData = regOutput[0];
		5'b00001 : readData = regOutput[1];
		5'b00010 : readData = regOutput[2];
		5'b00011 : readData = regOutput[3];
		5'b00100 : readData = regOutput[4];
		5'b00101 : readData = regOutput[5];
		5'b00110 : readData = regOutput[6];
		5'b00111 : readData = regOutput[7];
		5'b01000 : readData = regOutput[8];
		5'b01001 : readData = regOutput[9];
		5'b01010 : readData = regOutput[10];
		5'b01011 : readData = regOutput[11];
		5'b01100 : readData = regOutput[12];
		5'b01101 : readData = regOutput[13];
		5'b01110 : readData = regOutput[14];
		5'b01111 : readData = regOutput[15];
		5'b10000 : readData = regOutput[16];
		5'b10001 : readData = regOutput[17];
		5'b10010 : readData = regOutput[18];
		5'b10011 : readData = regOutput[19];
		5'b10100 : readData = regOutput[20];
		5'b10101 : readData = regOutput[21];
		5'b10110 : readData = regOutput[22];
		5'b10111 : readData = regOutput[23];
		5'b11000 : readData = regOutput[24];
		5'b11001 : readData = regOutput[25];
		5'b11010 : readData = regOutput[26];
		5'b11011 : readData = regOutput[27];
		5'b11100 : readData = regOutput[28];
		5'b11101 : readData = regOutput[29];
		5'b11110 : readData = regOutput[30];
		5'b11111 : readData = regOutput[31];
		default : readData = `XLEN'h0;
	endcase
  end

  //destination register decoder
  //only change input values on write
  //defaults to undefined with invalid address
  //
  //note - this is an intermediary signal, so
  //this is not asynch assignment. FF in flopr
  //will not update data until clk pulse
  always_comb begin
	  if(write) begin
		case(rd)	
			5'b00000 : regInput[0] = writeData;
			5'b00001 : regInput[1] = writeData;
			5'b00010 : regInput[2] = writeData;
			5'b00011 : regInput[3] = writeData;	
			5'b00100 : regInput[4] = writeData;
			5'b00101 : regInput[5] = writeData;
			5'b00110 : regInput[6] = writeData;
			5'b00111 : regInput[7] = writeData;
			5'b01000 : regInput[8] = writeData;
			5'b01000 : regInput[9] = writeData;
			5'b01001 : regInput[10] = writeData;
			5'b01010 : regInput[11] = writeData;
			5'b01111 : regInput[12] = writeData;
			5'b01101 : regInput[13] = writeData;
			5'b01110 : regInput[14] = writeData;
			5'b01111 : regInput[15] = writeData;
			5'b10000 : regInput[16] = writeData;
			5'b10001 : regInput[17] = writeData;
			5'b10010 : regInput[18] = writeData;
			5'b10011 : regInput[19] = writeData;	
			5'b10100 : regInput[20] = writeData;
			5'b10101 : regInput[21] = writeData;
			5'b10110 : regInput[22] = writeData;
			5'b10111 : regInput[23] = writeData;
			5'b11000 : regInput[24] = writeData;
			5'b11000 : regInput[25] = writeData;
			5'b11001 : regInput[26] = writeData;
			5'b11010 : regInput[27] = writeData;
			5'b11111 : regInput[28] = writeData;
			5'b11101 : regInput[29] = writeData;
			5'b11110 : regInput[30] = writeData;
			5'b11111 : regInput[31] = writeData;
			default : regInput[0] = `XLEN'hx;
		endcase
	end	
  end

endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//********
//formatting separation
//********
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module freg2adr (
  input  logic 	           FmtW,
  input  logic             reset,
  input  logic             clear,
  input  logic             clk,
  input  logic [4:0]       rd,
  input  logic             write,
  input  logic [4:0]       adr1,
  input  logic [4:0]       adr2,
  input  logic [`XLEN-1:0] writeData,
  output logic [`XLEN-1:0] readData1,
  output logic [`XLEN-1:0] readData2);

  //note - not word aligning based on precision of 
  //operation (FmtW)

  //reg number should remain static, but it doesn't hurt
  //to parameterize
  parameter numRegs = 32;

  //intermediary signals - useful for debugging
  //and easy instatiation of generated modules
  logic [`XLEN-1:0] [numRegs-1:0] regInput;
  logic [`XLEN-1:0] [numRegs-1:0] regOutput;

  //generate fp registers themselves
  genvar i;
  generate
  	for (i = 0; i < numRegs; i = i + 1) begin:register

  		floprc #(`XLEN) freg[i](.clk(clk), .reset(reset), .clear(clear), .d(regInput[i][`XLEN-1:0]), .q(regOutput[i][`XLEN-1:0])); 
	end

  endgenerate

  //address decoder
  //2 are used for this fp register set
  //used with fpadd/cvt, fpdiv/sqrt, and fpcmp
  //defaults to outputting zeroes
  always_comb begin

	//adderss 1 decoder
  	case(adr1)
		5'b00000 : readData1 = regOutput[0];
		5'b00001 : readData1 = regOutput[1];
		5'b00010 : readData1 = regOutput[2];
		5'b00011 : readData1 = regOutput[3];
		5'b00100 : readData1 = regOutput[4];
		5'b00101 : readData1 = regOutput[5];
		5'b00110 : readData1 = regOutput[6];
		5'b00111 : readData1 = regOutput[7];
		5'b01000 : readData1 = regOutput[8];
		5'b01001 : readData1 = regOutput[9];
		5'b01010 : readData1 = regOutput[10];
		5'b01011 : readData1 = regOutput[11];
		5'b01100 : readData1 = regOutput[12];
		5'b01101 : readData1 = regOutput[13];
		5'b01110 : readData1 = regOutput[14];
		5'b01111 : readData1 = regOutput[15];
		5'b10000 : readData1 = regOutput[16];
		5'b10001 : readData1 = regOutput[17];
		5'b10010 : readData1 = regOutput[18];
		5'b10011 : readData1 = regOutput[19];
		5'b10100 : readData1 = regOutput[20];
		5'b10101 : readData1 = regOutput[21];
		5'b10110 : readData1 = regOutput[22];
		5'b10111 : readData1 = regOutput[23];
		5'b11000 : readData1 = regOutput[24];
		5'b11001 : readData1 = regOutput[25];
		5'b11010 : readData1 = regOutput[26];
		5'b11011 : readData1 = regOutput[27];
		5'b11100 : readData1 = regOutput[28];
		5'b11101 : readData1 = regOutput[29];
		5'b11110 : readData1 = regOutput[30];
		5'b11111 : readData1 = regOutput[31];
		default : readData1 = `XLEN'h0;
	endcase

	//address 2 decoder
  	case(adr2)
		5'b00000 : readData2 = regOutput[0];
		5'b00001 : readData2 = regOutput[1];
		5'b00010 : readData2 = regOutput[2];
		5'b00011 : readData2 = regOutput[3];
		5'b00100 : readData2 = regOutput[4];
		5'b00101 : readData2 = regOutput[5];
		5'b00110 : readData2 = regOutput[6];
		5'b00111 : readData2 = regOutput[7];
		5'b01000 : readData2 = regOutput[8];
		5'b01001 : readData2 = regOutput[9];
		5'b01010 : readData2 = regOutput[10];
		5'b01011 : readData2 = regOutput[11];
		5'b01100 : readData2 = regOutput[12];
		5'b01101 : readData2 = regOutput[13];
		5'b01110 : readData2 = regOutput[14];
		5'b01111 : readData2 = regOutput[15];
		5'b10000 : readData2 = regOutput[16];
		5'b10001 : readData2 = regOutput[17];
		5'b10010 : readData2 = regOutput[18];
		5'b10011 : readData2 = regOutput[19];
		5'b10100 : readData2 = regOutput[20];
		5'b10101 : readData2 = regOutput[21];
		5'b10110 : readData2 = regOutput[22];
		5'b10111 : readData2 = regOutput[23];
		5'b11000 : readData2 = regOutput[24];
		5'b11001 : readData2 = regOutput[25];
		5'b11010 : readData2 = regOutput[26];
		5'b11011 : readData2 = regOutput[27];
		5'b11100 : readData2 = regOutput[28];
		5'b11101 : readData2 = regOutput[29];
		5'b11110 : readData2 = regOutput[30];
		5'b11111 : readData2 = regOutput[31];
		default : readData2 = `XLEN'h0;
	endcase
  end

  //destination register decoder
  //only change input values on write
  //defaults to undefined with invalid address
  //
  //note - this is an intermediary signal, so
  //this is not asynch assignment. FF in flopr
  //will not update data until clk pulse
  always_comb begin
	  if(write) begin
		case(rd)	
			5'b00000 : regInput[0] = writeData;
			5'b00001 : regInput[1] = writeData;
			5'b00010 : regInput[2] = writeData;
			5'b00011 : regInput[3] = writeData;	
			5'b00100 : regInput[4] = writeData;
			5'b00101 : regInput[5] = writeData;
			5'b00110 : regInput[6] = writeData;
			5'b00111 : regInput[7] = writeData;
			5'b01000 : regInput[8] = writeData;
			5'b01000 : regInput[9] = writeData;
			5'b01001 : regInput[10] = writeData;
			5'b01010 : regInput[11] = writeData;
			5'b01111 : regInput[12] = writeData;
			5'b01101 : regInput[13] = writeData;
			5'b01110 : regInput[14] = writeData;
			5'b01111 : regInput[15] = writeData;
			5'b10000 : regInput[16] = writeData;
			5'b10001 : regInput[17] = writeData;
			5'b10010 : regInput[18] = writeData;
			5'b10011 : regInput[19] = writeData;	
			5'b10100 : regInput[20] = writeData;
			5'b10101 : regInput[21] = writeData;
			5'b10110 : regInput[22] = writeData;
			5'b10111 : regInput[23] = writeData;
			5'b11000 : regInput[24] = writeData;
			5'b11000 : regInput[25] = writeData;
			5'b11001 : regInput[26] = writeData;
			5'b11010 : regInput[27] = writeData;
			5'b11111 : regInput[28] = writeData;
			5'b11101 : regInput[29] = writeData;
			5'b11110 : regInput[30] = writeData;
			5'b11111 : regInput[31] = writeData;
			default : regInput[0] = `XLEN'hx;
		endcase
	end	
  end

endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//********
//formatting separation
//********
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module freg3adr (
  input  logic    	   FmtW,
  input  logic             reset,
  input  logic             clear,
  input  logic             clk,
  input  logic [4:0]       rd,
  input  logic             write,
  input  logic [4:0]       adr1,
  input  logic [4:0]       adr2,
  input  logic [4:0]       adr3,
  input  logic [`XLEN-1:0] writeData,
  output logic [`XLEN-1:0] readData1,
  output logic [`XLEN-1:0] readData2,
  output logic [`XLEN-1:0] readData3);

  //note - not word aligning based on precision of 
  //operation (FmtW)

  //reg number should remain static, but it doesn't hurt
  //to parameterize
  parameter numRegs = 32;

  //intermediary signals - useful for debugging
  //and easy instatiation of generated modules
  logic [numRegs-1:0] [`XLEN-1:0] regInput;
  logic [numRegs-1:0] [`XLEN-1:0] regOutput;

  //generate fp registers themselves
  genvar i;
  generate
  	for (i = 0; i < numRegs; i = i + 1) begin:register

  		floprc #(`XLEN) freg(.clk(clk), .reset(reset), .clear(clear), .d(regInput[i][`XLEN-1:0]), .q(regOutput[i][`XLEN-1:0])); 
	end

  endgenerate

  //address decoder
  //3 are used for this fp register set
  //used exclusively for fma
  //defaults to outputting zeroes
  always_comb begin

	//adderss 1 decoder
  	case(adr1)
		5'b00000 : readData1 = regOutput[0];
		5'b00001 : readData1 = regOutput[1];
		5'b00010 : readData1 = regOutput[2];
		5'b00011 : readData1 = regOutput[3];
		5'b00100 : readData1 = regOutput[4];
		5'b00101 : readData1 = regOutput[5];
		5'b00110 : readData1 = regOutput[6];
		5'b00111 : readData1 = regOutput[7];
		5'b01000 : readData1 = regOutput[8];
		5'b01001 : readData1 = regOutput[9];
		5'b01010 : readData1 = regOutput[10];
		5'b01011 : readData1 = regOutput[11];
		5'b01100 : readData1 = regOutput[12];
		5'b01101 : readData1 = regOutput[13];
		5'b01110 : readData1 = regOutput[14];
		5'b01111 : readData1 = regOutput[15];
		5'b10000 : readData1 = regOutput[16];
		5'b10001 : readData1 = regOutput[17];
		5'b10010 : readData1 = regOutput[18];
		5'b10011 : readData1 = regOutput[19];
		5'b10100 : readData1 = regOutput[20];
		5'b10101 : readData1 = regOutput[21];
		5'b10110 : readData1 = regOutput[22];
		5'b10111 : readData1 = regOutput[23];
		5'b11000 : readData1 = regOutput[24];
		5'b11001 : readData1 = regOutput[25];
		5'b11010 : readData1 = regOutput[26];
		5'b11011 : readData1 = regOutput[27];
		5'b11100 : readData1 = regOutput[28];
		5'b11101 : readData1 = regOutput[29];
		5'b11110 : readData1 = regOutput[30];
		5'b11111 : readData1 = regOutput[31];
		default : readData1 = `XLEN'h0;
	endcase

	//address 2 decoder
  	case(adr2)
		5'b00000 : readData2 = regOutput[0];
		5'b00001 : readData2 = regOutput[1];
		5'b00010 : readData2 = regOutput[2];
		5'b00011 : readData2 = regOutput[3];
		5'b00100 : readData2 = regOutput[4];
		5'b00101 : readData2 = regOutput[5];
		5'b00110 : readData2 = regOutput[6];
		5'b00111 : readData2 = regOutput[7];
		5'b01000 : readData2 = regOutput[8];
		5'b01001 : readData2 = regOutput[9];
		5'b01010 : readData2 = regOutput[10];
		5'b01011 : readData2 = regOutput[11];
		5'b01100 : readData2 = regOutput[12];
		5'b01101 : readData2 = regOutput[13];
		5'b01110 : readData2 = regOutput[14];
		5'b01111 : readData2 = regOutput[15];
		5'b10000 : readData2 = regOutput[16];
		5'b10001 : readData2 = regOutput[17];
		5'b10010 : readData2 = regOutput[18];
		5'b10011 : readData2 = regOutput[19];
		5'b10100 : readData2 = regOutput[20];
		5'b10101 : readData2 = regOutput[21];
		5'b10110 : readData2 = regOutput[22];
		5'b10111 : readData2 = regOutput[23];
		5'b11000 : readData2 = regOutput[24];
		5'b11001 : readData2 = regOutput[25];
		5'b11010 : readData2 = regOutput[26];
		5'b11011 : readData2 = regOutput[27];
		5'b11100 : readData2 = regOutput[28];
		5'b11101 : readData2 = regOutput[29];
		5'b11110 : readData2 = regOutput[30];
		5'b11111 : readData2 = regOutput[31];
		default : readData2 = `XLEN'h0;
	endcase

	//address 3 decoder
  	case(adr3)
		5'b00000 : readData3 = regOutput[0];
		5'b00001 : readData3 = regOutput[1];
		5'b00010 : readData3 = regOutput[2];
		5'b00011 : readData3 = regOutput[3];
		5'b00100 : readData3 = regOutput[4];
		5'b00101 : readData3 = regOutput[5];
		5'b00110 : readData3 = regOutput[6];
		5'b00111 : readData3 = regOutput[7];
		5'b01000 : readData3 = regOutput[8];
		5'b01001 : readData3 = regOutput[9];
		5'b01010 : readData3 = regOutput[10];
		5'b01011 : readData3 = regOutput[11];
		5'b01100 : readData3 = regOutput[12];
		5'b01101 : readData3 = regOutput[13];
		5'b01110 : readData3 = regOutput[14];
		5'b01111 : readData3 = regOutput[15];
		5'b10000 : readData3 = regOutput[16];
		5'b10001 : readData3 = regOutput[17];
		5'b10010 : readData3 = regOutput[18];
		5'b10011 : readData3 = regOutput[19];
		5'b10100 : readData3 = regOutput[20];
		5'b10101 : readData3 = regOutput[21];
		5'b10110 : readData3 = regOutput[22];
		5'b10111 : readData3 = regOutput[23];
		5'b11000 : readData3 = regOutput[24];
		5'b11001 : readData3 = regOutput[25];
		5'b11010 : readData3 = regOutput[26];
		5'b11011 : readData3 = regOutput[27];
		5'b11100 : readData3 = regOutput[28];
		5'b11101 : readData3 = regOutput[29];
		5'b11110 : readData3 = regOutput[30];
		5'b11111 : readData3 = regOutput[31];
		default : readData3 = `XLEN'h0;
	endcase
  end

  //destination register decoder
  //only change input values on write
  //defaults to undefined with invalid address
  //
  //note - this is an intermediary signal, so
  //this is not asynch assignment. FF in flopr
  //will not update data until clk pulse
  always_comb begin
	  if(write) begin
		case(rd)	
			5'b00000 : regInput[0] = writeData;
			5'b00001 : regInput[1] = writeData;
			5'b00010 : regInput[2] = writeData;
			5'b00011 : regInput[3] = writeData;	
			5'b00100 : regInput[4] = writeData;
			5'b00101 : regInput[5] = writeData;
			5'b00110 : regInput[6] = writeData;
			5'b00111 : regInput[7] = writeData;
			5'b01000 : regInput[8] = writeData;
			5'b01001 : regInput[9] = writeData;
			5'b01010 : regInput[10] = writeData;
			5'b01011 : regInput[11] = writeData;
			5'b01100 : regInput[12] = writeData;
			5'b01101 : regInput[13] = writeData;
			5'b01110 : regInput[14] = writeData;
			5'b01111 : regInput[15] = writeData;
			5'b10000 : regInput[16] = writeData;
			5'b10001 : regInput[17] = writeData;
			5'b10010 : regInput[18] = writeData;
			5'b10011 : regInput[19] = writeData;	
			5'b10100 : regInput[20] = writeData;
			5'b10101 : regInput[21] = writeData;
			5'b10110 : regInput[22] = writeData;
			5'b10111 : regInput[23] = writeData;
			5'b11000 : regInput[24] = writeData;
			5'b11001 : regInput[25] = writeData;
			5'b11010 : regInput[26] = writeData;
			5'b11011 : regInput[27] = writeData;
			5'b11100 : regInput[28] = writeData;
			5'b11101 : regInput[29] = writeData;
			5'b11110 : regInput[30] = writeData;
			5'b11111 : regInput[31] = writeData;
			default : regInput[0] = `XLEN'hx;
		endcase
	end	
  end

endmodule
