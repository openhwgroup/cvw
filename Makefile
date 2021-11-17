make all: submodules other
submodules: addins/riscv-isa-sim addins/riscv-arch-test
	cd addins;git init; git submodule add https://github.com/riscv-non-isa/riscv-arch-test; git submodule add https://github.com/riscv-software-src/riscv-isa-sim
	git submodule update --init --recursive

other:
	cp -r addins/riscv-isa-sim/arch_test_target/spike/device/rv32i_m/I addins/riscv-isa-sim/arch_test_target/spike/device/rv32i_m/F
	cp -r addins/riscv-isa-sim/arch_test_target/spike/device/rv32i_m/I addins/riscv-isa-sim/arch_test_target/spike/device/rv32i_m/D
	sed -i 's/--isa=rv32i /--isa=32if/' addins/riscv-isa-sim/arch_test_target/spike/device/rv32i_m/F/Makefile.include
	sed -i 's/--isa=rv32i /--isa=32if/' addins/riscv-isa-sim/arch_test_target/spike/device/rv32i_m/D/Makefile.include
ifneq ("$(wildcard $(addins/riscv-isa-sim/build/.*))",)
else
	mkdir addins/riscv-isa-sim/build
endif
	cd addins/riscv-isa-sim/build; ../configure --prefix=/cad/riscv/gcc/bin
	make -C addins/riscv-isa-sim/
	sed -i '/export TARGETDIR ?=/c\export TARGETDIR ?= /home/harris/riscv-wally/addins/riscv-isa-sim/arch_test_target' tests/wally-riscv-arch-test/Makefile.include
	echo export RISCV_PREFIX = riscv64-unknown-elf- >> tests/wally-riscv-arch-test/Makefile.include
	make -C tests/wally-riscv-arch-test
	make -C tests/wally-riscv-arch-test XLEN=32
	cd tests/wally-riscv-arch-test; exe2memfile.pl work/*/*/*.elf
	make -C wally-pipelined/regression
	



