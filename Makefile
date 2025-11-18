CPPFLAGS = -I./include -std=c++11 -lGL -lglfw -Ofast -march=native -flto
SRCS = main.cpp display.cpp glad.c

all: verilog run
run: build
	bin/main

build:
	mkdir -p bin
	g++ $(SRCS) -o bin/main $(CPPFLAGS)

verilog:
	iverilog tb.sv test.v vga.v -DTOP_MODULE=test -o test.vvp -g2012
	vvp -v test.vvp

clean:
	rm -rf bin *.bin *.vvp *.vcd