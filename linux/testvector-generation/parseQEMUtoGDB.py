#!/usr/bin/env python3
import fileinput, sys

parseState = "idle"
beginPageFault = 0
inPageFault = 0
endPageFault = 0
CSRs = {}
pageFaultCSRs = {}
regs = {}
pageFaultRegs = {}
instrs = {}
instrCount = 0
returnAdr = 0
sys.stderr.write("reminder: parse_qemu.py takes input from stdin\n")

def printPC(l):
    global parseState, inPageFault, CSRs, pageFaultCSRs, regs, pageFaultCSRs, instrs, instrCount
    if not inPageFault:
        inst = l.split()
        if len(inst) > 3:
            print(f'=> {inst[1]}:\t{inst[2]} {inst[3]}')
        else:
            print(f'=> {inst[1]}:\t{inst[2]}')
        print(f'{inst[0]} 0x{inst[1]}')
        instrCount += 1
        if ((instrCount % 100000) == 0):
            sys.stderr.write("QEMU parser reached "+str(instrCount)+" instrs\n")

def printCSRs():
    global parseState, inPageFault, CSRs, pageFaultCSRs, regs, pageFaultCSRs, instrs
    global interrupt_line
    if not inPageFault:
        for (csr,val) in CSRs.items():
            print('{}{}{:#x}  {}'.format(csr, ' '*(15-len(csr)), val, val))
        print('-----') # end of current instruction
        if len(interrupt_line)>0: # squish interrupts in between instructions
            print(interrupt_line)
            interrupt_line=""

def parseCSRs(l):
    global parseState, inPageFault, CSRs, pageFaultCSRs, regs, pageFaultCSRs, instrs
    if l.strip() and (not l.startswith("Disassembler")) and (not l.startswith("Please")):
        # If we've hit the register file
        if l.startswith(' x0/zero'): 
            parseState = "regFile"
            if not inPageFault:
                instr = instrs[CSRs["pc"]]
                printPC(instr)
            parseRegs(l)
        # If we've hit a CSR
        else:
            csr = l.split()[0]
            val = int(l.split()[1],16)
            # Commented out this conditional because the pageFault instrs don't corrupt CSRs
            #if inPageFault:
                # Not sure if these CSRs should be updated or not during page fault.
                #if l.startswith("mstatus") or l.startswith("mepc") or l.startswith("mcause") or l.startswith("mtval") or l.startswith("sepc") or l.startswith("scause") or l.startswith("stval"):
                    # We do update some CSRs
                #    CSRs[csr] = val
                #else:
                    # Others we preserve until changed later
                #    pageFaultCSRs[csr] = val
            #elif pageFaultCSRs and (csr in pageFaultCSRs):
            #    if (val != pageFaultCSRs[csr]):
            #        del pageFaultCSRs[csr]
            #        CSRs[csr] = val
            #else:
            #    CSRs[csr] = val
            #
            # However SEPC and STVAL do get corrupted upon exiting
            if endPageFault and ((csr == 'sepc') or (csr == 'stval')):
                CSRs[csr] = returnAdr
                pageFaultCSRs[csr] = val
            elif pageFaultCSRs and (csr in pageFaultCSRs):
                if (val != pageFaultCSRs[csr]):
                    del pageFaultCSRs[csr]
                    CSRs[csr] = val
            else:
                CSRs[csr] = val

def parseRegs(l):
    global parseState, inPageFault, CSRs, pageFaultCSRs, regs, pageFaultCSRs, instrs, pageFaultRegs
    if "pc" in l:
        printCSRs()
        # New non-disassembled instruction
        parseState = "CSRs"
        parseCSRs(l)
    elif l.startswith('--------'):
        # End of disassembled instruction
        printCSRs()
        parseState = "idle"
    else:
        s = l.split()
        for i in range(0,len(s),2):
            if '/' in s[i]:
                reg = s[i].split('/')[1]
                val = int(s[i+1], 16)
                if inPageFault:
                    pageFaultRegs[reg] = val
                else:
                    if pageFaultRegs and (reg in pageFaultRegs):
                        if (val != pageFaultRegs[reg]):
                            del pageFaultRegs[reg]
                            regs[reg] = val
                    else:
                        regs[reg] = val
                    val = regs[reg]
                    print('{}{}{:#x}  {}'.format(reg, ' '*(15-len(reg)), val, val))
            else:
                sys.stderr.write("Whoops. Expected a list of reg file regs; got:\n"+l)

#############
# Main Code #
#############
interrupt_line=""
for l in fileinput.input():
    #sys.stderr.write(l)
    if l.startswith('riscv_cpu_do_interrupt'):
        sys.stderr.write(l)
        interrupt_line = l.strip('\n')
    elif l.startswith('qemu-system-riscv64: QEMU: Terminated via GDBstub'):
        break
    elif l.startswith('IN:'):
        # New disassembled instr
        parseState = "instr"
    elif (parseState == "instr") and l.startswith('0x'):
        # New instruction
        if "out of bounds" in l:
            sys.stderr.write("Detected QEMU page fault error\n")
            beginPageFault = not inPageFault
            if beginPageFault:
                returnAdr = int(l.split()[0][2:-1], 16)
                sys.stderr.write('Saving SEPC of '+hex(returnAdr)+'\n')
            inPageFault = 1
        else: 
            endPageFault = inPageFault
            inPageFault = 0
            adr = int(l.split()[0][2:-1], 16)
            instrs[adr] = l
        parseState = "CSRs"
    elif parseState == "CSRs":
        parseCSRs(l)
    elif parseState == "regFile":
        parseRegs(l)
