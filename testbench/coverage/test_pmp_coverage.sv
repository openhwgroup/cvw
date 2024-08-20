module test_pmp_coverage import cvw::*; #(parameter cvw_t P) (input clk);

// Ensure the covergroup is defined correctly
covergroup cg_priv_mode @(posedge clk);
    coverpoint dut.core.ifu.PrivilegeModeW {
        bins user   = {2'b00};
        bins superv = {2'b01};
        bins hyperv = {2'b10};
        bins mach   = {2'b11};
    }
endgroup

covergroup cg_PMPConfig @(posedge clk);
    coverpoint dut.core.ifu.PMPCFG_ARRAY_REGW[0][0] {
        bins ones    = {1};
        bins zeros = {0};
    }
endgroup


function bit [1:0] getPMPConfigSlice(int index);
    return dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[index][4:3];
endfunction

//if (P.PMP_ENTRIES > 0) begin : pmp
    covergroup cg_pmpcfg_mode @(posedge clk);
            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[0][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }


            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[1][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }

            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[2][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }

            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[3][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }

            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[4][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }

            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[5][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }

            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[6][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }

            coverpoint dut.core.ifu.immu.immu.PMPCFG_ARRAY_REGW[7][4:3] {
                bins off   = {2'b00};
                bins tor   = {2'b01};
                bins na4   = {2'b10};
                bins napot = {2'b11};
            }
    endgroup
//end


// Ensure that the instantiation and sampling of covergroups are within the correct procedural context
initial begin
    cg_priv_mode privmodeCG = new();  // Instantiate the privilege mode covergroup
    cg_PMPConfig pmpconfigCG = new(); // Instantiate the PMP config covergroup
    cg_pmpcfg_mode pmpcfgmodeCG = new();

    forever begin
        @(posedge clk) begin
            privmodeCG.sample();  // Sample the privilege mode covergroup
            pmpconfigCG.sample(); // Sample the PMP config covergroupi
	    pmpcfgmodeCG.sample();
        end
    end
end


endmodule





