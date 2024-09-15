.DELETE_ON_ERROR:
SHELL := /bin/bash

TESTFLOAT_DIR := ${WALLY}/addins/TestFloat-3e/build/Linux-x86_64-GCC
TESTFLOAT_GEN_CMD := ${TESTFLOAT_DIR}/testfloat_gen -tininessafter -level

# List of testvectors to generate. Each rounding mode will be generated for each test.
cvtint := ui32_to_f16 ui32_to_f32 ui32_to_f64 ui32_to_f128 \
          ui64_to_f16 ui64_to_f32 ui64_to_f64 ui64_to_f128 \
          i32_to_f16 i32_to_f32 i32_to_f64 i32_to_f128 \
          i64_to_f16 i64_to_f32 i64_to_f64 i64_to_f128 \
          f16_to_ui32 f32_to_ui32 f64_to_ui32 f128_to_ui32 \
          f16_to_ui64 f32_to_ui64 f64_to_ui64 f128_to_ui64
cvtfp := f16_to_i32 f32_to_i32 f64_to_i32 f128_to_i32 \
         f16_to_i64 f32_to_i64 f64_to_i64 f128_to_i64 \
         f16_to_f32 f16_to_f64 f16_to_f128 \
         f32_to_f16 f32_to_f64 f32_to_f128 \
         f64_to_f16 f64_to_f32 f64_to_f128 \
         f128_to_f16 f128_to_f32 f128_to_f64
add := f16_add f32_add f64_add f128_add
sub := f16_sub f32_sub f64_sub f128_sub
mul := f16_mul f32_mul f64_mul f128_mul
div := f16_div f32_div f64_div f128_div
sqrt := f16_sqrt f32_sqrt f64_sqrt f128_sqrt
eq := f16_eq f32_eq f64_eq f128_eq
le := f16_le f32_le f64_le f128_le
lt := f16_lt f32_lt f64_lt f128_lt
mulAdd := f16_mulAdd f32_mulAdd f64_mulAdd f128_mulAdd

tests := $(cvtfp) $(cvtint) $(add) $(sub) $(mul) $(div) $(sqrt) $(eq) $(le) $(lt) $(mulAdd)


.PHONY: all rne rz ru rd rnm clean

all: rne rz ru rd rnm

# Generate test vectors for each rounding mode
rne: $(addsuffix _rne.tv, $(tests))
rz: $(addsuffix _rz.tv, $(tests))
ru: $(addsuffix _ru.tv, $(tests))
rd: $(addsuffix _rd.tv, $(tests))
rnm: $(addsuffix _rnm.tv, $(tests))

# Rules to generate individual test vectors, broken up by rounding mode
%_rne.tv: ${TESTFLOAT_GEN}
	@echo Creating $*_rne.tv vectors
	@if [[ "$*" =~ "to" ]] || [[ "$*" =~ "sqrt" ]] ; then level=2 ; else level=1 ; fi ; \
	if [[ "$*" =~ "to_i" ]] || [[ "$*" =~ "to_u" ]] ; then exact="-exact" ; else exact="" ; fi ; \
	${TESTFLOAT_GEN_CMD} $$level $$exact -rnear_even $* > $@
	@sed -i 's/ /_/g' $@

%_rz.tv: ${TESTFLOAT_GEN}
	@echo Creating $*_rz.tv vectors
	@if [[ "$*" =~ "to" ]] || [[ "$*" =~ "sqrt" ]] ; then level=2 ; else level=1 ; fi ; \
	if [[ "$*" =~ "to_i" ]] || [[ "$*" =~ "to_u" ]] ; then exact="-exact" ; else exact="" ; fi ; \
	${TESTFLOAT_GEN_CMD} $$level $$exact -rminMag $* > $@
	@sed -i 's/ /_/g' $@

%_ru.tv: ${TESTFLOAT_GEN}
	@echo Creating $*_ru.tv vectors
	@if [[ "$*" =~ "to" ]] || [[ "$*" =~ "sqrt" ]] ; then level=2 ; else level=1 ; fi ; \
	if [[ "$*" =~ "to_i" ]] || [[ "$*" =~ "to_u" ]] ; then exact="-exact" ; else exact="" ; fi ; \
	${TESTFLOAT_GEN_CMD} $$level $$exact -rmax $* > $@
	@sed -i 's/ /_/g' $@

%_rd.tv: ${TESTFLOAT_GEN}
	@echo Creating $*_rd.tv vectors
	@if [[ "$*" =~ "to" ]] || [[ "$*" =~ "sqrt" ]] ; then level=2 ; else level=1 ; fi ; \
	if [[ "$*" =~ "to_i" ]] || [[ "$*" =~ "to_u" ]] ; then exact="-exact" ; else exact="" ; fi ; \
	${TESTFLOAT_GEN_CMD} $$level $$exact -rmin $* > $@
	@sed -i 's/ /_/g' $@

%_rnm.tv: ${TESTFLOAT_GEN}
	@echo Creating $*_rnm.tv vectors
	@if [[ "$*" =~ "to" ]] || [[ "$*" =~ "sqrt" ]] ; then level=2 ; else level=1 ; fi ; \
	if [[ "$*" =~ "to_i" ]] || [[ "$*" =~ "to_u" ]] ; then exact="-exact" ; else exact="" ; fi ; \
	${TESTFLOAT_GEN_CMD} $$level $$exact -rnear_maxMag $* > $@
	@sed -i 's/ /_/g' $@

# Generate TestFloat first if necessary
${TESTFLOAT_GEN}:
	$(MAKE) -C ${WALLY}/tests/fp testfloat

clean:
	rm -f *.tv
	rm -f sed*
