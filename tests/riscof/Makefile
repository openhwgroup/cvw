.SECONDEXPANSION:

MAKEFLAGS += --output-sync --no-print-directory
nproc := $(shell nproc --ignore=1)

# Directories
arch_dir := $(WALLY)/addins/riscv-arch-test
cvw_arch_dir := $(WALLY)/addins/cvw-riscv-arch-test
wally_dir := $(WALLY)/tests/wally-riscv-arch-test
work_dir := ./riscof_work
work := ./work
arch_workdir := $(work)/riscv-arch-test
cvw_arch_workdir := $(work)/cvw-riscv-arch-test
wally_workdir := $(work)/wally-riscv-arch-test
current_dir := $(shell pwd)

# General make rules
.PHONY: all riscv-arch-test wally-riscv-arch-test clean
all: riscv-arch-test wally-riscv-arch-test

$(wally_workdir)/wally%.stamp: $(shell find $(wally_dir) -type f) config.ini
	$(MAKE) wally$*
	touch $@

$(arch_workdir)/arch%.stamp: $(shell find $(arch_dir) -type f) config.ini
	$(MAKE) arch$*
	touch $@

# Standard riscv-arch-test tests
# .PHONY: arch32e arch32 arch64
riscv-arch-test: arch32e arch32 arch64
arch%: test_dir=$(arch_dir)
arch%: work_result=$(arch_workdir)

# cvw-arch-verif based riscv-arch-test tests
# cvw-riscv-arch-test: cvw_arch32 cvw_arch64
# cvw_arch%: test_dir=$(cvw_arch_dir)
# cvw_arch%: work_result=$(cvw_arch_workdir)

# wally-riscv-arch-test tests
wally-riscv-arch-test: wally32 wally64
wally%: test_dir=$(wally_dir)
wally%: work_result=$(wally_workdir)

# Generate config.ini files
config%.ini: config.ini
	sed 's,{0},$(current_dir),g;s,{1},$(patsubst %64,%64gc,$(patsubst %32,%32gc,$*)),g;s,{2},$(nproc),g' config.ini > $@

# Compile tests with riscof
arch% wally%: config$$*.ini | $(work_dir)
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
