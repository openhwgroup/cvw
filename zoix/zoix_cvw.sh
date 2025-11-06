
rm -r ./run_zoix
mkdir ./run_zoix
cd ./run_zoix

# Compile DUT & strobe file
#

zoix -f ../netlist.f  -l ../log.txt \
-v /data/libraries/NangateOpenCellLibrary_15_45_nm/45nm/NangateOpenCellLibrary.v \
+timescale+override+1ns/1ps \
+top+wallypipelinedcore_gate+strobe \
+sv +notimingchecks +define+ZOIX +define+TOPLEVEL=wallypipelinedcore_gate +suppress+cell +delay_mode_fault +verbose+undriven -l zoix_compile.log


#2 step, simulation:
# addstrobe -fsgroup ../../sim/questa/core.vcd strobbed_vcd.vcd ../strobe.strobe 21000 10000
./zoix.sim +vcd+file+"../../sim/questa/core.vcd" \
 +vcd+dut+wallypipelinedcore_gate+testbench.dut.core_gate +vcd+verify +vcd+verbose  -l logic_sim.log +vcd+limit+mismatch+100000


#3 run fault simulation
fmsh  -load ../fault_sim_cvw.fmsh
fault_report +group+detail
