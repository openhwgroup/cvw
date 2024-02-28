module rptr_empty #(parameter ADDRSIZE = 4)
   (rempty, raddr, rptr, rq2_wptr, rinc, rclk, rrst_n);

   input logic [ADDRSIZE:0]    rq2_wptr;
   input logic 		       rinc;
   input logic 		       rclk;
   input logic 		       rrst_n;   
   output logic 	       rempty;
   output logic [ADDRSIZE-1:0] raddr;
   output logic [ADDRSIZE  :0] rptr;

   logic [ADDRSIZE:0] 	       rbin;
   logic [ADDRSIZE:0] 	       rgraynext;
   logic [ADDRSIZE:0] 	       rbinnext;   

   //-------------------
   // GRAYSTYLE2 pointer
   //-------------------
   always @(posedge rclk or negedge rrst_n)
     if (!rrst_n) {rbin, rptr} <= 0;
     else         {rbin, rptr} <= {rbinnext, rgraynext};
   
   // Memory read-address pointer (okay to use binary to address memory)
   assign raddr     = rbin[ADDRSIZE-1:0];
   assign rbinnext  = rbin + (rinc & ~rempty);
   assign rgraynext = (rbinnext>>1) ^ rbinnext;
   
   //--------------------------------------------------------------- 
   // FIFO empty when the next rptr == synchronized wptr or on reset 
   //--------------------------------------------------------------- 
   assign rempty_val = (rgraynext == rq2_wptr);
   
   always @(posedge rclk or negedge rrst_n)
     if (!rrst_n) rempty <= 1'b1;   
     else         rempty <= rempty_val;
   
endmodule // rptr_empty
