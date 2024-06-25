# There are three parts in testing as there are three scripts
# It is fine to use either docker or podman as they are equivalent in the context
export USE_PODMAN=1

## build either one of them
UBUNTU_BUILD=1 ./get_image.sh
echo "get images is $?"

## mount toolchian and questa
TOOLCHAINS_MOUNT=/opt/riscv QUESTA=/cad/mentor/questa_sim-2023.4 ./start.sh
# then run 
# - `file ${QUESTA}/questasim/vsim` to check if it is properly mount
# - `file $RISCV/bin/riscv64-unknown-elf-gcc` to check the toolchain

## use internal toolchain
./start.sh
# then run 
# - `file $RISCV/bin/riscv64-unknown-elf-gcc` to check the toolchain
# - `which verilator | grep riscv` to check the verilator

## mount questa
RUN_QUESTA=true QUESTA=/cad/mentor/questa_sim-2023.4 ./run_regression.sh