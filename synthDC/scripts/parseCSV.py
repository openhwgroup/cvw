import csv
import os

#order:
""" sort by noidiv, then idiv, 32, 64, f, d,q, and r/k """

def parse_freq(rows):
    rowout = []
    rows_slowclk = []
    rows_fastclk = []
    for row in rows:
        if "100_MHz" in row[0]:
            rows_slowclk.append(row)
        if "5000_MHz" in row[0]:
            rows_fastclk.append(row)
    rowout.extend(parse_idiv(rows_slowclk,1E6*100))
    rowout.extend(parse_idiv(rows_fastclk,1E6*5000))
    return rowout
def parse_xlen(rows,freq):
    final = []
    rows32 = []
    rows64 = []
    for row in rows:
        if "rv32gc" in row[0]:
            rows32.append(row)
        
        if "rv64gc" in row[0]:
            rows64.append(row)
    rowout = []
    rowout.extend(parse_fpmode(rows32,freq))
    rowout.extend(parse_fpmode(rows64,freq))
    return rowout
     
    
def parse_r_k(rows,freq):
    rowout = []
    for row in rows:
        design = row[0]
        area = row[1]
        delay = row[2]
        power = float(row[3])/freq
        if "RADIX_2" in design and "K_1" in design and len(rowout)/3 == 0:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        area = row[1]
        delay = row[2]
        power = float(row[3])/freq
        if "RADIX_2" in design and "K_2" in design and len(rowout)/3 == 1:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        area = row[1]
        delay = row[2]
        power = float(row[3])/freq
        if "RADIX_2" in design and "K_4" in design and len(rowout)/3==2:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        area = row[1]
        delay = row[2]
        power = float(row[3])/freq
        if "RADIX_4" in design and "K_1" in design and len(rowout)/3 ==3:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        area = row[1]
        delay = row[2]
        power = float(row[3])/freq
        if "RADIX_4" in design and "K_2" in design and len(rowout)/3 ==4:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        area = row[1]
        delay = row[2]
        power = float(row[3])/freq
        if "RADIX_4" in design and "K_4" in design and len(rowout)/3 ==5:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    rowout.insert(0, titleClean(rows[0][0]))
    return rowout

def titleClean(title):
    i = title.index("RADIX")
    title=title[:i] + title[i+12:]
    i = title.index("IDIVBITS")
    title=title[:i] + title[i+11:]
    return title
def parse_fpmode(rows,freq):
    rowf = []
    rowd = []
    rowq = []
    rowout = []
    for row in rows:
        if "FPMODE_F" in row[0]:
            rowf.append(row)
        if "FPMODE_D" in row[0]:
            rowd.append(row)
        if "FPMODE_Q" in row[0]:
            rowq.append(row)
    rowout.append(parse_r_k(rowf,freq))
    rowout.append(parse_r_k(rowd,freq))
    rowout.append(parse_r_k(rowq,freq))
    return rowout

    

def parse_idiv(rows,freq):
    idivrows = []
    noidivrows = []
    rowout = []
    for row in rows:
        if "INTDIV_1" in row[0]:
            idivrows.append(row)
        else:
            noidivrows.append(row)
    rowout.extend(parse_xlen(idivrows,freq))
    rowout.extend(parse_xlen(noidivrows,freq))
    return rowout

    
with open(f"{os.environ['WALLY']}/synthDC/fp-synth.csv", 'r') as csv_file:
    reader = csv.reader(csv_file)
    allrows = []
    rowout = [["design","RADIX_2_K_1", "RADIX_2_K_1", "RADIX_2_K_1", "RADIX_2_K_2", "RADIX_2_K_2", "RADIX_2_K_2", "RADIX_2_K_4", "RADIX_2_K_4", "RADIX_2_K_4", "RADIX_4_K_1", "RADIX_4_K_1", "RADIX_4_K_1", "RADIX_4_K_2", "RADIX_4_K_2", "RADIX_4_K_2", "RADIX_4_K_4", "RADIX_4_K_4", "RADIX_4_K_4"]]
    for row in reader:
        allrows.append(row)
    rowout.extend(parse_freq(allrows))
    print(rowout)

with open(f"{os.environ['WALLY']}/synthDC/fp-synthresults.csv", 'w') as csv_out:
    csvwriter=csv.writer(csv_out)
    csvwriter.writerows(rowout)