#!/bin/bash
source /cad/riscv/OVP/Imperas.20200630/bin/setup.sh
setupImperas /cad/riscv/OVP/Imperas.20200630 -m32
source /cad/riscv/OVP/Imperas.20200630/bin/switchRuntime.sh 2>/dev/null
echo 1 | switchRuntimeImperas
source /cad/riscv/OVP/Imperas.20200630/bin/switchISS.sh 2>/dev/null
echo 1 | switchISSImperas
