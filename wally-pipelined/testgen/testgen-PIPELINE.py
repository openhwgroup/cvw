
import numpy as np
import string
from datetime import datetime

INSTRUCTION_SIZE = 32
VALID_REGISTERS = [str(x) for x in range(1, 32) if x != 6] # generates list of ints from (1, 31) without 6

# Enumeration for decoding instruction formats
NAME            = 0
REG             = 1
ADDR            = 5
IMM             = 6
ZIMM            = 7
LABEL           = 8

# Enumeration for decoding alignments
BYTE            = 1
HALF            = INSTRUCTION_SIZE // 16
WORD            = INSTRUCTION_SIZE // 8
NONE            = 1 

wordsize = 8

class InstrGenerator():
    
    class InstrDict():
        INSTR_RV32I = \
        ["lb", "lh", "lw", "lbu", "lhu", "addi", "slli", "slti", "sltiu", "xori", \
        "srli", "srai", "ori", "andi", "auipc", "sb", "sh", "sw", "add", "sub", \
        "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and", "lui", "beq", \
        "bne", "blt", "bge", "bltu", "bgeu", "jal"] #37 #"jalr"
        INSTR_RV64M = ["mul", "mulh", "muhsu", "mulhu"] #"div", "divu", "rem", "remu"
        #TODO: Add jalr functionality 
        
        # Lists of instructions that follow a specific format
        INSTR_MEM = ["lb", "lh", "lw", "lbu", "lhu", "sb", "sh", "sw"] #8
        INSTR_DEST_SRC1_IMM = ["addi", "slti", "sltiu", "xori", "ori", "andi", "jarl"] #7
        INSTR_DEST_SRC1_ZIMM = ["slli", "srli", "srai"] #3
        INSTR_DEST_IMM = ["auipc", "lui"] #2
        INSTR_DEST_SRC1_SRC2 = ["add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and"]
        
        INSTR_SRC1_SRC2_LABEL = ["beq", "bne", "blt", "bge", "bltu", "bgeu"] #6
        INSTR_DEST_LABEL = ["jal"] #1

        INSTR_DEST_SRC1_SRC2_64M = ["mul", "mulh", "muhsu", "mulhu", "div", "divu", "rem", "remu"]

        def __init__(self):
            self.instr = {}
            
        
        def fillInstructionDictRV32i(self):
            self.instr["lb"] = [(NAME, REG, ADDR), BYTE]
            self.instr["lh"] = [(NAME, REG, ADDR), HALF]
            self.instr["lw"] = [(NAME, REG, ADDR), WORD]
            self.instr["lbu"] = [(NAME, REG, ADDR), BYTE]
            self.instr["lhu"] = [(NAME, REG, ADDR), HALF]

            self.instr["addi"] = [(NAME, REG, REG, IMM), NONE]
            self.instr["slli"] = [(NAME, REG, REG, ZIMM), NONE]
            self.instr["slti"] = [(NAME, REG, REG, IMM), NONE]
            self.instr["sltiu"] = [(NAME, REG, REG, IMM), NONE]
            self.instr["xori"] = [(NAME, REG, REG, IMM), NONE]

            self.instr["srli"] = [(NAME, REG, REG, ZIMM), NONE]
            self.instr["srai"] = [(NAME, REG, REG, ZIMM), NONE]
            self.instr["ori"] = [(NAME, REG, REG, IMM), NONE]
            self.instr["andi"] = [(NAME, REG, REG, IMM), NONE]
            self.instr["auipc"] = [(NAME, REG, IMM), NONE]

            self.instr["sb"] = [(NAME, REG, ADDR), BYTE]
            self.instr["sh"] = [(NAME, REG, ADDR), HALF]
            self.instr["sw"] = [(NAME, REG, ADDR), WORD]
            self.instr["add"] = [(NAME, REG, REG, REG), NONE]
            self.instr["sub"] = [(NAME, REG, REG, REG), NONE]

            self.instr["sll"] = [(NAME, REG, REG, REG), NONE]
            self.instr["slt"] = [(NAME, REG, REG, REG), NONE]
            self.instr["sltu"] = [(NAME, REG, REG, REG), NONE]
            self.instr["xor"] = [(NAME, REG, REG, REG), NONE]
            self.instr["srl"] = [(NAME, REG, REG, REG), NONE]

            self.instr["sra"] = [(NAME, REG, REG, REG), NONE]
            self.instr["or"] = [(NAME, REG, REG, REG), NONE]
            self.instr["and"] = [(NAME, REG, REG, REG), NONE]
            self.instr["lui"] = [(NAME, REG, IMM), NONE]
            self.instr["beq"] = [(NAME, REG, REG, LABEL), NONE]
            
            self.instr["bne"] = [(NAME, REG, REG, LABEL), NONE]
            self.instr["blt"] = [(NAME, REG, REG, LABEL), NONE] 
            self.instr["bge"] = [(NAME, REG, REG, LABEL), NONE]
            self.instr["bltu"] = [(NAME, REG, REG, LABEL), NONE]
            self.instr["bgeu"] = [(NAME, REG, REG, LABEL), NONE]
            
            #self.instr["jalr"] = [(NAME, REG, REG, IMM), NONE]
            self.instr["jal"] = [(NAME, REG, LABEL), WORD]
            
        def fillInstructionDictRV64M(self):
            self.instr["mul"] = [(NAME, REG, REG, REG), NONE]
            self.instr["mulh"] = [(NAME, REG, REG, REG), NONE]
            self.instr["mulhsu"] = [(NAME, REG, REG, REG), NONE]
            self.instr["mulhu"] = [(NAME, REG, REG, REG), NONE]
            self.instr["div"] = [(NAME, REG, REG, REG), NONE]
            self.instr["divu"] = [(NAME, REG, REG, REG), NONE]
            self.instr["rem"] = [(NAME, REG, REG, REG), NONE]
            self.instr["remu"] = [(NAME, REG, REG, REG), NONE]
    
    class RandomSelect():
        LETTER_CHOICES = string.ascii_letters
        
        def randReg(self, regs):
            return regs[np.random.randint(0, len(regs))]
        
        def randBinary(self, signed, numBits, valueAlignment):
            # use this for corners: xlen = 32 here 
            corners = [0, 1, 2, 0xFF, 0x624B3E976C52DD14 % 2**numBits, 2**(numBits-1)-2, 2**(numBits-1)-1, \
            2**(numBits-1), 2**(numBits-1)+1, 0xC365DDEB9173AB42 % 2**numBits, 2**(numBits)-2, 2**(numBits)-1]
            # when not biased don't gen numbers from (|2^(n-2) to 2^(n-2)|)
            biased = np.random.randint(0, 3) # on 2 generate random edge case
            returnVal = 0
            sign = 0
            if biased < 2:
                # print("unbiased")
                if not(signed):
                    returnVal = np.random.randint(0, 2**(numBits) - 1)

                else:    
                    returnVal = np.random.randint(-2**(numBits - 1), 2**(numBits - 1) - 1)
            
            else:
                # print("corner")
                returnVal = corners[np.random.randint(0, len(corners))]

            binReturnVal = bin(returnVal)
            
            if returnVal >= 0:
                binReturnVal = binReturnVal[2:] # get rid of 0b

                #make binary correct length
                while(len(binReturnVal) < numBits):
                    binReturnVal = "0" + binReturnVal

            else:
                binReturnVal = binReturnVal[3:] # get rid of -0b
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

        def randHex(self, sign, numBits, divisibleByValue):
            return hex(int(self.randBinary(sign, numBits*4, divisibleByValue), 2))
        
        def randDec(self, valueRangeMin, valueRangeMax, divisibleByValue):
            valRange = (valueRangeMax - valueRangeMin)//divisibleByValue   
            return (np.random.randint(0, valRange + 1) * divisibleByValue + valueRangeMin)

    def __init__(self, numMemoryRegisters, xlen):
        self.instrDict = self.InstrDict()
        self.instrDict.fillInstructionDictRV32i()
        if (xlen == 64):
            self.instrDict.fillInstructionDictRV64M()

        self.randSelect = self.RandomSelect()

        self.memoryAdrList = []
        self.populateMemory()
        self.prevLabel = 0

        self.memReg = []
        self.anyReg = VALID_REGISTERS[:]

        self.xlen = xlen
        self.test_count = 0

        for i in range(0, numMemoryRegisters):
            reg = self.randSelect.randReg(self.anyReg)
            self.anyReg.remove(reg)
            self.memReg.append(reg)
        
        self.PC = int("80000108",16)
    
    def addPC(self, instr): #adapted from BB code
        if instr == "li":
            self.PC += 8 if (self.xlen == 32) else 20
        elif instr == "la":
            self.PC += 8
        else:
            self.PC += 4

    def getRandInstruction(self, instr):
        return instr[np.random.randint(0, len(instr))]

    def getForwardingInstructions(self, instr): #TODO make so that memory register can be manipulated
        fields, alignment = self.instrDict.instr[instr]
        ld_instr = "lw"
        num = np.random.randint(0, 2) # 0 signed, on 1 unsigned
        if alignment == BYTE:
            if num == 0:
                ld_instr = "lbu"
            else:
                ld_instr = "lb"
        if alignment == HALF:
            if num == 0:
                ld_instr = "lhu"
            else:
                ld_instr = "lw"

        reg1 = self.randSelect.randReg(self.anyReg)
        mask = self.randSelect.randHex(True, 3, alignment)
        reg_set_instr = "andi x" + reg1 + ", x" + reg1 + ", SEXT_IMM(" + mask + ")"  # set register to  multiple of 4

        rd = self.randSelect.randReg(self.anyReg)
        imm1 = self.memoryAdrList[np.random.randint(0, len(self.memoryAdrList))] #load imm 
        mem_instr_ld = ld_instr + " x" + rd + ", " + imm1 + "(x" + reg1 + ")" #load value to rd

        reg2 = self.randSelect.randReg(self.memReg)
        imm2 = self.memoryAdrList[np.random.randint(0, len(self.memoryAdrList))] #str imm
        mem_instr_str = "sw" + " x" + rd + ", " + imm2 + "(x" + reg2 + ")" #store value of rd
        
        instructions = [reg_set_instr, mem_instr_ld, mem_instr_str]
        check_instr = self.genTestInstr(rd)
        for check in check_instr:
            instructions.append(check)
        
        return instructions
        
    def jumpInstruction(self, instr):
        fields, alignment = self.instrDict.instr[instr]

        # randomly determine forward or back branch direction
        fwd = np.random.randint(0, 2) #fwd on 1, bwd on 0
        taken = np.random.randint(0,2) #not taken on 0, taken on 1

        reg_pc = self.randSelect.randReg(self.anyReg)
        instructions = []

        if fwd == 1:
            instructions.append(instr + " x" + reg_pc + ", " + str(self.prevLabel) + "f")
            
            numInstr = np.random.randint(0, 6)
            # add random alu instructions after jumping before jump point
            reg_check = 1
            for i in range(0, numInstr):
                curr = self.getRandInstruction(self.instrDict.INSTR_DEST_SRC1_SRC2)
                rd = self.randSelect.randReg(self.anyReg)
                while (rd == reg_pc):
                    rd = self.randSelect.randReg(self.anyReg)
                reg_check = rd
                r1 = self.randSelect.randReg(self.anyReg)
                r2 = self.randSelect.randReg(self.anyReg)
                instructions.append(curr + " x" + rd + ", x" + r1 + ", x" + r2)
            instructions.append(str(self.prevLabel) + ":")
            self.prevLabel += 1

            #make sure jump was taken
            check_instr = self.genTestInstr(reg_check)
            for check in check_instr:
                instructions.append(check)

            #check value in pc + 4 reg
            check_instr = self.genTestInstr(reg_pc)
            for check in check_instr:
                instructions.append(check)
        else:
            reg1 = self.randSelect.randReg(self.anyReg)
            reg2 = self.randSelect.randReg(self.anyReg)
            while reg2 == reg1:
                reg2 = self.randSelect.randReg(self.anyReg)
            
            instructions.append("jal x" + reg1 + ", 1f")
            
            instructions.append("2:")
            instructions.append("jal x" + reg2 + ", 3f")
            
            instructions.append("1:")
    
            numInstr = np.random.randint(0,6)
            for i in range(0, numInstr):
                curr = self.getRandInstruction(self.instrDict.INSTR_DEST_SRC1_SRC2)
                rd = self.randSelect.randReg(self.anyReg)
                r1 = self.randSelect.randReg(self.anyReg)
                r2 = self.randSelect.randReg(self.anyReg)
                instructions.append(curr + " x" + rd + ", x" + r1 + ", x" + r2)
            
            #test case here
            instructions.append("jal x" + reg2 + ", 2b")
            instructions.append("3:")
            
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
            
    def branchInstruction(self, instr):
        fields, alignment = self.instrDict.instr[instr]

        # randomly determine forward or back branch direction
        fwd = np.random.randint(0, 2) #fwd on 1, bwd on 0
        taken = np.random.randint(0,2) #not taken on 0, taken on 1

        instructions = []

        # pick 2 registers for branch comparison
        reg1 = self.randSelect.randReg(self.anyReg)
        reg2 = reg1
        while (reg2 == reg1):
            reg2 = self.randSelect.randReg(self.anyReg)
            
        if (fwd == 1):
            # set r1 and r2 to what they should be to do the branching we want
            #TODO this assumed that greater than equal to or lteq are instead jsut equal, will be changed later
            if  (instr == "beq" and taken==1)   or (instr == "bne" and taken==0) or \
                (instr == "blt" and taken==0)   or (instr == "bge" and taken==1) or \
                (instr == "bltu" and taken==0)  or (instr == "bgeu" and taken==1): #r1 = r2
                instructions.append("mv x" + reg1 + ", x" + reg2)

            elif (instr == "beq" and taken==0)   or (instr == "bne" and taken==1) or \
                (instr == "blt" and taken==1)   or (instr == "bltu" and taken==1): #r2 = r1 + 1
                instructions.append("addi x" + reg2 + ", x" + reg1 + ", 1")

            else:
                instructions.append("addi x" + reg2 + ", x" + reg1 + ", -1") #r2 = r1 - 1

            # add branching instruction
            instructions.append(instr + " x" + reg1 + ", x" + reg2 +  ", " + str(self.prevLabel) + "f")
            numInstr = np.random.randint(0, 6)
            # add random alu instructions after branching before branch point
            reg_check = 1
            for i in range(0, numInstr):
                curr = self.getRandInstruction(self.instrDict.INSTR_DEST_SRC1_SRC2)
                rd = self.randSelect.randReg(self.anyReg)
                reg_check = rd
                r1 = self.randSelect.randReg(self.anyReg)
                r2 = self.randSelect.randReg(self.anyReg)
                instructions.append(curr + " x" + rd + ", x" + r1 + ", x" + r2)
            instructions.append(str(self.prevLabel) + ":")
            self.prevLabel += 1
            check_instr = self.genTestInstr(reg_check)
            for check in check_instr:
                instructions.append(check)
            return instructions

        # Backwards branch case
        else:
            if (not taken):
                if instr == "beq":
                    randImm = self.randSelect.randHex(True, 1, 1)
                    while randImm == "0x0":
                        randImm = self.randSelect.randHex(True, 1, 1)
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(randImm) + ")") #r2 = r1 + randImm (-10, 10) and not 0

                elif instr == "bne":
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", 0") #r2 = r1 + 0
                
                elif instr == "bltu" or instr == "blt":
                    randImm = np.random.randint(-10, 0)
                    randMaskLen = np.random.randint(10, 100)
                    instructions.append("addi x" + reg1 + ", x0, " + "MASK_XLEN(" + str(randMaskLen) + ")") # set reg1 to be rand positive number, helps stop infinite looping
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(randImm) + ")") #r2 = r1 + randImm (-10, -1)

                elif instr == "bgeu" or instr == "bge":
                    randImm = np.random.randint(1, 11)
                    randMaskLen = np.random.randint(10, 100)
                    instructions.append("addi x" + reg1 + ", x0, "+ "MASK_XLEN(" + str(randMaskLen) + ")") # set reg1 to be rand positive number, helps stop infinite looping
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(randImm) + ")") #r2 = r1 + randImm (1, 11)

                instructions.append(str(self.prevLabel) + ":")
                numInstr = np.random.randint(0, 6)
                # add random alu instructions after branching before branch point
                reg_check = 1
                for i in range(0, numInstr):
                    curr = self.getRandInstruction(self.instrDict.INSTR_DEST_SRC1_SRC2)
                    rd = self.randSelect.randReg(self.anyReg)
                    reg_check = rd
                    while rd == reg1 or rd==reg2:
                        rd = self.randSelect.randReg(self.anyReg)
                    r1 = self.randSelect.randReg(self.anyReg)
                    r2 = self.randSelect.randReg(self.anyReg)
                    instructions.append(curr + " x" + rd + ", x" + r1 + ", x" + r2)
                
                check_instr = self.genTestInstr(reg_check)
                for check in check_instr:
                    instructions.append(check)
            
            else:
                #setup reg instructions before any branching stuff
                if instr == "beq": 
                    numTimesRepeat = 1 #can only be repeated once with the way we are doing this
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(numTimesRepeat) + ")") #r2 = r1 + numTimesRepeat ( - 6)
                    instructions.append(str(self.prevLabel) + ":")
                    instructions.append("addi x" + reg2 + ", x" + reg2 + ", -1")

                elif instr == "bne":
                    numTimesRepeat = np.random.randint(2, 6) 
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(numTimesRepeat) + ")") #r2 = r1 + numTimesRepeat (2 - 6)
                    instructions.append(str(self.prevLabel) + ":")
                    instructions.append("addi x" + reg2 + ", x" + reg2 + ", -1")
                
                elif instr == "bltu": 
                    numTimesRepeat = np.random.randint(2, 6)
                    instructions.append("ori x" + reg1 + ", x" + reg1 + ", " + "1") # ensure reg1 is not 0
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(numTimesRepeat) + ")") #r2 = r1 - numTimesRepeat (2 - 6)
                    instructions.append(str(self.prevLabel) + ":")
                    instructions.append("addi x" + reg2 + ", x" + reg2 + ", -1")
                
                elif instr == "blt":
                    numTimesRepeat = np.random.randint(2, 6)
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(numTimesRepeat) + ")") #r2 = r1 - numTimesRepeat (2 - 6)
                    instructions.append(str(self.prevLabel) + ":")
                    instructions.append("addi x" + reg2 + ", x" + reg2 + ", -1")

                elif instr == "bgeu" or instr == "bge":
                    numTimesRepeat = np.random.randint(2, 6)*(-1)
                    instructions.append("addi x" + reg2 + ", x" + reg1 + ", MASK_XLEN(" + str(numTimesRepeat) + ")") #r2 = r1 + numTimesRepeat (2 - 6)
                    instructions.append(str(self.prevLabel) + ":")
                    instructions.append("addi x" + reg2 + ", x" + reg2 + ", 1")

                # Junk instructions
                numInstr = np.random.randint(0, 5)
                reg_check = 1
                for i in range(0, numInstr):
                    curr = self.getRandInstruction(self.instrDict.INSTR_DEST_SRC1_SRC2)
                    rd = self.randSelect.randReg(self.anyReg)
                    reg_check = rd
                    while rd == reg1 or rd==reg2:
                        rd = self.randSelect.randReg(self.anyReg)
                    r1 = self.randSelect.randReg(self.anyReg)
                    r2 = self.randSelect.randReg(self.anyReg)
                    instructions.append(curr + " x" + rd + ", x" + r1 + ", x" + r2)
                    
                check_instr = self.genTestInstr(reg_check)
                for check in check_instr:
                    instructions.append(check)
            instructions.append(instr + " x" + reg1 + ", x" + reg2 +  ", " + str(self.prevLabel) + "b")  
            self.prevLabel += 1

        return instructions
            
        # have (1-5) sudo random alu instructions for backwards branch, (0-5) for forward

        # randomly determine if branch is taken or not
            # if branch not taken, 
                # we go by specific instruction and do some bit swizzling to make it false
        
            # if branch taken
                # add specific instruction to make branch true
                # for backwards, have alu instructions change comparison flags to be true
    
    def genTestInstr(self, reg):
        out = ["sw x" + str(reg) + ", "+ str(self.test_count) + "(x6)"]
        out.append("RVTEST_IO_ASSERT_GPR_EQ(x7, x{}, 0xdeadbeef) ".format(reg))
        self.test_count += 4

        if (self.test_count == 2044):
            # Reset
            wreset = "addi x6, x6, MASK_XLEN(2044)"
            self.test_count = 0
            out.append(wreset)
            
        return out

    def genInstruction(self):
        num = np.random.randint(0, 20)
        instr = ""
        if (self.xlen == 64) and (num == 20):
            instr = self.getRandInstruction(self.InstrDict.INSTR_RV64M)
        else:
            instr = self.getRandInstruction(self.InstrDict.INSTR_RV32I)

        num = np.random.randint(0, 2) # 0 mem reg, on 1 do forwarding stuff
        if instr in self.InstrDict.INSTR_MEM and num == 1:
            return self.getForwardingInstructions(instr)
        
        if instr in self.InstrDict.INSTR_SRC1_SRC2_LABEL:
            return self.branchInstruction(instr)
        
        if instr in self.InstrDict.INSTR_DEST_LABEL:
            return self.jumpInstruction(instr)

        fields, alignment = self.instrDict.instr[instr]
        output = ""
        rd = 1
        for field in fields:
            if field == NAME:
                output += instr + " "
                
            elif field == REG:
                rd = self.randSelect.randReg(self.anyReg)
                output += "x" + str(rd) + ", "
                
            elif field == IMM and instr != "lui" and instr != "auipc":
                output += "SEXT_IMM(" + self.randSelect.randHex(False, 3, alignment) + ")"

            elif field == IMM and (instr == "lui" or instr == "auipc"):
                output += self.randSelect.randHex(False, 3, alignment)
            
            elif field == ADDR:
                output += self.memoryAdrList[np.random.randint(0, len(self.memoryAdrList))]
                output += "("
                output += "x" + self.randSelect.randReg(self.memReg)
                output += ")"
            
            elif field == ZIMM:
                if (instr in self.instrDict.INSTR_DEST_SRC1_ZIMM):
                    output += "SEXT_IMM(" + str(hex(np.random.randint(0, 32))) + ")" # has to be between 0 and 31
                else:
                    output += "SEXT_IMM(" + self.randSelect.randHex(True, 3, alignment) + ")"
                
            elif field == LABEL:
                output += str(self.prevLabel)
        
        if output[-2:] == ", ":
            output = output[0:-2]
        
        out_instr = [output]
        check_instr = self.genTestInstr(rd)
        for check in check_instr:
            out_instr.append(check)
        return out_instr
    
    def setRegisters(self):
        out = []
        for reg in self.anyReg:
            out.append('li x{}, MASK_XLEN({})'.format(reg, self.randSelect.randHex(False, 5, 1)))
        return out
        
    def populateMemory(self):
        for i in range(0, 5):
            val = self.randSelect.randDec(-1000, 1000, WORD)
            while val in self.memoryAdrList:
                val = self.randSelect.randDec(-1000, 1000, WORD)
            self.memoryAdrList.append(str(val))

    def generateInstructions(self, numInstructions):
        instructions = []
        for i in range(0, numInstructions):
            instr = self.genInstruction()
            for j in instr:
                instructions.append(j) 
        return instructions

