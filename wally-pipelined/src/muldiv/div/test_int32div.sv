module tb;

   logic [31:0]  N, D;
   logic 	 clk;
   logic 	 reset;   
   logic 	 start;
   
   logic [31:0]  Q;
   logic [31:0]  rem;
   logic 	 div0;
   logic 	 done;
   logic 	 divdone;   
   
   integer 	 handle3;
   integer 	 desc3;
   integer 	 i;   

   logic [7:0] 	 count [0:15];   

   int32div dut (Q, done, divdone, rem, div0, N, D, clk, reset, start);

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
	#0  N = 32'h0;
	#0  D = 32'h0;
	#0  start = 1'b0;	
	#0  reset = 1'b1;
	#22 reset = 1'b0;	
	//#25 N = 32'h9830_07C0;
	//#0  D = 32'h0000_000C;
	#25 N = 32'h06b9_7b0d;	
	#0  D = 32'h46df_998d;	
	#0  start = 1'b1;
	#50 start = 1'b0;

     end

endmodule // tb
