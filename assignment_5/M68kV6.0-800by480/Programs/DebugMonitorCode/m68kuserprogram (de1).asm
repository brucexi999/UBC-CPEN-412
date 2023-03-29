; C:\M68KV6.0-800BY480\PROGRAMS\DEBUGMONITORCODE\M68KUSERPROGRAM (DE1).C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; //IMPORTANT
; //
; // Uncomment one of the two #defines below
; // Define StartOfExceptionVectorTable as 08030000 if running programs from sram or
; // 0B000000 for running programs from dram
; //
; // In your labs, you will initially start by designing a system with SRam and later move to
; // Dram, so these constants will need to be changed based on the version of the system you have
; // building
; //
; // The working 68k system SOF file posted on canvas that you can use for your pre-lab
; // is based around Dram so #define accordingly before building
; //SRAM
; //#define StartOfExceptionVectorTable 0x08030000
; //DRAM
; #define StartOfExceptionVectorTable 0x0B000000
; /**********************************************************************************************
; **	Parallel port addresses
; **********************************************************************************************/
; #define PortA   *(volatile unsigned char *)(0x00400000)
; #define PortB   *(volatile unsigned char *)(0x00400002)
; #define PortC   *(volatile unsigned char *)(0x00400004)
; #define PortD   *(volatile unsigned char *)(0x00400006)
; #define PortE   *(volatile unsigned char *)(0x00400008)
; /*********************************************************************************************
; **	Hex 7 seg displays port addresses
; *********************************************************************************************/
; #define HEX_A        *(volatile unsigned char *)(0x00400010)
; #define HEX_B        *(volatile unsigned char *)(0x00400012)
; #define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
; #define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only
; /**********************************************************************************************
; **	LCD display port addresses
; **********************************************************************************************/
; #define LCDcommand   *(volatile unsigned char *)(0x00400020)
; #define LCDdata      *(volatile unsigned char *)(0x00400022)
; /********************************************************************************************
; **	Timer Port addresses
; *********************************************************************************************/
; #define Timer1Data      *(volatile unsigned char *)(0x00400030)
; #define Timer1Control   *(volatile unsigned char *)(0x00400032)
; #define Timer1Status    *(volatile unsigned char *)(0x00400032)
; #define Timer2Data      *(volatile unsigned char *)(0x00400034)
; #define Timer2Control   *(volatile unsigned char *)(0x00400036)
; #define Timer2Status    *(volatile unsigned char *)(0x00400036)
; #define Timer3Data      *(volatile unsigned char *)(0x00400038)
; #define Timer3Control   *(volatile unsigned char *)(0x0040003A)
; #define Timer3Status    *(volatile unsigned char *)(0x0040003A)
; #define Timer4Data      *(volatile unsigned char *)(0x0040003C)
; #define Timer4Control   *(volatile unsigned char *)(0x0040003E)
; #define Timer4Status    *(volatile unsigned char *)(0x0040003E)
; /*********************************************************************************************
; **	RS232 port addresses
; *********************************************************************************************/
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; /*********************************************************************************************
; **	PIA 1 and 2 port addresses
; *********************************************************************************************/
; #define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
; #define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
; #define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
; #define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)
; #define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
; #define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
; #define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
; #define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)
; /*******************************************************************************************
; ** I2C address and common commands
; *******************************************************************************************/
; #define I2C_prescale_reg_L *(volatile unsigned char *) (0x00408000)
; #define I2C_prescale_reg_H *(volatile unsigned char *) (0x00408002)
; #define I2C_control_reg  *(volatile unsigned char *) (0x00408004)
; #define I2C_TX_reg  *(volatile unsigned char *) (0x00408006)
; #define I2C_RX_reg  *(volatile unsigned char *) (0x00408006)
; #define I2C_command_reg  *(volatile unsigned char *) (0x00408008)
; #define I2C_status_reg  *(volatile unsigned char *) (0x00408008)
; #define start_write_cmd_I2C (char) (0x91)          // generate start signal and enable write, clear any pending interrupt
; #define write_cmd_I2C (char) (0x11)            // send TX byte without generating a start signal
; #define stop_write_cmd_I2C (char) (0x51)
; #define stop_read_NACK_cmd_I2C (char) (0x69)
; #define read_ACK_cmd_I2C (char) (0x21)
; /*********************************************************************************************************************************
; * 
; * 
; (( DO NOT initialise global variables here, do it main even if you want 0
; (( it's a limitation of the compiler
; (( YOU HAVE BEEN WARNED
; *********************************************************************************************************************************/
; unsigned int i, x, y, z, PortA_Count;
; unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;
; /*******************************************************************************************
; ** Function Prototypes
; *******************************************************************************************/
; int _getch( void );
; char xtod(int c);
; int Get1HexDigits(char *CheckSumPtr);
; int Get2HexDigits(char *CheckSumPtr);
; int Get4HexDigits(char *CheckSumPtr);
; int Get6HexDigits(char *CheckSumPtr);
; void Wait1ms(void);
; void Wait3ms(void);
; void Wait500ms (void);
; void Init_LCD(void) ;
; void LCDOutchar(int c);
; void LCDOutMess(char *theMessage);
; void LCDClearln(void);
; void LCDline1Message(char *theMessage);
; void LCDline2Message(char *theMessage);
; int sprintf(char *out, const char *format, ...) ;
; unsigned int ask_EEPROM_internal_addr(void);
; unsigned char ask_EEPROM_data(void);
; void EEPROM_internal_writting_polling(unsigned char slave_addr_RW);
; void I2C_init(void);
; void I2C_TX_command_status (char data, char command);
; void I2C_byte_write (void);
; void I2C_byte_read (void);
; unsigned int ask_EEPROM_addr_range(void);
; void I2C_multi_write (void);
; void I2C_multi_read (void);
; int boundry_checker (int intended_page_size, unsigned int current_addr);
; void DAC(void);
; unsigned char ask_ADC_channel (void);
; /*******************************************************************************************
; ** I2C functions
; *******************************************************************************************/
; unsigned int ask_EEPROM_internal_addr(void){
       section   code
       xdef      _ask_EEPROM_internal_addr
_ask_EEPROM_internal_addr:
       movem.l   D2/D3,-(A7)
; // ask the internal EEPROM address, return an array, storing the upper byte at location 0, and the lower byte at 1, the block select at 2
; int valid = 0;
       clr.l     D3
; unsigned int addr;
; printf("\r\nWhat is the internal EEPROM address you want to access? ");
       pea       @m68kus~1_1.L
       jsr       _printf
       addq.w    #4,A7
; while (!valid){
ask_EEPROM_internal_addr_1:
       tst.l     D3
       bne.s     ask_EEPROM_internal_addr_3
; addr = Get6HexDigits(0);
       clr.l     -(A7)
       jsr       _Get6HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; if (addr > 0x01ffff) { // 128k byte memory
       cmp.l     #131071,D2
       bls.s     ask_EEPROM_internal_addr_4
; printf("\r\nAddress cannot be greater than 0x01ffff! Input again: ");
       pea       @m68kus~1_2.L
       jsr       _printf
       addq.w    #4,A7
       bra.s     ask_EEPROM_internal_addr_5
ask_EEPROM_internal_addr_4:
; } else {
; valid = 1;
       moveq     #1,D3
ask_EEPROM_internal_addr_5:
       bra       ask_EEPROM_internal_addr_1
ask_EEPROM_internal_addr_3:
; }
; }
; return addr;
       move.l    D2,D0
       movem.l   (A7)+,D2/D3
       rts
; }
; unsigned char ask_EEPROM_data(void){
       xdef      _ask_EEPROM_data
_ask_EEPROM_data:
       link      A6,#-4
; // ask the data to be written into the EEPROM
; unsigned char data;
; printf("\r\nWhat is the data you want to write into the EEPROM? ");
       pea       @m68kus~1_3.L
       jsr       _printf
       addq.w    #4,A7
; data = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.b    D0,-1(A6)
; return data;
       move.b    -1(A6),D0
       unlk      A6
       rts
; }
; void EEPROM_internal_writting_polling(unsigned char slave_addr_RW){
       xdef      _EEPROM_internal_writting_pollin
_EEPROM_internal_writting_pollin:
       link      A6,#0
       move.l    D2,-(A7)
; int flag = 1;
       moveq     #1,D2
; // EEPROM acknowledge polling, wait for EEPROM's internal writting
; // send the writting control byte with a start signal
; I2C_TX_reg = slave_addr_RW;
       move.b    11(A6),4227078
; while (flag) {
EEPROM_internal_writting_pollin_1:
       tst.l     D2
       beq.s     EEPROM_internal_writting_pollin_3
; I2C_command_reg = start_write_cmd_I2C;
       move.b    #145,4227080
; // wait for the master core to finish transmitting
; while ((I2C_status_reg & 0x02) != 0){}
EEPROM_internal_writting_pollin_4:
       move.b    4227080,D0
       and.b     #2,D0
       beq.s     EEPROM_internal_writting_pollin_6
       bra       EEPROM_internal_writting_pollin_4
EEPROM_internal_writting_pollin_6:
; // if we didn't get ACK bit, then EEPROM is done writting, quit polling 
; if ((I2C_status_reg & 0x80) == 0) {
       move.b    4227080,D0
       and.w     #255,D0
       and.w     #128,D0
       bne.s     EEPROM_internal_writting_pollin_7
; flag = 0;
       clr.l     D2
EEPROM_internal_writting_pollin_7:
       bra       EEPROM_internal_writting_pollin_1
EEPROM_internal_writting_pollin_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; void I2C_init (void) {
       xdef      _I2C_init
_I2C_init:
; // disenable the core to allow us to set the prescale registers
; I2C_control_reg = 0x00; 
       clr.b     4227076
; // set prescale registers to 0x0031
; I2C_prescale_reg_L = 0x31;
       move.b    #49,4227072
; I2C_prescale_reg_H = 0x00;
       clr.b     4227074
; // enable the core, disenable the interrupt
; I2C_control_reg = 0x80;
       move.b    #128,4227076
       rts
; }
; void I2C_TX_command_status (unsigned char data, unsigned char command) {
       xdef      _I2C_TX_command_status
_I2C_TX_command_status:
       link      A6,#0
; //printf("\r\ndata: %x", data);
; //printf("\r\ncommand: %x", command);
; I2C_TX_reg = data;
       move.b    11(A6),4227078
; I2C_command_reg = command;
       move.b    15(A6),4227080
; // check the TIP bit, if it's 1, we wait here
; while ((I2C_status_reg & 0x02) != 0){}
I2C_TX_command_status_1:
       move.b    4227080,D0
       and.b     #2,D0
       beq.s     I2C_TX_command_status_3
       bra       I2C_TX_command_status_1
I2C_TX_command_status_3:
; //printf("\r\nTIP done");
; // wait for acknowledge from slave
; while ((I2C_status_reg & 0x80) != 0){
I2C_TX_command_status_4:
       move.b    4227080,D0
       and.w     #255,D0
       and.w     #128,D0
       beq.s     I2C_TX_command_status_6
; //printf("\r\n%x", I2C_status_reg);
; }
       bra       I2C_TX_command_status_4
I2C_TX_command_status_6:
       unlk      A6
       rts
; //printf("\r\nACK received");
; }
; void I2C_byte_write (void) {
       xdef      _I2C_byte_write
_I2C_byte_write:
       link      A6,#-8
       movem.l   D2/D3/A2,-(A7)
       lea       _I2C_TX_command_status.L,A2
; unsigned char slave_addr_RW;
; unsigned char slave_write_data;
; unsigned char EEPROM_block_select;
; unsigned char EEPROM_internal_addr_H, EEPROM_internal_addr_L;
; unsigned int addr;
; int EEPROM_polling_flag = 1;
       move.l    #1,-4(A6)
; printf("\r\nRandom EEPROM byte write");
       pea       @m68kus~1_4.L
       jsr       _printf
       addq.w    #4,A7
; // get the internal address
; addr = ask_EEPROM_internal_addr();
       jsr       _ask_EEPROM_internal_addr
       move.l    D0,D2
; EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
       move.l    D2,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.b    D0,-6(A6)
; EEPROM_internal_addr_L = addr & 0x0000ff;
       move.l    D2,D0
       and.l     #255,D0
       move.b    D0,-5(A6)
; EEPROM_block_select = (addr & 0x010000) >> 16;
       move.l    D2,D0
       and.l     #65536,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.b    D0,-7(A6)
; slave_write_data = ask_EEPROM_data();
       jsr       _ask_EEPROM_data
       move.b    D0,-8(A6)
; // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
; slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));
       move.w    #160,D0
       move.b    -7(A6),D1
       lsl.b     #1,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D3
; // send the control byte and generate a start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // write EEPROM internal addr (upper and lower byte), no start signal
; I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
       pea       17
       move.b    -6(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);
       pea       17
       move.b    -5(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // write the actual data, and generate a stop condition after receiving an Acknowledge from the slave
; I2C_TX_command_status(slave_write_data, stop_write_cmd_I2C);
       pea       81
       move.b    -8(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; EEPROM_internal_writting_polling(slave_addr_RW);
       and.l     #255,D3
       move.l    D3,-(A7)
       jsr       _EEPROM_internal_writting_pollin
       addq.w    #4,A7
; printf("\r\nEEPROM writting done!");
       pea       @m68kus~1_5.L
       jsr       _printf
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; void I2C_byte_read (void) {
       xdef      _I2C_byte_read
_I2C_byte_read:
       link      A6,#-4
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _I2C_TX_command_status.L,A2
; char slave_addr_RW;
; unsigned char slave_read_data;
; unsigned char EEPROM_block_select;
; unsigned int addr;
; unsigned char EEPROM_internal_addr_H, EEPROM_internal_addr_L;
; printf("\r\nRandom EEPROM byte read");
       pea       @m68kus~1_6.L
       jsr       _printf
       addq.w    #4,A7
; // get the internal address
; addr = ask_EEPROM_internal_addr();
       jsr       _ask_EEPROM_internal_addr
       move.l    D0,D3
; EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
       move.l    D3,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.b    D0,-2(A6)
; EEPROM_internal_addr_L = addr & 0x0000ff;
       move.l    D3,D0
       and.l     #255,D0
       move.b    D0,-1(A6)
; EEPROM_block_select = (addr & 0x010000) >> 16;
       move.l    D3,D0
       and.l     #65536,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.b    D0,D4
; // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
; slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));
       move.w    #160,D0
       move.b    D4,D1
       lsl.b     #1,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D2
; // send the control byte and generate a start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // write EEPROM internal addr (upper and lower byte), no start signal
; I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
       pea       17
       move.b    -2(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);
       pea       17
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // EEPROM tag (b'1010) + chip select ('b00) + block select + read (1)
; slave_addr_RW = (0xa1 | (EEPROM_block_select << 1));
       move.w    #161,D0
       move.b    D4,D1
       lsl.b     #1,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D2
; // send the control byte and generate a repeated start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // set STO bit to 1, set RD bit to 1, set ACk to 1 (NACK), set IACK to 1
; I2C_command_reg = stop_read_NACK_cmd_I2C;
       move.b    #105,4227080
; // polling the IF flag in the status reg
; while ((I2C_status_reg & 0x01) != 1){}
I2C_byte_read_1:
       move.b    4227080,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     I2C_byte_read_3
       bra       I2C_byte_read_1
I2C_byte_read_3:
; slave_read_data = I2C_RX_reg;
       move.b    4227078,-3(A6)
; printf("\r\nEEPROM reading done! %x",slave_read_data);
       move.b    -3(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_7.L
       jsr       _printf
       addq.w    #8,A7
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; unsigned int ask_EEPROM_addr_range(void) {
       xdef      _ask_EEPROM_addr_range
_ask_EEPROM_addr_range:
       movem.l   D2/D3/A2,-(A7)
       lea       _printf.L,A2
; unsigned int size;
; int valid = 0;
       clr.l     D3
; printf("\r\nWhat is the EEPROM address range size (in hex) you want to access? ");
       pea       @m68kus~1_8.L
       jsr       (A2)
       addq.w    #4,A7
; while (!valid) {
ask_EEPROM_addr_range_1:
       tst.l     D3
       bne       ask_EEPROM_addr_range_3
; size = Get6HexDigits(0);
       clr.l     -(A7)
       jsr       _Get6HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; if (size > 0x020000) {
       cmp.l     #131072,D2
       bls.s     ask_EEPROM_addr_range_4
; printf ("\r\nSize cannot be larger than 'h020000 (128K bytes), input again: ");
       pea       @m68kus~1_9.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     ask_EEPROM_addr_range_7
ask_EEPROM_addr_range_4:
; } else if (size == 0) {
       tst.l     D2
       bne.s     ask_EEPROM_addr_range_6
; printf("\r\nSize cannot be 0, the minimum size is 'h000001 (1 byte), input again: ");
       pea       @m68kus~1_10.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     ask_EEPROM_addr_range_7
ask_EEPROM_addr_range_6:
; } else {
; valid = 1;
       moveq     #1,D3
ask_EEPROM_addr_range_7:
       bra       ask_EEPROM_addr_range_1
ask_EEPROM_addr_range_3:
; }
; }
; return size;
       move.l    D2,D0
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; int boundry_checker (int intended_page_size, unsigned int current_addr) {
       xdef      _boundry_checker
_boundry_checker:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    12(A6),D2
; // check boundry crossing, return the appropriate number of bytes we should write in a page write (page_size)
; unsigned int new_addr;
; int page_size;
; // if we write the intended page size, what's the end address we're gonna be at?
; new_addr = current_addr + intended_page_size - 1;
       move.l    D2,D0
       add.l     8(A6),D0
       subq.l    #1,D0
       move.l    D0,D4
; if (current_addr <= 0xffff && new_addr > 0xffff) {
       cmp.l     #65535,D2
       bhi.s     boundry_checker_1
       cmp.l     #65535,D4
       bls.s     boundry_checker_1
; // cross the middle boundry
; page_size = 0xffff - current_addr + 1;
       move.w    #65535,D0
       and.l     #65535,D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D3
       bra.s     boundry_checker_4
boundry_checker_1:
; } else if (current_addr <= 0x1ffff && new_addr > 0x1ffff) {
       cmp.l     #131071,D2
       bhi.s     boundry_checker_3
       cmp.l     #131071,D4
       bls.s     boundry_checker_3
; // cross the end boundry
; page_size = 0x1ffff - current_addr + 1;
       move.l    #131071,D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D3
       bra.s     boundry_checker_4
boundry_checker_3:
; } else {
; page_size = intended_page_size;
       move.l    8(A6),D3
boundry_checker_4:
; }
; return page_size;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; void I2C_multi_write (void) {
       xdef      _I2C_multi_write
_I2C_multi_write:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3,-(A7)
       lea       _I2C_TX_command_status.L,A2
       lea       _printf.L,A3
; unsigned int size, addr, page_index;
; unsigned char slave_addr_RW;
; unsigned char EEPROM_block_select, EEPROM_internal_addr_H, EEPROM_internal_addr_L;
; char command;
; int page_size;
; int page_limit = 128;
       move.l    #128,D6
; unsigned char write_data = 0;
       clr.b     -1(A6)
; printf("\r\nMultipe bytes EEPROM write");
       pea       @m68kus~1_11.L
       jsr       (A3)
       addq.w    #4,A7
; // ask the range of the writting
; size = ask_EEPROM_addr_range();
       jsr       _ask_EEPROM_addr_range
       move.l    D0,D4
; // ask the start address
; addr = ask_EEPROM_internal_addr();
       jsr       _ask_EEPROM_internal_addr
       move.l    D0,D2
; printf("\r\nWritting...");
       pea       @m68kus~1_12.L
       jsr       (A3)
       addq.w    #4,A7
; while (size > 0){
I2C_multi_write_1:
       cmp.l     #0,D4
       bls       I2C_multi_write_3
; command = write_cmd_I2C;
       move.b    #17,-2(A6)
; if (size <= page_limit) {
       cmp.l     D6,D4
       bhi.s     I2C_multi_write_4
; page_size = boundry_checker(size, addr);
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       jsr       _boundry_checker
       addq.w    #8,A7
       move.l    D0,D3
       bra.s     I2C_multi_write_6
I2C_multi_write_4:
; } else if (size > page_limit) {
       cmp.l     D6,D4
       bls.s     I2C_multi_write_6
; page_size = boundry_checker(page_limit, addr);
       move.l    D2,-(A7)
       move.l    D6,-(A7)
       jsr       _boundry_checker
       addq.w    #8,A7
       move.l    D0,D3
I2C_multi_write_6:
; }
; EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
       move.l    D2,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.b    D0,-4(A6)
; EEPROM_internal_addr_L = addr & 0x0000ff;
       move.l    D2,D0
       and.l     #255,D0
       move.b    D0,-3(A6)
; EEPROM_block_select = (addr & 0x010000) >> 16;
       move.l    D2,D0
       and.l     #65536,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.b    D0,-5(A6)
; // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
; slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));
       move.w    #160,D0
       move.b    -5(A6),D1
       lsl.b     #1,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D7
; // send the control byte and generate a start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D7
       ext.l     D7
       move.l    D7,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // write EEPROM internal addr (upper and lower byte), no start signal
; I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
       pea       17
       move.b    -4(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);
       pea       17
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; for (page_index = 0; page_index < page_size; page_index++) {
       clr.l     D5
I2C_multi_write_8:
       cmp.l     D3,D5
       bhs       I2C_multi_write_10
; // write the actual data (128 bytes), generate a stop signal at the 128th byte
; if (page_index == page_size - 1) {
       move.l    D3,D0
       subq.l    #1,D0
       cmp.l     D0,D5
       bne.s     I2C_multi_write_11
; command = stop_write_cmd_I2C;
       move.b    #81,-2(A6)
I2C_multi_write_11:
; }
; I2C_TX_command_status(write_data, command);
       move.b    -2(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; write_data ++;
       addq.b    #1,-1(A6)
       addq.l    #1,D5
       bra       I2C_multi_write_8
I2C_multi_write_10:
; }
; EEPROM_internal_writting_polling(slave_addr_RW);
       and.l     #255,D7
       move.l    D7,-(A7)
       jsr       _EEPROM_internal_writting_pollin
       addq.w    #4,A7
; addr = addr + page_size;
       add.l     D3,D2
; size = size - page_size;
       sub.l     D3,D4
       bra       I2C_multi_write_1
I2C_multi_write_3:
; // refresh the writting command to exclude stop signal
; }
; printf("\r\nMultiple bytes writting done");
       pea       @m68kus~1_13.L
       jsr       (A3)
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3
       unlk      A6
       rts
; }
; void I2C_multi_read (void) {
       xdef      _I2C_multi_read
_I2C_multi_read:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3,-(A7)
       lea       _I2C_TX_command_status.L,A2
; unsigned int size, addr, page_index;
; unsigned char slave_addr_RW;
; unsigned char EEPROM_block_select, EEPROM_internal_addr_H, EEPROM_internal_addr_L;
; char command;
; int page_size;
; unsigned char read_data;
; unsigned int counter = 0;
       moveq     #0,D7
; unsigned printing_step_size = 1;
       move.w    #1,A3
; printf("\r\nMultiple bytes EEPROM read");
       pea       @m68kus~1_14.L
       jsr       _printf
       addq.w    #4,A7
; // ask the range of the writting
; size = ask_EEPROM_addr_range();
       jsr       _ask_EEPROM_addr_range
       move.l    D0,D3
; // ask the start address
; addr = ask_EEPROM_internal_addr();
       jsr       _ask_EEPROM_internal_addr
       move.l    D0,D2
; // if we have more than 10 items to read, we only print out 10 lines.
; if (size > 10){
       cmp.l     #10,D3
       bls.s     I2C_multi_read_1
; printing_step_size = size/10;
       move.l    D3,-(A7)
       pea       10
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,A3
I2C_multi_read_1:
; }
; while (size > 0){
I2C_multi_read_3:
       cmp.l     #0,D3
       bls       I2C_multi_read_5
; command = read_ACK_cmd_I2C;
       move.b    #33,-2(A6)
; page_size = boundry_checker(size, addr);
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _boundry_checker
       addq.w    #8,A7
       move.l    D0,D4
; EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
       move.l    D2,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.b    D0,-4(A6)
; EEPROM_internal_addr_L = addr & 0x0000ff;
       move.l    D2,D0
       and.l     #255,D0
       move.b    D0,-3(A6)
; EEPROM_block_select = (addr & 0x010000) >> 16;
       move.l    D2,D0
       and.l     #65536,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.b    D0,-5(A6)
; // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
; slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));
       move.w    #160,D0
       move.b    -5(A6),D1
       lsl.b     #1,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D6
; // send the control byte and generate a start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D6
       ext.l     D6
       move.l    D6,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // write EEPROM internal addr (upper and lower byte), no start signal
; I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
       pea       17
       move.b    -4(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);
       pea       17
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // EEPROM tag (b'1010) + chip select ('b00) + block select + read (1)
; slave_addr_RW = (0xa1 | (EEPROM_block_select << 1));
       move.w    #161,D0
       move.b    -5(A6),D1
       lsl.b     #1,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D6
; // send the control byte and generate a repeated start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D6
       ext.l     D6
       move.l    D6,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; for (page_index = 0; page_index < page_size; page_index++) {
       clr.l     D5
I2C_multi_read_6:
       cmp.l     D4,D5
       bhs       I2C_multi_read_8
; if (page_index == page_size - 1) {
       move.l    D4,D0
       subq.l    #1,D0
       cmp.l     D0,D5
       bne.s     I2C_multi_read_9
; command = stop_read_NACK_cmd_I2C;
       move.b    #105,-2(A6)
I2C_multi_read_9:
; }
; I2C_command_reg = command;
       move.b    -2(A6),4227080
; // polling the IF flag in the status reg
; while ((I2C_status_reg & 0x01) != 1){}
I2C_multi_read_11:
       move.b    4227080,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     I2C_multi_read_13
       bra       I2C_multi_read_11
I2C_multi_read_13:
; if (counter % printing_step_size == 0){
       move.l    D7,-(A7)
       move.l    A3,-(A7)
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     I2C_multi_read_14
; read_data = I2C_RX_reg;
       move.b    4227078,-1(A6)
; printf("\r\nAddress: %x, Read data: %x",counter & 0x01ffff, read_data);
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D7,D1
       and.l     #131071,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_15.L
       jsr       _printf
       add.w     #12,A7
I2C_multi_read_14:
; }
; counter ++;
       addq.l    #1,D7
       addq.l    #1,D5
       bra       I2C_multi_read_6
I2C_multi_read_8:
; }
; addr = addr + page_size;
       add.l     D4,D2
; size = size - page_size;        
       sub.l     D4,D3
       bra       I2C_multi_read_3
I2C_multi_read_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3
       unlk      A6
       rts
; }
; }
; void DAC(void) {
       xdef      _DAC
_DAC:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _I2C_TX_command_status.L,A2
; unsigned char slave_addr_RW;
; unsigned char control_byte;
; unsigned char command = write_cmd_I2C;
       moveq     #17,D2
; printf("\r\nUsing DAC to control LED");
       pea       @m68kus~1_16.L
       jsr       _printf
       addq.w    #4,A7
; // PCF8591 tag (b'1001) + chip select (b'000) + write (0)
; slave_addr_RW = 0x90;
       move.b    #144,-2(A6)
; // only enable the analog bit
; control_byte = 0x40;
       move.b    #64,-1(A6)
; // send the slave address byte and generate a start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       move.b    -2(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; //printf("\r\nslave address sent");
; // send the control byte to PCF8591
; I2C_TX_command_status(control_byte, write_cmd_I2C);
       pea       17
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; //printf("\r\ncontrol byte sent");
; /*
; for (i = 0; i <2560; i++) {
; // keep writting digital signal
; if (i == 2559) {
; // generate a stop signal at the last byte
; command = stop_write_cmd_I2C;
; }
; I2C_TX_command_status(digital_write_data, command);
; digital_write_data ++;
; }
; */
; while (1){
DAC_1:
; I2C_TX_command_status(0xff,command);
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       pea       255
       jsr       (A2)
       addq.w    #8,A7
; Wait500ms ();
       jsr       _Wait500ms
; I2C_TX_command_status(0x00,command);
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #8,A7
; Wait500ms ();
       jsr       _Wait500ms
       bra       DAC_1
; }
; }
; void ADC(void) {
       xdef      _ADC
_ADC:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _I2C_TX_command_status.L,A2
; unsigned char slave_addr_RW;
; unsigned char control_byte;
; unsigned char command = read_ACK_cmd_I2C;
       move.b    #33,-2(A6)
; unsigned char read_data;
; printf("\r\nReading values from the ADC");
       pea       @m68kus~1_17.L
       jsr       _printf
       addq.w    #4,A7
; // PCF8591 tag (b'1001) + chip select (b'000) + write (0)
; slave_addr_RW = 0x90;
       move.b    #144,D2
; // generate the control byte based on the channel user selected
; control_byte = ask_ADC_channel();
       jsr       _ask_ADC_channel
       move.b    D0,-3(A6)
; // send the slave address byte and generate a start signal
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // send the control byte to PCF8591
; I2C_TX_command_status(control_byte, write_cmd_I2C);
       pea       17
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // PCF8591 tag (b'1001) + chip select (b'000) + read (1)
; slave_addr_RW = 0x91;
       move.b    #145,D2
; // repeated start
; I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
       pea       145
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // send the slave address byte and generate a repeated start signal
; //I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
; while (1) {
ADC_1:
; I2C_command_reg = command;
       move.b    -2(A6),4227080
; // polling the IF flag in the status reg
; while ((I2C_status_reg & 0x01) != 1){}
ADC_4:
       move.b    4227080,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     ADC_6
       bra       ADC_4
ADC_6:
; read_data = I2C_RX_reg;
       move.b    4227078,-1(A6)
; printf("\r\nRead data: %x", read_data);
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_18.L
       jsr       _printf
       addq.w    #8,A7
       bra       ADC_1
; }
; }
; unsigned char ask_ADC_channel (void){
       xdef      _ask_ADC_channel
_ask_ADC_channel:
       movem.l   D2/D3/D4,-(A7)
; unsigned char channel;
; unsigned char control_byte;
; int valid = 0;
       clr.l     D2
; while (!valid){
ask_ADC_channel_1:
       tst.l     D2
       bne       ask_ADC_channel_3
; printf("\r\nWhich channel you want to read? 1. Potentiometer 2.Photoresistor 3.Thermistor ");
       pea       @m68kus~1_19.L
       jsr       _printf
       addq.w    #4,A7
; channel = Get1HexDigits(0);
       clr.l     -(A7)
       jsr       _Get1HexDigits
       addq.w    #4,A7
       move.b    D0,D4
; if (channel == 1) {
       cmp.b     #1,D4
       bne.s     ask_ADC_channel_4
; control_byte = 0x01;
       moveq     #1,D3
; valid = 1;
       moveq     #1,D2
       bra.s     ask_ADC_channel_9
ask_ADC_channel_4:
; } else if (channel == 2) {
       cmp.b     #2,D4
       bne.s     ask_ADC_channel_6
; control_byte = 0x02;
       moveq     #2,D3
; valid = 1;
       moveq     #1,D2
       bra.s     ask_ADC_channel_9
ask_ADC_channel_6:
; } else if (channel == 3) {
       cmp.b     #3,D4
       bne.s     ask_ADC_channel_8
; control_byte = 0x03;
       moveq     #3,D3
; valid = 1;
       moveq     #1,D2
       bra.s     ask_ADC_channel_9
ask_ADC_channel_8:
; } else {
; printf("\r\nInvalid selection!");
       pea       @m68kus~1_20.L
       jsr       _printf
       addq.w    #4,A7
; valid = 0;
       clr.l     D2
ask_ADC_channel_9:
       bra       ask_ADC_channel_1
ask_ADC_channel_3:
; }
; }
; return control_byte;
       move.b    D3,D0
       movem.l   (A7)+,D2/D3/D4
       rts
; }
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; void Timer_ISR()
; {
       xdef      _Timer_ISR
_Timer_ISR:
; if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
       move.b    4194354,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_1
; Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194354
; PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
       move.b    _Timer1Count.L,D0
       addq.b    #1,_Timer1Count.L
       move.b    D0,4194304
Timer_ISR_1:
; }
; if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
       move.b    4194358,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_3
; Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194358
; PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
       move.b    _Timer2Count.L,D0
       addq.b    #1,_Timer2Count.L
       move.b    D0,4194308
Timer_ISR_3:
; }
; if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
       move.b    4194362,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_5
; Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194362
; HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
       move.b    _Timer3Count.L,D0
       addq.b    #1,_Timer3Count.L
       move.b    D0,4194320
Timer_ISR_5:
; }
; if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
       move.b    4194366,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_7
; Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194366
; HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
       move.b    _Timer4Count.L,D0
       addq.b    #1,_Timer4Count.L
       move.b    D0,4194322
Timer_ISR_7:
       rts
; }
; }
; /*****************************************************************************************
; **	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void ACIA_ISR()
; {}
       xdef      _ACIA_ISR
_ACIA_ISR:
       rts
; /***************************************************************************************
; **	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void PIA_ISR()
; {}
       xdef      _PIA_ISR
_PIA_ISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 2 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key2PressISR()
; {}
       xdef      _Key2PressISR
_Key2PressISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 1 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key1PressISR()
; {}
       xdef      _Key1PressISR
_Key1PressISR:
       rts
; /************************************************************************************
; **   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
; ************************************************************************************/
; void Wait1ms(void)
; {
       xdef      _Wait1ms
_Wait1ms:
       move.l    D2,-(A7)
; int  i ;
; for(i = 0; i < 1000; i ++)
       clr.l     D2
Wait1ms_1:
       cmp.l     #1000,D2
       bge.s     Wait1ms_3
       addq.l    #1,D2
       bra       Wait1ms_1
Wait1ms_3:
       move.l    (A7)+,D2
       rts
; ;
; }
; /************************************************************************************
; **  Subroutine to give the 68000 something useless to do to waste 3 mSec
; **************************************************************************************/
; void Wait3ms(void)
; {
       xdef      _Wait3ms
_Wait3ms:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 3; i++)
       clr.l     D2
