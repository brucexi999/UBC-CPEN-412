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
// CREATED		"Mon Jan 16 10:35:50 2023"

module SramBlock_32KWord(
	Clock,
	UDS_L,
	LDS_L,
	WE_L,
	AS_L,
	32kWordBlockSelect_H,
	Address,
	DataIn,
	DataOut
);


input wire	Clock;
input wire	UDS_L;
input wire	LDS_L;
input wire	WE_L;
input wire	AS_L;
input wire	32kWordBlockSelect_H;
input wire	[14:0] Address;
input wire	[15:0] DataIn;
output wire	[15:0] DataOut;

wire	SYNTHESIZED_WIRE_0;
wire	[7:0] SYNTHESIZED_WIRE_1;
wire	SYNTHESIZED_WIRE_2;
wire	[7:0] SYNTHESIZED_WIRE_3;
wire	SYNTHESIZED_WIRE_4;
wire	SYNTHESIZED_WIRE_10;
wire	SYNTHESIZED_WIRE_6;
wire	SYNTHESIZED_WIRE_11;





lpm_bustri2	b2v_inst(
	.enabledt(SYNTHESIZED_WIRE_0),
	.data(SYNTHESIZED_WIRE_1),
	.tridata(DataOut[7:0])
	);


lpm_bustri2	b2v_inst1(
	.enabledt(SYNTHESIZED_WIRE_2),
	.data(SYNTHESIZED_WIRE_3),
	.tridata(DataOut[15:8])
	);

assign	SYNTHESIZED_WIRE_10 =  ~Clock;


Ram32kByte	b2v_inst3(
	.wren(SYNTHESIZED_WIRE_4),
	.clock(SYNTHESIZED_WIRE_10),
	.address(Address),
	.data(DataIn[15:8]),
	.q(SYNTHESIZED_WIRE_3));


Ram32kByte	b2v_inst4(
	.wren(SYNTHESIZED_WIRE_6),
	.clock(SYNTHESIZED_WIRE_10),
	.address(Address),
	.data(DataIn[7:0]),
	.q(SYNTHESIZED_WIRE_1));

assign	SYNTHESIZED_WIRE_4 = ~(UDS_L | WE_L | AS_L);

assign	SYNTHESIZED_WIRE_2 = ~(UDS_L | SYNTHESIZED_WIRE_11 | AS_L);

assign	SYNTHESIZED_WIRE_0 = ~(LDS_L | SYNTHESIZED_WIRE_11 | AS_L);

assign	SYNTHESIZED_WIRE_11 =  ~32kWordBlockSelect_H;

assign	SYNTHESIZED_WIRE_6 = ~(LDS_L | WE_L | AS_L);


endmodule
