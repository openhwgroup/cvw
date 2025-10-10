# Wally Debug Feature List

:x: means we currently have no intention of implementing this feature.
🔶 means we intend to implement this in the future at some point but it is not immediately imperative.

Anything else is intended to be implemented and will be implemented as soon as possible.

General Overview of Implemented Features:
- [x] Halting and Resuming
- [x] Abstract GPR read and write access.
- [x] Abstract CSR read and write access.
- [ ] Stepping
- [ ] Resetting from Debug Module
- [ ] Halt on Reset
- [ ] Trigger Modules 🔶
- [ ] Program buffer 🔶
- [ ] System bus access 🔶

DTM Registers
- [x] idcode
- [x] dtmcs
- [x] dmi 

Debug Module
- [x] DMControl
  - [x] haltreq
  - [x] resumereq
  - [ ] hartreset
  - [ ] ackhavereset
  - [ ] ackunavail :x:
    - I can't imagine there's a scenario where the only hart that exists wouldn't be available, but I need to investigate further, just in case.
  - [ ] hasel :x:
    - By hardcoding this to `0` as well as the hardcoding `hartsello` and `hartselhi` to 0 indicates to the debugger that there is only one hart. If Wally becomes multicore, this will need to be expanded so that we can select many harts. For now, it's not important to implement.
  - [ ] hartsello :x:
  - [ ] hartselhi :x:
  - [ ] setkeepalive
  - [ ] clrkeepalive
  - [ ] setresethaltreq
  - [ ] clrresethaltreq
  - [ ] ndmreset
  - [x] dmactive. Note: Partially implemented. It needs to actually block writes to other debug module registers when set low.
- [x] DMStatus
  - [ ] ndmresetpending
  - [ ] stickyunavail 🔶
  - [ ] impebreak 🔶
  - [ ] allhavereset
  - [ ] anyhavereset
  - [x] allresumeack
  - [x] anyresumeack
  - [ ] allnonexistent
  - [ ] anynonexistent
  - [ ] allunavail :x:
  - [ ] anyunavail :x:
  - [x] allrunning
  - [x] anyrunning
  - [x] allhalted
  - [x] anyhalted
  - [ ] authenticated 🔶
  - [ ] authbusy 🔶
  - [ ] hasresethaltreq
  - [ ] confstrptrvalid :x:
  - [x] version
- [x] Command
- [x] AbstractCS
  - [ ] progbufsize 🔶
  - [ ] busy
    - For clarification, abstract access are near immediate currently, so there are no busy cycles. This is subject to change.
  - [ ] relaxedpriv 🔶
  - [x] cmderr
  - [x] datacount
- [x] Data0
- [x] Data1 (`if XLEN == 64`)
- [ ] HartInfo
- [ ] Hart Array Window Select
- [ ] Hart

Debug Extension
- [x] DCSR
  - [x] Halting
  - [x] Resuming
  - [x] Version field
  - [x] Halt cause updating
  - [ ] Stepping
  - [ ] Stepie 🔶
    - This is for enabling interrupts during stepping. Not as important as implementing stepping itself for now. 
  - [ ] Ebreak to Debug mode in all modes
  - [ ] Stop counters 🔶
  - [ ] Stop time 🔶
  - [ ] extcause :x:
    - Can just be set to 0 for not being implemented and also stays 0 even if cetrig is implemented which is partly what it's needed for. All other values are reserved for future version of the RISCV debug spec.
  - [ ] nmip 🔶
  - [ ] prv
  - [ ] mprven
  - [ ] v 🔶  
- [x] DPC
  - [x] Grabs PC + 4 on Halt
  - [ ] Resumes at DPC value on Resume

- [ ] Sdtrig 🔶
