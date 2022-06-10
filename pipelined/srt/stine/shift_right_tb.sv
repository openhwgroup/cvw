//
// File name : tb
// Title     : test
// project   : HW3
// Library   : test
// Purpose   : definition of modules for testbench 
// notes :   
//
// Copyright Oklahoma State University
//

// Top level stimulus module

`timescale 1ns/1ps

`define XLEN 32
module stimulus;

   logic [`XLEN-1:0]         A;   
   logic [$clog2(`XLEN)-1:0] Shift;   
   logic [`XLEN-1:0] 	     Z;
   logic [`XLEN-1:0] 	     Z_corr;      

   logic 	 clk;   

   integer 	 handle3;
   integer 	 desc3;
   integer 	 i;   
   
   // instatiate part to test
   shift_right dut1 (A, Shift, Z);
   assign Z_corr = (A >> Shift);   

   initial 
     begin	
	clk = 1'b1;
	forever #5 clk = ~clk;
     end
   
   initial
     begin
	handle3 = $fopen("shift_right.out");
	desc3 = handle3;	
	#250 $finish;		
     end
   
   initial
     begin
	for (i=0; i < 128; i=i+1)
	  begin
	     // Put vectors before beginning of clk
	     @(posedge clk)
	       begin
		  A = $random;
		  Shift = $random;
	       end
	     @(negedge clk)
	       begin
		  $fdisplay(desc3, "%h %h || %h %h | %b", A, Shift, Z, Z_corr, (Z == Z_corr));
	       end
	  end // @(negedge clk)
     end // for (j=0; j < 32; j=j+1)
   
endmodule // stimulus
