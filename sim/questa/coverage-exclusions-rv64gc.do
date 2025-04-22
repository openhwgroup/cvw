#///////////////////////////////////////////
#// coverage-exclusions-rv64gc.do
#//
#// Written: David_Harris@hmc.edu 19 March 2023
#//
#// Purpose: Set of exclusions from coverage for rv64gc configuration
#//          For example, signals hardwired to 0 should not be checked for toggle coverage
#//
#// A component of the CORE-V-WALLY configurable RISC-V project.
#// https://github.com/openhwgroup/cvw
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

set WALLY $::env(WALLY)
set SRC ${WALLY}/src

# a hack to describe coverage exclusions without hardcoding linenumbers:
do GetLineNum.do

# LZA (i<64) statement confuses coverage tool 
# DH 4/22/23: Exclude all LZAs
coverage exclude -srcfile lzc.sv 

#################
# FPU Exclusions
#################
# DH 4/22/23: FDIVSQRT can't go directly from done to busy again
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtfsm -ftrans state DONE->BUSY
# DH 4/22/23: The busy->idle transition only occurs if a FlushE occurs while the divider is busy.  The flush is caused by a trap or return,
# which won't happen while the divider is busy. 
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtfsm -ftrans state BUSY->IDLE
# All Memory-stage stalls have resolved by time fdivsqrt finishes regular operation in this configuration, so can't test StallM
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtfsm -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtfsm.sv "exclusion-tag: fdivsqrtfsm stallm"] -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtfsm -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtfsm.sv "exclusion-tag: fdivsqrtfsm stallm"] -item s 1
# Division by zero never sets sticky/guard/overflow/round to cause inexact or underflow result, but check out of paranoia
coverage exclude -scope /dut/core/fpu/fpu/postprocess/flags -linerange [GetLineNum ${SRC}/fpu/postproc/flags.sv "assign FpInexact"] -item e 1 -fecexprrow 15 
coverage exclude -scope /dut/core/fpu/fpu/postprocess/flags -linerange [GetLineNum ${SRC}/fpu/postproc/flags.sv "assign Underflow"] -item e 1 -fecexprrow 22
# Convert int to fp will never underflow
coverage exclude -scope /dut/core/fpu/fpu/postprocess/cvtshiftcalc -linerange [GetLineNum ${SRC}/fpu/postproc/cvtshiftcalc.sv "assign CvtResUf"] -item e 1 -fecexprrow 4
# without Q support, the FMT field is guaranteed to be 00, 01, or 10 
coverage exclude -scope /dut/core/fpu/fpu/fctrl -linerange [GetLineNum ${SRC}/fpu/fctrl.sv "fmv int to fp"] -item 1 3 5
coverage exclude -scope /dut/core/fpu/fpu/fctrl -linerange [GetLineNum ${SRC}/fpu/fctrl.sv "fmv fp to int"] -item 1 3 5
# j0 can only be 1 in iteration 0, j1 can only be 1 in iteration 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[0]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign sqrtspecial"] -item e 1 -fecexprrow 4 6
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[1]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign sqrtspecial"] -item e 1 -fecexprrow 6
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[2]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign sqrtspecial"] -item e 1 -fecexprrow 1 2 4 6
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[3]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign sqrtspecial"] -item e 1 -fecexprrow 1 2 4 6
# outside of iterations 1 and 0, (j0 | j1) is always 0 so sqrtspecial is always 0
# need to exclude scenarios where sqrtspecial is 1 for the ternary operators that assign mk2, mk1, mk0, and mkm1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[2]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mk2"]  -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[2]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mk1"]  -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[2]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mk0"]  -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[2]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mkm1"] -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[3]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mk2"]  -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[3]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mk1"]  -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[3]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mk0"]  -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[3]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mkm1"] -item b 1
# outside of iteration 0, j0 is always 0 so the ternary operator that assigns mkj1 cannot be fully covered
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[3]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mkj1"] -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[2]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mkj1"] -item b 1
coverage exclude -scope /dut/core/fpu/fpu/fdivsqrt/fdivsqrtiter/iterations[1]/stage/fdivsqrtstage/uslc4 -linerange [GetLineNum ${SRC}/fpu/fdivsqrt/fdivsqrtuslc4cmp.sv "assign mkj1"] -item b 1

