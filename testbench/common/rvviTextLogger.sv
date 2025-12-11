///////////////////////////////////////////
// rvviTextLogger.sv
//
// Written: Sadhvi Narayanan sanarayanan@hmc.edu
// Generic RVVI-TRACE to RVVI-TEXT converter
// Works with any RISC-V processor implementing RVVI-TRACE
//
// Converts the rvviTrace interface to RVVI-TEXT format
// for use with coverage tools, reference models, and analysis
//
// Fully parameterized - no processor-specific dependencies
///////////////////////////////////////////

module rvviTextLogger #(
    parameter string FILENAME = "logs/rvvi_trace.txt", // TODO: not sure what default should be
    parameter string VENDOR_NAME = "Placeholdr",
    parameter int VENDOR_MAJOR = 1,
    parameter int VENDOR_MINOR = 0,
    parameter bit COMPRESSED_WIDTH_16 = 1  // Detect compressed instructions by width
) (
    rvviTrace rvvi  // Only input for now - RVVI-TRACE interface
);

    // Extract standard parameters from the interface
    localparam int ILEN = rvvi.ILEN;
    localparam int XLEN = rvvi.XLEN;
    localparam int FLEN = rvvi.FLEN;
    localparam int VLEN = rvvi.VLEN;
    localparam int NHART = rvvi.NHART;
    localparam int RETIRE = rvvi.RETIRE;

    // need someway handle the file
    integer file;

    // Track current hart (for general processors, multi-core)
    int current_hart = 0;

    // Track current mode to only output when it changes
    logic [1:0] prev_mode[NHART];
    logic prev_mode_virt[NHART];


    // INITIALIZATION - Write File Header
    initial begin
        file = $fopen(FILENAME, "w");

        if (file == 0) begin
            $display("ERROR: rvviTextLogger could not open %s for writing", FILENAME);
            $finish;
        end

        $display("rvviTextLogger: Writing RVVI-TEXT trace to %s", FILENAME);
        $display("  Parameters: ILEN=%0d XLEN=%0d FLEN=%0d VLEN=%0d NHART=%0d RETIRE=%0d",
                 ILEN, XLEN, FLEN, VLEN, NHART, RETIRE);

        // Write RVVI-TEXT header
        $fwrite(file, "VERSION 0 1\n");
        $fwrite(file, "VENDOR %s %0d %0d\n", VENDOR_NAME, VENDOR_MAJOR, VENDOR_MINOR);
        $fwrite(file, "PARAMS 6 ILEN %0d XLEN %0d FLEN %0d VLEN %0d NHART %0d RETIRE %0d\n",
                ILEN, XLEN, FLEN, VLEN, NHART, RETIRE);

        // Write initial HART 0 (default hart)
        if (NHART > 0) begin
            $fwrite(file, "HART 0\n");
        end

        // Initialize mode tracking
        for (int i = 0; i < NHART; i++) begin
            prev_mode[i] = 2'b11;  // Start in M-mode
            prev_mode_virt[i] = 0;
        end
    end


    // NET CHANGES - Track External Signal Transitions (may not be needed or correct)
    // essentially, if something externallly changes (like interrupt) we pull from the rvviTrace interface

    // net_pop() function will retrieve net changes from the standard RVVI-TRACE API interface
    string net_name;
    logic [XLEN-1:0] net_value;

    always_ff @(posedge rvvi.clk) begin
        // Pop all available NET changes
        while (rvvi.net_pop(net_name, net_value)) begin
            $fwrite(file, "NET %s %h\n", net_name, net_value);
        end
    end


    // MAIN TRACE - Process All Harts and Retirement Slots
    always_ff @(posedge rvvi.clk) begin
        for (int hart = 0; hart < NHART; hart++) begin
            for (int retire_slot = 0; retire_slot < RETIRE; retire_slot++) begin
                if (rvvi.valid[retire_slot][hart]) begin
                    writeTraceEvent(hart, retire_slot);
                end
            end
        end
    end


    // Write Complete Trace Event
    task automatic writeTraceEvent(int hart, int retire_slot);
        logic [ILEN-1:0] insn;
        int insn_bytes;

        insn = rvvi.insn[retire_slot][hart];

        // Determine instruction width (compressed vs full)
        // Compressed instructions: lower 2 bits != 11
        if (COMPRESSED_WIDTH_16 && (insn[1:0] != 2'b11)) begin
            insn_bytes = 2;  // 16-bit compressed
        end else begin
            insn_bytes = 4;  // 32-bit full
        end

        // HART switching (only if changed)
        if (hart != current_hart) begin
            $fwrite(file, "HART %0d\n", hart);
            current_hart = hart;
        end

        // ISSUE (retirement slot) - only needed for superscalar
        // According to RVVI-TEXT spec, slot auto-increments
        static int expected_slot[NHART];
        if (retire_slot != expected_slot[hart] && RETIRE > 1) begin
            $fwrite(file, "ISSUE %0d ", retire_slot);
        end
        expected_slot[hart] = (retire_slot + 1) % RETIRE;


        // RET or TRAP
        if (rvvi.trap[retire_slot][hart]) begin
            $fwrite(file, "TRAP ");
        end else begin
            $fwrite(file, "RET ");
        end

        // PC (formatted based on XLEN)
        if (XLEN == 32) begin
            $fwrite(file, " %5h ", rvvi.pc_rdata[retire_slot][hart][31:0]);
        end else if (XLEN == 64) begin
            $fwrite(file, "%6h ", rvvi.pc_rdata[retire_slot][hart][63:0]);
        end else begin
            $fwrite(file, "%h ", rvvi.pc_rdata[retire_slot][hart]);
        end

        // Instruction encoding (width depends on compressed/full)
        if (insn_bytes == 2) begin
            $fwrite(file, "%04h ", insn[15:0]);
        end else begin
            $fwrite(file, "%08h ", insn[31:0]);
        end

        // Write register and state changes
        writeGPRChanges(hart, retire_slot);
        writeFPRChanges(hart, retire_slot);
        writeVRChanges(hart, retire_slot);
        writeCSRChanges(hart, retire_slot);
        writeModeChanges(hart, retire_slot);
        writeProcessorState(hart, retire_slot);

        // End of line
        $fwrite(file, "\n");
    endtask


    // Write GPR Changes
    task automatic writeGPRChanges(int hart, int retire_slot);
        string reg_name;

        // 32 registers to look at
        for (int i = 0; i < 32; i++) begin
            if (rvvi.x_wb[retire_slot][hart][i]) begin
                // Get register name
                reg_name = getGPRName(i);

                // Format: X <index> <value>
                if (XLEN == 32) begin
                    $fwrite(file, "X %2d '%s' %08h ", i, reg_name, rvvi.x_wdata[retire_slot][hart][i][31:0]);
                end else if (XLEN == 64) begin
                    $fwrite(file, "X %2d '%s' %016h ", i, reg_name, rvvi.x_wdata[retire_slot][hart][i][63:0]);
                end else begin
                    $fwrite(file, "X %0d '%s' %h ", i, reg_name, rvvi.x_wdata[retire_slot][hart][i]);
                end
            end
        end
    endtask


    // Write FPR Changes (similar to above)
    task automatic writeFPRChanges(int hart, int retire_slot);
        string reg_name;

        if (FLEN > 0) begin
            for (int i = 0; i < 32; i++) begin
                if (rvvi.f_wb[retire_slot][hart][i]) begin
                    // Get register name
                    reg_name = getFPRName(i);

                    // Format: F <index> <value>
                    if (FLEN == 32) begin
                        $fwrite(file, "F %2d '%s' %08h ", i, reg_name, rvvi.f_wdata[retire_slot][hart][i][31:0]);
                    end else if (FLEN == 64) begin
                        $fwrite(file, "F %2d '%s' %016h ", i, reg_name, rvvi.f_wdata[retire_slot][hart][i][63:0]);
                    end else if (FLEN == 128) begin
                        $fwrite(file, "F %2d '%s' %032h ", i, reg_name, rvvi.f_wdata[retire_slot][hart][i][127:0]);
                    end else begin
                        $fwrite(file, "F %0d '%s' %h ", i, reg_name, rvvi.f_wdata[retire_slot][hart][i]);
                    end
                end
            end
        end
    endtask


    // Write Vector Register Changes (can't find this in wallyTracer - double check)
    task automatic writeVRChanges(int hart, int retire_slot);
        if (VLEN > 0) begin
            for (int i = 0; i < 32; i++) begin
                if (rvvi.v_wb[retire_slot][hart][i]) begin
                    // Format: V <index> <value>
                    $fwrite(file, "V %2d %h ", i, rvvi.v_wdata[retire_slot][hart][i]);
                end
            end
        end
    endtask


    // Write CSR Changes
    task automatic writeCSRChanges(int hart, int retire_slot);
        // Iterate through all 4096 possible CSR addresses
        // Note: made CSR address is in HEX format
        for (int i = 0; i < 4096; i++) begin
            if (rvvi.csr_wb[retire_slot][hart][i]) begin
                // Format: C <address_hex> <value_hex>
                if (XLEN == 32) begin
                    $fwrite(file, "C %03h %08h ", i, rvvi.csr[retire_slot][hart][i][31:0]);
                end else if (XLEN == 64) begin
                    $fwrite(file, "C %03h %016h ", i, rvvi.csr[retire_slot][hart][i][63:0]);
                end else begin
                    $fwrite(file, "C %03h %h ", i, rvvi.csr[retire_slot][hart][i]);
                end
            end
        end
    endtask


    // Write Mode Changes (only when changed)
    task automatic writeModeChanges(int hart, int retire_slot);
        logic mode_changed;
        logic virt_changed;

        mode_changed = (rvvi.mode[retire_slot][hart] != prev_mode[hart]);
        virt_changed = (rvvi.mode_virt[retire_slot][hart] != prev_mode_virt[hart]);

        // MODE - Only write if changed
        if (mode_changed) begin
            $fwrite(file, "MODE %h ", rvvi.mode[retire_slot][hart]);
            prev_mode[hart] = rvvi.mode[retire_slot][hart];
        end

        // VIRT - Only write if changed and non-zero
        if (virt_changed && rvvi.mode_virt[retire_slot][hart]) begin
            $fwrite(file, "VIRT %0d ", rvvi.mode_virt[retire_slot][hart]);
            prev_mode_virt[hart] = rvvi.mode_virt[retire_slot][hart];
        end
    endtask


    // Write Processor State
    task automatic writeProcessorState(int hart, int retire_slot);
        // INTR - First instruction of interrupt handler
        if (rvvi.intr[retire_slot][hart]) begin
            $fwrite(file, "INTR 1 ");
        end

        // HALT - Processor halted (e.g., WFI)
        if (rvvi.halt[retire_slot][hart]) begin
            $fwrite(file, "HALT 1 ");
        end

        // DM - Debug mode
        // TODO: do we need something for debug mode?
    endtask


    // FUNCTION: Get GPR Name
    function automatic string getGPRName(int idx);
        case (idx)
            0:  return "zero";
            1:  return "ra";
            2:  return "sp";
            3:  return "gp";
            4:  return "tp";
            5:  return "t0";
            6:  return "t1";
            7:  return "t2";
            8:  return "s0";
            9:  return "s1";
            10: return "a0";
            11: return "a1";
            12: return "a2";
            13: return "a3";
            14: return "a4";
            15: return "a5";
            16: return "a6";
            17: return "a7";
            18: return "s2";
            19: return "s3";
            20: return "s4";
            21: return "s5";
            22: return "s6";
            23: return "s7";
            24: return "s8";
            25: return "s9";
            26: return "s10";
            27: return "s11";
            28: return "t3";
            29: return "t4";
            30: return "t5";
            31: return "t6";
            default: return "x?";
        endcase
    endfunction


    // FUNCTION: Get FPR Name
    function automatic string getFPRName(int idx);
        case (idx)
            0:  return "ft0";
            1:  return "ft1";
            2:  return "ft2";
            3:  return "ft3";
            4:  return "ft4";
            5:  return "ft5";
            6:  return "ft6";
            7:  return "ft7";
            8:  return "fs0";
            9:  return "fs1";
            10: return "fa0";
            11: return "fa1";
            12: return "fa2";
            13: return "fa3";
            14: return "fa4";
            15: return "fa5";
            16: return "fa6";
            17: return "fa7";
            18: return "fs2";
            19: return "fs3";
            20: return "fs4";
            21: return "fs5";
            22: return "fs6";
            23: return "fs7";
            24: return "fs8";
            25: return "fs9";
            26: return "fs10";
            27: return "fs11";
            28: return "ft8";
            29: return "ft9";
            30: return "ft10";
            31: return "ft11";
            default: return "f?";
        endcase
    endfunction


    // Close File on Simulation End
    final begin
        if (file != 0) begin
            $fclose(file);
            $display("rvviTextLogger: Trace file closed: %s", FILENAME);
        end
    end

endmodule
