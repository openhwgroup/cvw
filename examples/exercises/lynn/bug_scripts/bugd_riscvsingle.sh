#!/bin/sh
sed -i 's/assign LT = Neg \^ Overflow;/assign LT = Neg;/' "$WALLY/examples/exercises/lynn/sample_processor/src/alu.sv"
