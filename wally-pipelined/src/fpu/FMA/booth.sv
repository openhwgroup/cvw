module booth(xExt, choose, add1, e, pp); 
/////////////////////////////////////////////////////////////////////////////
    
	input 		[53:0]		xExt;				// multiplicand	xExt
	input		[2:0]		choose;				// bits needed to choose which encoding
	output		[1:0]       	add1;				// do you add 1	
    output                  e;
	output		[54:0]		pp;				//	the resultant encoding
    
    logic [54:0] pp, temp;
    logic e;
    logic [1:0] add1;
    logic [53:0] negx;
    //logic temp;

    assign negx = ~xExt;

    always @(choose, xExt, negx)
    case (choose)
        3'b000 : pp = 55'b0;   //  0
        3'b001 : pp = {1'b0, xExt};  //  1
        3'b010 : pp = {1'b0, xExt};  //  1
        3'b011 : pp = {xExt, 1'b0};  //  2
        3'b100 : pp = {negx, 1'b0};  // -2
        3'b101 : pp = {1'b1, negx};  // -1
        3'b110 : pp = {1'b1, negx};  // -1
        3'b111 : pp = 55'hfffffffffffffff;  //  -0
    endcase

    always @(choose, xExt, negx)
    case (choose)
        3'b000 : e = 0;   //  0
        3'b001 : e = 0;  //  1
        3'b010 : e = 0;  //  1
        3'b011 : e = 0;  //  2
        3'b100 : e = 1;  // -2
        3'b101 : e = 1;  // -1
        3'b110 : e = 1;  // -1
        3'b111 : e = 1;  //  -0
    endcase
    // assign add1 = (choose[2] == 1'b1) ? ((choose[1:0] == 2'b11) ? 1'b0 : 1'b1) : 1'b0;
    // assign add1 = choose[2];
    always @(choose)
    case (choose)
        3'b000 : add1 = 2'b0;   //  0
        3'b001 : add1 = 2'b0;  //  1
        3'b010 : add1 = 2'b0;  //  1
        3'b011 : add1 = 2'b0;  //  2
        3'b100 : add1 = 2'b10;  // -2
        3'b101 : add1 = 2'b1;  // -1
        3'b110 : add1 = 2'b1;  // -1
        3'b111 : add1 = 2'b1;  //  -0
    endcase

endmodule
