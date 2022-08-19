arch_dir = ../../addins/riscv-arch-test
wally_dir = ../wally-riscv-arch-test
work_dir = ./riscof_work
work = ./work
arch_workdir = $(work)/riscv-arch-test
wally_workdir = $(work)/wally-riscv-arch-test

current_dir = $(shell pwd)
#XLEN    ?= 64

all: root fsd_fld_tempfix arch32 wally32  wally32e arch64 wally64
#all: root fsd_fld_tempfix wally32

root:
	mkdir -p $(work_dir)
	mkdir -p $(work)
	mkdir -p $(arch_workdir)
	mkdir -p $(wally_workdir)
	sed 's,{0},$(current_dir),g;s,{1},32imc,g' config.ini > config32.ini
	sed 's,{0},$(current_dir),g;s,{1},64gc,g' config.ini > config64.ini
	sed 's,{0},$(current_dir),g;s,{1},32e,g' config.ini > config32e.ini

fsd_fld_tempfix:
    # this is a temporary fix, there's a typo on the rv64i_m/D/src/d_fsd-align-01.S and rv64i_m/D/src/d_fld-align-01.S tests
    # https://github.com/riscv-non-isa/riscv-arch-test/issues/266
	find ../../addins/riscv-arch-test/riscv-test-suite -type f -name "*d_fld-align*.S" | xargs -I{} sed -i 's,regex(\.\*32\.\*),regex(\.\*64\.\*),g' {}
	find ../../addins/riscv-arch-test/riscv-test-suite -type f -name "*d_fsd-align*.S" | xargs -I{} sed -i 's,regex(\.\*32\.\*),regex(\.\*64\.\*),g' {}

arch32:
	riscof run --work-dir=$(work_dir) --config=config32.ini --suite=$(arch_dir)/riscv-test-suite/ --env=$(arch_dir)/riscv-test-suite/env --no-browser
	rsync -a $(work_dir)/rv32i_m/ $(arch_workdir)/rv32i_m/ || echo "error suppressed"

arch64:
	riscof run --work-dir=$(work_dir) --config=config64.ini --suite=$(arch_dir)/riscv-test-suite/ --env=$(arch_dir)/riscv-test-suite/env --no-browser
	rsync -a $(work_dir)/rv64i_m/ $(arch_workdir)/rv64i_m/ || echo "error suppressed"
#	 Also copy F and D tests to RV64
	rsync -a $(work_dir)/rv32i_m/ $(arch_workdir)/rv64i_m/ || echo "error suppressed"  

wally32:
	riscof run --work-dir=$(work_dir) --config=config32.ini --suite=$(wally_dir)/riscv-test-suite/ --env=$(wally_dir)/riscv-test-suite/env --no-browser --no-dut-run
	rsync -a $(work_dir)/rv32i_m/ $(wally_workdir)/rv32i_m/ || echo "error suppressed"

wally64:
	riscof run --work-dir=$(work_dir) --config=config64.ini --suite=$(wally_dir)/riscv-test-suite/ --env=$(wally_dir)/riscv-test-suite/env --no-browser --no-dut-run
	rsync -a $(work_dir)/rv64i_m/ $(wally_workdir)/rv64i_m/ || echo "error suppressed"

wally32e:
	riscof run --work-dir=$(work_dir) --config=config32e.ini --suite=$(wally_dir)/riscv-test-suite/ --env=$(wally_dir)/riscv-test-suite/env --no-browser --no-dut-run
	rsync -a $(work_dir)/rv32i_m/ $(wally_workdir)/rv32i_m/ || echo "error suppressed"
	rsync -a $(work_dir)/rv32e_unratified/ $(wally_workdir)/rv32e_unratified/ || echo "error suppressed"


memfile: 
	find $(work) -type f -name "*.elf" | grep "rv64i_m" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 64 --input "$$f" --output "$$f.memfile"; done
	find $(work) -type f -name "*.elf" | grep "rv32i_m" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 32 --input "$$f" --output "$$f.memfile"; done
	find $(work) -type f -name "*.elf.objdump" | while read f; do extractFunctionRadix.sh $$f; done

clean:
	rm -f config64.ini
	rm -f config32.ini
	rm -f config32e.ini
	rm -rf $(work_dir)
	rm -rf $(wally_workdir)
	rm -rf $(arch_workdir)
