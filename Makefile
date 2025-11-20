CPPFLAGS = -I./include -std=c++11 -lGL -lglfw -Ofast -march=native -flto
SRCS = main.cpp display.cpp glad.c

VERILOG_SRCS?=$(TOP_MODULE)

all: args test.vvp run

args:
ifeq ($(strip $(TOP_MODULE)),)
	@echo "Error: TOP_MODULE not set." >&2
	@echo "Syntax: make TOP_MODULE=<top module> VERILOG_SRCS=<full path to srcs>" >&2
	@exit 1
endif

run: build
	bin/main

build:
	mkdir -p bin
	g++ $(SRCS) -o bin/main $(CPPFLAGS)

test.vvp:
	iverilog tb.sv $(VERILOG_SRCS) -DTOP_MODULE=$(TOP_MODULE) \
	-DFUNCTIONAL -DUSE_POWER_PINS -DSIM -DUNIT_DELAY=\#1 -o test.vvp -g2012
	vvp -v test.vvp

clean:
	rm -rf bin *.bin *.vvp *.vcd
