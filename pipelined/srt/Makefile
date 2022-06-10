all: exptestgen testgen qslc_r4a2

sqrttestgen: sqrttestgen.c
	gcc sqrttestgen.c -o sqrttestgen -lm

testgen: testgen.c
	gcc testgen.c -o testgen -lm
	./testgen

exptestgen: exptestgen.c
	gcc -o exptestgen exptestgen.c -lm
	./exptestgen

qslc_r4a2: qslc_r4a2.c
	gcc qslc_r4a2.c -o qslc_r4a2 -lm
	./qslc_r4a2 > qslc_r4a2.sv

clean:
	rm -f testgen exptestgen qslc_r4a2 
