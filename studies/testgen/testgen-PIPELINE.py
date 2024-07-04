#!/usr/bin/env python3
###################################################################################################
# testgen-PIPELINE.py
#
# Shriya Nadgauda: snadgauda@hmc.edu & Ethan Falicov: efalicov@hmc.edu
# Created: Feb 2, 2021
#
# Generate random assembly code for RISC-V Processor Design Validation.
###################################################################################################

# Many Functions Based On: https://github.com/wallento/riscv-python-model (MIT License)


###################################################################################################
# Libraries
###################################################################################################
from random import seed
from random import randint
from enum import Enum
import numpy as np

import re

from datetime import datetime

MEMSTART = 'testdata'
###################################################################################################
# Main Body
###################################################################################################

class InvalidImmediateValueException(Exception):
    pass

class InvalidRegisterNumberException(Exception):
    pass

class InvalidRegisterValueException(Exception):
    pass

class WriteToImmutableRegisterException(Exception):
    pass

class ReadFromUninitializedMemoryException(Exception):
    pass

class InvalidMemoryWriteLocation(Exception):
    pass

def zeroExtend(inputBits, resultNumBits):
    numDigitsToAppend = resultNumBits - len(inputBits)
    newBits = inputBits
    if numDigitsToAppend > 0:
        newBits = ('0' * numDigitsToAppend) + inputBits
    return newBits

def oneExtend(inputBits, resultNumBits):
    numDigitsToAppend = resultNumBits - len(inputBits)
    newBits = inputBits
    if numDigitsToAppend > 0:
        newBits = ('1' * numDigitsToAppend) + inputBits
    return newBits

def signExtend(inputBits, resultNumBits):
    if inputBits[0] == '1':
        return oneExtend(inputBits = inputBits, resultNumBits = resultNumBits)
    return zeroExtend(inputBits = inputBits, resultNumBits = resultNumBits)

def binToDec(inputBits):
    if inputBits[0] == '0':
        return int(inputBits, 2)
    
    numBits = len(inputBits)
    twoCompMask = (1 << (numBits - 1)) - 1
    msbMask = (1 << (numBits -1))
    
    return int((-1 * (msbMask * int(inputBits[0], 2))) + (twoCompMask & int(inputBits, 2)))

def randBinary(signed, numBits, valueAlignment):
    # use this for corners: xlen = 32 here
    # corners = [0, 1, 2, 0xFF, 0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
    # 2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1]
    # when not biased don't gen numbers from (|2^(n-2) to 2^(n-2)|)
    biased = np.random.randint(0, 3) # on 2 generate random edge case
    returnVal = 0
    sign = 0
    if biased < 2:
        # print("unbiased")
        if not(signed):
            returnVal = np.random.randint(0, 2**(numBits - 2))

        else:    
            returnVal = np.random.randint(-2**(numBits - 2), 2**(numBits - 2))
    
    else:
        # print("corner")
        if not(signed):
            returnVal = np.random.randint(2**(numBits - 2)+1, 2**(numBits - 1)-2)

        else:    
            sign = np.random.randint(0, 2) # 0 is pos, 1 is neg
            if sign:
                returnVal = np.random.randint(2**(numBits - 2)+1, 2**(numBits - 1)-2)
            else:
                returnVal = np.random.randint(-2**(numBits - 1), -2**(numBits - 2)-1)

    binReturnVal = bin(returnVal) #remove "0b"
    if returnVal >= 0:
        binReturnVal = binReturnVal[2:]

        #make binary correct length
        while(len(binReturnVal) < numBits):
            binReturnVal = "0" + binReturnVal
    else:
        binReturnVal = binReturnVal[3:]
        #two's compliment
        flipped = ''.join('1' if x == '0' else '0' for x in binReturnVal)
        added = bin(int(flipped, 2) + 1)[2:]

        while(len(added) < len(flipped)):
            added = "0" + added
        while(len(added) < numBits):
            added = "1" + added
        
        binReturnVal = added

    # ensure correct value assignment
    if valueAlignment == 1:
        return binReturnVal
    
    indexVal = valueAlignment // 2
    returnValue = binReturnVal[:-indexVal] + "0"*indexVal 
    return returnValue

def randHex(sign, numBits, divisibleByValue):
    val = hex(int(randBinary(sign, numBits*4, divisibleByValue), 2))
    return val

def randDec(valueRangeMin, valueRangeMax, divisibleByValue):
    valRange = (valueRangeMax - valueRangeMin)//divisibleByValue   
    return (np.random.randint(0, valRange + 1) * divisibleByValue + valueRangeMin)

class Label:
    def __init__(self, name, pcValue):
        self.name = name
        self.pcValue = pcValue

class Immediate:
    def __init__(self, xlen, numBits = None, signed = 1):
        self.xlen = int(xlen)
        if numBits == None:
            numBits = self.xlen
        self.numBits = int(numBits)
        self.signed = signed
        self.bits = '0'*self.numBits
        self.twoCompMask = (1 << (self.numBits - 1)) - 1
        self.msbMask = (1 << (self.numBits -1))

        self.value = self.getDecValue()
    
        self.maxValue = self.getMaxValue()
        self.minValue = self.getMinValue()

    def getDecValue(self):
        if self.signed == 1:
            return self.getValueSigned()
        return self.getValueUnsigned()

    def getMaxValue(self):
        if self.signed == 1:
            return ((2**(self.numBits - 1)) - 1)
        return ((2**self.numBits) - 1) 

    def getMinValue(self):
        if self.signed == 1:
            return (-1 * 2**(self.numBits - 1))
        return 0

    def signExtend(self, inputBits = None):
        if inputBits == None:
            inputBits = self.bits

        return signExtend(inputBits, self.numBits)

    def oneExtend(self, inputBits = None):
        if inputBits == None:
            inputBits = self.bits

        return oneExtend(inputBits, self.numBits)

    def zeroExtend(self, inputBits = None):
        if inputBits == None:
            inputBits = self.bits

        return zeroExtend(inputBits, self.numBits)

    def setValue(self, newValue, signed = None):
        if signed != None:
            self.signed = signed
        self.maxValue = self.getMaxValue()
        self.minValue = self.getMinValue()

        if newValue > self.maxValue:
            errStr = 'Attempted: {}, Max: {}'.format(newValue, self.maxValue)
            raise InvalidImmediateValueException(errStr)
            newValue = self.maxValue

        elif newValue < self.minValue:
            errStr = 'Attempted: {}, Min: {}'.format(newValue, self.minValue)
            raise InvalidImmediateValueException(errStr)
            newValue = self.minValue
        
        self.value = newValue

        bitValue = ''
        if (self.signed == 1) and (newValue < 0):
            bitValue = bin(self.value)[3:] # Remove the -0b
            flipped = ''.join('1' if x == '0' else '0' for x in bitValue)
            bitValue = bin(int(flipped, 2) + 1)[2:]

            if len(bitValue) < len(flipped): # Correction for removing sig figs
                bitValue = '0'*(len(flipped)-len(bitValue)) + bitValue

            bitValue = self.oneExtend(bitValue)
        elif self.signed == 1 and newValue >= 0:
            bitValue = bin(self.value)[2:] # Remove the 0b
            bitValue = self.zeroExtend(bitValue)
        else:
            bitValue = bitValue = bin(self.value)[2:] # Remove the 0b
            bitValue = self.zeroExtend(bitValue)
        
        self.bits = bitValue

    def setBits(self, newBits, signed = None):
        if signed != None:
            self.signed = signed

        if len(newBits) != self.numBits:
            errStr = 'Attempted to write {} bits into {} bit immediate'.format(len(newBits), self.numBits)
            raise InvalidImmediateValueException(errStr)
        
        self.bits = newBits
        self.value = self.getDecValue()
        
    def randomize(self, signed = None, minVal = None, maxVal = None, granularity = None):
        if signed != None: 
            self.signed = signed
        self.maxValue = self.getMaxValue()
        self.minValue = self.getMinValue()

        if minVal == None:
            minVal = self.minValue
        if maxVal == None:
            maxVal = self.maxValue
        if granularity == None:
            granularity = GRANULARITY.BYTE
        
        granularityNum = 1
        if granularity == GRANULARITY.HALFWORD:
            granularityNum = self.xlen // 16
        elif granularity == GRANULARITY.WORD:
            granularityNum = self.xlen // 8 

        minVal = int(np.ceil(minVal / granularityNum) * granularityNum)
        maxVal = int(np.floor(maxVal / granularityNum) * granularityNum)

        
        valRange = (maxVal - minVal)//granularityNum
        randValue = randint(0, valRange) * granularityNum + minVal

        self.setValue(randValue, signed=self.signed)

    def getValueSigned(self):
        if self.bits[0] == '0':
            return int(self.bits, 2)
        else:
            return int((-1 * (self.msbMask * int(self.bits[0], 2))) + (self.twoCompMask & int(self.bits, 2)))

    def getValueUnsigned(self):
        return int(self.bits, 2)

    def __str__(self):
        infoStr = ''
        if self.signed == 1:
            infoStr = 'Signed {} bit value: {}'.format(self.numBits, self.value)
        infoStr = 'Unsigned {} bit value: {}'.format(self.numBits, self.value)
        return 'Immediate bits {} ({})'.format(self.bits, infoStr)

    @classmethod
    def randImm12(cls, xlen, signed = 1):
        imm = cls(xlen = xlen, numBits = 12, signed = signed)
        imm.randomize()
        return imm

    @classmethod
    def setImm12(cls, xlen, value, signed = 1):
        imm = cls(xlen = xlen, numBits = 12, signed = signed)
        imm.setValue(newValue = value)
        return imm

    @classmethod
    def setImm20(cls, xlen, value, signed = 1):
        imm = cls(xlen = xlen, numBits = 20, signed = signed)
        imm.setValue(newValue = value, signed=1)
        return imm

    @classmethod
    def randZImm5(cls, xlen, signed = 0):
        imm = cls(xlen = xlen, numBits = 5, signed = signed)
        imm.randomize()
        return imm

    @classmethod
    def randImm13(cls, xlen, signed = 1):
        imm = cls(xlen = xlen, numBits = 13, signed = signed)
        imm.randomize()
        return imm

    @classmethod
    def randImm20(cls, xlen, signed = 1):
        imm = cls(xlen = xlen, numBits = 20, signed = signed)
        imm.randomize()
        return imm
       
