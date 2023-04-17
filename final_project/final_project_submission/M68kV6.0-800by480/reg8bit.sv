module reg8bit (
    input [7:0] d,
    input clk,
    input wren_H,
    input reset_L,
    output logic [7:0] q
);
always @ (posedge clk or negedge reset_L) begin
    if (reset_L == 0) begin
        q <= 8'b0;
    end
    else if (wren_H == 1) begin
        q <= d;
    end
end
endmodule