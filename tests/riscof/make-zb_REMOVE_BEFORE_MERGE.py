import os

os.chdir("/home/kmacsai-goren/cvw/tests/riscof/riscof_work/rv64i_m/B/src")

filenames = []

for testname in os.listdir():
    print(
f"""cd /home/kmacsai-goren/cvw/tests/riscof/riscof_work/rv64i_m/B/src/{testname}/ref;riscv64-unknown-elf-gcc -march=rv64izba_zbb_zbc_zbs          -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles         -T /home/kmacsai-goren/cvw/tests/riscof/sail_cSim/env/link.ld         -I /home/kmacsai-goren/cvw/tests/riscof/sail_cSim/env/         -I /home/kmacsai-goren/cvw/addins/riscv-arch-test/riscv-test-suite/env -mabi=lp64  /home/kmacsai-goren/cvw/addins/riscv-arch-test/riscv-test-suite/rv64i_m/B/src/{testname} -o ref.elf -DTEST_CASE_1=True -DXLEN=64;riscv64-unknown-elf-objdump -D ref.elf > ref.elf.objdump;riscv_sim_RV64 -z268435455 -i --test-signature=/home/kmacsai-goren/cvw/tests/riscof/riscof_work/rv64i_m/B/src/{testname}/ref/Reference-sail_c_simulator.signature ref.elf > add.uw-01.log 2>&1;
riscv64-unknown-elf-elf2hex --bit-width 64 --input /home/kmacsai-goren/cvw/tests/riscof/riscof_work/rv64i_m/B/src/{testname}/ref/ref.elf --output /home/kmacsai-goren/cvw/tests/riscof/work/riscv-arch-test/rv64i_m/B/src/{testname}/ref/ref.elf.memfile
extractFunctionRadix.sh /home/kmacsai-goren/cvw/tests/riscof/work/riscv-arch-test/rv64i_m/B/src/{testname}/ref/ref.elf.objdump
""")

