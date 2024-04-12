# Simulation with Verilator

Different executables will be built for different architecture configurations, e.g., rv64gc, rv32i. A executable can run all the test suites that it can run with `+TEST=<testsuite>`.

This folder contains the following files that help the simulation of Wally with Verilator:

- executables
    - `obj_dir_non_profiling`: non-profiling executables for different configurations
    - `obj_dir_profiling`: profiling executables for different configurations
- [NOT WORKING] `logs`: contains all the logs

## Examples

```shell
# non-profiling mode
make WALLYCONF=rv64gc TEST=arch64i run
# profiling mode
make WALLYCONF=rv64gc TEST=arch64i profile
```