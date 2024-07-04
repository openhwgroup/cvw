#!/bin/bash

#
# Written 1 Mar 2021 by Domenico Ottolia (dottolia@hmc.edu)
#
# See README.md in this directory for more info
#

clear
printf "\n\n#####\nStarting tests for $1\n#####\n\n"

if [[ "$2" != "-simonly" ]]
then
	cd $WALLY/testgen/privileged
	$RISCV/riscv-python/bin/python3 "testgen-$1.py"
	printf "\n\n#####\nRan testgen-$1.py Making...\n#####\n\n\n"

	if [[ "$2" == "-c" ]]
	then
		printf "\n\n###\nWARNING\nThis seems to not be outputting begin_signature at the moment... Probably won't work in modelsim...\n###\n\n\n"
		cd $WALLY/imperas-riscv-tests/riscv-test-suite/rv64p/src
		riscv64-unknown-elf-gcc -nostdlib -nostartfiles -march=rv64g "WALLY-$1".S -I../../../riscv-test-env -I../../../riscv-test-env/p -I../../../riscv-target/riscvOVPsimPlus -T../../../riscv-test-env/p/link.ld -o "../../../work/rv64p/WALLY-$1.elf"
		cd $WALLY/imperas-riscv-tests/work/rv64p
		riscv64-unknown-elf-objdump -d "WALLY-$1".elf > "WALLY-$1".elf.objdump
 
	elif [[ "$2" != "-nosim" ]]
	then
		cd $WALLY/imperas-riscv-tests
		make privileged

		exe2memfile.pl work/*/*.elf
		extractFunctionRadix.sh work/rv64p/*.elf.objdump
	fi
fi

if [[ "$2" == "-simonly" ]]
then
	printf "\n\n###\nWARNING\nThis seems to not be outputting begin_signature at the moment... Probably won't work in modelsim...\n###\n\n\n"
	cd $WALLY/imperas-riscv-tests/riscv-test-suite/rv64p/src
	riscv64-unknown-elf-gcc -nostdlib -nostartfiles -march=rv64g "WALLY-$1".S -I../../../riscv-test-env -I../../../riscv-test-env/p -I../../../riscv-target/riscvOVPsimPlus -T../../../riscv-test-env/p/link.ld -o "../../../work/rv64p/WALLY-$1.elf"
	cd $WALLY/imperas-riscv-tests/work/rv64p
	riscv64-unknown-elf-objdump -d "WALLY-$1".elf > "WALLY-$1".elf.objdump

	# 	riscv64-unknown-elf-gcc -nostdlib -nostartfiles -march=rv64g "WALLY-CAUSE".S -I../../../riscv-test-env -I../../../riscv-test-env/p -I../../../riscv-target/riscvOVPsimPlus -T../../../riscv-test-env/p/link.ld -o "../../../work/rv64p/WALLY-CAUSE.elf"
	# riscv64-unknown-elf-objdump -d "WALLY-CAUSE.elf" > "WALLY-CAUSE.elf.objdump"
fi

if [[ "$2" == "-sim" || "$2" == "-simonly" ]]
then
	printf "\n\n\n#####\nSimulating!\n#####\n\n"
	cd $WALLY/sim
	vsim -do wally-privileged.do -c
fi

cd $WALLY/pipelined
printf "\n\n\n#####\nDone!\n#####\n\n"

cd $WALLY/imperas-riscv-tests/work
for isa in "rv64p" "rv32p"; do
	printf "$isa = '{"
	COMMA=""
	for file in "$isa"/*.elf.objdump; do
		if [[ "$file" == *"$1"* ]]; then
		    RES=$(grep "^\s*0*8000.000 <begin_signature>" $file)
		    RES=$(echo "$RES" | sed -r 's/^0*80+([0-9]+).+?$/\1/g')
		    file=$(echo "$file" | sed -r 's/^(.+?)\.elf\.objdump/\1/g')
		    printf "$COMMA\n    '$file', '${RES}'"
		    COMMA=","
		fi
	done
	printf "\n};\n\n"
done

cd $WALLY/pipelined