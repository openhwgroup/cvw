module tb;

   logic [52:0]  d, n;
   logic 	 reset;
   
   logic [63:0]  q, qm, qp, rega_out, regb_out, regc_out;
   logic [127:0] regr_out;   
   
   logic 	 start;
   logic 	 error;
   logic  	 op_type;   
   
   logic 	 done;
   logic 	 load_rega;
   logic 	 load_regb;
   logic 	 load_regc;
   logic 	 load_regr;   
   logic [1:0] 	 sel_muxa;
   logic [1:0] 	 sel_muxb;
   logic 	 sel_muxr;   

   logic 	 clk;
   integer 	 handle3;
   integer 	 desc3;   

   divconv dut (q, qm, qp, rega_out, regb_out, regc_out, regr_out,
		d, n, sel_muxa, sel_muxb, sel_muxr, reset, clk,
		load_rega, load_regb, load_regc, load_regr);		   
   fsm control (done, load_rega, load_regb, load_regc, load_regr,
		sel_muxa, sel_muxb, sel_muxr,
		clk, reset, start, error, op_type);   
   
   initial 
     begin	
	clk = 1'b1;
	forever #5 clk = ~clk;
     end

   initial
     begin
	handle3 = $fopen("divconvDP.out");
	#700 $finish;		
     end

   always 
     begin
	desc3 = handle3;
	#5 $fdisplay(desc3, "%b %b %b | %h %h | %h %h %h | %h %h %h %h", sel_muxa,
		     sel_muxb, sel_muxr, d, n, q, qm, qp, rega_out, regb_out, regc_out, regr_out);
     end

   initial
     begin
	#0  start = 1'b0;	
	#0  n = 53'h1C_0000_0000_0000; // 1.75
	#0  d = 53'h1E_0000_0000_0000; // 1.875
	#0  reset = 1'b1;	

	#20 reset = 1'b0;	
	#20 start = 1'b1;
	#40 start = 1'b0;
	

     end


endmodule // tb





