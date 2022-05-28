all: sqrttestgen testgen qst2

sqrttestgen: sqrttestgen.c
	gcc sqrttestgen.c -lm -o sqrttestgen

testgen: testgen.c
	gcc testgen.c -lm -o testgen

qst2: qst2.c
	gcc qst2.c -lm -o qst2
	gcc -lm -o testgen testgen.c
	./testgen

exptestgen: exptestgen.c
	gcc -lm -o exptestgen exptestgen.c
	./exptestgen
