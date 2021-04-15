
module multiply(xman, yman, xdenormE, ydenormE, xzeroE, yzeroE, rE, sE); 
/////////////////////////////////////////////////////////////////////////////

	input 		[51:0]		xman;				// Fraction of multiplicand	x
	input		[51:0]		yman;				// Fraction of multiplicand y	
	input					xdenormE;		// is x denormalized	
	input					ydenormE;		// is y denormalized	
	input     			xzeroE;		// Z is denorm
	input     			yzeroE;		// Z is denorm
	output		[105:0]		rE;				//	partial product 1	
	output		[105:0]		sE;				//	partial product 2	
    
     wire        [54:0]      yExt; //y with appended 0 and assumed 1
     wire        [53:0]      xExt; //y with assumed 1
     wire [26:0][1:0] add1;
     wire [26:0][54:0] pp; 
     wire [26:0] e;
     logic [17:0][105:0] lv1add;
     logic [11:0][105:0] lv2add;
     logic [7:0][105:0] lv3add;
     logic [3:0][105:0] lv4add;
     logic [21:0][106:0] carryTmp;
     wire [26:0][105:0] acc; 
     // wire [105:0] acc
    genvar i;	

	assign xExt = {2'b0,~(xdenormE|xzeroE),xman};
	assign yExt = {2'b0,~(ydenormE|yzeroE),yman, 1'b0};
    
     generate
        for(i=0; i<27; i=i+1) begin
            booth booth(.xExt(xExt), .choose(yExt[(i*2)+2:i*2]), .add1(add1[i]), .e(e[i]), .pp(pp[i]));
        end
     endgenerate

    assign acc[0] = {49'b0,~e[0],e[0],e[0],pp[0]}; 
    assign acc[1] = {50'b01,~e[1],pp[1],add1[0]}; 
    assign acc[2] = {48'b01,~e[2],pp[2],add1[1], 2'b0};
    assign acc[3] = {46'b01,~e[3],pp[3],add1[2], 4'b0};
    assign acc[4] = {44'b01,~e[4],pp[4],add1[3], 6'b0};
    assign acc[5] = {42'b01,~e[5],pp[5],add1[4], 8'b0};
    assign acc[6] = {40'b01,~e[6],pp[6],add1[5], 10'b0};
    assign acc[7] = {38'b01,~e[7],pp[7],add1[6], 12'b0};
    assign acc[8] = {36'b01,~e[8],pp[8],add1[7], 14'b0};
    assign acc[9] = {34'b01,~e[9],pp[9],add1[8], 16'b0};
    assign acc[10] = {32'b01,~e[10],pp[10],add1[9], 18'b0};
    assign acc[11] = {30'b01,~e[11],pp[11],add1[10], 20'b0};
    assign acc[12] = {28'b01,~e[12],pp[12],add1[11], 22'b0};
    assign acc[13] = {26'b01,~e[13],pp[13],add1[12], 24'b0};
    assign acc[14] = {24'b01,~e[14],pp[14],add1[13], 26'b0};
    assign acc[15] = {22'b01,~e[15],pp[15],add1[14], 28'b0};
    assign acc[16] = {20'b01,~e[16],pp[16],add1[15], 30'b0};
    assign acc[17] = {18'b01,~e[17],pp[17],add1[16], 32'b0};
    assign acc[18] = {16'b01,~e[18],pp[18],add1[17], 34'b0};
    assign acc[19] = {14'b01,~e[19],pp[19],add1[18], 36'b0};
    assign acc[20] = {12'b01,~e[20],pp[20],add1[19], 38'b0};
    assign acc[21] = {10'b01,~e[21],pp[21],add1[20], 40'b0};
    assign acc[22] = {8'b01,~e[22],pp[22],add1[21], 42'b0};
    assign acc[23] = {6'b01,~e[23],pp[23],add1[22], 44'b0};
    assign acc[24] = {4'b01,~e[24],pp[24],add1[23], 46'b0};
    assign acc[25] = {~e[25],pp[25],add1[24], 48'b0};
    assign acc[26] = {pp[26],add1[25], 50'b0};

    //*** resize adders
     generate
        for(i=0; i<9; i=i+1) begin
            add3comp2 #(.BITS(106)) add1(.a(acc[i*3]), .b(acc[i*3+1]), .c(acc[i*3+2]), 
                                           .carry(carryTmp[i][105:0]), .sum(lv1add[i*2+1]));
            assign lv1add[i*2] = {carryTmp[i][104:0], 1'b0};
        end
     endgenerate

     generate
        for(i=0; i<6; i=i+1) begin
            add3comp2 #(.BITS(106)) add2(.a(lv1add[i*3]), .b(lv1add[i*3+1]), .c(lv1add[i*3+2]), 
                                           .carry(carryTmp[i+9][105:0]), .sum(lv2add[i*2+1]));
            assign lv2add[i*2] = {carryTmp[i+9][104:0], 1'b0};
        end
     endgenerate

    generate
        for(i=0; i<4; i=i+1) begin
            add3comp2 #(.BITS(106)) add3(.a(lv2add[i*3]), .b(lv2add[i*3+1]), .c(lv2add[i*3+2]), 
                                            .carry(carryTmp[i+15][105:0]), .sum(lv3add[i*2+1]));
            assign lv3add[i*2] = {carryTmp[i+15][104:0], 1'b0};
        end
    endgenerate


    generate
        for(i=0; i<2; i=i+1) begin
            add4comp2 #(.BITS(106)) add4(.a(lv3add[i*4]), .b(lv3add[i*4+1]), .c(lv3add[i*4+2]), .d(lv3add[i*4+3]),
                                            .carry(carryTmp[i+19]), .sum(lv4add[i*2+1]));
            assign lv4add[i*2] = {carryTmp[i+19][104:0], 1'b0};
        end
    endgenerate

    add4comp2 #(.BITS(106)) add5(.a(lv4add[0]), .b(lv4add[1]), .c(lv4add[2]), .d(lv4add[3]) ,
                                    .carry(carryTmp[21]), .sum(sE));
    assign rE = {carryTmp[21][104:0], 1'b0};
		// assign rE = 0;
		// assign sE = acc[0] +
		// 		   acc[1] +
		// 		   acc[2] +
		// 		   acc[3] +
		// 		   acc[4] +
		// 		   acc[5] +
		// 		   acc[6] +
		// 		   acc[7] +
		// 		   acc[8] +
		// 		   acc[9] +
		// 		   acc[10] +
		// 		   acc[11] +
		// 		   acc[12] +
		// 		   acc[13] +
		// 		   acc[14] +
		// 		   acc[15] +
		// 		   acc[16] +
		// 		   acc[17] +
		// 		   acc[18] +
		// 		   acc[19] +
		// 		   acc[20] +
		// 		   acc[21] +
		// 		   acc[22] +
		// 		   acc[23] +
		// 		   acc[24] +
		// 		   acc[25] +
		// 		   acc[26];

			// assign sE = {53'b0,~(xdenormE|xzeroE),xman}  *  {53'b0,~(ydenormE|yzeroE),yman};
			// assign rE = 0;
endmodule
