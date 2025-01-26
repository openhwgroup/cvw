Jordan Carlin, jcarlin@hmc.edu, December 2024

# Breker Trek Tests Support Files for CVW

[Breker's Trek Test Suite](https://brekersystems.com/products/trek-suite/) is a proprietary set of tests that require a license to use (this license is not generally available to noncommercial users).

This directory contains the support files necessary to run Breker's Trek Tests on CVW. For additional details on the tests see [`$WALLY/tests/breker/README.md`](../../tests/breker/README.md)

To generate the Breker support files (with a license), run `make` in the `testbench/trek_files` directory (this one). Before running, make sure to set `$BREKER_HOME` in your system's `site-setup.sh` file. This Makefile only needs to be run once.
