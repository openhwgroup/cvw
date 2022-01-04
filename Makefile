all:
	make install
	make regression

# install copies over the Makefile.include from riscv-isa-sim
# And corrects the TARGETDIR path and the RISCV_PREFIXZ

install:
	cp ${RISCV}/riscv-isa-sim/arch_test_target/spike/Makefile.include addins/riscv-arch-test/
	sed -i '/export TARGETDIR ?=/c\export TARGETDIR ?= ${RISCV}/riscv-isa-sim/arch_test_target' addins/riscv-arch-test/Makefile.include
	echo export RISCV_PREFIX = riscv64-unknown-elf- >> addins/riscv-arch-test/Makefile.include

regression:
	make -C pipelined/regression



