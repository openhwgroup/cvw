#!/bin/bash

# set WALLY path
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY/../../" && pwd)
echo "WALLY is set to: $WALLY"

# Going to nightly runs
cd $WALLY/../

# check if directories exist
if [ ! -d "build-results" ]; then
    echo "Directory does not exist, creating it..."
    mkdir -p "build-results"
    if [ $? -eq 0 ]; then
        echo "Directory created successfully."
    else
        echo "Failed to create directory."
        exit 1
    fi
else
    echo "Directory already exists."
fi

if [ ! -d "logs" ]; then
    echo "Directory does not exist, creating it..."
    mkdir -p "logs"
    if [ $? -eq 0 ]; then
        echo "Directory created successfully."
    else
        echo "Failed to create directory."
        exit 1
    fi
else
    echo "Directory already exists."
fi

# setup source okstate file
echo "Sourcing setup files"
source $WALLY/setup_host.sh
source $WALLY/../setup-files/setup_tools.sh

# Navigate to the gir repo
cd $WALLY

# pull the repository
echo "Pulling submodules"
#git pull --recurse-submodules origin main

# build the regression tests
echo "Building the regression tests"
cd sim
#if make wally-riscv-arch-test; then
#if make all; then
#	echo "Make successfull"
#else
#	echo "Make failed"
#	cd $WALLY/..
	# add the the regression result and the coverage result that there was an error in making the tests
#	python $WALLY/bin/nightly_build/src/error_detector.py --tag make -o $WALLY/../build-results/regression_results.md
#	python $WALLY/bin/nightly_build/src/error_detector.py --tag make -o $WALLY/../build-results/coverage_results.md

	# exit the program
	#exit 1
#fi

# execute the simulation / regression tests and save output to a file
echo "running the regression test"
#./regression-wally > $WALLY/../logs/regression_output.log 2>&1

echo "running coverage tests"
#./coverage > $WALLY/../logs/coverage_output.log 2>&1


# run the Python script to parse the output and generate the log file
echo "Parsing output data from the regression test"
cd $WALLY/../

python $WALLY/bin/nightly_build/src/parse_regression.py -i $WALLY/../logs/regression_output.log -o $WALLY/../build-results/regression_results.md

python $WALLY/bin/nightly_build/src/parse_coverage.py -i $WALLY/../logs/coverage_output.log -o $WALLY/../build-results/coverage_results.md

# email update
cd $WALLY/bin/nightly_build/src/
./send_mail_html.sh
