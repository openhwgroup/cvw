TARGET ?= fma

$(TARGET): $(TARGET).c Makefile
	gcc -c -I../../../addins/SoftFloat-3e/source/include  -O2 -o $(TARGET).o $(TARGET).c
	gcc -L../../../addins/SoftFloat-3e/build/Linux-x86_64-GCC \
		   -o $(TARGET) $(TARGET).o softfloat.a \

clean: 
	rm $(TARGET).o
	rm $(TARGET)
