#!/usr/bin/python3
#from msilib.schema import File
import subprocess
from multiprocessing import Pool
import csv
import re
import matplotlib.pyplot as plt
import numpy as np


def run_command(module, width, tech, freq):
    command = "make synth DESIGN=ppa_{}_{} TECH={} DRIVE=INV FREQ={} MAXOPT=1".format(module, width, tech, freq)
    subprocess.Popen(command, shell=True)

def deleteRedundant(LoT):
    '''not working'''
    synthStr = "rm -rf runs/ppa_{}_{}_rv32e_{}_{}_*"
    for synth in LoT:        
        print(synth)
        bashCommand = synthStr.format(*synth)
        outputCPL = subprocess.check_output(['bash','-c', bashCommand])

widths = ['8']
modules = ['add']
freqs = ['10']
tech = 'sky90'

LoT = []
for module in modules:
    for width in widths:
        for freq in freqs:
            LoT += [[module, width, tech, freq]]

deleteRedundant(LoT)

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
    mwm = wm.findall(line)[0][4:-4].split('_')
    oneSynth = [mwm[0], int(mwm[1])]
    oneSynth += [int(f.findall(line)[0][1:-4])]
    oneSynth += [float(cpl.findall(line)[0])]
    oneSynth += [float(da.findall(linesDA[i])[0])]
    allSynths += [oneSynth]

file = open("ppaData.csv", "w")
writer = csv.writer(file)
writer.writerow(['Module', 'Width', 'Target Freq', 'Delay', 'Area'])

for one in allSynths:
    writer.writerow(one)

file.close()


def plotPPA(module, freq, var):
    '''
    module: string module name
    freq: int freq (GHz)
    var: string 'delay' or 'area'
    plots chosen variable vs width for all matching syntheses with regression
    '''
    global allSynths
    ind = 3 if (var == 'delay') else 4
    widths = []
    ivar = []
    for oneSynth in allSynths:
        if (oneSynth[0] == module) & (oneSynth[2] == freq):
            
            widths += [oneSynth[1]]
            ivar += [oneSynth[ind]]

    x = np.array(widths, dtype=np.int)
    y = np.array(ivar, dtype=np.float)

    A = np.vstack([x, np.ones(len(x))]).T
    m, c = np.linalg.lstsq(A, y, rcond=None)[0]
    z = np.polyfit(x, y, 2)
    p = np.poly1d(z)

    xp = np.linspace(0, 140, 200)

    _ = plt.plot(x, y, 'o', label=module, markersize=10)
    _ = plt.plot(x, m*x + c, 'r', label='Linear fit')
    _ = plt.plot(xp, p(xp), label='Quadratic fit')
    _ = plt.legend()
    _ = plt.xlabel("Width (bits)")
    _ = plt.ylabel(str.title(var))
    plt.show()


plotPPA('add', 5000, 'delay')