// Depth is number of bits in one "word" of the memory, width is number of such words

/* verilator lint_off ASSIGNDLY */

module sram1rw #(parameter DEPTH=128, WIDTH=256) (
    input logic 		    clk,
    // port 1 is read only
    input logic [$clog2(WIDTH)-1:0] Addr,
    output logic [DEPTH-1:0] 	    ReadData,
  
    // port 2 is write only
    input logic [DEPTH-1:0] 	    WriteData,
    input logic 		    WriteEnable
);

    logic [WIDTH-1:0][DEPTH-1:0] StoredData;

    always_ff @(posedge clk) begin
        ReadData <= StoredData[Addr];
        if (WriteEnable) begin
            StoredData[Addr] <= #1 WriteData;
        end
    end
endmodule

/* verilator lint_on ASSIGNDLY */

