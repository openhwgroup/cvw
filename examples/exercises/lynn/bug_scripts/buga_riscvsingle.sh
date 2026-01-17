#!/bin/sh
sed -i 's/logic \[11:0\] controls;/logic        controls;/' "$WALLY/examples/exercises/lynn/sample_processor/src/controller.sv"
