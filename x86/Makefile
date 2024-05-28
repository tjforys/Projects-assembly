CC = gcc
NASM = nasm
CFLAGS = -Wall -m32
LDFLAGS = -m32
NASMFLAGS = -f elf

all: main32

main32: main.c enhance_contrast32.o
    $(CC) $(CFLAGS) -o main32 main.c enhance_contrast32.o

enhance_contrast32.o: enhance_contrast.asm
    $(NASM) $(NASMFLAGS) -o enhance_contrast32.o enhance_contrast.asm

clean:
    rm -f *.o main32