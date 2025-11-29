`timescale 1ns/1ps
module tb;

    // Clock & reset
    reg clk = 0;
    reg rst_n = 1;

    // DUT inputs
    reg [7:0] ui_in   = 0;
    reg [7:0] uio_in  = 0;
    reg       ena     = 1;

    // DUT outputs
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // ------------------------------------------------------------------
    // FAST CLOCK (50 MHz): period = 20 ns
    // ------------------------------------------------------------------
    always #10 clk = ~clk;

    // ------------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------------
    dut_wrapper dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // ------------------------------------------------------------------
    // Simulation parameters
    // ------------------------------------------------------------------
    localparam integer TOTAL_CYCLES = 420_000 * 90;  // 90 frames @ 420k cycles/frame

    integer cycle_count = 0;

    integer file;         // dump.bin
    integer ifile;        // in.dat (binary)
    integer input_len = 0;
    integer input_index = 0;
    integer bytes_read;

    // ----------------------------------------------------
    // Read entire input file at initialization
    // ----------------------------------------------------
    // Maximum input size (safe limit)
    localparam MAX_INPUT_BYTES = 1_000_000;

    reg [7:0] input_mem [MAX_INPUT_BYTES-1:0];

    initial begin
        // Open output
        file = $fopen("dump.bin", "wb");
        if (!file) begin
            $display("ERROR: Cannot open dump.bin");
            $finish;
        end

        ifile = $fopen("in.dat", "rb");
        if (!ifile) begin
            $display("ERROR: Cannot open in.dat");
            $finish;
        end

        // Read the entire file into input_mem
        bytes_read = $fread(input_mem, ifile);
        input_len = bytes_read;

        $display("Loaded %0d bytes from in.dat", input_len);
        $fclose(ifile);

        // Write cycle count header (8 bytes)
        for (int i = 0; i < 8; i++)
            $fwrite(file, "%c", (TOTAL_CYCLES >> (8*i)) & 8'hFF);

        // Reset pulse
        rst_n = 0;
        #200;            // 200 ns reset
        rst_n = 1;
    end

    // ------------------------------------------------------------------
    // VSYNC-triggered input update once per frame
    // ------------------------------------------------------------------
    // VSYNC = uo_out[3]
    always @(negedge uo_out[3]) begin
        if (input_index < input_len)
            ui_in <= input_mem[input_index++];
        else
            ui_in <= 8'h00;       // default if out of input
    end

    // ------------------------------------------------------------------
    // FAST OUTPUT: write every cycle directly to dump.bin
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        cycle_count++;

        // Write 2 bytes per cycle
        $fwrite(file, "%c%c", uo_out, uio_out);

        if (cycle_count >= TOTAL_CYCLES) begin
            $display("Simulation finished.");
            $fclose(file);
            $finish;
        end
    end

endmodule

// -----------------------------------------------------
// Wrapper that instantiates the selected TOP_MODULE
// -----------------------------------------------------
module dut_wrapper (
    input  [7:0] ui_in,
    input  [7:0] uio_in,
    input        ena,
    input        clk,
    input        rst_n,
    output [7:0] uo_out,
    output [7:0] uio_out,
    output [7:0] uio_oe
);
    supply0 GND;
    supply1 PWR;
    `TOP_MODULE dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n),
        .VPWR(PWR),
        .VGND(GND)
    );
endmodule
