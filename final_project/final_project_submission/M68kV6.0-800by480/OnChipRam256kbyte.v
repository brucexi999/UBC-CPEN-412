// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"
// CREATED		"Mon Jan 16 10:35:23 2023"

module OnChipRam256kbyte(
	Clock,
	UDS_L,
	LDS_L,
	RamSelect_H,
	WE_L,
	AS_L,
	Address,
	DataIn,
	DataOut
);


input wire	Clock;
input wire	UDS_L;
input wire	LDS_L;
input wire	RamSelect_H;
input wire	WE_L;
input wire	AS_L;
input wire	[16:0] Address;
input wire	[15:0] DataIn;
output wire	[15:0] DataOut;

wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_8;
wire	SYNTHESIZED_WIRE_2;
wire	SYNTHESIZED_WIRE_4;
wire	SYNTHESIZED_WIRE_6;





SramBlock_32KWord	b2v_inst(
	.32kWordBlockSelect_H(SYNTHESIZED_WIRE_0),
	.UDS_L(UDS_L),
	.LDS_L(LDS_L),
	.WE_L(WE_L),
	.AS_L(AS_L),
	.Clock(SYNTHESIZED_WIRE_8),
	.Address(Address[14:0]),
	.DataIn(DataIn),
	.DataOut({DataOut[15:8],DataOut[7:0]}));


SramBlockDecoder_Verilog	b2v_inst1(
	.SRamSelect_H(RamSelect_H),
	.Address(Address),
	.Block0_H(SYNTHESIZED_WIRE_0),
	.Block1_H(SYNTHESIZED_WIRE_2),
	.Block2_H(SYNTHESIZED_WIRE_4),
	.Block3_H(SYNTHESIZED_WIRE_6));

assign	SYNTHESIZED_WIRE_8 =  ~Clock;


SramBlock_32KWord	b2v_inst3(
	.32kWordBlockSelect_H(SYNTHESIZED_WIRE_2),
	.UDS_L(UDS_L),
	.LDS_L(LDS_L),
	.WE_L(WE_L),
	.AS_L(AS_L),
	.Clock(SYNTHESIZED_WIRE_8),
	.Address(Address[14:0]),
	.DataIn(DataIn),
	.DataOut({DataOut[15:8],DataOut[7:0]}));


SramBlock_32KWord	b2v_inst4(
	.32kWordBlockSelect_H(SYNTHESIZED_WIRE_4),
	.UDS_L(UDS_L),
	.LDS_L(LDS_L),
	.WE_L(WE_L),
	.AS_L(AS_L),
	.Clock(SYNTHESIZED_WIRE_8),
	.Address(Address[14:0]),
	.DataIn(DataIn),
	.DataOut({DataOut[15:8],DataOut[7:0]}));


SramBlock_32KWord	b2v_inst5(
	.32kWordBlockSelect_H(SYNTHESIZED_WIRE_6),
	.UDS_L(UDS_L),
	.LDS_L(LDS_L),
	.WE_L(WE_L),
	.AS_L(AS_L),
	.Clock(SYNTHESIZED_WIRE_8),
	.Address(Address[14:0]),
	.DataIn(DataIn),
	.DataOut({DataOut[15:8],DataOut[7:0]}));

assign	DataOut[15:8] = DataOut[15:8];
assign	DataOut[15:8] = DataOut[15:8];
assign	DataOut[15:8] = DataOut[15:8];
assign	DataOut[15:8] = DataOut[15:8];
assign	DataOut[7:0] = DataOut[7:0];
assign	DataOut[7:0] = DataOut[7:0];
assign	DataOut[7:0] = DataOut[7:0];
assign	DataOut[7:0] = DataOut[7:0];

endmodule
