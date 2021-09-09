#! /usr/bin/python3
import sys,os

if len(sys.argv) != 3:
    sys.exit('Error fix_mem.py expects 2 args:\n fix_mem.py <input filename> <output filename>')
inputFile = sys.argv[1]
outputFile = sys.argv[2]
if not os.path.exists(inputFile):
    sys.exit('Error input file '+inputFile+'not found')
print('Translating '+os.path.basename(inputFile)+' to '+os.path.basename(outputFile))
with open(inputFile, 'r') as f:
    with open(outputFile, 'w') as w:
        for l in f:
            w.write(f'{"".join([x[2:] for x in l.split()[:0:-1]])}\n')
