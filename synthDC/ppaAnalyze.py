#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 5/22

from distutils.log import error
from operator import index
from statistics import median
import subprocess
import statistics
import csv
import re
import matplotlib.pyplot as plt
import matplotlib.lines as lines
import numpy as np


def getData(tech, mod=None, width=None):
    ''' returns a list of lists 
        each list contains results of one synthesis that matches the input specs
    '''
    specStr = ''
    if mod != None:
        specStr = mod
        if width != None:
            specStr += ('_'+str(width))
    specStr += '*{}*'.format(tech)

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

def getVals(tech, module, var, freq=None):
    ''' for a specified tech, module, and variable/metric
        returns a list of widths and the corresponding values for that metric with the appropriate units
        works at a specified target frequency or if none is given, uses the synthesis with the min delay for each width
    '''

    allSynths = getData(tech, mod=module)

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

def writeCSV(tech):
    ''' writes a CSV with one line for every available synthesis for a specified tech
        each line contains the module, width, target freq, and resulting metrics
    '''
    allSynths = getData(tech)
    file = open("ppaData.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Width', 'Target Freq', 'Delay', 'Area', 'L Power (nW)', 'D energy (mJ)'])

    for one in allSynths:
        writer.writerow(one)

    file.close()

def genLegend(fits, coefs, r2, tech):
    ''' generates a list of two legend elements 
        labels line with fit equation and dots with tech and r squared of the fit
    '''

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

    c = 'blue' if (tech == 'sky90') else 'green'
    legend_elements = [lines.Line2D([0], [0], color=c, label=eq),
                       lines.Line2D([0], [0], color=c, ls='', marker='o', label=tech +'  $R^2$='+ str(round(r2, 4)))]
    return legend_elements

def oneMetricPlot(module, var, freq=None, ax=None, fits='clsgn'):
    ''' module: string module name
        freq: int freq (MHz)
        var: string delay, area, lpower, or denergy
        fits: constant, linear, square, log2, Nlog2
        plots given variable vs width for all matching syntheses with regression
    '''

    if ax is None:
        singlePlot = True
        ax = plt.gca()
    else:
        singlePlot = False

    fullLeg = []
    for tech in ['sky90', 'tsmc28']:
        c = 'blue' if (tech == 'sky90') else 'green'
        widths, metric, units = getVals(tech, module, var, freq=freq)
        xp, pred, leg = regress(widths, metric, tech, fits)
        fullLeg += leg

        ax.scatter(widths, metric, color=c)
        ax.plot(xp, pred, color=c)

    ax.legend(handles=fullLeg)

    ax.set_xticks(widths)
    ax.set_xlabel("Width (bits)")
    ax.set_ylabel(str.title(var) + units)

    if singlePlot:
        ax.set_title(module + "  (target  " + str(freq) + "MHz)")
        plt.show()

def regress(widths, var, tech, fits='clsgn'):
    ''' fits a curve to the given points
        returns lists of x and y values to plot that curve and legend elements with the equation
    '''

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

    xp = np.linspace(8, 140, 200)
    pred = []
    for x in xp:
        n = [func(x) for func in funcArr]
        pred += [sum(np.multiply(coefs, n))]

    leg = genLegend(fits, coefs, r2, tech)

    return xp, pred, leg

def makeCoefTable(tech):
    ''' writes CSV with each line containing the coefficients for a regression fit 
        to a particular combination of module, metric, and target frequency
    '''
    file = open("ppaFitting.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Metric', 'Freq', '1', 'N', 'N^2', 'log2(N)', 'Nlog2(N)', 'R^2'])

    for mod in ['add', 'mult', 'comparator', 'shifter']:
        for comb in [['delay', 5000], ['area', 5000], ['area', 10]]:
            var = comb[0]
            freq = comb[1]
            widths, metric, units = getVals(tech, mod, freq, var)
            coefs, r2, funcArr = regress(widths, metric)
            row = [mod] + comb + np.ndarray.tolist(coefs) + [r2]
            writer.writerow(row)

    file.close()

def genFuncs(fits='clsgn'):
    ''' helper function for regress()
        returns array of functions with one for each term desired in the regression fit
    '''
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
    ''' returns a pared down list of freqs, delays, and areas 
        cuts out any syntheses in which target freq isn't within 75% of the min delay target to focus on interesting area
        helper function to freqPlot()
    '''
    f=[]
    d=[]
    a=[]
    
    try:
        ind = delays.index(min(delays))
        med = freqs[ind]
        for i in range(len(freqs)):
            norm = freqs[i]/med
            if (norm > 0.25) & (norm<1.75):
                f += [freqs[i]]
                d += [delays[i]]
                a += [areas[i]]
    except: pass
    
    return f, d, a

def freqPlot(tech, mod, width):
    ''' plots delay, area, area*delay, and area*delay^2 for syntheses with specified tech, module, width
    '''
    allSynths = getData(tech, mod=mod, width=width)

    freqsL, delaysL, areasL = ([[], []] for i in range(3))
    for oneSynth in allSynths:
        if (mod == oneSynth[0]) & (width == oneSynth[1]):
            ind = (1000/oneSynth[3] < oneSynth[2]) # when delay is within target clock period
            freqsL[ind] += [oneSynth[2]]
            delaysL[ind] += [oneSynth[3]]
            areasL[ind] += [oneSynth[4]]

    f, (ax1, ax2, ax3, ax4, ax5) = plt.subplots(5, 1, sharex=True)

    for ind in [0,1]:
        areas = areasL[ind]
        delays = delaysL[ind]
        freqs = freqsL[ind]

        if ('flop' in mod): areas = [m/2 for m in areas] # since two flops in each module
        freqs, delays, areas = noOutliers(freqs, delays, areas)

        c = 'blue' if ind else 'green'
        adprod = adprodpow(areas, delays, 2)
        adpow = adprodpow(areas, delays, 3)
        adpow2 = adprodpow(areas, delays, 4)
        ax1.scatter(freqs, delays, color=c)
        ax2.scatter(freqs, areas, color=c)
        ax3.scatter(freqs, adprod, color=c)
        ax4.scatter(freqs, adpow, color=c)
        ax5.scatter(freqs, adpow2, color=c)

    legend_elements = [lines.Line2D([0], [0], color='green', ls='', marker='o', label='timing achieved'),
                       lines.Line2D([0], [0], color='blue', ls='', marker='o', label='slack violated')]

    ax1.legend(handles=legend_elements)
    
    ax4.set_xlabel("Target Freq (MHz)")
    ax1.set_ylabel('Delay (ns)')
    ax2.set_ylabel('Area (sq microns)')
    ax3.set_ylabel('Area * Delay')
    ax4.set_ylabel('Area * $Delay^2$')
    ax1.set_title(mod + '_' + str(width))
    plt.show()

def adprodpow(areas, delays, pow):
    ''' for each value in [areas] returns area*delay^pow
        helper function for freqPlot'''
    result = []

    for i in range(len(areas)):
        result += [(areas[i])*(delays[i])**pow]
    
    return result

def plotPPA(mod, freq=None):
    ''' for the module specified, plots width vs delay, area, leakage power, and dynamic energy with fits
        if no freq specified, uses the synthesis with min delay for each width
        overlays data from both techs
    '''
    fig, axs = plt.subplots(2, 2)
    oneMetricPlot(mod, 'delay', ax=axs[0,0], fits='clg', freq=freq)
    oneMetricPlot(mod, 'area', ax=axs[0,1], fits='s', freq=freq)
    oneMetricPlot(mod, 'lpower', ax=axs[1,0], fits='c', freq=freq)
    oneMetricPlot(mod, 'denergy', ax=axs[1,1], fits='s', freq=freq)
    titleStr = "  (target  " + str(freq)+ "MHz)" if freq != None else " (min delay)"
    plt.suptitle(mod + titleStr)
    plt.show()


# writeCSV()

# look at comparaotro 32

# for x in ['add', 'mult', 'comparator', 'alu', 'csa']:
#     for y in [8, 16, 32, 64, 128]:
#         freqPlot('sky90', x, y)

freqPlot('sky90', 'mult', 32)