`timescale 1 ps/ 1 ps
module Tb_SdramController ();
    logic Clock;							
    logic Reset_L;     						
    logic unsigned [31:0] Address;
    logic unsigned [15:0] DataIn;			
    logic UDS_L;							
    logic LDS_L; 							
    logic DramSelect_L;     				
    logic WE_L;  							
    logic AS_L;								
                
    logic  unsigned[15:0] DataOut; 		
    logic  SDram_CKE_H;					
    logic  SDram_CS_L;					
    logic  SDram_RAS_L;					
    logic  SDram_CAS_L;					
    logic  SDram_WE_L;					
    logic  unsigned [12:0] SDram_Addr;
    logic  unsigned [1:0] SDram_BA;		
    wire  unsigned [15:0] SDram_DQ;	
                
    logic  Dtack_L;						
    logic  ResetOut_L;					
    logic  [4:0] DramState;
    
    M68kDramController_Verilog dut (
        Clock,
        Reset_L,
        Address,
        DataIn,
        UDS_L,
        LDS_L,
        DramSelect_L,
        WE_L,
        AS_L,
        DataOut,
        SDram_CKE_H,
        SDram_CS_L,
        SDram_RAS_L,
        SDram_CAS_L,
        SDram_WE_L,
        SDram_Addr,
        SDram_BA,
        SDram_DQ,
        Dtack_L,
        ResetOut_L,
        DramState
    );

    initial begin
        Clock = 0; #5;
        forever begin
            Clock = 1; #5;
            Clock = 0; #5;
        end
    end

    initial begin
        Reset_L = 1; #5;
        Reset_L = 0; #10;
        Reset_L = 1; #100000;
        //Reset_L = 0; #10;
        //Reset_L = 1; #100000;
        $stop; 
    end

endmodule