class Register:
    def __init__(self, xlen, signed = 1):
        self.xlen = int(xlen)
        self.numBits = self.xlen
        self.signed = signed
        self.bits = '0'*self.numBits
        self.twoCompMask = (1 << (self.numBits - 1)) - 1
        self.msbMask = (1 << (self.numBits -1))

        self.value = self.getDecValue()
        self.immutable = False
        self.regName = None
    
        self.maxValue = self.getMaxValue()
        self.minValue = self.getMinValue()
    
    def getRegName(self):
        return self.regName
        
    def setRegName(self, newName):
        self.regName = newName

    def setImmutable(self, immutable):
        self.immutable = immutable    

    def getDecValue(self):
        if self.signed == 1:
            return self.getValueSigned()
        return self.getValueUnsigned()

    def getMaxValue(self):
        if self.signed == 1:
            return (2**(self.numBits - 1) - 1)
        return (2**(self.numBits) - 1) 

    def getMinValue(self):
        if self.signed == 1:
            return (-1 * 2**(self.numBits - 1))
        return 0

    def signExtend(self, inputBits = None):
        if inputBits == None:
            inputBits = self.bits

        return signExtend(inputBits, self.numBits)

    def oneExtend(self, inputBits = None):
        if inputBits == None:
            inputBits = self.bits

        return oneExtend(inputBits, self.numBits)

    def zeroExtend(self, inputBits = None):
        if inputBits == None:
            inputBits = self.bits

        return zeroExtend(inputBits, self.numBits)  

    def setValue(self, newValue, signed = None):
        if self.immutable:
            raise(WriteToImmutableRegisterException)
        else:
            if signed != None:
                self.signed = signed
            self.maxValue = self.getMaxValue()
            self.minValue = self.getMinValue()

            if newValue > self.maxValue:
                errStr = 'Attempted: {}, Max: {}'.format(newValue, self.maxValue)
                raise InvalidRegisterValueException(errStr)
                newValue = self.maxValue

            elif newValue < self.minValue:
                errStr = 'Attempted: {}, Min: {}'.format(newValue, self.minValue)
                raise InvalidRegisterValueException(errStr)
                newValue = self.minValue
            
            self.value = newValue

            bitValue = ''
            if signed == 1 and newValue < 0:
                bitValue = bin(self.value)[3:] # Remove the -0b
                flipped = ''.join('1' if x == '0' else '0' for x in bitValue)
                bitValue = bin(int(flipped, 2) + 1)[2:]

                if len(bitValue) < len(flipped): # Correction for removing sig figs
                    bitValue = '0'*(len(flipped)-len(bitValue)) + bitValue

                bitValue = self.oneExtend(bitValue)
            elif signed == 1 and newValue >= 0:
                bitValue = bin(self.value)[2:] # Remove the 0b
                bitValue = self.zeroExtend(bitValue)
            else:
                bitValue = bitValue = bin(self.value)[2:] # Remove the 0b
                bitValue = self.zeroExtend(bitValue)
            
            self.bits = bitValue

    def setBits(self, newBits, signed = None):
        if self.immutable:
            raise(WriteToImmutableRegisterException)
        else:
            if signed != None:
                self.signed = signed

            if len(newBits) != self.numBits:
                errStr = 'Attempted to write {} bits into {} bit register'.format(len(newBits), self.numBits)
                raise InvalidRegisterValueException(errStr)
            
            self.bits = newBits
            self.value = self.getDecValue()
        
    def randomize(self, signed = None, minVal = None, maxVal = None, granularity = None):
        if self.immutable:
            raise(WriteToImmutableRegisterException)
        else:
            if signed != None: 
                self.signed = signed
            self.maxValue = self.getMaxValue()
            self.minValue = self.getMinValue()
            
            if minVal == None:
                minVal = self.minValue
            if maxVal == None:
                maxVal = self.maxValue
            if granularity == None:
                granularity = GRANULARITY.BYTE
            
            granularityNum = 1
            if granularity == GRANULARITY.HALFWORD:
                granularityNum = self.xlen // 16
            elif granularity == GRANULARITY.WORD:
                granularityNum = self.xlen // 8 

            minVal = int(np.ceil(minVal / granularityNum) * granularityNum)
            maxVal = int(np.floor(maxVal / granularityNum) * granularityNum)

            
            valRange = (maxVal - minVal)//granularityNum
            randValue = randint(0, valRange) * granularityNum + minVal
        
            self.setValue(randValue, signed=self.signed)
    
    def getValueSigned(self):
        if self.bits[0] == 0:
            return int(self.bits, 2)
        else:
            return int((-1 * (self.msbMask * int(self.bits[0], 2))) + (self.twoCompMask & int(self.bits, 2)))

    def getValueUnsigned(self):
        return int(self.bits, 2)

    def __str__(self):
        infoStr = ''
        if self.signed == 1:
            infoStr += 'Signed'
        else:
            infoStr += 'Unsigned'

        if self.immutable == True:
            infoStr += ' Immutable'
        
            
        return('Register {} bits: {} ({} value: {})'.format(self.regName, self.bits, infoStr, self.value))

    def __add__(self, other):
        self.setValue(self.value + int(other))
        return self

    @classmethod 
    def immutableRegister(cls, xlen, value, signed = 1):
        reg = cls(xlen = xlen)
        reg.setValue(newValue = value, signed = signed)
        reg.setImmutable(immutable = True)
        return reg

class RegFile():
    def __init__(self, xlen, numRegs = 32, immutableRegsDict = {0 : 0}, prefix = 'x'):
        self.xlen = xlen
        self.numRegs = numRegs
        self.regs = []
        self.immutableRegsList = []
        self.prefix = prefix

        for i in range(0, numRegs):
            self.regs.append(Register(xlen))
            self.regs[-1].setRegName('{}{}'.format(prefix, i))
            

        for immutableRegKey, immutableRegVal in immutableRegsDict.items():
            self.regs[immutableRegKey].setValue(newValue = immutableRegVal, signed = 1)
            self.immutableRegsList.append(immutableRegKey)
                
    def getRandReg(self):
        reg = randint(1, len(self.regs)-1)
        while(reg in self.immutableRegsList):
            reg = randint(1, len(self.regs)-1)
        return self.regs[reg]
    
    # def getRandMemReg(self):
    #     reg = randint(1, len(self.memoryreg)-1)
    #     while(reg in self.immutableRegsList):
    #         reg = randint(1, len(self.memoryreg)-1)
    #     return str(reg)

    def randomize(self):
        for regNum in range(0, self.numRegs):
            if regNum not in self.immutableRegsList:
                self.regs[regNum].randomize()
    
    def setRegValue(self, regNum, newValue, signed = None):
        if regNum in self.immutableRegsList:
            errStr = 'Write to x{} not allowed'.format(regNum)
            raise WriteToImmutableRegisterException(errStr)
        if regNum > self.numRegs - 1:
            errStr = 'Write to x{} exceeds number of registers: {}'.format(regNum, self.numRegs)
            raise InvalidRegisterNumberException(errStr)


        self.regs[regNum].setValue(newValue = newValue, signed = signed)

    def setRegBits(self, regNum, newBits, signed = None):
        if regNum in self.immutableRegsList:
            errStr = 'Write to x{} not allowed'.format(regNum)
            raise WriteToImmutableRegisterException(errStr)

        if regNum > self.numRegs - 1:
            errStr = 'Write to x{} exceeds number of registers: {}'.format(regNum, self.numRegs)
            raise InvalidRegisterNumberException(errStr)

        self.regs[regNum].setBits(newBits = newBits, signed = signed)
        
    def __str__(self):
        formattedString = ''
        for x in range(0, len(self.regs)):
            formattedString += 'x{}:\t{}\n'.format(str(x), str(self.regs[x]))
        return formattedString

