# core-v-wally Design Verification Test Plan

This document outlines the test plan for the Wally rv64gc configuration to reach Technology Readiness Level 5.

a) Pass riscv-arch-test
b) Boot Linux
c) FPU pass all TestFloat vectors
d) Performance verification: Caches and branch predictor miss rates match independent simulation
e) Directed tests
	- Privileged unit: Chapter 5 test plan
	- MMU: PMA, PMP, virtual memory: Chapter 8 test plan
	- Peripherals: Chapter 16 test plan
f) Random tests
	- riscdv tests
g) Coverage tests
	- Directed tests to bring coverage up to 100%.  
		- Statement, experssion, branch, condition, FSM coverage in Questa 
		- Do not measure toggle coverage

All tests operate correctly in lock-step with ImperasDV

Open questions:
	How to define extent of riscdv random tests needed?
	What other directed tests?
    PMP Tests
    Virtual Memory Tests
		How to define pipeline tests? 
			Simple ones like use after load stall are not important.
			Hard ones such as page table walker fault during data access while I$ access is pending are hard to articulate and code
      Is there an example of a good directed pipeline test plan & implementation
