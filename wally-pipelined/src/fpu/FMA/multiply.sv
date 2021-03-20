
module multiply(xman, yman, xdenorm, ydenorm, r, s); 
/////////////////////////////////////////////////////////////////////////////

	input 		[51:0]		xman;				// Fraction of multiplicand	x
	input		[51:0]		yman;				// Fraction of multiplicand y	
	input					xdenorm;		// is x denormalized	
	input					ydenorm;		// is y denormalized	
	output		[105:0]		r;				//	partial product 1	
	output		[105:0]		s;				//	partial product 2	

	assign r = 106'b0;
	assign s = {53'b0,~xdenorm,xman}  *  {53'b0,~ydenorm,yman};

endmodule
