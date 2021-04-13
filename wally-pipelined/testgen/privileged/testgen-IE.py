#!/usr/bin/python3
##################################
# testgen-IE.py
#
# ushakya@hmc.edu 31 March 2021
# Modified: 4 April 2021
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
  [reg1, reg2, reg3] = [30, 29, 28]
  [reg4, reg5] = [27, 26]
  lines = "\n# Trap Handler: Machine Timer Interupt\n"
  lines += "_timerM_trap_handler:\n"
  lines += "li x" + str(reg1) + ", MASK_XLEN(0x2A)\n"
  lines += "la x" + str(reg2) + ", 0x2004000\n"
  lines += str(storecmd) + " x" + str(reg1) + ",  0(x" + str(reg2) + ")\n"
  lines += "csrrw x" + str(reg3) + ", mepc, x0\n"
  lines += "addi x"+ str(reg3) + ", x" + str(reg3) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: Supervisor Timer Interupt\n"
  lines += "_timerS_trap_handler:\n"
  lines += "li x" + str(reg4) + ", MASK_XLEN(0x20)\n"
  lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: User Timer Interupt\n"
  lines += "_timerU_trap_handler:\n"
  lines += "li x" + str(reg4) + ", MASK_XLEN(0x10)\n"
  lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: Machine Software Interupt\n"
  lines += "_softwareM_trap_handler:\n"
  lines += "li x" + str(reg1) + ", MASK_XLEN(0x0)\n" # clear MSIP bit in CLINT
  lines += "la x" + str(reg2) + ", 0x2000000\n"
  lines += str(storecmd) + " x" + str(reg1) + ",  0(x" + str(reg2) + ")\n"
  lines += "csrrw x" + str(reg3) + ", mepc, x0\n"
  lines += "addi x"+ str(reg3) + ", x" + str(reg3) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: Supervisor Software Interupt\n"
  lines += "_softwareS_trap_handler:\n"
  lines += "li x" + str(reg4) + ", MASK_XLEN(0x2)\n"
  lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: User Software Interupt\n"
  lines += "_softwareU_trap_handler:\n"
  lines += "li x" + str(reg4) + ", MASK_XLEN(0x1)\n"
  lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: Machine External Interupt\n"
  lines += "_externalM_trap_handler:\n"
  #lines += "li x" + str(reg1) + ", MASK_XLEN(0x0)\n" # clear MSIP bit in CLINT
  #lines += "la x" + str(reg2) + ", 0x2000000\n"
  #lines += str(storecmd) + " x" + str(reg1) + ",  0(x" + str(reg2) + ")\n"
  lines += "csrrw x" + str(reg3) + ", mepc, x0\n"
  lines += "addi x"+ str(reg3) + ", x" + str(reg3) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: Supervisor External Interupt\n"
  lines += "_externalS_trap_handler:\n"
  lines += "li x" + str(reg4) + ", MASK_XLEN(0x200)\n"
  lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  lines += "\n# Trap Handler: User External Interupt\n"
  lines += "_externalU_trap_handler:\n"
  lines += "li x" + str(reg4) + ", MASK_XLEN(0x100)\n"
  lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  lines += "mret\n"

  f.write(lines)

def getInteruptEnableValues():
  if test == "timerM":
    mstatusE = 0x8
    mieE = 0x80
  elif test == "timerS":
    mstatusE = 0x2
    mieE = 0x20
  elif test == "timerU":
    mstatusE = 0x1
    mieE = 0x10
  elif test == "softwareM":
    mstatusE = 0x8
    mieE = 0x8
  elif test == "softwareS":
    mstatusE = 0x2
    mieE = 0x2
  elif test == "softwareU":
    mstatusE = 0x1
    mieE = 0x1
  elif test == "externalM":
    mstatusE = 0x8
    mieE = 0x800
  elif test == "externalS":
    mstatusE = 0x2
    mieE = 0x200
  elif test == "externalU":
    mstatusE = 0x1
    mieE = 0x100
  return [mstatusE, mieE]

def getMcause():
  b = 1 << (xlen-1)
  if test == "timerM":
    b = b + 0x7
  elif test == "timerS":
    b = b + 0x5
  elif test == "timerU":
    b = b + 0x4
  elif test == "softwareM":
    b = b + 0x3
  elif test == "softwareS":
    b = b + 0x1
  elif test == "softwareU":
    b = b
  elif test == "externalM":
    b = b + 0xB
  elif test == "externalS":
    b = b + 0x9
  elif test == "externalU":
    b = b + 0x8
  return b

def writeVectors(a, xlen, storecmd):
  global testnum

  [reg1, reg2, reg3] = [1, 2, 3]
  [reg5, reg8] = [5, 8]
  [reg9, reg10, reg11, reg12] = [9, 10, 11, 12]

  lines = f"\n# Testcase {testnum}: {test} Interupt\n"
  
  # mcause code
  expected = getMcause()
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(expected) + ")\n"

  if (testnum == 0): expected = 0

  [mstatusE, mieE] = getInteruptEnableValues()
  # set interupt enable bit in mstatus
  lines += "li x" + str(reg3) + ", MASK_XLEN(" + str(mstatusE) + ")\n"
  lines += "csrrs x0, mstatus, x" + str(reg3) + "\n"

  # set timer interupt enable bit in mie
  lines += "li x" + str(reg9) + ", MASK_XLEN(" + str(mieE) + ")\n"
  lines += "csrrs x0, mie, x" + str(reg3) + "\n"

  # Save and set trap handler address for interrupt
  lines += "la x" + str(reg5) + ", _" + test + "_trap_handler\n"
  
  # save orignal mtvec address
  lines += "csrrw x" + str(reg12) + ", mtvec, x" + str(reg5) + "\n"
  
  # cause timer interupt
  if test == "timerM":
    lines += "li x" + str(reg8) + ", MASK_XLEN(0)\n"
    lines += str(storecmd) + " x" + str(reg8) + ", " + str(wordsize*testnum)+ "(x6)\n"
    
    lines += "la x" + str(reg8) + ", 0x2004000\n"

    lines += "li x" + str(reg3) + ", MASK_XLEN(0)\n"

    # save old value of mtimecmp and then set mtimecmp to zero
    lines += "lw x" + str(reg11) + ", 0(x" + str(reg8) + ")\n"
    lines += str(storecmd) + " x" + str(reg3) + ",  0(x" + str(reg8) + ")\n"
  elif test == "timerS":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x20)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"
  elif test == "timerU":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x10)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"
  
  # cause software interupt
  if test == "softwareM":
    lines += "la x" + str(reg8) + ", 0x2000000\n" # Write to the MSIP bit in CLINT
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x1)\n"
    lines += str(storecmd) + " x" + str(reg3) + ",  0(x" + str(reg8) + ")\n"
  elif test == "softwareS":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x2)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"
  elif test == "softwareU":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x1)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"
  
  # cause external interupt
  # Not sure how to cause an external machine interupt yet
  # will writing to PLIC just cause it? (where is the ExtIntM located in PLIC)
  #if test == "externalM":
    #lines += "la x" + str(reg8) + ", 0x2000000\n" # Write to the MSIP bit in CLINT
    #lines += "li x" + str(reg3) + ", MASK_XLEN(0x1)\n"
    #lines += str(storecmd) + " x" + str(reg3) + ",  0(x" + str(reg8) + ")\n"
  if test == "externalS":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x200)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"
  elif test == "externalU":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x100)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"

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
tests = ["timerM"] #, "timerS", "timerU", "softwareM", "softwareS", "softwareU"]
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
      writeVectors(a, xlen, storecmd)

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
