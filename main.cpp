#include <iostream>
#include <fstream>
#include <string>
#include <math.h>
#include <vector>
#include <condition_variable>
#include <thread>
#include <chrono>
#include "display.h"

std::condition_variable cv;
std::mutex mtx;

bool gl_done = false;
bool texUpdate = false;

long long length;

typedef struct {
    unsigned char uo_out;
    unsigned char uio_out;
} vga_output_t;

std::vector<unsigned char> pixels(WIDTH * HEIGHT * 4);

inline uint8_t _2to8(uint8_t v) { return (((v >> 3) & 0x02) | (v & 0x01)) * 0x55; }

static inline void wait_gl_done() {
    std::unique_lock<std::mutex> lock(mtx);
    cv.wait(lock, []{ return gl_done; });
}

std::vector<vga_output_t> fileinit() {
    std::string filename = "dump.bin";
    std::ifstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Error opening file: " << filename << std::endl;
        std::vector<vga_output_t> tmp(1);
        return tmp;
    }
    // Parse testbench output
    file.read((char*)&length, 8);
    
    printf("%llu cycles detected\n", length);
    std::vector<vga_output_t> outs(length);

    for(long long i = 0; i < length; i++) {
        file.read((char*)&outs[i].uo_out, 1);
        file.read((char*)&outs[i].uio_out, 1);
    }
    printf("Finished loading file\n");
    return outs;
}

static void tb(std::vector<vga_output_t> outs) {

    int x = 0;
    int y = 0;
    long long i = 0;
    bool last_hsync = true;
    bool last_vsync = true;
    
    constexpr uint8_t HSYNC_MASK = 0b10000000;
    constexpr uint8_t VSYNC_MASK = 0b00001000;
    constexpr uint8_t DE_MASK    = 0b00000001;
    printf("Starting...\n");

    constexpr double frame_time = 1.0 / 60.0; // 60 FPS

    auto frame_start = std::chrono::high_resolution_clock::now();

    while(true) {
        bool hsync = outs[i].uo_out & HSYNC_MASK;
        bool vsync = outs[i].uo_out & VSYNC_MASK;
        bool de    = outs[i].uio_out & DE_MASK;

        // Detect rising edges of syncs
        if (last_hsync && !hsync) {
            x = 0;
            y++;
        }
        if (last_vsync && !vsync) {
            y = 0;
            texUpdate = true;
            auto frame_end = std::chrono::high_resolution_clock::now();
            auto elapsed = std::chrono::duration<double>(frame_end - frame_start).count();
            if(elapsed < frame_time) {
                std::this_thread::sleep_for(std::chrono::duration<double>(frame_time - elapsed));
            }
            frame_start = std::chrono::high_resolution_clock::now();
        }

        last_hsync = hsync;
        last_vsync = vsync;

        if (x < WIDTH && y < HEIGHT) {
            char r = 0, g = 0, b = 0;
            if(de) {
                r = _2to8(outs[i].uo_out & 0b00010001);
                g = _2to8((outs[i].uo_out & 0b00100010) >> 1);
                b = _2to8((outs[i].uo_out & 0b01000100) >> 2);
            }

            unsigned char* p = &pixels[(y * WIDTH + x) * 4];
            p[0] = r; p[1] = g; p[2] = b; p[3] = 0xFF;
        }
        x++;
        i++;
        if(i >= length){
            i = 0;
            last_hsync = true;
            last_vsync = true;
        }
    }
}

int main() {
    std::vector<vga_output_t> outs = fileinit();
    std::thread thread(displayRun, &pixels, &gl_done, &texUpdate);
    wait_gl_done();
    tb(outs);

    return 0;
}
