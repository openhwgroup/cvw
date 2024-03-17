#!/bin/bash
date


# Variables
LOG=$HOME/nightly-runs/logs/from_wrapper.log    # you can store your log file where you would like
PYTHON_SCRIPT=$HOME/nightly-runs/cvw/bin/       # cvw can be anywhere you would like it. Make sure to point your variable there
SETUP_SCRIPT=$HOME/nightly-runs/cvw/            # cvw can be anywhere you would like it. Make sure to point your variable there



date > $LOG 2>&1

echo "Current directory"
pwd

cd $SETUP_SCRIPT
echo "Current directory"
pwd

echo "Sourcing setup_host"
source ./setup_host.sh >> $LOG 2>&1

cd $PYTHON_SCRIPT
pwd
echo "Running python file"
python nightly_build.py --path "nightly-runs" --repository "https://github.com/openhwgroup/cvw" --target "all" --send_email "yes" >> $LOG 2>&1
echo "Finished"
