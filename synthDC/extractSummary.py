#!/usr/bin/python3
# Shreya Sanghai (ssanghai@hmc.edu) 2/28/2022
import glob 
import re
import csv

field_names = [ 'Name', 'Critical Path Length', 'Cell Area', 'Synth Time']
data = []
for name in glob.glob("/home/ssanghai/riscv-wally/synthDC/runs/*/reports/wallypipelinedcore_qor.rep"):   
    f = open(name, 'r')
    # trimName = re.search("runs\/(.*?)\/reports", name).group(1)
    trimName = re.search("wallypipelinedcore_(.*?)_sky9",name).group(1)
    for line in f:
        if "Critical Path Length" in line:
            pathLen = re.search("Length: *(.*?)\\n", line).group(1) 
        if "Cell Area" in line:
            area = re.search("Area: *(.*?)\\n", line).group(1) 
        if "Overall Compile Time" in line:
            time = re.search("Time: *(.*?)\\n", line).group(1)
    data += [{'Name' : trimName, 'Critical Path Length': pathLen, 'Cell Area' : area, 'Synth Time' :time}]

with open('Summary.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=field_names)
    writer.writeheader()
    writer.writerows(data)



            