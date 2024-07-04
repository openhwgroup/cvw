#!/usr/bin/env python3
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

  # t5 gets written with mtvec?

  # lines = f"""

  # li x{reg1}, 0
  # csrwi mtvec, 80002000
  # .data 00000000
  # j _done{testnum}

  # _trap{testnum}:
  # csrrs x{reg1}, mcause, x0
  # ecall

  # _done{testnum}:
  # add x0, x0, x0
  # """

  #lines = 


  # https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_chapter/as_7.html

  lines = f"""
  li x1, 100
  li x2, 200
  add x3, x1, x2
  add x6, x3, x3

  """
  f.write(lines)

  expected = 600

  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)

##################################
# main body
##################################

author = "Domenico Ottolia (dottolia@hmc.edu)"
xlens = [32, 64]
numrand = 60;

# setup
seed(0xC395D19B9173AD42) # make tests reproducible

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

  imperaspath = f"""../../../imperas-riscv-tests/riscv-test-suite/rv{xlen}p/"""
  basename = "WALLY-RET"
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
  # h = open("../testgen_header.S", "r")
  # for line in h:  
  #   f.write(line)

  # print directed and random test vectors

  h = open("../testgen_header.S", "r")
  for line in h:  
    f.write(line)

  writeVectors(storecmd)

  h = open("../testgen_footer.S", "r")
  for line in h:  
    f.write(line)

  # Finish
  lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
  lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
  f.write(lines)


  # print footer
  # h = open("../testgen_footer.S", "r")
  # for line in h:  
  #   f.write(line)

  # Finish
  # lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
  # lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
  # f.write(lines)
  f.close()
  r.close()