##################
# Cache Exclusions
##################

### Exclude D$ states and logic for the I$ instance
# This is cleaner than trying to set an I$-specific pragma in cachefsm.sv (which would exclude it for the D$ instance too)
# Also exclude the write line to ready transition for the I$ since we can't get a flush during this operation.
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -fstate CurrState STATE_FLUSH STATE_FLUSH_WRITEBACK STATE_FLUSH_WRITEBACK STATE_WRITEBACK
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -ftrans CurrState STATE_WRITE_LINE->STATE_ACCESS STATE_FETCH->STATE_ACCESS
# exclude unused transitions from case statement. Unfortunately the whole branch needs to be excluded I think. Expression coverage should still work.
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache state-case"] -item b 1
# I$ does not flush
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache FlushCache"] -item e 1 -fecexprrow 2
coverage exclude -scope /dut/core/ifu/bus/icache/icache/AdrSelMuxLRU -item b 1
# exclude branch/condition coverage: LineDirty if statement
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache FETCHStatement"] -item bc 1
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache FLUSHStatement"] -item bs 1
# exclude the unreachable logic
set start [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag-start: icache case"]
set end [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag-end: icache case"]
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange $start-$end
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache WRITEBACKStatement"]
# exclude Atomic Operation logic
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: cache AnyMiss"] -item e 1 -fecexprrow 6
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache storeAMO1"] -item e 1 -fecexprrow 2-4
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache AnyUpdateHit"] -item e 1 -fecexprrow 2
# cache write logic
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache CacheW"] -item e 1 -fecexprrow 4
# output signal logic
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache StallStates"] -item e 1 -fecexprrow 8 12 14
set start [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag-start: icache flushdirtycontrols"]
set end [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag-end: icache flushdirtycontrols"]
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange $start-$end
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache CacheBusW"]
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache SelAdrCauses"] -item e 1 -fecexprrow 4 10
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache SelAdrTag"] -item e 1 -fecexprrow 8 
coverage exclude -scope /dut/core/ifu/bus/icache/icache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: icache CacheBusRCauses"] -item e 1 -fecexprrow 1-2 12

# cache.sv AdrSelMuxData and AdrSelMuxTag and CacheBusAdrMux, excluding unhit Flush branch
coverage exclude -scope /dut/core/ifu/bus/icache/icache/AdrSelMuxData -linerange [GetLineNum ${SRC}/generic/mux.sv "exclusion-tag: mux3"] -item b 1
coverage exclude -scope /dut/core/ifu/bus/icache/icache/AdrSelMuxTag -linerange [GetLineNum ${SRC}/generic/mux.sv "exclusion-tag: mux3"] -item b 1
coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheBusAdrMux -linerange [GetLineNum ${SRC}/generic/mux.sv "exclusion-tag: mux3"] -item b 1 3
# CacheWay Dirty logic. -scope does not accept wildcards.
set numcacheways 4
for {set i 0} {$i < $numcacheways} {incr i} {
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: icache SetDirtyWay"] -item e 1
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: icache SelectedWiteWordEn"] -item e 1 -fecexprrow 4 6
    # below: flushD can't go high during an icache write b/c of pipeline stall
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: cache SetValidEN"] -item e 1 -fecexprrow 4
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: cache ClearValidEN"] -item e 1 -fecexprrow 4
    # No CMO to clear valid bits of I$
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "// exclusion-tag: icache ClearValidBits"] 
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "// exclusion-tag: icache ClearValidWay"] -item e 1
    # No dirty ways in read-only I$
    coverage exclude -scope /dut/core/ifu/bus/icache/icache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "// exclusion-tag: icache DirtyWay"] -item e 1
}
# I$ buscachefsm does not perform atomics or write/writeback; HREADY is always 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicReadData"]
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicElse"] -item s 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicPhase"]
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicWait"] -item bs 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm FetchWriteback"] -item b 2
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm FetchWriteback"] -item s 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm WritebackWriteback"] 
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm WritebackWriteback2"] -item bs 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY4"] -item bs 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY6"] -item bs 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADYread"] -item c 1 -feccondrow 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm FetchWriteback"] -item c 1 -feccondrow 1,2,3,4,6
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY4"] -item c 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY6"] -item c 1
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "assign HTRANS"] -item c 1 -feccondrow 5
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "assign BeatCntEn"] -item e 1 -fecexprrow 4
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "assign CacheAccess"] -item e 1 -fecexprrow 4
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "assign BusStall"] -item e 1 -fecexprrow 10,12,18
coverage exclude -scope /dut/core/ifu/bus/icache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "assign CacheBusAck"] -item e 1 -fecexprrow 3