Wait3ms_1:
       cmp.l     #3,D2
       bge.s     Wait3ms_3
; Wait1ms() ;
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       Wait3ms_1
Wait3ms_3:
       move.l    (A7)+,D2
       rts
; }
; void Wait500ms (void) {
       xdef      _Wait500ms
_Wait500ms:
       move.l    D2,-(A7)
; int i;
; for (i = 0; i<500; i++){
       clr.l     D2
Wait500ms_1:
       cmp.l     #500,D2
       bge.s     Wait500ms_3
; Wait1ms();
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       Wait500ms_1
Wait500ms_3:
       move.l    (A7)+,D2
       rts
; }
; }
; /*********************************************************************************************
; **  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
; **  Sets it for parallel port and 2 line display mode (if I recall correctly)
; *********************************************************************************************/
; void Init_LCD(void)
; {
       xdef      _Init_LCD
_Init_LCD:
; LCDcommand = 0x0c ;
       move.b    #12,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDcommand = 0x38 ;
       move.b    #56,4194336
; Wait3ms() ;
       jsr       _Wait3ms
       rts
; }
; /*********************************************************************************************
; **  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level output function to 6850 ACIA
; **  This routine provides the basic functionality to output a single character to the serial Port
; **  to allow the board to communicate with HyperTerminal Program
; **
; **  NOTE you do not call this function directly, instead you call the normal putchar() function
; **  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
; **  call _putch() also
; *********************************************************************************************************/
; int _putch( int c)
; {
       xdef      __putch
__putch:
       link      A6,#0
; while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.l     #127,D0
       move.b    D0,4194370
; return c ;                                              // putchar() expects the character to be returned
       move.l    8(A6),D0
       unlk      A6
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level input function to 6850 ACIA
; **  This routine provides the basic functionality to input a single character from the serial Port
; **  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
; **
; **  NOTE you do not call this function directly, instead you call the normal getchar() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       move.l    D2,-(A7)
; char c ;
; while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; c = (RS232_RxData & (char)(0x7f));
       move.b    4194370,D0
       and.b     #127,D0
       move.b    D0,D2
; _putch(c);
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       __putch
       addq.w    #4,A7
; return c;                   // read received character, mask off top bit and return as 7 bit ASCII character
       ext.w     D2
       ext.l     D2
       move.l    D2,D0
       move.l    (A7)+,D2
       rts
; }
; char xtod(int c)
; {
       xdef      _xtod
_xtod:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if ((char)(c) <= (char)('9'))
       cmp.b     #57,D2
       bgt.s     xtod_1
; return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
       move.b    D2,D0
       sub.b     #48,D0
       bra.s     xtod_3
xtod_1:
; else if((char)(c) > (char)('F'))    // assume lower case
       cmp.b     #70,D2
       ble.s     xtod_4
; return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
       move.b    D2,D0
       sub.b     #87,D0
       bra.s     xtod_3
xtod_4:
; else
; return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
       move.b    D2,D0
       sub.b     #55,D0
xtod_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get1HexDigits(char *CheckSumPtr)
; {
       xdef      _Get1HexDigits
_Get1HexDigits:
       link      A6,#0
       move.l    D2,-(A7)
; register int i = xtod(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D2
; if(CheckSumPtr)
       tst.l     8(A6)
       beq.s     Get1HexDigits_1
; *CheckSumPtr += i ;
       move.l    8(A6),A0
       add.b     D2,(A0)
Get1HexDigits_1:
; return i; 
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get2HexDigits(char *CheckSumPtr)
; {
       xdef      _Get2HexDigits
_Get2HexDigits:
       link      A6,#0
       move.l    D2,-(A7)
; register int i = (xtod(_getch()) << 4) | (xtod(_getch()));
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       __getch
       move.l    (A7)+,D1
       move.l    D0,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; if(CheckSumPtr)
       tst.l     8(A6)
       beq.s     Get2HexDigits_1
; *CheckSumPtr += i ;
       move.l    8(A6),A0
       add.b     D2,(A0)
Get2HexDigits_1:
; return i ;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get4HexDigits(char *CheckSumPtr)
; {
       xdef      _Get4HexDigits
_Get4HexDigits:
       link      A6,#0
; return (Get2HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get6HexDigits(char *CheckSumPtr)
; {
       xdef      _Get6HexDigits
_Get6HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get8HexDigits(char *CheckSumPtr)
; {
       xdef      _Get8HexDigits
_Get8HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 16) | (Get4HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; /******************************************************************************
; **  Subroutine to output a single character to the 2 row LCD display
; **  It is assumed the character is an ASCII code and it will be displayed at the
; **  current cursor position
; *******************************************************************************/
; void LCDOutchar(int c)
; {
       xdef      _LCDOutchar
_LCDOutchar:
       link      A6,#0
; LCDdata = (char)(c);
       move.l    8(A6),D0
       move.b    D0,4194338
; Wait1ms() ;
       jsr       _Wait1ms
       unlk      A6
       rts
; }
; /**********************************************************************************
; *subroutine to output a message at the current cursor position of the LCD display
; ************************************************************************************/
; void LCDOutMessage(char *theMessage)
; {
       xdef      _LCDOutMessage
_LCDOutMessage:
       link      A6,#-4
; char c ;
; while((c = *theMessage++) != 0)     // output characters from the string until NULL
LCDOutMessage_1:
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),-1(A6)
       move.b    (A0),D0
       beq.s     LCDOutMessage_3
; LCDOutchar(c) ;
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _LCDOutchar
       addq.w    #4,A7
       bra       LCDOutMessage_1
LCDOutMessage_3:
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to clear the line by issuing 24 space characters
; *******************************************************************************/
; void LCDClearln(void)
; {
       xdef      _LCDClearln
_LCDClearln:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 24; i ++)
       clr.l     D2
LCDClearln_1:
       cmp.l     #24,D2
       bge.s     LCDClearln_3
; LCDOutchar(' ') ;       // write a space char to the LCD display
       pea       32
       jsr       _LCDOutchar
       addq.w    #4,A7
       addq.l    #1,D2
       bra       LCDClearln_1
LCDClearln_3:
       move.l    (A7)+,D2
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 1 and clear that line
; *******************************************************************************/
; void LCDLine1Message(char *theMessage)
; {
       xdef      _LCDLine1Message
_LCDLine1Message:
       link      A6,#0
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 2 and clear that line
; *******************************************************************************/
; void LCDLine2Message(char *theMessage)
; {
       xdef      _LCDLine2Message
_LCDLine2Message:
       link      A6,#0
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /*********************************************************************************************************************************
; **  IMPORTANT FUNCTION
; **  This function install an exception handler so you can capture and deal with any 68000 exception in your program
; **  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
; **  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
; **  Calling this function allows you to deal with Interrupts for example
; ***********************************************************************************************************************************/
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       xdef      _InstallExceptionHandler
_InstallExceptionHandler:
       link      A6,#-4
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
       move.l    #184549376,-4(A6)
; RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
       move.l    -4(A6),A0
       move.l    12(A6),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; /******************************************************************************************************************************
; * Start of user program
; ******************************************************************************************************************************/
; void main()
; {   
       xdef      _main
_main:
       link      A6,#-172
       movem.l   D2/D3/A2,-(A7)
       lea       _InstallExceptionHandler.L,A2
; unsigned int row, i=0, count=0, counter1=1;
       clr.l     -168(A6)
       clr.l     -164(A6)
       move.l    #1,-160(A6)
; char c, text[150] ;
; int f;
; int valid;
; int PassFailFlag = 1 ;
       move.l    #1,-4(A6)
; i = x = y = z = PortA_Count =0;
       clr.l     _PortA_Count.L
       clr.l     _z.L
       clr.l     _y.L
       clr.l     _x.L
       clr.l     -168(A6)
; Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;
       clr.b     _Timer4Count.L
       clr.b     _Timer3Count.L
       clr.b     _Timer2Count.L
       clr.b     _Timer1Count.L
; InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
       pea       25
       pea       _PIA_ISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
       pea       26
       pea       _ACIA_ISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
       pea       27
       pea       _Timer_ISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
       pea       28
       pea       _Key2PressISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ
       pea       29
       pea       _Key1PressISR.L
       jsr       (A2)
       addq.w    #8,A7
; Timer1Data = 0x10;		// program time delay into timers 1-4
       move.b    #16,4194352
; Timer2Data = 0x20;
       move.b    #32,4194356
; Timer3Data = 0x15;
       move.b    #21,4194360
; Timer4Data = 0x25;
       move.b    #37,4194364
; Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
       move.b    #3,4194354
; Timer2Control = 3;
       move.b    #3,4194358
; Timer3Control = 3;
       move.b    #3,4194362
; Timer4Control = 3;
       move.b    #3,4194366
; Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
       jsr       _Init_LCD
; Init_RS232() ;          // initialise the RS232 port for use with hyper terminal
       jsr       _Init_RS232
; /************************************************************************************************
; **  Test of scanf function
; ************************************************************************************************/
; /*scanflush() ;                       // flush any text that may have been typed ahead
; printf("\r\nEnter Integer: ") ;
; scanf("%d", &i) ;
; printf("You entered %d", i) ;
; sprintf(text, "Hello CPEN 412 Student") ;
; LCDLine1Message(text) ;
; printf("\r\nHello CPEN 412 Student\r\nYour LEDs should be Flashing") ;
; printf("\r\nYour LCD should be displaying") ;
; while(1)
; ;*/
; //printf("\r\nBig Brother is watching you");
; I2C_init ();
       jsr       _I2C_init
; //I2C_byte_write();
; //I2C_byte_write();
; //I2C_multi_write();
; //I2C_byte_read();
; /*I2C_byte_read();
; I2C_byte_read();
; I2C_byte_read();
; I2C_byte_read();*/
; //I2C_multi_read();
; //DAC();
; //ADC();
; while(1) {
main_1:
; valid = 0;
       clr.l     D3
; while (!valid) {
main_4:
       tst.l     D3
       bne       main_6
; printf("\r\nWhich function you want to run?\n1.EEPROM single byte write\n2.EEPROM single byte read\n3.EEPROM page write\n4.EEPROM page read\n5.DAC->LED\n6.ADC<-sensors ");
       pea       @m68kus~1_21.L
       jsr       _printf
       addq.w    #4,A7
; f = Get1HexDigits(0);
       clr.l     -(A7)
       jsr       _Get1HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; if (f >= 1 && f <= 6) {
       cmp.l     #1,D2
       blt.s     main_7
       cmp.l     #6,D2
       bgt.s     main_7
; valid = 1;
       moveq     #1,D3
       bra.s     main_8
main_7:
; } else {
; printf("\r\nInvalid selection! ");
       pea       @m68kus~1_22.L
       jsr       _printf
       addq.w    #4,A7
; valid = 0;
       clr.l     D3
main_8:
       bra       main_4
main_6:
; }
; }
; if (f == 1){
       cmp.l     #1,D2
       bne.s     main_9
; I2C_byte_write();
       jsr       _I2C_byte_write
       bra       main_19
main_9:
; } else if (f == 2){
       cmp.l     #2,D2
       bne.s     main_11
; I2C_byte_read();
       jsr       _I2C_byte_read
       bra.s     main_19
main_11:
; } else if (f == 3){
       cmp.l     #3,D2
       bne.s     main_13
; I2C_multi_write();
       jsr       _I2C_multi_write
       bra.s     main_19
main_13:
; } else if (f == 4){
       cmp.l     #4,D2
       bne.s     main_15
; I2C_multi_read();
       jsr       _I2C_multi_read
       bra.s     main_19
main_15:
; } else if (f == 5){
       cmp.l     #5,D2
       bne.s     main_17
; DAC();
       jsr       _DAC
       bra.s     main_19
main_17:
; } else if (f == 6){
       cmp.l     #6,D2
       bne.s     main_19
; ADC();
       jsr       _ADC
main_19:
       bra       main_1
; }
; }
; // programs should NOT exit as there is nothing to Exit TO !!!!!!
; // There is no OS - just press the reset button to end program and call debug
; }
       section   const
@m68kus~1_1:
       dc.b      13,10,87,104,97,116,32,105,115,32,116,104,101
       dc.b      32,105,110,116,101,114,110,97,108,32,69,69,80
       dc.b      82,79,77,32,97,100,100,114,101,115,115,32,121
       dc.b      111,117,32,119,97,110,116,32,116,111,32,97,99
       dc.b      99,101,115,115,63,32,0
@m68kus~1_2:
       dc.b      13,10,65,100,100,114,101,115,115,32,99,97,110
       dc.b      110,111,116,32,98,101,32,103,114,101,97,116
       dc.b      101,114,32,116,104,97,110,32,48,120,48,49,102
       dc.b      102,102,102,33,32,73,110,112,117,116,32,97,103
       dc.b      97,105,110,58,32,0
@m68kus~1_3:
       dc.b      13,10,87,104,97,116,32,105,115,32,116,104,101
       dc.b      32,100,97,116,97,32,121,111,117,32,119,97,110
       dc.b      116,32,116,111,32,119,114,105,116,101,32,105
       dc.b      110,116,111,32,116,104,101,32,69,69,80,82,79
       dc.b      77,63,32,0
@m68kus~1_4:
       dc.b      13,10,82,97,110,100,111,109,32,69,69,80,82,79
       dc.b      77,32,98,121,116,101,32,119,114,105,116,101
       dc.b      0
@m68kus~1_5:
       dc.b      13,10,69,69,80,82,79,77,32,119,114,105,116,116
       dc.b      105,110,103,32,100,111,110,101,33,0
@m68kus~1_6:
       dc.b      13,10,82,97,110,100,111,109,32,69,69,80,82,79
       dc.b      77,32,98,121,116,101,32,114,101,97,100,0
@m68kus~1_7:
       dc.b      13,10,69,69,80,82,79,77,32,114,101,97,100,105
       dc.b      110,103,32,100,111,110,101,33,32,37,120,0
@m68kus~1_8:
       dc.b      13,10,87,104,97,116,32,105,115,32,116,104,101
       dc.b      32,69,69,80,82,79,77,32,97,100,100,114,101,115
       dc.b      115,32,114,97,110,103,101,32,115,105,122,101
       dc.b      32,40,105,110,32,104,101,120,41,32,121,111,117
       dc.b      32,119,97,110,116,32,116,111,32,97,99,99,101
       dc.b      115,115,63,32,0
@m68kus~1_9:
       dc.b      13,10,83,105,122,101,32,99,97,110,110,111,116
       dc.b      32,98,101,32,108,97,114,103,101,114,32,116,104
       dc.b      97,110,32,39,104,48,50,48,48,48,48,32,40,49
       dc.b      50,56,75,32,98,121,116,101,115,41,44,32,105
       dc.b      110,112,117,116,32,97,103,97,105,110,58,32,0
@m68kus~1_10:
       dc.b      13,10,83,105,122,101,32,99,97,110,110,111,116
       dc.b      32,98,101,32,48,44,32,116,104,101,32,109,105
       dc.b      110,105,109,117,109,32,115,105,122,101,32,105
       dc.b      115,32,39,104,48,48,48,48,48,49,32,40,49,32
       dc.b      98,121,116,101,41,44,32,105,110,112,117,116
       dc.b      32,97,103,97,105,110,58,32,0
@m68kus~1_11:
       dc.b      13,10,77,117,108,116,105,112,101,32,98,121,116
       dc.b      101,115,32,69,69,80,82,79,77,32,119,114,105
       dc.b      116,101,0
@m68kus~1_12:
       dc.b      13,10,87,114,105,116,116,105,110,103,46,46,46
       dc.b      0
@m68kus~1_13:
       dc.b      13,10,77,117,108,116,105,112,108,101,32,98,121
       dc.b      116,101,115,32,119,114,105,116,116,105,110,103
       dc.b      32,100,111,110,101,0
@m68kus~1_14:
       dc.b      13,10,77,117,108,116,105,112,108,101,32,98,121
       dc.b      116,101,115,32,69,69,80,82,79,77,32,114,101
       dc.b      97,100,0
@m68kus~1_15:
       dc.b      13,10,65,100,100,114,101,115,115,58,32,37,120
       dc.b      44,32,82,101,97,100,32,100,97,116,97,58,32,37
       dc.b      120,0
@m68kus~1_16:
       dc.b      13,10,85,115,105,110,103,32,68,65,67,32,116
       dc.b      111,32,99,111,110,116,114,111,108,32,76,69,68
       dc.b      0
@m68kus~1_17:
       dc.b      13,10,82,101,97,100,105,110,103,32,118,97,108
       dc.b      117,101,115,32,102,114,111,109,32,116,104,101
       dc.b      32,65,68,67,0
@m68kus~1_18:
       dc.b      13,10,82,101,97,100,32,100,97,116,97,58,32,37
       dc.b      120,0
@m68kus~1_19:
       dc.b      13,10,87,104,105,99,104,32,99,104,97,110,110
       dc.b      101,108,32,121,111,117,32,119,97,110,116,32
       dc.b      116,111,32,114,101,97,100,63,32,49,46,32,80
       dc.b      111,116,101,110,116,105,111,109,101,116,101
       dc.b      114,32,50,46,80,104,111,116,111,114,101,115
       dc.b      105,115,116,111,114,32,51,46,84,104,101,114
       dc.b      109,105,115,116,111,114,32,0
@m68kus~1_20:
       dc.b      13,10,73,110,118,97,108,105,100,32,115,101,108
       dc.b      101,99,116,105,111,110,33,0
@m68kus~1_21:
       dc.b      13,10,87,104,105,99,104,32,102,117,110,99,116
       dc.b      105,111,110,32,121,111,117,32,119,97,110,116
       dc.b      32,116,111,32,114,117,110,63,10,49,46,69,69
       dc.b      80,82,79,77,32,115,105,110,103,108,101,32,98
       dc.b      121,116,101,32,119,114,105,116,101,10,50,46
       dc.b      69,69,80,82,79,77,32,115,105,110,103,108,101
       dc.b      32,98,121,116,101,32,114,101,97,100,10,51,46
       dc.b      69,69,80,82,79,77,32,112,97,103,101,32,119,114
       dc.b      105,116,101,10,52,46,69,69,80,82,79,77,32,112
       dc.b      97,103,101,32,114,101,97,100,10,53,46,68,65
       dc.b      67,45,62,76,69,68,10,54,46,65,68,67,60,45,115
       dc.b      101,110,115,111,114,115,32,0
@m68kus~1_22:
       dc.b      13,10,73,110,118,97,108,105,100,32,115,101,108
       dc.b      101,99,116,105,111,110,33,32,0
       section   bss
       xdef      _i
_i:
       ds.b      4
       xdef      _x
_x:
       ds.b      4
       xdef      _y
_y:
       ds.b      4
       xdef      _z
_z:
       ds.b      4
       xdef      _PortA_Count
_PortA_Count:
       ds.b      4
       xdef      _Timer1Count
_Timer1Count:
       ds.b      1
       xdef      _Timer2Count
_Timer2Count:
       ds.b      1
       xdef      _Timer3Count
_Timer3Count:
       ds.b      1
       xdef      _Timer4Count
_Timer4Count:
       ds.b      1
       xref      ULDIV
       xref      _printf
