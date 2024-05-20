# Simulation with Verilator

Different executables will be built for different architecture configurations, e.g., rv64gc, rv32i. A executable can run all the test suites that it can run with `+TEST=<testsuite>`.

Demand:

- Avoid unnecessary compilation by sharing the same executable for a specific configuration
    - executables are stored in `obj_dir_non_profiling` and `obj_dir_profiling` correspondingly
- Wsim should support `-s verilator` option and run simulation with Verilator.

## Folder Structure

This folder contains the following files that help the simulation of Wally with Verilator:

- Makefile: simplify the usage with Verialtor
- executables
    - `obj_dir_non_profiling`: non-profiling executables for different configurations
    - `obj_dir_profiling`: profiling executables for different configurations
- logs in `logs` and `logs_profiling` correspondingly
- [NOT WORKING] `logs`: contains all the logs

## Examples

```shell
# non-profiling mode
make WALLYCONF=rv64gc TEST=arch64i run
# profiling mode
make WALLYCONF=rv64gc TEST=arch64i profile

# remove all the temporary files, including executables and logs
make clean
```