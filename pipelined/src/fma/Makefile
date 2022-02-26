TARGET ?= fma

# for some reason, softfloat.a needs to be symlinked to the local directory.  -L isn't working
$(TARGET): $(TARGET).c Makefile
	gcc -O2 -o $(TARGET) $(TARGET).c softfloat.a  \
		 -I../../../addins/SoftFloat-3e/source/include  \
		 -L../../../addins/SoftFloat-3e/build/Linux-x86_64-GCC 

clean: 
	rm $(TARGET)
