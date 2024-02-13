#!/bin/bash
date


# Variables
LOG=$HOME/nightly_runs/logs/from_wrapper.log    # you can store your log file where you would like
PYTHON_SCRIPT=$HOME/nightly_runs/cvw/bin/       # cvw can be anywhere you would like it. Make sure to point your variable there
SETUP_SCRIPT=$HOME/nightly_runs/cvw/            # cvw can be anywhere you would like it. Make sure to point your variable there



date > $LOG 2>&1

echo "Current directory"
pwd

cd $SETUP_SCRIPT
echo "Current directory"
pwd

echo "Sourcing setup_host"
source ./setup_host.sh >> $LOG 2>&1
echo "Sourcing setup_tools"

cd $PYTHON_SCRIPT
pwd
echo "Running python file"
python nightly_build.py >> $LOG 2>&1