## D$ Exclusions.
# InvalidateCache is I$ only:
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: dcache InvalidateCheck"] -item b 2
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: dcache InvalidateCheck"] -item s 1
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: dcache CacheEn"] -item e 1 -fecexprrow 12
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -linerange [GetLineNum ${SRC}/cache/cachefsm.sv "exclusion-tag: cache AnyMiss"] -item e 1 -fecexprrow 4
set numcacheways 4
for {set i 0} {$i < $numcacheways} {incr i} {
    coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: dcache invalidateway"] -item bes 1 -fecexprrow 4
    # InvalidateCacheDelay is always 0 for D$ because it is flushed, not invalidated
    coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: dcache HitWay"] -item 3 1 -fecexprrow 2

    # FlushStage=1 will never happen when SetValidWay=1 since a pipeline stall is asserted by the cache in the fetch stage, which happens before
    # going into the WRITE_LINE state (and asserting SetValidWay). No TrapM can fire and since StallW is high, a stallM caused by WFIStallM would not cause a flushW.
    coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: cache SetValidEN"] -item e 1 -fecexprrow 4
    coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: cache ClearValidEN"] -item e 1 -fecexprrow 4
# Not right; other ways can get flushed and dirtied simultaneously    coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/CacheWays[$i] -linerange [GetLineNum ${SRC}/cache/cacheway.sv "exclusion-tag: cache UpdateDirty"] -item c 1 -feccondrow 6
}
# D$ writeback, flush, write_line, or flush_writeback states can't be cancelled by a flush
coverage exclude -scope /dut/core/lsu/bus/dcache/dcache/cachefsm -ftrans CurrState STATE_WRITEBACK->STATE_ACCESS STATE_FLUSH->STATE_ACCESS STATE_WRITE_LINE->STATE_ACCESS STATE_FLUSH_WRITEBACK->STATE_ACCESS 

####################
# Unused / illegal peripheral accesses
####################

# Excluding peripherals as sources of instructions for the ifu
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/clintdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/gpiodec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/uartdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/plicdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/dtimdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/iromdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/ddr4dec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/sdcdec

# PMA Regions 1, 2, and 3 (dtim, irom, ddr4) are never used in the rv64gc configuration, so exclude coverage
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "exclusion-tag: unused-atomic"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2,4
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2,4
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "exclusion-tag: unused-tim"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2,4
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2,4
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "exclusion-tag: unused-cachable"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "exclusion-tag: unused-idempotent"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2,4,6
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2,4,6,8

# Excluding so far un-used instruction sources for the ifu
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/bootromdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/uncoreramdec
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker/adrdecs/spidec

