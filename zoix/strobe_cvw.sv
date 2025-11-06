// ZOIX MODULE FOR FAULT INJECTION AND STROBING
//`timescale 1ps / 1ns

`define TOPLEVEL wallypipelinedcore_gate
module strobe;

// Inject faults
//initial begin
//
//    $fs_add(wallypipelinedcore_gate);
//$display("ZOIX CIAO");
//
//end

// Strobe point


//#`START_TIME;

initial begin 

    #22;
    forever begin 
        
        $fs_strobe(`TOPLEVEL );
        #10;
        $display("Strobed at %t", $time);
    end
end 

final begin 
    $display ("DONE");
end 


endmodule


//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.instr_addr_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.instr_req_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.data_addr_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.data_wdata_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.data_we_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.data_req_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.data_be_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.apu_master_req_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.apu_master_ready_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.apu_master_operands_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.apu_master_op_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.apu_master_type_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.apu_master_flags_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.irq_ack_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.irq_id_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.debug_rdata_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.debug_gnt_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.debug_rvalid_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.debug_halted_o);
//end
//
//initial begin 
//  #701000;
//
//  forever #40000 $fs_strobe(riscv_core.core_busy_o);
//end
//

