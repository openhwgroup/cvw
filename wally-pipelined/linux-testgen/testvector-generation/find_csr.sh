#grep '=>.*csr' $1 | rev | cut -d'	' -f1 | rev | tee >(cut -d',' -f1) | cut -d',' -f2 | grep -Ev 'a[0-7]|t[0-6]|zero|[0-8]' | sort | uniq | paste -s -d, -
grep 'csr' /mnt/scratch/riscv_decodepc_threads/riscv_decodepc.txt.disassembly | rev | cut -d' ' -f1 | rev | tee >(cut -d',' -f1 | sort -u) >(cut -d',' -f2 | sort -u) | (cut -d',' -f3 | sort -u) | sort -u  | paste -s -d, -
