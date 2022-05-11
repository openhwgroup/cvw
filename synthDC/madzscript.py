#!/usr/bin/python3
# from msilib.schema import File
import subprocess



bashCommand = "find . | grep ppa_timing.rep"
output = subprocess.check_output(['bash','-c', bashCommand])
files = output.decode("utf-8").split('\n')
print(files)

widths = []
areas = []
delays = []

for file in files:
    widths += [pullNum('ports', file)/3]
    areas += [pullNum('Total cell area', file)]
    delays += [pullNum('delay', file)]


def pullNum(keyText, file):
    return

# File_object = open("greppedareas","r")
# content = File_object.readlines()
# File_object.close()

# LoT = []
# for line in content:
#     l = line.split(':')
#     LoT += [float(l[2])]

# avg = sum(LoT)/len(LoT)

# print(avg)