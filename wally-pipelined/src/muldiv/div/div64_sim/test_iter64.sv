module tb;

   logic [63:0]  N, D;
   logic 	 clk;
   logic 	 reset;   
   logic 	 start;
   
   logic [63:0]  Q;
   logic [63:0]  rem0;
   logic 	 div0;
   logic 	 done;
   logic 	 divdone;   
   
   integer 	 handle3;
   integer 	 desc3;
   integer 	 i;   

   bit [63:0] 	 Ncomp;
   bit [63:0] 	 Dcomp;
   bit [63:0] 	 Qcomp;
   bit [63:0] 	 Rcomp;   
   
   logic [7:0] 	 count [0:15];   

   div dut (Q, done, divdone, rem0, div0, N, D, clk, reset, start);
   
   initial 
     begin	
	clk = 1'b0;
	forever #5 clk = ~clk;
     end

   initial
     begin
	handle3 = $fopen("iter64.out");
	#8000000 $finish;		
     end

   always @(posedge clk, posedge reset)
     begin
	desc3 = handle3;	
	#0  start = 1'b0;
	#0  reset = 1'b1;
	#30 reset = 1'b0;	
	for (i=0; i<2; i=i+1)
	  begin
	     N = $random;
	     D = $random;
	     start <= 1'b1;
	     // Wait 2 cycles (to be sure)
	     repeat (2)
	       @(posedge clk);
	     start <= 1'b0;	     
	     repeat (41)
	       @(posedge clk);
	     Ncomp = N;
	     Dcomp = D;
	     Qcomp = Ncomp/Dcomp;
	     Rcomp = Ncomp%Dcomp;	     
	     $fdisplay(desc3, "%h %h %h %h || %h %h || %b %b", 
		       N, D, Q, rem0, Qcomp, Rcomp, 
		       (Q==Qcomp), (rem0==Rcomp));
	  end // for (i=0; i<2, i=i+1)	
     end 

endmodule // tb






