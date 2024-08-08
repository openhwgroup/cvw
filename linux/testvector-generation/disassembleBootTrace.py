#!/usr/bin/env python3
# 
# disassembleBootTrace.py
# David_Harris@hmc.edu 22 November 2023
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# 
# Reads boottrace.log and disassembles the machine code
#

import csv
import os
import re

# read a file from sim/logs/boottrace.log and extract the second comma-separated field containing the instruction
print("Reading boottrace.log")
trace = []
count = 0
with open('../../sim/logs/boottrace.log') as f:
    reader = csv.reader(f, delimiter=',')
    for row in reader:
        trace.append(row)
        count = count + 1
        if count > 50000000:
            break
f.close()

print("Disassembling boottrace.log instructions")
# Write an assembly language file with the machine code
with (open('boottrace.S', 'w')) as f:
    f.write('main:\n')
    for row in trace:
        instr = row[1]
        # scrape off leading white space from instr
        instr = instr.lstrip()
        # check if last character indicates an compressed or uncompressed instruction
        lastNibble = instr[-1]
        if (lastNibble == '3' or lastNibble == '7' or lastNibble == 'b' or lastNibble == 'f'): 
            # uncompressed
             f.write('.word 0x' + instr + '\n')
        else:
            # compressed
            instr = instr[-4:]
            f.write('.hword 0x' + instr + '\n')
f.close()

# Then assemble and disassemble the file
os.system('riscv64-unknown-elf-gcc -march=rv64gqc_zba_zbb_zbc_zbs_zfh_zicboz_zicbop_zicbom -mabi=lp64d -c boottrace.S')
os.system('riscv64-unknown-elf-objdump -D boottrace.o > boottrace.objdump')

# Patch disassembly back into boottrace
print("Inserting disassembly into trace")
dumpedLines = []
with (open('boottrace.objdump', 'r')) as f:
    lines = f.readlines()
    f.close()
lines = lines[7:]       # skip header
p = r'[^:]*:\s*(\S*)\s*(.*)'
for line in lines:
    match = re.search(p, line)
    if (match):
        dump = [match.group(1), match.group(2)]
        dumpedLines.append(dump)

linenum = 0
for i in range(len(trace)):
    row = trace[i]
    row.insert(2, dumpedLines[i][1])

# write trace back to csv file
print("Writing trace back to boottrace_disasm.log")
with (open('boottrace_disasm.log', 'w')) as f:
    writer = csv.writer(f)
    writer.writerows(trace)
f.close()
