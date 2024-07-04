#!/usr/bin/env python3
##################################
# testgen-STORE.py
#
# Jessica Torrey <jtorrey@hmc.edu>  03 February 2021
# Thomas Fleming <tfleming@hmc.edu> 03 February 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
##################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint, seed, getrandbits
from textwrap import dedent

##################################
# global structures
##################################
size_to_store = {8: "sd", 4: "sw", 2: "sh", 1: "sb"}
size_to_load = {8: "ld", 4: "lw", 2: "lh", 1: "lb"}
store_to_size = {"sd": 8, "sw": 4, "sh": 2, "sb": 1}
testcase_num = 0
signature_len = 2000
signature = [0xff for _ in range(signature_len)]

##################################
# functions
##################################

def rand_reg():
  """
  Produce a random register from 1 to 31 (skipping 6, since r6 is used for
  other things).
  """
  r = randint(1,30)
  if r >= 6:
    r += 1
  return r

def rand_regs():
  """
  Generate two random, unequal register numbers (skipping x6).
  """
  rs1 = rand_reg()
  rs2 = rand_reg()
  while rs1 == rs2:
    rs2 = rand_reg()
  
  return rs1, rs2

def generate_case(xlen, instruction, value_register, value, addr_register, offset, base_delta):
  """
  Create assembly code for a given STORE test case, returned as a string.

  Generates an `xlen`-bit test case for `instruction` (one of sb, sh, sw, or
  sd) that loads `value` into `value_register`, then attempts to store that
  value in memory at address (x6 + `base_delta`). The test case
  assumes the current base address for the signature is in register x6.

  The form of the STORE instruction is as follows:

  `instruction` `value_register` `offset`(`addr_register`)
  """
  global testcase_num

  hex_value = f"{value:0{xlen // 4}x}"

  data = f"""# Testcase {testcase_num}: source: x{value_register} (value 0x{hex_value}), destination: {offset}(x{addr_register}) ({base_delta} bytes into signature)
    addi x{addr_register}, x6, {base_delta}
    li x{value_register}, MASK_XLEN({-offset})
    add x{addr_register}, x{addr_register}, x{value_register}
    li x{value_register}, 0x{hex_value}
    {instruction} x{value_register}, {offset}(x{addr_register})
    """

  update_signature(store_to_size[instruction], value, base_delta)

  testcase_num += 1
  return data

def validate_memory(scratch_register, value_register, value, base_delta, length):
  """
  Create assembly code to verify that `length` bytes at mem[x6 + `base_delta`]
  store `value`.

  Assumes x6 stores the current base address for the signature.
  """
  truncated_value = value & (2**(length * 8) - 1)
  hex_value = f"{truncated_value:0{length * 2}x}"

  load = size_to_load[length]
  data = f"""addi x{scratch_register}, x6, {base_delta}
    {load} x{value_register}, 0(x{scratch_register})
    RVTEST_IO_ASSERT_GPR_EQ(x{scratch_register}, x{value_register}, 0x{hex_value})

    """
  return data

def update_signature(length, value, base_delta):
  """
  Write the lower `length` bytes of `value` to the little-endian signature
  array, starting at byte `base_delta`.
  """
  truncated_value = value & (2**(length * 8) - 1)
  value_bytes = truncated_value.to_bytes(length, 'little')
  #print("n: {}, value: {:x}, trunc: {:x}, length: {}, bd: {:x}".format(testcase_num, value, truncated_value, length, base_delta))
  for i in range(length):
    signature[base_delta + i] = value_bytes[i]

def write_signature(outfile):
  """
  Writes successive 32-bit words from the signature array into a given file.
  """
  for i in range(0, signature_len, 4):
    word = list(reversed(signature[i:i+4]))
    hexword = bytearray(word).hex()
    outfile.write(f"{hexword}\n")

def write_header(outfile):
  """
  Write the name of the test file, authors, and creation date.
  """
  outfile.write(dedent(f"""\
    ///////////////////////////////////////////
    //
    // WALLY-STORE
    //
    // Author: {author}
    //
    // Created {str(datetime.now())}
    """))
  outfile.write(open("testgen_header.S", "r").read())

def write_footer(outfile):
  """
  Write necessary closing code, including a data section for the signature.
  """
  outfile.write(open("testgen_footer.S", 'r').read())
  data_section = dedent(f"""\
    \t.fill {signature_len}, 1, -1
    RV_COMPLIANCE_DATA_END
    """)
  outfile.write(data_section)

##################################
# test cases
##################################

