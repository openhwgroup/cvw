import csv
import os

from iteration_utilities import grouper

#order:
""" sort by noidiv, then idiv, 32, 64, f, d,q, and r/k """

def parse_freq(rows):
    rowout = []
    rows_slowclk = []
    rows_fastclk = []
    for row in rows:
        if "100_MHz" in row[0]:
            rows_slowclk.append(row)
        if "6000_MHz" in row[0]:
            rows_fastclk.append(row)
    rowout.extend(parse_idiv(rows_slowclk,1E6*100))
    rowout.extend(parse_idiv(rows_fastclk,1E6*6000))
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
    if ("drsu" in rows[0][0]):
      rowout.extend(parse_fpmode(rows32,freq)) 
      rowout.extend(parse_fpmode(rows64,freq))
    elif ("mdudiv" in rows[0][0]):
      rowout.append(parse_idivbits(rows32,freq))
      rowout.append(parse_idivbits(rows64,freq))
    return rowout
     
    
def parse_r_k(rows,freq):
    rowout = []
    for row in rows:
        design = row[0]
        r = int(design.split("_")[4])
        k = int(design.split("_")[5][0])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if r==2 and k==1 and len(rowout)/3 == 0:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        r = int(design.split("_")[4])
        k = int(design.split("_")[5][0])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if r==2 and k==2 and len(rowout)/3 == 1:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        r = int(design.split("_")[4])
        k = int(design.split("_")[5][0])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if r==2 and k==4  and len(rowout)/3==2:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        r = int(design.split("_")[4])
        k = int(design.split("_")[5][0])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if r==2 and k==8  and len(rowout)/3==3:
            print("WE ARE HERE")
            print(row[0])
            print(area)
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        r = int(design.split("_")[4])
        k = int(design.split("_")[5][0])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if r==4 and k== 1 and len(rowout)/3 ==4:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        r = int(design.split("_")[4])
        k = int(design.split("_")[5][0])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if r==4 and k==2 and len(rowout)/3 ==5:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        r = int(design.split("_")[4])
        k = int(design.split("_")[5][0])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if r==4 and k==4 and len(rowout)/3 ==6:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    rowout.insert(0, titleClean(rows[0][0]))
    return rowout

# *** NOTE CHANGE THIS STUFF
def parse_idivbits(rows,freq):
    rowout = []
    for row in rows:
        design = row[0]
        bits = int(design.split("_")[3])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if bits == 1 and len(rowout)/3 == 0:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        bits = int(design.split("_")[3])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if bits == 2 and len(rowout)/3 == 1:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        bits = int(design.split("_")[3])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if bits == 4 and len(rowout)/3==2:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        bits = int(design.split("_")[3])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if bits == 8 and (len(rowout)/3 ==3):
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        bits = int(design.split("_")[3])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if bits == 2 and len(rowout)/3 ==4:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        bits = int(design.split("_")[3])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if bits == 4 and len(rowout)/3 ==5:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    for row in rows:
        design = row[0]
        bits = int(design.split("_")[3])
        area = float(row[1])/1000
        delay = row[2]
        power = float(row[3])/freq
        if bits == 8 and len(rowout)/3 ==6:
            rowout.append(area)
            rowout.append(delay)
            rowout.append(power)
    rowout.insert(0, titleClean(rows[0][0]))
    return rowout
def titleClean(title):
  newtitle = ""
  if ("drsu" in title):
    tokens = title.split("_")
    tokens.pop(3)
    tokens.pop(3)
    tokens.pop(3)
    tokens.pop(4)
    if "i_" in title:
      newtitle = "_".join(tokens) + "_IDIV"
    else:
      newtitle = "_".join(tokens)
  elif ("mdudiv" in title):
    tokens = title.split("_")
    tokens.pop(5)
    tokens.pop(3)
    newtitle = "_".join(tokens)
    #*** DO STUFF HERE

  """

  i = title.index("RADIX")
  title=title[:i] + title[i+12:]
  i = title.index("IDIVBITS")
  title=title[:i] + title[i+11:]
  """
  return newtitle
def parse_fpmode(rows,freq):
    rowf = []
    rowd = []
    rowq = []
    rowout = []
    for row in rows:
        precision = row[0].split("_")[1]
        if precision == "f":
            rowf.append(row)
        if precision == "fd":
            rowd.append(row)
        if precision == "fdq":
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
      idiv = len((row[0].split("_"))[5]) == 2
      if idiv:
          idivrows.append(row)
      else:
          noidivrows.append(row)
    
    if len(idivrows)>0: rowout.extend(parse_xlen(idivrows,freq))
    rowout.extend(parse_xlen(noidivrows,freq))
    return rowout

