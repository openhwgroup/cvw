#!/bin/sh
#sed -z 's/assign Aprime .*Memory stage//' $WALLY/src/mdu/mul.sv
sed -zi 's/\/\/ Number systems.*logic/  logic/' $WALLY/src/mdu/mul.sv
sed -zi 's/assign Aprime.*Memory/\/\/ Memory/' $WALLY/src/mdu/mul.sv
