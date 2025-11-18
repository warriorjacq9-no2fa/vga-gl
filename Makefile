all: run
run: build
	bin/main

build: verilog
	g++ main.cpp -o bin/main -I./include -std=c++11 -O3 -lGL -lglfw

verilog:
	iverilog tb.sv test.v vga.v -DTOP_MODULE=test -o test.vvp -g2012
	vvp test.vvp

clean:
	rm -rf bin *.bin *.vvp *.vcd