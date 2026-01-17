#!/bin/sh
RTL_DIR=${RTL_DIR:-.}
sed -i 's/if (reset)  PC <= entry_addr;/if (1 | reset)  PC <= entry_addr;/' "$WALLY/examples/exercises/lynn/sample_processor/src/ifu.sv"
