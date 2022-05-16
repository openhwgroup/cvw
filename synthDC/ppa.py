#!/usr/bin/python3
# from msilib.schema import File
import subprocess
from multiprocessing import Pool
import csv
import re
# import matplotlib.pyplot as plt
# import numpy as np

print("hi")

def run_command(module, width, freq):
    command = "make synth DESIGN=ppa_{}_{} TECH=sky90 DRIVE=INV FREQ={} MAXOPT=1".format(module, width, freq)
    subprocess.Popen(command, shell=True)

widths = ['16']
modules = ['shifter']
freqs = ['10']


LoT = []
for module in modules:
    for width in widths:
        for freq in freqs:
            LoT += [[module, width, freq]]

pool = Pool()
pool.starmap(run_command, LoT)
pool.close()

bashCommand = "grep 'Critical Path Length' runs/ppa_*/reports/*qor*"
outputCPL = subprocess.check_output(['bash','-c', bashCommand])
linesCPL = outputCPL.decode("utf-8").split('\n')[:-1]

bashCommand = "grep 'Design Area' runs/ppa_*/reports/*qor*"
outputDA = subprocess.check_output(['bash','-c', bashCommand])
linesDA = outputDA.decode("utf-8").split('\n')[:-1]

cpl = re.compile('\d{1}\.\d{6}')
f = re.compile('_\d*_MHz')
wm = re.compile('ppa_\w*_\d*_qor')
da = re.compile('\d*\.\d{6}')

allSynths = []

for i in range(len(linesCPL)):
    line = linesCPL[i]
    oneSynth = []
    mwm = wm.findall(line)[0][4:-4].split('_')
    oneSynth += [mwm[0]]
    oneSynth += [mwm[1]]
    oneSynth += [f.findall(line)[0][1:-4]]
    oneSynth += cpl.findall(line)
    oneSynth += da.findall(linesDA[i])
    allSynths += [oneSynth]

file = open("ppaData.csv", "w")
writer = csv.writer(file)
writer.writerow(['Module', 'Width', 'Target Freq', 'Delay', 'Area'])

for one in allSynths:
    writer.writerow(one)

file.close()