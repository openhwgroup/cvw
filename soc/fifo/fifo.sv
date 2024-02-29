module fifo #(parameter DSIZE = 8,
	       parameter ASIZE = 4)
   (rdata, wfull, rempty, wdata, 
    winc, wclk, wrst_n, rinc, rclk, rrst_n);

   input logic [DSIZE-1:0] wdata;   
   input logic 		   winc;
   input logic 		   wclk;
   input logic 		   wrst_n;
   input logic 		   rinc;
   input logic 		   rclk;
   input logic 		   rrst_n;
   
   output logic [DSIZE-1:0] rdata;
   output logic 	    wfull;
   output logic 	    rempty;   
   
   logic [ASIZE-1:0] 	    waddr, raddr;
   logic [ASIZE:0] 	    wptr, rptr, wq2_rptr, rq2_wptr;
   
   sync_r2w      sync_r2w  (.wq2_rptr(wq2_rptr), .rptr(rptr),
			    .wclk(wclk), .wrst_n(wrst_n));
   sync_w2r      sync_w2r  (.rq2_wptr(rq2_wptr), .wptr(wptr),
			    .rclk(rclk), .rrst_n(rrst_n));
   
   fifomem #(DSIZE, ASIZE) fifomem (.rdata(rdata), .wdata(wdata),
				    .waddr(waddr), .raddr(raddr),
				    .wclken(winc), .wfull(wfull),
				    .wclk(wclk));
   rptr_empty #(ASIZE)   rptr_empty (.rempty(rempty), .raddr(raddr),
				     .rptr(rptr), .rq2_wptr(rq2_wptr), 
				     .rinc(rinc), .rclk(rclk), 
				     .rrst_n(rrst_n));
   wptr_full  #(ASIZE) wptr_full (.wfull(wfull), .waddr(waddr),
				  .wptr(wptr), .wq2_rptr(wq2_rptr),
				  .winc(winc), .wclk(wclk),
				  .wrst_n(wrst_n));

endmodule // fifo1

   
   
   
