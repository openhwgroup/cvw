all: sqrttestgen testgen

sqrttestgen: sqrttestgen.c
	gcc sqrttestgen.c -lm -o sqrttestgen
	
testgen: testgen.c
	gcc -lm -o testgen testgen.c
	./testgen

	
exptestgen: exptestgen.c
	gcc -lm -o exptestgen exptestgen.c
	./exptestgen
