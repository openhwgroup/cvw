// This testbench tests the functionality of the DMI at various clock ratios
// and resets during various stages of command transactions

module testbench ();

`include "debug.vh"
localparam JTAG_DEVICE_ID = 32'hDEADBEEF;

integer i,j,k;
string wave_marker;

logic clk; // core clock
logic rst; // core reset
// JTAG interface
logic tck, tdi, tms, trstn, tdo;

// DMI
logic ReqReady;
logic ReqValid;
logic [`ADDR_WIDTH-1:0] ReqAddress;
logic [31:0] ReqData;
logic [1:0] ReqOP;
logic RspReady;
logic RspValid;
logic [31:0] RspData;
logic [1:0] RspOP;

logic ScanEn;
logic ScanIn;
logic ScanOut;
logic [63:0] r1q, r2q;
logic c1;
logic reg_init;


dm #(.ADDR_WIDTH(`ADDR_WIDTH),.XLEN(64)) dm (.clk, .rst, .ReqReady, .ReqValid, .ReqAddress, 
    .ReqData, .ReqOP, .RspReady, .RspValid, .RspData, .RspOP,
    .ScanEn, .ScanIn, .ScanOut);

dtm #(`ADDR_WIDTH, JTAG_DEVICE_ID) dtm (.*);

dummy_reg #(.WIDTH(64),.CONST(64'hDEADBEEFBAADF00D)) r1 (.clk,.en(reg_init),.se(ScanEn),.scan_in(ScanOut),.scan_out(c1),.q(r1q));
dummy_reg #(.WIDTH(64),.CONST(64'h0123456789ABCDEF)) r2 (.clk,.en(reg_init),.se(ScanEn),.scan_in(c1),.scan_out(ScanIn),.q(r2q));



// clocks
initial begin
  clk = 1;
  forever #4 clk = ~clk;
end
initial begin
  tck = 1;
  forever #19 tck = ~tck;
end

// Initialize logic
initial begin
  i=0; j=0; k=0;
  tms = 1;
  trstn = 1; rst = 0;
  #1 trstn = 0; rst = 1;
  #1 trstn = 1; rst = 0;
  // for dummy scan register
  reg_init = 1;
  #20 reg_init = 0;
end

static logic [31:0] data = 0;

