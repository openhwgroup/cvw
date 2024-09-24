#!/usr/bin/env python3

import sys, fileinput

address = 0


for line in fileinput.input('-'):
    # the 14- is to reverse the byte order to little endian
    formatedLine = ' '.join(line[14-i:14-i+2] for i in range(0, len(line), 2))
    sys.stdout.write('@{:08x} {:s}\n'.format(address, formatedLine))
    address+=8
