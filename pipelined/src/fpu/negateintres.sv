`include "wally-config.vh"

module negateintres(
    input logic         XSgnM,
    input logic [`NORMSHIFTSZ-1:0]  Shifted,
    input logic         Signed,
    input logic         Int64,
    input logic         Plus1,
    output logic [1:0]          NegResMSBS,
    output logic [`XLEN+1:0]    NegRes
);

    
    // round and negate the positive res if needed
    assign NegRes = XSgnM ? -({2'b0, Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1}) : {2'b0, Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1};
    
    assign NegResMSBS = Signed ? Int64 ? NegRes[`XLEN:`XLEN-1] : NegRes[32:31] :
			              Int64 ? NegRes[`XLEN+1:`XLEN] : NegRes[33:32];

endmodule