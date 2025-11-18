#include <iostream>
#include <fstream>
#include <string>
#include <math.h>
#include <vector>

long long length;

typedef struct {
    unsigned char uo_out;
    unsigned char uio_out;
} vga_output_t;

int main() {
    std::string filename = "dump.bin";
    std::ifstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return 1;
    }
    // Parse testbench output
    unsigned long long length;
    file.read((char*)&length, 8);
    printf("%llu cycles detected\n", length);
    std::vector<vga_output_t> outs(length);
    for(long long i = 0; i < length; i++) {
        file.read((char*)&outs[i].uo_out, 1);
        file.read((char*)&outs[i].uio_out, 1);
        printf("0x%02X, 0x%02X\n", outs[i].uo_out, outs[i].uio_out);
    }
    return 0;
}