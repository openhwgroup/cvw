// this module exists for testing purposes only

module dummy_reg #(parameter WIDTH=32, parameter CONST) (
    input  logic clk, en, se,
    input  logic scan_in,
    output logic scan_out,
    output logic [WIDTH-1:0] q
);

scan_reg #(.WIDTH(WIDTH)) sr (.clk, .en, .se, .scan_in, .scan_out, .d(CONST), .q);

endmodule