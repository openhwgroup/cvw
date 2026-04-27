# Coverage Tests

## Hypervisor Unit Tests

`hypervisorUnitTests.S` is a targeted coverage test for the currently implemented parts of Wally's RISC-V Hypervisor extension support. It is intended to run on `rv64gch` against ImperasDV lockstep.

This is not a full H-extension architectural compliance test. In particular, it does not currently attempt a stable checked-in VS/VU execution test because the RTL still has incomplete guest execution and two-stage translation support.

### What It Tests

- Hypervisor CSR read/write and WARL behavior from M-mode:
  - `mtinst`, `mtval2`
  - `hstatus`, `hedeleg`, `hideleg`, `hcounteren`, `hgeie`
  - `htval`, `htinst`, `hgatp`
  - `vsstatus`, `vstvec`, `vsscratch`, `vsepc`, `vscause`, `vstval`, `vsatp`

- Hypervisor interrupt CSR aliasing:
  - `hie` writes reflected in `mie`
  - `vsie` writes reflected through delegated `hie`/`mie` bits
  - `hip`, `hvip`, and `vsip` delegated virtual interrupt aliases

- Timer and environment CSRs:
  - `vstimecmp`
  - `menvcfg` / `henvcfg`
  - `htimedelta`

- Read-only / illegal CSR behavior:
  - `hgeip` write attempts trap as illegal and read back as zero

- HS-mode execution test:
  - enters HS using the shared `WALLY-init-lib.h` ecall privilege-change helper
  - executes `hfence.gvma x0, x0` in HS
  - returns to M-mode and verifies a marker register to confirm the HS block ran

- Hypervisor privileged instruction decode:
  - legal `hfence.vvma x0, x0` in M-mode
  - legal `hfence.gvma x0, x0` in M-mode
  - illegal HFENCE-like encoding with nonzero `rd`, expecting `mcause = 2`

### Known Limitations

- VS/VU execution is not included yet. Earlier experiments could enter virtualized state but were not stable enough for this coverage test because guest execution, trap behavior, and two-stage translation support are still incomplete.
- The test is primarily for implemented CSR behavior, RVVI/Imperas lockstep visibility, and privileged decode coverage.

### Build

From the repository root:

```sh
source ./setup.sh
make -C tests/coverage hypervisorUnitTests.elf hypervisorUnitTests.elf.objdump
```

Useful generated files:

- `tests/coverage/hypervisorUnitTests.elf`
- `tests/coverage/hypervisorUnitTests.elf.objdump`
- `tests/coverage/hypervisorUnitTests.elf.memfile`

### Run With ImperasDV Lockstep

The active target configuration is `rv64gch`.

The `rv64gch` ImperasDV run needs a local configuration file at:

```text
config/deriv/rv64gch/imperas.ic
```

`config/deriv` is ignored by git, so first generate the derived configurations from the repository root:

```sh
make deriv
```

Then create the local Imperas config if needed. Copy and paste the contents of `config/rv64gc/imperas.ic` into `config/deriv/rv64gch/imperas.ic`, then make these edits:

1. Change the variant line from `--variant RV64GCK` to `--variant RV64GCH`.
2. Remove the crypto override block, because this target is `GCH`, not `GCK`:

```text
# Crypto extensions
--override cpu/Zkr=F
--override cpu/Zksed=F
--override cpu/Zksh=F
--override cpu/mnoise_undefined=T
```

If the destination directory or file does not exist yet, create it first:

```sh
mkdir -p config/deriv/rv64gch
touch config/deriv/rv64gch/imperas.ic
```

Then paste in the contents from `config/rv64gc/imperas.ic` and make the two edits above.

From the repository root:

```sh
wsim rv64gch --elf tests/coverage/hypervisorUnitTests.elf --lockstepverbose > hypervisorUnitTests.log 2>&1
```

### Expected Successful Result

A successful lockstep run should report:

```text
Mismatches            : 0
```

The test should write `tohost = 1`, then stop at the normal coverage-test self loop / testbench stop point.

In `--lockstepverbose` output, the HS-mode test can be identified by the instruction trace around `hs_mode_entry`, where Imperas prints the privilege label as `Supervisor`:

```text
0x000000008000545a(hs_mode_entry): Supervisor ...
0x000000008000545e(hs_mode_entry+4): Supervisor 62000073 hfence.gvma x0,x0
```

In this test context, `Supervisor` with virtualization mode `V=0` corresponds to HS-mode.

## Hypervisor Exception Tests

`hypervisorExceptions.S` is a focused companion test for hypervisor exception classification and trap CSR side effects. It currently covers:

- VS-mode virtual-instruction traps for H CSR access, HFENCE, HLV, CBO/envcfg, SATP under `hstatus.VTVM`, and SRET under `hstatus.VTSR`
- `mtval` contents for those virtual-instruction traps
- HS-mode illegal-instruction delegation for `hfence.gvma` when `mstatus.TVM=1`
- `stval` contents for the delegated HS illegal-instruction trap

Build it from the repository root with:

```sh
source ./setup.sh
make -C tests/coverage hypervisorExceptions.elf hypervisorExceptions.elf.objdump
```

Run it with ImperasDV lockstep using the same `rv64gch` setup described above:

```sh
wsim rv64gch --elf tests/coverage/hypervisorExceptions.elf --lockstepverbose > hypervisorExceptions.log 2>&1
```
