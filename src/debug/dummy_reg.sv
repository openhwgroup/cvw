// this module exists for testing purposes only

module dummy_reg #(parameter WIDTH=32, parameter CONST) (
    input  logic clk, en, se,
    input  logic scan_in,
    output logic scan_out,
    output logic [WIDTH-1:0] q
);

flopenrs #(.WIDTH(WIDTH)) sr (.clk, .reset(1'b0), .en, .scan(se), .scanin(scan_in), .scanout(scan_out), .d(CONST), .q);

endmodule