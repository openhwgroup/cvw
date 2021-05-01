////////////////////////////////////////////////////////////////////////////////
//
// Block Name:	add.v
// Author:		David Harris
// Date:		11/12/1995
//
// Block Description:
//       This block performs the addition of the product and addend.   It also
//   contains logic necessary to adjust the signs for effective subtracts 
//   and negative results. 
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
module add(rM, sM, tM, sum,
		   negsum, invz, selsum1, negsum0, negsum1, killprodM);
////////////////////////////////////////////////////////////////////////////////

	input logic 		[105:0]		rM;     			// partial product 1
	input logic 		[105:0]		sM;              // partial product 2
	input logic 		[163:0]		tM;             	// aligned addend 
	input logic					invz;       	// invert addend
	input logic 					selsum1;    	// select +1 mode of compound adder 
	input logic					killprodM;    	// z >> product
	input logic					negsum;      	// Negate sum 
	output logic		[163:0]		sum;         	// sum
	output logic					negsum0;     	// sum was negative in +0 mode
	output logic					negsum1;     	// sum was negative in +1 mode 

	// Internal nodes

	wire		[105:0]		r2;				// partial product possibly zeroed out
	wire		[105:0]		s2;				// partial product possibly zeroed out
	wire		[164:0]		t2;				// addend after inversion if necessary
	wire		[164:0] 	sum0;			// sum of compound adder +0 mode
	wire		[164:0] 	sum1;			// sum of compound adder +1 mode
	wire		[163:0] 	prodshifted;			// sum of compound adder +1 mode
	wire		[164:0] 	tmp;			// sum of compound adder +1 mode

	// Invert addend if z'sM sign is diffrent from the product'sM sign

	assign t2 = invz ? ~{1'b0,tM} : {1'b0,tM};
	
	// Zero out product if Z >> product or product really should be 	

	assign r2 = killprodM ? 106'b0 : rM;
	assign s2 = killprodM ? 106'b0 : sM;

	//***replace this with a more structural cpa that synthisises better
	// Compound adder
	// Consists of 3:2 CSA followed by long compound CPA
	//assign prodshifted = killprodM ? 0 : {56'b0, r2+s2, 2'b0};
	//assign tmp = ({{57{r2[105]}},r2, 2'b0} + {{57{s2[105]}},s2, 2'b0});
	assign sum0 = t2 + 164'b0 + {57'b0, r2+s2, 2'b0};
	assign sum1 = t2 + 164'b1 + {57'b0, r2+s2, 2'b0}; // +1 from invert of z above
	
	// Check sign bits in +0/1 modes 
	assign negsum0 = sum0[164];
	assign negsum1 = sum1[164];

	// Mux proper result (+Oil mode and inversion) using 4:1 mux
 	//assign sumzero = |sum;
	assign sum = selsum1 ? (negsum ? -sum1[163:0] : sum1[163:0]) : (negsum ? -sum0[163:0] : sum0[163:0]);
	
endmodule

