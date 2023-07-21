.PHONY: all clean
obj-m += fpga-axi-sdc.o

all:
	$(MAKE) -C '$(LINUX-DIR)' M='$(PWD)' modules
	$(MAKE) -C '$(LINUX-DIR)' M='$(PWD)' modules_install

clean:
	$(MAKE) -C '$(LINUX-DIR)' M='$(PWD)' clean
