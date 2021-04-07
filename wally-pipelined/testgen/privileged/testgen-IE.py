#!/usr/bin/python3
##################################
# testgen-IE.py
#
# ushakya@hmc.edu 31 March 2021
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

def writeTrapHandlers(storecmd):
  global testnum
  reg1 = 30
  reg2 = 29
  reg3 = 28
  lines = "\n# Trap Handler: Timer Interupt\n"
  lines += "_timer_trap_handler:\n"
  lines += "li x" + str(reg1) + ", MASK_XLEN(0x2A)\n"
  lines += str(storecmd) + " x" + str(reg1) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines += "la x" + str(reg2) + ", 0x2004000\n"
  lines += str(storecmd) + " x" + str(reg1) + ",  0(x" + str(reg2) + ")\n"
  lines += "csrrw x" + str(reg3) + ", mepc, x0\n"
  lines += "addi x"+ str(reg3) + ", x" + str(reg3) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  f.write(lines)

def writeVector(a, xlen, storecmd):
  global testnum

  [reg1, reg2, reg3] = [1, 2, 3]
  [reg5, reg8] = [5, 8]
  [reg9, reg10, reg11, reg12] = [9, 10, 11, 12]

  lines = "\n# Testcase 0: Timer Interupt\n"

  # Page 6 of unpriviledged spec
  # For both CSRRS and CSRRC, if rs1=x0, then the instruction will not write to the CSR at all, and so shall not cause any of the side effects
  
  # mcause code
  b = 1 << (xlen-1)
  b = b + 0x7
  expected = b
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(b) + ")\n"

  if (testnum == 0): expected = 0

  # set interupt enable bit in mstatus
  lines += "li x" + str(reg3) + ", MASK_XLEN(0x8)\n"
  lines += "csrrs x0, mstatus, x" + str(reg3) + "\n"

  # set machine timer interupt enable bit in mie
  lines += "li x" + str(reg9) + ", MASK_XLEN(0x80)\n"
  lines += "csrrs x0, mie, x" + str(reg3) + "\n"

  # Save and set trap handler address for machine mode timer interrupt
  lines += "la x" + str(reg5) + ", _timer_trap_handler\n"
  
  # save orignal mtvec address
  lines += "csrrw x" + str(reg12) + ", mtvec, x" + str(reg5) + "\n"
  
  # cause timer interupt
  #if (testnum == 0):
  lines += "li x" + str(reg8) + ", MASK_XLEN(0)\n"
  lines += str(storecmd) + " x" + str(reg8) + ", " + str(wordsize*testnum)+ "(x6)\n"
  
  lines += "la x" + str(reg8) + ", 0x2004000\n"

  lines += "li x" + str(reg3) + ", MASK_XLEN(0)\n"

  # save old value of mtimecmp and then set mtimecmp to zero
  lines += "lw x" + str(reg11) + ", 0(x" + str(reg8) + ")\n"
  lines += str(storecmd) + " x" + str(reg3) + ",  0(x" + str(reg8) + ")\n"
  #lines += "wfi\n" # wait for interupt to be taken
  lines += "nop\nnop\n"

  lines += "csrrw " + " x" + str(reg2) + ", mcause, x" + str(reg1) + "\n"
  
  # reset mtvec
  lines += "csrrw x0, mtvec, x" + str(reg12) + "\n"

  lines += storecmd + " x" + str(reg2) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, x" + str(reg2) +", "+formatstr.format(expected)+")\n"
  f.write(lines)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  testnum = testnum+1

##################################
# main body
##################################

# change these to suite your tests
tests = ["timer"]
author = "ushakya@hmc.edu"
xlens = [64, 32]
numrand = 100;

# setup
seed(0) # make tests reproducible

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
    imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
    basename = "WALLY-IE" 
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
      a = getrandbits(xlen)
      b = getrandbits(xlen)
      writeVector(a, xlen, storecmd)

    writeTrapHandlers(storecmd)

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