def write_basic_tests(outfile, xlen, instr_len, num, base_delta):
  """
  Test basic functionality of STORE, using random registers, offsets, and
  values.

  Creates `num` tests for a single store instruction of length `instr_len`,
  writing to memory at consecutive locations, starting `base_delta` bytes from
  the start of the signature.

  Returns the number of bytes from the start of the signature where testing
  ended.
  """
  instruction = size_to_store[instr_len]
  for i in range(num):
    value_register, addr_register = rand_regs()
    offset = randint(-2**(12 - 1), 2**(12 - 1) - 1)
    value = randint(0, 2**(instr_len * 8) - 1)
    test = generate_case(xlen, instruction, value_register, value, addr_register, offset, base_delta)
    validate = validate_memory(addr_register, value_register, value, base_delta, instr_len)
    outfile.write(test)
    outfile.write(validate)
    base_delta += instr_len
  return base_delta

def write_random_store_tests(outfile, xlen, instr_len, num, min_base_delta):
  """
  Test random access of STORE, using random registers, offsets, values, and
  memory locations.

  Creates `num` tests for a single store instruction of length `instr_len`,
  writing to memory at random locations between `min_base_delta` bytes past
  the start of the signature to the end of the signature.
  """
  instruction = size_to_store[instr_len]
  for i in range(num):
    base_delta = randint(min_base_delta, signature_len - 1)
    base_delta -= (base_delta % instr_len)
    value_register, addr_register = rand_regs()
    offset = randint(-2**(12 - 1), 2**(12 - 1) - 1)
    value = randint(0, 2**(instr_len * 8) - 1)

    test = generate_case(xlen, instruction, value_register, value, addr_register, offset, base_delta)
    validate = validate_memory(addr_register, value_register, value, base_delta, instr_len)
    outfile.write(test)
    outfile.write(validate)

def write_repeated_store_tests(outfile, xlen, instr_len, num, base_delta):
  """
  Test repeated access of STORE, using random registers, offsets, values, and a
  single memory location.

  Creates `num` tests for a single store instruction of length `instr_len`,
  writing to memory `base_delta` bytes past the start of the signature.
  """
  instruction = size_to_store[instr_len]
  for i in range(num):
    value_register, addr_register = rand_regs()
    offset = 0
    value = (1 << ((2 * i) % xlen))

    test = generate_case(xlen, instruction, value_register, value, addr_register, offset, base_delta)
    validate = validate_memory(addr_register, value_register, value, base_delta, instr_len)

    outfile.write(test)
    outfile.write(validate)

def write_corner_case_tests(outfile, xlen, instr_len, base_delta):
  instruction = size_to_store[instr_len]

  corner_cases_32 = [0x0, 0x10000001, 0x01111111]
  corner_cases_64 = [0x1000000000000001, 0x0111111111111111]
  corner_cases = corner_cases_32
  if xlen == 64:
    corner_cases += corner_cases_64

  for offset in corner_cases:
    for value in corner_cases:
      value_register, addr_register = rand_regs()
      test = generate_case(xlen, instruction, value_register, value, addr_register, offset, base_delta)
      validate = validate_memory(addr_register, value_register, value, base_delta, instr_len)

      outfile.write(test)
      outfile.write(validate)

      base_delta += instr_len
  
  return base_delta

##################################
# main body
##################################

instructions = ["sd", "sw", "sh", "sb"]
author = "Jessica Torrey <jtorrey@hmc.edu> & Thomas Fleming <tfleming@hmc.edu>"
xlens = [32, 64]
numrand = 100

# setup
seed(0) # make tests reproducible

for xlen in xlens:
  if (xlen == 32):
    wordsize = 4
  else:
    wordsize = 8

  fname = f"../../imperas-riscv-tests/riscv-test-suite/rv{xlen}i/src/WALLY-STORE.S"
  refname = f"../../imperas-riscv-tests/riscv-test-suite/rv{xlen}i/references/WALLY-STORE.reference_output"
  f = open(fname, "w")
  r = open(refname, "w")

  write_header(f)

  base_delta = 0

  for instruction in instructions:
    if xlen == 32 and instruction == 'sd':
      continue
    instr_len = store_to_size[instruction]
    base_delta = write_basic_tests(f, xlen, instr_len, 5, base_delta)
    write_repeated_store_tests(f, xlen, instr_len, 32, base_delta)
    write_random_store_tests(f, xlen, instr_len, 5, base_delta + wordsize)

  write_footer(f)

  write_signature(r)
  f.close()
  r.close()

  # Reset testcase_num and signature
  testcase_num = 0
  signature = [0xff for _ in range(signature_len)]
