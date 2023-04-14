; D:\UBC-CPEN-412\ASSIGNMENT_1\SRAM_TEST.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
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
; #define StartOfExceptionVectorTable 0x08030000
; //DRAM
; //#define StartOfExceptionVectorTable 0x0B000000
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
; /**********************************************************************************************
; SRAM memory test 
; ***********************************************************************************************/
; #define sram_base   *(volatile unsigned short *)(0x08020000)
; /*********************************************************************************************************************************
; (( DO NOT initialise global variables here, do it main even if you want 0
; (( it's a limitation of the compiler
; (( YOU HAVE BEEN WARNED
; *********************************************************************************************************************************/
; unsigned int i, x, y, z, PortA_Count;
; unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;
; /*******************************************************************************************
; ** Function Prototypes
; *******************************************************************************************/
; void Wait1ms(void);
; void Wait3ms(void);
; void Init_LCD(void) ;
; void LCDOutchar(int c);
; void LCDOutMess(char *theMessage);
; void LCDClearln(void);
; void LCDline1Message(char *theMessage);
; void LCDline2Message(char *theMessage);
; int sprintf(char *out, const char *format, ...) ;
; int data_bus_test(void);
; void ask_addr_range (unsigned int*, int);
; unsigned char byte_data (int data_pattern);
; unsigned short word_data (int data_pattern);
; unsigned int long_word_data (int data_pattern);
; int byte_test (unsigned char byte, unsigned int* addr_array);
; int word_test (unsigned short word, unsigned int* addr_array);
; int long_word_test (unsigned int long_word, unsigned int* addr_array);
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; void Timer_ISR()
; {
       section   code
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
       link      A6,#-4
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
; return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
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
       move.l    #134414336,-4(A6)
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
; int data_bus_test (void) {
       xdef      _data_bus_test
_data_bus_test:
       movem.l   D2/D3/A2,-(A7)
       lea       _printf.L,A2
; unsigned short test_data = 1;
       moveq     #1,D2
; int shift_count;
; for (shift_count = 0; shift_count < 16; shift_count++){
       clr.l     D3
data_bus_test_1:
       cmp.l     #16,D3
       bge       data_bus_test_3
; printf("\r\ndata bus test data: %d", test_data);
       and.l     #65535,D2
       move.l    D2,-(A7)
       pea       @sram_t~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; sram_base = test_data;
       move.w    D2,134348800
; if (sram_base != test_data ) {
       cmp.w     134348800,D2
       beq.s     data_bus_test_4
; printf ("\r\ndata bus test failed with data: %d", test_data);
       and.l     #65535,D2
       move.l    D2,-(A7)
       pea       @sram_t~1_2.L
       jsr       (A2)
       addq.w    #8,A7
; return 0;
       clr.l     D0
       bra.s     data_bus_test_6
data_bus_test_4:
; }
; test_data = test_data << 1; 
       lsl.w     #1,D2
       addq.l    #1,D3
       bra       data_bus_test_1
data_bus_test_3:
; }
; printf ("\r\ndata bus test passed!");
       pea       @sram_t~1_3.L
       jsr       (A2)
       addq.w    #4,A7
; return 0; 
       clr.l     D0
data_bus_test_6:
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; // Returning an array containing the start and the end address of the test (two hex numbers)
; void ask_addr_range (unsigned int* addr_array, int data_length) {
       xdef      _ask_addr_range
_ask_addr_range:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
       move.l    8(A6),D2
; int start_addr_valid = 0;
       clr.l     D4
; int end_addr_valid = 0;
       clr.l     D3
; while (!start_addr_valid) {
ask_addr_range_1:
       tst.l     D4
       bne       ask_addr_range_3
; printf("\r\nProvide the start address of the test.\n");
       pea       @sram_t~1_4.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%x", addr_array);
       move.l    D2,-(A7)
       pea       @sram_t~1_5.L
       jsr       _scanf
       addq.w    #8,A7
; if (addr_array[0] < 134348800) {
       move.l    D2,A0
       move.l    (A0),D0
       cmp.l     #134348800,D0
       bhs.s     ask_addr_range_4
; printf ("The start address is smaller than 0x08020000, invalid!\n");
       pea       @sram_t~1_6.L
       jsr       (A2)
       addq.w    #4,A7
       bra       ask_addr_range_9
ask_addr_range_4:
; } else if (addr_array[0] > 134414336) {
       move.l    D2,A0
       move.l    (A0),D0
       cmp.l     #134414336,D0
       bls.s     ask_addr_range_6
; printf ("The start address is bigger than 0x08030000, invalid!\n");
       pea       @sram_t~1_7.L
       jsr       (A2)
       addq.w    #4,A7
       bra       ask_addr_range_9
ask_addr_range_6:
; } else { // If the data length is words or long words, check whether the start address is odd 
; if (data_length > 1 && addr_array[0] % 2 != 0) {
       move.l    12(A6),D0
       cmp.l     #1,D0
       ble.s     ask_addr_range_8
       move.l    D2,A0
       move.l    (A0),-(A7)
       pea       2
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq.s     ask_addr_range_8
; printf("The start address provided is odd, need an even one!\n");
       pea       @sram_t~1_8.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     ask_addr_range_9
ask_addr_range_8:
; } else {
; printf ("Start address valid.\n");
       pea       @sram_t~1_9.L
       jsr       (A2)
       addq.w    #4,A7
; start_addr_valid = 1;
       moveq     #1,D4
ask_addr_range_9:
       bra       ask_addr_range_1
ask_addr_range_3:
; } 
; }
; }
; while (!end_addr_valid) {
ask_addr_range_10:
       tst.l     D3
       bne       ask_addr_range_12
; printf("\r\nProvide the end address of the test.\n");
       pea       @sram_t~1_10.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%x", addr_array+1);
       move.l    D2,D1
       addq.l    #4,D1
       move.l    D1,-(A7)
       pea       @sram_t~1_11.L
       jsr       _scanf
       addq.w    #8,A7
; if (addr_array[1] < 134348800) {
       move.l    D2,A0
       move.l    4(A0),D0
       cmp.l     #134348800,D0
       bhs.s     ask_addr_range_13
; printf ("The end address is smaller than 0x08020000, invalid!\n");
       pea       @sram_t~1_12.L
       jsr       (A2)
       addq.w    #4,A7
       bra       ask_addr_range_18
ask_addr_range_13:
; } else if (addr_array[1] > 134414336)
       move.l    D2,A0
       move.l    4(A0),D0
       cmp.l     #134414336,D0
       bls.s     ask_addr_range_15
; {
; printf ("The end address is bigger than 0x08030000, invalid!\n");
       pea       @sram_t~1_13.L
       jsr       (A2)
       addq.w    #4,A7
       bra       ask_addr_range_18
ask_addr_range_15:
; } else { 
; if (data_length > 1 && addr_array[1] % 2 != 0) {
       move.l    12(A6),D0
       cmp.l     #1,D0
       ble.s     ask_addr_range_17
       move.l    D2,A0
       move.l    4(A0),-(A7)
       pea       2
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq.s     ask_addr_range_17
; printf("The end address provided is odd, need an even one!\n");
       pea       @sram_t~1_14.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     ask_addr_range_18
ask_addr_range_17:
; } else {
; printf ("End address valid.\n");
       pea       @sram_t~1_15.L
       jsr       (A2)
       addq.w    #4,A7
; end_addr_valid = 1;
       moveq     #1,D3
ask_addr_range_18:
       bra       ask_addr_range_10
ask_addr_range_12:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; } 
; }
; }
; }
; // Return the byte data with the correct pattern
; unsigned char byte_data (int data_pattern){
       xdef      _byte_data
_byte_data:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if (data_pattern == 1) {
       cmp.l     #1,D2
       bne.s     byte_data_1
; return 0;
       clr.b     D0
       bra.s     byte_data_8
byte_data_1:
; } else if (data_pattern == 2) {
       cmp.l     #2,D2
       bne.s     byte_data_4
; return 0x55;
       moveq     #85,D0
       bra.s     byte_data_8
byte_data_4:
; } else if (data_pattern == 3) {
       cmp.l     #3,D2
       bne.s     byte_data_6
; return 0xaa;
       move.b    #170,D0
       bra.s     byte_data_8
byte_data_6:
; } else if (data_pattern == 4) {
       cmp.l     #4,D2
       bne.s     byte_data_8
; return 0xff;
       move.b    #255,D0
       bra       byte_data_8
byte_data_8:
       move.l    (A7)+,D2
       unlk      A6
       rts
; } 
; }
; // Return the word data (16 bits) with the correct pattern
; unsigned short word_data (int data_pattern){
       xdef      _word_data
_word_data:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if (data_pattern == 1) {
       cmp.l     #1,D2
       bne.s     word_data_1
; return 0;
       clr.w     D0
       bra.s     word_data_8
word_data_1:
; } else if (data_pattern == 2) {
       cmp.l     #2,D2
       bne.s     word_data_4
; return 0x5555;
       move.w    #21845,D0
       bra.s     word_data_8
word_data_4:
; } else if (data_pattern == 3) {
       cmp.l     #3,D2
       bne.s     word_data_6
; return 0xaaaa;
       move.w    #43690,D0
       bra.s     word_data_8
word_data_6:
; } else if (data_pattern == 4) {
       cmp.l     #4,D2
       bne.s     word_data_8
; return 0xffff;
       move.w    #65535,D0
       bra       word_data_8
word_data_8:
       move.l    (A7)+,D2
       unlk      A6
       rts
; } 
; }
; // Return the long word data (32 bits) with the correct pattern
; unsigned int long_word_data (int data_pattern){
       xdef      _long_word_data
_long_word_data:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if (data_pattern == 1) {
       cmp.l     #1,D2
       bne.s     long_word_data_1
; return 0;
       clr.l     D0
       bra.s     long_word_data_8
long_word_data_1:
; } else if (data_pattern == 2) {
       cmp.l     #2,D2
       bne.s     long_word_data_4
; return 0x55555555;
       move.l    #1431655765,D0
       bra.s     long_word_data_8
long_word_data_4:
; } else if (data_pattern == 3) {
       cmp.l     #3,D2
       bne.s     long_word_data_6
; return 0xaaaaaaaa;
       move.l    #-1431655766,D0
       bra.s     long_word_data_8
long_word_data_6:
; } else if (data_pattern == 4) {
       cmp.l     #4,D2
       bne.s     long_word_data_8
; return 0xffffffff;
       moveq     #-1,D0
       bra       long_word_data_8
long_word_data_8:
       move.l    (A7)+,D2
       unlk      A6
       rts
; } 
; }
; int byte_test (unsigned char byte, unsigned int* addr_array) {
       xdef      _byte_test
_byte_test:
       link      A6,#-4
       movem.l   D2/D3/D4/D5,-(A7)
       move.b    11(A6),D5
       and.l     #255,D5
; unsigned int start_addr = addr_array[0];
       move.l    12(A6),A0
       move.l    (A0),D4
; unsigned int end_addr = addr_array[1];
       move.l    12(A6),A0
       move.l    4(A0),-4(A6)
; volatile unsigned char *test_addr = (unsigned char *) start_addr;
       move.l    D4,D2
; int i;
; for (i = 0; i < end_addr - start_addr; i ++) {
       clr.l     D3
byte_test_1:
       move.l    -4(A6),D0
       sub.l     D4,D0
       cmp.l     D0,D3
       bhs       byte_test_3
; test_addr = (unsigned char *) start_addr + i; 
       move.l    D4,D0
       add.l     D3,D0
       move.l    D0,D2
; *test_addr = byte;
       move.l    D2,A0
       move.b    D5,(A0)
; if (i % 10000 == 0){
       move.l    D3,-(A7)
       pea       10000
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     byte_test_4
; printf("Location %x, write data: %x, read data: %x\n", test_addr, byte, *test_addr);
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       pea       @sram_t~1_16.L
       jsr       _printf
       add.w     #16,A7
byte_test_4:
; }
; if (*test_addr != byte) {
       move.l    D2,A0
       cmp.b     (A0),D5
       beq.s     byte_test_6
; printf("Test failed at location %d!\n", test_addr);
       move.l    D2,-(A7)
       pea       @sram_t~1_17.L
       jsr       _printf
       addq.w    #8,A7
; return 0;
       clr.l     D0
       bra.s     byte_test_8
byte_test_6:
       addq.l    #1,D3
       bra       byte_test_1
byte_test_3:
; }
; }
; return 1;
       moveq     #1,D0
byte_test_8:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; int word_test (unsigned short word, unsigned int* addr_array) {
       xdef      _word_test
_word_test:
       link      A6,#-4
       movem.l   D2/D3/D4/D5,-(A7)
       move.w    10(A6),D5
       and.l     #65535,D5
; unsigned int start_addr = addr_array[0];
       move.l    12(A6),A0
       move.l    (A0),D4
; unsigned int end_addr = addr_array[1];
       move.l    12(A6),A0
       move.l    4(A0),-4(A6)
; volatile unsigned short *test_addr = (volatile unsigned short *) start_addr;
       move.l    D4,D2
; int i;
; for (i = 0; i < (end_addr - start_addr); i++) {
       clr.l     D3
word_test_1:
       move.l    -4(A6),D0
       sub.l     D4,D0
       cmp.l     D0,D3
       bhs       word_test_3
; test_addr = start_addr + i;
       move.l    D4,D0
       add.l     D3,D0
       move.l    D0,D2
; *test_addr = word;
       move.l    D2,A0
       move.w    D5,(A0)
; if (i % 10000 == 0){
       move.l    D3,-(A7)
       pea       10000
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     word_test_4
; printf("Location %x, write data: %x, read data: %x\n", test_addr, word, *test_addr);
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       pea       @sram_t~1_18.L
       jsr       _printf
       add.w     #16,A7
word_test_4:
; }
; if (*test_addr != word) {
       move.l    D2,A0
       cmp.w     (A0),D5
       beq.s     word_test_6
; printf("Test failed at location %x!\n", test_addr);
       move.l    D2,-(A7)
       pea       @sram_t~1_19.L
       jsr       _printf
       addq.w    #8,A7
; return 0;
       clr.l     D0
       bra.s     word_test_8
word_test_6:
       addq.l    #1,D3
       bra       word_test_1
word_test_3:
; }
; }
; return 1;
       moveq     #1,D0
word_test_8:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; int long_word_test (unsigned int long_word, unsigned int* addr_array) {
       xdef      _long_word_test
_long_word_test:
       link      A6,#-4
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    8(A6),D5
; unsigned int start_addr = addr_array[0];
       move.l    12(A6),A0
       move.l    (A0),D4
; unsigned int end_addr = addr_array[1];
       move.l    12(A6),A0
       move.l    4(A0),-4(A6)
; volatile unsigned int *test_addr = (volatile unsigned int *) start_addr;
       move.l    D4,D2
; int i;
; for (i = 0; i < (end_addr - start_addr); i++) {
       clr.l     D3
long_word_test_1:
       move.l    -4(A6),D0
       sub.l     D4,D0
       cmp.l     D0,D3
       bhs       long_word_test_3
; test_addr = start_addr + i; 
       move.l    D4,D0
       add.l     D3,D0
       move.l    D0,D2
; *test_addr = long_word;
       move.l    D2,A0
       move.l    D5,(A0)
; if (i % 10000 == 0){
       move.l    D3,-(A7)
       pea       10000
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     long_word_test_4
; printf("Location %x, write data: %x, read data: %x\n", test_addr, long_word, *test_addr);
       move.l    D2,A0
       move.l    (A0),-(A7)
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       pea       @sram_t~1_20.L
       jsr       _printf
       add.w     #16,A7
long_word_test_4:
; }
; if (*test_addr != long_word) {
       move.l    D2,A0
       cmp.l     (A0),D5
       beq.s     long_word_test_6
; printf("Test failed at location %d!\n", test_addr);
       move.l    D2,-(A7)
       pea       @sram_t~1_21.L
       jsr       _printf
       addq.w    #8,A7
; return 0;
       clr.l     D0
       bra.s     long_word_test_8
long_word_test_6:
       addq.l    #1,D3
       bra       long_word_test_1
long_word_test_3:
; }
; }
; return 1;
       moveq     #1,D0
long_word_test_8:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; void main (void) {
       xdef      _main
_main:
       link      A6,#-24
       movem.l   D2/D3/D4/D5/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       -16(A6),A3
; int data_length;
; int data_pattern;
; unsigned int addr_array[2];
; unsigned int start_addr, end_addr;
; unsigned char byte;
; unsigned short word;
; unsigned int long_word;
; int result;
; data_bus_test();
       jsr       _data_bus_test
; printf("\r\nDo you want the data to be 1. bytes, 2. words, or 3. long words? Provide the integer below.\n");
       pea       @sram_t~1_22.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%d", &data_length);
       pea       -24(A6)
       pea       @sram_t~1_23.L
       jsr       _scanf
       addq.w    #8,A7
; printf("\r\nDo you want the data to be composed of (hex) 1. 0, 2. 5, 3. A, or 4. F? Provide the integer below.\n");
       pea       @sram_t~1_24.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%d", &data_pattern);
       pea       -20(A6)
       pea       @sram_t~1_25.L
       jsr       _scanf
       addq.w    #8,A7
; ask_addr_range(addr_array, data_length);
       move.l    -24(A6),-(A7)
       move.l    A3,-(A7)
       jsr       _ask_addr_range
       addq.w    #8,A7
; start_addr = addr_array[0];
       move.l    (A3),-8(A6)
; end_addr = addr_array[1];
       move.l    4(A3),-4(A6)
; printf("Start address: %x\n", start_addr);
       move.l    -8(A6),-(A7)
       pea       @sram_t~1_26.L
       jsr       (A2)
       addq.w    #8,A7
; printf("End address: %x\n", end_addr);
       move.l    -4(A6),-(A7)
       pea       @sram_t~1_27.L
       jsr       (A2)
       addq.w    #8,A7
; if (data_length == 1) {
       move.l    -24(A6),D0
       cmp.l     #1,D0
       bne       main_1
; byte = byte_data (data_pattern);
       move.l    -20(A6),-(A7)
       jsr       _byte_data
       addq.w    #4,A7
       move.b    D0,D5
; printf ("Test data: %x\n",byte);
       and.l     #255,D5
       move.l    D5,-(A7)
       pea       @sram_t~1_28.L
       jsr       (A2)
       addq.w    #8,A7
; result = byte_test(byte, addr_array);
       move.l    A3,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       jsr       _byte_test
       addq.w    #8,A7
       move.l    D0,D2
       bra       main_5
main_1:
; } else if (data_length == 2) {
       move.l    -24(A6),D0
       cmp.l     #2,D0
       bne       main_3
; word = word_data (data_pattern);
       move.l    -20(A6),-(A7)
       jsr       _word_data
       addq.w    #4,A7
       move.w    D0,D4
; printf ("Test data: %x\n", word);
       and.l     #65535,D4
       move.l    D4,-(A7)
       pea       @sram_t~1_29.L
       jsr       (A2)
       addq.w    #8,A7
; result = word_test (word, addr_array);
       move.l    A3,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _word_test
       addq.w    #8,A7
       move.l    D0,D2
       bra       main_5
main_3:
; } else if (data_length == 3) {
       move.l    -24(A6),D0
       cmp.l     #3,D0
       bne.s     main_5
; long_word = long_word_data (data_pattern);
       move.l    -20(A6),-(A7)
       jsr       _long_word_data
       addq.w    #4,A7
       move.l    D0,D3
; printf ("Test data: %x\n", long_word);
       move.l    D3,-(A7)
       pea       @sram_t~1_30.L
       jsr       (A2)
       addq.w    #8,A7
; result = long_word_test (long_word, addr_array);
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       jsr       _long_word_test
       addq.w    #8,A7
       move.l    D0,D2
main_5:
; }
; if (result == 1) {
       cmp.l     #1,D2
       bne.s     main_7
; printf("Test passed!\n");
       pea       @sram_t~1_31.L
       jsr       (A2)
       addq.w    #4,A7
main_7:
; }
; while(1)
main_9:
       bra       main_9
; ;
; }
       section   const
@sram_t~1_1:
       dc.b      13,10,100,97,116,97,32,98,117,115,32,116,101
       dc.b      115,116,32,100,97,116,97,58,32,37,100,0
@sram_t~1_2:
       dc.b      13,10,100,97,116,97,32,98,117,115,32,116,101
       dc.b      115,116,32,102,97,105,108,101,100,32,119,105
       dc.b      116,104,32,100,97,116,97,58,32,37,100,0
@sram_t~1_3:
       dc.b      13,10,100,97,116,97,32,98,117,115,32,116,101
       dc.b      115,116,32,112,97,115,115,101,100,33,0
@sram_t~1_4:
       dc.b      13,10,80,114,111,118,105,100,101,32,116,104
       dc.b      101,32,115,116,97,114,116,32,97,100,100,114
       dc.b      101,115,115,32,111,102,32,116,104,101,32,116
       dc.b      101,115,116,46,10,0
@sram_t~1_5:
       dc.b      37,120,0
@sram_t~1_6:
       dc.b      84,104,101,32,115,116,97,114,116,32,97,100,100
       dc.b      114,101,115,115,32,105,115,32,115,109,97,108
       dc.b      108,101,114,32,116,104,97,110,32,48,120,48,56
       dc.b      48,50,48,48,48,48,44,32,105,110,118,97,108,105
       dc.b      100,33,10,0
@sram_t~1_7:
       dc.b      84,104,101,32,115,116,97,114,116,32,97,100,100
       dc.b      114,101,115,115,32,105,115,32,98,105,103,103
       dc.b      101,114,32,116,104,97,110,32,48,120,48,56,48
       dc.b      51,48,48,48,48,44,32,105,110,118,97,108,105
       dc.b      100,33,10,0
@sram_t~1_8:
       dc.b      84,104,101,32,115,116,97,114,116,32,97,100,100
       dc.b      114,101,115,115,32,112,114,111,118,105,100,101
       dc.b      100,32,105,115,32,111,100,100,44,32,110,101
       dc.b      101,100,32,97,110,32,101,118,101,110,32,111
       dc.b      110,101,33,10,0
@sram_t~1_9:
       dc.b      83,116,97,114,116,32,97,100,100,114,101,115
       dc.b      115,32,118,97,108,105,100,46,10,0
@sram_t~1_10:
       dc.b      13,10,80,114,111,118,105,100,101,32,116,104
       dc.b      101,32,101,110,100,32,97,100,100,114,101,115
       dc.b      115,32,111,102,32,116,104,101,32,116,101,115
       dc.b      116,46,10,0
@sram_t~1_11:
       dc.b      37,120,0
@sram_t~1_12:
       dc.b      84,104,101,32,101,110,100,32,97,100,100,114
       dc.b      101,115,115,32,105,115,32,115,109,97,108,108
       dc.b      101,114,32,116,104,97,110,32,48,120,48,56,48
       dc.b      50,48,48,48,48,44,32,105,110,118,97,108,105
       dc.b      100,33,10,0
@sram_t~1_13:
       dc.b      84,104,101,32,101,110,100,32,97,100,100,114
       dc.b      101,115,115,32,105,115,32,98,105,103,103,101
       dc.b      114,32,116,104,97,110,32,48,120,48,56,48,51
       dc.b      48,48,48,48,44,32,105,110,118,97,108,105,100
       dc.b      33,10,0
@sram_t~1_14:
       dc.b      84,104,101,32,101,110,100,32,97,100,100,114
       dc.b      101,115,115,32,112,114,111,118,105,100,101,100
       dc.b      32,105,115,32,111,100,100,44,32,110,101,101
       dc.b      100,32,97,110,32,101,118,101,110,32,111,110
       dc.b      101,33,10,0
@sram_t~1_15:
       dc.b      69,110,100,32,97,100,100,114,101,115,115,32
       dc.b      118,97,108,105,100,46,10,0
@sram_t~1_16:
       dc.b      76,111,99,97,116,105,111,110,32,37,120,44,32
       dc.b      119,114,105,116,101,32,100,97,116,97,58,32,37
       dc.b      120,44,32,114,101,97,100,32,100,97,116,97,58
       dc.b      32,37,120,10,0
@sram_t~1_17:
       dc.b      84,101,115,116,32,102,97,105,108,101,100,32
       dc.b      97,116,32,108,111,99,97,116,105,111,110,32,37
       dc.b      100,33,10,0
@sram_t~1_18:
       dc.b      76,111,99,97,116,105,111,110,32,37,120,44,32
       dc.b      119,114,105,116,101,32,100,97,116,97,58,32,37
       dc.b      120,44,32,114,101,97,100,32,100,97,116,97,58
       dc.b      32,37,120,10,0
@sram_t~1_19:
       dc.b      84,101,115,116,32,102,97,105,108,101,100,32
       dc.b      97,116,32,108,111,99,97,116,105,111,110,32,37
       dc.b      120,33,10,0
@sram_t~1_20:
       dc.b      76,111,99,97,116,105,111,110,32,37,120,44,32
       dc.b      119,114,105,116,101,32,100,97,116,97,58,32,37
       dc.b      120,44,32,114,101,97,100,32,100,97,116,97,58
       dc.b      32,37,120,10,0
@sram_t~1_21:
       dc.b      84,101,115,116,32,102,97,105,108,101,100,32
       dc.b      97,116,32,108,111,99,97,116,105,111,110,32,37
       dc.b      100,33,10,0
@sram_t~1_22:
       dc.b      13,10,68,111,32,121,111,117,32,119,97,110,116
       dc.b      32,116,104,101,32,100,97,116,97,32,116,111,32
       dc.b      98,101,32,49,46,32,98,121,116,101,115,44,32
       dc.b      50,46,32,119,111,114,100,115,44,32,111,114,32
       dc.b      51,46,32,108,111,110,103,32,119,111,114,100
       dc.b      115,63,32,80,114,111,118,105,100,101,32,116
       dc.b      104,101,32,105,110,116,101,103,101,114,32,98
       dc.b      101,108,111,119,46,10,0
@sram_t~1_23:
       dc.b      37,100,0
@sram_t~1_24:
       dc.b      13,10,68,111,32,121,111,117,32,119,97,110,116
       dc.b      32,116,104,101,32,100,97,116,97,32,116,111,32
       dc.b      98,101,32,99,111,109,112,111,115,101,100,32
       dc.b      111,102,32,40,104,101,120,41,32,49,46,32,48
       dc.b      44,32,50,46,32,53,44,32,51,46,32,65,44,32,111
       dc.b      114,32,52,46,32,70,63,32,80,114,111,118,105
       dc.b      100,101,32,116,104,101,32,105,110,116,101,103
       dc.b      101,114,32,98,101,108,111,119,46,10,0
@sram_t~1_25:
       dc.b      37,100,0
@sram_t~1_26:
       dc.b      83,116,97,114,116,32,97,100,100,114,101,115
       dc.b      115,58,32,37,120,10,0
@sram_t~1_27:
       dc.b      69,110,100,32,97,100,100,114,101,115,115,58
       dc.b      32,37,120,10,0
@sram_t~1_28:
       dc.b      84,101,115,116,32,100,97,116,97,58,32,37,120
       dc.b      10,0
@sram_t~1_29:
       dc.b      84,101,115,116,32,100,97,116,97,58,32,37,120
       dc.b      10,0
@sram_t~1_30:
       dc.b      84,101,115,116,32,100,97,116,97,58,32,37,120
       dc.b      10,0
@sram_t~1_31:
       dc.b      84,101,115,116,32,112,97,115,115,101,100,33
       dc.b      10,0
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
       xref      LDIV
       xref      _scanf
       xref      ULDIV
       xref      _printf
