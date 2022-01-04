Code Improvements
David_Harris@hmc.edu 15 Nov 2021

Remove depricated N-Mode stuff, including sd in privileged.sv
Look at version 13? of privileged spec.  What should we add?
Reduce size of repo

Timing optimization (Kip, Shreya)
    Use ForwardSrcA instead of SrcA for mdu / fpu
    Look at TLB -> PMP -> Access Fault -> Trap
        may be able to precompute
    Try flattening, see speedup
    Take out Mul synthesis modes

RISCV-Arch-tests 
    Port MMU tests

FPU
    spec difference on signaling/quiet NAN propagation
    SRT Div/Sqrt (Katherine, maybe Udeema)
    Get riscv-arch-tests running (James, Katherine)
    Get testfloat all passing
    Katherine's FPU optimization

Linux Boot
    Ben, Skyler

FPGA Boot Linux (Ross)

IFU/LSU
    Block diagrams, code cleanup
    Burst mode transfers to speed up IPC
    Implications of no byte enables on subword write - do stores take extra cycle, should this be avoided?

28 nm Implementation
    Install processor  
    Memory macros
    Synthesis & PNR
    Timing review

Benchmarking

Flow
    Kevin Kim has a makefile to check out and build all the pieces.  Make sure this is running; change Repo README to use his makefile

Code cleanup    
    .* fixes by thanksgiving
    Rename top-level modules to abbreviations
    Rename muldiv to mdu
    Get rid of DESIGN_COMPILER flag and redundant multiplier