#!/bin/sh
# create test vectors for stand alone int

./extract_testfloat_vectors.py
./extract_arch_vectors.py

# to create tvs for evaluation of combined IFdivsqrt
#./combined_IF_vectors/create_IF_vectors.sh