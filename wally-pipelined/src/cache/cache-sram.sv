// Depth is number of bits in one "word" of the memory, width is number of such words
module Sram1Read1Write #(parameter DEPTH=128, WIDTH=256) (
    input logic clk,
    // port 1 is read only
    input  logic [$clog2(WIDTH)-1:0] ReadAddr,
    output logic [DEPTH-1:0] ReadData,
  
    // port 2 is write only
    input logic [$clog2(WIDTH)-1:0]  WriteAddr,
    input logic [DEPTH-1:0]  WriteData,
    input logic 		     WriteEnable
);

    logic [WIDTH-1:0][DEPTH-1:0] StoredData;

    always_ff @(posedge clk) begin
        ReadData <= StoredData[ReadAddr];
        if (WriteEnable) begin
            StoredData[WriteAddr] <= WriteData;
        end
    end
endmodule
