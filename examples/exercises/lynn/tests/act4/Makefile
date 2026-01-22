# tests/act4/Makefile

RISCV_ARCH_TEST ?= $(WALLY)/addins/riscv-arch-test-cvw

WORK_DIR        ?= $(CURDIR)/work
STAMP           := $(WORK_DIR)/copy_stamp

.PHONY: populate
populate: $(STAMP)

$(STAMP): Makefile
	@mkdir -p $(WORK_DIR)
	@$(MAKE) -C $(RISCV_ARCH_TEST) \
		CONFIG_FILES=$(RISCV_ARCH_TEST)/config/ref/sail-rv32gc/test_config.yaml \
		EXTENSIONS=I,Zicntr,Zihpm,Zicsr \
		DEBUG=True \
		--jobs $$(nproc)
	@cp -r $(RISCV_ARCH_TEST)/work/common/elfs/rv32i/I/* $(WORK_DIR)/
	@touch $(STAMP)

.PHONY: list-elfs
list-elfs:
	@find -L $(WORK_DIR) -type f -name '*.elf' | sort

.PHONY: clean
clean:
	rm -rf $(WORK_DIR)
