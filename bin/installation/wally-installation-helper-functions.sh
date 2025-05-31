#!/bin/bash
###########################################
## Installation helper functions.
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: May 30 2025
## Modified: 
##
## Purpose: Common functions for toolchain installation scripts
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
## except in compliance with the License, or, at your option, the Apache License version 2.0. You
## may obtain a copy of the License at
##
## https:##solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
## either express or implied. See the License for the specific language governing permissions
## and limitations under the License.
################################################################################################

## Helper functions
# Error handler
error() {
    echo -e "${FAIL_COLOR}Error: $STATUS installation failed"
    echo -e "Error on line ${BASH_LINENO[0]} with command $BASH_COMMAND${ENDC}"
    if [ -e "$RISCV/logs/$STATUS.log" ]; then
        echo -e "Please check the log in $RISCV/logs/$STATUS.log for more information."
    fi
    exit 1
}

# Check if a git repository exists, is up to date, and has been installed
# clones the repository if it doesn't exist
# $1: repo name
# $2: repo url to clone from
# $3: file to check if already installed
# $4: upstream branch, optional, default is master
git_check() {
    local repo=$1
    local url=$2
    local check=$3
    local branch="${4:-master}"

    # Clone repo if it doesn't exist
    if [[ ! -e $repo ]]; then
        for ((i=1; i<=5; i++)); do
            git clone "$url" && break
            echo -e "${WARNING_COLOR}Failed to clone $repo. Retrying.${ENDC}"
            rm -rf "$repo"
            sleep $i
        done
        if [[ ! -e $repo ]]; then
            echo -e "${ERROR_COLOR}Failed to clone $repo after 5 attempts. Exiting.${ENDC}"
            exit 1
        fi
    fi

    # Get the current HEAD commit hash and the remote branch commit hash
    cd "$repo"
    git fetch
    local local_head=$(git rev-parse HEAD)
    local remote_head=$(git rev-parse origin/"$branch")

    # Check if the git repository is not up to date or the specified file does not exist
    if [[ "$local_head" != "$remote_head" ]]; then
        echo "$repo is not up to date. Updating now."
        true
    elif [[ ! -e $check ]]; then
        true
    else
        false
    fi
}

# Log output to a file and only print lines with keywords
logger() {
    local log_file="$RISCV/logs/$STATUS.log"
    local keyword_pattern="(\bwarning|\berror|\bfail|\bsuccess|\bstamp|\bdoesn't work)"
    local exclude_pattern="(_warning|warning_|_error|error_|-warning|warning-|-error|error-|Werror|error\.o|warning flags)"

    cat < /dev/stdin | tee -a "$log_file" | \
    (grep -iE --color=never "$keyword_pattern" || true) | \
    (grep -viE --color=never "$exclude_pattern" || true)
}

# Print section header
section_header() {
    if tput cols > /dev/null 2>&1; then
        printf "${SECTION_COLOR}%$(tput cols)s\n" | tr ' ' '#'
        printf "%$(tput cols)s\n" | tr ' ' '#'
        printf "%s\n" "$1"
        printf "%$(tput cols)s\n" | tr ' ' '#'
        printf "%$(tput cols)s${ENDC}\n" | tr ' ' '#'
    else
        printf "${SECTION_COLOR}%s\n${ENDC}" "$1"
    fi
}
