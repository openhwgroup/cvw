#!/bin/bash

# Variables
PYTHON_SCRIPT=$HOME/nightly-runs/cvw/bin/       # cvw can be anywhere you would like it. Make sure to point your variable there
SETUP_SCRIPT=$HOME/nightly-runs/cvw/            # cvw can be anywhere you would like it. Make sure to point your variable there

echo "Current directory"
pwd

cd $SETUP_SCRIPT
echo "Current directory"
pwd

echo "Sourcing setup_host"
source ./setup.sh 

cd $PYTHON_SCRIPT
pwd
echo "Running python file"
$RISCV/riscv-python/bin/python nightly_build.py
echo "Finished"
