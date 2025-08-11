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
riscv-arch-test: arch32e arch32 arch64

cvw-riscv-arch-test: # cvw-arch32e
	rm -rf $(cvw_arch_workdir)
	rm -rf $(WALLY)/addins/cvw-arch-verif/work/*
	$(MAKE) cvw-arch32
	$(MAKE) cvw-arch64

wally-riscv-arch-test: wally32 wally64

# Generate config.ini files
config%.ini: config.ini
	sed 's,{0},$(current_dir),g;s,{1},$(patsubst %64,%64gc,$(patsubst %32,%32gc,$*)),g;s,{2},$(nproc),g' config.ini > $@

# Generate riscv-arch-test targets
arch%: config$$*.ini | $(work_dir) $(arch_workdir) 
	riscof run --work-dir=$(work_dir)/$@ --config=$< --suite=$(arch_dir)/riscv-test-suite/ --env=$(arch_dir)/riscv-test-suite/env --no-browser
	$(MAKE) -f makefile-memfile WORKDIR=$(work_dir)/$@ BITWIDTH=$(patsubst %32e,%32,$*)
	rsync -a $(work_dir)/$@/rv*/* $(arch_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*))_m || echo "error suppressed"

# Generate cvw-riscv-arch-test targets
# Generate riscv-arch-test targets
cvw-arch%: config$$*.ini | $(work_dir) $(cvw_arch_workdir)
	export COLLECT_COVERAGE=true; riscof run --work-dir=$(work_dir)/$@ --config=$< --suite=$(cvw_arch_dir)/riscv-test-suite/ --env=$(cvw_arch_dir)/riscv-test-suite/env --no-browser
	$(MAKE) -f makefile-memfile WORKDIR=$(work_dir)/$@ BITWIDTH=$(patsubst %32e,%32,$*)
	rsync -a $(work_dir)/$@/rv*/* $(cvw_arch_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*)) || echo "error suppressed"
	rsync -a $(work_dir)/$@/privileged/* $(cvw_arch_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*)) || echo "error suppressed"
	${CVW_ARCH_VERIF}/bin/trace-coverreport.py $(cvw_arch_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*))

cvw-arch-no-report%: config$$*.ini | $(work_dir) $(cvw_arch_workdir)
	export COLLECT_COVERAGE=true; riscof run --work-dir=$(work_dir)/$@ --config=$< --suite=$(cvw_arch_dir)/riscv-test-suite/ --env=$(cvw_arch_dir)/riscv-test-suite/env --no-browser
	$(MAKE) -f makefile-memfile WORKDIR=$(work_dir)/$@ BITWIDTH=$(patsubst %32e,%32,$*)
	rsync -a $(work_dir)/$@/rv*/* $(cvw_arch_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*)) || echo "error suppressed"

clean-cvw-arch:
	rm -rf $(WALLY)/addins/cvw-arch-verif/work/*

clean-riscof-else-ucdb%:
	rm -f config??*.ini
	rm -rf $(work_dir)
	@if [ -e ./work/cvw-riscv-arch-test/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*)) ]; then \
		find $(cvw_arch_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*)) -type f ! -name '*.ucdb' -exec rm -f {} +; \
	fi

coverreport%:
	${CVW_ARCH_VERIF}/bin/trace-coverreport.py $(cvw_arch_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*))

# Generate wally-riscv-arch-test targets
wally%: config$$*.ini | $(work_dir) $(wally_workdir)
	riscof run --work-dir=$(work_dir)/$@ --config=$< --suite=$(wally_dir)/riscv-test-suite/ --env=$(wally_dir)/riscv-test-suite/env --no-browser --no-dut-run
	$(MAKE) -f makefile-memfile WORKDIR=$(work_dir)/$@
	rsync -a $(work_dir)/$@/rv*/* $(wally_workdir)/rv$(patsubst %64,%64i,$(patsubst %32,%32i,$*))_m || echo "error suppressed"

clean:
	rm -f config??*.ini
	rm -rf $(work_dir)
	rm -rf $(wally_workdir)
	rm -rf $(arch_workdir)
	rm -rf $(cvw_arch_workdir)
	rm -rf $(WALLY)/addins/cvw-arch-verif/work/*

$(work_dir) $(arch_workdir) $(wally_workdir) $(cvw_arch_workdir):
	mkdir -p $@
