#!/bin/bash

###############################################################################
# Script Name: lint_spyglass.sh
# Author: james.stine@okstate.edu 11 June 2025
# Description:
#   This script automates the running of Synopsys SpyGlass linting for
#   various Wally RISC-V configurations. It substitutes the WALLYVER value
#   in the base project file and runs SpyGlass for a specified lint goal.
#
#   - Cleans out the lint-synopsys directory (if it exists)
#   - Accepts one configurable linting goal
#   - Iterates over multiple Wally configurations
#   - Generates temporary .prj files for each run
###############################################################################

# Check or set WALLY environment variable
if [ -z "$WALLY" ]; then
    echo "Error: WALLY environment variable is not set."
    echo "Please make sure you source your setup before running this script."
    exit 1
fi

# OPTIONAL: choose one of: lint/lint_rtl or lint/lint_rtl_enhanced
GOAL="lint/lint_rtl"

# List of configurations (add configurations for linting)
configs=(rv32e)

# Set current dir to make sure it writes to the current dir
CUR_DIR=$(pwd)

# Base project file for Spyglass
TEMPLATE_PRJ="$WALLY/bin/cvw.prj"

# Clean out the lint-synopsys directory (if it exists)
if [ -d "$CUR_DIR/lint-spyglass-reports" ]; then
    echo "Cleaning lint-spyglass directory..."
    rm -rf "$CUR_DIR/lint-spyglass-reports"/*
fi

for config in "${configs[@]}"; do
    echo "Processing configuration: $config"

    # Output project file
    CONFIG_PRJ="$CUR_DIR/cvw_${config}.prj"

    # Replace WALLYVER with current config and save to new .prj
    # Also replaces path for Tcl so can incorporate everything correctly
    sed -e "s|\$WALLY|$WALLY|g" \
	-e "s|WALLYVER|$config|g" \
	-e "s|read_file -type awl waivers.tcl|read_file -type awl $WALLY/bin/waivers.tcl|g" \
	-e "s|set_option projectwdir lint-spyglass/|set_option projectwdir ${CUR_DIR}/lint-spyglass/|g" \
	"$TEMPLATE_PRJ" > "$CONFIG_PRJ"

    # Run spyglass using the generated project file 
    echo "Running spyglass for: $config"
    spyglass -project "$CONFIG_PRJ" -goal "$GOAL" -batch

    # Optional: handle errors
    if [ $? -ne 0 ]; then
        echo "Error running spyglass for configuration: $config"
    else
        echo "Completed: $config"
    fi

    # Optional: uncomment the line below to keep each prj after each run
    rm "$CONFIG_PRJ"
    
done

