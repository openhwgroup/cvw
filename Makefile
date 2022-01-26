all:
	make install
	make regression

# install copies over the Makefile.include from riscv-isa-sim
# And corrects the TARGETDIR path and the RISCV_PREFIXZ

install:
	cp ${RISCV}/riscv-isa-sim/arch_test_target/spike/Makefile.include addins/riscv-arch-test/
	sed -i '/export TARGETDIR ?=/c\export TARGETDIR ?= ${RISCV}/riscv-isa-sim/arch_test_target' addins/riscv-arch-test/Makefile.include
	echo export RISCV_PREFIX = riscv64-unknown-elf- >> addins/riscv-arch-test/Makefile.include
	cd tests/linux-testgen/linux-testvectors; source ./tvLinker.sh # needs to be run in local directory
	rm tests/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64/riscvOVPsimPlus.exe
	ln -s ${RISCV}/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64/riscvOVPsimPlus.exe tests/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64/riscvOVPsimPlus.exe

regression:
	make -C pipelined/regression

clean:
	make clean -C pipelined/regression
	

