module sync_w2r #(parameter ADDRSIZE = 4)
   (rq2_wptr, wptr, rclk, rrst_n);

   input logic      [ADDRSIZE:0] wptr;
   input logic			 rclk;
   input logic 			 rrst_n;
   
   output logic [ADDRSIZE:0] 	 rq2_wptr;

   logic [ADDRSIZE:0] 		 rq1_wptr;

   always @(posedge rclk or negedge rrst_n)
     if (!rrst_n) {rq2_wptr,rq1_wptr} <= 0;   
     else         {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

endmodule // sync_w2r
