module tb;

   logic [63:0]  N, D;
   logic 	 clk;
   logic 	 reset;   
   logic 	 start;
   
   logic [63:0]  Q;
   logic [63:0]  rem;
   logic 	 div0;
   logic 	 done;
   logic 	 divdone;   
   
   integer 	 handle3;
   integer 	 desc3;
   integer 	 i;   

   logic [7:0] 	 count [0:15];

   bit [63:0] 	 Ncomp;
   bit [63:0] 	 Dcomp;
   bit [63:0] 	 Qcomp;
   bit [63:0] 	 Rcomp;      

   int64div dut (Q, done, divdone, rem, div0, N, D, clk, reset, start);
   assign Ncomp = N;
   assign Dcomp = D;
   assign Qcomp = Ncomp/Dcomp;
   assign Rcomp = Ncomp%Dcomp;	        

   initial 
     begin	
	clk = 1'b0;
	forever #5 clk = ~clk;
     end

   initial
     begin
	#800 $finish;		
     end

      initial
     begin
	handle3 = $fopen("div64.out");
	desc3 = handle3;
     end

   always 
     begin
	desc3 = handle3;
	#5 $fdisplay(desc3, "%h %h | %h %h | %h %h %b %b",
		     N, D, Q, rem, Qcomp, Rcomp, 
		       (Q==Qcomp), (rem==Rcomp));	
     end

   initial
     begin
	#0  N = 64'h0;
	#0  D = 64'h0;
	#0  start = 1'b0;	
	#0  reset = 1'b1;
	#22 reset = 1'b0;	
	#25 N = 64'hffff_ffff_ffff_ffff;
	#0  D = 64'h0000_0000_0000_0000;
	#0  start = 1'b1;
	#50 start = 1'b0;	


     end

endmodule // tb