initial begin
  
  #10;

  wave_marker = "Scan ID";
  ScanID(tck, tms, tdi, tdo);
  
  wave_marker = "Scan DTMCS";
  ScanDTMCS(tck, tms, tdi, tdo, .dtmhardreset(0), .dmireset(1));

  $display("Activating Debug Module");
  wave_marker = "Write DMCONTROL (dmactive=1)";
  data = 0; data[`DMACTIVE] = 1;
  ScanDMI(tck, tms, tdi, tdo, .addr(`DMCONTROL), .op(`OP_WRITE), .data(data));

  wave_marker = "Wait for DMACTIVE to assert";
  while (1) begin
    ScanDMI(tck, tms, tdi, tdo, .addr(`DMCONTROL), .op(`OP_READ), .scanout(data));
    if (data[`DMACTIVE])
      break;
  end

  $display("Halting Hart");
  wave_marker = "Write DMCONTROL (haltreq=1)";
  data = 1; data[`HALTREQ] = 1;
  ScanDMI(tck, tms, tdi, tdo, .addr(`DMCONTROL), .op(`OP_WRITE), .data(data));
  $display("Reading DMCONTROL");
  wave_marker = "Read DMCONTROL";
  ScanDMI(tck, tms, tdi, tdo, .addr(`DMCONTROL), .op(`OP_READ));
  
  $display("Reading Register 2 (send read command)");
  wave_marker = "Transfer R2 to Data1,0";
  data = 0; data[`CMDTYPE] = `ACCESS_REGISTER; data[`TRANSFER] = 1; data[`AARWRITE] = 0;
  ScanDMI(tck, tms, tdi, tdo, .addr(`COMMAND), .op(`OP_WRITE), .data(data));
  
  // wait for shift to complete
  
  // read continueusly until we dont get a busy signal
  $display("Reading message register DATA1, DATA0");
  wave_marker = "Read Data1";
  ScanDMI(tck, tms, tdi, tdo, .addr(`DATA1), .op(`OP_READ));
  wave_marker = "Read Data0";
  ScanDMI(tck, tms, tdi, tdo, .addr(`DATA0), .op(`OP_READ));
  $display("R1Q: %h", r1q);
  $display("R2Q: %h", r2q);

  //mw
  //trstn = 0; #20 trstn = 1;
  
  $display("Writing 00000000_BAADFEED to R1");
  wave_marker = $sformatf("Write Data1 %h",32'h0);
  ScanDMI(tck, tms, tdi, tdo, .addr(`DATA1), .op(`OP_WRITE), .data(32'h0));
  wave_marker = "Read Data1";
  ScanDMI(tck, tms, tdi, tdo, .addr(`DATA1), .op(`OP_READ));
  wave_marker = $sformatf("Write Data0 %h",32'hBAADFEED);
  ScanDMI(tck, tms, tdi, tdo, .addr(`DATA0), .op(`OP_WRITE), .data(32'hBAADFEED));
  wave_marker = "Read Data0";
  ScanDMI(tck, tms, tdi, tdo, .addr(`DATA0), .op(`OP_READ));
  wave_marker = "Transfer Data1,0 to R1";
  data = 0; data[`CMDTYPE] = `ACCESS_REGISTER; data[`TRANSFER] = 1; data[`AARWRITE] = 1;
  ScanDMI(tck, tms, tdi, tdo, .addr(`COMMAND), .op(`OP_WRITE), .data(data));
  $display("R1Q: %h", r1q);
  $display("R2Q: %h", r2q);


  // Poll ABSTRACTCS until not busy
  WaitForNotBusy(tck, tms, tdi, tdo);
  $display("R1Q: %h", r1q);
  $display("R2Q: %h", r2q);
  
  $finish();
end

endmodule: testbench


task automatic ScanID (
  ref tck, tms, tdi, tdo
);

  integer i,j = 0;
  logic [48:0] tdi_vector;
  logic [48:0] tms_vector;
  logic [31:0] read_buffer;
  tms_vector = {<<{14'b01100_00001_1100,32'b1,3'b100}};
  tdi_vector = {<<{14'b00000_10000_0000,32'b0,3'b0}};

  $display("Retrieving JTAG ID");
  for (i=0; i<49; i=i+1) begin
    @(negedge tck) begin
      tms = tms_vector[i];
      tdi = tdi_vector[i];
    end
    
    @(posedge tck) begin
      if (i>13) begin
        read_buffer[j] = tdo;
        j=j+1;
      end
    end
  end
  if (read_buffer == 32'hDEADBEEF)
    $display("JTAG ID output: %h", read_buffer);
  else
    $error("Error: JTAG ID is incorrect: %h", read_buffer[31:0]);

endtask: ScanID


task automatic ScanDTMCS (
  ref tck, tms, tdi, tdo,
  input dtmhardreset, dmireset
);

  integer i,j = 0;
  logic [84:0] tdi_vector;
  logic [84:0] tms_vector;
  logic [31:0] read_buffer;
  tms_vector = {<<{14'b01100_00001_1100, 32'b1, 4'b1100, 32'b1, 3'b100}};
  tdi_vector = {<<{14'b00000_00001_0000, {<<{14'b0, dtmhardreset, dmireset, 16'b0}}, 4'b0, 32'b0, 3'b0}}; // TODO: Source of Invalid DMI access???

  $display("Scanning DTMCS (dtmhardreset: %b | dmireset: %b)", dtmhardreset, dmireset);
  for (i=0; i<85; i=i+1) begin
    @(negedge tck) begin
      tms = tms_vector[i];
      tdi = tdi_vector[i];
    end

    @(posedge tck) begin
      if (i>49) begin
        read_buffer[j] = tdo;
        j=j+1;
      end
    end
  end
  $display("errinfo: %h | dtmhardreset: %h | dmireset: %h | idle: %h | dmistat: %h | abits: %h | version: %h", 
          read_buffer[20:18], read_buffer[17], read_buffer[16], read_buffer[14:12],
          read_buffer[11:10], read_buffer[9:4], read_buffer[3:0]);

endtask: ScanDTMCS


bit trash;
task automatic ScanDMI (
  ref tck, tms, tdi, tdo,
  input [`ADDR_WIDTH-1:0] addr,
  input [31:0] data = 0,
  input [1:0] op,
  output [31:0] scanout = trash
);
  localparam DMI_WIDTH = `ADDR_WIDTH + 32 + 2;

  integer i, j = 0;
  if (op == `OP_READ) begin
    logic [2*DMI_WIDTH+20:0] tdi_vector;
    logic [2*DMI_WIDTH+20:0] tms_vector;
    logic [DMI_WIDTH-1:0] read_buffer;
    logic [`ADDR_WIDTH-1] rsp_addr;
    logic [31:0] rsp_data;
    logic [1:0] rsp_op;
    tms_vector = {<<{14'b01100_00001_1100, {{(DMI_WIDTH-1){1'b0}},1'b1}, 4'b1100, {{(DMI_WIDTH-1){1'b0}},1'b1}, 3'b100}};
    tdi_vector = {<<{14'b00000_10001_0000, {<<{addr, data, op}}, 4'b0, {DMI_WIDTH{1'b0}}, 3'b0}};

    for (i=0; i<(2*DMI_WIDTH+21); i=i+1) begin
      @(negedge tck) begin
        tms = tms_vector[i];
        tdi = tdi_vector[i];
      end
      
      @(posedge tck) begin
        if (i>(DMI_WIDTH+17)) begin
          read_buffer[j] = tdo;
          j=j+1;
        end
      end
    end
    {rsp_addr, rsp_data, rsp_op} = read_buffer;
    scanout = rsp_data;

    case (addr) inside
      [`DATA0:`DATA11] : begin
        $display("Data: %h", rsp_data);
      end
      `DMCONTROL : begin
        $display("haltreq: %h | resumereq: %h | hartreset: %h | ackhavereset: %h | ackunavail: %h\
 | hasel: %h | hartsello: %h | hartselhi: %h | setkeepalive: %h | clrkeepalive: %h\
 | setresethaltreq: %h | clrresethaltreq: %h | ndmreset: %h | dmactive: %h", 
          rsp_data[`HALTREQ], rsp_data[`RESUMEREQ], rsp_data[`HARTRESET], 
          rsp_data[`ACKHAVERESET], rsp_data[`ACKUNAVAIL], rsp_data[`HASEL], 
          rsp_data[`HARTSELLO], rsp_data[`HARTSELHI], rsp_data[`SETKEEPALIVE], 
          rsp_data[`CLRKEEPALIVE], rsp_data[`SETRESETHALTREQ], rsp_data[`CLRRESETHALTREQ], 
          rsp_data[`NDMRESET], rsp_data[`DMACTIVE]);
      end
    endcase

  end else begin
    logic [DMI_WIDTH+16:0] tdi_vector;
    logic [DMI_WIDTH+16:0] tms_vector;
    tms_vector = {<<{14'b01100_00001_1100, {{(DMI_WIDTH-1){1'b0}},1'b1}, 3'b100}};
    tdi_vector = {<<{14'b00000_10001_0000, {<<{addr, data, op}}, 3'b0}};
    for (i=0; i<(DMI_WIDTH+17); i=i+1) begin
      @(negedge tck) begin
        tms = tms_vector[i];
        tdi = tdi_vector[i];
      end
    end
  end

endtask: ScanDMI

task automatic WaitForNotBusy (
  ref tck, tms, tdi, tdo
);
  static logic [31:0] data;

  while (1) begin
    ScanDMI(tck, tms, tdi, tdo, .addr(`ABSTRACTCS), .op(`OP_READ), .scanout(data));
    if (~data[`BUSY])
      break;
  end
endtask : WaitForNotBusy