`timescale 1ns/1ps
module tb ();

   logic [63:0] op1; 
   logic [63:0] op2;
   logic [1:0] 	Sel;

   logic 	Invalid;
   logic [1:0] 	FCC;
   
   logic 	clk;
   logic [3:0] 	yexpected; 
   logic 	reset;   
   logic [63:0] vectornum, errors;    // bookkeeping variables
   logic [139:0] testvectors[50000:0]; // array of testvectors
   logic [7:0] 	 flags_expected;

   integer 	 handle3;
   integer 	 desc3;   
   
   // instantiate device under test
   fpcomp dut (Invalid, FCC, op1, op2, Sel);   

   always     
     begin
	clk = 1; #5; clk = 0; #5;
     end
   
   initial
     begin
	handle3 = $fopen("test_f64.out");
	desc3 = handle3;	
	$readmemh("./cmp_f64.tv", testvectors);
	vectornum = 0; errors = 0;
	reset = 1; #27; reset = 0;	
     end

   always @(posedge clk)
     begin
	desc3 = handle3;
	#0  Sel = 2'b00;	
	#1; {op1, op2, yexpected, flags_expected} = testvectors[vectornum];
     end

   // check results on falling edge of clk
   always @(negedge clk)
     if (~reset) 
       begin // skip during reset
	  if (FCC !== yexpected[3:0]) 
	    begin
	       errors = errors + 1;
               $display("Error %4d: inputs = %h %h", errors, op1, op2);
               $display("  outputs = %h (%h expected)", FCC, yexpected[3:0]);
	    end

	  $fdisplay(desc3, "%h_%h_%b_%b", op1, op2, FCC, Invalid);	  	  
	  vectornum = vectornum + 1;
	  if (testvectors[vectornum] === 140'hx) 
	    begin 
               $display("%d tests completed with %d errors", 
			vectornum, errors);
	       $finish;	       
	    end	
       end // if (~reset)

endmodule // tb


