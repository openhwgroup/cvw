#!/usr/bin/python3
##################################
# testgen-LOAD.py
#
# Jarred Allen <jaallen@g.hmc.edu> 02 February 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
##################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint, seed, getrandbits

##################################
# functions
##################################

def rand_reg():
  """Produce a random register (skipping 6, since r6 is used for other things"""
  r = randint(1,30)
  if r >= 6:
    r += 1
  return r

testcase_num = 0
def generate_case(xlen, instruction, load_register, source_register, source_register_value, offset, expected):
    """Produce the specified test case and return it as a string"""
    global testcase_num
    if xlen == 64:
        store = "sd"
    elif xlen == 32:
        if instruction in ["lwu", "ld"]:
            raise Exception("Instruction %s not supported in RV32I" % instruction)
        store = "sw"
    else:
        raise Exception("Unknown xlen value: %s" % xlen)
    data = f"""# Testcase {testcase_num}: source {offset}(x{source_register} == {source_register_value}), rresult: x{load_register} == {expected}
    lui x{source_register}, {source_register_value // (1 << 12)}
    addi x{source_register}, x{source_register}, {source_register_value % (1 << 12)} 
    {instruction} x{load_register}, {offset}(x{source_register})
    {store} x{load_register}, {testcase_num}(x6)
    RVTEST_IO_ASSERT_GPR_EQ(x8, x{load_register}, {expected})
    """
    testcase_num += 1
    return data

def write_header(outfile):
    outfile.write(f"""///////////////////////////////////////////
    //
    // WALLY-LOAD
    //
    // Author: f{author}
    //
    // Created {str(datetime.now())}
    // 
    ///////////////////////////////////////////

    """)
    outfile.write(open("testgen_header.S", "r").read())

##################################
# main body
##################################

instructions = ["lb", "lbu", "lh", "lhu", "lw", "lwu", "ld"]
author = "Jarred Allen"
xlens = [32, 64]
numrand = 100;

# setup
seed(0) # make tests reproducible

for xlen in xlens:
    fname = "../../imperas-riscv-tests/riscv-test-suite/rv{}i/src/WALLY-LOAD.S".format(xlen)
    refname = "../../imperas-riscv-tests/riscv-test-suite/rv{}i/references/WALLY-LOAD.S.reference_output".format(xlen)
    f = open(fname, "w")
    r = open(refname, "w")
    write_header(f)
    test_data = dict()
    corner_values = [0x00, 0xFF, 0xFFFF, 0xFFFFFFFF, 0x7F, 0x7FFF, 0x7FFFFFFF, 0x01]
    if xlen == 64:
        corner_values += [0xFFFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFF]
    for instruction in instructions:
        if xlen == 32:
            if instruction in ["lwu", "ld"]:
                continue
