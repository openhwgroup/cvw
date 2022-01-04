import os

# Kevin Wan kewan@hmc.edu 10/27/2021
def read_input(filename):  #1
    """Takes in a string filename and outputs the parsed verilog code by line into a list
    such that each element of the list is one line of verilog code as a string."""
    lineOfCode = []
    input_file = open(filename, 'r')
    for line in input_file:
        lineOfCode.append(line)
    return lineOfCode
###################################################################################
def ID_start(GiantString):#2
    """takes in the list of sv file lines, outputs the location that variable names should start"""
    VarLoc = 0 
    VarLineNum = None
    for lines in GiantString:
        if ' logic ' in lines and (lines.find("//") == -1 or lines.find("//") > lines.find(' logic ')): # // logic does not proceed. logic proceeds. logic // proceeds. 
            if "[" in lines and "]" in lines:# need to account for these space
                NowLoc = lines.find(']') + 3# column number in sv code when 1st char of the var name should appear. 
                if NowLoc>VarLoc: 
                    VarLoc = NowLoc
                    VarLineNum = GiantString.index(lines) # Update this number if new record is made. 
            else:   
                NowLoc = lines.find('logic') + 7 # same as before.
                if NowLoc>VarLoc: 
                    VarLoc = NowLoc
                    VarLineNum = GiantString.index(lines)
    #print("Furthest variable appears on line", VarLineNum + 1,VarLoc)   # Disable this line after debugging. 
    return VarLoc
##################################################################################
def modified_logNew(GS,SOV): #3
    Ind = SOV - 1 # SOV is for human readability, Ind is the character's index in computer, since computers count from 0's we need to correct it. 
    Out = []
    for l in GS:
        lines = l.replace('\t',' ')

        if ' logic ' in lines and (lines.find("//") == -1 or lines.find("//") > lines.find(' logic ')): # // logic does not proceed. logic proceeds. logic // proceeds. 
            if "[" in lines and "]" in lines: # the line is an extended declaration. 
                EditLoc = lines.find("]") # Re-finds the string index number of ]. 
                VarLoc = FindCharRel(lines[EditLoc+1::]) + EditLoc + 1  # Checks where variable declaration currently is at. 
                #print(VarLoc,lines[VarLoc])# VERIFIED
                NewLine = Mod_Space_at(lines,VarLoc,VarLoc-Ind) 
                Out.append(NewLine)# Verified0957 10272021
            else:
                EditLoc1 = lines.find('c') # Hopefully sees the c in 'logic'

                VarLoc1 = FindCharRel(lines[EditLoc1+1::]) + EditLoc1 + 1
                NewLine1 = Mod_Space_at(lines,VarLoc1,VarLoc1-Ind)

                Out.append(NewLine1)# Verified 1005 10272021
        else:
            Out.append(lines)
    return Out   
################################################################################
def write_to_output(filename,GiantString,OW=True,Lines_editted=None):   #4
 """Filename is preferrably passed from the early function calls"""
 """GiantString has all the corrected features in the code, each line is a good verilog code line"""
 newname = filename
 if not OW or OW =='f':   #which means no overwrite (create a new file)
  Decomposed=filename.split('.')
  newname = Decomposed[0] + "_AL." + Decomposed[1] # AL for aligned. 
  
 OutFile = open(newname,'w') # This step should create a new file. 
 OutFile.writelines(GiantString)
 OutFile.close()
 print("Success! " + newname + " Now contains an aligned file!")
 return newname
#################################################################################

def FindCharRel(Ln):
    #returns the computer location of a character's first occurence
    for num in range(len(Ln)):
        if Ln[num] != " ":
            return num 


def Mod_Space_at(Ln,loc,diff):
    #loc is the varLoc from mln, diff is varLoc - Ind
    if diff > 0: # to delete
        NewString = Ln[:(loc-diff)] + Ln[loc:]
        
    if diff < 0: # to add
        NewString = Ln[:loc] + (-diff)*" " + Ln[loc:]
    if diff == 0:
        NewString = Ln
    
    return NewString

'''def main_filehandler(overwrite=False):
    for filename in os.listdir():
        if ".sv" in filename:
            GiantString = read_input(filename)
            SOV = ID_start(GiantString)
            ModifiedGS = modified_logNew(GiantString,SOV)
            Newname = write_to_output(filename,ModifiedGS,overwrite)'''
def root_filehandler(path,overwrite=False):
    for f in os.listdir(path):
        if os.path.isdir(f):
            root_filehandler(path+"/"+f)
        else:
            if ".sv" in f:
                GiantString = read_input(f)
                SOV = ID_start(GiantString)
                ModifiedGS = modified_logNew(GiantString,SOV)
                Newname = write_to_output(f,ModifiedGS,overwrite)
                
                
def driver(overwrite=False):
    root_filehandler(os.getcwd())
 
driver(True)