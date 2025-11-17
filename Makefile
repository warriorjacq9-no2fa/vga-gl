all: run
run: build

build:
	iverilog tb.sv test.v vga.v -DTOP_MODULE=test -o test.vvp
	vvp test.vvp

clean:
	rm -rf bin *.bin *.vvp *.vcd