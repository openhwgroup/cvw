# Readme CAD

# Preliminaries
After activated your EDA tools.
You need to prepare your simulation environment with :
```bash
git submodule update --init addins/verilog-ethernet/
```

# How to change the Core
You can change the file ``${WALLY}/config/derivlist.txt`` to create/change your wally configuration.

**Afterward, you need generate the configuration files with the command:** 
```bash 
make deriv
```


# How to compile a SBST

You can write your SBST in the folder ``${WALLY}/asm/sbst``
and edit ``${WALLY}/asm/sbst/sbst.S`` for prototyping your functional test program.

**Afterward, to create an executable suitable for the simulation, it is necessary to:**
```bash 
${WALLY}/asm/sbst $ make 
```

# How to synthesize (for gate level fault/logic simulation)

In order to run the synthesis, it is necessary to go in the  ``${WALLY}/synthDC`` folder and run the command:
```bash 
./wallySynth_polito.py --tech nangate45   -t 1500 -v syn_polito_rv32e -c 16
```
It currently supports only the nangate45 tech library without any additional mods.
**Be carefull with ``-c`` option, it chooses the number of cores used during the synthesis**

# How to simulate
In order to run a simulation and dump the vcd (for the fault simulation):
```bash
wsim wsim --elf ./examples/asm/sbst/sbst.elf --sim questa --tb testbench --vcd syn_polito_rv32e
```
# How to run the fault simulation on the gate-level netlist

In order to run the fault simulation for the previously executed SBSTs, it is necessary to go in the  ``${WALLY}/zoix`` folder and run the command:
```bash 
$ ./zoix_cvw.sh
```
