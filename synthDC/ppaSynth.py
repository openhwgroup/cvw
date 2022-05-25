#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 5/22

import subprocess
import re
from multiprocessing import Pool


def runCommand(module, width, tech, freq):
    command = "make synth DESIGN=ppa_{}_{} TECH={} DRIVE=INV FREQ={} MAXOPT=1".format(module, width, tech, freq)
    subprocess.Popen(command, shell=True)

def deleteRedundant(LoT):
    '''removes any previous runs for the current synthesis specifications'''
    synthStr = "rm -rf runs/ppa_{}_{}_rv32e_{}nm_{}_*"
    for synth in LoT:   
        bashCommand = synthStr.format(*synth)
        outputCPL = subprocess.check_output(['bash','-c', bashCommand])

def getData():
    bashCommand = "grep 'Critical Path Length' runs/ppa_*/reports/*qor*"
    outputCPL = subprocess.check_output(['bash','-c', bashCommand])
    linesCPL = outputCPL.decode("utf-8").split('\n')[:-1]

    cpl = re.compile('\d{1}\.\d{6}')
    f = re.compile('_\d*_MHz')
    wm = re.compile('ppa_\w*_\d*_qor')

    allSynths = []

    for i in range(len(linesCPL)):
        line = linesCPL[i]
        mwm = wm.findall(line)[0][4:-4].split('_')
        freq = int(f.findall(line)[0][1:-4])
        delay = float(cpl.findall(line)[0])
        mod = mwm[0]
        width = int(mwm[1])

        oneSynth = [mod, width, freq, delay]
        allSynths += [oneSynth]

    return allSynths

allSynths = getData()
arr = [-40, -20, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10, 14, 20, 40]

widths = [32, 64]
modules = ['flop', 'flopr']
tech = 'sky90'
LoT = []

# # # # initial sweep to get estimate of min delay
# freqs = ['10000', '15000', '20000']
# for module in modules:
#     for width in widths:
#         for freq in freqs:
#             LoT += [[module, width, tech, freq]]

# thorough sweep based on estimate of min delay
for m in modules:
    for w in widths:
        delays = []
        for oneSynth in allSynths:
            if (oneSynth[0] == m) & (oneSynth[1] == w):
                delays += [oneSynth[3]]
        try: f = 1000/min(delays)
        except: print(m)
        for freq in [str(round(f+f*x/100)) for x in arr]:
            LoT += [[m, w, tech, freq]]

deleteRedundant(LoT)

pool = Pool()
pool.starmap(runCommand, LoT)
pool.close()