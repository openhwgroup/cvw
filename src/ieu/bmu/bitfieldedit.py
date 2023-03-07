""" 
    bitfieldedit.py
    Script that appends 0 just before the "illegal instruction" field of the bitstring
    Written by Kevin Kim <kekim@hmc.edu>
"""
def addZero(s):
    try:
        indexSemicolon = s.index(";")
        newS = s[:indexSemicolon-1]+"0_"+s[indexSemicolon-1:]
        return newS
    except: return s

def main():
    filename = input("Enter full filename: ")
    n1 = int(input("Line number to begin: "))
    n2 = int(input("Line number to end: "))
    f = open(filename, "r")
    flines = f.readlines()

    #create list of lines from line n1 to n2, inclusive
    lines = flines[(n1-1):(n2-1)]

    #string to be printed
    out = ""

    for i in range(len(lines)):
        lines[i] = addZero(lines[i])
        out += lines[i]
    print(out)

if __name__ == "__main__":
    main()