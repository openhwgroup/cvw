all: exptestgen testgen qslc_r4a2 qslc_r4a2b

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

qslc_r4a2b: qslc_r4a2b.c
	gcc qslc_r4a2b.c -o qslc_r4a2b -lm
	./qslc_r4a2b > qslc_r4a2b.tv

clean:
	rm -f testgen exptestgen qslc_r4a2 
