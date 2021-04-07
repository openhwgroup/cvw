#!/usr/bin/python3
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

def randRegs():
  reg1 = randint(1,20)
  reg2 = randint(1,20)
  reg3 = randint(1,20)
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return str(reg1), str(reg2), str(reg3)

def writeVectors(storecmd):
  global testnum

  # x23 holds the expected value

  # Illegal Instruction 
  writeTest(storecmd, f, r, f"""
    .fill 1, 4, 0
  """, f"""
    li x23, 0
  """)

  val = (randint(0, 200) * 4) + 1

  # Load Address Misaligned 
  writeTest(storecmd, f, r, f"""
    lw x0, {val}(x0)
  """, f"""
    li x23, {val}
  """)

  val = (randint(0, 200) * 4) + 1

  # Load Address Misaligned 
  writeTest(storecmd, f, r, f"""
    sw x0, {val}(x0)
  """, f"""
    li x23, {val}
  """)
  

  

def writeTest(storecmd, f, r, test, expected, mode = "m", resetHander = ""):
  global testnum


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
  # x24: mtval
  # x23: mtval expected
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
    csrrs x24, mtval, x0
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
    li x24, 0x7BAD
    {before}
    {test}

    # Finished test. Reset to old mtvec
    _jend{testnum}:

    {expected}
    sub x25, x24, x23
    csrrw x0, mtvec, x31
  """

  expected = 0
  
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
numrand = 30;

# setup
seed(0xC363DDEB9173AB42) # make tests reproducible

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

  corners = [
    0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
    2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1
  ]
  imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
  basename = "WALLY-TVAL"
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
  for i in range(0,numrand):
    writeVectors(storecmd)


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




