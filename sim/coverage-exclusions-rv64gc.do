#///////////////////////////////////////////
#// coverage-exclusions-rv64gc.do
#//
#// Written: David_Harris@hmc.edu 19 March 2023
#//
#// Purpose: Set of exclusions from coverage for rv64gc configuration
#//          For example, signals hardwired to 0 should not be checked for toggle coverage
#//
#// A component of the CORE-V-WALLY configurable RISC-V project.
#// 
#// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
#//
#// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#//
#// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
#// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
#// may obtain a copy of the License at
#//
#// https://solderpad.org/licenses/SHL-2.1/
#//
#// Unless required by applicable law or agreed to in writing, any work distributed under the 
#// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
#// either express or implied. See the License for the specific language governing permissions 
#// and limitations under the License.
#////////////////////////////////////////////////////////////////////////////////////////////////

# This file should be a last resort.  It's preferable to put 
# // coverage off 
# statements inline with the code whenever possible.
# a hack to describe coverage exclusions without hardcoding linenumbers:
do GetLineNum.do

# LZA (i<64) statement confuses coverage tool 
# DH 4/22/23: Exclude all LZAs
coverage exclude -srcfile lzc.sv 

# DH 4/22/23: FDIVSQRT can't go directly from done to busy again
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtfsm -ftrans state DONE->BUSY
# DH 4/22/23: The busy->idle transition only occurs if a FlushE occurs while the divider is busy.  The flush is caused by a trap or return,
# which won't happen while the divider is busy. 
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtfsm -ftrans state BUSY->IDLE

### Exclude D$ states and logic for the I$ instance
# This is cleaner than trying to set an I$-specific pragma in cachefsm.sv (which would exclude it for the D$ instance too)
# Also exclude the write line to ready transition for the I$ since we can't get a flush during this operation.
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -fstate CurrState STATE_FLUSH STATE_FLUSH_WRITEBACK STATE_FLUSH_WRITEBACK STATE_WRITEBACK
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -ftrans CurrState STATE_WRITE_LINE->STATE_READY
# exclude unused transitions from case statement. Unfortunately the whole branch needs to be excluded I think. Expression coverage should still work.
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache state-case"] -item b 1
# exclude branch/condition coverage: LineDirty if statement
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache FETCHStatement"] -item bc 1
# exclude the unreachable logic
set start [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag-start: icache case"]
set end [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag-end: icache case"]
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange $start-$end
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache WRITEBACKStatement"]
# exclude Atomic Operation logic
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: cache AnyMiss"] -item e 1 -fecexprrow 6
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache storeAMO1"] -item e 1 -fecexprrow 2-4
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache AnyUpdateHit"] -item e 1 -fecexprrow 2
# cache write logic
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache CacheW"] -item e 1 -fecexprrow 4
# output signal logic
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache StallStates"] -item e 1 -fecexprrow 8 12 14
set start [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag-start: icache flushdirtycontrols"]
set end [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag-end: icache flushdirtycontrols"]
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange $start-$end
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache CacheBusW"]
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache SelAdrCauses"] -item e 1 -fecexprrow 4 10
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: icache CacheBusRCauses"] -item e 1 -fecexprrow 1-2 12
# cache.sv AdrSelMux and CacheBusAdrMux, excluding unhit Flush branch
coverage exclude -scope /dut/core/ifu/bus/icache/icache/AdrSelMux -linerange [GetLineNum ../src/generic/mux.sv "exclusion-tag: mux3"] -item b 1
coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheBusAdrMux -linerange [GetLineNum ../src/generic/mux.sv "exclusion-tag: mux3"] -item b 1 3
# CacheWay Dirty logic. -scope does not accept wildcards.
set numcacheways 4
for {set i 0} {$i < $numcacheways} {incr i} {
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ../src/cache/cacheway.sv "exclusion-tag: icache SetDirtyWay"] -item e 1
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ../src/cache/cacheway.sv "exclusion-tag: icache SelectedWiteWordEn"] -item e 1 -fecexprrow 4 6
    # below: flushD can't go high during an icache write b/c of pipeline stall
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ../src/cache/cacheway.sv "exclusion-tag: icache SetValidEN"] -item e 1 -fecexprrow 4
}

## D$ Exclusions.
# InvalidateCache is I$ only:
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: dcache InvalidateCheck"] -item b 2
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: dcache InvalidateCheck"] -item s 1
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: dcache CacheEn"] -item e 1 -fecexprrow 12
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ../src/cache/cachefsm.sv "exclusion-tag: cache AnyMiss"] -item e 1 -fecexprrow 4
set numcacheways 4
for {set i 0} {$i < $numcacheways} {incr i} {
    coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/CacheWays[$i] -linerange [GetLineNum ../src/cache/cacheway.sv "exclusion-tag: dcache invalidateway"] -item be 1 -fecexprrow 4
}
# D$ writeback, flush, write_line, or flush_writeback states can't be cancelled by a flush
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -ftrans CurrState STATE_WRITEBACK->STATE_READY STATE_FLUSH->STATE_READY STATE_WRITE_LINE->STATE_READY STATE_FLUSH_WRITEBACK->STATE_READY


# Excluding peripherals as sources of instructions for the ifu
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/clintdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/gpiodec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/uartdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/plicdec

# Excluding so far un-used instruction sources for the ifu
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/bootromdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/uncoreramdec


#Excluding the bootrom, uncoreran, and clint as sources for the lsu
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/bootromdec


#Excluding signals in lsu: clintdec and uncoreram accept all sizes so 'SizeValid' will never be 0
set line [GetLineNum ../src/mmu/adrdec.sv "& SizeValid"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/clintdec -linerange $line-$line -item e 1 -fecexprrow 5
set line [GetLineNum ../src/mmu/adrdec.sv "& SizeValid"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/uncoreramdec -linerange $line-$line -item e 1 -fecexprrow 5

# Excluding signals in lsu: the lsu never executes instructions so 'ExecuteAccess' will never be 1
set line [GetLineNum ../src/mmu/pmachecker.sv "AccessRWX ="]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 6
set line [GetLineNum ../src/mmu/pmachecker.sv "ReadAccessM \\| ExecuteAccessF"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 4

# Excluding ReadAccess and WriteAccess signal in the ifu that will never be true
set line [GetLineNum ../src/mmu/pmachecker.sv "ReadAccessM \\| WriteAccessM"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2 4
set line [GetLineNum ../src/mmu/pmachecker.sv "WriteAccessM \\| ExecuteAccessF"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 1-5
set line [GetLineNum ../src/mmu/pmachecker.sv "ReadAccessM \\| ExecuteAccessF"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 1-3

# Excluding reset and clear for impossible case in the wficountreg in privdec
set line [GetLineNum ../src/generic/flop/floprc.sv "reset \\| clear"]
coverage exclude -scope /dut/core/priv/priv/pmd/wfi/wficountreg -linerange $line-$line -item c 1 -feccondrow 2
