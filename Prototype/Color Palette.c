#include <stdio.h>

int main() {
    int width = 256, height = 256;
    FILE *fp = fopen("out.ppm", "w");
    fprintf(fp, "P3\n%d %d\n255\n", width, height); // PPMヘッダ

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int r = x;
            int g = y;
            int b = (x + y) / 2;
            fprintf(fp, "%d %d %d\n", r, g, b); // ピクセルごとのRGB
        }
    }
    fclose(fp);
    return 0;
}