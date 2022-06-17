arch_dir = ../../addins/riscv-arch-test
work_dir = "./riscof_work"
current_dir = $(shell pwd)
XLEN    ?= 64

all: build

build:
	mkdir -p $(work_dir)
	mkdir -p work
	sed 's,{0},$(current_dir),g;s,{1},$(XLEN)$(if $(findstring 64,$(XLEN)),gc,imc),g' config.ini > config$(XLEN).ini
	riscof run --work-dir=$(work_dir) --config=config$(XLEN).ini --suite=$(arch_dir)/riscv-test-suite/ --env=$(arch_dir)/riscv-test-suite/env --no-browser --no-dut-run
	mv $(work_dir)/rv$(XLEN)i_m work/

clean:
	rm -f config64.ini
	rm -f config32.ini
	rm -rf $(work_dir)
	rm -rf work