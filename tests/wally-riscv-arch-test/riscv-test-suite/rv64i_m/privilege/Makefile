include ../../Makefile.include

RVTEST_DEFINES += -march=rv$(XLEN)iaf # KMG: removed compressed instructions from privileged tests

$(eval $(call compile_template,-march=rv64iaf -mabi=lp64 -Drvtest_mtrap_routine=True -DXLEN=$(XLEN)))
