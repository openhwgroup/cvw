# this script is used to run regression inside the Dockerfile.regression
# of course, you can run it in the current environment as soon as
#   - RISCV is defined
#   - QUESTA is defined
QUESTA="/cad/mentor/questa_sim-xxxx.x_x"

# now only main branch is supported
if [ -z "${CVW_GIT+x}" ]; then
    echo "No CVW_GIT is provided"
    CVW_GIT="https://github.com/openhwgroup/cvw"
fi

export PATH="${RISCV}/bin:${PATH}"
git config --global http.version HTTP/1.1

# if cvw is not available or new cvw is required
if [ ! -f "/home/${USERNAME}/cvw/setup.sh" ] || [ -z "${CLEAN_CVW+x}" ]; then
    cd /home/${USERNAME} && rm -rf /home/${USERNAME}/cvw
    git clone --recurse-submodules  ${CVW_GIT} /home/${USERNAME}/cvw
    # if failed to clone submodules for some reason, please run `git submodule update`
fi

cd /home/${USERNAME}/cvw && chmod +x ./setup.sh && ./setup.sh
make install && make riscof && make testfloat

if [ -z "${RUN_QUESTA+x}" ] ; then
    if [ ! -f "${QUESTA}/questasim/bin/vsim" ]; then
        echo "Cannot find vsim with ${QUESTA}/questasim/bin/vsim"
    else
        export PATH="${QUESTA}/questasim/bin:${PATH}"
        cd sim && ./regression-wally 2>&1 > ./regression_questa.out && cd ..
    fi
fi

cd sim && verilator -GTEST="\"arch64i\"" -DVERILATOR=1 \
    --timescale "1ns/1ns" --timing --binary --top-module testbench -I../config/shared -I../config/rv64gc ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv --relative-includes
./obj_dir/Vtestbench 2>&1 > ./regression_verilator.out
