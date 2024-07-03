# Quad Precision Floating Point Tests for Wally
## Shreesh Kulkarni
## Email : kshreesh5@gmail.com
## Date : 26th June, 2024


This folder consists of all the required files and tools to generate Q tests for Wally via riscv-ctg, riscv-isac and riscof.

NOTE : Only some of the IBM tests are currently supporting Quad testing. 

Tests which are working : ibm1, ibm9,ibm21,ibm23,ibm24,ibm25,ibm26,ibm27,ibm28,ibm29
These ibm tests can be included in the riscv-ctg tests generation command, along with riscof.

The tests which are currently breaking due to overflow errors are : ibm2,ibm3,ibm4,ibm5,ibm6,ibm7,ibm8,ibm10,ibm11,ibm12,ibm13,ibm14,ibm15,ibm16,ibm17,ibm18,ibm19,ibm20,ibm22

These tests cannnot generate Quad tests yet due to underlying errors.


Changes Made : fp_dataset.py in riscv-isac -> This dataset consists of 10 IBM floating point tests generators for Quads

riscv-ctg-> This folder consists of the CTG tool which is responsible for generating the assembly files for Quads by using the fp_dataset.py in riscv-isac. CGF files were added for each of the IBM floating point tests.

riscof -> The riscof directory in Wally was changed to include some Quad precision template files for compilation. Along with modification of scripts and yaml files to support FLEN=128

TO DO: 
    Debug why fadd.q_b1 doesn't match Sail vs. Spike
    Run the q test on Wally RTL
    Make more tests from the working datasets
    Get other datasets working by using softfloat to do quad math
    Push changes back to riscv-ctg and riscv-isac and remove them from wally-riscv-arch/tsts/riscv-test-suite/rv64i_m/Q


Start by installing riscv-ctg via the following commands : 


cd $WALLY/tests/wally-riscv-arch-test/riscv-test-suite/rv64i_m/Q/riscv-ctg

pip3 install --editable .

Once installed, generate the assembly files in the tests directory{cvw/tests/wally-riscv-arch-test/riscv-test-suite/rv64i_m/Q/riscv-ctg/tests} for the specific opcode by running this command :

riscv_ctg --base-isa rv64i --flen 128 --cgf ./sample_cgfs/dataset.cgf --cgf ./sample_cgfs/sample_cgfs_fext/RV32D/fadd.q.cgf -d ./tests/ --randomize -v debug -p2

NOTE : The following warning might be generated : 
WARNING | Neither mnemonics nor csr_comb node not found in covergroup: datasets

This can be ignored as this warning tells us that not all IBM tests have been included as only a limited number of them support Quads currently.

You can choose the corresponding cgf file for the opcode you wish to generate tests. 

This command was referenced in the following Issue generated in the riscv-ctg repository.
(CTG Issue 111){https://github.com/riscv-software-src/riscv-ctg/issues/111}

You should now see some assembly tests pertaining to your selected opcode in the tests directory(cvw/tests/wally-riscv-arch-test/riscv-test-suite/rv64i_m/Q/riscv-ctg/tests).

To finally generate the SAIL signatures and dut/ref log/assembly files, RISCOF will be used to compile our generated tests from CTG.

The following command will invoke riscof and generate a riscof-work directory with all the selected tests and log files, SAIL signatures and dis-assembly files.

PATH=/home/jcarlin/REPOS/sail-riscv/c_emulator/current:$PATH
cd $WALLY/tests/riscof
make quad64


NOTE : The above command will generate the following error. 

ERROR | /home/skulkarni/cvw/tests/wally-riscv-arch-test/riscv-test-suite/rv64i_m/Q/riscv-ctg/tests/fadd.q_b1-01.S : -                                        : Failed

This is because and SAIL and SPIKE's signatures do not match. This needs further debugging.

The log-files, disassembly files and reference SAIL signatures can be viewed in the riscof-work directory(cvw/tests/riscof/riscof_work/)


