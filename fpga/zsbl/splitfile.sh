# Acquired from here.
# https://stackoverflow.com/questions/3066948/how-to-file-split-at-a-line-number
file_name=$1

# set first K lines:
K=512

# line count (N): 
N=$(wc -l < $file_name)

# length of the bottom file:
L=$(( $N - $K ))

# create the top of file: 
head -n $K $file_name > boot.mem

# create bottom of file: 
tail -n $L $file_name > data.mem
