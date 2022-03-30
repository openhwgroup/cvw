// This model actually works correctly with vivado.


module bram2p1r1w
  #(
	//--------------------------------------------------------------------------
	parameter NUM_COL = 8,
	parameter COL_WIDTH = 8,
	parameter ADDR_WIDTH = 10,
	// Addr Width in bits : 2 *ADDR_WIDTH = RAM Depth
	parameter DATA_WIDTH = NUM_COL*COL_WIDTH // Data Width in bits
	//----------------------------------------------------------------------
	) (
	   input logic 					 clk,
	   input logic 					 enaA,
	   input logic [ADDR_WIDTH-1:0]  addrA,
	   output logic [DATA_WIDTH-1:0] doutA,
	   input logic 					 enaB,
	   input logic [NUM_COL-1:0] 	 weB,
	   input logic [ADDR_WIDTH-1:0]  addrB,
	   input logic [DATA_WIDTH-1:0]  dinB
	   );
  // Core Memory
  logic [DATA_WIDTH-1:0] 			 RAM [(2**ADDR_WIDTH)-1:0];
  integer 							 i;

  initial begin
	$readmemh("big64.txt", RAM);
  end

  // Port-A Operation
  always @ (posedge clk) begin
	if(enaA) begin
	  doutA <= RAM[addrA];
	end
  end
  // Port-B Operation:
  always @ (posedge clk) begin
	if(enaB) begin
	  for(i=0;i<NUM_COL;i=i+1) begin
		if(weB[i]) begin
		  RAM[addrB][i*COL_WIDTH +: COL_WIDTH] <= dinB[i*COL_WIDTH +:COL_WIDTH];
		end
	  end
	end
  end
endmodule // bytewrite_tdp_ram_rf
