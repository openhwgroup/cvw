// Daniel Fajardo
// dfajardo@g.hmc.edu
// 2/8/2025

module fma16(input logic [15:0] x, y, z,
        input logic mul, add, negp, negz,
        input logic [1:0] roundmode,
        output logic [15:0] result,
        output logic [3:0] flags);

        fmul_0 fmul_0(x, y, z, mul, add, negp, negz, roundmode, result, flags);

endmodule

// fmul_0 multiplies two positive half-precision floats with exponents of 0
// the two inputs will be 16 bits
// the sign bit will be 0, and the bias will be 15, ie the two inputs will be of the form 0_01111_xxxxxxxxxx
module fmul_0(input logic [15:0] x, y, z,
        input logic mul, add, negp, negz,
        input logic [1:0] roundmode,
        output logic [15:0] result,
        output logic [3:0] flags);
        logic [9:0] fx, fy;
        logic [10:0] fresult;
        logic [19:0] fxfy;
        logic [4:0] exp;

        assign fx = x[9:0];
        assign fy = y[9:0];
        // fresult = fx + fy + (fx*fy)
        assign fxfy = fx*fy;
        assign fresult = ({1'b0,fx} + {1'b0,fy}) + {1'b0,fxfy[19:10]};
        always_comb begin
                // if fc is >1, change exponent output bias to 16
                if (fresult[10]) begin
                        exp = 5'b10000;
                        result = {1'b0, exp, 1'b0, fresult[9:1]};
                end
                else begin 
                        exp = 5'b01111;
                        result = {1'b0, exp, fresult[9:0]};
                        end
        end
        assign flags = 4'b0000;       
endmodule