/* -----\/----- EXCLUDED -----\/-----
// Depth is number of bits in one "word" of the memory, width is number of such words

/-* verilator lint_off ASSIGNDLY *-/

module sram1rw #(parameter DEPTH=128, WIDTH=256) (
    input logic 		    clk,
    // port 1 is read only
    input logic [$clog2(WIDTH)-1:0] Addr,
    output logic [DEPTH-1:0] 	    ReadData,
  
    // port 2 is write only
    input logic [DEPTH-1:0] 	    WriteData,
    input logic 		    WriteEnable
);

    logic [WIDTH-1:0][DEPTH-1:0] StoredData;
    logic [$clog2(WIDTH)-1:0] 	 AddrD;
  

    always_ff @(posedge clk) begin
      AddrD <= Addr;
        if (WriteEnable) begin
            StoredData[Addr] <= #1 WriteData;
        end
    end

      
  assign ReadData = StoredData[AddrD];
  
endmodule

/-* verilator lint_on ASSIGNDLY *-/
 -----/\----- EXCLUDED -----/\----- */


// Depth is number of bits in one "word" of the memory, width is number of such words

/* verilator lint_off ASSIGNDLY */

module sram1rw #(parameter DEPTH=128, WIDTH=256) (
    input logic 		    clk,
    // port 1 is read only
    input logic [$clog2(WIDTH)-1:0] Addr,
    output logic [DEPTH-1:0] 	    ReadData,
  
    // port 2 is write only
    input logic [DEPTH-1:0] 	    WriteData,
    input logic 		    WriteEnable
);

    logic [WIDTH-1:0][DEPTH-1:0] StoredData;
    logic [$clog2(WIDTH)-1:0] 	 AddrD;
    logic [WIDTH-1:0] 		 WriteDataD;
    logic 			 WriteEnableD;
  

    always_ff @(posedge clk) begin
      AddrD <= Addr;
      WriteDataD <= WriteData;
      WriteEnableD <= WriteEnable;
        if (WriteEnableD) begin
            StoredData[AddrD] <= #1 WriteDataD;
        end
    end

      
  assign ReadData = StoredData[AddrD];
  
endmodule

/* verilator lint_on ASSIGNDLY */

