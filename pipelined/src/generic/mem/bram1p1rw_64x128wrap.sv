module bram1p1rw_64x128wrap
  #(
	//--------------------------------------------------------------------------
	parameter NUM_COL = 16,
	parameter COL_WIDTH = 8,
	parameter ADDR_WIDTH = 6,
	// Addr Width in bits : 2 *ADDR_WIDTH = RAM Depth
	parameter DATA_WIDTH = NUM_COL*COL_WIDTH // Data Width in bits
	//----------------------------------------------------------------------
	) (
	   input logic 					 clk,
	   input logic 					 we,
	   input logic [NUM_COL-1:0] 	 bwe,
	   input logic [ADDR_WIDTH-1:0]  addr,
	   output logic [DATA_WIDTH-1:0] dout,
	   input logic [DATA_WIDTH-1:0]  din
	   );

  logic                              we2;
  logic [NUM_COL-1:0]                bwe2;
  logic [ADDR_WIDTH-1:0]             addr2;
  logic [DATA_WIDTH-1:0]             dout2;
  logic [DATA_WIDTH-1:0]             din2;

    always_ff @(posedge clk) begin 
        we2 <= we;
        bwe2 <= bwe;
        addr2 <= addr;
        din2 <= din;
        dout2 <= dout;
    end

    bram1p1rw_64x128wrap dut(clk, we2, bwe2, addr2, dout, din2);

endmodule
