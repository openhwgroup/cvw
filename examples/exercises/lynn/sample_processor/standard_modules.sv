module flopr #(parameter WIDTH, parameter DEFAULT = 0) (
        input   logic               clk,
        input   logic               reset,
        input   logic [WIDTH-1:0]   D,
        output  logic [WIDTH-1:0]   Q
    );

    always_ff @(posedge clk, posedge reset) begin
        if (reset)  Q <= DEFAULT;
        else        Q <= D;
    end

endmodule

module adder (
        input   logic [`XLEN-1:0]   inputA, inputB,
        output  logic [`XLEN-1:0]   result
    );

    assign result = inputA + inputB;

endmodule

module mux2 #(parameter WIDTH) (
        input   logic [WIDTH-1:0]   A,
        input   logic [WIDTH-1:0]   B,
        input   logic               select,

        output  logic [WIDTH-1:0]   result
    );

    assign result = ~select ? A : B;

endmodule
