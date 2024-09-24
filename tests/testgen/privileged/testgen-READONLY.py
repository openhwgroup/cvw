#!/usr/bin/env python3
##################################
# testgen-CAUSE.py
#
# dottolia@hmc.edu 1 Mar 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
##################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint 
from random import seed
from random import getrandbits

##################################
# functions
##################################

#For instruction-fetch access or page-fault exceptions on systems with variable-length instructions, mtval will contain the virtual address of the portion of the instruction that caused the fault while mepc will point to the beginning of the instruction.

def randRegs():
  reg1 = randint(1,20)
  reg2 = randint(1,20)
  reg3 = randint(1,20)
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return str(reg1), str(reg2), str(reg3)

def writeVectors(a, storecmd):
  writeSingleVector(a, storecmd, f"""csrrw x0, {test}, x13""")
  writeSingleVector(a, storecmd, f"""csrrwi x0, {test}, {a % 32}""")
  if a != 0:
    writeSingleVector(a, storecmd, f"""csrrs x0, {test}, x13""")
    writeSingleVector(a, storecmd, f"""csrrc x0, {test}, x13""")
    writeSingleVector(a, storecmd, f"""csrrsi x0, {test}, {(a % 31) + 1}""")
    writeSingleVector(a, storecmd, f"""csrrci x0, {test}, {(a % 31) + 1}""")


def writeSingleVector(a, storecmd, writeInstruction):
  global testnum

  # Illegal Instruction 
  writeTest(storecmd, f, r, f"""
    li x13, MASK_XLEN({a})
    csrrw x11, {test}, x0
    {writeInstruction}
    csrrwi x12, {test}, 0
    sub x15, x11, x12
  """, False, 2)
  
  expected = 0
  lines = ""
  lines += storecmd + " x15, " + str(wordsize*testnum) + "(x6)\n"
  #lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg2) +", "+formatstr.format(expected)+")\n"
  f.write(lines)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  testnum = testnum+1

  

def writeTest(storecmd, f, r, test, interrupt, code, mode = "m", resetHander = ""):
  global testnum

  expected = code
  if(interrupt):
    expected+=(1 << (wordsize - 1))


  trapEnd = ""
  before = ""
  if mode != "m":
    before = f"""
      li x1, 0b110000000000
      csrrc x28, mstatus, x1
      li x1, 0b{"01" if mode == "s" else "00"}0000000000
      csrrs x28, mstatus, x1

      auipc x1, 0
      addi x1, x1, 16 # x1 is now right after the mret instruction
      csrrw x27, mepc, x1
      mret

      # We're now in {mode} mode...
    """

    trapEnd = f"""j _jend{testnum}"""


  # Setup
  # TODO: Adding 8 to x30 won't work for 32 bit?
  # x31: Old mtvec value
  # x30: trap handler address
  # x29: Old mtvec value for user/supervisor mode
  # x28: Old mstatus value
  # x27: Old mepc value
  # x26: 0 if we should execute mret normally. 1 otherwise. This allows us to stay in machine
  # x25: mcause
  # mode for the next tests
  lines = f"""
    # Testcase {testnum}
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest{testnum}

    # Machine trap vector
    {resetHander}
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    {trapEnd}
    mret

    # Actual test
    _jtest{testnum}:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    {before}
    {test}

    # Finished test. Reset to old mtvec
    _jend{testnum}:

    csrrw x0, mtvec, x31
  """

  #expected = 42
  
  lines += storecmd + " x25, " + str(wordsize*testnum) + "(x6)\n"
  #lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg2) +", "+formatstr.format(expected)+")\n"
  f.write(lines)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  testnum = testnum+1

  # lines += storecmd + " x0" + ", " + str(wordsize*testnum) + "(x6)\n"
  # #lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg2) +", "+formatstr.format(expected)+")\n"
  # f.write(lines)
  # if (xlen == 32):
  #   line = formatrefstr.format(expected)+"\n"
  # else:
  #   line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  # r.write(line)
  # testnum = testnum+1

##################################
# main body
##################################

# change these to suite your tests
# csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
author = "dottolia@hmc.edu"
xlens = [32, 64]
numrand = 4;
tests = ["marchid", "mhartid", "mimpid", "mvendorid"]

# setup
seed(0xD365DDEB9173AB42) # make tests reproducible

# generate files for each test
for xlen in xlens:
  formatstrlen = str(int(xlen/4))
  formatstr = "0x{:0" + formatstrlen + "x}" # format as xlen-bit hexadecimal number
  formatrefstr = "{:08x}" # format as xlen-bit hexadecimal number with no leading 0x
  if (xlen == 32):
    storecmd = "sw"
    wordsize = 4
  else:
    storecmd = "sd"
    wordsize = 8

  for test in tests:
    corners = [
      0, 1, 2, 31, 32,
      0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
      2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1
    ]
    imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
    basename = "WALLY-" + test.upper()
    fname = imperaspath + "src/" + basename + ".S"
    refname = imperaspath + "references/" + basename + ".reference_output"
    testnum = 0

    # print custom header part
    f = open(fname, "w")
    r = open(refname, "w")
    line = "///////////////////////////////////////////\n"
    f.write(line)
    lines="// "+fname+ "\n// " + author + "\n"
    f.write(lines)
    line ="// Created " + str(datetime.now()) 
    f.write(line)

    # insert generic header
    h = open("../testgen_header.S", "r")
    for line in h:  
      f.write(line)

    # print directed and random test vectors
    for i in corners:
      writeVectors(i, storecmd)
    for i in range(0,numrand):
      writeVectors(getrandbits(xlen), storecmd)


    # print footer
    h = open("../testgen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
    lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
    lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
    f.write(lines)
    f.close()
    r.close()




