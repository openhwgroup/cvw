`include "idiv-config.vh"

module tb;

   logic [127:0]  N, D;
   logic 	  clk;
   logic 	  reset;   
   logic 	  start;
   logic 	  S;   
   
   logic [127:0]   Q;
   logic [127:0]  rem0;
   logic 	 div0;
   logic 	 done;
   
   integer 	 handle3;
   integer 	 desc3;
   integer 	 i;   

   logic [31:0]  rnd1;
   logic [31:0]  rnd2;            
   logic [127:0] Ncomp;
   logic [127:0] Dcomp;
   logic [127:0] Qcomp;
   logic [127:0] Rcomp;
   
   logic [31:0]  vectornum;
   logic [31:0]  errors;   
   
   intdiv #(128) dut (Q, done, rem0, div0, N, D, clk, reset, start, S);
   
   initial 
     begin	
	clk = 1'b0;
	forever #5 clk = ~clk;
     end

   initial
     begin
	vectornum = 0;
	errors = 0;	
	handle3 = $fopen("iter128_signed.out");
     end

   /*
   // VCD generation for power estimation
   initial
     begin
        $dumpfile("iter128_signed.vcd");
	$dumpvars (0,tb.dut);	
     end
    */      

   always @(posedge clk, posedge reset)
     begin
	desc3 = handle3;	
	#0  start = 1'b0;
	#0  S = 1'b1;	
	#0  reset = 1'b1;
	#30 reset = 1'b0;
	#30 N = 128'h0;
	#0  D = 128'h0;	
	for (i=0; i<`IDIV_TESTS; i=i+1)
	  begin
	     N = {$urandom(), $urandom(), $urandom(), $urandom()};
	     D = {$urandom(), $urandom(), $urandom(), $urandom()};		
	     start <= 1'b1;
	     // Wait 2 cycles (to be sure)
	     repeat (1)
	       @(posedge clk);
	     start <= 1'b0;	     
	     repeat (65)
	       @(posedge clk);
	     Ncomp = N;
	     Dcomp = D;
	     Qcomp = $signed(Ncomp)/$signed(Dcomp);
	     Rcomp = $signed(Ncomp)%$signed(Dcomp);	     
	     vectornum = vectornum + 1;
	       if ((Q !== Qcomp)) begin
	       errors = errors + 1;
	     end
	     $fdisplay(desc3, "%h %h %h %h || %h %h || %b %b", 
		       N, D, Q, rem0, Qcomp, Rcomp, 
		       (Q==Qcomp), (rem0==Rcomp));
	  end 
	$display("%d tests completed, %d errors", vectornum, errors);
	$finish;	
     end 

endmodule // tb
