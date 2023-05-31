#!/bin/sh

mkdir -p vectors
./create_vectors.sh
./remove_spaces.sh

# to create tvs for evaluation of combined IFdivsqrt
cd combined_IF_vectors; ./create_IF_vectors.sh