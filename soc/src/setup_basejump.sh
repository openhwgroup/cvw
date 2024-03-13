#! /bin/bash

git submodule deinit -f basejump_stl
git submodule update --init
cd basejump_stl

rm -rf imports
git sparse-checkout set bsg_async bsg_clk_gen bsg_dataflow bsg_dmc bsg_mem bsg_misc bsg_noc bsg_tag testing/bsg_dmc/lpddr_verilog_model
rm -f */*_nonsynth_*

# Fix errors in basejump code
printf '69m63\nw\n' | ed bsg_mem/bsg_mem_1rw_sync_mask_write_bit_from_1r1w.sv
sed -i '17i \`include "bsg_defines.sv"' bsg_dmc/bsg_dmc_dly_line_v3.sv
