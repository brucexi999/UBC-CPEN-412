module vga_adaptor (
    input R,
    input G,
    input B,
    input hsync,
    input vsync,
    input clk,
    output logic [7:0] VGA_RED,
    output logic [7:0] VGA_GREEN,
    output logic [7:0] VGA_BLUE,
    output logic VGA_HSYNC,
    output logic VGA_VSYNC,
    output logic VGA_CLK,
    output logic VGA_BLANK_N,
    output logic VGA_SYNC_N
);

    always_comb begin 
        if (R == 1) begin
            VGA_RED = 8'b11111111;
        end
        else begin
            VGA_RED = 8'b0;
        end
        
    end

    always_comb begin 
        if (G == 1) begin
            VGA_GREEN = 8'b11111111;
        end
        else begin
            VGA_GREEN = 8'b0;
        end
        
    end

    always_comb begin 
        if (B == 1) begin
            VGA_BLUE = 8'b11111111;
        end
        else begin
            VGA_BLUE = 8'b0;
        end
        
    end

    assign VGA_BLANK_N = 1;
    assign VGA_SYNC_N = 1;
    assign VGA_HSYNC = hsync;
    assign VGA_VSYNC = vsync;
    assign VGA_CLK = clk;
    
endmodule