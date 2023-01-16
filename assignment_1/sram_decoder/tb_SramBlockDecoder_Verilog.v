module tb_SramBlockDecoder_Verilog ();

    reg [16:0] Address;
    reg SRamSelect_H;

    wire Block0_H;
    wire Block1_H;
    wire Block2_H;
    wire Block3_H;

    SramBlockDecoder_Verilog dut (Address, SRamSelect_H, Block0_H, Block1_H, Block2_H, Block3_H);

    initial begin
        Address = 'h0000;
        SRamSelect_H = 0;
        #5;

        SRamSelect_H = 1;
        #5; // Block0_H = 1

        Address[15] = 1;
        #5; // Block1_H = 1
        
        Address[16:15] = 2'b10;
        #5; // Block2_H = 1

        Address[16:15] = 2'b11;
        #5; // Block3_H = 1

        SRamSelect_H = 0;
        #5; // All outputs should be 0


    end

endmodule