This is a novel integer divider using r4 division by recurrence.  The
reference is:

J. E. Stine and K. Hill, "An Efficient Implementation of Radix-4
Integer Division Using Scaling," 2020 IEEE 63rd International Midwest
Symposium on Circuits and Systems (MWSCAS), Springfield, MA, USA,
2020, pp. 1092-1095, doi: 10.1109/MWSCAS48704.2020.9184631.

Although this version does not contain scaling, it could do this, if
needed.  Moreover, a higher radix or overlapped radix can be done
easily to expand the the size.  Also, the implementations here are
initially unsigned but hope to expand for signed, which should be
easy.

There are two types of tests in this directory within each testbench.
One tests for 32-bits and the other 64-bits:

int32div.do and int64div.do = test individual vector for debugging

iter32.do and iter64.do = do not use any waveform generation and just
output lots of tests

