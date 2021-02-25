`include "../../config/rv64icfd/wally-config.vh"

module fctrl (
  input  logic [6:0] Funct7D,
  input  logic [6:0] OpD,
  input  logic [4:0] Rs2D,
  input  logic [4:0] Rs1D,
  input  logic [2:0] FrmW,
  output logic       WriteEnD,
  output logic       DivSqrtStartD,
  output logic [2:0] regSelD,
  output logic [2:0] writeSelD,
  output logic [3:0] OpCtrlD,
  output logic       FmtD,
  output logic       WriteIntD);



  //precision is taken directly from instruction
  assign FmtD = Funct7D[0];

  //all subsequent logic is based on the table present
  //in Section 5 of Wally Architecture Specification
  
  //write is enabled for all fp instruciton op codes
  //sans fp load
  logic isFP, isFPLD;
  always_comb begin
	//case statement is easier to modify
	//in case of errors
	case(OpD)
		//fp instructions sans load
		7'b1010011 : begin isFP = 1'b1; isFPLD = 1'b0; end
		7'b1000011 : begin isFP = 1'b1; isFPLD = 1'b0; end
		7'b1000111 : begin isFP = 1'b1; isFPLD = 1'b0; end
		7'b1001011 : begin isFP = 1'b1; isFPLD = 1'b0; end
		7'b1001111 : begin isFP = 1'b1; isFPLD = 1'b0; end
		7'b0100111 : begin isFP = 1'b1; isFPLD = 1'b0; end
		//fp load	
		7'b1010011 : begin isFP = 1'b1; isFPLD = 1'b1; end
		default : begin isFP = 1'b0; isFPLD = 1'b0; end
	endcase
  end
  
  assign WriteEnD = isFP & ~isFPLD; 
  
  //useful intermediary signals
  //
  //(mult only not supported in current datapath)
  //set third FMA operand to zero in this case
  //(or equivalent)
  logic isAddSub, isFMA, isMult, isDivSqrt, isCvt, isCmp, isFPSTR;

  always_comb begin
	//checks all but FMA/store/load
	if(OpD == 7'b1010011) begin
  		case(Funct7D)
			//compare	
			7'b10100?? : begin isAddSub = 1'b0; isFMA = 1'b0; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b1; isFPSTR = 1'b0; end
			//div/sqrt
			7'b0?011?? : begin isAddSub = 1'b0; isFMA = 1'b0; isMult = 1'b0; isDivSqrt = 1'b1; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b0; end
			//add/sub
			7'b0000??? : begin isAddSub = 1'b1; isFMA = 1'b0; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b0; end
			//mult
			7'b00010?? : begin isAddSub = 1'b0; isFMA = 1'b0; isMult = 1'b1; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b0; end
			//convert (not precision)
			7'b110?0?? : begin isAddSub = 1'b0; isFMA = 1'b0; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b1; isCmp = 1'b0; isFPSTR = 1'b0; end
			//convert (precision)
			7'b010000? : begin isAddSub = 1'b0; isFMA = 1'b0; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b1; isCmp = 1'b0; isFPSTR = 1'b0; end
		endcase
	end
	//FMA/store/load
	else begin
  		case(OpD)
			//4 FMA instructions
			7'b1000011 : begin isAddSub = 1'b0; isFMA = 1'b1; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b0; end
			7'b1000111 : begin isAddSub = 1'b0; isFMA = 1'b1; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b0; end
			7'b1001011 : begin isAddSub = 1'b0; isFMA = 1'b1; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b0; end
			7'b1001111 : begin isAddSub = 1'b0; isFMA = 1'b1; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b0; end
			//store (load already found)
			7'b0100111 : begin isAddSub = 1'b0; isFMA = 1'b0; isMult = 1'b0; isDivSqrt = 1'b0; isCvt = 1'b0; isCmp = 1'b0; isFPSTR = 1'b1; end
		endcase
	end
  end

  //register is chosen based on operation performed
  //---- 
  //write selection is chosen in the same way as 
  //register selection
  //

  // reg/write sel logic and assignment
  // 
  // 3'b000 = add/sub/cvt
  // 3'b001 = sign
  // 3'b010 = fma
  // 3'b011 = cmp
  // 3'b100 = div/sqrt
  //
  //reg select
  
  //this value is used enough to be shorthand
  logic isSign;
  assign isSign = ~Funct7D[6] & ~Funct7D[5] & Funct7D[4] & ~Funct7D[3] & ~Funct7D[2];


  assign regSelD[2] = isDivSqrt & ~isFMA;
  assign regSelD[1] = isFMA | isCmp;
  //AND of Funct7 for sign
  assign regSelD[0] = isCmp | isSign;

  //write select
  assign writeSelD[2] = isDivSqrt & ~isFMA;
  assign writeSelD[1] = isFMA | isCmp;
  //AND of Funct7 for sign
  assign writeSelD[0] = isCmp | isSign;

  //if op is div/sqrt - start div/sqrt
  assign DivSqrtStartD = isDivSqrt & ~isFMA;

  //operation control for each fp operation
  //has to be expanded over standard to account for
  //integrated fpadd/cvt
  //
  //will integrate FMA opcodes into design later
  //
  //conversion instructions will
  //also need to be added later as I find the opcode
  //version I used for this repo

  assign OpCtrlD[3] = 1'b0;
  //if is positive sign injection OR is precision convert
  assign OpCtrlD[2] = (isSign & ~FrmW[0]) | (~Funct7D[6] & Funct7D[5] & ~Funct7D[4] & ~Funct7D[3] & ~Funct7D[2] & ~Funct7D[1]);
  //if is precision convert OR is sign xor 
  assign OpCtrlD[1] = (isSign & FrmW[1]) | (~Funct7D[6] & Funct7D[5] & ~Funct7D[4] & ~Funct7D[3] & ~Funct7D[2] & ~Funct7D[1]);
  //if is sqrt OR is sub OR is single-precision cmp OR negation
  assign OpCtrlD[0] = (isDivSqrt & ~isFMA & Funct7D[6]) | (isAddSub & ~isFMA & Funct7D[2]) | (isCmp & ~isFMA & Funct7D[0]) | (isSign & FrmW[0]);
  
  //write to integer source if conv to int occurs
  //AND of Funct7 for int results 
  assign WriteIntD = isCvt & (Funct7D[6] & Funct7D[5] & ~Funct7D[4] & ~Funct7D[3] & ~Funct7D[2] & ~Funct7D[1]);

endmodule
