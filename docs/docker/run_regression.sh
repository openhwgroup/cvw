#!/bin/bash
# this script is used to run regression inside the Dockerfile.regression
# of course, you can run it in the current environment as soon as
#   - RISCV is defined
#   - QUESTA is defined
# now only main branch is supported
if [ -z "${CVW_GIT}" ]; then
    echo "No CVW_GIT is provided"
    CVW_GIT="https://github.com/openhwgroup/cvw"
fi

git config --global http.version HTTP/1.1

# if cvw is not available or CLEAN_CVW(empty string) is defined
if [[ ! -f "/home/${USERNAME}/cvw/setup.sh" ]] || [[ -z "${CLEAN_CVW-x}" ]]; then
    cd /home/${USERNAME} && rm -rf /home/${USERNAME}/cvw
    git clone --recurse-submodules  ${CVW_GIT} /home/${USERNAME}/cvw
    # if failed to clone submodules for some reason, please run `git submodule update`
fi

# Preset Environment Variable
export PATH="${RISCV}/bin:${PATH}"
export CVW_HOME="/home/${USERNAME}/cvw"
export QUESTA="/cad/mentor/questa_sim-xxxx.x_x"
export PATH="${QUESTA}/questasim/bin:${PATH}"

# cd /home/${USERNAME}/cvw && chmod +x ./setup.sh && ./setup.sh
chmod +x ${CVW_HOME}/setup.sh && source ${CVW_HOME}/setup.sh
chmod +x ${CVW_HOME}/site-setup.sh && source ${CVW_HOME}/site-setup.sh

# Overwriting
export QUESTAPATH=/cad/mentor/questa_sim-xxxx.x_x/questasim/bin

# if you are making it alone, it works
make

# build it only if BUILD_RISCOF is defined with empty string
# if [[ -z "${BUILD_RISCOF-x}" ]]; then
#     make install && make riscof && make testfloat
# fi

# if [[ -z "${RUN_QUESTA-x}" ]] ; then
#     if [ ! -f "${QUESTA}/questasim/bin/vsim" ]; then
#         echo "Cannot find vsim with ${QUESTA}/questasim/bin/vsim"
#     else
#         # cd sim && ./regression-wally 2>&1 > ./regression_questa.out && cd ..
#         make verify
#     fi
# fi

# make coverage
# make benchmarks

cd ${CVW_HOME}/sim && verilator -GTEST="\"arch64i\"" -DVERILATOR=1 --timescale "1ns/1ns" --timing --binary --top-module testbench -I../config/shared -I../config/rv64gc ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv --relative-includes
${CVW_HOME}/sim/obj_dir/Vtestbench > ${CVW_HOME}/sim/regression_verilator.out
