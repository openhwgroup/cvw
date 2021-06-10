#! /usr/bin/python3
import sys, fileinput

sys.stderr.write("reminder: this script takes input from stdin\n")

csrs = ['fcsr','mcause','mcounteren','medeleg','mepc','mhartid','mideleg','mie','mip','misa','mscratch','mstatus','mtval','mtvec','pmpaddr0','pmpcfg0','satp','scause','scounteren','sepc','sie','sscratch','sstatus','stval','stvec']

# just for now, since these CSRs aren't yet ready to be checked in testbench-linux
list(map(csrs.remove, ['fcsr','mhartid','pmpcfg0','pmpaddr0','mip']))
#output_path = '/courses/e190ax/busybear_boot_new/'
#output_path = '/courses/e190ax/buildroot_boot/'
output_path = sys.argv[1]
print(f'output dir: {output_path}')
instrs = -1
try:
    with open('{}parsedPC.txt'.format(output_path), 'w') as wPC:
      with open('{}parsedRegs.txt'.format(output_path), 'w') as wReg:
        with open('{}parsedMemRead.txt'.format(output_path), 'w') as wMem:
          with open('{}parsedMemWrite.txt'.format(output_path), 'w') as wMemW:
            with open('{}parsedCSRs.txt'.format(output_path), 'w') as wCSRs:
              firstCSR = True
              curCSRs = {}
              lastRead = ''
              currentRead = ''
              readOffset = ''
              lastReadLoc = ''
              readType = ''
              lastReadType = ''
              readLoc = ''
              instrStart = -1
              lastRegs = ''
              curRegs = ''
              storeReg = ''
              storeOffset = ''
              storeLoc = ''
              storeAMO = ''
              lastAMO = ''
              lastStoreReg = ''
              lastStoreLoc = ''
              for l in fileinput.input('-'):
                l = l.split("#")[0].rstrip()
                if l.startswith('=>'):
                  instrs += 1
                  storeAMO = ''
                  if instrs % 10000 == 0:
                    print(instrs)
                  wPC.write('{} ***\n'.format(' '.join(l.split(':')[1].split()[0:2])))
                  if '\tld' in l or '\tlw' in l or '\tlh' in l or '\tlb' in l:
                    currentRead = l.split()[-1].split(',')[0]
                    if len(l.split()[-1].split(',')) < 2:
                      print(l)
                    readOffset = l.split()[-1].split(',')[1].split('(')[0]
                    readLoc = l.split()[-1].split(',')[1].split('(')[1][:-1]
                    readType = l.split()[-2]
                  if 'amo' in l:
                    #print(l)
                    currentRead = l.split()[-1].split(',')[0]
                    readOffset = "0"
                    readLoc = l.split()[-1].split('(')[1][:-1]
                    readType = l.split()[-2]
                    storeOffset = "0"
                    storeLoc = readLoc
                    storeReg = l.split()[-1].split(',')[1]
                    storeAMO = l.split()[-2]
                  if '\tsd' in l or '\tsw' in l or '\tsh' in l or '\tsb' in l:
                    #print(l)
                    s = l.split('#')[0].split()[-1]
                    storeReg = s.split(',')[0]
                    if len(s.split(',')) < 2:
                      print(s)
                      print(l)
                    if len(s.split(',')[1].split('(')) < 1:
                      print(s)
                      print(l)
                    storeOffset = s.split(',')[1].split('(')[0]
                    storeLoc = s.split(',')[1].split('(')[1][:-1]
                  instrStart = 0
                elif instrStart != -1:
                  instrStart += 1
                  if instrStart == 1:
                    wPC.write('{}\n'.format(l.split()[-1][2:]))
                  elif instrStart < 34:
                    if lastRead == l.split()[0]:
                      readData  = int(l.split()[1][2:], 16)
                      readData <<= (8 * (lastReadLoc % 8))
                      #if(lastReadLoc % 8 != 0 and ('lw' in lastReadType or 'lb' in lastReadType)):
                      #  readData <<= 32
                      wMem.write('{:x}\n'.format(readData))
                    if readLoc == l.split()[0]:
                      readLoc = l.split()[1][2:]
                    if storeReg == l.split()[0]:
                      storeReg = l.split()[1]
                    if storeLoc == l.split()[0]:
                      storeLoc = l.split()[1][2:]
                    if instrStart > 2:
                      #print(l)
                      #print(instrStart)
                      curRegs += '{}\n'.format(l.split()[1][2:])
                  elif instrStart < 35:
                    #print("----------")
                    #print(l.split()[1][2:])
                    wPC.write('{}\n'.format(l.split()[1][2:]))
                    #print(l.split()[1][2:])
                if any([c == l.split()[0] for c in csrs]):
                  if l.split()[0] in curCSRs:
                    if curCSRs[l.split()[0]] != l.split()[1]:
                      if firstCSR:
                        wCSRs.write('---\n')
                        firstCSR = False
                      wCSRs.write('{}\n{}\n'.format(l.split()[0], l.split()[1][2:]))
                  else:
                    wCSRs.write('{}\n{}\n'.format(l.split()[0], l.split()[1][2:]))
                  curCSRs[l.split()[0]] = l.split()[1]
                if '-----' in l: # end of each cycle
                    if curRegs != lastRegs:
                      if lastRegs == '':
                        wReg.write(curRegs)
                      else:
                        for i in range(32):
                          if curRegs.split('\n')[i] != lastRegs.split('\n')[i]:
                            wReg.write('{}\n'.format(i+1))
                            wReg.write('{}\n'.format(curRegs.split('\n')[i]))
                            break
                      lastRegs = curRegs
                    if lastAMO != '':
                      if 'amoadd' in lastAMO:
                        lastStoreReg = hex(int(lastStoreReg[2:], 16) + readData)[2:]
                      elif 'amoand' in lastAMO:
                        lastStoreReg = hex(int(lastStoreReg[2:], 16) & readData)[2:]
                      elif 'amoor' in lastAMO:
                        lastStoreReg = hex(int(lastStoreReg[2:], 16) | readData)[2:]
                      elif 'amoswap' in lastAMO:
                        lastStoreReg = hex(int(lastStoreReg[2:], 16))[2:]
                      else:
                        print(lastAMO)
                        exit()
                      wMemW.write('{}\n'.format(lastStoreReg))
                      wMemW.write('{:x}\n'.format(int(lastStoreLoc, 16)))
                    if storeReg != '' and storeOffset != '' and storeLoc != '' and storeAMO == '':
                      storeLocOffset = int(storeOffset,10) + int(storeLoc, 16)
                      #wMemW.write('{:x}\n'.format(int(storeReg, 16) << (8 * (storeLocOffset % 8))))
                      wMemW.write('{}\n'.format(storeReg[2:]))
                      wMemW.write('{:x}\n'.format(storeLocOffset))
                    if readOffset != '' and readLoc != '':
                      wMem.write('{:x}\n'.format(int(readOffset,10) + int(readLoc, 16)))
                      lastReadLoc = int(readOffset,10) + int(readLoc, 16)
                    lastReadType = readType
                    readOffset = ''
                    readLoc = ''
                    curRegs = ''
                    instrStart = -1
                    lastRead = currentRead
                    currentRead = ''
                    lastStoreReg = storeReg
                    lastStoreLoc = storeLoc
                    storeReg = ''
                    storeOffset = ''
                    storeLoc = ''
                    lastAMO = storeAMO


except (FileNotFoundError):
  print('please give gdb output file as argument')

