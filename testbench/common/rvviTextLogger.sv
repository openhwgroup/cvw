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
    parameter string VENDOR_NAME = "cvw",
    parameter int VENDOR_MAJOR = 1,
    parameter int VENDOR_MINOR = 0
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

    // File handling
    integer file;
    string filename;

    // Track current hart (for general processors, multi-core)
    int current_hart = 0;

    // Track current mode to only output when it changes
    logic [1:0] prev_mode[NHART];
    logic prev_mode_virt[NHART];

    // Track expected retirement slot (moved to module scope)
    int expected_slot[NHART];

    // Track ORDER for each hart (auto-increments per spec)
    longint unsigned order_counter[NHART];

    // Track CYCLE count (delta since last CYCLE output)
    longint unsigned total_cycles;
    longint unsigned last_cycle_output;

    // Track TIME (delta since last TIME output)
    // Assumes time is in picoseconds by default
    time last_time_output;


    // INITIALIZATION - Write File Header
    initial begin
        // Get filename from plusarg, default if not provided
        if (!$value$plusargs("rvvi_trace_file=%s", filename)) begin
            filename = "logs/rvvi_trace.txt";
        end

        file = $fopen(filename, "w");

        if (file == 0) begin
            $display("ERROR: rvviTextLogger could not open %s for writing", filename);
            $finish;
        end

        $display("rvviTextLogger: Writing RVVI-TEXT trace to %s", filename);
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
            expected_slot[i] = 0; // TODO: follow up on this
            order_counter[i] = 0;  // Start order at 0 per spec
        end

        // Initialize cycle and time tracking
        total_cycles = 0;
        last_cycle_output = 0;
        last_time_output = $time;
    end


    // NET CHANGES - Track External Signal Transitions (may not be needed or correct)
    // essentially, if something externally changes (like interrupt) we pull from the rvviTrace interface

    // MAIN TRACE - Process All Harts and Retirement Slots
    always_ff @(posedge rvvi.clk) begin
        // Increment cycle counter
        total_cycles++;

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

        longint unsigned cycle_delta;
        time time_delta;

        insn = rvvi.insn[retire_slot][hart];

        // Determine instruction width (compressed vs full)
        // Compressed instructions: lower 2 bits != 11
        if (insn[1:0] != 2'b11) begin
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
        if (retire_slot != expected_slot[hart] && RETIRE > 1) begin
            $fwrite(file, "ISSUE %0d\n", retire_slot);
        end
        expected_slot[hart] = (retire_slot + 1) % RETIRE;


        // ORDER - Only output if it doesn't follow the auto-increment algorithm
        // The spec says order auto-increments after each RET/TRAP
        // We output ORDER when we need to override the expected value
        if (rvvi.order[retire_slot][hart] != order_counter[hart]) begin
            $fwrite(file, "ORDER %0d ", rvvi.order[retire_slot][hart]);
            order_counter[hart] = rvvi.order[retire_slot][hart];
        end

        // CYCLE - Output cycle delta periodically or on significant events
        // Only output if cycles have elapsed since last output
        // cycle_delta = total_cycles - last_cycle_output;
        // if (cycle_delta > 0) begin
        //     $fwrite(file, "CYCLE %0d ", cycle_delta);
        //     last_cycle_output = total_cycles;
        // end

        // // TIME - Output time delta
        // // Spec says time is in units of TIMESCALE (default picoseconds)
        // time_delta = $time - last_time_output;
        // if (time_delta > 0) begin
        //     $fwrite(file, "TIME %0d ", time_delta);
        //     last_time_output = $time;
        // end


        // RET or TRAP
        if (rvvi.trap[retire_slot][hart]) begin
            $fwrite(file, "TRAP ");
        end else begin
            $fwrite(file, "RET ");
        end

        // PC (formatted based on XLEN)
        if (XLEN == 32) begin
            $fwrite(file, " %08h ", rvvi.pc_rdata[retire_slot][hart]);
        end else if (XLEN == 64) begin
            $fwrite(file, "%016h ", rvvi.pc_rdata[retire_slot][hart]);
        end

        // Instruction encoding (width depends on compressed/full)
        if (insn_bytes == 2) begin
            $fwrite(file, "%04h ", insn[15:0]);
        end else begin
            $fwrite(file, "%08h ", insn);
        end

        // Write register and state changes
        writeGPRChanges(hart, retire_slot);
        writeFPRChanges(hart, retire_slot);
        writeVRChanges(hart, retire_slot);
        writeCSRChanges(hart, retire_slot);
        writeModeChanges(hart, retire_slot);
        writeProcessorState(hart, retire_slot);

        // Update order counter for next instruction (auto-increment algorithm)
        order_counter[hart]++;

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

                // Format: X <index> <register> <value>
                if (XLEN == 32) begin
                    $fwrite(file, "X %2d '%s' %08h ", i, reg_name, rvvi.x_wdata[retire_slot][hart][i]);
                end else if (XLEN == 64) begin
                    $fwrite(file, "X %2d '%s' %016h ", i, reg_name, rvvi.x_wdata[retire_slot][hart][i]);
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
                        $fwrite(file, "F %2d '%s' %08h ", i, reg_name, rvvi.f_wdata[retire_slot][hart][i]);
                    end else if (FLEN == 64) begin
                        $fwrite(file, "F %2d '%s' %016h ", i, reg_name, rvvi.f_wdata[retire_slot][hart][i]);
                    end else if (FLEN == 128) begin
                        $fwrite(file, "F %2d '%s' %032h ", i, reg_name, rvvi.f_wdata[retire_slot][hart][i]);
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
    // task automatic writeCSRChanges(int hart, int retire_slot);
    //     // Iterate through all 4096 possible CSR addresses
    //     // Note: CSR address is in HEX format
    //     for (int i = 0; i < 4096; i++) begin
    //         if (rvvi.csr_wb[retire_slot][hart][i]) begin
    //             // Format: C <address_hex> <value_hex>
    //             if (XLEN == 32) begin
    //                 $fwrite(file, "C %03h %08h ", i, rvvi.csr[retire_slot][hart][i]);
    //             end else if (XLEN == 64) begin
    //                 $fwrite(file, "C %03h %016h ", i, rvvi.csr[retire_slot][hart][i]);
    //             end else begin
    //                 $fwrite(file, "C %03h %h ", i, rvvi.csr[retire_slot][hart][i]);
    //             end
    //         end
    //     end
    // endtask
    task automatic writeCSRChanges(int hart, int retire_slot);
        // Iterate through all 4096 possible CSR addresses
        // Note: CSR address is in HEX format
        for (int i = 0; i < 4096; i++) begin
            if (rvvi.csr_wb[retire_slot][hart][i]) begin
                // Skip auto-incrementing performance counters
                if (i == 'hb00 || i == 'hb02) continue;  // Skip mcycle and minstret for now

                // Format: C <address_hex> <value_hex>
                if (XLEN == 32) begin
                    $fwrite(file, "C %03h %08h ", i, rvvi.csr[retire_slot][hart][i]);
                end else if (XLEN == 64) begin
                    $fwrite(file, "C %03h %016h ", i, rvvi.csr[retire_slot][hart][i]);
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
        // virt_changed = (rvvi.mode_virt[hart] != prev_mode_virt[hart]);

        // MODE - Only write if changed
        if (mode_changed) begin
            $fwrite(file, "MODE %h ", rvvi.mode[retire_slot][hart]);
            prev_mode[hart] = rvvi.mode[retire_slot][hart];
        end

        // VIRT - Only write if changed and non-zero
        // if (virt_changed && rvvi.mode_virt[hart]) begin
        //     $fwrite(file, "VIRT %0d ", rvvi.mode_virt[hart]);
        //     prev_mode_virt[hart] = rvvi.mode_virt[hart];
        // end
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
            default: begin
                $error("rvviTextLogger: Invalid GPR index %0d", idx);
                return "x?";
            end
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
            default: begin
                $error("rvviTextLogger: Invalid FPR index %0d", idx);
                return "f?";
            end
        endcase
    endfunction


    // Close File on Simulation End
    final begin
        if (file != 0) begin
            $fclose(file);
            $display("rvviTextLogger: Trace file closed: %s", filename);
        end
    end

endmodule