def mergerows(drsu,mdu):
  drsumdurow = []
  for i in range(len(drsu)):
    drsurow = drsu[i]
    mdurow=mdu[i//3]
    drsumdurow.append(combinerow(drsurow, mdurow))
  return drsumdurow
def combinerow(drsu, mdu):
  drsu_mdu = ["MDU_"+drsu[0]]
  # group into 3's 
  drsu_group = list(grouper(drsu[1:],3))
  print(drsu_group)
  mdu_group = list(grouper(mdu[1:],3))
  for i in range(len(drsu_group)):
    area_1 = drsu_group[i][0]
    area_2 = mdu_group[i][0]

    timing_1 = drsu_group[i][1]
    timing_2 = mdu_group[i][1]

    energy_1 = drsu_group[i][2]
    energy_2 = mdu_group[i][2]

    area_comb = float(area_1) + float(area_2)
    timing_comb = max(float(timing_1), float(timing_2))
    energy_comb = float(energy_1) + float(energy_2)
    drsu_mdu.append(area_comb)
    drsu_mdu.append(timing_comb)
    drsu_mdu.append(energy_comb)
  return drsu_mdu


rowout = [["design","RADIX_2_K_1", "RADIX_2_K_1", "RADIX_2_K_1", "RADIX_2_K_2", "RADIX_2_K_2", "RADIX_2_K_2", "RADIX_2_K_4", "RADIX_2_K_4", "RADIX_2_K_4", "RADIX_2_K_8", "RADIX_2_K_8", "RADIX_2_K_8", "RADIX_4_K_1", "RADIX_4_K_1", "RADIX_4_K_1", "RADIX_4_K_2", "RADIX_4_K_2", "RADIX_4_K_2", "RADIX_4_K_4", "RADIX_4_K_4", "RADIX_4_K_4"]]

with open(f"{os.environ['WALLY']}/synthDC/fp-synth.csv", 'r') as csv_file:
    reader = csv.reader(csv_file)
    allrows = []
    for row in reader:
        allrows.append(row)
    rowout.extend(parse_freq(allrows))
# add mdu divider results, and combine with fdivsqrt only results
# format should be drsu_idiv, drsu_noidiv + intdiv, drsu_noidiv, intdiv
# insert drsu_noidiv+intdiv at index 7
with open(f"{os.environ['WALLY']}/synthDC/fp-synth_intdiv.csv", 'r') as csv_file:
    reader = csv.reader(csv_file)
    allrows = []
    for row in reader:
        allrows.append(row)
    rowout.extend(parse_freq(allrows))
    drsu100i_rows = rowout[1:7]
    drsu100_rows = rowout[7:13]
    drsu5000i_rows = rowout[13:19]
    drsu5000_rows = rowout[19:25]
    mdu100_rows = rowout[25:27]
    mdu5000_rows = rowout[27:29]
    drsumdu_100_rows = mergerows(drsu100_rows,mdu100_rows)
    drsumdu_5000_rows = mergerows(drsu5000_rows,mdu5000_rows)
    header = [str(x) for x in range(7*3+1)]
    rowout = [header,
      ["design","RADIX_2_K_1", "RADIX_2_K_1", "RADIX_2_K_1", "RADIX_2_K_2", "RADIX_2_K_2", "RADIX_2_K_2", "RADIX_2_K_4", "RADIX_2_K_4", "RADIX_2_K_4", "RADIX_2_K_8", "RADIX_2_K_8", "RADIX_2_K_8","RADIX_4_K_1", "RADIX_4_K_1", "RADIX_4_K_1", "RADIX_4_K_2", "RADIX_4_K_2", "RADIX_4_K_2", "RADIX_4_K_4", "RADIX_4_K_4", "RADIX_4_K_4"]]
    rowout.extend(drsu100i_rows[0:3])
    rowout.extend(drsumdu_100_rows[0:3])
    rowout.extend(drsu100_rows[0:3])
    rowout.extend([mdu100_rows[0]])

    rowout.extend(drsu100i_rows[3:6])
    rowout.extend(drsumdu_100_rows[3:6])
    rowout.extend(drsu100_rows[3:6])
    rowout.extend([mdu100_rows[1]])


    rowout.extend(drsu5000i_rows[0:3])
    rowout.extend(drsumdu_5000_rows[0:3])
    rowout.extend(drsu5000_rows[0:3])
    rowout.extend([mdu5000_rows[0]])

    rowout.extend(drsu5000i_rows[3:6])
    rowout.extend(drsumdu_5000_rows[3:6])
    rowout.extend(drsu5000_rows[3:6])
    rowout.extend([mdu5000_rows[1]])











with open(f"{os.environ['WALLY']}/synthDC/fp-synthresults.csv", 'w') as csv_out:
    csvwriter=csv.writer(csv_out)
    csvwriter.writerows(rowout)

with open(f"{os.environ['WALLY']}/synthDC/fp-synthresults.csv", "r") as csv_file, open(f"{os.environ['WALLY']}/synthDC/fp-synthresults_reordered.csv", "w") as csv_out:
  newheader = ["0"]
  for i in range(1, 7*3+1):
    if i%3 == 1:
      newheader.append(str(i))
  for i in range(1, 7*3+1):
    if i%3 == 2:
      newheader.append(str(i))
  for i in range(1, 7*3+1):
    if i%3 == 0:
      newheader.append(str(i))
  rowout = [['design', 'area', 'area', 'area', 'area', 'area', 'area', 'area', 'delay', 'delay', 'delay', 'delay', 'delay', 'delay', 'delay', 'energy', 'energy', 'energy', 'energy', 'energy', 'energy', 'energy']]
  
  csvwriter=csv.writer(csv_out)
  csvwriter.writerows(rowout)
  writer = csv.DictWriter(csv_out, fieldnames=newheader)
  for row in csv.DictReader(csv_file):
    writer.writerow(row)
  
  