#!/usr/bin/python3

# fma16_testgen.py
# David_Harris@hmc.edu 26 February 2022
# Generate test cases for 16-bit FMA 
  
def makeVal(val):

def makeCase(x, y, z, mul, add, msg):
    xval = makeVal(x);
    yval = makeVal(y);
    zval = makeVal(z);
    mode = mul*2+add; # convert to hexadecimal code
    expected = makeExpected(x, y, z, mul, add);
    print(xval,"_", yval, "_", zval, "_", mode, "_", expected, " //", msg);

def makeMulCase(x, y, msg):
  makeCase(x, y, "0", 1, 0, msg)

################################
## Main program
################################

# Directed cases
makeMulCase("1", "1", "1 x 1");


# Corner cases

# Random cases