"""
#!/usr/bin/python3
##################################
# testgen-IE.py
#
# ushakya@hmc.edu 24 Mar 2021
#
# Generate tests for mie CSR for RISC-V Design Validation.
##################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint 
from random import seed
from enum import Enum
from random import getrandbits

##################################
# functions
##################################

def randRegs():
  reg1 = randint(1,30)
  reg2 = randint(1,30)
  reg3 = randint(1,30)
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return reg1, reg2, reg3

def writeVectors(storecmd):  
  global testnum
  reg1, reg2, reg3 = randRegs()

  # Set interupt enable bit in mstatus
  lines = ""
  li x2, 0x8
  csrrs x3, mstatus, x2
  ""

  f.write(lines)

 # Save and set trap handler address for machine mode timer interrupt
  lines += ""
  la x1, _timer_trap_handler
  csrrw x31, mtvec, x1
  ""
  f.write(lines)

  # Machine Mode Timer Interrupt (when interupt is enabled)
  # is this not working because mtimecmp isn't implemented????
  write(f""
    li x2, 0x0

    li x4, 0x80
    csrrs x0, mie, x4

    {storecmd} x2, {str(wordsize*testnum)}(x6)

    la x2, 0x2004000
    
    li x3, 0x0
    lw x5, 0(x2)
    sd x3, 0(x2)
    wfi
  "", storecmd, True, 4, "m")

  # Supervisor Timer Interrupt
  # user timer interupt

  # Machine mode external interrupt (hasn't been connected yet)

  # User external interrupt True, 8
  # Supervisor external interrupt True, 9

  # Save and set trap handler address for machine mode software interrupt
 # lines = ""
 # la x1, _interupt_trap_handler
 # csrrw x31, mtvec, x1
 # ""
 # f.write(lines)
 
  # Machine Mode software interupt (write to the CLINT)
  #write(f""
  #  li x6, 0x0
#
#    li x4, 0x8
#    csrrs x0, mie, x4
#    
#    li x3, 0x1
#    lw x4, clint
#    or x3, x4, x3
#    {storecmd} x3, clint
#  "", storecmd, True, 3, "m")

  # supervisor mode software interupt
  # user mode software interupt
  
  # timer interupt trap handler
  lines = f""
  _timer_trap_handler:
  li x2, 0x2A
  {storecmd} x2, {str(wordsize*testnum)}(x6)
  la x3, 0x2004000
  {storecmd} x2, 0(x3)
  mret
  ""

  # software interupt trap handler
  #lines += f""
  #_interupt_trap_handler:
  #li x6, 0x2A
  #li x3, 0x0
  #lw x4, clint
  #xor x3, x4, x3
  #{storecmd} x3, 0(clint)
 #mret
  #""
  lines += storecmd + " x" + str(reg3) + ", " + str(wordsize*testnum) + "(x6)"

  f.write(lines)

def write(lines, storecmd, interrupt, code, mode = "m"):
  global testnum

  # generate expected interrupt code
  expected = 0
  #(0 if not interrupt else (2**31 if xlen == 32 else 2**63)) + code
  # go back and fix expected

  lines = f""
    # Testcase {testnum}
    li x31, 0
    {lines}

    {storecmd} x31, {str(wordsize*testnum)}(x6)
    # RVTEST_IO_ASSERT_GPR_EQ(x0, 0, {formatstr.format(expected)})
  ""

  #if mode == "s":
    # go to supervisor mode
  #elif mode == "u":
    # go to user mode

  f.write(lines)

  if (xlen == 32):
    line = formatrefstr.format(expected)+""
  else:
    line = formatrefstr.format(expected % 2**32)+"" + formatrefstr.format(expected >> 32) + ""
  r.write(line)
  testnum = testnum+1

##################################
# main body
##################################

# name: (interrupt?, code)
# tests = {
#  'User software interrupt': (1, '0'),
#  'Supervisor software interrupt': (1, '1'),
#  'Machine software interrupt': (1, '3'),
#  'User timer interrupt': (1, '4'),
#  'Supervisor timer interrupt': (1, '5'),
#  'Machine timer interrupt': (1, '7'),
#  'User external interrupt': (1, '8'),
#  'Supervisor external interrupt': (1, '9'),
#  'Machine external interrupt': (1, '11'),
# }
author = "Udeema Shakya (ushakya@hmc.edu)"
xlens = [64, 32]
numrand = 60;

# setup
seed(0xC395DDEB9173AD42) # make tests reproducible

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

  imperaspath = f"../../../imperas-riscv-tests/riscv-test-suite/rv{xlen}p/""
  basename = "WALLY-IE"
  fname = imperaspath + "src/" + basename + ".S"
  refname = imperaspath + "references/" + basename + ".reference_output"
  testnum = 0

  # print custom header part
  f = open(fname, "w")
  r = open(refname, "w")
  line = "///////////////////////////////////////////"
  f.write(line)
  lines="// "+fname+ "// " + author + ""
  f.write(lines)
  line ="// Created " + str(datetime.now()) 
  f.write(line)

  # insert generic header
  h = open("../testgen_header.S", "r")
  for line in h:  
    f.write(line)

  # print directed and random test vectors
  writeVectors(storecmd)


  # print footer
  h = open("../testgen_footer.S", "r")
  for line in h:  
    f.write(line)

  # Finish
  lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1"
  lines = lines + "RV_COMPLIANCE_DATA_END" 
   f.write(lines)
  f.close()
  r.close()
  """
