
module multiply(xman, yman, xdenorm, ydenorm, xzero, yzero, r, s); 
/////////////////////////////////////////////////////////////////////////////

	input 		[51:0]		xman;				// Fraction of multiplicand	x
	input		[51:0]		yman;				// Fraction of multiplicand y	
	input					xdenorm;		// is x denormalized	
	input					ydenorm;		// is y denormalized	
	input     			xzero;		// Z is denorm
	input     			yzero;		// Z is denorm
	output		[105:0]		r;				//	partial product 1	
	output		[105:0]		s;				//	partial product 2	

	assign r = 106'b0;
	assign s = {53'b0,~(xdenorm|xzero),xman}  *  {53'b0,~(ydenorm|yzero),yman};

endmodule
