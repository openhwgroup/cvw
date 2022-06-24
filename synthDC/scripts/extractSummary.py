#!/usr/bin/python3
# Shreya Sanghai (ssanghai@hmc.edu) 2/28/2022
import glob 
import re
import csv
import linecache
import os 

# field_names = [ 'Name', 'Critical Path Length', 'Cell Area', 'Synth Time']
# data = []
# for name in glob.glob("/home/ssanghai/riscv-wally/synthDC/runs/*/reports/wallypipelinedcore_qor.rep"):   
#     f = open(name, 'r')
#     # trimName = re.search("runs\/(.*?)\/reports", name).group(1)
#     trimName = re.search("wallypipelinedcore_(.*?)_sky9",name).group(1)
#     for line in f:
#         if "Critical Path Length" in line:
#             pathLen = re.search("Length: *(.*?)\\n", line).group(1) 
#         if "Cell Area" in line:
#             area = re.search("Area: *(.*?)\\n", line).group(1) 
#         if "Overall Compile Time" in line:
#             time = re.search("Time: *(.*?)\\n", line).group(1)
#     data += [{'Name' : trimName, 'Critical Path Length': pathLen, 'Cell Area' : area, 'Synth Time' :time}]

def main():
    data = []
    curr_dir = os.path.dirname(os.path.abspath(__file__))
    output_file = os.path.join(curr_dir,"..","Summary.csv")
    runs_dir = os.path.join(curr_dir,"..","runs/*/reports/wallypipelinedcore_qor.rep")
    # cruns_dir = "/home/ssanghai/Desktop/cleanRun/*/reports/wallypipelinedcore_qor.rep"
    search_strings = [
        "Critical Path Length:", "Cell Area:", "Overall Compile Time:",
        "Critical Path Clk Period:", "Critical Path Slack:"
    ]
    for name in glob.glob(runs_dir):   
        f = open(name, 'r')
        trimName = re.search("wallypipelinedcore_(.*?)_sky",name).group(1)

        output = {'Name':trimName}
        num_lines = len(f.readlines())
        curr_line_index = 0

        while curr_line_index < num_lines:
            line = linecache.getline(name, curr_line_index)
            for search_string in search_strings:
                if search_string in line:
                    val = getVal(name,search_string,line,curr_line_index)
                    output[search_string] = val
            curr_line_index +=1 
        data += [output]

    with open(output_file, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=['Name'] + search_strings)
        writer.writeheader()
        writer.writerows(data)
        
def getVal(filename, search_string, line, line_index):
    data = re.search(f"{search_string} *(.*?)\\n", line).group(1)
    if data == '': #sometimes data is stored in two line
        data = linecache.getline(filename, line_index+1).strip()
    return data

if __name__=="__main__":
    main()
                