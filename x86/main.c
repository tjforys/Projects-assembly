#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

extern void enhance_contrast(uint8_t *img);
extern int essa;
uint8_t* load_bmp(const char *filename, int *size) {
    FILE *f = fopen(filename, "rb");
    if (!f) {
        perror("Error opening file");
        return NULL;
    }

    // Move the file pointer to the end of the file
    fseek(f, 0, SEEK_END);
    // Get the size of the file
    *size = ftell(f);
    // Move the file pointer back to the beginning of the file
    fseek(f, 0, SEEK_SET);

    // Allocate memory to hold the entire file
    uint8_t *data = (uint8_t*)malloc(*size);
    if (data == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        fclose(f);
        return NULL;
    }

    // Read the entire file into memory
    fread(data, 1, *size, f);
    fclose(f);

    return data;
}

void write_bmp(const char *filename, uint8_t *data, int size) {
    FILE *f = fopen(filename, "wb");
    if (!f) {
        perror("Error opening file for writing");
        return;
    }

    fwrite(data, 1, size, f);
    fclose(f);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input.bmp> <output.bmp>\n", argv[0]);
        return 1;
    }

    int size;
    uint8_t *img = load_bmp(argv[1], &size);
    if (img == NULL) {
        return 1;
    }

    printf("Loaded BMP file with size: %d bytes\n", size);


    enhance_contrast(img);
    printf("%d", essa);
    write_bmp(argv[2], img, size);
    printf("Wrote the modified image to '%s'\n", argv[2]);

    // Free the allocated memory
    free(img);

    return 0;
}
