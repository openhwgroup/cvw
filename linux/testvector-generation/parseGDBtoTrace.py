#!/usr/bin/env python3
import sys, fileinput, re

# Ross Thompson
# July 27, 2021
# Rewrite of the linux trace parser.


InstrStartDelim = '=>'
InstrEndDelim = '-----'

#InputFile = 'noparse.txt'
#InputFile = sys.stdin
#InputFile = 'temp.txt'
#OutputFile = 'parsedAll.txt'

HUMAN_READABLE = False

def toDict(lst):
    'Converts the list of register values to a dictionary'
    dct= {}
    for item in lst:
        regTup = item.split()
        dct[regTup[0]] = int(regTup[2], 10)
    del dct['pc']
    return dct

def whichClass(text, Regs):
    'Which instruction class?'
    #print(text, Regs)
    if text[0:2] == 'ld' or text[0:2] == 'lw' or text[0:2] == 'lh' or text[0:2] == 'lb':
        return ('load', WhatAddr(text, Regs), None, WhatMemDestSource(text))
    elif text[0:2] == 'sd' or text[0:2] == 'sw' or text[0:2] == 'sh' or text[0:2] == 'sb':
        return ('store', WhatAddr(text, Regs), WhatMemDestSource(text), None)
    elif text[0:3] == 'amo':
        return ('amo', WhatAddrAMO(text, Regs), WhatMemDestSource(text), WhatMemDestSource(text))
    elif text[0:2] == 'lr':
        return ('lr', WhatAddrLR(text, Regs), None, WhatMemDestSource(text))
    elif text[0:2] == 'sc':
        return ('sc', WhatAddrSC(text, Regs), WhatMemDestSource(text), None)
    else:
        return ('other', None, None, None)

def whatChanged(dct0, dct1):
    'Compares two dictionaries of instrution registers and indicates which registers changed'
    dct = {}
    for key in dct0:
        if (dct1[key] != dct0[key]):
            dct[key] = dct1[key]
    return dct

def WhatMemDestSource(text):
    ''''What is the destination register. Used to compute where the read data is 
    on a load or the write data on a store.'''
    return text.split()[1].split(',')[0]

def WhatAddr(text, Regs):
    'What is the data memory address?'
    Imm = text.split(',')[1]
    (Imm, Src) = Imm.split('(')
    Imm = int(Imm.strip(), 10)
    Src = Src.strip(')').strip()
    RegVal = Regs[Src]
    return Imm + RegVal

def WhatAddrAMO(text, Regs):
    'What is the data memory address?'
    Src = text.split('(')[1]
    Src = Src.strip(')').strip()
    return Regs[Src]

def WhatAddrLR(text, Regs):
    'What is the data memory address?'
    Src = text.split('(')[1]
    Src = Src.strip(')').strip()
    return Regs[Src]

def WhatAddrSC(text, Regs):
    'What is the data memory address?'
    Src = text.split('(')[1]
    Src = Src.strip(')').strip()
    return Regs[Src]

def PrintInstr(instr):
    if instr[2] == None:
        return
    ChangedRegisters = instr[4]
    GPR = ''
    CSR = []
    for key in ChangedRegisters:
        # filter out csr which are not checked.
        if(key in RegNumber):
            if(RegNumber[key] < 32):
                # GPR
                if(HUMAN_READABLE):
                    GPR = '{:-2d} {:016x}'.format(RegNumber[key], ChangedRegisters[key])
                else:
                    GPR = '{:d} {:x}'.format(RegNumber[key], ChangedRegisters[key])
            else:
                if(HUMAN_READABLE):
                    CSR.extend([key, '{:016x}'.format(ChangedRegisters[key])])
                else:
                    CSR.extend([key, '{:x}'.format(ChangedRegisters[key])])                

    CSRStr = ' '.join(CSR)

    #print(instr)

    if (HUMAN_READABLE == True):
        outString='{:016x} {:08x} {:25s}'.format(instr[0], instr[1], instr[2])
        if(len(GPR) != 0):
            outString+=' GPR {}'.format(GPR)
        if(instr[3] == 'load' or instr[3] == 'lr'):
            outString+=' MemR {:016x} {:016x} {:016x}'.format(instr[5], 0, instr[7])
        if(instr[3] == 'store'):
            outString+='\t\t\t    MemW {:016x} {:016x} {:016x}'.format(instr[5], instr[6], 0)
        if(len(CSR) != 0):
            outString+=' CSR {}'.format(CSRStr)
    else:
        outString='{:x} {:x} {:s}'.format(instr[0], instr[1], instr[2].replace(' ', '_'))
        if(len(GPR) != 0):
            outString+=' GPR {}'.format(GPR)
        if(instr[3] == 'load' or instr[3] == 'lr'):
            outString+=' MemR {:x} {:x} {:x}'.format(instr[5], 0, instr[7])
        if(instr[3] == 'store'):
            outString+=' MemW {:x} {:x} {:x}'.format(instr[5], instr[6], 0)
        if(len(CSR) != 0):
            outString+=' CSR {}'.format(CSRStr)
    outString+='\n'
    return outString

# =========
# Main Code
# =========
# Parse argument for interrupt file
if len(sys.argv) != 2:
    sys.exit('Error parseGDBtoTrace.py expects 1 arg:\n <interrupt filename>>')
