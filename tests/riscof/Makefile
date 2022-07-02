arch_dir = ../../addins/riscv-arch-test
wally_dir = ../wally-riscv-arch-test
work_dir = ./riscof_work
work = ./work
arch_workdir = $(work)/riscv-arch-test
wally_workdir = $(work)/wally-riscv-arch-test

current_dir = $(shell pwd)
XLEN    ?= 64

all: root build_arch # build_wally memfile

root:
	mkdir -p $(work_dir)
	mkdir -p $(work)
	mkdir -p $(arch_workdir)
	mkdir -p $(wally_workdir)
	sed 's,{0},$(current_dir),g;s,{1},$(XLEN)$(if $(findstring 64,$(XLEN)),gc,imc),g' config.ini > config$(XLEN).ini

build_arch:
	riscof run --work-dir=$(work_dir) --config=config$(XLEN).ini --suite=$(arch_dir)/riscv-test-suite/ --env=$(arch_dir)/riscv-test-suite/env --no-browser
	rm -rf $(arch_workdir)/rv$(XLEN)i_m
	mv -f $(work_dir)/rv$(XLEN)i_m $(arch_workdir)/

build_wally:
	riscof --verbose debug run --work-dir=$(work_dir) --config=config$(XLEN).ini --suite=$(wally_dir)/riscv-test-suite/ --env=$(wally_dir)/riscv-test-suite/env --no-browser --no-dut-run
	rm -rf $(wally_workdir)/rv$(XLEN)i_m
	mv -f $(work_dir)/rv$(XLEN)i_m $(wally_workdir)/

memfile: 
	find $(work) -type f -name "*.elf" | grep "rv64i_m" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 64 --input "$$f" --output "$$f.memfile"; done
	find $(work) -type f -name "*.elf" | grep "rv32i_m" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 32 --input "$$f" --output "$$f.memfile"; done
	find $(work) -type f -name "*.elf.objdump" | while read f; do extractFunctionRadix.sh $$f; done

clean:
	rm -f config64.ini
	rm -f config32.ini
	rm -rf $(work_dir)
	rm -rf $(wally_workdir)
	rm -rf $(arch_workdir)