class Memory():
    def __init__(self, xlen):
        self.memDict = {} #keys: strings, values: binary strings
        self.xlen = int(xlen)
        self.minVal = 0
        self.maxVal = 2047
    def populateMemory(self, memDict):
        # add all values of memDict to self.memDict
        # overwrites any values that already exist 
        for key in memDict.keys():
            self.memDict[key] = memDict[key]

    def updateMemory(self, addr, granularity, value):
        # sign extend value to 32 bits
        if addr > self.maxVal:
            errStr = 'Tried to write to invalid memory location {} max {}'.format(value, self.maxVal)
            raise InvalidMemoryWriteLocation(errStr)
        exValue = signExtend(value, self.xlen)
        self.memDict[addr] = exValue

    def readMemory(self, addr, granularity):
        # check if memory is unitilaized 
        if addr not in self.memDict.keys():
            errStr = 'Tried to read from uninitialized address: {}'.format(addr)
            raise ReadFromUninitializedMemoryException(errStr)

        val = self.memDict[addr]
        if granularity == GRANULARITY.WORD:
            val = val
        elif granularity == GRANULARITY.HALFWORD:
            val = val[-(self.xlen//2):]
        else:
            val = val[-(self.xlen//4):]
        if val == "":
            return '0'
        return val
    
    def genRandMemoryValue(self):

        #generate a random value
        minVal = self.minVal
        maxVal = self.maxVal
        randValue = randint(0, self.maxVal + 1)

        # #convert to binary string
        # bitValue = ''
        # bitValue = bitValue = bin(randValue)[2:] # Remove the 0b
        # bitValue = signExtend(bitValue, self.xlen)
        
        return randValue

class Model():
    def __init__(self, xlen, numRegs, immutableRegsDict, initPc = 0):
        self.xlen = int(xlen)
        self.memory = Memory(xlen=self.xlen)
        self.regFile = RegFile(xlen=self.xlen, immutableRegsDict = immutableRegsDict)
        self.pc = Register(xlen=self.xlen, signed=0)
        self.pc.setValue(newValue=initPc)
        self.pc.setRegName(newName = 'PC')
        self.memStart = 0x8000400
        self.memoryImmediateCounter = 0
        self.resultImmediateCounter = 0
        self.totalStoreCount = 0
    
class TestGen():
    def __init__(self, numInstr, immutableRegsDict, instrSet, imperasPath):
        self.numInstr = numInstr
        self.instrSet = instrSet
        self.xlen = int((re.search(r'\d+', instrSet)).group())
        self.model = Model(xlen=self.xlen, numRegs=16, immutableRegsDict = immutableRegsDict)

        self.prevLabel = 0
        self.test_count = 0

        self.imperasPath = imperasPath + instrSet.lower() + '/'
        self.exportTestName = 'PIPELINE'
        if (self.numInstr == 100000):
            self.exportTestName += "-100K"
        elif (self.numInstr == 1000000):
            self.exportTestName += "-1M"
        self.basename = 'WALLY-'+ self.exportTestName
        self.fname = self.imperasPath + "src/" + self.basename + ".S"
        self.refname = self.imperasPath + "references/" + self.basename + ".reference_output"
        
    def genTestInstr(self, reg):
        imm = Immediate.setImm12(xlen = self.xlen, value = self.model.resultImmediateCounter)
        reg6 = self.model.regFile.regs[6]
        out = [Instr.issue(model = self.model, instrName = "sw", rs2 = reg, imm = imm, rs1 = reg6)]
        self.model.resultImmediateCounter += 4
        if (self.model.resultImmediateCounter == 2040):
            # Reset
            imm2 = Immediate.setImm12(xlen = self.xlen, value = 2040)
            reg6.setImmutable(False)
            wreset = Instr.issue(model = self.model, instrName = "addi", rd = reg6, imm = imm2, rs1 = reg6) 
            reg6.setImmutable(True)
            self.model.resultImmediateCounter = 0
            out.append(wreset)     
        out.append('\n')
        self.model.totalStoreCount += 1       
        return out

    def branchInstruction(self, instr):
        # get field and granularity of instruction

        # randomly determine forward or back branch direction
        fwd = np.random.randint(0, 2) #fwd on 1, bwd on 0
        taken = np.random.randint(0,2) #not taken on 0, taken on 1

        # pick 2 registers for branch comparison
        reg1 = self.model.regFile.getRandReg()
        reg2 = reg1
        reg0 = self.model.regFile.regs[0]
        while(reg2 == reg1):
            reg2 = self.model.regFile.getRandReg()

        instructions = []
       
        
        if (fwd == 1):
            # set r1 and r2 to what they should be to do the branching we want
            if  (instr == "beq" and taken==1)   or (instr == "bne" and taken==0) or \
                (instr == "blt" and taken==0)   or (instr == "bge" and taken==1) or \
                (instr == "bltu" and taken==0)  or (instr == "bgeu" and taken==1): #r1 = r2
                newInstr = Instr.issue(model = self.model, instrName="add", rd = reg1, rs1  = reg2, rs2 = reg0)
                instructions.append(newInstr)

            elif (instr == "beq" and taken==0)   or (instr == "bne" and taken==1) or \
                (instr == "blt" and taken==1)   or (instr == "bltu" and taken==1): #r2 = r1 + 1
                imm = Immediate.setImm12(xlen = self.xlen, value = 1)
                newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                instructions.append(newInstr)

            else: #r2 = r1 - 1
                imm = Immediate.setImm12(xlen = self.xlen, value = -1)
                newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                instructions.append(newInstr)

            # add branching instruction
            label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
            branch = Instr.issue(model = self.model, instrName = instr, rs1 = reg2, rs2 = reg1, label = label, dir = 'f')
            instructions.append(branch)
            numInstr = np.random.randint(0, 6)
            # add random alu instructions after branching before branch point
            for i in range(0, numInstr):
                curr = "RAND ALU INSTRUCTION"
                rd = self.model.regFile.getRandReg()
                r1 = self.model.regFile.getRandReg()
                r2 = self.model.regFile.getRandReg()
                instr = "add"
                if (taken == 0):
                    instructions.append('add {}, {}, {}'.format(rd.getRegName(), r1.getRegName(), r2.getRegName()))
                else:
                    instructions.append(Instr.issue(model = self.model, instrName = instr, rd = rd, rs1 = r1, rs2 = r2))

            instructions.append(str(self.prevLabel) + ":")
            self.prevLabel += 1
            return instructions
        else:
            if (not taken):
                if instr == "beq":
                    randImm = np.random.randint(1, 10)
                    imm = Immediate.setImm12(xlen = self.xlen, value = randImm)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)

                elif instr == "bne":
                    imm = Immediate.setImm12(xlen = self.xlen, value = 0)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)
                
                elif instr == "bltu":
                    # deals with overflow
                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 2)
                    newInstr = Instr.issue(model = self.model, instrName="srli", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)

                    randImm = np.random.randint(1, 11)
                    imm = Immediate.setImm12(xlen = self.xlen, value = randImm)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)

                elif instr == "blt":
                    # deals with overflow
                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 2)
                    newInstr = Instr.issue(model = self.model, instrName="srli", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)

                    randImm = np.random.randint(1, 11)
                    imm = Immediate.setImm12(xlen = self.xlen, value = randImm)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)

                elif instr == "bgeu":
                    # deals with overflow
                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 2)
                    newInstr = Instr.issue(model = self.model, instrName="srli", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)

                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 15)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)

                    randImm = np.random.randint(-10, 0)
                    imm = Immediate.setImm12(xlen = self.xlen, value = randImm)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)

                elif instr == "bge":
                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 15)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)

                    randImm = np.random.randint(-10, 0)
                    imm = Immediate.setImm12(xlen = self.xlen, value = randImm)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)

                label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
                instructions.append(str(self.prevLabel) + ":")
                numInstr = np.random.randint(0, 6)
                # add random alu instructions after branching before branch point
                for i in range(0, numInstr):
                    curr = "RAND ALU INSTRUCTION"
                    rd = self.model.regFile.getRandReg()
                    while(rd == reg2 or rd == reg1):
                        rd = self.model.regFile.getRandReg()
                    r1 = self.model.regFile.getRandReg()
                    r2 = self.model.regFile.getRandReg()
                    instrJunk = "add"
                    instructions.append('add {}, {}, {}'.format(rd.getRegName(), r1.getRegName(), r2.getRegName()))
                branch = Instr.issue(model = self.model, instrName = instr, rs1 = reg2, rs2 = reg1, label = label, dir = 'b')
                instructions.append(branch)  
            else:
                #setup reg instructions before any branching stuff
                if instr == "beq": 
                    numTimesRepeat = 1 #can only be repeated once with the way we are doing this
                    imm = Immediate.setImm12(xlen = self.xlen, value = numTimesRepeat)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)
                    
                    label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
                    instructions.append(str(self.prevLabel) + ":")

                    imm = Immediate.setImm12(xlen = self.xlen, value = -1)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg2, imm = imm)
                    instructions.append(newInstr)

                elif instr == "bne":
                    numTimesRepeat = np.random.randint(2, 6) 
                    imm = Immediate.setImm12(xlen = self.xlen, value = numTimesRepeat)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)
                    
                    label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
                    instructions.append(str(self.prevLabel) + ":")

                    imm = Immediate.setImm12(xlen = self.xlen, value = -1)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg2, imm = imm)
                    instructions.append(newInstr)
                
                elif instr == "bltu": 
                    numTimesRepeat = np.random.randint(2, 6)*(-1)
                    # deals with overflow
                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 2)
                    newInstr = Instr.issue(model = self.model, instrName="srli", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)

                    imm = Immediate.setImm12(xlen = self.xlen, value = numTimesRepeat)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)
                    
                    label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
                    instructions.append(str(self.prevLabel) + ":")

                    imm = Immediate.setImm12(xlen = self.xlen, value = 1)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg2, imm = imm)
                    instructions.append(newInstr)
                
                elif instr == "blt":
                    # deals with overflow
                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 2)
                    newInstr = Instr.issue(model = self.model, instrName="srli", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)
                    
                    numTimesRepeat = np.random.randint(2, 6)*(-1)
                    imm = Immediate.setImm12(xlen = self.xlen, value = numTimesRepeat)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)
                    
                    label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
                    instructions.append(str(self.prevLabel) + ":")

                    imm = Immediate.setImm12(xlen = self.xlen, value = 1)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg2, imm = imm)
                    instructions.append(newInstr)

                elif instr == "bgeu":
                    numTimesRepeat = np.random.randint(2, 6)
                    imm = Immediate.setImm12(xlen = self.xlen, value = numTimesRepeat)
                    
                    # deals with overflow
                    imm1 = Immediate.setImm12(xlen = self.xlen, value = 2)
                    newInstr1 = Instr.issue(model = self.model, instrName="srli", rd = reg1, rs1  = reg1, imm = imm1)
                    instructions.append(newInstr1)

                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 15)
                    newInstr2 = Instr.issue(model = self.model, instrName="addi", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr2)

                    newInstr3 = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr3)
                    
                    label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
                    instructions.append(str(self.prevLabel) + ":")

                    imm = Immediate.setImm12(xlen = self.xlen, value = -1)
                    newInstr4 = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg2, imm = imm)
                    instructions.append(newInstr4)

                elif instr == "bge":
                    imm2 = Immediate.setImm12(xlen = self.xlen, value = 15)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg1, rs1  = reg1, imm = imm2)
                    instructions.append(newInstr)
                    
                    numTimesRepeat = np.random.randint(2, 6)
                    imm = Immediate.setImm12(xlen = self.xlen, value = numTimesRepeat)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg1, imm = imm)
                    instructions.append(newInstr)
                    
                    label = Label(name = self.prevLabel, pcValue = self.model.pc.getValueUnsigned())
                    instructions.append(str(self.prevLabel) + ":")

                    imm = Immediate.setImm12(xlen = self.xlen, value = -1)
                    newInstr = Instr.issue(model = self.model, instrName="addi", rd = reg2, rs1  = reg2, imm = imm)
                    instructions.append(newInstr)

                numInstr = np.random.randint(0, 5)
                for i in range(0, numInstr):
                    curr = "RAND ALU INSTRUCTION"
                    rd = self.model.regFile.getRandReg()
                    while(rd == reg2) or (rd == reg1):
                        rd = self.model.regFile.getRandReg()
                    r1 = self.model.regFile.getRandReg()
                    r2 = self.model.regFile.getRandReg()
                    instrJunk = "add"
                    instructions.append(Instr.issue(model = self.model, instrName = instrJunk, rd = rd, rs1 = r1, rs2 = r2))

                branch = Instr.issue(model = self.model, instrName = instr, rs1 = reg2, rs2 = reg1, label = label, dir = 'b')
                instructions.append(branch) 
            self.prevLabel += 1
        return instructions


    def getForwardingInstructions(self, instr):
        ld_instr = instr
        divBy = 1 
        
        granularity = None
        if (instr == "lw"):
            granularity = GRANULARITY.WORD
        elif (instr == "lh") | (instr == 'lhu'):
            divBy = self.xlen//2
            granularity = GRANULARITY.HALFWORD
        else:
            divBy = self.xlen//4
            granularity =  GRANULARITY.BYTE

        instructions = []
        
        rd = self.model.regFile.getRandReg()
        reg1 = self.model.regFile.regs[7]

        memVal = self.model.memoryImmediateCounter
        self.model.memoryImmediateCounter += 4
        if instr == "ld":
            if ((memVal + reg1.getValueUnsigned()) % 8) != 0:
                memVal -= 4
                self.model.memoryImmediateCounter -= 4 # we haven't read from a new location

        
        
        if (self.model.memoryImmediateCounter == 2040):
            self.model.memoryImmediateCounter = 0
            immMem = Immediate.setImm12(xlen = self.model.xlen, value = 2040)
            instructions.append(Instr.issue(model = self.model, instrName = "addi" , rd = reg1, rs1 = reg1, imm = immMem))


        imm1 = Immediate.setImm12(xlen = self.model.xlen, value = memVal)

        reg2 = self.model.regFile.getRandReg()
        instructions.append(Instr.issue(model = self.model, instrName = "sw" , rs2 = reg2, rs1 = reg1, imm = imm1))
    
        
        while (rd == reg1):
            rd = self.model.regFile.getRandReg()
        instructions.append(Instr.issue(model = self.model, instrName = ld_instr, rd = rd, rs1 = reg1, imm = imm1))
        
        return instructions

    def jumpInstruction(self, instr):
        # fields, alignment = self.instrDict.instr[instr]
        granularity = GRANULARITY.BYTE
        divBy = 1

        # randomly determine forward or back branch direction
        fwd = np.random.randint(0, 2) #fwd on 1, bwd on 0
        taken = np.random.randint(0,2) #not taken on 0, taken on 1

        reg_pc = self.model.regFile.getRandReg()
        instructions = []

        label1 = Label(name = 1, pcValue = self.model.pc.getValueUnsigned())
        label2 = Label(name = 2, pcValue = self.model.pc.getValueUnsigned())
        label3 = Label(name = 3, pcValue = self.model.pc.getValueUnsigned())

        if fwd == 1:
            newInstr = Instr.issue(model = self.model, instrName=instr, rd = reg_pc, label = label1, dir = "f")  
            instructions.append(newInstr)
            
            numInstr = np.random.randint(0, 6)
            # add random alu instructions after jumping before jump point
            reg_check = self.model.regFile.getRandReg()
            for i in range(0, numInstr):
                rd = self.model.regFile.getRandReg()
                while (rd == reg_pc):
                    rd = self.model.regFile.getRandReg()
                reg_check = rd
                r1 = self.model.regFile.getRandReg()
                r2 = self.model.regFile.getRandReg()
                instructions.append(Instr.issue(model = self.model, instrName = "and", rd = rd, rs1 = r1, rs2 = r2))
            instructions.append("1:")
            self.model.pc += 4

            # #make sure jump was taken
            check_instr = self.genTestInstr(reg_check)
            for check in check_instr:
                instructions.append(check)

            # #check value in pc + 4 reg
            check_instr = self.genTestInstr(reg_pc)
            for check in check_instr:
                instructions.append(check)
        else:
            reg1 = self.model.regFile.getRandReg()
            reg2 = self.model.regFile.getRandReg()
            while reg2 == reg1:
                reg2 = self.model.regFile.getRandReg()
            
            newInstr = Instr.issue(model = self.model, instrName=instr, rd = reg1, label = label1, dir = "f")  
            instructions.append(newInstr)
            # instructions.append("jal x" + reg1 + ", 1f")
            
            instructions.append("2:")
            self.model.pc += 4
            newInstr = Instr.issue(model = self.model, instrName=instr, rd = reg2, label = label3, dir = "f")  
            instructions.append(newInstr)
            # instructions.append("jal x" + reg2 + ", 3f")
            
            instructions.append("1:")
            self.model.pc += 4

            numInstr = np.random.randint(0,6)
            for i in range(0, numInstr):
                rd = self.model.regFile.getRandReg()
                r1 = self.model.regFile.getRandReg()
                r2 = self.model.regFile.getRandReg()
                instructions.append(Instr.issue(model = self.model, instrName = 'and', rd = rd, rs1 = r1, rs2 = r2))
            
            #test case here
            newInstr = Instr.issue(model = self.model, instrName=instr, rd = reg2, label = label2, dir = "b")  
            instructions.append(newInstr)
            # instructions.append("jal x" + reg2 + ", 2b")
            instructions.append("3:")
            self.model.pc += 4
            
            check_instr = self.genTestInstr(reg1)
            for check in check_instr:
                instructions.append(check)
            
                # jump to 1
                # #2
                #     jump to 3
                # #1
                #     junk here
                #     test: jump to 2
                # #3  
                #     check answer from 1
        return instructions


    def jumpRInstruction(self, instr):
        # fields, alignment = self.instrDict.instr[instr]
        granularity = GRANULARITY.BYTE
        divBy = 1

        # randomly determine forward or back branch direction
        fwd = np.random.randint(0, 2) #fwd on 1, bwd on 0

        reg_pc = self.model.regFile.getRandReg()
        instructions = []

        label1 = Label(name = 1, pcValue = self.model.pc.getValueUnsigned())
        label2 = Label(name = 2, pcValue = self.model.pc.getValueUnsigned())
        label3 = Label(name = 3, pcValue = self.model.pc.getValueUnsigned())

        if fwd == 1:
            numInstr = np.random.randint(0, 6)
            
            rs1 = self.model.regFile.getRandReg()
            while (rs1 == reg_pc):
                rs1 = self.model.regFile.getRandReg() 
                
            # TODO fix the value of rs1 - should be pc location of "1f"
            rs1.setValue(newValue = 0)
            
            imm = Immediate.setImm12(xlen = self.model.xlen, value = 0)
            
            instructions.append('la {}, {}'.format(rs1.regName , "1f"))
            self.model.pc += 8     

            newInstr = Instr.issue(model = self.model, instrName=instr, rd = reg_pc, rs1 = rs1, imm = imm)  
            instructions.append(newInstr)
            
            # add random alu instructions after jumping before jump point
            reg_check = self.model.regFile.getRandReg()
            for i in range(0, numInstr):
                rd = self.model.regFile.getRandReg()
                while (rd == reg_pc):
                    rd = self.model.regFile.getRandReg()
                reg_check = rd
                r1 = self.model.regFile.getRandReg()
                r2 = self.model.regFile.getRandReg()
                instructions.append(Instr.issue(model = self.model, instrName = "and", rd = rd, rs1 = r1, rs2 = r2))

            instructions.append("1:")
            self.model.pc += 4

            #make sure jump was taken
            check_instr = self.genTestInstr(reg_check)
            for check in check_instr:
                instructions.append(check)

            #check value in pc + 4 reg
            check_instr = self.genTestInstr(reg_pc)
            for check in check_instr:
                instructions.append(check)
        else:
            reg1 = self.model.regFile.getRandReg()
            reg2 = self.model.regFile.getRandReg()
            while reg2 == reg1:
                reg2 = self.model.regFile.getRandReg()
            
            jumpDestVal = self.model.pc.value + 4
            newInstr = Instr.issue(model = self.model, instrName='jal', rd = reg1, label = label1, dir = "f")  
            instructions.append(newInstr)
            # instructions.append("jal x" + reg1 + ", 1f")
            
            instructions.append("2:")
            self.model.pc += 4

            newInstr = Instr.issue(model = self.model, instrName='jal', rd = reg2, label = label3, dir = "f")  
            instructions.append(newInstr)
            # instructions.append("jal x" + reg2 + ", 3f")
            
            instructions.append("1:")
            self.model.pc += 4


            rs1 = self.model.regFile.getRandReg()
            while (rs1 == reg_pc):
                rs1 = self.model.regFile.getRandReg()
                
            imm = Immediate.setImm12(xlen = self.model.xlen, value = 0)
            
            
            instructions.append('la {}, {}'.format(rs1.regName ,"2b"))
            self.model.pc += 8

            
            rs1.setValue(newValue = 0) #TODO: this value is wrong, should be address of label
            imm = Immediate.setImm12(xlen = self.model.xlen, value = 0)


            numInstr = np.random.randint(0,6)
            for i in range(0, numInstr):
                rd = self.model.regFile.getRandReg()
                while(rd == rs1) or (rd == reg_pc):
                    rd = self.model.regFile.getRandReg()
                r1 = self.model.regFile.getRandReg()
                r2 = self.model.regFile.getRandReg()
                instructions.append(Instr.issue(model = self.model, instrName = 'and', rd = rd, rs1 = r1, rs2 = r2))
            
            #test case here
            newInstr = Instr.issue(model = self.model, instrName=instr, rd = reg_pc, rs1 = rs1, imm = imm)  
            instructions.append(newInstr)
            # instructions.append("jal x" + reg2 + ", 2b")
            instructions.append("3:")
            self.model.pc += 4
            
            check_instr = self.genTestInstr(reg1)
            for check in check_instr:
                instructions.append(check)
            
            check_instr = self.genTestInstr(reg_pc)
            for check in check_instr:
                instructions.append(check)
            
                # jump to 1
                # #2
                # jump to 3
                # #1
                # junk instructions
                # ...
                # ...
                # test instruction to 2
                # #3  
                # check answer from 1
        return instructions

    def generateASM(self, instrSet, instrTypes):
        generatedInstructions = []

        # for memLocation in self.model.memory.memDict.keys():
        #     memData = self.model.memory.readMemory(addr = memLocation, granularity = GRANULARITY.WORD)
        #     memDataVal = hex(int(memData, 2))
        #     generatedInstructions.append('li x2, MASK_XLEN({})'.format(memDataVal))
        #     self.model.pc += 8
        #     generatedInstructions.append('li x3, MASK_XLEN({})'.format(memLocation))
        #     self.model.pc += 8
        #     generatedInstructions.append('sw x2, 0(x3)')
        #     self.model.pc += 4

        generatedInstructions.append('la x7, test_data')
        self.model.pc += 8

        for reg in self.model.regFile.regs:
            if (int(reg.regName[-1:]) not in self.model.regFile.immutableRegsList) :
                immHex = randHex(False, 5, 1)
                imm = int(immHex, 16)
                reg.setValue(imm)
                generatedInstructions.append('li {}, MASK_XLEN({})'.format(reg.getRegName(), immHex))
                self.model.pc += 8
            elif (reg == self.model.regFile.regs[0]):
                immHex = 0
                imm = 0
                reg.setValue(imm)
                generatedInstructions.append('li {}, MASK_XLEN({})'.format(reg.getRegName(), immHex))
                self.model.pc += 8
            elif (reg == self.model.regFile.regs[6]):
                # immHex = 0
                # imm = 0
                # reg.setValue(imm)
                # generatedInstructions.append('la {}, {}'.format(reg.getRegName(), "test_1_res"))
                # self.model.pc += 8
                pass
        for i in range(0, self.numInstr):
            # decide which instruction to issue
            randInstr = instrSet[randint(0, len(instrSet)-1)]

            randNum = randint(0, 2)
            if randInstr in InstrTypes['B']:
                newInstr = self.branchInstruction(instr = randInstr)
                for i in newInstr:
                    generatedInstructions.append(i)
            elif randInstr in InstrTypes['J']:
                newInstr = self.jumpInstruction(instr = randInstr)
                for i in newInstr:
                    generatedInstructions.append(i)
            elif randInstr[0] == 'l' and randNum == 0 and randInstr != "lui":
                newInstr = self.getForwardingInstructions(instr = randInstr)
                for i in newInstr:
                    generatedInstructions.append(i)
            else:
                if randInstr in InstrTypes['R']:
                    rd = self.model.regFile.getRandReg()
                    rs1 = self.model.regFile.getRandReg()
                    rs2 = self.model.regFile.getRandReg()
                    instr = Instr.issue(model = self.model, instrName = randInstr, rd = rd, rs1 = rs1, rs2 = rs2)
                    generatedInstructions.append(instr)

                    testInstrs = self.genTestInstr(rd)
                    for testInstr in testInstrs:
                        generatedInstructions.append(testInstr)

                elif randInstr in InstrTypes['I']:
                    if randInstr == "jalr":
                        newInstr = self.jumpRInstruction(instr = randInstr)
                        for i in newInstr:
                            generatedInstructions.append(i)
                    # memory instruction
                    elif randInstr[0] == 'l': 
                        rs1 = self.model.regFile.regs[7]

                        memLocation = list(self.model.memory.memDict.keys())[randint(0, len(self.model.memory.memDict.keys()) -1)]
                        if randInstr == "ld":
                            if ((memLocation + rs1.getValueUnsigned()) % 8) != 0:
                                if (memLocation != 0):
                                    memLocation -=4
                                else:
                                    memLocation = 4

                        rd = self.model.regFile.getRandReg()
                        
                        imm12 = Immediate.setImm12(xlen = self.model.xlen, value = memLocation)
                        instr = Instr.issue(model = self.model, instrName = randInstr, rd = rd, rs1 = rs1, imm = imm12)
                        generatedInstructions.append(instr)

                        testInstrs = self.genTestInstr(rd)
                        for testInstr in testInstrs:
                            generatedInstructions.append(testInstr)
                    else:
                        rd = self.model.regFile.getRandReg()
                        rs1 = self.model.regFile.getRandReg()
                        imm12 = Immediate.randImm12(xlen = self.model.xlen)

                        instr = Instr.issue(model = self.model, instrName = randInstr, rd = rd, rs1 = rs1, imm = imm12)
                        generatedInstructions.append(instr)

                        testInstrs = self.genTestInstr(rd)
                        for testInstr in testInstrs:
                            generatedInstructions.append(testInstr)

                elif randInstr in InstrTypes['S']:
                    rs1 = self.model.regFile.regs[7]

                    immValue = self.model.memoryImmediateCounter
                    self.model.memoryImmediateCounter += 4
                    if randInstr == 'Sd':
                        if ((immValue + rs1.getValueUnsigned()) % 8) != 0:
                            immValue -= 4
                            self.model.memoryImmediateCounter -= 4 #haven't put a value in a new mem locatoin
                    
                    rs2 = self.model.regFile.getRandReg()
                    

                    immMem = Immediate.setImm12(xlen = self.model.xlen, value = 2040)
                    if (self.model.memoryImmediateCounter == 2040):
                        self.model.memoryImmediateCounter = 0
                        generatedInstructions.append(Instr.issue(model = self.model, instrName = "addi" , rd = rs1, rs1 = rs1, imm = immMem))

                    imm12 = Immediate.setImm12(xlen = self.model.xlen, value = immValue)
                    instr = Instr.issue(model = self.model, instrName = randInstr, rs1 = rs1, rs2 = rs2, imm = imm12)
                    generatedInstructions.append(instr)

                elif randInstr in InstrTypes['U']:
                    rd = self.model.regFile.getRandReg()
                    imm20 = Immediate.randImm20(xlen = self.model.xlen, signed = 0)
                    instr = Instr.issue(model = self.model, instrName = randInstr, rd = rd, imm = imm20)
                    generatedInstructions.append(instr)

                    testInstrs = self.genTestInstr(rd)
                    for testInstr in testInstrs:
                        generatedInstructions.append(testInstr)

                elif randInstr in InstrTypes['R4']:
                    continue
                else:
                    # INVALID INSTR
                    print(randInstr)
                    print("You made a typo")
        return generatedInstructions    

    def exportASM(self, instrSet, instrTypes):
        asmFile = open(self.fname, 'w')
        refFile = open(self.refname, 'w')
        
        # Custom Header
        line = "///////////////////////////////////////////\n"
        asmFile.write(line)
        line ="// "+self.fname+ "\n// " + "Ethan Falicov & Shriya Nadgauda" + "\n"
        asmFile.write(line)
        line ="// Created " + str(datetime.now())  + "\n" + "\n"
        asmFile.write(line)
        line = "// Begin Tests" + "\n"
        asmFile.write(line)

        # Generic Header
        headerFile = open("testgen_header.S", "r")
        for line in headerFile:  
            asmFile.write(line)
        asmFile.write("\n")


        # Write Instructions
        generatedInstructions = self.generateASM(instrSet = INSTRSETS[instrSet], instrTypes = instrType)
        for generatedInstr in generatedInstructions:
            asmFile.write("\t" + generatedInstr + "\n")
            if ("RVTEST_IO_ASSERT_GPR_EQ" in generatedInstr):
                asmFile.write("\n")

        # Footer
        footerFile = open("testgen_footer.S", "r")
        lineNum = 0
        for line in footerFile:  
            asmFile.write(line)
            if lineNum  == 14:
                asmFile.write('test_data:\n')
                memList = list(self.model.memory.memDict.keys())
                memList.sort()
                paddingSize = 0
                for memLoc in memList:
                    hexVal = int(self.model.memory.memDict[memLoc],2)
                    hexDigitSize = self.model.xlen / 4
                    formattedStr = '0x{0:0{1}x}'.format(hexVal, hexDigitSize)
                    if self.model.xlen == 64:
                        asmFile.write('\t.dword {}\n'.format(formattedStr))
                    else:
                        asmFile.write('\t.word {}\n'.format(formattedStr))
            lineNum += 1
        
        asmFile.write("\n")
        line = "\t.fill " + str(self.model.totalStoreCount) + ", " + str(self.xlen//8) + ", -1\n"
        asmFile.write(line)
        asmFile.write("\n")
        
        line = "\nRV_COMPLIANCE_DATA_END\n" 
        asmFile.write(line)
        
        asmFile.close()
        refFile.close()

class Instr():
    @classmethod
    def issue(self, model, instrName, **kwargs):
        funcName = 'Instr_' + str(instrName)
        return getattr(Instr, funcName)(model = model, **kwargs)
 
    @classmethod
    def Instr_label(self, model, label = None):
        label.pcValue = model.pc.value
        model.pc += 4
        return '{}:'.format(label.name)

    ###############################################################################################
    # RV32I Instructions
    ###############################################################################################
    @classmethod
    def Instr_lb(self, model, rd = None, rs1 = None, imm = None):  
        addr = imm.getDecValue()
        rd.setBits(newBits = signExtend(model.memory.readMemory(addr = addr, granularity = GRANULARITY.BYTE), \
            resultNumBits = model.xlen))
        model.pc += 4
        return 'lb {}, {}({})'.format(rd.getRegName(), imm.getDecValue(), rs1.getRegName())
        
    @classmethod
    def Instr_lh(self, model, rd = None, rs1 = None, imm = None):
        addr = imm.getDecValue()
        rd.setBits(newBits = signExtend(model.memory.readMemory(addr = addr, granularity = GRANULARITY.HALFWORD), \
            resultNumBits = model.xlen))
        model.pc += 4
        return 'lh {}, {}({})'.format(rd.getRegName(), imm.getDecValue(), rs1.getRegName())
    
    @classmethod
    def Instr_lw(self, model, rd = None, rs1 = None, imm = None):
        addr = imm.getDecValue()
        rd.setBits(newBits = signExtend(model.memory.readMemory(addr = addr, granularity = GRANULARITY.WORD), \
            resultNumBits = model.xlen))
        model.pc += 4
        return 'lw {}, {}({})'.format(rd.getRegName(), imm.getDecValue(), rs1.getRegName())

    @classmethod
    def Instr_lbu(self, model, rd = None, rs1 = None, imm = None):
        addr = imm.getDecValue()
        rd.setBits(newBits = zeroExtend(model.memory.readMemory(addr = addr, granularity = GRANULARITY.BYTE), \
            resultNumBits = model.xlen))
        model.pc += 4
        return 'lbu {}, {}({})'.format(rd.getRegName(), imm.getDecValue(), rs1.getRegName())
        
    @classmethod
    def Instr_lhu(self, model, rd = None, rs1 = None, imm = None):
        addr = imm.getDecValue()
        rd.setBits(newBits = zeroExtend(model.memory.readMemory(addr = addr, granularity = GRANULARITY.HALFWORD), \
            resultNumBits = model.xlen))
        model.pc += 4
        return 'lhu {}, {}({})'.format(rd.getRegName(), imm.getDecValue(), rs1.getRegName())

    @classmethod
    def Instr_addi(self, model, rd = None, rs1 = None, imm = None):
        newValue = rs1.getDecValue() + imm.getDecValue()
        newValueBin = 0
        if newValue > 0:
            newValueBin = bin(newValue)[2:]
        elif newValue == 0:
            newValueBin = "0" * model.xlen
        else:
            newValueBin = bin(newValue)[3:]
        newValueBinTrunk = newValueBin[-model.xlen:]
        rd.setBits(newBits = signExtend(inputBits = newValueBinTrunk, resultNumBits = model.xlen), signed = 1)
        model.pc += 4
        return 'addi {}, {}, MASK_XLEN({})'.format(rd.getRegName(), rs1.getRegName(), imm.getDecValue())
        
    @classmethod
    def Instr_slli(self, model, rd = None, rs1 = None, imm = None):
        bits = rs1.bits
        immBits = imm.bits[-5:]
        immShift = int(immBits, 2)
        shifted = bits[-(len(bits) - immShift):]
        shiftedExt = binToDec(inputBits = shifted + '0'*(model.xlen - len(shifted)))
        rd.setValue(newValue = shiftedExt, signed = 1)
        model.pc += 4
        return 'slli {}, {}, 0b{}'.format(rd.getRegName(), rs1.getRegName(), immBits)

    @classmethod
    def Instr_slti(self, model, rd = None, rs1 = None, imm = None):
        if (rs1.getValueSigned() < imm.getValueSigned()):
            rd.setValue(newValue = 1, signed = 1)
        else:
            rd.setValue(newValue = 0, signed = 1)
        model.pc += 4
        return 'slti {}, {}, SEXT_IMM({})'.format(rd.getRegName(), rs1.getRegName(), imm.getDecValue())

    @classmethod
    def Instr_sltiu(self, model, rd = None, rs1 = None, imm = None):
        if (rs1.getValueUnsigned() < imm.getValueUnsigned()):
            rd.setValue(newValue = 1, signed = 1)
        else:
            rd.setValue(newValue = 0, signed = 1)
        model.pc += 4
        return 'slti {}, {}, SEXT_IMM({})'.format(rd.getRegName(),rs1.getRegName(), imm.getDecValue())

    @classmethod
    def Instr_xori(self, model, rd = None, rs1 = None, imm = None):
        newValue = rs1.getDecValue() ^ imm.getDecValue()
        rd.setValue(newValue = newValue, signed = rs1.signed)
        model.pc += 4
        return 'xori {}, {}, SEXT_IMM({})'.format(rd.getRegName(), rs1.getRegName(), imm.getDecValue())

    @classmethod
    def Instr_srli(self, model, rd = None, rs1 = None, imm = None):
        bits = rs1.bits
        immBits = imm.bits[-5:]
        immShift = int(immBits, 2)
        shifted = bits[0:len(bits) - immShift]
        extShifted = zeroExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'srli {}, {}, 0b{}'.format(rd.getRegName(), rs1.getRegName(), immBits)

    @classmethod
    def Instr_srai(self, model, rd = None, rs1 = None, imm = None):
        bits = rs1.bits
        immBits = imm.bits[-5:]
        immShift = int(immBits, 2)
        shifted = bits[0:len(bits) - immShift]
        extShifted = signExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'srai {}, {}, 0b{}'.format(rd.getRegName(), rs1.getRegName(), immBits)

    @classmethod
    def Instr_ori(self, model, rd = None, rs1 = None, imm = None):
        rd.setValue(newValue = (rs1.getDecValue() | imm.getDecValue()), signed = rs1.signed)
        return 'ori {}, {}, SEXT_IMM({})'.format(rd.getRegName(), rs1.getRegName(), imm.getDecValue())

    @classmethod
    def Instr_andi(self, model, rd = None, rs1 = None, imm = None):
        rd.setValue(newValue = (rs1.getDecValue() & imm.getDecValue()), signed = rs1.signed)
        return 'andi {}, {}, SEXT_IMM({})'.format(rd.getRegName(), rs1.getRegName(), imm.getDecValue())

    @classmethod
    def Instr_auipc(self, model, rd = None, imm = None):
        rd.setValue(newValue = binToDec(inputBits = imm.bits[:-12] + '0'*12) + model.pc.getDecValue(), signed = 1)
        return 'auipc {}, MASK_XLEN({})'.format(rd.getRegName(), imm.getDecValue())

    @classmethod
    def Instr_sb(self, model, rs1 = None, rs2 = None, imm = None):
        addr = imm.getDecValue()
        if addr in model.memory.memDict.keys():
            originalMem = model.memory.readMemory(addr = addr, granularity = GRANULARITY.WORD)
            model.memory.updateMemory(addr = addr, value = originalMem[:-8] + rs2.bits[-8:], granularity = GRANULARITY.WORD)
        else:
            model.memory.updateMemory(addr = addr, value = '0'*(model.xlen - 8) + rs2.bits[-8:], granularity = GRANULARITY.WORD)
        model.pc += 4
        return 'sb {}, {}({})'.format(rs2.getRegName(), imm.getDecValue(), rs1.getRegName())

    @classmethod
    def Instr_sh(self, model, rs1 = None, rs2 = None, imm = None):
        addr = imm.getDecValue()
        if addr in model.memory.memDict.keys():
            originalMem = model.memory.readMemory(addr = addr, granularity = GRANULARITY.WORD)
            model.memory.updateMemory(addr = addr, value = originalMem[:-16] + rs2.bits[-16:], granularity = GRANULARITY.WORD)
        else:
            model.memory.updateMemory(addr = addr, value = '0'*(model.xlen - 16) + rs2.bits[-16:], granularity = GRANULARITY.WORD)
        model.pc += 4
        return 'sh {}, {}({})'.format(rs2.getRegName(), imm.getDecValue(), rs1.getRegName())

    @classmethod
    def Instr_sw(self, model, rs1 = None, rs2 = None, imm = None):
        addr = imm.getDecValue()
        model.memory.updateMemory(addr = addr, value = rs2.bits, granularity = GRANULARITY.WORD)
        model.pc += 4
        return 'sw {}, {}({})'.format(rs2.getRegName(), imm.getDecValue(), rs1.getRegName())

    @classmethod
    def Instr_add(self, model, rd = None, rs1 = None, rs2 = None):
        newValue = rs1.getDecValue() + rs2.getDecValue()
        newValueBin = 0
        if newValue > 0:
            newValueBin = bin(newValue)[2:]
        elif newValue == 0:
            newValueBin = "0" * model.xlen
        else:
            newValueBin = bin(newValue)[3:]
        newValueBinTrunk = newValueBin[-model.xlen:]
        rd.setBits(newBits = signExtend(inputBits = newValueBinTrunk, resultNumBits = model.xlen), signed = 1)
        model.pc += 4
        return 'add {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_sub(self, model, rd = None, rs1 = None, rs2 = None):
        newValue = rs1.getDecValue() - rs2.getDecValue()
        newValueBin = 0
        if newValue > 0:
            newValueBin = bin(newValue)[2:]
        elif newValue == 0:
            newValueBin = "0" * model.xlen
        else:
            newValueBin = bin(newValue)[3:]
        newValueBinTrunk = newValueBin[-model.xlen:]
        rd.setBits(newBits = signExtend(inputBits = newValueBinTrunk, resultNumBits = model.xlen), signed = 1)
        model.pc += 4
        return 'sub {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_sll(self, model, rd = None, rs1 = None, rs2 = None):
        bits = rs1.bits
        rs2Bin = rs2.bits[-5:]
        rs2Shift = int(rs2Bin,2)
        shifted = bits[-(len(bits) - rs2Shift):]
        shiftedExt = binToDec(inputBits = shifted + '0'*(model.xlen - len(shifted)))
        rd.setValue(newValue = shiftedExt, signed = 1)
        model.pc += 4
        return 'sll {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_slt(self, model, rd = None, rs1 = None, rs2 = None):
        if (rs1.getDecValue() < rs2.getDecValue()):
            rd.setValue(newValue = 1, signed = 1)
        else:
            rd.setValue(newValue = 0, signed = 1)
        model.pc += 4
        return 'slt {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())


    @classmethod
    def Instr_sltu(self, model, rd = None, rs1 = None, rs2 = None):
        if (rs1.getValueUnsigned() < rs2.getValueUnsigned()):
            rd.setValue(newValue = 1, signed = 1)
        else:
            rd.setValue(newValue = 0, signed = 1)
        model.pc += 4
        return 'sltu {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_xor(self, model, rd = None, rs1 = None, rs2 = None):
        rd.setValue(newValue = (rs1.getDecValue() ^ rs2.getDecValue()), signed = rs1.signed)
        model.pc += 4
        return 'xor {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_srl(self, model, rd = None, rs1 = None, rs2 = None):
        bits = rs1.bits
        rs2Bin = rs2.bits[-5:]
        rs2Shift = int(rs2Bin,2)
        shifted = bits[0:len(bits) - rs2Shift]
        extShifted = zeroExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'srl {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_sra(self, model, rd = None, rs1 = None, rs2 = None):
        bits = rs1.bits
        rs2Bin = rs2.bits[-5:]
        rs2Shift = int(rs2Bin,2)
        shifted = bits[0:len(bits) - rs2Shift]
        extShifted = signExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'sra {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_or(self, model, rd = None, rs1 = None, rs2 = None):
        rd.setValue(newValue = (rs1.getDecValue() | rs2.getDecValue()), signed = rs1.signed)
        model.pc += 4
        return 'or {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_and(self, model, rd = None, rs1 = None, rs2 = None):
        rd.setValue(newValue = (rs1.getDecValue() & rs2.getDecValue()), signed = rs1.signed)
        model.pc += 4
        return 'and {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_lui(self, model, rd = None, imm = None):
        rd.setValue(newValue = binToDec(inputBits = imm.bits[:20] + '0'*(model.xlen-20)) , signed = 1)
        model.pc += 4
        return 'lui {}, {}'.format(rd.getRegName(), imm.getDecValue())


    @classmethod
    def Instr_beq(self, model, rs1 = None, rs2 = None, label = None, dir = None):
        if (rs1.getValueSigned() == rs2.getValueSigned()):
            model.pc.setValue(label.pcValue)
        else:
            model.pc += 4
        return 'beq {}, {}, {}{}'.format(rs1.getRegName(), rs2.getRegName(), label.name, dir)

    @classmethod
    def Instr_bne(self, model, rs1 = None, rs2 = None, label = None, dir = None):
        if (rs1.getValueSigned() != rs2.getValueSigned()):
            model.pc.setValue(label.pcValue)
        else:
            model.pc += 4
        return 'bne {}, {}, {}{}'.format(rs1.getRegName(), rs2.getRegName(), label.name, dir)

    @classmethod
    def Instr_blt(self, model, rs1 = None, rs2 = None, label = None, dir = None):
        if (rs1.getValueSigned() < rs2.getValueSigned()):
            model.pc.setValue(label.pcValue)
        else:
            model.pc += 4
        return 'blt {}, {}, {}{}'.format(rs1.getRegName(), rs2.getRegName(), label.name, dir)

    @classmethod
    def Instr_bge(self, model, rs1 = None, rs2 = None, label = None, dir = None):
        if (rs1.getValueSigned() >= rs2.getValueSigned()):
            model.pc.setValue(label.pcValue)
        else:
            model.pc += 4
        return 'bge {}, {}, {}{}'.format(rs1.getRegName(), rs2.getRegName(), label.name, dir)

    @classmethod
    def Instr_bltu(self, model, rs1 = None, rs2 = None, label = None, dir = None):
        if (rs1.getValueUnsigned() < rs2.getValueUnsigned()):
            model.pc.setValue(label.pcValue)
        else:
            model.pc += 4
        return 'bltu {}, {}, {}{}'.format(rs1.getRegName(), rs2.getRegName(), label.name, dir)

    @classmethod
    def Instr_bgeu(self, model, rs1 = None, rs2 = None, label = None, dir = None):
        if (rs1.getValueUnsigned() >= rs2.getValueUnsigned()):
            model.pc.setValue(label.pcValue)
        else:
            model.pc += 4
        return 'bgeu {}, {}, {}{}'.format(rs1.getRegName(), rs2.getRegName(), label.name, dir)

    @classmethod
    def Instr_jalr(self, model, rd = None, rs1 = None, imm = None):
        rd.setValue(newValue = model.pc.getDecValue() + 4, signed = 1)
        model.pc.setValue(rs1.getDecValue() + imm.getDecValue())
        return 'jalr {}, {}, MASK_XLEN({})'.format(rd.getRegName(), rs1.getRegName(), imm.getDecValue())

    @classmethod
    def Instr_jal(self, model, rd = None, label = None, dir = None):
        rd.setValue(newValue = model.pc.getDecValue() + 4, signed = 1)
        model.pc.setValue(label.pcValue)
        return 'jal {}, {}{}'.format(rd.getRegName(), label.name, dir)


    
    
    ###################################################################################################
    # RV 64I
    ###################################################################################################
    #TODO These may not keep the internal model consistent. You have been warned...sorry lol
    
    @classmethod
    def Instr_ld(self, model, rd = None, rs1 = None, imm = None):
        addr = imm.getDecValue()
        rd.setBits(newBits = signExtend(model.memory.readMemory(addr = addr, granularity = GRANULARITY.WORD), \
            resultNumBits = model.xlen))
        model.pc += 4
        return 'ld {}, {}({})'.format(rd.getRegName(), imm.getDecValue(), rs1.getRegName())

    @classmethod
    def Instr_lwu(self, model, rd = None, rs1 = None, imm = None):
        addr = imm.getDecValue()
        rd.setBits(newBits = zeroExtend(model.memory.readMemory(addr = addr, granularity = GRANULARITY.BYTE), \
            resultNumBits = model.xlen))
        model.pc += 4
        return 'lwu {}, {}({})'.format(rd.getRegName(), imm.getDecValue(), rs1.getRegName())
    
    @classmethod
    def Instr_addiw(self, model, rd = None, rs1 = None, imm = None):
        newValue = rs1.getDecValue() + imm.getDecValue()
        newValueBin = 0
        if newValue > 0:
            newValueBin = bin(newValue)[2:]
        elif newValue == 0:
            newValueBin = "0" * model.xlen
        else:
            newValueBin = bin(newValue)[3:]
        newValueBinTrunk = newValueBin[-model.xlen:]
        rd.setBits(newBits = signExtend(inputBits = newValueBinTrunk, resultNumBits = model.xlen), signed = 1)
        model.pc += 4
        return 'addiw {}, {}, MASK_XLEN({})'.format(rd.getRegName(), rs1.getRegName(), imm.getDecValue())
    
    @classmethod
    def Instr_slliw(self, model, rd = None, rs1 = None, imm = None):
        bits = rs1.bits
        immBits = imm.bits[-5:]
        immShift = int(immBits, 2)
        shifted = bits[-(len(bits) - immShift):]
        shiftedExt = binToDec(inputBits = shifted + '0'*(model.xlen - len(shifted)))
        rd.setValue(newValue = shiftedExt, signed = 1)
        model.pc += 4
        return 'slliw {}, {}, 0b{}'.format(rd.getRegName(), rs1.getRegName(), immBits)

    @classmethod
    def Instr_srliw(self, model, rd = None, rs1 = None, imm = None):
        bits = rs1.bits
        immBits = imm.bits[-5:]
        immShift = int(immBits, 2)
        shifted = bits[0:len(bits) - immShift]
        extShifted = zeroExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'srliw {}, {}, 0b{}'.format(rd.getRegName(), rs1.getRegName(), immBits)

    @classmethod
    def Instr_sraiw(self, model, rd = None, rs1 = None, imm = None):
        bits = rs1.bits
        immBits = imm.bits[-5:]
        immShift = int(immBits, 2)
        shifted = bits[0:len(bits) - immShift]
        extShifted = signExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'sraiw {}, {}, 0b{}'.format(rd.getRegName(), rs1.getRegName(), immBits)

    @classmethod
    def Instr_Sd(self, model, rs1 = None, rs2 = None, imm = None):
        addr = imm.getDecValue()
        model.memory.updateMemory(addr = addr, value = rs2.bits, granularity = GRANULARITY.WORD)
        model.pc += 4
        return 'Sd {}, {}({})'.format(rs2.getRegName(), imm.getDecValue(), rs1.getRegName())

    @classmethod
    def Instr_addw(self, model, rd = None, rs1 = None, rs2 = None):
        newValue = rs1.getDecValue() + rs2.getDecValue()
        newValueBin = 0
        if newValue > 0:
            newValueBin = bin(newValue)[2:]
        elif newValue == 0:
            newValueBin = "0" * model.xlen
        else:
            newValueBin = bin(newValue)[3:]
        newValueBinTrunk = newValueBin[-model.xlen:]
        rd.setBits(newBits = signExtend(inputBits = newValueBinTrunk, resultNumBits = model.xlen), signed = 1)
        model.pc += 4
        return 'addw {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())
    
    @classmethod
    def Instr_subw(self, model, rd = None, rs1 = None, rs2 = None):
        newValue = rs1.getDecValue() - rs2.getDecValue()
        newValueBin = 0
        if newValue > 0:
            newValueBin = bin(newValue)[2:]
        elif newValue == 0:
            newValueBin = "0" * model.xlen
        else:
            newValueBin = bin(newValue)[3:]
        newValueBinTrunk = newValueBin[-model.xlen:]
        rd.setBits(newBits = signExtend(inputBits = newValueBinTrunk, resultNumBits = model.xlen), signed = 1)
        model.pc += 4
        return 'subw {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())
        
    @classmethod
    def Instr_sllw(self, model, rd = None, rs1 = None, rs2 = None):
        bits = rs1.bits
        rs2Bin = rs2.bits[-5:]
        rs2Shift = int(rs2Bin,2)
        shifted = bits[-(len(bits) - rs2Shift):]
        shiftedExt = binToDec(inputBits = shifted + '0'*(model.xlen - len(shifted)))
        rd.setValue(newValue = shiftedExt, signed = 1)
        model.pc += 4
        return 'sllw {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())

    @classmethod
    def Instr_srlw(self, model, rd = None, rs1 = None, rs2 = None):
        bits = rs1.bits
        rs2Bin = rs2.bits[-5:]
        rs2Shift = int(rs2Bin,2)
        shifted = bits[0:len(bits) - rs2Shift]
        extShifted = zeroExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'srlw {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())
    
    @classmethod
    def Instr_sraw(self, model, rd = None, rs1 = None, rs2 = None):
        bits = rs1.bits
        rs2Bin = rs2.bits[-5:]
        rs2Shift = int(rs2Bin,2)
        shifted = bits[0:len(bits) - rs2Shift]
        extShifted = signExtend(inputBits = shifted, resultNumBits = model.xlen)
        rd.setBits(newBits = extShifted, signed = 1)
        model.pc += 4
        return 'sraw {}, {}, {}'.format(rd.getRegName(), rs1.getRegName(), rs2.getRegName())


###################################################################################################
# Global Constants
###################################################################################################
GRANULARITY = Enum('granularity', ['WORD', 'HALFWORD', 'BYTE'])
# 'jalr',
INSTRSETS = {'RV32I':   ['lb', 'lh', 'lw', 'lbu', 'lhu', 'addi', 'slli', 'slti', 'sltiu', 'xori', \
                        'srli', 'srai', 'ori', 'andi', 'auipc', 'sb', 'sh', 'sw', 'add', 'sub', \
                        'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and', 'lui', 'beq', \
                        'bne', 'blt', 'bge', 'bltu', 'bgeu', 'jal', 'jalr'], \
            'RV64I':   ['lb', 'lh', 'lw', 'lbu', 'lhu', 'addi', 'slli', 'slti', 'sltiu', 'xori', \
                        'srli', 'srai', 'ori', 'andi', 'auipc', 'sb', 'sh', 'sw', 'add', 'sub', \
                        'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and', 'lui', 'beq', \
                        'bne', 'blt', 'bge', 'bltu', 'bgeu', 'jalr', 'jal', \
                        'ld', 'lwu', 'addiw', 'slliw', 'srliw', 'sraiw', 'Sd', 'addw', 'subw', \
                        'sllw', 'srlw', 'sraw'] \
            }


InstrTypes = {  'R' : ['add', 'sub', 'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and', \
                        'addw', 'subw', 'sllw', 'srlw', 'sraw'], \
                'I' : ['lb', 'lh', 'lw', 'lbu', 'lhu', 'addi', 'slli', 'slti', 'sltiu', 'xori', 'srli', 'srai', 'ori', 'andi', 'jalr', \
                        'ld', 'lwu', 'addiw', 'slliw', 'srliw', 'sraiw'], \
                'S' : ['sw', 'sh', 'sb', 'Sd'], \
                'B' : ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu'], \
                'U' : ['lui', 'auipc'], \
                'J' : ['jal'],  \
                'R4': []}
###################################################################################################
# Main Body
###################################################################################################

XLEN = ['32', '64']
INSTRUCTION_TYPE = ['I']
NUMINSTR = [100000, 1000000]
IMPERASPATH = "../../imperas-riscv-tests/riscv-test-suite/"

seed(42)
np.random.seed(42)
for num_instructions in NUMINSTR:
    for xlen in XLEN:
        memInit = {}
        for i in range(0, 400, 4):
            val = randBinary(signed = 0, numBits = int(xlen), valueAlignment = 1)
            memInit[i] = val
        for instrType in INSTRUCTION_TYPE:
            instrSet = 'RV' + xlen + instrType

            print('Generating {} Assembly Instructions for {}'.format(num_instructions, instrSet))
            
            dut = TestGen(numInstr=num_instructions, immutableRegsDict = {0 : 0, 6 : 0, 7 : 0}, instrSet=instrSet, imperasPath=IMPERASPATH)
            # regFile = 
            dut.model.memory.populateMemory(memDict = memInit)
            dut.exportASM(instrSet = instrSet, instrTypes = instrType)