#!/usr/bin/python3
import subprocess
import csv
import re
import matplotlib.pyplot as plt
import numpy as np

def getData():
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

    return allSynths

def writeCSV(allSynths):
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

    zlog = np.polyfit(np.log(x), y, 1)
    plog = np.poly1d(zlog)

    xp = np.linspace(0, 140, 200)
    xplog = np.log(xp)

    _ = plt.plot(x, y, 'o', label=module, markersize=10)
    _ = plt.plot(x, m*x + c, 'r', label='Linear fit')
    _ = plt.plot(xp, p(xp), label='Quadratic fit')
    _ = plt.plot(xp, plog(xplog), label = 'Log fit')
    _ = plt.legend()
    _ = plt.xlabel("Width (bits)")
    _ = plt.ylabel(str.title(var))
    _ = plt.title("Target frequency " + str(freq))
    plt.show()
#fix square microns, picosec, end plots at 8 to stop negs, add equation to plots and R2
# try linear term with delay as well (w and wo)

allSynths = getData()

writeCSV(allSynths)

plotPPA('mult', 5000, 'delay')
plotPPA('mult', 5000, 'area')
plotPPA('mult', 10, 'area')