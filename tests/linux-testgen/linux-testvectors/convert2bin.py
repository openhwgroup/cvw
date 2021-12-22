#!/usr/bin/python3

asciiBinFile = 'ram.txt'
binFile = 'ram.bin'

asciiBinFP = open(asciiBinFile, 'r')
binFP = open (binFile, 'wb')

for line in asciiBinFP.readlines():
    binFP.write(int(line, 16).to_bytes(8, byteorder='little', signed=False))

asciiBinFP.close()
binFP.close()    
