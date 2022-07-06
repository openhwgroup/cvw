//leading zero counter i.e. priority encoder
module lzc #(parameter WIDTH = 1) (
    input logic  [WIDTH-1:0]            num,
    output logic [$clog2(WIDTH+1)-1:0]  ZeroCnt
);
/* verilator lint_off CMPCONST */
/* verilator lint_off WIDTH */
    
    int i;
    always_comb begin
        i = 0;
        while (~num[WIDTH-1-i] & (i < WIDTH)) i = i+1;  // search for leading one
        ZeroCnt = i;
    end
/* verilator lint_on WIDTH */
/* verilator lint_on CMPCONST */
endmodule
