module tb_AddressDecoder_Verilog();
    logic [31:0] Address;
		
    logic OnChipRomSelect_H;
    logic OnChipRamSelect_H;
    logic DramSelect_H;
    logic IOSelect_H;
    logic DMASelect_L;
    logic GraphicsCS_L;
    logic OffBoardMemory_H;
    logic CanBusSelect_H;

    AddressDecoder_Verilog dut (
        Address,
        OnChipRomSelect_H,
        OnChipRamSelect_H,
        DramSelect_H,
        IOSelect_H,
        DMASelect_L,
        GraphicsCS_L,
        OffBoardMemory_H,
        CanBusSelect_H
    );

    initial begin
        Address = 'hefffffff; #5;
        Address = 'hf0000000; #5;
        Address = 'hf1000000; #5;
        Address = 'hf3ffffff; #5;
        Address = 'hf4000000; #5;
    end


endmodule 