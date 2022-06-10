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

   //logic [63:0]       A;
   //logic [5:0] 	      Shift;
   //logic [63:0]       Z;
   //logic [63:0]       Z_corr;
   //logic [63:0]       Z_orig;

   
   logic 	 clk;   

   integer 	 handle3;
   integer 	 desc3;
   integer 	 i;   
   
   // instatiate part to test
   shift_left dut1 (A, Shift, Z);
   assign Z_corr = (A << Shift);   

   initial 
     begin	
	clk = 1'b1;
	forever #5 clk = ~clk;
     end
   
   initial
     begin
	handle3 = $fopen("shift_left.out");
	desc3 = handle3;	
     end
   
   initial
     begin
	for (i=0; i < 256; i=i+1)
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
	  end // for (i=0; i < 256; i=i+1)
	$finish;// 	
     end // initial begin   
   
endmodule // stimulus
