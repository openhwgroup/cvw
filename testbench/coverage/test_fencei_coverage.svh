typedef RISCV_instruction #(ILEN, XLEN, FLEN, VLEN, NHART, RETIRE) test_ins_rv64i_t;

covergroup test_fencei_cg with function sample(test_ins_rv64i_t ins);
    option.per_instance = 1; 
    option.comment = "Fence.I";
  
    cp_asm_count : coverpoint ins.ins_str == "fence.i"  iff (ins.trap == 0 )  {
        option.comment = "Number of times instruction is executed";
        bins count[]  = {1};
    }
endgroup

function void test_fencei_sample(int hart, int issue);
    test_ins_rv64i_t ins;

    case (traceDataQ[hart][issue][0].inst_name)
        "fenci"     : begin 
            ins = new(hart, issue, traceDataQ); 
            test_fencei_cg.sample(ins); 
        end
    endcase

endfunction


