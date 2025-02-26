#!/bin/sh
sed -i 's/assign MFunctD.*/assign MFunctD = 0; \/\/ *** Replace with your logic/' $WALLY/src/ieu/controller.sv
sed -i 's/ControlsD.*Divide/assign ControlsD = 0; \/\/ *** Replace with your logic/' $WALLY/src/ieu/controller.sv
sed -zi 's/\/\/ Number systems.*logic/  logic/' $WALLY/src/mdu/mul.sv
sed -zi 's/assign Aprime.*Memory/\/\/ Memory/' $WALLY/src/mdu/mul.sv
