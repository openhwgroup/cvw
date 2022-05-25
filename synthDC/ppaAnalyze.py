#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 5/22

from distutils.log import error
from statistics import median
import subprocess
import statistics
import csv
import re
import matplotlib.pyplot as plt
import matplotlib.lines as lines
import numpy as np


def getData(mod=None, width=None):
    specStr = ''
    if mod != None:
        specStr = mod
        if width != None:
            specStr += ('_'+str(width))
    specStr += '*'

    bashCommand = "grep 'Critical Path Length' runs/ppa_{}/reports/*qor*".format(specStr)
    outputCPL = subprocess.check_output(['bash','-c', bashCommand])
    linesCPL = outputCPL.decode("utf-8").split('\n')[:-1]

    bashCommand = "grep 'Design Area' runs/ppa_{}/reports/*qor*".format(specStr)
    outputDA = subprocess.check_output(['bash','-c', bashCommand])
    linesDA = outputDA.decode("utf-8").split('\n')[:-1]

    bashCommand = "grep '100' runs/ppa_{}/reports/*power*".format(specStr)
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
        freq = int(f.findall(line)[0][1:-4])
        delay = float(cpl.findall(line)[0])
        area = float(da.findall(linesDA[i])[0])
        mod = mwm[0]
        width = int(mwm[1])

        power = p.findall(linesP[i])
        lpower = float(power[2])
        denergy = float(power[1])*delay

        oneSynth = [mod, width, freq, delay, area, lpower, denergy]
        allSynths += [oneSynth]

    return allSynths

def getVals(module, var, freq=None):
    allSynths = getData(mod=module)

    if (var == 'delay'):
        ind = 3 
        units = " (ns)"
    elif (var == 'area'):
        ind = 4
        units = " (sq microns)"
        scale = 2
    elif (var == 'lpower'):
        ind = 5
        units = " (nW)"
    elif (var == 'denergy'):
        ind = 6
        units = " (pJ)"
    else:
        error

    widths = []
    metric = []
    if (freq != None):
        for oneSynth in allSynths:
            if (oneSynth[2] == freq):
                widths += [oneSynth[1]]
                metric += [oneSynth[ind]]
    else:
        widths = [8, 16, 32, 64, 128]
        for w in widths:
            m = 10000 # large number to start
            for oneSynth in allSynths:
                if (oneSynth[1] == w):
                    if (oneSynth[3] < m): 
                        m = oneSynth[3]
                        met = oneSynth[ind]
            metric += [met]

    if ('flop' in module) & (var == 'area'):
        metric = [m/2 for m in metric] # since two flops in each module 
    return widths, metric, units

