#!/usr/bin/python3
##################################
# testgen-CAUSE.py
#
# dottolia@hmc.edu 16 Mar 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
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

# def computeExpected(a, b, test):
#   if (test == "ADD"):
#     return a + b
#   elif (test == "SUB"):
#     return a - b
#   else:
#     die("bad test name ", test)
#   #  exit(1)

def randRegs():
  reg1 = randint(1,31)
  reg2 = randint(1,31)
  reg3 = randint(1,31)
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return reg1, reg2, reg3

def writeVectors(storecmd):  
  reg1, reg2, reg3 = randRegs()

  lines = f"""
  li x{reg1}, 0
  """

  write(lines, storecmd, reg1, 0)

def write(lines, storecmd, reg, expected):
  global testnum

  lines = f"""
    # Testcase {testnum}
    {lines}

    {storecmd} x{reg}, {str(wordsize*testnum)}(x6)
    #RVTEST_IO_ASSERT_GPR_EQ(x0, 0, {formatstr.format(expected)})
  """
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

# name: (interrupt?, code)
tests = {
 'User software interrupt': (1, '0'),
 'Supervisor software interrupt': (1, '1'),
 'Machine software interrupt': (1, '3'),
 'User timer interrupt': (1, '4'),
 'Supervisor timer interrupt': (1, '5'),
 'Machine timer interrupt': (1, '7'),
 'User external interrupt': (1, '8'),
 'Supervisor external interrupt': (1, '9'),
 'Machine external interrupt': (1, '11'),
 'Instruction address misaligned': (0, '0'),
 'Instruction access fault': (0, '1'),
 'Illegal instruction': (0, '2'),
 'Breakpoint': (0, '3'),
 'Load address misaligned': (0, '4'),
 'Load access fault': (0, '5'),
 'Store/AMO address misaligned': (0, '6'),
 'Store/AMO access fault': (0, '7'),
 'Environment call from U-mode': (0, '8'),
 'Environment call from S-mode': (0, '9'),
 'Environment call from M-mode': (0, '11'),
 'Instruction page fault': (0, '12'),
 'Load page fault': (0, '13'),
 'Store/AMO page fault': (0, '15'),
}
author = "dottolia@hmc.edu"
xlens = [32, 64]
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

  imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/privileged/"
  basename = "WALLY-CAUSE-" + str(xlen)
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

