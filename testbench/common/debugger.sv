module debugger import cvw::*;  #(parameter cvw_t P)(
  input logic clk, reset,
  output logic tck, tms, tdi,
  input logic tdo
);
  localparam int tcktime = 52;
  
  // ANSII color codes
  string red     = "\033[1;31m"; // Red text
  string green   = "\033[1;32m"; // Green text
  string yellow  = "\033[1;33m"; // Yellow text
  string normal  = "\033[0m";  // Reset to default
  string bold    = "\033[1m";

  enum logic {RUN, WAIT} debugger_state;
  
  // ----------------------------------------------------------------
  //  Write instruction task.
  // ----------------------------------------------------------------

  // Changing the instructions happens so infrequently that we need
  // only make a single task for this. The only time we may need to
  // revisit this after initializing is if we need to set DMIReset if
  // we encounter the sticky error in the DMI.
  
  // Task for writing instructions to the DTM
  task write_instr(input logic [4:0] INST);
    logic [11:0] tms_seq;
    logic [11:0] tdi_seq;
    begin
      tms_seq = {4'b0110, 5'b0, 3'b110};
      // Reverse instruction so LSB is first
      tdi_seq = {5'b0, {<<{INST}}, 2'b0};
      
      // Clock should be idling high, TMS should be low keeping
      // us in the Run-test/Idle state and the input should not
      // be driven.
      tck = 1;
      tms = 0;
      tdi = 0;
      
      // SelectIR -> CaptureIR -> ShiftIR
      for (int i = 11; i >= 0; i--) begin
        #(tcktime) tck = ~tck; // low
        tms = tms_seq[i];
        tdi = tdi_seq[i];
        #(tcktime) tck = ~tck; // high
      end
    end   
  endtask // instr
  
  // ----------------------------------------------------------------
  // Classes
  // ----------------------------------------------------------------
   
  // JTAG_DR Class that generalizes the task of reading and writing
  // to the Test Data Regisers. 
  class JTAG_DR #(parameter WIDTH = 32);
    logic [WIDTH-1:0] result;
      
    task read();
      logic [5 + WIDTH + 2 - 1:0] tms_seq = {5'b01000, {(WIDTH-1){1'b0}}, 1'b1, 2'b10};
      for (int i = 5 + WIDTH + 2 - 1; i >= 0; i--) begin
        #(tcktime) tck = ~tck; 
        tdi = 0;
        tms = tms_seq[i];
        if ((i < WIDTH + 2) && (i >= 2)) begin               
          this.result[WIDTH - i + 2-1] = tdo;
        end
        #(tcktime) tck = ~tck;
      end
    endtask // read

    task write(input logic [WIDTH-1:0] val);
      logic [5 + WIDTH + 2 - 1:0] tms_seq = {5'b01000, {(WIDTH-1){1'b0}}, 1'b1, 2'b10};
      for (int i = 5 + WIDTH + 2 - 1; i >= 0; i--) begin
        #(tcktime) tck = ~tck; 
        tms = tms_seq[i];
        if ((i < WIDTH + 2) && (i >= 2)) begin
          tdi = val[WIDTH - i + 2-1];
        end
        this.result[WIDTH - i + 2-1] = tdo;
        #(tcktime) tck = ~tck;
      end
    endtask
  endclass
   
  // Debug Module Interface Abstraction.
  // TODO: Can probably be further abstracted with a Debugger class
  class DMI extends JTAG_DR #(41);
    //logic [40:0] result;
    // DMControl = 0x10
    task read_dmcontrol();
      this.write({7'h10, 32'h0000_0000, 2'b01});
      this.write({7'h10, 32'h0000_0000, 2'b00});
    endtask

    task write_dmcontrol(input logic [31:0] data);
      this.write({7'h10, data, 2'b10});
    endtask

    // DMStatus = 0x11
    task read_dmstatus();
      this.write({7'h11, 32'h0000_0000, 2'b01});
      this.write({7'h11, 32'h0000_0000, 2'b00});
    endtask

    // Command = 0x17
    task read_command();
      this.write({7'h17, 32'h0000_0000, 2'b01});
    endtask

    task write_command(input logic [31:0] data);
      this.write({7'h17, data, 2'b10});
    endtask

    // AbstractCS = 0x16
    task read_abstractcs();
      this.write({7'h16, 32'h0000_0000, 2'b01});
      this.write({7'h16, 32'h0000_0000, 2'b00});
    endtask

    task write_abstractcs(input logic [31:0] data);
      this.write({7'h16, data, 2'b10});
    endtask

    // DATA0 = 0x04
    task read_data0();
      this.write({7'h04, 32'h0000_0000, 2'b01});
      this.write({7'h04, 32'h0000_0000, 2'b00});
    endtask

    task write_data0(input logic [31:0] data);
      this.write({7'h04, data, 2'b10});
    endtask      
  endclass

  // Debugger Class
   
  /* This class is special. It simulates what the debugger is
    * supposed to do as outlined in the RISC-V Debug Specification.
    *
    * - Debugger.initialize():
    *   This initializes the Debug Module by setting DMActive high
    *   then polling for the the setting to take effect.
    *
    * - Debugger.halt():
    *   This sets haltreq high and polls for the halting to have taken
    *   effect in DMStatus before deasserting haltreq.
    *
    * - Debugger.resume():
    *   Sets resumereq high and polls DMStatus for when the processor
    *   resumes.
    *   
    * - Debugger.readreg(regno):
    *   Reads a GPR of the user's choice
    * 
    * - Debugger.readcsr():
    *   
    */
   
  class Debugger;
    // Primary JTAG Registers
    JTAG_DR #(32) idcode;
    JTAG_DR #(32) dtmcs;
    DMI dmireg;

    // For running testvectors instead of the encapsulated tests.
    logic [40:0] testvectors[$];
    logic [40:0] expected_outputs[$];
      
    function new();
      idcode = new();
      dtmcs = new();
      dmireg = new();
    endfunction
      
    // Confirm the DTM is working 
    task initialize();
      write_instr(5'b00001);
      this.idcode.read();
      assert(this.idcode.result == 32'h1002AC05) $display("Received IDCODE");
      else $display("IDCODE was corrupted: 0x%0h", this.idcode.result);

      // Reading DTMCS value
      write_instr(5'b10000);
      this.dtmcs.read();
      assert(this.dtmcs.result == 32'h00100071) $display("DTMCS properly captures default value. dtmcs = 0x%8h", this.dtmcs.result);
      else $display("Something is wrong with DTMCS on reset and capture: dtmcs = 0x%0h", this.dtmcs.result);

      // Set instruction DMI
      write_instr(5'b10001);
    endtask

    task init_dm();
      // Set DMActive
      this.dmireg.write_dmcontrol(32'h0000_0001);
      this.dmireg.read_dmcontrol();
      assert(this.dmireg.result[33:2] == 32'h0000_0001) $display("DMActive was set");
      else $display("Failed to write to DMActive");

      // Read DMControl
      this.dmireg.read_dmcontrol();
      assert(this.dmireg.result[33:2] == 32'h0000_0001) $display("DMControl: 0x%8h, CORRECT", this.dmireg.result[33:2]);
      else $display("DMControl = 0x%8h, FAILED", this.dmireg.result[33:2]);

      // Read AbstractCS
      this.dmireg.read_abstractcs();
      assert(this.dmireg.result[33:2] == 32'h0000_0001) $display("AbstractCS: 0x%8h, CORRECT", this.dmireg.result[33:2]);
      else $display("AbstractCS: 0x%8h, FAILED", this.dmireg.result[33:2]);
    endtask
      
    // Halt the processor, and confirm halted
    task halt();
      this.dmireg.read_dmcontrol();
      this.dmireg.write_dmcontrol(32'h8000_0000 | this.dmireg.result);
      this.dmireg.read_dmstatus();
      // 0000_0000_0000_0000_0000_0011_0000_0000
      // 00000300
      assert(|(this.dmireg.result[33:2] & 32'h0000_0300)) $display("Hart Halted. DMStatus = 0x%8h, CORRECT", this.dmireg.result[33:2]);
      else $display("Hart not halted. DMStatus = 0x%8h, FAILED", this.dmireg.result[33:2]);

      this.dmireg.read_dmcontrol();
      this.dmireg.write_dmcontrol(32'h7fff_ffff & this.dmireg.result);
      this.dmireg.read_dmcontrol();

      assert(|(this.dmireg.result[33:2] & 32'h8000_0000) == 0) $display("Haltreq de-asserted. DMControl = 0x%8h, CORRECT", this.dmireg.result[33:2]);
      else $display("Haltreq NOT de-asserted. DMControl = 0x%8h, FAILED", this.dmireg.result[33:2]);
    endtask

    // Resume the processor, and confirm resume
    task resume();
      this.dmireg.read_dmcontrol();
      this.dmireg.write_dmcontrol(32'h4000_0000 | this.dmireg.result);

      this.dmireg.read_dmstatus();
      assert(|(this.dmireg.result[33:2] & 32'h0000_0c00)) $display("Hart resumed! DMStatus = 0x%8h, CORRECT", this.dmireg.result[33:2]);
      else $display("Hart not resumed. DMStatus = 0x%8h, FAILED", this.dmireg.result[33:2]);

      this.dmireg.read_dmcontrol();
      this.dmireg.write_dmcontrol(32'hbfff_ffff & this.dmireg.result);
      this.dmireg.read_dmcontrol();
         
      assert(|(this.dmireg.result[33:2] & 32'h4000_0000) == 0) $display("Resumereq de-asserted. DMControl = 0x%8h, CORRECT", this.dmireg.result[33:2]);
      else $display("Resumereq NOT de-asserted. DMControl = 0x%8h, FAILED", this.dmireg.result[33:2]);
    endtask

    task command(input logic [31:0] cmd);
      this.dmireg.write_command(cmd);
      this.dmireg.read_data0();
      $display("COMMAND: Data0:\n  op: 0b%2b,\n  data: 0x%8h,\n  addr: 0x%2h", this.dmireg.result[1:0], this.dmireg.result[33:2], this.dmireg.result[40:34]);
    endtask

    task read_abstractcs();
      this.dmireg.read_abstractcs();
      $display("AbstractCS: op: 0b%2b, data: 0x%8h, addr: 0x%2h", this.dmireg.result[1:0], this.dmireg.result[33:2], this.dmireg.result[40:34]);
    endtask

    task readreg(input logic [4:0] regno);
      // 32'h0020_0301
      this.dmireg.write_command({16'h0022, 11'b0001_0000_000, regno});
      this.dmireg.read_data0();
      $display("GPR: Data0:\n  op: 0b%2b,\n  data: 0x%8h,\n  addr: 0x%2h", this.dmireg.result[1:0], this.dmireg.result[33:2], this.dmireg.result[40:34]);
    endtask

    task readcsr(input logic [11:0] regno);
      this.dmireg.write_command({16'h0022, 4'b0, regno});
      this.read_abstractcs();
      this.dmireg.read_data0();
      $display("CSR: Data0 =\n  op: 0b%2b,\n  data: 0x%8h,\n  addr: 0x%2h\n", this.dmireg.result[1:0], this.dmireg.result[33:2], this.dmireg.result[40:34]);
    endtask

    // TESTVECTOR READING. Reading testvectors grabbed from openocd.log
    function void get_testvectors(string filename);
      string line;
      string items[$];
      int    file = $fopen(filename, "r");
         
      while (!$feof(file)) begin
        if ($fgets(line, file)) begin
          // Allow comments and whitespace
          if (line[0] == "#" | line[0] == " " | line[0] == "\n") begin
            continue;
          end
          items = split(line, " ");
          this.testvectors.push_back({items[2].substr(1, 2).atohex(), items[1].atohex(), op_decode(items[0], 0)});
          this.expected_outputs.push_back({items[6].substr(1, 2).atohex(), items[5].atohex(), op_decode(items[4], 1)});
        end
      end 

      // foreach (this.testvectors[i]) begin
      //    $display("testvector[%0d]:\n  addr: %2h, data: %8h, op: %2b", i, this.testvectors[i][40:34], this.testvectors[i][33:2], this.testvectors[i][1:0]);
      // end
         
    endfunction

    task run_testvectors();
      foreach (testvectors[i]) begin
        this.dmireg.write(testvectors[i]);
        $display("\n\033[1mtestvector\033[0m[%0d]: \033[1m addr:\033[0m %2h, data: %8h, op: %2b", i, this.testvectors[i][40:34], this.testvectors[i][33:2], this.testvectors[i][1:0]);
        assert(this.dmireg.result == expected_outputs[i]) begin 
          $display("%sMATCHES%s", green, normal);
        end else begin 
          $display("%sFAILED:%s Simulation does not match FPGA.", red, normal);
        end
        $display("  Expected[%0d] = \033[1m addr:\033[0m %2h, data: %8h, op: %2b", i, this.expected_outputs[i][40:34], this.expected_outputs[i][33:2], this.expected_outputs[i][1:0]);
        $display("  Actual[%0d] =  addr: %2h, data: %8h, op: %2b", i, this.dmireg.result[40:34], this.dmireg.result[33:2], this.dmireg.result[1:0]);
      end
    endtask
     
  endclass
  
  // ----------------------------------------------------------------
  // THE TESTS
  // ----------------------------------------------------------------
  
  // Debug Commands
  initial begin
    JTAG_DR #(32) idcode = new();
    JTAG_DR #(32) dtmcs = new();
    DMI dmireg = new();
    Debugger debugger = new();

    debugger.get_testvectors("../../tests/debug/testvectors.mem");
    
    forever begin
      @(negedge reset);
      debugger.initialize();
      debugger.run_testvectors();
    end
  end
    
endmodule

typedef string stringarr[];
// No native split function in System Verilog. Coming up with a way
// of doing this natively for better testvector parsing.
function automatic stringarr split(string str, string delimiter);
  string result[$];
  int    strlen = str.len();
  string temp = "";
  for (int i = 0; i <= strlen; i++) begin
    if (str[i] == delimiter[0] || (i == strlen && temp.len() != 0) || str[i] == "\n") begin
      result.push_back(temp);
      temp = "";
    end else begin
      temp = {temp, str[i]};
    end
  end
  return result;
endfunction

function automatic logic [1:0] op_decode(string op_str, logic response);
  if (response) begin
    if (op_str == "+") begin
      return 2'b00;
    end else if (op_str == "b") begin
      return 2'b11;
    end else begin
      return 2'b01; // reserved
    end
  end else begin
    if (op_str == "r") begin
      return 2'b01;
    end else if (op_str == "w") begin
      return 2'b10;
    end else if (op_str == "-") begin
      return 2'b00;
    end else begin
      return 2'b11;
    end
  end
  return 2'b00;
endfunction
