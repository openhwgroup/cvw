clear
printf "\n\n#####\nStarting tests for $1\n#####\n\n"

if [[ "$2" != "-simonly" ]]
then
	cd ~/riscv-wally/wally-pipelined/testgen/privileged
	python3 "testgen-$1.py"
	printf "\n\n#####\nRan testgen-$1.py Making...\n#####\n\n\n"

	cd ~/riscv-wally/imperas-riscv-tests
	make privileged
fi

if [[ "$2" == "-sim" || "$2" == "-simonly" ]]
then
	printf "\n\n\n#####\nSimulating!\n#####\n\n"
	cd ~/riscv-wally/wally-pipelined/regression
	vsim -do wally-privileged.do -c
fi

cd ~/riscv-wally
printf "\n\n\n#####\nDone!\n#####\n\n"