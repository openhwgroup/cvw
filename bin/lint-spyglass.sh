#!/bin/bash

###############################################################################
# Script Name: lint_spyglass.sh
# Author: james.stine@okstate.edu 11 June 2025
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description:
#   Automates Synopsys SpyGlass linting for Wally RISC-V configurations.
#   Supports command-line options for custom goals and configs.
###############################################################################

# Check WALLY environment
if [ -z "$WALLY" ]; then
    echo "Error: WALLY environment variable is not set."
    echo "Please source your setup before running this script."
    exit 1
fi

# === Defaults ===
GOAL="lint/lint_rtl"
DEFAULT_CONFIGS=(rv32e rv64gc rv32gc rv32imc rv32i rv64i)
CONFIGS=()

# === Parse command-line options ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--goal)
            GOAL="$2"
            shift 2
            ;;
        -c|--configs)
            IFS=',' read -r -a CONFIGS <<< "$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-g lint_goal] [-c config1,config2,...]"
            echo "  -g, --goal      Linting goal (e.g., lint/lint_rtl or lint/lint_rtl_enhanced)"
            echo "  -c, --configs   Comma-separated list of configs to run (e.g., rv32e,rv64gc)"
            echo "Defaults: goal=$GOAL, configs=${DEFAULT_CONFIGS[*]}"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Use default configs if none provided
if [ ${#CONFIGS[@]} -eq 0 ]; then
    CONFIGS=("${DEFAULT_CONFIGS[@]}")
fi

# Spyglass work directories/files
SPYGLASS_DIR="$WALLY/synthDC/spyglass"
TEMPLATE_PRJ="$SPYGLASS_DIR/cvw.prj"

# Clean output directory
echo "Cleaning lint-spyglass-reports directory..."
rm -rf "$SPYGLASS_DIR/lint-spyglass-reports"

# Iterate configs
for config in "${CONFIGS[@]}"; do
    echo "Processing configuration: $config"
    CONFIG_PRJ="$SPYGLASS_DIR/cvw_${config}.prj"

    # Replace placeholders in template
    sed -e "s|\$WALLY|$WALLY|g" \
        -e "s|WALLYVER|$config|g" \
        -e "s|read_file -type awl waivers.tcl|read_file -type awl $SPYGLASS_DIR/waivers.tcl|g" \
        -e "s|set_option projectwdir lint-spyglass/|set_option projectwdir ${SPYGLASS_DIR}/lint-spyglass/|g" \
        "$TEMPLATE_PRJ" > "$CONFIG_PRJ"

    # Run SpyGlass
    echo "Running spyglass for: $config with goal: $GOAL"
    spyglass -project "$CONFIG_PRJ" -goal "$GOAL" -batch

    if [ $? -ne 0 ]; then
        echo "Error running spyglass for configuration: $config"
    else
        echo "Completed: $config"
    fi

    rm "$CONFIG_PRJ"
done
