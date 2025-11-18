module test (
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

    assign uio_oe = 8'b0;

    reg [3:0] r, g, b;
    wire [10:0] x, y;
    wire de;
    wire hsync, vsync;
    reg [10:0] counter;
    wire [10:0] x_mov = counter + x;

    assign uo_out[7:0] = {g[3:0], r[3:0]};
    assign uio_out[3:0] = b[3:0];
    assign uio_out[7:4] = {1'b0, de, vsync, hsync};


    // ******************** GRAPHICS ********************
    vga vga (
	    .clk(clk), 
	    .hsync(hsync),
		.vsync(vsync),
		.x(x),
		.y(y),
		.de(de),
        .rst_n(rst_n)
	);


    /* verilator lint_off LATCH */
    always @(*) begin // Display logic
        r = 0;
        g = 0;
        b = 0;
        if(de == 1) begin
            r = x_mov[8:5];
            g = y[8:5];
            b = 15 - r;
        end
    end

    reg vsync_d;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            vsync_d <= 0;
            counter <= 0;
        end else begin
            vsync_d <= vsync; // delay version
            if (vsync && !vsync_d)
                counter <= counter + 1; // rising edge detect
        end
    end

    wire _unused = &{ui_in, uio_in, ena, 1'b0};
endmodule