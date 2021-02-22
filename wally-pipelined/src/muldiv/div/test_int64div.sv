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

   int64div dut (Q, done, divdone, rem, div0, N, D, clk, reset, start);

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
	#0  N = 64'h0;
	#0  D = 64'h0;
	#0  start = 1'b0;	
	#0  reset = 1'b1;
	#22 reset = 1'b0;	
	//#25 N = 64'h0000_0000_9830_07C0;
	//#0  D = 64'h0000_0000_0000_000C;
	#25 N = 64'h0000_0000_06b9_7b0d;	
	#0  D = 64'h0000_0000_46df_998d;
	#0  start = 1'b1;
	#50 start = 1'b0;	


     end

endmodule // tb
