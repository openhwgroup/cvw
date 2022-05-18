#!/usr/bin/python3
from distutils.log import error
import subprocess
import csv
import re
import matplotlib.pyplot as plt
import matplotlib.lines as lines
import numpy as np


def getData():
    bashCommand = "grep 'Critical Path Length' runs/ppa_*/reports/*qor*"
    outputCPL = subprocess.check_output(['bash','-c', bashCommand])
    linesCPL = outputCPL.decode("utf-8").split('\n')[:-1]

    bashCommand = "grep 'Design Area' runs/ppa_*/reports/*qor*"
    outputDA = subprocess.check_output(['bash','-c', bashCommand])
    linesDA = outputDA.decode("utf-8").split('\n')[:-1]

    bashCommand = "grep '100' runs/ppa_*/reports/*power*"
    outputP = subprocess.check_output(['bash','-c', bashCommand])
    linesP = outputP.decode("utf-8").split('\n')[:-1]

    cpl = re.compile('\d{1}\.\d{6}')
    f = re.compile('_\d*_MHz')
    wm = re.compile('ppa_\w*_\d*_qor')
    da = re.compile('\d*\.\d{6}')
    p = re.compile('\d+\.\d+[e-]*\d+')

    allSynths = []

    for i in range(len(linesCPL)):
        line = linesCPL[i]
        mwm = wm.findall(line)[0][4:-4].split('_')
        power = p.findall(linesP[i])
        oneSynth = [mwm[0], int(mwm[1])]
        oneSynth += [int(f.findall(line)[0][1:-4])]
        oneSynth += [float(cpl.findall(line)[0])]
        oneSynth += [float(da.findall(linesDA[i])[0])]
        oneSynth += [float(power[1])]
        oneSynth += [float(power[2])]
        allSynths += [oneSynth]

    return allSynths

def getVals(module, freq, var):
    global allSynths
    if (var == 'delay'):
        ind = 3 
        units = " (ps)"
    elif (var == 'area'):
        ind = 4
        units = " (sq microns)"
    elif (var == 'dpower'):
        ind = 5
        units = " (mW)"
    elif (var == 'lpower'):
        ind = 6
        units = " (nW)"
    else:
        error

    widths = []
    ivar = []
    for oneSynth in allSynths:
        if (oneSynth[0] == module) & (oneSynth[2] == freq):
            widths += [oneSynth[1]]
            ivar += [oneSynth[ind]]
    return widths, ivar, units

def writeCSV(allSynths):
    file = open("ppaData.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Width', 'Target Freq', 'Delay', 'Area', 'D Power (mW)', 'L Power (nW)'])

    for one in allSynths:
        writer.writerow(one)

    file.close()

def polyfitR2(x, y, deg):
    ''' from internet, check math'''
    z = np.polyfit(x, y, deg)
    p = np.poly1d(z)
    yhat = p(x)                         # or [p(z) for z in x]    
    ybar = np.sum(y)/len(y)          # or sum(y)/len(y)    
    ssreg = np.sum((yhat-ybar)**2)   # or sum([ (yihat - ybar)**2 for yihat in yhat])    
    sstot = np.sum((y - ybar)**2)    # or sum([ (yi - ybar)**2 for yi in y])    
    r2 = ssreg / sstot    
    return p, r2

def plotPPA(module, freq, var):
    '''
    module: string module name
    freq: int freq (GHz)
    var: string 'delay' or 'area'
    plots chosen variable vs width for all matching syntheses with regression
    '''

    # A = np.vstack([x, np.ones(len(x))]).T
    # mcresid = np.linalg.lstsq(A, y, rcond=None)
    # m, c = mcresid[0]
    # resid = mcresid[1]
    # r2 = 1 - resid / (y.size * y.var())
    # p, r2p = polyfitR2(x, y, 2)
    # zlog = np.polyfit(np.log(x), y, 1)
    # plog = np.poly1d(zlog)
    # xplog = np.log(xp)
    # _ = plt.plot(x, m*x + c, 'r', label='Linear fit R^2='+ str(r2)[1:7])
    # _ = plt.plot(xp, p(xp), label='Quadratic fit R^2='+ str(r2p)[:6])
    # _ = plt.plot(xp, plog(xplog), label = 'Log fit')

    widths, ivar, units = getVals(module, freq, var)
    coefs, r2 = regress(widths, ivar)

    xp = np.linspace(8, 140, 200)
    pred = [coefs[0] + x*coefs[1] + np.log(x)*coefs[2] + x*np.log(x)*coefs[3] for x in xp]

    r2p = round(r2[0], 4)
    rcoefs = [round(c, 3) for c in coefs]

    l = "{} + {}*N + {}*log(N) + {}*Nlog(N)".format(*rcoefs) 
    legend_elements = [lines.Line2D([0], [0], color='steelblue', label=module),
                       lines.Line2D([0], [0], color='orange', label=l),
                       lines.Line2D([0], [0], ls='', label=' R^2='+ str(r2p))]

    _ = plt.plot(widths, ivar, 'o', label=module, markersize=10)
    _ = plt.plot(xp, pred)
    _ = plt.legend(handles=legend_elements)
    _ = plt.xlabel("Width (bits)")
    _ = plt.ylabel(str.title(var) + units)
    _ = plt.title("Target frequency " + str(freq) + "MHz")
    plt.show()

def makePlots(mod):
    plotPPA(mod, 5000, 'delay')
    plotPPA(mod, 5000, 'area')
    plotPPA(mod, 10, 'area')
    plotPPA(mod, 5000, 'lpower')
    plotPPA(mod, 5000, 'dpower')

def regress(widths, var):

    mat = []
    for w in widths:
        row = [1, w, np.log(w), w*np.log(w)]
        mat += [row]
    
    y = np.array(var, dtype=np.float)
    coefsResid = np.linalg.lstsq(mat, y, rcond=None)
    coefs = coefsResid[0]
    resid = coefsResid[1] 
    r2 = 1 - resid / (y.size * y.var())
    return coefs, r2

def makeCoefTable():
    file = open("ppaFitting.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Metric', 'Freq', '1', 'N', 'log(N)', 'Nlog(N)', 'R^2'])

    for mod in ['add', 'mult', 'comparator', 'shifter']:
        for comb in [['delay', 5000], ['area', 5000], ['area', 10]]:
            var = comb[0]
            freq = comb[1]
            widths, ivar, units = getVals(mod, freq, var)
            coefs, r2 = regress(widths, ivar)
            row = [mod] + comb + np.ndarray.tolist(coefs) + [r2[0]]
            writer.writerow(row)

    file.close()

allSynths = getData()

writeCSV(allSynths)

makePlots('shifter')

makeCoefTable()

