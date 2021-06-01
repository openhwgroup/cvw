//
// File name : tb.v
// Title     : stimulus
// project   : mult
// Library   : test
// Author(s) : James E. Stine, Jr.
// Purpose   : definition of modules for testbench 
// notes :   
//
// Copyright Oklahoma State University
//

// Top level stimulus module

module stimulus;

   reg clk;  // Always declared so can simulate based on clock
    
   // Declare variables for stimulating input
   reg [63:0]  op1;
   reg [63:0]  op2;
   reg [1:0] rm;
   reg [2:0] op_type;
   reg P;
   reg OvEn;
   reg UnEn;
   
   wire [63:0] AS_Result;
   wire [4:0] Flags;
   wire Denorm;

   integer     handle3;
   integer     desc3;      

   // Instantiate the design block counter
   fpadd dut (AS_Result, Flags, Denorm, op1, op2, rm, op_type, P , OvEn, UnEn);
   
   // Setup the clock to toggle every 1 time units 
   initial 
     begin	
	clk = 1'b1;
	forever #25 clk = ~clk;
     end
   
   initial
     begin
	handle3 = $fopen("tb.out");
     end
   
   always @(posedge clk)
     begin
	desc3 = handle3;
	#5 $display(desc3, "%h %h || %h", op1, op2, AS_Result);
     end
   
   // Stimulate the Input Signals
   initial
     begin
	// Add your test vectors here
	$display("%h", AS_Result);
	#0   rm = 2'b00;
	#0   op_type = 3'b000;
	#0   P = 1'b0;
	#0   OvEn = 1'b0;
	#0   UnEn = 1'b0;
	#0   op1 = 64'h4031e147ae147ae1;
	#0   op2 = 64'h4046e147ae147ae1;
	$display("%h", AS_Result);
	#200;
	#0   rm = 2'b00;
	#0   op_type = 3'b000;
	#0   P = 1'b0;
	#0   OvEn = 1'b0;
	#0   UnEn = 1'b0;
	#0   op1 = 64'h4031e147ae147ae1;
	#0   op2 = 64'h4046e147ae147ae1;
	$display("%h", AS_Result);
	
     end

endmodule // stimulus





