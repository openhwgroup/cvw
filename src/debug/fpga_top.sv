

module top (    
    // jtag logic
    (* mark_debug = "true" *) input tck,tdi,tms,
    (* mark_debug = "true" *) output tdo,

    // dut logic
    input clk,
    (* mark_debug = "true" *) input sys_reset,

    output syncout,
    output [3:0] led
);

`include "config.vh"
import cvw::*;
`include "parameter-defs.vh"
`include "debug.vh"

logic CoreHalt;
logic CoreHaltConfirm;
logic CoreResume;
logic CoreResumeConfirm;
logic ScanEn;
logic ScanIn;
logic ScanOut;
(* mark_debug = "true" *) logic [63:0] r1q, r2q;
logic c1;
logic reg_init;

localparam histlen = 20;
localparam statewidth = 4;
(* mark_debug = "true" *) logic [histlen*statewidth-1:0] state_history;
logic [statewidth-1:0] laststate;

assign reg_init = ~sys_reset;

//assign syncout = dm.dtm.tcks;
//assign led = dm.dtm.jtag.tap.State;

dm #(P) dm (.clk, .rst(~sys_reset), .tck, .tdi, .tms, .tdo,
    .CoreHalt, .CoreHaltConfirm, .CoreResume, .CoreResumeConfirm,
    .ScanEn, .ScanIn, .ScanOut);

dummy_reg #(.WIDTH(64),.CONST(64'hDEADBEEF15a15a15)) r1 (.clk,.en(reg_init),.se(ScanEn),.scan_in(ScanOut),.scan_out(c1),.q(r1q));
dummy_reg #(.WIDTH(64),.CONST(64'h0123456789ABCDEF)) r2 (.clk,.en(reg_init),.se(ScanEn),.scan_in(c1),.scan_out(ScanIn),.q(r2q));


always_ff @(posedge clk) begin
    if (dm.State != laststate && dm.State != dm.ACK && dm.State != dm.IDLE) begin
        state_history <= {state_history[((histlen-1)*4)-1:0],dm.State};
    end
    laststate <= dm.State;  
end

always_ff @(posedge clk) begin
    if (CoreResume) begin
        CoreResumeConfirm <= 1;
        CoreHaltConfirm <= 0;
    end
    if (CoreHalt) begin
        CoreHaltConfirm <= 1;
        CoreResumeConfirm <= 0;
    end
end

endmodule // top