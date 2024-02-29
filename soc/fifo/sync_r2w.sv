module sync_r2w #(parameter ADDRSIZE = 4)
   (wq2_rptr, rptr, wclk, wrst_n);

   input logic    [ADDRSIZE:0] rptr;
   input logic		       wclk;
   input logic 		       wrst_n;
   
   output logic [ADDRSIZE:0]   wq2_rptr;
  
   logic [ADDRSIZE:0] 	       wq1_rptr;

   always @(posedge wclk or negedge wrst_n)
     if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
     else         {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

endmodule // sync_r2w
