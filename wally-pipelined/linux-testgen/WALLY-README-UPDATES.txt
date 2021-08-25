Many of the scripts to build the linux ram.txt and trace files have changed over the Summer.
Specifically the parsed*.txt files have all been replaced by a single all.txt file which contains
all of the changes concurrent with a specific instruction.
Each line of all.txt is encoded in the following way.

The tokens are space deliminted (limitation the parsing function in system verilog).  This could be
improved with some effort.

<Token> denotes a required token.

()? is an optional set of tokens.  Exactly 0 or 1 of this pattern will occur.
The register update, memory operation, and CSR update are all possilbe but not present on all operations.
()+ is used to denote a variable number of this pattern with at least 1 instance of the pattern.
All integers are in hex and not zero extended.

<PC> <instruction bits> <instruction text> (<GPR> <Reg Number> <Value>)? (<MemR|MemW|MemRW> <Address> <WriteData if valid> <ReadData if valid>)? (<CSR> (<Name> <Value>)+)?

Example

1010 182b283 ld_t0,24(t0) GPR 5 80000000 MemR 1018 0 80000000

PC = 0x1010
Instruction encoding = 0x182_b283
instruction pneumonic (text) = ld_t0,24(t0)
Updating x5 to 0x8000_0000
Memory read at address 0x8000_0000 with read data of 0x8000_0000

CSR updates can occur in more than once for a single instruction.  The multiple sets will appear as pairs of regsiter name followed by value.

**** This trace is generated using the CreateTrace.sh script.

Generation of ram.txt has not changed.  Still use logBuildrootMem.sh

Only the all.txt and ram.txt are required to run modelsim's linux simulation. However there are three additional files will aid
in the debugging process.  logBuildrootMem.sh was modified to also create an object dump from the vmlinux image.  Using
extractFunctionRadix.sh the objdump is converted into two files vmlinux.objdump.addr and vmlinux.objdump.lab which contain
the addresses and labels of global functions in the linux binarary. The linux test bench is configured to uses these two files
to tell the user which function is currently being executed in modelsim.