interruptFname = sys.argv[1]
# reg number
RegNumber = {'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4, 't0': 5, 't1': 6, 't2': 7, 's0': 8, 's1': 9, 'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17, 's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27, 't3': 28, 't4': 29, 't5': 30, 't6': 31, 'mhartid': 32, 'mstatus': 33, 'mip': 34, 'mie': 35, 'mideleg': 36, 'medeleg': 37, 'mtvec': 38, 'stvec': 39, 'mepc': 40, 'sepc': 41, 'mcause': 42, 'scause': 43, 'mtval': 44, 'stval': 45, 'mscratch': 46, 'sscratch': 47, 'satp': 48}
# initial state
CurrentInstr = ['0', '0', None, 'other', {'zero': 0, 'ra': 0, 'sp': 0, 'gp': 0, 'tp': 0, 't0': 0, 't1': 0, 't2': 0, 's0': 0, 's1': 0, 'a0': 0, 'a1': 0, 'a2': 0, 'a3': 0, 'a4': 0, 'a5': 0, 'a6': 0, 'a7': 0, 's2': 0, 's3': 0, 's4': 0, 's5': 0, 's6': 0, 's7': 0, 's8': 0, 's9': 0, 's10': 0, 's11': 0, 't3': 0, 't4': 0, 't5': 0, 't6': 0, 'mhartid': 0, 'mstatus': 0, 'mip': 0, 'mie': 0, 'mideleg': 0, 'medeleg': 0, 'mtvec': 0, 'stvec': 0, 'mepc': 0, 'sepc': 0, 'mcause': 0, 'scause': 0, 'mtval': 0, 'stval': 0, 'mscratch': 0, 'sscratch': 0, 'satp': 0}, {}, None, None, None]

#with open (InputFile, 'r') as InputFileFP:
#lines = InputFileFP.readlines()
lineNum = 0
StartLine = 0
EndLine = 0
numInstrs = 0
#instructions = []
MemAdr = 0
lines = []
interrupts=open(interruptFname,'w')
interrupts.close()

prevInstrOutString=''
currInstrOutString=''
for line in fileinput.input('-'):
    if line.startswith('riscv_cpu_do_interrupt'):
        with open(interruptFname,'a') as interrupts:
            # Write line
            # Example line: hart:0, async:0, cause:0000000000000002, epc:0x0000000080008548, tval:0x0000000000000000, desc=illegal_instruction
            interrupts.write(line)
            # Write instruction count
            interrupts.write(str(numInstrs)+'\n')
            # Convert line to rows of info for easier Verilog parsing
            vals=line.strip('riscv_cpu_do_interrupt: ').strip('\n').split(',')
            vals=[val.split(':')[-1].strip(' ') for val in vals]
            vals=[val.split('=')[-1].strip(' ') for val in vals]
            for val in vals:
                interrupts.write(val+'\n')
        continue
    lines.insert(lineNum, line)
    if InstrStartDelim in line:
        lineNum = 0
        StartLine = lineNum
    elif InstrEndDelim in line:
        EndLine = lineNum
        (InstrBits, text) = lines[StartLine].split(':')
        InstrBits = int(InstrBits.strip('=> '), 16)
        text = text.strip()
        PC = int(lines[StartLine+1].split(':')[0][2:], 16)
        Regs = toDict(lines[StartLine+2:EndLine])
        (Class, Addr, WriteReg, ReadReg) = whichClass(text, Regs)
        #print("CWR", Class, WriteReg, ReadReg)
        PreviousInstr = CurrentInstr

        Changed = whatChanged(PreviousInstr[4], Regs)

        if (ReadReg !=None): ReadData = ReadReg
        else: ReadData = None

        if (WriteReg !=None): WriteData = WriteReg
        else: WriteData = None

        CurrentInstr = [PC, InstrBits, text, Class, Regs, Changed, Addr, WriteData, ReadData]

        #print(CurrentInstr[0:4], PreviousInstr[5], CurrentInstr[6:7], PreviousInstr[8])

        # pc, instrbits, text and class come from the last line.
        MoveInstrToRegWriteLst = PreviousInstr[0:4]
        # updated registers come from the current line.
        MoveInstrToRegWriteLst.append(CurrentInstr[5])   # destination regs
        # memory address if present comes from the last line.
        MoveInstrToRegWriteLst.append(PreviousInstr[6])  # MemAdrM
        # write data from the previous line
        #MoveInstrToRegWriteLst.append(PreviousInstr[7])   # WriteDataM

        if (PreviousInstr[7] != None):
            MoveInstrToRegWriteLst.append(Regs[PreviousInstr[7]])   # WriteDataM
        else:
            MoveInstrToRegWriteLst.append(None)

        # read data from the current line
        #MoveInstrToRegWriteLst.append(PreviousInstr[8])   # ReadDataM
        if (PreviousInstr[8] != None):
            MoveInstrToRegWriteLst.append(Regs[PreviousInstr[8]])   # ReadDataM
        else:
            MoveInstrToRegWriteLst.append(None)

        lines.clear()
        #instructions.append(MoveInstrToRegWriteLst)

        prevInstrOutString = currInstrOutString
        currInstrOutString = PrintInstr(MoveInstrToRegWriteLst)
        # Remove duplicates
        if (PreviousInstr[0] != CurrentInstr[0]) and (currInstrOutString != None):
            sys.stdout.write(currInstrOutString)
            numInstrs += 1
            if (numInstrs % 1e5 == 0):
                sys.stderr.write('GDB trace parser reached '+str(numInstrs/1.0e6)+' million instrs.\n')
                sys.stderr.flush()
    lineNum += 1


#for instruction in instructions[1::]:


#with open(OutputFile, 'w') as OutputFileFP:
#    print('opened file')



