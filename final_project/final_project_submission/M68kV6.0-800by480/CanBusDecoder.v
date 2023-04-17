module CanBusDecoder (
    Address,
    CanBusSelect_H,
    AS_L,
    CAN_Enable0_H,
    CAN_Enable1_H
);

input [31:0] Address;
input CanBusSelect_H;
input AS_L;
output reg CAN_Enable0_H, CAN_Enable1_H;

always @* begin
    CAN_Enable0_H = 0;
    CAN_Enable1_H = 0;

    if (AS_L == 0 && CanBusSelect_H == 1 && Address[15:9] == 7'b0) begin
        CAN_Enable0_H = 1;
    end
    if (AS_L == 0 && CanBusSelect_H == 1 && Address[15:9] == 7'b0000001) begin
        CAN_Enable1_H = 1;
    end
end
    
endmodule