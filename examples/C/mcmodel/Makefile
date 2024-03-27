all:
	riscv64-unknown-elf-gcc -O3 -march=rv64gc -mcmodel=medlow mcmodel.c -o mcmodel_medlow
	riscv64-unknown-elf-objdump -d mcmodel_medlow > mcmodel_medlow.objdump
	riscv64-unknown-elf-gcc -O3 -march=rv64gc -mcmodel=medany mcmodel.c -o mcmodel_medany
	riscv64-unknown-elf-objdump -d mcmodel_medany > mcmodel_medany.objdump

clean:
	rm mcmodel_*
