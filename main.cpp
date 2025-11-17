#include <iostream>
#include <fstream>
#include <string>

typedef struct {
    char uo_out;
    char uio_out;
} vga_output_t;

int main() {
    std::string filename = "dump.bin";
    std::ifstream file(filename);
    if (!file) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return 1;
    }
    // Parse testbench output
    char llbuf[5];
    file.read(llbuf, 4);
    llbuf[4] = 0;
    long long num = atoi(llbuf);
    printf("%s: %llu\n", llbuf, num);
    return 0;
}