module vga_decoder (
    input [15:0] addr,
    input AS_L,
    input vga_select_H,
    output x_en,
    output y_en,
    output ctl_en,
    output text_en
);

always_comb begin
    x_en = 0;
    y_en = 0;
    ctl_en = 0;
    text_en = 0;

    if (addr[15:12] == 4'b0000 && AS_L == 0 && vga_select_H == 1) begin
        text_en = 1;
    end
    else if (addr[15:0] == 'h1000 && AS_L == 0 && vga_select_H == 1) begin
        x_en = 1;
    end
    else if (addr[15:0] == 'h1002 && AS_L == 0 && vga_select_H == 1) begin
        y_en = 1;
    end
    else if (addr[15:0] == 'h1004 && AS_L == 0 && vga_select_H == 1) begin
        ctl_en = 1;
    end
end
endmodule