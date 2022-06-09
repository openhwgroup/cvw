all: exptestgen testgen qslc_r4a2

sqrttestgen: sqrttestgen.c
	gcc sqrttestgen.c -lm -o sqrttestgen

testgen: testgen.c
	gcc testgen.c -lm -o testgen
	./testgen

exptestgen: exptestgen.c
	gcc -lm -o exptestgen exptestgen.c
	./exptestgen

qslc_r4a2: qslc_r4a2.c
	gcc qslc_r4a2.c -lm -o qslc_r4a2
	./qslc_r4a2 >> qslc_r4a2.sv

clean:
	rm -f testgen exptestgen qslc_r4a2 