# The following peripherals are always supported
set line [GetLineNum ${SRC}/mmu/adrdec.sv "exclusion-tag: adrdecSel"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/bootromdec -linerange $line-$line -item e 1 -fecexprrow 3,7
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/gpiodec -linerange $line-$line -item e 1 -fecexprrow 3
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/uartdec -linerange $line-$line -item e 1 -fecexprrow 3
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/plicdec -linerange $line-$line -item e 1 -fecexprrow 3
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/spidec -linerange $line-$line -item e 1 -fecexprrow 3

#Excluding signals in lsu: clintdec and uncoreram accept all sizes so 'SizeValid' will never be 0
set line [GetLineNum ${SRC}/mmu/adrdec.sv "& SizeValid"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/clintdec -linerange $line-$line -item e 1 -fecexprrow 5
set line [GetLineNum ${SRC}/mmu/adrdec.sv "& SizeValid"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/uncoreramdec -linerange $line-$line -item e 1 -fecexprrow 5

# set line [GetLineNum ${SRC}/mmu/adrdec.sv "& Supported"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/dtimdec
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/iromdec
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/ddr4dec
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker/adrdecs/sdcdec

# No DTIM or IROM
coverage exclude -scope /dut/core/ifu/bus/icache/UnCachedDataMux -linerange [GetLineNum ${SRC}/generic/mux.sv "exclusion-tag: mux3"] -item b 1
coverage exclude -scope /dut/core/lsu/bus/dcache/UnCachedDataMux -linerange [GetLineNum ${SRC}/generic/mux.sv "exclusion-tag: mux3"] -item b 1

####################
# Unused access types due to sharing IFU and LSU logic
####################

## The lsu never executes instructions so 'ExecuteAccessF' will never be 1
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "AccessRWXC ="]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 6
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "ReadAccessM \\| ExecuteAccessF"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 4
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "ExecuteAccessF & PMAAccessFault"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2
set line [GetLineNum ${SRC}/mmu/mmu.sv "ExecuteAccessF \\| ReadAccessM"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu -linerange $line-$line -item e 1 -fecexprrow 2
set line [GetLineNum ${SRC}/mmu/mmu.sv "TLBPageFault & ExecuteAccessF"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu -linerange $line-$line -item e 1 -fecexprrow 1,2,4
set line [GetLineNum ${SRC}/mmu/mmu.sv "PMAInstrAccessFaultF    \\|"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu -linerange $line-$line -item e 1 -fecexprrow 2,4,5,6
set line [GetLineNum ${SRC}/mmu/pmpchecker.sv "EnforcePMP & ExecuteAccessF"]
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmp/pmpchecker -linerange $line-$line -item e 1 -fecexprrow 1,2,4,5,6
set line [GetLineNum ${SRC}/mmu/pmpchecker.sv "EnforcePMP & ExecuteAccessF"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange $line-$line -item e 1 -fecexprrow 3 


## The IFU has ReadAccess = WriteAccess = 0 and ExecuteAccess = 1 hardwired, so exclude alternatives
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "ReadAccessM \\| WriteAccessM"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2 4
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "WriteAccessM \\| ExecuteAccessF"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 1-5
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "ReadAccessM \\| ExecuteAccessF"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 1-3
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "ExecuteAccessF & PMAAccessFault"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 1
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "ReadAccessM & ~WriteAccessM & PMAAccessFault"]
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 2-4
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "PMAStoreAmoAccessFaultM ="] 
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line
set line [GetLineNum ${SRC}/mmu/pmachecker.sv "AccessRWXC \\| AtomicAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu/pmachecker -linerange $line-$line -item e 1 -fecexprrow 3
set line [GetLineNum ${SRC}/mmu/mmu.sv "ExecuteAccessF \\| ReadAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 1,3,4
set line [GetLineNum ${SRC}/mmu/mmu.sv "ReadAccessM & ~WriteAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 2-4
set line [GetLineNum ${SRC}/mmu/mmu.sv "assign AtomicMisalignedCausesAccessFaultM"] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1
set line [GetLineNum ${SRC}/mmu/mmu.sv "DataMisalignedM & WriteAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 1,2,4
set line [GetLineNum ${SRC}/mmu/mmu.sv "TLBPageFault & ExecuteAccessF"] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 3
set line [GetLineNum ${SRC}/mmu/mmu.sv "TLBPageFault & ReadNoAmoAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 1,2,4
set line [GetLineNum ${SRC}/mmu/mmu.sv "StoreAmoPageFaultM \="] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 1,2,4
set line [GetLineNum ${SRC}/mmu/mmu.sv "DataMisalignedM & ReadNoAmoAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 1,2,4
set line [GetLineNum ${SRC}/mmu/pmpchecker.sv "EnforcePMP & WriteAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange $line-$line -item e 1 -fecexprrow 1,2,4,5,6
set line [GetLineNum ${SRC}/mmu/pmpchecker.sv "EnforcePMP & ReadAccessM"] 
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange $line-$line -item e 1 -fecexprrow 1,2,4,5,6
set line [GetLineNum ${SRC}/mmu/mmu.sv "LoadAccessFaultM     \="] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 2,4,5,6
set line [GetLineNum ${SRC}/mmu/mmu.sv "StoreAmoAccessFaultM \="] 
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line -item e 1 -fecexprrow 2,4,5,6
set line [GetLineNum ${SRC}/mmu/tlb/tlbcontrol.sv "ReadAccess \\| WriteAccess"] 
coverage exclude -scope /dut/core/ifu/immu/immu/tlb/tlb/tlbcontrol -linerange $line-$line -item e 1 -fecexprrow 1,3,4
set line [GetLineNum ${SRC}/mmu/tlb/tlbcontrol.sv "CAMHit & TLBAccess"] 
coverage exclude -scope /dut/core/ifu/immu/immu/tlb/tlb/tlbcontrol -linerange $line-$line -item e 1 -fecexprrow 3
set line [GetLineNum ${SRC}/mmu/tlb/tlbcontrol.sv "~CAMHit & TLBAccess"] 
coverage exclude -scope /dut/core/ifu/immu/immu/tlb/tlb/tlbcontrol -linerange $line-$line -item e 1 -fecexprrow 3

# IMMU only makes word-sized accesses
set line [GetLineNum ${SRC}/mmu/mmu.sv "exclusion-tag: immu-wordaccess"] 
set line2 [expr $line + 6 ]
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line2 -item e 1 -fecexprrow 4
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line2 -item b 1
coverage exclude -scope /dut/core/ifu/immu/immu -linerange $line-$line2 -item s 1

# IMMU never disables translations
coverage exclude -scope /dut/core/ifu/ifu/immu/immu/tlb/tlb/tlbcontrol -linerange [GetLineNum ${SRC}/mmu/tlb/tlbcontrol.sv "assign Translate"] -item e 1 -fecexprrow 2
coverage exclude -scope /dut/core/ifu/ifu/immu/immu/tlb/tlb/tlbcontrol -linerange [GetLineNum ${SRC}/mmu/tlb/tlbcontrol.sv "assign UpdateDA"] -item e 1 -fecexprrow 5
# never reaches this when ENVCFG_ADUE_1 because HPTW updates A bit first
coverage exclude -scope /dut/core/ifu/ifu/immu/immu/tlb/tlb/tlbcontrol -linerange [GetLineNum ${SRC}/mmu/tlb/tlbcontrol.sv "assign PrePageFault"] -item e 1 -fecexprrow 18 




###############
# HPTW exclusions
###############

# RV64GC HPTW never starts at L1_ADR
set line [GetLineNum ${SRC}/mmu/hptw.sv "InitialWalkerState == L1_ADR"] 
coverage exclude -scope /dut/core/lsu/lsu/hptw/hptw -linerange $line-$line -item c 1 -feccondrow 2

# Never possible to get a page fault when neither reading nor writing
set line [GetLineNum ${SRC}/mmu/hptw.sv "assign HPTWLoadPageFault"] 
coverage exclude -scope /dut/core/lsu/lsu/hptw/hptw -linerange $line-$line -item e 1 -fecexprrow 7
 
# Never possible to get a store page fault from an ITLB walk
set line [GetLineNum ${SRC}/mmu/hptw.sv "assign HPTWStoreAmoPageFault"] 
coverage exclude -scope /dut/core/lsu/lsu/hptw/hptw -linerange $line-$line -item e 1 -fecexprrow 3
 
# Never possible to get Access = 0 on a nonleaf PTE with no OtherPageFault (because InvalidRead/Write will be 1 on the nonleaf)
set line [GetLineNum ${SRC}/mmu/hptw.sv "assign HPTWUpdateDA"] 
coverage exclude -scope /dut/core/lsu/lsu/hptw/hptw -linerange $line-$line -item e 1 -fecexprrow 3
 
###############
# Other exclusions
###############

# IMMU PMP does not support CBO instructions
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange [GetLineNum ${SRC}/mmu/pmpchecker.sv "exclusion-tag: immu-pmpcbom"] 
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange [GetLineNum ${SRC}/mmu/pmpchecker.sv "exclusion-tag: immu-pmpcboz"] 
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange [GetLineNum ${SRC}/mmu/pmpchecker.sv "exclusion-tag: immu-pmpcboaccess"] 

# IMMU PMP only makes 4-byte accesses
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange [GetLineNum ${SRC}/mmu/pmpchecker.sv "SizeBytesMinus1 = 3'd0"]  -item bs 1
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange [GetLineNum ${SRC}/mmu/pmpchecker.sv "SizeBytesMinus1 = 3'd1"]  -item bs 1
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker -linerange [GetLineNum ${SRC}/mmu/pmpchecker.sv "SizeBytesMinus1 = 3'd7"]  -item bs 1

# No irom
set line [GetLineNum ${SRC}/ifu/ifu.sv "~ITLBMissF & ~CacheableF & ~SelIROM"] 
coverage exclude -scope /dut/core/ifu -linerange $line-$line -item c 1 -feccondrow 6
set line [GetLineNum ${SRC}/ifu/ifu.sv "~ITLBMissF & CacheableF & ~SelIROM"] 
coverage exclude -scope /dut/core/ifu -linerange $line-$line -item c 1 -feccondrow 4

# no DTIM 
set line [GetLineNum ${SRC}/lsu/lsu.sv "assign BusRW"] 
coverage exclude -scope /dut/core/lsu -linerange $line-$line -item c 1 -feccondrow 4
set line [GetLineNum ${SRC}/lsu/lsu.sv "assign CacheRWM"] 
coverage exclude -scope /dut/core/lsu -linerange $line-$line -item c 1 -feccondrow 4

# Excluding reset and clear for impossible case in the wficountreg in privdec
#set line [GetLineNum ${SRC}/generic/flop/floprc.sv "reset \\| clear"]
#coverage exclude -scope /dut/core/priv/priv/pmd/wfi/wficountreg -linerange $line-$line -item c 1 -feccondrow 2

# Exclude system reset case in ebu
set line [GetLineNum ${SRC}/ebu/ebufsmarb.sv "BeatCounter\\("]
coverage exclude -scope /dut/core/ebu/ebu/ebufsmarb -linerange $line-$line -item e 1 -fecexprrow 1
set line [GetLineNum ${SRC}/ebu/ebufsmarb.sv "FinalBeatReg\\("]
coverage exclude -scope /dut/core/ebu/ebu/ebufsmarb -linerange $line-$line -item e 1 -fecexprrow 1

set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicElse"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line  -item bc 1

set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicWait"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item bc 1

# The WritebackWriteback and FetchWriteback support back to back pipelined cache writebacks and fetch then
# writebacks.  The cache never issues these type of requests.
set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm WritebackWriteback"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item bc 2

set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm FetchWriteback"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item bc 2

# FetchWait never occurs because HREADY is never 0.
set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm FetchWait"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item bc 1

# all of these HREADY exclusions occur because HREADY is always 1.  The ram_ahb module never stalls.
set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY0"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 1

#set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY1"]
#coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 1

#set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY2"]
#coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 1

set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY3"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 4

set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY4"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 1
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 3

set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY5"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 1

set line [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm HREADY6"]
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 1
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange $line-$line -item c 1 -feccondrow 5

coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "assign CacheBusAck"] -item e 1 -fecexprrow 5

coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicElse"] -item s 1
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -linerange [GetLineNum ${SRC}/ebu/buscachefsm.sv "exclusion-tag: buscachefsm AtomicWait"] -item s 1

# these transitions will not happen
coverage exclude -scope /dut/core/lsu/bus/dcache/ahbcacheinterface/AHBBuscachefsm -ftrans CurrState DATA_PHASE->ADR_PHASE ATOMIC_READ_DATA_PHASE->ADR_PHASE ATOMIC_PHASE->ADR_PHASE

# TLB not recently used never has all RU bits = 1 because it will then clear all to 0
# This is a blunt instrument; perhaps there is a more graceful exclusion
coverage exclude -srcfile priorityonehot.sv 

# Excluding pmpadrdecs[0] coverage case for PAgePMPAdrIn being hardwired to 1
coverage exclude -scope /dut/core/ifu/immu/immu/pmp/pmpchecker/pmp/pmpadrdecs[0] -linerange [GetLineNum ${SRC}/mmu/pmpadrdec.sv "exclusion-tag: PAgePMPAdrIn"] -item e 1 -fecexprrow 1
coverage exclude -scope /dut/core/lsu/dmmu/dmmu/pmp/pmpchecker/pmp/pmpadrdecs[0] -linerange [GetLineNum ${SRC}/mmu/pmpadrdec.sv "exclusion-tag: PAgePMPAdrIn"] -item e 1 -fecexprrow 1

# StallD always equals StallF so LatestUnstalledD is always 0
coverage exclude -scope /dut/core/hzu -linerange [GetLineNum ${SRC}/hazard/hazard.sv "StallD always equals StallF"] -item 1 4
coverage exclude -scope /dut/core/hzu -linerange [GetLineNum ${SRC}/hazard/hazard.sv "coverage tag: LatestUnstalledD always 0"] -item e 1 -fecexprrow 2

####################
# Privileged
####################

# Instruction Misaligned never asserted because compresssed instructions are accepted
coverage exclude -scope /dut/core/priv/priv/trap -linerange [GetLineNum ${SRC}/privileged/trap.sv "assign ExceptionM"] -item e 1 -fecexprrow 2

# Attempting to access fflags, frm, fcsr with mstatus.FS = 0 traps, so checking for (STATUS_FS != 2'b00)
# before enabling writes to these CSRs is redundant and uncoverable
coverage exclude -scope /dut/core/priv/priv/csr/csru/csru -linerange [GetLineNum ${SRC}/privileged/csru.sv "assign WriteFRMM"] -item e 1 -fecexprrow 3
coverage exclude -scope /dut/core/priv/priv/csr/csru/csru -linerange [GetLineNum ${SRC}/privileged/csru.sv "assign WriteFFLAGSM"] -item e 1 -fecexprrow 3

# Attempted writes to the nonextistant MTIME register trap, so WriteHPMCOUNTERM cannot be set for that address (0xb01)
coverage exclude -scope /dut/core/priv/priv/csr/counters/counters/cntr[1] -linerange [GetLineNum ${SRC}/privileged/csrc.sv "MTIME traps"] -item e 1 -fecexprrow 2 4
coverage exclude -scope /dut/core/priv/priv/csr/counters/counters/cntr[1] -linerange [GetLineNum ${SRC}/privileged/csrc.sv "assign NextHPMCOUNTERM"] -item b 1

# attempting to write stimecmp with STCE=0 traps, causing CSRSWriteM to go low 
coverage exclude -scope /dut/core/priv/priv/csr/csrs/csrs -linerange [GetLineNum ${SRC}/privileged/csrs.sv "assign WriteSTIMECMPM"] -item e 1 -fecexprrow 5

# mode != m_mode and TVM = 1 causes a trap, causing CSRSWriteM to go low
coverage exclude -scope /dut/core/priv/priv/csr/csrs/csrs -linerange [GetLineNum ${SRC}/privileged/csrs.sv "assign WriteSATPM"] -item e 1 -fecexprrow 5 8

####################
# EBU
####################

# Exclude EBU Beat Counter flop because it is only idle when bus has multicycle latency, but rv64gc has single cycle latency
coverage exclude -scope /dut/core/ebu/ebu/ebufsmarb/BeatCounter/cntrflop




