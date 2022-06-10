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
module stimulus;

   logic [7:0] B;   
   logic [2:0] ZP;   
   logic       ZV;      

   logic       clk;   
   
   integer     handle3;
   integer     desc3;
   integer     i;   
   
   // instatiate part to test
   lzd_hier #(8) dut (B, ZP, ZV);

   initial 
     begin	
	clk = 1'b1;
	forever #5 clk = ~clk;
     end
   
   initial
     begin
	handle3 = $fopen("lzd.out");
	desc3 = handle3;	
     end
   
   initial
     begin
	for (i=0; i < 256; i=i+1)
	  begin
	     // Put vectors before beginning of clk
	     @(posedge clk)
	       begin
		  B = $random;
	       end
	     @(negedge clk)
	       begin
		  $fdisplay(desc3, "%b || %b %b", B, ZP, ZV);
	       end
	  end // for (i=0; i < 256; i=i+1)
	$finish;// 	
     end // initial begin   
   
endmodule // stimulus
