
// DATASIZE = Memory data word width    
// ADDRSIZE = Number of mem address bits
module fifomem #(parameter  DATASIZE = 8, 
		 parameter  ADDRSIZE = 4) 
   (rdata, wdata, waddr, raddr, wclken, wfull, wclk);

   input logic [DATASIZE-1:0]  wdata;
   input logic [ADDRSIZE-1:0]  waddr;
   input logic [ADDRSIZE-1:0]  raddr;
   input logic		       wclken;
   input logic 		       wfull;
   input logic 		       wclk;
   output logic [DATASIZE-1:0] rdata;

   // RTL Verilog memory model
   localparam DEPTH = 1 << ADDRSIZE;   
   logic [DATASIZE-1:0]        mem [0:DEPTH-1];

   assign rdata = mem[raddr];   
   always @(posedge wclk)
     if (wclken && !wfull) mem[waddr] <= wdata;
   
endmodule // fifomem
