//James Kaden Cassidy jkc.cassidy@gmail.com 12/20/2024

module vectorStorage #(
    parameter ADDRESS_BITS,
    parameter DATA_BITS,
    parameter MEMORY_SIZE_ENTRIES,
    parameter MEMORY_FILE_BASE_ADDRESS   = 0,
    parameter MEMORY_ADR_OFFSET     = 0,
    parameter MEMORY_FILE_PATH      = "",
    parameter MEMFILE_PLUS_ARG      = ""
) (
    input   logic                       clk,
    input   logic                       reset,

    input   logic                       En,
    input   logic                       WriteEn,
    input   logic[(DATA_BITS/8)-1:0]    WriteByteEn,

    input   logic[ADDRESS_BITS-1:0]     MemoryAddress,
    input   logic[DATA_BITS-1:0]        WriteData,

    output  logic[DATA_BITS-1:0]        ReadData
);

    // allows memory to be loaded from arbitrary position within InitMem rather than just from the beginning
    localparam int EXTRA_ENTRIES = (MEMORY_ADR_OFFSET - MEMORY_FILE_BASE_ADDRESS) / (DATA_BITS/8);
    logic[DATA_BITS-1:0] InitMem [MEMORY_SIZE_ENTRIES - 1 + EXTRA_ENTRIES : 0];

    logic[DATA_BITS-1:0] Memory[MEMORY_SIZE_ENTRIES-1:0];

    assign ReadData = En ? Memory[(MemoryAddress-MEMORY_ADR_OFFSET)>>2] : 'x;

    always_ff @(posedge clk) begin
        if (reset) begin
            int i;
            for (i = 0; i < MEMORY_SIZE_ENTRIES; i++) begin
                Memory[i] = InitMem [EXTRA_ENTRIES + i];
            end
        end else if (En && unsigned'(MemoryAddress) < MEMORY_ADR_OFFSET ||
                    unsigned'(MemoryAddress) > MEMORY_ADR_OFFSET + (MEMORY_SIZE_ENTRIES-1) * DATA_BITS) begin
            $display("ERROR: memory out-of-range addr %h", MemoryAddress);
            $finish(-1);

        end else if (WriteEn && En) begin
            logic[DATA_BITS-1:0] LocalReadData;

            LocalReadData = Memory[(MemoryAddress-MEMORY_ADR_OFFSET)>>2];

            for (int i = 0; i < (DATA_BITS/8); i++) begin
                if (WriteByteEn[i]) begin
                    LocalReadData[((i+1)*8-1) -: 8] = WriteData[((i+1)*8-1) -: 8];
                end
            end

            Memory[(MemoryAddress-MEMORY_ADR_OFFSET)>>2] <= LocalReadData;
        end
    end

    initial begin
        string memfile;
        int i;

        if (MEMORY_FILE_PATH !== "") begin
            $display("Loading Memory: " + MEMORY_FILE_PATH);
            $readmemh(MEMORY_FILE_PATH, InitMem);
        end else if (MEMFILE_PLUS_ARG !== "") begin
            // Try to read +MEMFILE=<path> from vsim command line
            if (!$value$plusargs({MEMFILE_PLUS_ARG,"=%s"}, memfile)) begin
                $display("ERROR: +%s not supplied", MEMFILE_PLUS_ARG);
                $finish(-1);
            end else begin
                $display("INFO: Using MEMFILE = '%s'", memfile);
            end
            $readmemh(memfile, InitMem);
        end else begin
            for (i = 0; i < MEMORY_SIZE_ENTRIES + EXTRA_ENTRIES; i++) begin
                InitMem [i] = 'x;
            end
        end

    end


endmodule
