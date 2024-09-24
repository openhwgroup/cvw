#!/usr/bin/env python3
##################################
# testgen-CSR-PERMISSIONS.py
#
# dottolia@hmc.edu 1 May 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
# Verify that an illegal instruction is raised when trying to write to csrs of a higher privilege
#
##################################
# DOCUMENTATION:
#
# Most of the comments explaining what everything
# does and the layout of the privileged tests
# can be found in this file
#
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

testCount = 2

def writeVectors(storecmd, testMode):
  global testnum

  csrs = ["status", "edeleg", "ideleg", "ie", "tvec", "counteren", "scratch", "epc", "cause", "tval", "ip"]
  if testMode == "s":
    csrs.append("atp")
  #csrs = ["status"]
  for csrStart in csrs:
    for i in range(0, testCount):
      a = 1

      csr = testMode + csrStart

      # only check for CSR changes if testing machine-mode registers
      csrWillChange = testMode == "s" or csrStart == "status" or csrStart == "epc" or csrStart == "cause" or csrStart == "tval"
      newCSRValue = "" if testMode == "s" else "csrr x24, " + csr

      f.write(f"""
        li x13, 1
      """)

      fromModeOptions = ["s", "u"] if testMode == "m" else ["u"]
      for fromMode in fromModeOptions:
        label = f"""{fromMode}_{csr}_{testnum}"""
        endlabel = f"""_j_end_{label}"""
        # This is all from testgen-TVAL.py, within the for loop on returningInstruction
        #
        # x25: mepc value
        # x24: new csr value
        # x23: original csr value
        lines = f"""
          li x30, 0
          la x1, _m_trap_from_{label}
          csrw mtvec, x1

          csrr x23, {csr}

          j _j_test_{label}

          _m_trap_from_{label}:
          bnez x30, {endlabel}

          csrr x25, mcause
          {newCSRValue}

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_{label}:
        """

        lines += f"""
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        """

        # Code to bring us down to user mode
        if fromMode == "u":
          lines += f"""

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          """

        f.write(lines)


        writeTest(storecmd, f, r, f"""csrrw x1, {csr}, x0""", csrWillChange)
        writeTest(storecmd, f, r, f"""csrrw x0, {csr}, x13""", csrWillChange)
        writeTest(storecmd, f, r, f"""csrrwi x0, {csr}, {a}""", csrWillChange)
        if a != 0:
          writeTest(storecmd, f, r, f"""csrrs x0, {csr}, x13""", csrWillChange)
          writeTest(storecmd, f, r, f"""csrrc x0, {csr}, x13""", csrWillChange)
          writeTest(storecmd, f, r, f"""csrrsi x0, {csr}, {a}""", csrWillChange)
          writeTest(storecmd, f, r, f"""csrrci x0, {csr}, {a}""", csrWillChange)

        f.write(f"""
          li x30, 1
          ebreak
          {endlabel}:
        """)


  

def writeTest(storecmd, f, r, test, csrWillChange):
  global testnum

  test = f"""
    _jdo{testnum}:
    li x25, 0xDEADBEA7

    {test}

    {storecmd} x25, 0(x7)
    addi x7, x7, {wordsize}
  """

  # We expect x25 to always be an illegal instruction
  expected = 2

  f.write(test)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  testnum = testnum+1

  if not csrWillChange:
    # We expect x24 should be equal to x23
    expected = 0

    f.write(f"""
      sub x25, x24, x23
      {storecmd} x25, 0(x7)
      addi x7, x7, {wordsize}
    """)
    if (xlen == 32):
      line = formatrefstr.format(expected)+"\n"
    else:
      line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
    r.write(line)
    testnum = testnum+1

##################################
# main body
##################################

author = "dottolia@hmc.edu"
xlens = [32, 64]

# setup
# Change this seed to a different constant value for every test
seed(0xC363DAEB9193AB45) # make tests reproducible

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

  for testMode in ["m", "s"]:
    imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
    basename = "WALLY-CSR-PERMISSIONS-" + testMode.upper()
    fname = imperaspath + "src/" + basename + ".S"
    refname = imperaspath + "references/" + basename + ".reference_output"
    testnum = 0
    storeAddressOffset = 0

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

    f.write(f"""
      add x7, x6, x0
      csrr x19, mtvec
    """)

    writeVectors(storecmd, testMode)

    f.write(f"""
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




