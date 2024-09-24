#!/usr/bin/env python3
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
  """Produce a random register (skipping 6 and 31, since they're used for other things)"""
  r = randint(1,29)
  if r >= 6:
    r += 1
  return r

def rand_value(width):
    """Generate a random value which fits in the given width"""
    return randint(0, (1 << width) - 1)

def rand_offset():
    """Generate a random offset"""
    ret = rand_value(12)
    # print("Random offset: %d" % ret)
    return ret

def rand_source():
    """Generate a random value for the source register, such that the load address is in the test data"""
    ret = randint(1 << 12, (1 << 12) + (1 << 10))
    # print("Random source: %d" % ret)
    return ret

def add_offset_to_source(source, offset):
    """Find the address from the given source value and offset"""
    if offset & 0x800:
        offset -= 0x1000
    return source + offset

def insert_into_data(test_data, source, offset, value, width, xlen):
    """Insert the given value into the given location of the test data"""
    address = add_offset_to_source(source, offset)
    # print("Test #%d" % testcase_num)
    # print(f"Source: {source}, Offset: {offset}, Value: {value}, Width: {width}, xlen: {xlen}, Addr: {address}")
    if address < 0:
        return False
    word_offset = address % (xlen // 8)
    word_address = address - word_offset
    if word_address in test_data:
        return False
    test_data[word_address] = value * (1 << (word_offset*8)) + ((~(((1 << width)-1) << (word_offset*8))) & rand_value(xlen))
    # print(f"Word: {hex(test_data[word_address])}")
    return True

def align(address, width):
    """Align the address to the given width, in bits"""
    return address - (address % (width // 8))

testcase_num = 0
def generate_case(xlen, instruction, load_register, source_register, source_register_value, offset, expected):
    """Produce the specified test case and return it as a pair of strings, where the first is the test case and the second is the output"""
    global testcase_num
    if xlen == 64:
        store = "sd"
    elif xlen == 32:
        if instruction in ["lwu", "ld"]:
            raise Exception("Instruction %s not supported in RV32I" % instruction)
        store = "sw"
    else:
        raise Exception("Unknown xlen value: %s" % xlen)
    if offset >= 0x800:
        offset -= 0x1000
    if widths[instruction] != xlen:
        expected = expected % (1 << widths[instruction])
        if 'u' not in instruction:
            if expected & (1 << (widths[instruction] - 1)):
                expected = (expected + ~((1 << widths[instruction]) - 1)) & ((1 << xlen) - 1)
    data = f"""# Testcase {testcase_num}: source {offset}(x{source_register} == {source_register_value}), result: x{load_register} == {expected}
    la x31, test_data
    lui x{source_register}, {source_register_value // (1 << 12)}
    addi x{source_register}, x{source_register}, {source_register_value % (1 << 12)} 
    add x{source_register}, x{source_register}, x31
    {instruction} x{load_register}, {offset}(x{source_register})
    {store} x{load_register}, {(testcase_num*xlen//8) % 0x800}(x6)
    RVTEST_IO_ASSERT_GPR_EQ(x8, x{load_register}, {expected})

    """
    testcase_num += 1
    if testcase_num*xlen//8 % 0x800 == 0:
        data += "# Adjust x6 because we're storing too many things\naddi x6, x6, 1024\naddi x6, x6, 1024\n\n"
    if xlen == 32:
        reference_output = "{:08x}\n".format(expected) 
    elif xlen == 64:
        reference_output = "{:08x}\n{:08x}\n".format(expected % (1 << 32), expected >> 32) 
    return (data, reference_output)

def write_header(outfile):
    outfile.write(f"""///////////////////////////////////////////
//
// WALLY-LOAD
//
// Author: {author}
//
// Created {str(datetime.now())}
// 
""")
    outfile.write(open("testgen_header.S", "r").read())

def write_test_data(outfile, test_data, xlen):
    # print("Begin writing test data:")
    # print("{} entries, from address {} to {}".format(len(test_data), min(test_data.keys()), max(test_data.keys())))
    # print(test_data)
    outfile.write("""
    .align 16
test_data:
    
    """)
    if xlen == 32:
        data_word = ".word"
    elif xlen == 64:
        data_word = ".dword"
    else:
        raise Exception("Unknown xlen: %d" % xlen)
    byte_width = xlen // 8
    for addr in [0] + sorted(test_data.keys()):
        if addr in test_data:
            word = f"    {data_word} {hex(test_data[addr] % (1 << xlen))} # test_data+{hex(addr)}\n"
        else:
            word = ""
        try:
            fill_len = (min(k for k in test_data.keys() if k > addr) - addr) // byte_width - 1
            if word == "":
                fill_len += 1
            fill = f"    .fill {fill_len}, {byte_width}, 0x0\n"
        except:
            fill = ""
        case = word+fill
        outfile.write(case)

##################################
# main body
##################################

widths = {
    "lb": 8,
    "lbu": 8,
    "lh": 16,
    "lhu": 16,
    "lw": 32,
    "lwu": 32,
    "ld": 64,
}
instructions = [i for i in widths]
author = "Jarred Allen"
xlens = [32, 64]
numrand = 100;

# setup
seed(0) # make tests reproducible

for xlen in xlens:
    testcase_num = 0
    fname = "../../imperas-riscv-tests/riscv-test-suite/rv{}i/src/WALLY-LOAD.S".format(xlen)
    refname = "../../imperas-riscv-tests/riscv-test-suite/rv{}i/references/WALLY-LOAD.reference_output".format(xlen)
    f = open(fname, "w")
    r = open(refname, "w")
    write_header(f)
    test_data = dict()
    corner_values = [0x00, 0xFFFFFFFF, 0x7F, 0x7FFF, 0x7FFFFFFF]
    if xlen == 64:
        corner_values += [0xFFFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFF]
    corner_offsets = [0x800, 0x000, 0x7FF]
    for instruction in instructions:
        print("Running xlen: %d, instruction: %s" % (xlen, instruction))
        if xlen == 32:
            if instruction in ["lwu", "ld"]:
                continue
        for value in corner_values + [rand_value(widths[instruction]) for _ in range(3)]:
            value = value % (1 << widths[instruction])
            source_reg = rand_source()
            for offset in corner_offsets + [rand_offset() for _ in range(3)]:
                offset = align(offset, widths[instruction])
                source_reg = align(source_reg, widths[instruction])
                if insert_into_data(test_data, source_reg, offset, value, widths[instruction], xlen):
                    data, output = generate_case(xlen, instruction, rand_reg(), rand_reg(), source_reg, offset, value)
                    f.write(data)
                    r.write(output)
    while testcase_num % 4:
        source = rand_source()
        offset = rand_offset()
        value = rand_value(widths[instruction])
        if insert_into_data(test_data, source, offset, value, widths['lb'], xlen):
            data, output = generate_case(xlen, 'lb', rand_reg(), rand_reg(), source, offset, value)
            f.write(data)
            r.write(output)
    f.write("""# ---------------------------------------------------------------------------------------------
	
	RVTEST_IO_WRITE_STR(x31, "Test End\\n")

	# ---------------------------------------------------------------------------------------------

	RV_COMPLIANCE_HALT

RV_COMPLIANCE_CODE_END

	.data
    # Input data section
""")
    write_test_data(f, test_data, xlen)
    f.write("""# Output data section.
RV_COMPLIANCE_DATA_BEGIN

test_1_res:
""")
    f.write(f".fill {testcase_num}, {xlen//8}, -1\n")
    f.write("\nRV_COMPLIANCE_DATA_END\n")
    f.close()
    r.close()
