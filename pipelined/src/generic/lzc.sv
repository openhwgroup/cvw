//leading zero counter i.e. priority encoder
module lzc #(parameter WIDTH=1) (
    input logic  [WIDTH-1:0]            num,
    output logic [$clog2(WIDTH+1)-1:0]  ZeroCnt
);
/* verilator lint_off CMPCONST */
    
    logic [$clog2(WIDTH+1)-1:0] i;
    always_comb begin
        i = 0;
        while (~num[WIDTH-1-(32)'(i)] & $unsigned(i) <= $unsigned(($clog2(WIDTH+1))'(WIDTH-1))) i = i+1;  // search for leading one
        ZeroCnt = i;
    end
/* verilator lint_on CMPCONST */
endmodule
