#!/bin/bash
# this script is used to run regression inside the Dockerfile.regression
# of course, you can run it in the current environment as soon as
#   - RISCV is defined
#   - QUESTA is defined
export QUESTA="/cad/mentor/questa_sim-xxxx.x_x"

export MGLS_LICENSE_FILE=27002@zircon.eng.hmc.edu                # Change this to your Siemons license server
export SNPSLMD_LICENSE_FILE=27002@zircon.eng.hmc.edu                # Change this to your Synopsys license server
export QUESTAPATH=/cad/mentor/questa_sim-xxxx.x_x/questasim/bin     # Change this for your path to Questa
export SNPSPATH=/cad/synopsys/SYN/bin                               # Change this for your path to Design Compiler

# now only main branch is supported
if [ -z "${CVW_GIT}" ]; then
    echo "No CVW_GIT is provided"
    CVW_GIT="https://github.com/openhwgroup/cvw"
fi

export PATH="${RISCV}/bin:${PATH}"
git config --global http.version HTTP/1.1

# if cvw is not available or CLEAN_CVW(empty string) is defined
if [[ ! -f "/home/${USERNAME}/cvw/setup.sh" ]] || [[ -z "${CLEAN_CVW-x}" ]]; then
    cd /home/${USERNAME} && rm -rf /home/${USERNAME}/cvw
    git clone --recurse-submodules  ${CVW_GIT} /home/${USERNAME}/cvw
    # if failed to clone submodules for some reason, please run `git submodule update`
fi

cd /home/${USERNAME}/cvw && chmod +x ./setup.sh && ./setup.sh
# build it only if BUILD_RISCOF is defined with empty string
if [[ -z "${BUILD_RISCOF-x}" ]]; then
    make install && make riscof && make testfloat
fi

if [[ -z "${RUN_QUESTA-x}" ]] ; then
    if [ ! -f "${QUESTA}/questasim/bin/vsim" ]; then
        echo "Cannot find vsim with ${QUESTA}/questasim/bin/vsim"
    else
        export PATH="${QUESTA}/questasim/bin:${PATH}"
        cd sim && ./regression-wally 2>&1 > ./regression_questa.out && cd ..
    fi
fi

cd sim && verilator -GTEST="\"arch64i\"" -DVERILATOR=1 --timescale "1ns/1ns" --timing --binary --top-module testbench -I../config/shared -I../config/rv64gc ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv --relative-includes
/home/${USERNAME}/cvw/sim/obj_dir/Vtestbench > ./regression_verilator.out
