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

# buildold:
# 	mkdir -p $(work_dir)
# 	mkdir -p work
# 	sed 's,{0},$(current_dir),g;s,{1},32imc,g' config.ini > config32.ini
# 	sed 's,{0},$(current_dir),g;s,{1},64gc,g' config.ini > config64.ini
# 	riscof run --work-dir=$(work_dir) --config=config32.ini --suite=$(arch_dir)/riscv-test-suite/ --env=$(arch_dir)/riscv-test-suite/env --no-browser --no-dut-run
# 	mv -r $(work_dir)/rv32i_m work/
# 	riscof run --work-dir=$(work_dir) --config=config64.ini --suite=$(arch_dir)/riscv-test-suite/ --env=$(arch_dir)/riscv-test-suite/env --no-browser --no-dut-run
# 	mv -r $(work_dir)/rv64i_m work/

# no-dut-run? do we want to run spike?
# sed  >> config64.ini
#	(cd $(arch_dir) && riscof validateyaml --config=config.ini)
#	(cd $(arch_dir) && riscof --verbose info arch-test --clone)
#	(cd $(arch_dir) && riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env)
# sed -i 's/riscv{.}-unknown-/riscv64-unknown-/g' $(arch_dir)/spike/riscof_spike.py
# sed -i 's/riscv{.}-unknown-/riscv64-unknown-/g' $(arch_dir)/sail_cSim/riscof_sail_cSim.py

# memfile:
# 	sleep 1
# # find work/rv*/*/ -type f -name "*ref.elf" | while read f; do riscv64-unknown-elf-objdump -S -D "$$f" > "$$f.objdump"; echo $$f; done
# 	find work/rv32*/*/ -type f -name "*ref.elf" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 32 --input "$$f" --output "$$f.memfile"; done
# 	find work/rv64*/*/ -type f -name "*ref.elf" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 64 --input "$$f" --output "$$f.memfile"; done
# 	find work/rv*/*/ -type f -name "*.objdump" | while read f; do extractFunctionRadix.sh $$f; done

clean:
	rm -f config64.ini
	rm -f config32.ini
	rm -rf $(work_dir)
	rm -rf work