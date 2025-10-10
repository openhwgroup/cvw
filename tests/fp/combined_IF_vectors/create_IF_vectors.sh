#!/bin/sh
# create test vectors for stand alone int

./extract_testfloat_vectors.py
#./extract_arch_vectors.py  # disabled 10/10/2025 david harris - canary seems to be missing at end of rv32m div_01.S/ref/Reference-sail_c_simulator.signature, causing this to hang
