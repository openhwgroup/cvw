

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

logic HaltReq;
logic HaltConfirm;
logic ResumeReq;
logic ResumeConfirm;
logic ScanEn;
logic ScanIn;
logic ScanOut;
(* mark_debug = "true" *) logic [P.E_SUPPORTED+3:0] DebugGPRAddr;

logic [7:0] c;
logic reg_init;

localparam histlen = 20;
localparam statewidth = 4;
(* mark_debug = "true" *) logic [histlen*statewidth-1:0] state_history;
logic [statewidth-1:0] laststate;

assign reg_init = ~sys_reset;

assign syncout = dm.dtm.tcks;
assign led = dm.dtm.jtag.tap.State;

dm #(P) dm (.clk, .rst(~sys_reset), .tck, .tdi, .tms, .tdo,
    .HaltReq, .ResumeReq, .HaltConfirm, .ResumeConfirm,
    .ScanEn, .ScanIn, .ScanOut, .DebugGPRAddr);

(* mark_debug = "true" *) logic [1:0] memrwm;
(* mark_debug = "true" *) logic instrvalid;
(* mark_debug = "true" *) logic [63:0] writedatam;
(* mark_debug = "true" *) logic [63:0] ieuadrm;
(* mark_debug = "true" *) logic [(P.LLEN+1):0] readdatam;

if (P.ZICSR_SUPPORTED) begin
    (* mark_debug = "true" *) logic [63:0] misa;
    (* mark_debug = "true" *) logic trapm;
    dummy_reg #(.WIDTH(64),.CONST(64'hDEADBEEF15a15a15)) imisa (.clk,.en(reg_init),.se(ScanEn),.scan_in(ScanOut),.scan_out(c[0]),.q(misa));
    dummy_reg #(.WIDTH(1),.CONST(1'b1)) itrapm (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[0]),.scan_out(c[1]),.q(trapm));
end else begin
    assign c[0] = ScanOut;
    assign c[1] = c[0];
end

if (P.ZICSR_SUPPORTED | P.BPRED_SUPPORTED) begin
    (* mark_debug = "true" *) logic [63:0] pcm;
    dummy_reg #(.WIDTH(64),.CONST(64'h0023456789ABCD00)) ipcm (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[1]),.scan_out(c[2]),.q(pcm));
end else
    assign c[2] = c[1];

if (P.ZICSR_SUPPORTED | P.A_SUPPORTED) begin
    (* mark_debug = "true" *) logic [31:0] instrm;
    dummy_reg #(.WIDTH(32),.CONST(32'h0051a500)) iinstrm (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[2]),.scan_out(c[3]),.q(instrm));
end else
    assign c[3] = c[2];
    
dummy_reg #(.WIDTH(2),.CONST(2'b10)) imemrwm (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[3]),.scan_out(c[4]),.q(memrwm));
dummy_reg #(.WIDTH(1),.CONST(1'b1)) iinstrvalid (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[4]),.scan_out(c[5]),.q(instrvalid));
dummy_reg #(.WIDTH(64),.CONST(64'hFF23456789ABCDFF)) iwritedatam (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[5]),.scan_out(c[6]),.q(writedatam));
dummy_reg #(.WIDTH(64),.CONST(64'hFFAEDAEDDEEDF0FF)) iieuadrm (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[6]),.scan_out(c[7]),.q(ieuadrm));
dummy_reg #(.WIDTH(P.LLEN+1),.CONST(0)) ireaddatam (.clk,.en(reg_init),.se(ScanEn),.scan_in(c[7]),.scan_out(ScanIn),.q(readdatam));


always_ff @(posedge clk) begin
    if (dm.State != laststate && dm.State != dm.ACK && dm.State != dm.IDLE) begin
        state_history <= {state_history[((histlen-1)*4)-1:0],dm.State};
    end
    laststate <= dm.State;  
end

always_ff @(posedge clk) begin
    if (ResumeReq) begin
        ResumeConfirm <= 1;
        HaltConfirm <= 0;
    end
    if (HaltReq) begin
        HaltConfirm <= 1;
        ResumeConfirm <= 0;
    end
end

endmodule // top