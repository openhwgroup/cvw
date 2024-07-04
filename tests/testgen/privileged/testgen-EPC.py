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

def writeVectors(storecmd):
  global testnum

  # Load address misaligned
  writeTest(storecmd, f, r, f"""
    ecall
  """, False, 9)
  

def writeTest(storecmd, f, r, test, interrupt, code, resetHander = ""):
  global testnum
  global testMode

  nops = ""
  for i in range(0, randint(1, 16)):
    nops+="nop\n"

  lines = f"""
    {nops}
    li x25, 0xDEADBEA7
    auipc x26, 0
    addi x26, x26, 8
    {test}

    _jend{testnum}:

    {storecmd} x25, 0(x7)
    addi x7, x7, {wordsize}
  """

  f.write(lines)

  expected = 0

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
numrand = 64;

# setup
seed(0x9365DDEB9173AB42) # make tests reproducible

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

  for testMode in ["m", "s"]:
    imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
    basename = "WALLY-" + testMode.upper() + "EPC"
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

    # All registers used:
    # x30: set to 1 if we should return to & stay in machine mode after trap, 0 otherwise
    # ...
    # x26: expected epc value
    # x25: value to write to memory
    # ...
    # x19: mtvec old value
    # x18: medeleg old value
    # x17: sedeleg old value


    lines = f"""
      add x7, x6, x0
      csrr x19, mtvec

      csrr x18, medeleg
      li x9, {"0b1100000000" if testMode == "s" or testMode == "u" else "0b0000000000"}
      csrs medeleg, x9

    """

    if testMode == "u":
      lines += f"""
        csrr x17, sedeleg
        li x9, {"0b1100000000" if testMode == "u" else "0b0000000000"}
        csrs sedeleg, x9
        """

    lines += f"""

      li x30, 0

      la x1, _j_m_trap
      csrw mtvec, x1
      la x1, _j_s_trap
      csrw stvec, x1
      la x1, _j_u_trap
      csrw utvec, x1
      j _j_t_begin

      _j_m_trap:
      csrrs x1, mepc, x0
      {"sub x25, x26, x1" if testMode == "m" else "li x25, 0xBAD00003"}

      addi x1, x1, 4
      csrrw x0, mepc, x1
      bnez x30, _j_all_end
      mret

      _j_s_trap:
      csrrs x1, sepc, x0
      {"sub x25, x26, x1" if testMode == "s" else "li x25, 0xBAD00001"}

      addi x1, x1, 4
      csrrw x0, sepc, x1
      bnez x30, _j_goto_machine_mode
      sret

      _j_u_trap:
      csrrs x1, uepc, x0
      {"sub x25, x26, x1" if testMode == "u" else "li x25, 0xBAD00000"}

      addi x1, x1, 4
      csrrw x0, uepc, x1
      bnez x30, _j_goto_supervisor_mode
      uret

      _j_goto_supervisor_mode:
      csrw sedeleg, x17
      j _j_goto_machine_mode

      _j_goto_machine_mode:
      csrw medeleg, x18
      li x30, 1
      ecall

      _j_t_begin:
    """

    fromModeOptions = ["m", "s", "u"] if testMode == "m" else (["s", "u"] if testMode == "s" else ["u"])

    f.write(lines)

    for fromMode in fromModeOptions:
      lines = ""
      
      if fromMode == "s" or fromMode == "u":
        lines += f"""
          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        """

      if fromMode == "u":
        lines += f"""

        li x1, 0b110000000000
        csrrc x31, sstatus, x1

        auipc x1, 0
        addi x1, x1, 16 # x1 is now right after the sret instruction
        csrw sepc, x1
        sret

        # We're now in user mode...
        """

      # print directed and random test vectors
      f.write(lines)
      for i in range(0,numrand):
        writeVectors(storecmd)


    f.write(f"""
      li x30, 1
      ecall
      _j_all_end:

      csrw mtvec, x19
    """)

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
