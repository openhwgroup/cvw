#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 5/22

from operator import index
import subprocess
import csv
import re
from matplotlib.cbook import flatten
import matplotlib.pyplot as plt
import matplotlib.lines as lines
import matplotlib.axes as axes
import numpy as np
from collections import namedtuple


def synthsfromcsv(filename):
    Synth = namedtuple("Synth", "module tech width freq delay area lpower denergy")
    with open(filename, newline='') as csvfile:
        csvreader = csv.reader(csvfile)
        global allSynths
        allSynths = list(csvreader)
        for i in range(len(allSynths)):
            for j in range(len(allSynths[0])):
                try: allSynths[i][j] = int(allSynths[i][j])
                except: 
                    try: allSynths[i][j] = float(allSynths[i][j])
                    except: pass
            allSynths[i] = Synth(*allSynths[i])
    
def synthsintocsv():
    ''' writes a CSV with one line for every available synthesis
        each line contains the module, tech, width, target freq, and resulting metrics
    '''
    print("This takes a moment...")
    bashCommand = "find . -path '*runs/ppa*rv32e*' -prune"
    output = subprocess.check_output(['bash','-c', bashCommand])
    allSynths = output.decode("utf-8").split('\n')[:-1]

    specReg = re.compile('[a-zA-Z0-9]+')
    metricReg = re.compile('\d+\.\d+[e]?[-+]?\d*')

    file = open("ppaData.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Tech', 'Width', 'Target Freq', 'Delay', 'Area', 'L Power (nW)', 'D energy (mJ)'])

    for oneSynth in allSynths:
        module, width, risc, tech, freq = specReg.findall(oneSynth)[2:7]
        tech = tech[:-2]
        metrics = []
        for phrase in [['Path Length', 'qor'], ['Design Area', 'qor'], ['100', 'power']]:
            bashCommand = 'grep "{}" '+ oneSynth[2:]+'/reports/*{}*'
            bashCommand = bashCommand.format(*phrase)
            try: output = subprocess.check_output(['bash','-c', bashCommand])
            except: print("At least one synth run doesn't have reports, try cleanup() first")
            nums = metricReg.findall(str(output))
            nums = [float(m) for m in nums]
            metrics += nums
        delay = metrics[0]
        area = metrics[1]
        lpower = metrics[4]
        denergy = (metrics[2] + metrics[3])*delay # (switching + internal powers)*delay

        writer.writerow([module, tech, width, freq, delay, area, lpower, denergy])
    file.close()

def cleanup():
    ''' removes runs that didn't work
    '''
    bashCommand = 'grep -r "Error" runs/ppa*/reports/*qor*'
    try: 
        output = subprocess.check_output(['bash','-c', bashCommand])
        allSynths = output.decode("utf-8").split('\n')[:-1]
        for run in allSynths:
            run = run.split('MHz')[0]
            bc = 'rm -r '+ run + '*'
            output = subprocess.check_output(['bash','-c', bc])
    except: pass

    bashCommand = "find . -path '*runs/ppa*rv32e*' -prune"
    output = subprocess.check_output(['bash','-c', bashCommand])
    allSynths = output.decode("utf-8").split('\n')[:-1]
    for oneSynth in allSynths:
        for phrase in [['Path Length', 'qor'], ['Design Area', 'qor'], ['100', 'power']]:
            bashCommand = 'grep "{}" '+ oneSynth[2:]+'/reports/*{}*'
            bashCommand = bashCommand.format(*phrase)
            try: output = subprocess.check_output(['bash','-c', bashCommand])
            except: 
                bc = 'rm -r '+ oneSynth[2:]
                try: output = subprocess.check_output(['bash','-c', bc])
                except: pass
    print("All cleaned up!")

def getVals(tech, module, var, freq=None):
    ''' for a specified tech, module, and variable/metric
        returns a list of values for that metric in ascending width order
        works at a specified target frequency or if none is given, uses the synthesis with the best achievable delay for each width
    '''

    global widths
    metric = []
    widthL = []

    if (freq != None):
        for oneSynth in allSynths:
            if (oneSynth.freq == freq) & (oneSynth.tech == tech) & (oneSynth.module == module):
                widthL += [oneSynth.width]
                osdict = oneSynth._asdict()
                metric += [osdict[var]]
        metric = [x for _, x in sorted(zip(widthL, metric))] # ordering
    else:
        for w in widths:
            m = 100000 # large number to start
            for oneSynth in allSynths:
                if (oneSynth.width == w) & (oneSynth.tech == tech) & (oneSynth.module == module):
                    if (oneSynth.delay < m) & (1000/oneSynth.delay > oneSynth.freq): 
                        m = oneSynth.delay
                        osdict = oneSynth._asdict()
                        met = osdict[var]
            try: metric += [met]
            except: pass

    if ('flop' in module) & (var == 'area'):
        metric = [m/2 for m in metric] # since two flops in each module 
    if (var == 'denergy'):
        metric = [m*1000 for m in metric] # more practical units for regression coefs

    return metric

def genLegend(fits, coefs, r2, spec):
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

    legend_elements = [lines.Line2D([0], [0], color=spec.color, label=eq),
                       lines.Line2D([0], [0], color=spec.color, ls='', marker=spec.shape, label=spec.tech +'  $R^2$='+ str(round(r2, 4)))]
    return legend_elements

def oneMetricPlot(module, var, freq=None, ax=None, fits='clsgn', norm=True):
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
    global techSpecs
    global widths

    global norms

    for spec in techSpecs:
        metric = getVals(spec.tech, module, var, freq=freq)
        
        if norm:
            techdict = spec._asdict()
            norm = techdict[var]
            metric = [m/norm for m in metric] # comment out to not normalize

        if len(metric) == 5:
            xp, pred, leg = regress(widths, metric, spec, fits)
            fullLeg += leg

            ax.scatter(widths, metric, color=spec.color, marker=spec.shape)
            ax.plot(xp, pred, color=spec.color)

    ax.legend(handles=fullLeg)

    ax.set_xticks(widths)
    ax.set_xlabel("Width (bits)")

    if norm:
        ylabeldic = {"lpower": "Normalized Leakage Power", "denergy": "Normalized Dynamic Energy", "area": "INVx1 Areas", "delay": "FO4 Delays"}
    else:
        ylabeldic = {"lpower": "Leakage Power (nW)", "denergy": "Dynamic Energy (nJ-CHECK)", "area": "Area (sq microns)", "delay": "Delay (ns)"}

    ax.set_ylabel(ylabeldic[var])

    if singlePlot:
        titleStr = "  (target  " + str(freq)+ "MHz)" if freq != None else " (best achievable delay)"
        ax.set_title(module + titleStr)
        plt.show()

def regress(widths, var, spec, fits='clsgn'):
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

    leg = genLegend(fits, coefs, r2, spec)

    return xp, pred, leg

def makeCoefTable(tech):
    ''' not currently in use, may salvage later
        writes CSV with each line containing the coefficients for a regression fit 
        to a particular combination of module, metric, and target frequency
    '''
    file = open("ppaFitting.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Module', 'Metric', 'Freq', '1', 'N', 'N^2', 'log2(N)', 'Nlog2(N)', 'R^2'])

    for mod in ['add', 'mult', 'comparator', 'shifter']:
        for comb in [['delay', 5000], ['area', 5000], ['area', 10]]:
            var = comb[0]
            freq = comb[1]
            metric = getVals(tech, mod, freq, var)
            global widths
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
    ind = delays.index(min(delays))
    med = freqs[ind]
    for i in range(len(freqs)):
        norm = freqs[i]/med
        if (norm > 0.25) & (norm<1.75):
            f += [freqs[i]]
            d += [delays[i]]
            a += [areas[i]]
    
    return f, d, a

def freqPlot(tech, mod, width):
    ''' plots delay, area, area*delay, and area*delay^2 for syntheses with specified tech, module, width
    '''
    global allSynths
    freqsL, delaysL, areasL = ([[], []] for i in range(3))
    for oneSynth in allSynths:
        if (mod == oneSynth.module) & (width == oneSynth.width) & (tech == oneSynth.tech):
            ind = (1000/oneSynth.delay < oneSynth.freq) # when delay is within target clock period
            freqsL[ind] += [oneSynth.freq]
            delaysL[ind] += [oneSynth.delay]
            areasL[ind] += [oneSynth.area]

    f, (ax1, ax2, ax3, ax4) = plt.subplots(4, 1, sharex=True)

    for ind in [0,1]:
        areas = areasL[ind]
        delays = delaysL[ind]
        freqs = freqsL[ind]

        if ('flop' in mod): areas = [m/2 for m in areas] # since two flops in each module
        freqs, delays, areas = noOutliers(freqs, delays, areas) # comment out to see all syntheses

        c = 'blue' if ind else 'green'
        adprod = adprodpow(areas, delays, 1)
        adpow = adprodpow(areas, delays, 2)
        ax1.scatter(freqs, delays, color=c)
        ax2.scatter(freqs, areas, color=c)
        ax3.scatter(freqs, adprod, color=c)
        ax4.scatter(freqs, adpow, color=c)

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

def squareAreaDelay(tech, mod, width):
    ''' plots delay, area, area*delay, and area*delay^2 for syntheses with specified tech, module, width
    '''
    global allSynths
    freqsL, delaysL, areasL = ([[], []] for i in range(3))
    for oneSynth in allSynths:
        if (mod == oneSynth.module) & (width == oneSynth.width) & (tech == oneSynth.tech):
            ind = (1000/oneSynth.delay < oneSynth.freq) # when delay is within target clock period
            freqsL[ind] += [oneSynth.freq]
            delaysL[ind] += [oneSynth.delay]
            areasL[ind] += [oneSynth.area]

    f, (ax1) = plt.subplots(1, 1)
    ax2 = ax1.twinx()

    for ind in [0,1]:
        areas = areasL[ind]
        delays = delaysL[ind]
        targets = freqsL[ind]
        targets = [1000/f for f in targets]
        
        if ('flop' in mod): areas = [m/2 for m in areas] # since two flops in each module
        targets, delays, areas = noOutliers(targets, delays, areas) # comment out to see all 
        
        if not ind:
            achievedDelays = delays

        c = 'blue' if ind else 'green'
        ax1.scatter(targets, delays, marker='^', color=c)
        ax2.scatter(targets, areas, marker='s', color=c)
    
    bestAchieved = min(achievedDelays)
        
    legend_elements = [lines.Line2D([0], [0], color='green', ls='', marker='^', label='delay (timing achieved)'),
                       lines.Line2D([0], [0], color='green', ls='', marker='s', label='area (timing achieved)'),
                       lines.Line2D([0], [0], color='blue', ls='', marker='^', label='delay (timing violated)'),
                       lines.Line2D([0], [0], color='blue', ls='', marker='s', label='area (timing violated)')]

    ax2.legend(handles=legend_elements, loc='upper left')
    
    ax1.set_xlabel("Delay Targeted (ns)")
    ax1.set_ylabel("Delay Achieved (ns)")
    ax2.set_ylabel('Area (sq microns)')
    ax1.set_title(mod + '_' + str(width))

    squarify(f)

    xvals = np.array(ax1.get_xlim())
    frac = (min(flatten(delaysL))-xvals[0])/(xvals[1]-xvals[0])
    areaLowerLim = min(flatten(areasL))-100
    areaUpperLim = max(flatten(areasL))/frac + areaLowerLim
    ax2.set_ylim([areaLowerLim, areaUpperLim])
    ax1.plot(xvals, xvals, ls="--", c=".3")
    ax1.hlines(y=bestAchieved, xmin=xvals[0], xmax=xvals[1], color="black", ls='--')

    plt.show()

def squarify(fig):
    ''' helper function for squareAreaDelay()
        forces matplotlib figure to be a square
    '''
    w, h = fig.get_size_inches()
    if w > h:
        t = fig.subplotpars.top
        b = fig.subplotpars.bottom
        axs = h*(t-b)
        l = (1.-axs/w)/2
        fig.subplots_adjust(left=l, right=1-l)
    else:
        t = fig.subplotpars.right
        b = fig.subplotpars.left
        axs = w*(t-b)
        l = (1.-axs/h)/2
        fig.subplots_adjust(bottom=l, top=1-l)

def adprodpow(areas, delays, pow):
    ''' for each value in [areas] returns area*delay^pow
        helper function for freqPlot'''
    result = []

    for i in range(len(areas)):
        result += [(areas[i])*(delays[i])**pow]
    
    return result

def plotPPA(mod, freq=None, norm=True):
    ''' for the module specified, plots width vs delay, area, leakage power, and dynamic energy with fits
        if no freq specified, uses the synthesis with best achievable delay for each width
        overlays data from both techs
    '''
    fig, axs = plt.subplots(2, 2)
    global fitDict
    modFit = fitDict[mod]
    oneMetricPlot(mod, 'delay', ax=axs[0,0], fits=modFit[0], freq=freq, norm=norm)
    oneMetricPlot(mod, 'area', ax=axs[0,1], fits=modFit[1], freq=freq, norm=norm)
    oneMetricPlot(mod, 'lpower', ax=axs[1,0], fits=modFit[1], freq=freq, norm=norm)
    oneMetricPlot(mod, 'denergy', ax=axs[1,1], fits=modFit[1], freq=freq, norm=norm)
    titleStr = "  (target  " + str(freq)+ "MHz)" if freq != None else " (best achievable delay)"
    plt.suptitle(mod + titleStr)
    plt.show()
    
if __name__ == '__main__':

    # set up stuff, global variables
    widths = [8, 16, 32, 64, 128]
    # fitDict in progress
    fitDict = {'add': ['cg', 'cl'], 'mult': ['clg', 's'], 'comparator': ['clsgn', 'clsgn'], 'csa': ['clsgn', 'clsgn'], 'shiftleft': ['clsgn', 'clsgn'], 'flop': ['cl', 'cl'], 'priorityencoder': ['clsgn', 'clsgn']}
    TechSpec = namedtuple("TechSpec", "tech color shape delay area lpower denergy")
    techSpecs = [['sky90', 'green', 'o', 43.2e-3, 1.96, 1.98, 1], ['gf32', 'purple', 's', 15e-3, .351, .3116, 1], ['tsmc28', 'blue', '^', 12.2e-3, .252, 1.09, 1]]
    techSpecs = [TechSpec(*t) for t in techSpecs]

    # cleanup()
    # synthsintocsv() # slow, run only when new synth runs to add to csv
  
    synthsfromcsv('ppaData.csv') # your csv here!

    ### examples
    # for mod in ['comparator', 'priorityencoder', 'shiftleft']:
    #     for w in [16, 32]:
    #         freqPlot('sky90', mod, w) # the weird ones
    # squareAreaDelay('sky90', 'add', 32)
    # oneMetricPlot('add', 'delay')
    for mod in ['add', 'csa', 'mult', 'comparator', 'priorityencoder', 'shiftleft', 'flop']:
        plotPPA(mod, norm=False) # no norm input now defaults to normalized