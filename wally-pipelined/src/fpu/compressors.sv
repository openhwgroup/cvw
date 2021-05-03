// //***breaks lint with warnings like: %Warning-UNOPTFLAT:      Example path: src/fpu/compressors.sv:37:  ASSIGNW
// //%Warning-UNOPTFLAT:      Example path: src/fpu/compressors.sv:32:  wallypipelinedsoc.hart.fpu.fma1.multiply.genblk5[0].add4.cout

// module add3comp2(a, b, c, carry, sum); 
// /////////////////////////////////////////////////////////////////////////////
// //look into diffrent implementations of the compressors?
    
//     parameter BITS = 4;
// 	input logic 		[BITS-1:0]		a;
// 	input logic		[BITS-1:0]		b;
// 	input logic		[BITS-1:0]    	c;
//     output logic      [BITS-1:0]      carry;
// 	output logic		[BITS-1:0]		sum;
//     genvar i;

//     generate
//         for(i= 0; i<BITS; i=i+1) begin
//             sng3comp2 add0(a[i], b[i], c[i], carry[i], sum[i]);
//         end
//     endgenerate

// endmodule

// module add4comp2(a, b, c, d, carry, sum); 
// /////////////////////////////////////////////////////////////////////////////
    
//     parameter BITS = 4;
// 	input logic 		[BITS-1:0]		a;
// 	input logic		[BITS-1:0]		b;
// 	input logic		[BITS-1:0]    	c;
// 	input logic		[BITS-1:0]    	d;
//     output logic      [BITS:0]      carry;
// 	output logic		[BITS-1:0]		sum;

//     logic       [BITS-1:0]      cout;
//     logic                       carryTmp;
//     genvar i;


//     sng4comp2 add0(a[0], b[0], c[0], d[0], 1'b0, cout[0], carry[0], sum[0]);

//     generate
//         for(i= 1; i<BITS-1; i=i+1) begin
//             sng4comp2 add1(a[i], b[i], c[i], d[i], cout[i-1], cout[i], carry[i], sum[i]);
//         end
//     endgenerate


//     sng4comp2 add2(a[BITS-1], b[BITS-1], c[BITS-1], d[BITS-1], cout[BITS-2], cout[BITS-1], carryTmp, sum[BITS-1]);

//     assign carry[BITS-1] = carryTmp & cout[BITS-1];
//     assign carry[BITS] = carryTmp ^ cout[BITS-1];

// endmodule

// module sng3comp2(a, b, c, carry, sum); 
// /////////////////////////////////////////////////////////////////////////////
// //look into diffrent implementations of the compressors?
    
// 	input logic 				a;
// 	input logic				b;
// 	input logic		       	c;
//     output logic              carry;
// 	output logic				sum;
    
//     logic               axorb;

//     assign axorb = a ^ b;
//     assign sum = axorb ^ c;

//     assign carry = axorb ? c : a;

// endmodule

// module sng4comp2(a, b, c, d, cin, cout, carry, sum); 
// /////////////////////////////////////////////////////////////////////////////
// //look into pass gate 4:2 counters?
    
// 	input logic 				a;
// 	input logic				b;
// 	input logic		       	c;
//     input logic               d;
//     input logic               cin;
//     output logic              cout;
//     output logic              carry;
// 	output logic				sum;
    
//     logic               TmpSum;

//     sng3comp2 add1(.carry(cout), .sum(TmpSum),.*);
//     sng3comp2 add2(.a(TmpSum), .b(d), .c(cin), .*);

// endmodule