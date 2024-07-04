#!/usr/bin/env python3
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

def writeTrapHandlers(storecmd, mode):
  global testnum
  [reg1, reg2, reg3] = [30, 29, 28]
  [reg4, reg5] = [27, 26]
  if mode == "M":
    lines = "\n# Trap Handler: Machine Timer Interupt\n"
    lines += "_timerM_trap_handler:\n"
    lines += "li x" + str(reg1) + ", MASK_XLEN(0xFFFF)\n"
    lines += "la x" + str(reg2) + ", 0x2004000\n"
    lines += str(storecmd) + " x" + str(reg1) + ",  0(x" + str(reg2) + ")\n"
    lines += "csrrc x" + str(reg3) + ", mepc, x0\n"
    lines += "addi x"+ str(reg3) + ", x" + str(reg3) + ", MASK_XLEN(0x4)\n"
    lines += "csrrw x0, mepc, x" + str(reg3) + "\n"
    # clear machine timer interupt enable bit in mie
    lines += "li x" + str(reg4) + ", MASK_XLEN(" + str(0x80) + ")\n"
    lines += "csrrc x0, mie, x" + str(reg4) + "\n"
    lines += "mret\n"
  elif mode == "S":
    lines = "\n# Trap Handler: Supervisor Timer Interupt\n"
    lines += "_timerS_trap_handler:\n"
    lines += "li x" + str(reg4) + ", MASK_XLEN(0x20)\n"
    lines += "csrrc x0, mip, x" + str(reg4) + "\n"
    lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
    lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
    lines += "mret\n"

  #lines += "\n# Trap Handler: User Timer Interupt\n"
  #lines += "_timerU_trap_handler:\n"
  #lines += "li x" + str(reg4) + ", MASK_XLEN(0x10)\n"
  #lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  #lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  #lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  #lines += "mret\n"

  #lines += "\n# Trap Handler: Machine Software Interupt\n"
  #lines += "_softwareM_trap_handler:\n"
  #lines += "li x" + str(reg1) + ", MASK_XLEN(0x0)\n" # clear MSIP bit in CLINT
  #lines += "la x" + str(reg2) + ", 0x2000000\n"
  #lines += str(storecmd) + " x" + str(reg1) + ",  0(x" + str(reg2) + ")\n"
  ##lines += "csrrs x" + str(reg3) + ", mepc, x0\n"
  #lines += "addi x"+ str(reg3) + ", x" + str(reg3) + ", MASK_XLEN(0x4)\n"
  #lines += "csrrw x0, mepc, x" + str(reg3) + "\n"
  #lines += "mret\n"

  """lines += "\n# Trap Handler: Supervisor Software Interupt\n"
  lines += "_softwareS_trap_handler:\n"
  lines += "li x" + str(reg4) + ", MASK_XLEN(0x2)\n"
  lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  lines += "csrrs x" + str(reg5) + ", mepc, x0\n"
  lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  lines += "csrrw x0, mepc, x" + str(reg5) + "\n"
  lines += "mret\n"
"""
  #lines += "\n# Trap Handler: User Software Interupt\n"
  #lines += "_softwareU_trap_handler:\n"
  #lines += "li x" + str(reg4) + ", MASK_XLEN(0x1)\n"
  #lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  #lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  #lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  #lines += "mret\n"

  #lines += "\n# Trap Handler: Machine External Interupt\n"
  #lines += "_externalM_trap_handler:\n"
  #lines += "li x" + str(reg1) + ", MASK_XLEN(0x0)\n" # clear MSIP bit in CLINT
  #lines += "la x" + str(reg2) + ", 0x2000000\n"
  #lines += str(storecmd) + " x" + str(reg1) + ",  0(x" + str(reg2) + ")\n"
  #lines += "csrrw x" + str(reg3) + ", mepc, x0\n"
  #lines += "addi x"+ str(reg3) + ", x" + str(reg3) + ", MASK_XLEN(0x4)\n"
  #lines += "mret\n"

  #lines += "\n# Trap Handler: Supervisor External Interupt\n"
  #lines += "_externalS_trap_handler:\n"
  #lines += "li x" + str(reg4) + ", MASK_XLEN(0x200)\n"
  #lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  #lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  #lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  #lines += "mret\n"

  #lines += "\n# Trap Handler: User External Interupt\n"
  #lines += "_externalU_trap_handler:\n"
  #lines += "li x" + str(reg4) + ", MASK_XLEN(0x100)\n"
  #lines += "csrrc x0, mip, x" + str(reg4) + "\n"
  #lines += "csrrw x" + str(reg5) + ", mepc, x0\n"
  #lines += "addi x"+ str(reg5) + ", x" + str(reg5) + ", MASK_XLEN(0x4)\n"
  #lines += "mret\n"

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

  # Registers used:
  # x13 ---> read mcause value
  # x12 ---> save old value of mtvec
  # x8  ---> holds mieE
  # x5  ---> holds value of trap handler
  # x3  ---> holds mstatusE
  # remaining registers (not used by mode management) are free to be used by tests

  [reg2, reg3] = [2, 3]
  [reg5, reg8] = [5, 8]
  [reg10, reg11, reg12] = [10, 11, 12]
  [reg13, reg14, reg15] = [13, 14, 15]

  lines = f"\n# Testcase {testnum}: {test} Interupt\n"
  
  # mcause code
  expected = getMcause()

  [mstatusE, mieE] = getInteruptEnableValues()
  # ensure interupt enable bit in mie is low
  lines += "li x" + str(reg8) + ", MASK_XLEN(" + formatstr.format(mieE) + ")\n"
  lines += "csrrc x0, mie, x" + str(reg8) + "\n"

  # set interupt enable bit in mstatus
  lines += "li x" + str(reg3) + ", MASK_XLEN(" + formatstr.format(mstatusE) + ")\n"
  lines += "csrrs x0, mstatus, x" + str(reg3) + "\n"

  # Save and set trap handler address for interrupt
  lines += "la x" + str(reg5) + ", _" + test + "_trap_handler\n"
  
  # save orignal mtvec address
  lines += "csrrw x" + str(reg12) + ", mtvec, x" + str(reg5) + "\n"
  
  # cause timer interupt
  if test == "timerM":
    
    # load MTIMECMP register address
    lines += "la x" + str(reg2) + ", 0x2004000\n"

    # to be stored in MTIMECMP
    lines += "li x" + str(reg10) + ", MASK_XLEN(0)\n"

    # save old value of mtimecmp and then set mtimecmp to zero
    if xlens == 64:
      lines += "lw x" + str(reg11) + ", 0(x" + str(reg2) + ")\n"
      lines += str(storecmd) + " x" + str(reg10) + ",  0(x" + str(reg2) + ")\n"

    elif xlen == 32:
      lines += "lw x" + str(reg11) + ", 0(x" + str(reg2) + ")\n"
      lines += str(storecmd) + " x" + str(reg10) + ",  0(x" + str(reg2) + ")\n"
      lines += str(storecmd) + " x" + str(reg10) + ",  4(x" + str(reg2) + ")\n"

  elif test == "timerS":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x20)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"
  
  # cause software interupt
  if test == "softwareM":
    lines += "la x" + str(reg8) + ", 0x2000000\n" # Write to the MSIP bit in CLINT
    lines += "li x" + str(reg11) + ", MASK_XLEN(0x1)\n"
    lines += str(storecmd) + " x" + str(reg11) + ",  0(x" + str(reg8) + ")\n"
  elif test == "softwareS":
    lines += "li x" + str(reg3) + ", MASK_XLEN(0x2)\n"
    lines += "csrrs x0, mip, x" + str(reg3) + "\n"
  

  # set timer interupt enable bit in mie
  lines += "csrrs x0, mie, x" + str(reg8) + "\n"
  
  # wait for interupt to be taken
  lines += "nop\nnop\n"

  lines += "csrrs " + " x" + str(reg13) + ", mcause, x0\n"

  # reset mtvec
  lines += "csrrw x0, mtvec, x" + str(reg12) + "\n"

  lines += storecmd + " x" + str(reg13) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, x" + str(reg13) +", "+formatstr.format(expected)+")\n"
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
tests = ["timerM"] #, "timerM", "timerS", "softwareM", "softwareS"]
author = "ushakya@hmc.edu"
xlens = [64] #, 32]
modes = ["M"]#, "S"]
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
  for mode in modes:
    imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
    basename = "WALLY-" + mode + "IE"
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
    
    line = "\n"
    # Registers used for dropping down to supervisor mode:
    # x30 ---> set to 1 if we should return to & stay in machine mode after trap, 0 otherwise
    # x20 ---> hold address of _j_all_end_{returningInstruction}
    # x19 ---> save old value of mtvec
    # x18 ---> save old value of medeleg
    # x16 ---> save old value of mideleg
    # x9  ---> bit mask for mideleg and medeleg
    # x1  ---> used to go down to supervisor mode

    # We need to leave at least one bit in medeleg unset so that we have a way to get
    # back to machine mode when the tests are complete (otherwise we'll only ever be able
    # to get up to supervisor mode). 
    #
    # So, we define a returning instruction which will be used to cause the exception that
    # brings us into machine mode. The bit for this returning instruction is NOT set in
    # medeleg. However, this also means that we can't test that instruction. So, we have
    # two different returning instructions.
    #
    # Current code is written to only support ebreak and ecall.
    #
    # For testgen-IE, we don't need to test ebreak, so we can use that as the sole
    # returning instruction.
    returningInstruction = "ebreak"
    if mode == "S":
      # need to move down to supervisor mode (based on code in testgen-TVAL)
      lines += f"""
        # Reset x30 to 0 so we can run the tests. We'll set this to 1 when tests are completed so we stay in machine mode
        li x30, 0
      """

      # We don't want to delegate our returning instruction. Otherwise, we'll have no way of getting
      # back to machine mode at the end! (and we need to be in machine mode to complete the tests)
      medelegMask = "0b1111111111110111" if returningInstruction == "ebreak" else "0b1111000011111111"

      # Set medeleg and mideleg
      lines += f"""
        csrr x18, medeleg
        li x9, {medelegMask if testMode == "s" or testMode == "u" else "0"}
        csrw medeleg, x9

        csrr x16, mideleg
        li x9, {"0xffffffff" if testMode == "s" or testMode == "u" else "0"}
        csrw mideleg, x9
      """

      # bring down to supervisor mode
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

    for test in tests:
      # print directed and random test vectors
      for i in range(0,numrand):
        a = getrandbits(xlen)
        writeVectors(a, xlen, storecmd)

    if mode == "S":
      # Bring us back up to machine mode!
      # Creates a new trap handler that just jumps to _j_all_end_{returningInstruction}
      #
      # Get into the trap handler by running returningInstruction (in this case its ebreak) 
      f.write(f"""
        li x30, 1 #may not need this 
        csrr x19, mtvec # save old value of mtvec
        la x20 _j_all_end_{returningInstruction}
        csrw mtvec, x20
        {returningInstruction}

        _returnMachineMode_handler:
        j _j_all_end_{returningInstruction}
        mret

        _j_all_end_{returningInstruction}:

        # Reset trap handling csrs to old values
        csrw mtvec, x19
        csrw medeleg, x18
        csrw mideleg, x16
      """)
    
    f.write(lines)

    # print footer
    h = open("../testgen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
    lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
    lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
    f.write(lines)

    writeTrapHandlers(storecmd, mode)

    f.close()
    r.close()
