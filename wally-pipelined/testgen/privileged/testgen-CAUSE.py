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
  j _setup
  csrrs x31, mcause, x0
  csrrs x30, mepc, x0
  addi x30, x30, 0x100
  csrrw x0, mepc, x30
  mret

  _setup:
  li x2, 0x80000004
  csrrw x0, mtvec, x2

  """
  f.write(lines)

  # # User Software Interrupt
  # write(f"""
  #   li x3, 0x8000000
  #   {storecmd} x2, 0(x3)
  # """, storecmd, True, 0, "u")

  # # A supervisor-level software interrupt is triggered on the current hart by writing 1 to its supervisor software interrupt-pending (SSIP) bit in the sip register.
  # # page 58 of priv spec
  # # Supervisor Software Interrupt
  # write(f"""
  #   li x3, 0x8000000
  #   {storecmd} x2, 0(x3)
  # """, storecmd, True, 0, "s")

  # # Machine Software Interrupt
  # write(f"""
  #   li x3, 0x8000000
  #   {storecmd} x2, 0(x3)
  # """, storecmd, True, 3)

  # User Timer Interrupt
  #write(f"""
  #  lw x2, mtimecmp
  #  {storecmd} x2, mtimecmp
  #""", storecmd, True, 4, "u")

 # # Supervisor Timer Interrupt
  #write(f"""
  #  lw x2, mtimecmp
  #  {storecmd} x2, mtimecmp
  #""", storecmd, True, 5, "s")

  # Machine Timer Interrupt
  #write(f"""
  #  lw x2, mtimecmp
  #  {storecmd} x2, mtimecmp
  #""", storecmd, True, 6)

  # User external interrupt True, 8
  # Supervisor external interrupt True, 9

  # Instr Addr Misalign
  write(f"""
    li x2, 0x00000000
    lw x3, 11(x2)
  """, storecmd, False, 0)

  # Instr Access Fault False, 1
  # Not possible in machine mode, because we can access all memory

  # Illegal Instruction
  # . fill 1, 2, 0 outputs all 0s
  write(f"""
      .fill 1, 2, 0
  """, storecmd, False, 2)

  # Breakpoint
  write(f"""
    ebreak
  """, storecmd, False, 3)

  # Load Addr Misalign
  write(f"""
    li x2, 0x00000000
    lw x3, 11(x2)
  """, storecmd, False, 4)

  # Load Access Fault False, 5
    # Not possible in machine mode, because we can access all memory


  # Store/AMO address misaligned
  write(f"""
    li x2, 0x00000000
    {storecmd} x3, 11(x2)
  """, storecmd, False, 6)

  # Store/AMO access fault False, 7
  # Not possible in machine mode, because we can access all memory

  # Environment call from U-mode
  # Environment call from S-mode

def write(lines, storecmd, interrupt, code, mode = "m"):
  global testnum

  # generate expected interrupt code
  expected = (0 if not interrupt else (2**31 if xlen == 32 else 2**63)) + code

  lines = f"""
    # Testcase {testnum}
    li x31, 0
    {lines}

    {storecmd} x31, {str(wordsize*testnum)}(x6)
    # RVTEST_IO_ASSERT_GPR_EQ(x0, 0, {formatstr.format(expected)})
  """

  #if mode == "s":
    # go to supervisor mode
  #elif mode == "u":
    # go to user mode

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
#  'Instruction address misaligned': (0, '0'),
#  'Instruction access fault': (0, '1'),
#  'Illegal instruction': (0, '2'),
#  'Breakpoint': (0, '3'),
#  'Load address misaligned': (0, '4'),
#  'Load access fault': (0, '5'),
#  'Store/AMO address misaligned': (0, '6'),
#  'Store/AMO access fault': (0, '7'),
#  'Environment call from U-mode': (0, '8'),
#  'Environment call from S-mode': (0, '9'),
#  'Environment call from M-mode': (0, '11'),
#  'Instruction page fault': (0, '12'),
#  'Load page fault': (0, '13'),
#  'Store/AMO page fault': (0, '15'),
# }
author = "Domenico Ottolia (dottolia@hmc.edu)"
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

  imperaspath = f"""../../../imperas-riscv-tests/riscv-test-suite/rv{xlen}p/"""
  basename = "WALLY-CAUSE"
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
  writeVectors(storecmd)


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