class RandInstrGenerator(InstrGenerator):
    pass

class HazardInstrGenerator(InstrGenerator):
    pass

# xlens = [32, 64]
xlens = [64]
for xlen in xlens:

    test = "PIPELINE"
    np.random.seed(42)
    instrGen = InstrGenerator(10, xlen)

    # write instructions to file
    imperaspath = "../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "wally/"
    basename = "WALLY-" + test 
    fname = imperaspath + "src/" + basename + ".S"
    refname = imperaspath + "references/" + basename + ".reference_output"


    # FOR LOCAL TESTING
    # fname = "PIPELINE_TEST.S"

    # print custom header part
    f = open(fname, "w")
    r = open(refname, "w")
    line = "///////////////////////////////////////////\n"
    f.write(line)
    lines="// "+fname+ "\n// " + "Ethan Falicov & Shriya Nadgauda" + "\n"
    f.write(lines)
    line ="// Created " + str(datetime.now())  + "\n" + "\n"
    f.write(line)
    line = "// Begin Tests" + "\n"
    f.write(line)


    # insert generic header
    h = open("testgen_header.S", "r")
    for line in h:  
        f.write(line)
    f.write("\n")


    #set registerss
    reg_instr = instrGen.setRegisters()
    for instr in reg_instr:
        f.write("\t" + instr + "\n")
    
    # write instructions
    testnum = 500
    instructions = instrGen.generateInstructions(testnum)
    for instr in instructions:
        f.write("\t" + instr + "\n")
        if ("RVTEST_IO_ASSERT_GPR_EQ" in instr):
            f.write("\n")


    # print footer
    h = open("testgen_footer.S", "r")
    for line in h:  
        f.write(line)

    # Finish
    lines = ".fill " + str(testnum) + ", " + str(xlen//8) + ", -1\n"
    lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
    f.write(lines)
    f.close()
    r.close()

    print("Done with ", xlen)