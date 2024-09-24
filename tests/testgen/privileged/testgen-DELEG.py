#!/usr/bin/env python3
##################################
# testgen-CAUSE.py
#
# dottolia@hmc.edu 27 Apr 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
#
#
##################################
# DOCUMENTATION:
# Most of the comments explaining what everything
# does can be found in testgen-TVAL.py
###################################

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

def writeVectors(storecmd):
  global testnum

  # User Software Interrupt: True, 0
  # Supervisor Software Interrupt: True, 1
  # Machine Software Interrupt: True, 2

  writeTest(storecmd, f, r, "timer-interrupt", True, -1) # code determined inside of writeTest

  # User external input: True, 8
  # Supervisor external input: True, 9
  # Machine externa input: True, 11

  # Instruction address misaligned: False, 0

  # Instruction access fault: False, 1

  # Illegal Instruction 
  writeTest(storecmd, f, r, f"""
    .fill 1, 4, 0
  """, False, 2)

  # Breakpoint
  writeTest(storecmd, f, r, "ebreak", False, 3)

  # Load Address Misaligned 
  writeTest(storecmd, f, r, f"""
    lw x0, 11(x0)
  """, False, 4)

  # # Load Access fault: False, 5
  # TODO: THIS NEEDS TO BE IMPLEMENTED

  # # Store/AMO address misaligned
  writeTest(storecmd, f, r, f"""
    sw x0, 11(x0)
  """, False, 6)

  # Breakpoint: codes 8, 9, 11
  writeTest(storecmd, f, r, "ecall", False, -1) # code determined inside of writeTest

  # Instruction page fault: 12
  # TODO: THIS NEEDS TO BE IMPLEMENTED

  # Load page fault: 13
  # TODO: THIS NEEDS TO BE IMPLEMENTED

  # Store/AMO page fault: 15
  # TODO: THIS NEEDS TO BE IMPLEMENTED
  

  #writeTest(storecmd, f, r, "ecall", False, 11, "m")
  
def writeTest(storecmd, f, r, test, interrupt, code, resetHander = ""):
  global testnum
  global testMode
  global isInterrupts

  beforeTest = ""

  if interrupt != isInterrupts:
    return
  
  isTimerInterruptTest = test == "timer-interrupt"
  delegateType = "i" if interrupt else "e"
  for mode in (["m", "s", "u"] if testMode == "m" else ["s", "u"]):
    if isTimerInterruptTest:
      clintAddr = "0x2004000"

      if mode == "m":
        code = 7
        test = f"""
          la x18, {clintAddr}
          {storecmd} x0, 0(x18)
        """

      elif mode == "s":
        code = 5
        test = ""
      else:
        code = 4
        test = ""

      ieMask = 1 << code
      statusMask = 0b1010

      beforeTest = f"""
        li x1, {statusMask}
        csrrs x0, mstatus, x1

        li x1, 0b0010
        csrrs x0, sstatus, x1

        la x18, {clintAddr}
        lw x11, 0(x18)
        li x1, 0x7fffffffffffffff
        {storecmd} x1, 0(x18)

        li x1, {ieMask}
        csrrs x0, mie, x1

        li x1, {ieMask}
        csrrs x0, sie, x1
      """

      resetHander = f"""
        #li x1, 0x80
        #csrrc x0, sie, x1

        li x1, {ieMask}
        csrrc x0, mie, x1

        li x1, {ieMask}
        csrrc x0, sie, x1

        li x1, {statusMask}
        csrrc x0, mstatus, x1

        li x1, 0b0010
        csrrc x0, sstatus, x1

        la x18, {clintAddr}
        {storecmd} x11, 0(x18)
      """

      if mode == "s":
        beforeTest += f"""
          li x1, {ieMask}
          csrrs x0, sip, x1
        """

        resetHander += f"""
          li x1, {ieMask}
          csrrc x0, sip, x1
        """

    elif test == "ecall":
      if mode == "m":
        code = 11
      elif mode == "s":
        code = 9
      else:
        code = 8

    mask = 1 << code
    for delegated in [True, False]:
      labelSuffix = testnum

      f.write(f"""
        _start_{labelSuffix}:

        la x1, _j_m_trap_{labelSuffix}
        csrw mtvec, x1
        la x1, _j_s_trap_{labelSuffix}
        csrw stvec, x1

        j _j_test_{labelSuffix}

        _j_m_trap_{labelSuffix}:
        {resetHander}
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_{labelSuffix}
        mret

        _j_s_trap_{labelSuffix}:
        {resetHander}
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_{labelSuffix}
        sret

        _j_goto_machine_mode_{labelSuffix}:
        li x30, 1
        {"ebreak" if test is not "ebreak" else "ecall"}

        _j_test_{labelSuffix}:
      """)

      original = f"""
        li x1, {mask if delegated else 0}
        csrw m{delegateType}deleg, x1
      """

      if mode != "m":
        lines = f"""
          {original}

          {beforeTest}

          li x1, 0b110000000000
          csrrc x31, {testMode}status, x1
          li x1, 0b{"01" if mode == "s" else "00"}00000000000
          csrrs x31, {testMode}status, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, {testMode}epc, x1
          {testMode}ret

          # From {testMode}, we're now in {mode} mode...
          {test}
        """

        writeTestInner(storecmd, f, r, lines, 1 if delegated else 3)

        f.write(f"""
          j _j_goto_machine_mode_{labelSuffix}
        """)

      else:
        lines = f"""
          {original}
          {beforeTest}
          {test}
        """
        writeTestInner(storecmd, f, r, lines, 3)

      f.write(f"""
        _j_finished_{labelSuffix}:
        li x30, 0
      """)
      

def writeTestInner(storecmd, f, r, lines, expected):
  global testnum

  lines = f"""
    li x25, 0xDEADBEA7
    {lines}
  """

  lines += storecmd + " x25, " + str(testnum * wordsize) + "(x6)\n"
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
author = "dottolia@hmc.edu"
xlens = [32, 64]
numrand = 1;

# setup
seed(0xD0C0_D0C0_D0C0_D0C0) # make tests reproducible

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

  for testMode in ["m"]:
    for isInterrupts in [True, False]:
      imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
      basename = "WALLY-" + testMode.upper() + ("I" if isInterrupts else "E") + "DELEG"
      fname = imperaspath + "src/" + basename + ".S"
      refname = imperaspath + "references/" + basename + ".reference_output"

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

      # All registers used:
      # x19: mtvec old value
      # x18: medeleg old value
      # x17: mideleg old value

      f.write(f"""
        add x7, x6, x0
        csrr x19, mtvec
        csrr x18, medeleg
        csrr x17, medeleg
      """)

      testnum = 0
      for i in range(0, 2):
        writeVectors(storecmd)

      f.write(f"""
        csrw mtvec, x19
        csrw medeleg, x18
        csrw mideleg, x17
      """)

      # if we're in supervisor mode, this leaves the ebreak instruction untested (we need a way to)
      # get back to machine mode. 

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



