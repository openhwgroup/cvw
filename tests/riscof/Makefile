.SECONDEXPANSION:

MAKEFLAGS += --output-sync --no-print-directory
nproc := $(shell nproc --ignore=1)

# Directories
arch_dir := $(WALLY)/addins/riscv-arch-test
wally_dir := $(WALLY)/tests/wally-riscv-arch-test
work_dir := ./riscof_work
work := ./work
arch_workdir := $(work)/riscv-arch-test
wally_workdir := $(work)/wally-riscv-arch-test
current_dir := $(shell pwd)

# General make rules
.PHONY: all riscv-arch-test wally-riscv-arch-test clean
all: riscv-arch-test wally-riscv-arch-test

# Standard riscv-arch-test tests
riscv-arch-test: arch32e arch32 arch64
arch%: test_dir=$(arch_dir)
arch%: work_result=$(arch_workdir)
arch32e: riscof32e
arch32:  riscof32
arch64:  riscof64

# wally-riscv-arch-test tests
wally-riscv-arch-test: wally32 wally64
wally%: test_dir=$(wally_dir)
wally%: work_result=$(wally_workdir)
wally32: riscof32
wally64: riscof64

# Generate config.ini files
config%.ini: config.ini
	sed 's,{0},$(current_dir),g;s,{1},$(patsubst %64,%64gc,$(patsubst %32,%32gc,$*)),g;s,{2},$(nproc),g' config.ini > $@

# Compile tests with riscof
riscof%: config$$*.ini | $(work_dir)
	riscof run --work-dir=$(work_dir)/$@ --config=$< --suite=$(test_dir)/riscv-test-suite/ --env=$(test_dir)/riscv-test-suite/env --no-browser
	$(MAKE) -f makefile-memfile WORKDIR=$(work_dir)/$@ BITWIDTH=$(patsubst %32e,%32,$*)
	mkdir -p $(work_result)
	rsync -a $(work_dir)/$@/rv*/* $(work_result)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*))_m || echo "error suppressed"

clean:
	rm -f config??*.ini
	rm -rf $(work_dir)
	rm -rf $(work)

$(work_dir):
	mkdir -p $@
