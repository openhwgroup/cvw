Intractions betwen the dcache and hardware page table walker are complex.
In particular the complications arise when a fault occurs concurrently with a memory operation.

At the begining of very memory operation there are 8 combinations of three signals;
ITBL miss, DTLB miss, and memory operation.  By looking at each combination we
can understand exactly the correct sequence of operations and if the operation
should continue.

It is important to note ITLB misses and faults DO NOT flush a memory operation
in the memory stage.  This is the core reason for the complexity.

| Type | ITLB miss | DTLB miss | mem op |               |
|-------+-----------+-----------+--------+--------------|
|     0 |         0 |         0 |      0 |              |
|     1 |         0 |         0 |      1 |              |
|     2 |         0 |         1 |      0 | Not possible |
|     3 |         0 |         1 |      1 |              |
|     4 |         1 |         0 |      0 |              |
|     5 |         1 |         0 |      1 |              |
|     6 |         1 |         1 |      0 | Not possible |
|     7 |         1 |         1 |      1 |              |


The above table classifies the operations into 8 categories.
2 of the 8 are not possible because a DTLB miss implies a memory operation.
Each (I/D)TLB miss results in either a write to the corresponding TLB or a TLB fault.
To complicate things it is possilbe to have current ITLB and DTLB misses, which
both can result in either a write or a fault. The table belows shows the possible
scenarios and the sequence of operations.


| Type | action 1         | action 2        | action 3        | keep stall? |
|------+------------------+-----------------+-----------------+-------------|
| 1    | D$ handles memop |                 |                 | Yes         |
| 3a   | DTLB Write       | D$ finish memop |                 | Yes         |
| 3b   | DTLB Fault       | Abort memop     |                 | No          |
| 4a   | ITLB write       |                 |                 | No          |
| 4b   | ITLB Fault       |                 |                 | No          |
| 5a   | ITLB Write       | D$ finish memop |                 | Yes         |
| 5b   | ITLB Fault       | D$ finish memop |                 | Yes         |
| 7a   | DTLB Write       | ITLB write      | D$ finish memop | Yes         |
| 7b   | DTLB Write       | ITLB Fault      | D$ finish memop | Yes         |
| 7c   | DTLB Fault       | Abort all       |                 | No          |

Type 1 is a memory operation which either hits in the DTLB or is a physical address.  The
Dcache handles the operation.

Type 3a is a memory operation with a DTLB miss.  The Dcache enters a special set of states
designed to handle the page table walker (HTPW).  Secondly the HPTW takes control over the
LSU via a set of multiplexors in the LSU Arbiter, driving the Dcache with addresses into the
page table.  Interally to the HPTW an FSM checks each node of the Page Table and eventually
signals either a TLB write or a TLB Fault.  In Type 3a the DTLB is written with the leaf
page table entry and returns control of the Dcache back to the IEU.  Now the Dcache finishes
the memory operation using the physical address provided by the TLB.  Note it is crucial
the dcache replay the memory access into the cache's SRAM memory.  As the HPTW sends it 
requests through the Dcache the original memory operation's SRAM lookup will be lost.

Type 3b is similar to the 3a type in that is starts with the same conditions; however the
at the end of the page table walk a fault is detched. Rather than update the TLB the CPU
and the dcache need to be informed about the fault and abort the memory operation.  Unlike
Type 3a the dcache returns directly to STATE_READY and lowers the stall.

Type 4a is the simpliest form of TLB miss as it is an ITLB miss with no memory operation.
The Dcache switches in to the special set of page table states and the HPTW takes control
of the Dcache.  Like with Type 3a the HPTW sends data request through the Dcache and eventually
reads a leaf page table entry (PTE).  At this time the HPTW writes the PTE to the ITLB and
removes the stall as there is not memory operation to do.

Type 4b is also an ITLB miss.  As with 4a the Dcache switches into page table walker mode and reads 
until it finds a leaf or in this case a fault.  The fault is deteched and the Dcaches switches back
to normal mode.

Type 5a is a Type 4a with a current memory operation.  The Dcache first switches to walker mode

