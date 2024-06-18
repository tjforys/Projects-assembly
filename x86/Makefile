CC=gcc
NASM=nasm
CFLAGS32=-m32
LDFLAGS32=-m32

all: enhance_contrast32

enhance_contrast32: main.c enhance_contrast32.asm
	$(NASM) -f elf32 enhance_contrast32.asm -o enhance_contrast32.o
	$(CC) $(CFLAGS32) main.c enhance_contrast32.o -o enhance_contrast32 $(LDFLAGS32)



clean:
	rm -f enhance_contrast32 enhance_contrast32.o
	rm -f enhance_contrast64 enhance_contrast64.o

