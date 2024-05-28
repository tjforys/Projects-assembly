#include <stdio.h>
#include <stdlib.h>

#pragma pack(push, 1)
typedef struct {
    unsigned short bfType;
    unsigned int bfSize;
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned int bfOffBits;
    unsigned int biSize;
    int biWidth;
    int biHeight;
    unsigned short biPlanes;
    unsigned short biBitCount;
    unsigned int biCompression;
    unsigned int biSizeImage;
    int biXPelsPerMeter;
    int biYPelsPerMeter;
    unsigned int biClrUsed;
    unsigned int biClrImportant;
} BITMAPFILEHEADER;
#pragma pack(pop)

extern void enhance_contrast(void *img, int width, int height);

void read_bmp(const char *filename, unsigned char **img_data, int *width, int *height) {
    FILE *f = fopen(filename, "rb");
    if (!f) {
        perror("Failed to open file");
        exit(1);
    }

    BITMAPFILEHEADER header;
    fread(&header, sizeof(BITMAPFILEHEADER), 1, f);

    if (header.bfType != 0x4D42 || header.biBitCount != 24) {
        fprintf(stderr, "Not a 24 bpp BMP file\n");
        fclose(f);
        exit(1);
    }

    *width = header.biWidth;
    *height = header.biHeight;
    int size = header.biSizeImage ? header.biSizeImage : (*width * 3 * *height);

    *img_data = (unsigned char *)malloc(size);
    if (!*img_data) {
        perror("Failed to allocate memory");
        fclose(f);
        exit(1);
    }

    fseek(f, header.bfOffBits, SEEK_SET);
    fread(*img_data, 1, size, f);
    fclose(f);
}

void save_bmp(const char *filename, unsigned char *img_data, int width, int height) {
    FILE *f = fopen(filename, "wb");
    if (!f) {
        perror("Failed to open file");
        exit(1);
    }

    BITMAPFILEHEADER header = {0};
    header.bfType = 0x4D42;
    header.bfSize = sizeof(BITMAPFILEHEADER) + width * height * 3;
    header.bfOffBits = sizeof(BITMAPFILEHEADER);
    header.biSize = sizeof(BITMAPFILEHEADER) - 14;
    header.biWidth = width;
    header.biHeight = height;
    header.biPlanes = 1;
    header.biBitCount = 24;
    header.biCompression = 0;
    header.biSizeImage = width * height * 3;

    fwrite(&header, sizeof(BITMAPFILEHEADER), 1, f);
    fwrite(img_data, 1, width * height * 3, f);
    fclose(f);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input_bmp> <output_bmp>\n", argv[0]);
        return 1;
    }

    unsigned char *img_data;
    int width, height;

    read_bmp(argv[1], &img_data, &width, &height);
    enhance_contrast(img_data, width, height);
    save_bmp(argv[2], img_data, width, height);

    free(img_data);
    return 0;
}