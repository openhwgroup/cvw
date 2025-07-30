module dtm(
    input logic clk, trst,
    input logic  tck,
    input logic  tdi,
    input logic tms,
    output logic tdo
);
    // Dummy logic for now.
    assign tdo = 1'b1;
endmodule