def writeCSV():
    allSynths = getData()
    file = open("ppaData.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Width', 'Target Freq', 'Delay', 'Area', 'L Power (nW)', 'D energy (mJ)'])

    for one in allSynths:
        writer.writerow(one)

    file.close()

def genLegend(fits, coefs, module, r2):

    coefsr = [str(round(c, 3)) for c in coefs]

    eq = ''
    ind = 0
    if 'c' in fits:
        eq += coefsr[ind]
        ind += 1
    if 'l' in fits:
        eq += " + " + coefsr[ind] + "*N"
        ind += 1
    if 's' in fits:
        eq += " + " + coefsr[ind] + "*N^2"
        ind += 1
    if 'g' in fits:
        eq += " + " + coefsr[ind] + "*log2(N)"
        ind += 1
    if 'n' in fits:
        eq += " + " + coefsr[ind] + "*Nlog2(N)"
        ind += 1

    legend_elements = [lines.Line2D([0], [0], color='orange', label=eq),
                       lines.Line2D([0], [0], color='steelblue', ls='', marker='o', label=' R^2='+ str(round(r2, 4)))]
    return legend_elements

def oneMetricPlot(module, var, freq=None, ax=None, fits='clsgn'):
    '''
    module: string module name
    freq: int freq (MHz)
    var: string delay, area, lpower, or denergy
    fits: constant, linear, square, log2, Nlog2
    plots chosen variable vs width for all matching syntheses with regression
    '''
    widths, metric, units = getVals(module, var, freq=freq)
    coefs, r2, funcArr = regress(widths, metric, fits)

    xp = np.linspace(8, 140, 200)
    pred = []
    for x in xp:
        y = [func(x) for func in funcArr]
        pred += [sum(np.multiply(coefs, y))]

    if ax is None:
        singlePlot = True
        ax = plt.gca()
    else:
        singlePlot = False

    ax.scatter(widths, metric)
    ax.plot(xp, pred, color='orange')

    legend_elements = genLegend(fits, coefs, module, r2)
    ax.legend(handles=legend_elements)

    ax.set_xticks(widths)
    ax.set_xlabel("Width (bits)")
    ax.set_ylabel(str.title(var) + units)

    if singlePlot:
        ax.set_title(module + "  (target  " + str(freq) + "MHz)")
        plt.show()

def regress(widths, var, fits='clsgn'):

    funcArr = genFuncs(fits)

    mat = []
    for w in widths:
        row = []
        for func in funcArr:
            row += [func(w)]
        mat += [row]
    
    y = np.array(var, dtype=np.float)
    coefsResid = np.linalg.lstsq(mat, y, rcond=None)
    coefs = coefsResid[0]
    try:
        resid = coefsResid[1][0]
    except:
        resid = 0
    r2 = 1 - resid / (y.size * y.var())
    return coefs, r2, funcArr

def makeCoefTable():
    file = open("ppaFitting.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Metric', 'Freq', '1', 'N', 'N^2', 'log2(N)', 'Nlog2(N)', 'R^2'])

    for mod in ['add', 'mult', 'comparator', 'shifter']:
        for comb in [['delay', 5000], ['area', 5000], ['area', 10]]:
            var = comb[0]
            freq = comb[1]
            widths, metric, units = getVals(mod, freq, var)
            coefs, r2, funcArr = regress(widths, metric)
            row = [mod] + comb + np.ndarray.tolist(coefs) + [r2]
            writer.writerow(row)

    file.close()

def genFuncs(fits='clsgn'):
    funcArr = []
    if 'c' in fits:
        funcArr += [lambda x: 1]
    if 'l' in fits:
        funcArr += [lambda x: x]
    if 's' in fits:
        funcArr += [lambda x: x**2]
    if 'g' in fits:
        funcArr += [lambda x: np.log2(x)]
    if 'n' in fits:
        funcArr += [lambda x: x*np.log2(x)]
    return funcArr

def noOutliers(freqs, delays, areas):
    f=[]
    d=[]
    a=[]
    try:
        med = statistics.median(freqs)
        for i in range(len(freqs)):
            norm = freqs[i]/med
            if (norm > 0.25) & (norm<1.75):
                f += [freqs[i]]
                d += [delays[i]]
                a += [areas[i]]
    except: pass
    
    return f, d, a

def freqPlot(mod, width):
    allSynths = getData(mod=mod, width=width)

    freqsV, delaysV, areasV, freqsA, delaysA, areasA = ([] for i in range(6))
    for oneSynth in allSynths:
        if (mod == oneSynth[0]) & (width == oneSynth[1]):
            if (1000/oneSynth[3] < oneSynth[2]):
                freqsV += [oneSynth[2]]
                delaysV += [oneSynth[3]]
                areasV += [oneSynth[4]]
            else:
                freqsA += [oneSynth[2]]
                delaysA += [oneSynth[3]]
                areasA += [oneSynth[4]]

    if ('flop' in mod): # since two flops in each module 
        areasA = [m/2 for m in areasA] 
        areasV = [m/2 for m in areasV]

    freqsA, delaysA, areasA = noOutliers(freqsA, delaysA, areasA)
    freqsV, delaysV, areasV = noOutliers(freqsV, delaysV, areasV)

    adprodA, adprodV = adprodpow(areasA, delaysA, areasV, delaysV, 1)
    adpowA, adpowV = adprodpow(areasA, delaysA, areasV, delaysV, 2)


    legend_elements = [lines.Line2D([0], [0], color='green', ls='', marker='o', label='timing achieved'),
                       lines.Line2D([0], [0], color='blue', ls='', marker='o', label='slack violated')]

    f, (ax1, ax2, ax3, ax4) = plt.subplots(4, 1, sharex=True)
    ax1.scatter(freqsA, delaysA, color='green')
    ax1.scatter(freqsV, delaysV, color='blue')
    ax2.scatter(freqsA, areasA, color='green')
    ax2.scatter(freqsV, areasV, color='blue')
    ax3.scatter(freqsA, adprodA, color='green')
    ax3.scatter(freqsV, adprodV, color='blue')
    ax4.scatter(freqsA, adpowA, color='green')
    ax4.scatter(freqsV, adpowV, color='blue')
    ax1.legend(handles=legend_elements)
    ax4.set_xlabel("Target Freq (MHz)")
    ax1.set_ylabel('Delay (ns)')
    ax2.set_ylabel('Area (sq microns)')
    ax3.set_ylabel('Area * Delay')
    ax4.set_ylabel('Area * Delay^2')
    ax1.set_title(mod + '_' + str(width))
    plt.show()

def adprodpow(areasA, delaysA, areasV, delaysV, pow):
    resultA = []
    resultV = []

    for i in range(len(areasA)):
        resultA += [(areasA[i])*(delaysA[i])**pow]
    for i in range(len(areasV)):
        resultV += [(areasV[i])*(delaysV[i])**pow]
    
    return resultA, resultV

def plotPPA(mod, freq=None):
    fig, axs = plt.subplots(2, 2)
    oneMetricPlot(mod, 'delay', ax=axs[0,0], fits='clg', freq=freq)
    oneMetricPlot(mod, 'area', ax=axs[0,1], fits='s', freq=freq)
    oneMetricPlot(mod, 'lpower', ax=axs[1,0], fits='c', freq=freq)
    oneMetricPlot(mod, 'denergy', ax=axs[1,1], fits='s', freq=freq)
    titleStr = "  (target  " + str(freq)+ "MHz)" if freq != None else " (min delay)"
    plt.suptitle(mod + titleStr)
    plt.show()


# plotPPA('alu')
# writeCSV()
# look at comparaotro 32
# for x in ['add', 'mult', 'comparator']:
#     for y in [16, 32, 64, 128]:
#         freqPlot(x, y)

freqPlot('flop', 8)

# plotPPA('alu')