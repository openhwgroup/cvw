CC = gcc
CFLAGS = -g
VERBOSE ?= 0
CFLAGS += -DVERBOSE=$(VERBOSE)

TARGET = aes

# Always rebuild if VERBOSE changes
.PHONY: all clean $(TARGET)

all: $(TARGET)

$(TARGET): aes.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET) *~
