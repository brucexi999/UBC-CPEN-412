; C:\M68KV6.0-800BY480\PROGRAMS\DEBUGMONITORCODE\M68KDEBUG (NO DISASSEMBLER).C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include "DebugMonitor.h"
; #include <stdio.h>
; #include <stdlib.h>
; #include <limits.h>
; #include "snake.h"
; // use 08030000 for a system running from sram or 0B000000 for system running from dram
; //#define StartOfExceptionVectorTable 0x08030000
; #define StartOfExceptionVectorTable 0x0B000000
; // use 0C000000 for dram or hex 08040000 for sram
; //#define TopOfStack 0x08040000
; #define TopOfStack 0x0C000000
; // the start address of the sdram
; #define start_of_dram 0x08000000
; #define vga_ram_start         (*(volatile unsigned char *)(0x00600000))
; #define vga_x_cursor_reg          (*(volatile unsigned char *)(0x00601000))
; #define vga_y_cursor_reg            (*(volatile unsigned char *)(0x00601002))
; #define vga_ctrl_reg             (*(volatile unsigned char *)(0x00601004))
; #define StartOfExceptionVectorTable 0x0B000000
; #define Timer2Data      *(volatile unsigned char *)(0x00400034)
; #define Timer2Control   *(volatile unsigned char *)(0x00400036)
; #define Timer2Status    *(volatile unsigned char *)(0x00400036)
; /* DO NOT INITIALISE GLOBAL VARIABLES - DO IT in MAIN() */
; unsigned int i, x, y, z, PortA_Count;
; int     Trace, GoFlag, Echo;                       // used in tracing/single stepping
; // 68000 register dump and preintialise value (these can be changed by the user program when it is running, e.g. stack pointer, registers etc
; unsigned int d0,d1,d2,d3,d4,d5,d6,d7 ;
; unsigned int a0,a1,a2,a3,a4,a5,a6 ;
; unsigned int PC, SSP, USP ;
; unsigned short int SR;
; // Breakpoint variables
; unsigned int BreakPointAddress[8];                      //array of 8 breakpoint addresses
; unsigned short int BreakPointInstruction[8] ;           // to hold the instruction opcode at the breakpoint
; unsigned int BreakPointSetOrCleared[8] ;
; unsigned int InstructionSize ;
; // watchpoint variables
; unsigned int WatchPointAddress[8];                      //array of 8 breakpoint addresses
; unsigned int WatchPointSetOrCleared[8] ;
; char WatchPointString[8][100] ;
; char    TempString[100] ; 
; int score;
; int timer;
; unsigned int clock_counter;
; unsigned int vga_color;
; struct
; {
; coord_t xy[SNAKE_LENGTH_LIMIT];
; int length;
; dir_t direction;
; int speed;
; int speed_increase;
; coord_t food;
; } Snake;
; const coord_t screensize = {NUM_VGA_COLUMNS,NUM_VGA_ROWS};
; int waiting_for_direction_to_be_implemented;
; /************************************************************************************
; *Subroutine to give the 68000 something useless to do to waste 1 mSec
; ************************************************************************************/
; void Wait1ms(void)
; {
       section   code
       xdef      _Wait1ms
_Wait1ms:
       move.l    D2,-(A7)
; long int  i ;
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
; *Subroutine to give the 68000 something useless to do to waste 3 mSec
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
; *Subroutine to initialise the display by writing some commands to the LCD internal registers
; *********************************************************************************************/
; void Init_LCD(void)
; {
       xdef      _Init_LCD
_Init_LCD:
; LCDcommand = (char)(0x0c) ;
       move.b    #12,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDcommand = (char)(0x38) ;
       move.b    #56,4194336
; Wait3ms() ;
       jsr       _Wait3ms
       rts
; }
; /******************************************************************************
; *subroutine to output a single character held in d1 to the LCD display
; *it is assumed the character is an ASCII code and it will be displayed at the
; *current cursor position
; *******************************************************************************/
; void Outchar(int c)
; {
       xdef      _Outchar
_Outchar:
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
; void OutMess(char *theMessage)
; {
       xdef      _OutMess
_OutMess:
       link      A6,#-4
; char c ;
; while((c = *theMessage++) != (char)(0))
OutMess_1:
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),-1(A6)
       move.b    (A0),D0
       beq.s     OutMess_3
; Outchar(c) ;
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Outchar
       addq.w    #4,A7
       bra       OutMess_1
OutMess_3:
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to clear the line by issuing 24 space characters
; *******************************************************************************/
; void Clearln(void)
; {
       xdef      _Clearln
_Clearln:
       move.l    D2,-(A7)
; unsigned char i ;
; for(i = 0; i < 24; i ++)
       clr.b     D2
Clearln_1:
       cmp.b     #24,D2
       bhs.s     Clearln_3
; Outchar(' ') ;  /* write a space char to the LCD display */
       pea       32
       jsr       _Outchar
       addq.w    #4,A7
       addq.b    #1,D2
       bra       Clearln_1
Clearln_3:
       move.l    (A7)+,D2
       rts
; }
; /******************************************************************************
; *subroutine to move the cursor to the start of line 1 and clear that line
; *******************************************************************************/
; void Oline0(char *theMessage)
; {
       xdef      _Oline0
_Oline0:
       link      A6,#0
; LCDcommand = (char)(0x80) ;
       move.b    #128,4194336
; Wait3ms();
       jsr       _Wait3ms
; Clearln() ;
       jsr       _Clearln
; LCDcommand = (char)(0x80) ;
       move.b    #128,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; OutMess(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _OutMess
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to move the cursor to the start of line 2 and clear that line
; *******************************************************************************/
; void Oline1(char *theMessage)
; {
       xdef      _Oline1
_Oline1:
       link      A6,#0
; LCDcommand = (char)(0xC0) ;
       move.b    #192,4194336
; Wait3ms();
       jsr       _Wait3ms
; Clearln() ;
       jsr       _Clearln
; LCDcommand = (char)(0xC0) ;
       move.b    #192,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; OutMess(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _OutMess
       addq.w    #4,A7
       unlk      A6
       rts
; }
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       xdef      _InstallExceptionHandler
_InstallExceptionHandler:
       link      A6,#-4
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
       move.l    #184549376,-4(A6)
; RamVectorAddress[level] = (long int *)(function_ptr);
       move.l    -4(A6),A0
       move.l    12(A6),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; void TestLEDS(void)
; {
       xdef      _TestLEDS
_TestLEDS:
       movem.l   D2/D3,-(A7)
; int delay ;
; unsigned char count = 0 ;
       clr.b     D2
; while(1)    {
TestLEDS_1:
; PortA = PortB = PortC = PortD = HEX_A = HEX_B = HEX_C = HEX_D = ((count << 4) + (count & 0x0f)) ;
       move.b    D2,D0
       lsl.b     #4,D0
       move.b    D2,D1
       and.b     #15,D1
       add.b     D1,D0
       move.b    D0,4194326
       move.b    D0,4194324
       move.b    D0,4194322
       move.b    D0,4194320
       move.b    D0,4194310
       move.b    D0,4194308
       move.b    D0,4194306
       move.b    D0,4194304
; for(delay = 0; delay < 200000; delay ++)
       clr.l     D3
TestLEDS_4:
       cmp.l     #200000,D3
       bge.s     TestLEDS_6
       addq.l    #1,D3
       bra       TestLEDS_4
TestLEDS_6:
; ;
; count ++;
       addq.b    #1,D2
       bra       TestLEDS_1
; }
; }
; void SwitchTest(void)
; {
       xdef      _SwitchTest
_SwitchTest:
       movem.l   D2/D3/A2,-(A7)
       lea       _printf.L,A2
; int i, switches = 0 ;
       clr.l     D3
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; while(1)    {
SwitchTest_1:
; switches = (PortB << 8) | (PortA) ;
       move.b    4194306,D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.b    4194304,D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D3
; printf("\rSwitches SW[7-0] = ") ;
       pea       @m68kde~1_2.L
       jsr       (A2)
       addq.w    #4,A7
; for( i = (int)(0x00000080); i > 0; i = i >> 1)  {
       move.l    #128,D2
SwitchTest_4:
       cmp.l     #0,D2
       ble.s     SwitchTest_6
; if((switches & i) == 0)
       move.l    D3,D0
       and.l     D2,D0
       bne.s     SwitchTest_7
; printf("0") ;
       pea       @m68kde~1_3.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     SwitchTest_8
SwitchTest_7:
; else
; printf("1") ;
       pea       @m68kde~1_4.L
       jsr       (A2)
       addq.w    #4,A7
SwitchTest_8:
       asr.l     #1,D2
       bra       SwitchTest_4
SwitchTest_6:
       bra       SwitchTest_1
; }
; }
; }
; /*********************************************************************************************
; *Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = (char)(0x15) ; //  %00010101    divide by 16 clock, set rts low, 8 bits no parity, 1 stop bit transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = (char)(0x1) ;      // program baud rate generator 000 = 230k, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
       rts
; }
; int kbhit(void)
; {
       xdef      _kbhit
_kbhit:
; if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // wait for Rx bit in status register to be '1'
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne.s     kbhit_1
; return 1 ;
       moveq     #1,D0
       bra.s     kbhit_3
kbhit_1:
; else
; return 0 ;
       clr.l     D0
kbhit_3:
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
; while(((char)(RS232_Status) & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; (char)(RS232_TxData) = ((char)(c) & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.b     #127,D0
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
; **  NOTE you do not call this function directly, instead you call the normal _getch() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call _getch() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       move.l    D2,-(A7)
; int c ;
; while(((char)(RS232_Status) & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; c = (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       move.l    D0,D2
; // shall we echo the character? Echo is set to TRUE at reset, but for speed we don't want to echo when downloading code with the 'L' debugger command
; if(Echo)
       tst.l     _Echo.L
       beq.s     _getch_4
; _putch(c);
       move.l    D2,-(A7)
       jsr       __putch
       addq.w    #4,A7
_getch_4:
; return c ;
       move.l    D2,D0
       move.l    (A7)+,D2
       rts
; }
; // flush the input stream for any unread characters
; void FlushKeyboard(void)
; {
       xdef      _FlushKeyboard
_FlushKeyboard:
       link      A6,#-4
; char c ;
; while(1)    {
FlushKeyboard_1:
; if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // if Rx bit in status register is '1'
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne.s     FlushKeyboard_4
; c = ((char)(RS232_RxData) & (char)(0x7f)) ;
       move.b    4194370,D0
       and.b     #127,D0
       move.b    D0,-1(A6)
       bra.s     FlushKeyboard_5
FlushKeyboard_4:
; else
; return ;
       bra.s     FlushKeyboard_6
FlushKeyboard_5:
       bra       FlushKeyboard_1
FlushKeyboard_6:
       unlk      A6
       rts
; }
; }
; // converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
; // char assumed to be a valid hex char 0-9, a-f, A-F
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
; void DumpMemory(void)   // simple dump memory fn
; {
       xdef      _DumpMemory
_DumpMemory:
       movem.l   D2/D3/D4/D5/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _putch.L,A3
; int i, j ;
; unsigned char *RamPtr,c ; // pointer to where the program is download (assumed)
; printf("\r\nDump Memory Block: <ESC> to Abort, <SPACE> to Continue") ;
       pea       @m68kde~1_5.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter Start Address: ") ;
       pea       @m68kde~1_6.L
       jsr       (A2)
       addq.w    #4,A7
; RamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; while(1)    {
DumpMemory_1:
; for(i = 0; i < 16; i ++)    {
       clr.l     D5
DumpMemory_4:
       cmp.l     #16,D5
       bge       DumpMemory_6
; printf("\r\n%08x ", RamPtr) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_7.L
       jsr       (A2)
       addq.w    #8,A7
; for(j=0; j < 16; j ++)  {
       clr.l     D2
DumpMemory_7:
       cmp.l     #16,D2
       bge.s     DumpMemory_9
; printf("%02X",RamPtr[j]) ;
       move.l    D3,A0
       move.b    0(A0,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_8.L
       jsr       (A2)
       addq.w    #8,A7
; putchar(' ') ;
       pea       32
       jsr       (A3)
       addq.w    #4,A7
       addq.l    #1,D2
       bra       DumpMemory_7
DumpMemory_9:
; }
; // now display the data as ASCII at the end
; printf("  ") ;
       pea       @m68kde~1_9.L
       jsr       (A2)
       addq.w    #4,A7
; for(j = 0; j < 16; j++) {
       clr.l     D2
DumpMemory_10:
       cmp.l     #16,D2
       bge       DumpMemory_12
; c = ((char)(RamPtr[j]) & 0x7f) ;
       move.l    D3,A0
       move.b    0(A0,D2.L),D0
       and.b     #127,D0
       move.b    D0,D4
; if((c > (char)(0x7f)) || (c < ' '))
       cmp.b     #127,D4
       bhi.s     DumpMemory_15
       cmp.b     #32,D4
       bhs.s     DumpMemory_13
DumpMemory_15:
; putchar('.') ;
       pea       46
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DumpMemory_14
DumpMemory_13:
; else
; putchar(RamPtr[j]) ;
       move.l    D3,A0
       move.b    0(A0,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
DumpMemory_14:
       addq.l    #1,D2
       bra       DumpMemory_10
DumpMemory_12:
; }
; RamPtr = RamPtr + 16 ;
       add.l     #16,D3
       addq.l    #1,D5
       bra       DumpMemory_4
DumpMemory_6:
; }
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; c = _getch() ;
       jsr       __getch
       move.b    D0,D4
; if(c == 0x1b)          // break on ESC
       cmp.b     #27,D4
       bne.s     DumpMemory_16
; break ;
       bra.s     DumpMemory_3
DumpMemory_16:
       bra       DumpMemory_1
DumpMemory_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3
       rts
; }
; }
; void FillMemory()
; {
       xdef      _FillMemory
_FillMemory:
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
; char *StartRamPtr, *EndRamPtr ;
; unsigned char FillData ;
; printf("\r\nFill Memory Block") ;
       pea       @m68kde~1_10.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter Start Address: ") ;
       pea       @m68kde~1_6.L
       jsr       (A2)
       addq.w    #4,A7
; StartRamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; printf("\r\nEnter End Address: ") ;
       pea       @m68kde~1_11.L
       jsr       (A2)
       addq.w    #4,A7
; EndRamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D4
; printf("\r\nEnter Fill Data: ") ;
       pea       @m68kde~1_12.L
       jsr       (A2)
       addq.w    #4,A7
; FillData = Get2HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.b    D0,D3
; printf("\r\nFilling Addresses [$%08X - $%08X] with $%02X", StartRamPtr, EndRamPtr, FillData) ;
       and.l     #255,D3
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_13.L
       jsr       (A2)
       add.w     #16,A7
; while(StartRamPtr < EndRamPtr)
FillMemory_1:
       cmp.l     D4,D2
       bhs.s     FillMemory_3
; *StartRamPtr++ = FillData ;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D3,(A0)
       bra       FillMemory_1
FillMemory_3:
       movem.l   (A7)+,D2/D3/D4/A2
       rts
; }
; void Load_SRecordFile()
; {
       xdef      _Load_SRecordFile
_Load_SRecordFile:
       link      A6,#-36
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -6(A6),A2
       lea       _Get2HexDigits.L,A3
       lea       _printf.L,A4
; int i, Address, AddressSize, DataByte, NumDataBytesToRead, LoadFailed, FailedAddress, AddressFail, SRecordCount = 0, ByteTotal = 0 ;
       clr.l     -18(A6)
       move.w    #0,A5
; int result, ByteCount ;
; char c, CheckSum, ReadCheckSum, HeaderType ;
; char *RamPtr ;                          // pointer to Memory where downloaded program will be stored
; LoadFailed = 0 ;                        //assume LOAD operation will pass
       moveq     #0,D7
; AddressFail = 0 ;
       clr.l     -22(A6)
; Echo = 0 ;                              // don't echo S records during download
       clr.l     _Echo.L
; printf("\r\nUse HyperTerminal to Send Text File (.hex)\r\n") ;
       pea       @m68kde~1_14.L
       jsr       (A4)
       addq.w    #4,A7
; while(1)    {
Load_SRecordFile_1:
; CheckSum = 0 ;
       clr.b     (A2)
; do {
Load_SRecordFile_4:
; c = toupper(_getch()) ;
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D6
; if(c == 0x1b )      // if break
       cmp.b     #27,D6
       bne.s     Load_SRecordFile_6
; return;
       bra       Load_SRecordFile_8
Load_SRecordFile_6:
       cmp.b     #83,D6
       bne       Load_SRecordFile_4
; }while(c != (char)('S'));   // wait for S start of header
; HeaderType = _getch() ;
       jsr       __getch
       move.b    D0,D3
; if(HeaderType == (char)('0') || HeaderType == (char)('5'))       // ignore s0, s5 records
       cmp.b     #48,D3
       beq.s     Load_SRecordFile_11
       cmp.b     #53,D3
       bne.s     Load_SRecordFile_9
Load_SRecordFile_11:
; continue ;
       bra       Load_SRecordFile_23
Load_SRecordFile_9:
; if(HeaderType >= (char)('7'))
       cmp.b     #55,D3
       blt.s     Load_SRecordFile_12
; break ;                 // end load on s7,s8,s9 records
       bra       Load_SRecordFile_3
Load_SRecordFile_12:
; // get the bytecount
; ByteCount = Get2HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,-10(A6)
; // get the address, 4 digits for s1, 6 digits for s2, and 8 digits for s3 record
; if(HeaderType == (char)('1')) {
       cmp.b     #49,D3
       bne.s     Load_SRecordFile_14
; AddressSize = 2 ;       // 2 byte address
       moveq     #2,D5
; Address = Get4HexDigits(&CheckSum);
       move.l    A2,-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D4
       bra.s     Load_SRecordFile_17
Load_SRecordFile_14:
; }
; else if (HeaderType == (char)('2')) {
       cmp.b     #50,D3
       bne.s     Load_SRecordFile_16
; AddressSize = 3 ;       // 3 byte address
       moveq     #3,D5
; Address = Get6HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       _Get6HexDigits
       addq.w    #4,A7
       move.l    D0,D4
       bra.s     Load_SRecordFile_17
Load_SRecordFile_16:
; }
; else    {
; AddressSize = 4 ;       // 4 byte address
       moveq     #4,D5
; Address = Get8HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D4
Load_SRecordFile_17:
; }
; RamPtr = (char *)(Address) ;                            // point to download area
       move.l    D4,-4(A6)
; NumDataBytesToRead = ByteCount - AddressSize - 1 ;
       move.l    -10(A6),D0
       sub.l     D5,D0
       subq.l    #1,D0
       move.l    D0,-30(A6)
; for(i = 0; i < NumDataBytesToRead; i ++) {     // read in remaining data bytes (ignore address and checksum at the end
       clr.l     D2
Load_SRecordFile_18:
       cmp.l     -30(A6),D2
       bge.s     Load_SRecordFile_20
; DataByte = Get2HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,-34(A6)
; *RamPtr++ = DataByte ;                      // store downloaded byte in Ram at specified address
       move.l    -34(A6),D0
       move.l    -4(A6),A0
       addq.l    #1,-4(A6)
       move.b    D0,(A0)
; ByteTotal++;
       addq.w    #1,A5
       addq.l    #1,D2
       bra       Load_SRecordFile_18
Load_SRecordFile_20:
; }
; // checksum is the 1's complement of the sum of all data pairs following the bytecount, i.e. it includes the address and the data itself
; ReadCheckSum = Get2HexDigits(0) ;
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.b    D0,-5(A6)
; if((~CheckSum&0Xff) != (ReadCheckSum&0Xff))   {
       move.b    (A2),D0
       not.b     D0
       ext.w     D0
       and.w     #255,D0
       move.b    -5(A6),D1
       ext.w     D1
       and.w     #255,D1
       cmp.w     D1,D0
       beq.s     Load_SRecordFile_21
; LoadFailed = 1 ;
       moveq     #1,D7
; FailedAddress = Address ;
       move.l    D4,-26(A6)
; break;
       bra.s     Load_SRecordFile_3
Load_SRecordFile_21:
; }
; SRecordCount++ ;
       addq.l    #1,-18(A6)
; // display feedback on progress
; if(SRecordCount % 25 == 0)
       move.l    -18(A6),-(A7)
       pea       25
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     Load_SRecordFile_23
; putchar('.') ;
       pea       46
       jsr       _putch
       addq.w    #4,A7
Load_SRecordFile_23:
       bra       Load_SRecordFile_1
Load_SRecordFile_3:
; }
; if(LoadFailed == 1) {
       cmp.l     #1,D7
       bne.s     Load_SRecordFile_25
; printf("\r\nLoad Failed at Address = [$%08X]\r\n", FailedAddress) ;
       move.l    -26(A6),-(A7)
       pea       @m68kde~1_15.L
       jsr       (A4)
       addq.w    #8,A7
       bra.s     Load_SRecordFile_26
Load_SRecordFile_25:
; }
; else
; printf("\r\nSuccess: Downloaded %d bytes\r\n", ByteTotal) ;
       move.l    A5,-(A7)
       pea       @m68kde~1_16.L
       jsr       (A4)
       addq.w    #8,A7
Load_SRecordFile_26:
; // pause at the end to wait for download to finish transmitting at the end of S8 etc
; for(i = 0; i < 400000; i ++)
       clr.l     D2
Load_SRecordFile_27:
       cmp.l     #400000,D2
       bge.s     Load_SRecordFile_29
       addq.l    #1,D2
       bra       Load_SRecordFile_27
Load_SRecordFile_29:
; ;
; FlushKeyboard() ;
       jsr       _FlushKeyboard
; Echo = 1;
       move.l    #1,_Echo.L
Load_SRecordFile_8:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; void MemoryChange(void)
; {
       xdef      _MemoryChange
_MemoryChange:
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
; unsigned char *RamPtr,c ; // pointer to memory
; int Data ;
; printf("\r\nExamine and Change Memory") ;
       pea       @m68kde~1_17.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n<ESC> to Stop, <SPACE> to Advance, '-' to Go Back, <DATA> to change") ;
       pea       @m68kde~1_18.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter Address: ") ;
       pea       @m68kde~1_19.L
       jsr       (A2)
       addq.w    #4,A7
; RamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; while(1)    {
MemoryChange_1:
; printf("\r\n[%08x] : %02x  ", RamPtr, *RamPtr) ;
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       pea       @m68kde~1_20.L
       jsr       (A2)
       add.w     #12,A7
; c = tolower(_getch()) ;
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       move.b    D0,D2
; if(c == (char)(0x1b))
       cmp.b     #27,D2
       bne.s     MemoryChange_4
; return ;                                // abort on escape
       bra       MemoryChange_6
MemoryChange_4:
; else if((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {  // are we trying to change data at this location by entering a hex char
       cmp.b     #48,D2
       blo.s     MemoryChange_10
       cmp.b     #57,D2
       bls.s     MemoryChange_9
MemoryChange_10:
       cmp.b     #97,D2
       blo       MemoryChange_7
       cmp.b     #102,D2
       bhi       MemoryChange_7
MemoryChange_9:
; Data = (xtod(c) << 4) | (xtod(_getch()));
       and.l     #255,D2
       move.l    D2,-(A7)
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
       move.l    D0,D4
; *RamPtr = (char)(Data) ;
       move.l    D3,A0
       move.b    D4,(A0)
; if(*RamPtr != Data) {
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       cmp.l     D4,D0
       beq.s     MemoryChange_11
; printf("\r\nWarning Change Failed: Wrote [%02x], Read [%02x]", Data, *RamPtr) ;
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D4,-(A7)
       pea       @m68kde~1_21.L
       jsr       (A2)
       add.w     #12,A7
MemoryChange_11:
       bra.s     MemoryChange_13
MemoryChange_7:
; }
; }
; else if(c == (char)('-'))
       cmp.b     #45,D2
       bne.s     MemoryChange_13
; RamPtr -= 2 ; ;
       subq.l    #2,D3
MemoryChange_13:
; RamPtr ++ ;
       addq.l    #1,D3
       bra       MemoryChange_1
MemoryChange_6:
       movem.l   (A7)+,D2/D3/D4/A2
       rts
; }
; }
; //////////////////////////////////////////////////////////////////////////////////////////////////
; // IMPORTANT
; // TG68 does not support the Native Trace mode of the original 68000 so tracing
; // has to be done with an interrupt (IRQ Level 6)
; //
; // To allow the 68000 to execute one more instruction after each pseudo trace (IRQ6)
; // the IRQ is removed in hardware once the TG68 reads the IRQ autovector (i.e. acknowledges the IRQ)
; //
; // on return from the IRQ service handler, the first access to the user memory program space
; // generates a fresh IRQ (in hardware) to generate a new trace, this allows the tg68 to
; // execute one more new instruction (without it the TG68 would trace on the same instruction
; // each time and not after the next one). It also means it doesn't simgle step outside the user
; // program area
; //
; // The bottom line is the Trace handler, which includes the Dump registers below
; // cannot access the user memory to display for example the Instruction Opcode or to disassemble etc
; // as this would lead to a new IRQ being reset and the TG68 would trace on same instruction
; // NOT SURE THIS IS TRUE NOW THAT TRACE HANDLER HAS BEEN MODIVIED TO NOT AUTOMATICALLY GENERATE A TRACE EXCEPTION
; // INSTEAD IT IS DONE IN THE 'N' COMMAND FOR NEXT
; /////////////////////////////////////////////////////////////////////////////////////////////////////
; void DumpRegisters()
; {
       xdef      _DumpRegisters
_DumpRegisters:
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _putch.L,A2
       lea       _printf.L,A3
       lea       _SR.L,A4
       lea       _WatchPointString.L,A5
; short i, x, j, k ;
; unsigned char c, *BytePointer;
; // buld up strings for displaying watchpoints
; for(x = 0; x < (short)(8); x++)
       clr.w     D2
DumpRegisters_1:
       cmp.w     #8,D2
       bge       DumpRegisters_3
; {
; if(WatchPointSetOrCleared[x] == 1)
       ext.l     D2
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne       DumpRegisters_4
; {
; sprintf(WatchPointString[x], "$%08X  ", WatchPointAddress[x]) ;
       ext.l     D2
       move.l    D2,D1
       lsl.l     #2,D1
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D1.L),-(A7)
       pea       @m68kde~1_22.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _sprintf
       add.w     #12,A7
; BytePointer = (char *)(WatchPointAddress[x]) ;
       ext.l     D2
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D0.L),D5
; for(j = 0; j < (short)(16); j+=2)
       clr.w     D3
DumpRegisters_6:
       cmp.w     #16,D3
       bge       DumpRegisters_8
; {
; for(k = 0; k < (short)(2); k++)
       clr.w     D6
DumpRegisters_9:
       cmp.w     #2,D6
       bge       DumpRegisters_11
; {
; sprintf(TempString, "%02X", BytePointer[j+k]) ;
       move.l    D5,A0
       ext.l     D3
       move.l    D3,D1
       ext.l     D6
       add.l     D6,D1
       move.b    0(A0,D1.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_8.L
       pea       _TempString.L
       jsr       _sprintf
       add.w     #12,A7
; strcat(WatchPointString[x], TempString) ;
       pea       _TempString.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
       addq.w    #1,D6
       bra       DumpRegisters_9
DumpRegisters_11:
; }
; strcat(WatchPointString[x]," ") ;
       pea       @m68kde~1_23.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
       addq.w    #2,D3
       bra       DumpRegisters_6
DumpRegisters_8:
; }
; strcat(WatchPointString[x], "  ") ;
       pea       @m68kde~1_9.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
; BytePointer = (char *)(WatchPointAddress[x]) ;
       ext.l     D2
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D0.L),D5
; for(j = 0; j < (short)(16); j++)
       clr.w     D3
DumpRegisters_12:
       cmp.w     #16,D3
       bge       DumpRegisters_14
; {
; c = ((char)(BytePointer[j]) & 0x7f) ;
       move.l    D5,A0
       ext.l     D3
       move.b    0(A0,D3.L),D0
       and.b     #127,D0
       move.b    D0,D7
; if((c > (char)(0x7f)) || (c < (char)(' ')))
       cmp.b     #127,D7
       bhi.s     DumpRegisters_17
       cmp.b     #32,D7
       bhs.s     DumpRegisters_15
DumpRegisters_17:
; sprintf(TempString, ".") ;
       pea       @m68kde~1_24.L
       pea       _TempString.L
       jsr       _sprintf
       addq.w    #8,A7
       bra.s     DumpRegisters_16
DumpRegisters_15:
; else
; sprintf(TempString, "%c", BytePointer[j]) ;
       move.l    D5,A0
       ext.l     D3
       move.b    0(A0,D3.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_25.L
       pea       _TempString.L
       jsr       _sprintf
       add.w     #12,A7
DumpRegisters_16:
; strcat(WatchPointString[x], TempString) ;
       pea       _TempString.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
       addq.w    #1,D3
       bra       DumpRegisters_12
DumpRegisters_14:
       bra.s     DumpRegisters_5
DumpRegisters_4:
; }
; }
; else
; strcpy(WatchPointString[x], "") ;
       pea       @m68kde~1_26.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
DumpRegisters_5:
       addq.w    #1,D2
       bra       DumpRegisters_1
DumpRegisters_3:
; }
; printf("\r\n\r\n D0 = $%08X  A0 = $%08X",d0,a0) ;
       move.l    _a0.L,-(A7)
       move.l    _d0.L,-(A7)
       pea       @m68kde~1_27.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D1 = $%08X  A1 = $%08X",d1,a1) ;
       move.l    _a1.L,-(A7)
       move.l    _d1.L,-(A7)
       pea       @m68kde~1_28.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D2 = $%08X  A2 = $%08X",d2,a2) ;
       move.l    _a2.L,-(A7)
       move.l    _d2.L,-(A7)
       pea       @m68kde~1_29.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D3 = $%08X  A3 = $%08X",d3,a3) ;
       move.l    _a3.L,-(A7)
       move.l    _d3.L,-(A7)
       pea       @m68kde~1_30.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D4 = $%08X  A4 = $%08X",d4,a4) ;
       move.l    _a4.L,-(A7)
       move.l    _d4.L,-(A7)
       pea       @m68kde~1_31.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D5 = $%08X  A5 = $%08X",d5,a5) ;
       move.l    _a5.L,-(A7)
       move.l    _d5.L,-(A7)
       pea       @m68kde~1_32.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D6 = $%08X  A6 = $%08X",d6,a6) ;
       move.l    _a6.L,-(A7)
       move.l    _d6.L,-(A7)
       pea       @m68kde~1_33.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D7 = $%08X  A7 = $%08X",d7,((SR & (unsigned short int)(0x2000)) == ((unsigned short int)(0x2000))) ? SSP : USP) ;
       move.w    (A4),D1
       and.w     #8192,D1
       cmp.w     #8192,D1
       bne.s     DumpRegisters_18
       move.l    _SSP.L,D1
       bra.s     DumpRegisters_19
DumpRegisters_18:
       move.l    _USP.L,D1
DumpRegisters_19:
       move.l    D1,-(A7)
       move.l    _d7.L,-(A7)
       pea       @m68kde~1_34.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n\r\nUSP = $%08X  (A7) User SP", USP ) ;
       move.l    _USP.L,-(A7)
       pea       @m68kde~1_35.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\nSSP = $%08X  (A7) Supervisor SP", SSP) ;
       move.l    _SSP.L,-(A7)
       pea       @m68kde~1_36.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\n SR = $%04X   ",SR) ;
       move.w    (A4),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_37.L
       jsr       (A3)
       addq.w    #8,A7
; // display the status word in characters etc.
; printf("   [") ;
       pea       @m68kde~1_38.L
       jsr       (A3)
       addq.w    #4,A7
; if((SR & (unsigned short int)(0x8000)) == (unsigned short int)(0x8000)) putchar('T') ; else putchar('-') ;      // Trace bit(bit 15)
       move.w    (A4),D0
       and.w     #32768,D0
       cmp.w     #32768,D0
       bne.s     DumpRegisters_20
       pea       84
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_21
DumpRegisters_20:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_21:
; if((SR & (unsigned short int)(0x2000)) == (unsigned short int)(0x2000)) putchar('S') ; else putchar('U') ;      // supervisor bit  (bit 13)
       move.w    (A4),D0
       and.w     #8192,D0
       cmp.w     #8192,D0
       bne.s     DumpRegisters_22
       pea       83
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_23
DumpRegisters_22:
       pea       85
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_23:
; if((SR & (unsigned short int)(0x0400)) == (unsigned short int)(0x0400)) putchar('1') ; else putchar('0') ;      // IRQ2 Bit (bit 10)
       move.w    (A4),D0
       and.w     #1024,D0
       cmp.w     #1024,D0
       bne.s     DumpRegisters_24
       pea       49
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_25
DumpRegisters_24:
       pea       48
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_25:
; if((SR & (unsigned short int)(0x0200)) == (unsigned short int)(0x0200)) putchar('1') ; else putchar('0') ;      // IRQ1 Bit (bit 9)
       move.w    (A4),D0
       and.w     #512,D0
       cmp.w     #512,D0
       bne.s     DumpRegisters_26
       pea       49
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_27
DumpRegisters_26:
       pea       48
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_27:
; if((SR & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100)) putchar('1') ; else putchar('0') ;      // IRQ0 Bit (bit 8)
       move.w    (A4),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DumpRegisters_28
       pea       49
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_29
DumpRegisters_28:
       pea       48
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_29:
; if((SR & (unsigned short int)(0x0010)) == (unsigned short int)(0x0010)) putchar('X') ; else putchar('-') ;      // X Bit (bit 4)
       move.w    (A4),D0
       and.w     #16,D0
       cmp.w     #16,D0
       bne.s     DumpRegisters_30
       pea       88
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_31
DumpRegisters_30:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_31:
; if((SR & (unsigned short int)(0x0008)) == (unsigned short int)(0x0008)) putchar('N') ; else putchar('-') ;      // N Bit (bit 3)
       move.w    (A4),D0
       and.w     #8,D0
       cmp.w     #8,D0
       bne.s     DumpRegisters_32
       pea       78
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_33
DumpRegisters_32:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_33:
; if((SR & (unsigned short int)(0x0004)) == (unsigned short int)(0x0004)) putchar('Z') ; else putchar('-') ;      // Z Bit (bit 2)
       move.w    (A4),D0
       and.w     #4,D0
       cmp.w     #4,D0
       bne.s     DumpRegisters_34
       pea       90
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_35
DumpRegisters_34:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_35:
; if((SR & (unsigned short int)(0x0002)) == (unsigned short int)(0x0002)) putchar('V') ; else putchar('-') ;      // V Bit (bit 1)
       move.w    (A4),D0
       and.w     #2,D0
       cmp.w     #2,D0
       bne.s     DumpRegisters_36
       pea       86
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_37
DumpRegisters_36:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_37:
; if((SR & (unsigned short int)(0x0001)) == (unsigned short int)(0x0001)) putchar('C') ; else putchar('-') ;      // C Bit (bit 0)
       move.w    (A4),D0
       and.w     #1,D0
       cmp.w     #1,D0
       bne.s     DumpRegisters_38
       pea       67
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_39
DumpRegisters_38:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_39:
; putchar(']') ;
       pea       93
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n PC = $%08X  ", PC) ;
       move.l    _PC.L,-(A7)
       pea       @m68kde~1_39.L
       jsr       (A3)
       addq.w    #8,A7
; if(*(unsigned short int *)(PC) == 0x4e4e)
       move.l    _PC.L,D0
       move.l    D0,A0
       move.w    (A0),D0
       cmp.w     #20046,D0
       bne.s     DumpRegisters_40
; printf("[@ BREAKPOINT]") ;
       pea       @m68kde~1_40.L
       jsr       (A3)
       addq.w    #4,A7
DumpRegisters_40:
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A3)
       addq.w    #4,A7
; for(i=0; i < 8; i++)    {
       clr.w     D4
DumpRegisters_42:
       cmp.w     #8,D4
       bge       DumpRegisters_44
; if(WatchPointSetOrCleared[i] == 1)
       ext.l     D4
       move.l    D4,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     DumpRegisters_45
; printf("\r\nWP%d = %s", i, WatchPointString[i]) ;
       move.l    A5,D1
       ext.l     D4
       move.l    D0,-(A7)
       move.l    D4,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       ext.l     D4
       move.l    D4,-(A7)
       pea       @m68kde~1_41.L
       jsr       (A3)
       add.w     #12,A7
DumpRegisters_45:
       addq.w    #1,D4
       bra       DumpRegisters_42
DumpRegisters_44:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       rts
; }
; }
; // Trace Exception Handler
; void DumpRegistersandPause(void)
; {
       xdef      _DumpRegistersandPause
_DumpRegistersandPause:
       move.l    A2,-(A7)
       lea       _printf.L,A2
; printf("\r\n\r\n\r\n\r\n\r\n\r\nSingle Step  :[ON]") ;
       pea       @m68kde~1_42.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nBreak Points :[Disabled]") ;
       pea       @m68kde~1_43.L
       jsr       (A2)
       addq.w    #4,A7
; DumpRegisters() ;
       jsr       _DumpRegisters
; printf("\r\nPress <SPACE> to Execute Next Instruction");
       pea       @m68kde~1_44.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nPress <ESC> to Resume Program") ;
       pea       @m68kde~1_45.L
       jsr       (A2)
       addq.w    #4,A7
; menu() ;
       jsr       _menu
       move.l    (A7)+,A2
       rts
; }
; void ChangeRegisters(void)
; {
       xdef      _ChangeRegisters
_ChangeRegisters:
       link      A6,#-4
       movem.l   D2/D3/A2/A3/A4/A5,-(A7)
       lea       _printf.L,A2
       lea       -4(A6),A3
       lea       _Get8HexDigits.L,A4
       lea       __getch.L,A5
; // get register name d0-d7, a0-a7, up, sp, sr, pc
; int reg_val ;
; char c, reg[3] ;
; reg[0] = tolower(_getch()) ;
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       move.b    D0,(A3)
; reg[1] = c = tolower(_getch()) ;
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       move.b    D0,D2
       move.b    D0,1(A3)
; if(reg[0] == (char)('d'))  {    // change data register
       move.b    (A3),D0
       cmp.b     #100,D0
       bne       ChangeRegisters_1
; if((reg[1] > (char)('7')) || (reg[1] < (char)('0'))) {
       move.b    1(A3),D0
       cmp.b     #55,D0
       bgt.s     ChangeRegisters_5
       move.b    1(A3),D0
       cmp.b     #48,D0
       bge.s     ChangeRegisters_3
ChangeRegisters_5:
; printf("\r\nIllegal Data Register : Use D0-D7.....\r\n") ;
       pea       @m68kde~1_46.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_3:
; }
; else {
; printf("\r\nD%c = ", c) ;
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       pea       @m68kde~1_47.L
       jsr       (A2)
       addq.w    #8,A7
; reg_val = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,D3
; }
; // bit cludgy but d0-d7 not stored as an array for good reason
; if(c == (char)('0'))
       cmp.b     #48,D2
       bne.s     ChangeRegisters_7
; d0 = reg_val ;
       move.l    D3,_d0.L
       bra       ChangeRegisters_20
ChangeRegisters_7:
; else if(c == (char)('1'))
       cmp.b     #49,D2
       bne.s     ChangeRegisters_9
; d1 = reg_val ;
       move.l    D3,_d1.L
       bra       ChangeRegisters_20
ChangeRegisters_9:
; else if(c == (char)('2'))
       cmp.b     #50,D2
       bne.s     ChangeRegisters_11
; d2 = reg_val ;
       move.l    D3,_d2.L
       bra       ChangeRegisters_20
ChangeRegisters_11:
; else if(c == (char)('3'))
       cmp.b     #51,D2
       bne.s     ChangeRegisters_13
; d3 = reg_val ;
       move.l    D3,_d3.L
       bra.s     ChangeRegisters_20
ChangeRegisters_13:
; else if(c == (char)('4'))
       cmp.b     #52,D2
       bne.s     ChangeRegisters_15
; d4 = reg_val ;
       move.l    D3,_d4.L
       bra.s     ChangeRegisters_20
ChangeRegisters_15:
; else if(c == (char)('5'))
       cmp.b     #53,D2
       bne.s     ChangeRegisters_17
; d5 = reg_val ;
       move.l    D3,_d5.L
       bra.s     ChangeRegisters_20
ChangeRegisters_17:
; else if(c == (char)('6'))
       cmp.b     #54,D2
       bne.s     ChangeRegisters_19
; d6 = reg_val ;
       move.l    D3,_d6.L
       bra.s     ChangeRegisters_20
ChangeRegisters_19:
; else
; d7 = reg_val ;
       move.l    D3,_d7.L
ChangeRegisters_20:
       bra       ChangeRegisters_51
ChangeRegisters_1:
; }
; else if(reg[0] == (char)('a'))  {    // change address register, a7 is the user stack pointer, sp is the system stack pointer
       move.b    (A3),D0
       cmp.b     #97,D0
       bne       ChangeRegisters_21
; if((c > (char)('7')) || (c < (char)('0'))) {
       cmp.b     #55,D2
       bgt.s     ChangeRegisters_25
       cmp.b     #48,D2
       bge.s     ChangeRegisters_23
ChangeRegisters_25:
; printf("\r\nIllegal Address Register : Use A0-A7.....\r\n") ;
       pea       @m68kde~1_48.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_23:
; }
; else {
; printf("\r\nA%c = ", c) ;
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       pea       @m68kde~1_49.L
       jsr       (A2)
       addq.w    #8,A7
; reg_val = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,D3
; }
; // bit cludgy but a0-a7 not stored as an array for good reason
; if(c == (char)('0'))
       cmp.b     #48,D2
       bne.s     ChangeRegisters_26
; a0 = reg_val ;
       move.l    D3,_a0.L
       bra       ChangeRegisters_39
ChangeRegisters_26:
; else if(c == (char)('1'))
       cmp.b     #49,D2
       bne.s     ChangeRegisters_28
; a1 = reg_val ;
       move.l    D3,_a1.L
       bra       ChangeRegisters_39
ChangeRegisters_28:
; else if(c == (char)('2'))
       cmp.b     #50,D2
       bne.s     ChangeRegisters_30
; a2 = reg_val ;
       move.l    D3,_a2.L
       bra       ChangeRegisters_39
ChangeRegisters_30:
; else if(c == (char)('3'))
       cmp.b     #51,D2
       bne.s     ChangeRegisters_32
; a3 = reg_val ;
       move.l    D3,_a3.L
       bra.s     ChangeRegisters_39
ChangeRegisters_32:
; else if(c == (char)('4'))
       cmp.b     #52,D2
       bne.s     ChangeRegisters_34
; a4 = reg_val ;
       move.l    D3,_a4.L
       bra.s     ChangeRegisters_39
ChangeRegisters_34:
; else if(c == (char)('5'))
       cmp.b     #53,D2
       bne.s     ChangeRegisters_36
; a5 = reg_val ;
       move.l    D3,_a5.L
       bra.s     ChangeRegisters_39
ChangeRegisters_36:
; else if(c == (char)('6'))
       cmp.b     #54,D2
       bne.s     ChangeRegisters_38
; a6 = reg_val ;
       move.l    D3,_a6.L
       bra.s     ChangeRegisters_39
ChangeRegisters_38:
; else
; USP = reg_val ;
       move.l    D3,_USP.L
ChangeRegisters_39:
       bra       ChangeRegisters_51
ChangeRegisters_21:
; }
; else if((reg[0] == (char)('u')) && (c == (char)('s')))  {
       move.b    (A3),D0
       cmp.b     #117,D0
       bne       ChangeRegisters_40
       cmp.b     #115,D2
       bne       ChangeRegisters_40
; if(tolower(_getch()) == 'p')  {    // change user stack pointer
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       cmp.l     #112,D0
       bne.s     ChangeRegisters_42
; printf("\r\nUser SP = ") ;
       pea       @m68kde~1_50.L
       jsr       (A2)
       addq.w    #4,A7
; USP = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,_USP.L
       bra.s     ChangeRegisters_43
ChangeRegisters_42:
; }
; else {
; printf("\r\nIllegal Register....") ;
       pea       @m68kde~1_51.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_43:
       bra       ChangeRegisters_51
ChangeRegisters_40:
; }
; }
; else if((reg[0] == (char)('s')) && (c == (char)('s')))  {
       move.b    (A3),D0
       cmp.b     #115,D0
       bne       ChangeRegisters_44
       cmp.b     #115,D2
       bne       ChangeRegisters_44
; if(tolower(_getch()) == 'p')  {    // change system stack pointer
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       cmp.l     #112,D0
       bne.s     ChangeRegisters_46
; printf("\r\nSystem SP = ") ;
       pea       @m68kde~1_52.L
       jsr       (A2)
       addq.w    #4,A7
; SSP = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,_SSP.L
       bra.s     ChangeRegisters_47
ChangeRegisters_46:
; }
; else {
; printf("\r\nIllegal Register....") ;
       pea       @m68kde~1_51.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_47:
       bra       ChangeRegisters_51
ChangeRegisters_44:
; }
; }
; else if((reg[0] == (char)('p')) && (c == (char)('c')))  {    // change program counter
       move.b    (A3),D0
       cmp.b     #112,D0
       bne.s     ChangeRegisters_48
       cmp.b     #99,D2
       bne.s     ChangeRegisters_48
; printf("\r\nPC = ") ;
       pea       @m68kde~1_53.L
       jsr       (A2)
       addq.w    #4,A7
; PC = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,_PC.L
       bra       ChangeRegisters_51
ChangeRegisters_48:
; }
; else if((reg[0] == (char)('s')) && (c == (char)('r')))  {    // change status register
       move.b    (A3),D0
       cmp.b     #115,D0
       bne.s     ChangeRegisters_50
       cmp.b     #114,D2
       bne.s     ChangeRegisters_50
; printf("\r\nSR = ") ;
       pea       @m68kde~1_54.L
       jsr       (A2)
       addq.w    #4,A7
; SR = Get4HexDigits(0) ;    // read 16 bit value from user keyboard
       clr.l     -(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.w    D0,_SR.L
       bra.s     ChangeRegisters_51
ChangeRegisters_50:
; }
; else
; printf("\r\nIllegal Register: Use A0-A7, D0-D7, SSP, USP, PC or SR\r\n") ;
       pea       @m68kde~1_55.L
       jsr       (A2)
       addq.w    #4,A7
ChangeRegisters_51:
; DumpRegisters() ;
       jsr       _DumpRegisters
ChangeRegisters_6:
       movem.l   (A7)+,D2/D3/A2/A3/A4/A5
       unlk      A6
       rts
; }
; void BreakPointDisplay(void)
; {
       xdef      _BreakPointDisplay
_BreakPointDisplay:
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _BreakPointAddress.L,A3
; int i, BreakPointsSet = 0 ;
       clr.l     D3
; // any break points  set
; for(i = 0; i < 8; i++)  {
       clr.l     D2
BreakPointDisplay_1:
       cmp.l     #8,D2
       bge.s     BreakPointDisplay_3
; if(BreakPointSetOrCleared[i] == 1)
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     BreakPointDisplay_4
; BreakPointsSet = 1;
       moveq     #1,D3
BreakPointDisplay_4:
       addq.l    #1,D2
       bra       BreakPointDisplay_1
BreakPointDisplay_3:
; }
; if(BreakPointsSet == 1) {
       cmp.l     #1,D3
       bne.s     BreakPointDisplay_6
; printf("\r\n\r\nNum     Address      Instruction") ;
       pea       @m68kde~1_56.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n---     ---------    -----------") ;
       pea       @m68kde~1_57.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     BreakPointDisplay_7
BreakPointDisplay_6:
; }
; else
; printf("\r\nNo BreakPoints Set") ;
       pea       @m68kde~1_58.L
       jsr       (A2)
       addq.w    #4,A7
BreakPointDisplay_7:
; for(i = 0; i < 8; i++)  {
       clr.l     D2
BreakPointDisplay_8:
       cmp.l     #8,D2
       bge       BreakPointDisplay_10
; // put opcode back, then put break point back
; if(BreakPointSetOrCleared[i] == 1)  {
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne       BreakPointDisplay_11
; *(unsigned short int *)(BreakPointAddress[i]) = BreakPointInstruction[i];
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    0(A3,D1.L),D1
       move.l    D1,A1
       move.w    0(A0,D0.L),(A1)
; *(unsigned short int *)(BreakPointAddress[i]) = (unsigned short int)(0x4e4e) ;
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       move.l    D0,A0
       move.w    #20046,(A0)
; printf("\r\n%3d     $%08x",i, BreakPointAddress[i]) ;
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    0(A3,D1.L),-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_59.L
       jsr       (A2)
       add.w     #12,A7
BreakPointDisplay_11:
       addq.l    #1,D2
       bra       BreakPointDisplay_8
BreakPointDisplay_10:
; }
; }
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/A2/A3
       rts
; }
; void WatchPointDisplay(void)
; {
       xdef      _WatchPointDisplay
_WatchPointDisplay:
       movem.l   D2/D3/A2,-(A7)
       lea       _printf.L,A2
; int i ;
; int WatchPointsSet = 0 ;
       clr.l     D3
; // any watchpoints set
; for(i = 0; i < 8; i++)  {
       clr.l     D2
WatchPointDisplay_1:
       cmp.l     #8,D2
       bge.s     WatchPointDisplay_3
; if(WatchPointSetOrCleared[i] == 1)
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     WatchPointDisplay_4
; WatchPointsSet = 1;
       moveq     #1,D3
WatchPointDisplay_4:
       addq.l    #1,D2
       bra       WatchPointDisplay_1
WatchPointDisplay_3:
; }
; if(WatchPointsSet == 1) {
       cmp.l     #1,D3
       bne.s     WatchPointDisplay_6
; printf("\r\nNum     Address") ;
       pea       @m68kde~1_60.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n---     ---------") ;
       pea       @m68kde~1_61.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     WatchPointDisplay_7
WatchPointDisplay_6:
; }
; else
; printf("\r\nNo WatchPoints Set") ;
       pea       @m68kde~1_62.L
       jsr       (A2)
       addq.w    #4,A7
WatchPointDisplay_7:
; for(i = 0; i < 8; i++)  {
       clr.l     D2
WatchPointDisplay_8:
       cmp.l     #8,D2
       bge       WatchPointDisplay_10
; if(WatchPointSetOrCleared[i] == 1)
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     WatchPointDisplay_11
; printf("\r\n%3d     $%08x",i, WatchPointAddress[i]) ;
       move.l    D2,D1
       lsl.l     #2,D1
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D1.L),-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_59.L
       jsr       (A2)
       add.w     #12,A7
WatchPointDisplay_11:
       addq.l    #1,D2
       bra       WatchPointDisplay_8
WatchPointDisplay_10:
; }
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; void BreakPointClear(void)
; {
       xdef      _BreakPointClear
_BreakPointClear:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; unsigned int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; BreakPointDisplay() ;
       jsr       _BreakPointDisplay
; printf("\r\nEnter Break Point Number: ") ;
       pea       @m68kde~1_63.L
       jsr       (A2)
       addq.w    #4,A7
; i = xtod(_getch()) ;           // get break pointer number
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D2
; if((i < 0) || (i > 7))   {
       cmp.l     #0,D2
       blo.s     BreakPointClear_3
       cmp.l     #7,D2
       bls.s     BreakPointClear_1
BreakPointClear_3:
; printf("\r\nIllegal Range : Use 0 - 7") ;
       pea       @m68kde~1_64.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       BreakPointClear_4
BreakPointClear_1:
; }
; if(BreakPointSetOrCleared[i] == 1)  {       // if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne       BreakPointClear_5
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program we are about to change
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; BreakPointAddress[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; *ProgramBreakPointAddress = BreakPointInstruction[i] ;  // put original instruction back
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
; BreakPointInstruction[i] = 0 ;
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
; printf("\r\nBreak Point Cleared.....\r\n") ;
       pea       @m68kde~1_65.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     BreakPointClear_6
BreakPointClear_5:
; }
; else
; printf("\r\nBreak Point wasn't Set.....") ;
       pea       @m68kde~1_66.L
       jsr       (A2)
       addq.w    #4,A7
BreakPointClear_6:
; BreakPointDisplay() ;
       jsr       _BreakPointDisplay
; return ;
BreakPointClear_4:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; void WatchPointClear(void)
; {
       xdef      _WatchPointClear
_WatchPointClear:
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; unsigned int i ;
; WatchPointDisplay() ;
       jsr       _WatchPointDisplay
; printf("\r\nEnter Watch Point Number: ") ;
       pea       @m68kde~1_67.L
       jsr       (A2)
       addq.w    #4,A7
; i = xtod(_getch()) ;           // get watch pointer number
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D2
; if((i < 0) || (i > 7))   {
       cmp.l     #0,D2
       blo.s     WatchPointClear_3
       cmp.l     #7,D2
       bls.s     WatchPointClear_1
WatchPointClear_3:
; printf("\r\nIllegal Range : Use 0 - 7") ;
       pea       @m68kde~1_64.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       WatchPointClear_4
WatchPointClear_1:
; }
; if(WatchPointSetOrCleared[i] == 1)  {       // if watch point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     WatchPointClear_5
; WatchPointAddress[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       clr.l     0(A0,D0.L)
; WatchPointSetOrCleared[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; printf("\r\nWatch Point Cleared.....\r\n") ;
       pea       @m68kde~1_68.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     WatchPointClear_6
WatchPointClear_5:
; }
; else
; printf("\r\nWatch Point Was not Set.....") ;
       pea       @m68kde~1_69.L
       jsr       (A2)
       addq.w    #4,A7
WatchPointClear_6:
; WatchPointDisplay() ;
       jsr       _WatchPointDisplay
; return ;
WatchPointClear_4:
       movem.l   (A7)+,D2/A2
       rts
; }
; void DisableBreakPoints(void)
; {
       xdef      _DisableBreakPoints
_DisableBreakPoints:
       link      A6,#-4
       move.l    D2,-(A7)
; int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
DisableBreakPoints_1:
       cmp.l     #8,D2
       bge       DisableBreakPoints_3
; if(BreakPointSetOrCleared[i] == 1)    {                                                    // if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     DisableBreakPoints_4
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; *ProgramBreakPointAddress = BreakPointInstruction[i];                                  // copy the instruction back to the user program overwritting the $4e4e
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
DisableBreakPoints_4:
       addq.l    #1,D2
       bra       DisableBreakPoints_1
DisableBreakPoints_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; void EnableBreakPoints(void)
; {
       xdef      _EnableBreakPoints
_EnableBreakPoints:
       link      A6,#-4
       move.l    D2,-(A7)
; int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
EnableBreakPoints_1:
       cmp.l     #8,D2
       bge.s     EnableBreakPoints_3
; if(BreakPointSetOrCleared[i] == 1)    {                                                     // if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     EnableBreakPoints_4
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; *ProgramBreakPointAddress = (unsigned short int)(0x4e4e);                              // put the breakpoint back in user program
       move.l    -4(A6),A0
       move.w    #20046,(A0)
EnableBreakPoints_4:
       addq.l    #1,D2
       bra       EnableBreakPoints_1
EnableBreakPoints_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; void KillAllBreakPoints(void)
; {
       xdef      _KillAllBreakPoints
_KillAllBreakPoints:
       link      A6,#-4
       move.l    D2,-(A7)
; int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
KillAllBreakPoints_1:
       cmp.l     #8,D2
       bge       KillAllBreakPoints_3
; // clear BP
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; *ProgramBreakPointAddress = BreakPointInstruction[i];                                  // copy the instruction back to the user program
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
; BreakPointAddress[i] = 0 ;                                                             // set BP address to NULL
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointInstruction[i] = 0 ;
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0 ;                                                        // mark break point as cleared for future setting
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
       addq.l    #1,D2
       bra       KillAllBreakPoints_1
KillAllBreakPoints_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //BreakPointDisplay() ;       // display the break points
; }
; void KillAllWatchPoints(void)
; {
       xdef      _KillAllWatchPoints
_KillAllWatchPoints:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
KillAllWatchPoints_1:
       cmp.l     #8,D2
       bge.s     KillAllWatchPoints_3
; WatchPointAddress[i] = 0 ;                                                             // set BP address to NULL
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       clr.l     0(A0,D0.L)
; WatchPointSetOrCleared[i] = 0 ;                                                        // mark break point as cleared for future setting
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
       addq.l    #1,D2
       bra       KillAllWatchPoints_1
KillAllWatchPoints_3:
       move.l    (A7)+,D2
       rts
; }
; //WatchPointDisplay() ;       // display the break points
; }
; void SetBreakPoint(void)
; {
       xdef      _SetBreakPoint
_SetBreakPoint:
       link      A6,#-4
       movem.l   D2/D3/D4/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _BreakPointSetOrCleared.L,A3
; int i ;
; int BPNumber;
; int BPAddress;
; volatile unsigned short int *ProgramBreakPointAddress ;
; // see if any free break points
; for(i = 0; i < 8; i ++) {
       clr.l     D2
SetBreakPoint_1:
       cmp.l     #8,D2
       bge.s     SetBreakPoint_3
; if( BreakPointSetOrCleared[i] == 0)
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne.s     SetBreakPoint_4
; break ;         // if spare BP found allow user to set it
       bra.s     SetBreakPoint_3
SetBreakPoint_4:
       addq.l    #1,D2
       bra       SetBreakPoint_1
SetBreakPoint_3:
; }
; if(i == 8) {
       cmp.l     #8,D2
       bne.s     SetBreakPoint_6
; printf("\r\nNo FREE Break Points.....") ;
       pea       @m68kde~1_70.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_6:
; }
; printf("\r\nBreak Point Address: ") ;
       pea       @m68kde~1_71.L
       jsr       (A2)
       addq.w    #4,A7
; BPAddress = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; ProgramBreakPointAddress = (volatile unsigned short int *)(BPAddress) ;     // point to the instruction in the user program we are about to change
       move.l    D3,D4
; if((BPAddress & 0x00000001) == 0x00000001)  {   // cannot set BP at an odd address
       move.l    D3,D0
       and.l     #1,D0
       cmp.l     #1,D0
       bne.s     SetBreakPoint_9
; printf("\r\nError : Break Points CANNOT be set at ODD addresses") ;
       pea       @m68kde~1_72.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_9:
; }
; if(BPAddress < 0x00008000)  {   // cannot set BP in ROM
       cmp.l     #32768,D3
       bhs.s     SetBreakPoint_11
; printf("\r\nError : Break Points CANNOT be set for ROM in Range : [$0-$00007FFF]") ;
       pea       @m68kde~1_73.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_11:
; }
; // search for first free bp or existing same BP
; for(i = 0; i < 8; i++)  {
       clr.l     D2
SetBreakPoint_13:
       cmp.l     #8,D2
       bge       SetBreakPoint_15
; if(BreakPointAddress[i] == BPAddress)   {
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       cmp.l     0(A0,D0.L),D3
       bne.s     SetBreakPoint_16
; printf("\r\nError: Break Point Already Exists at Address : %08x\r\n", BPAddress) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_74.L
       jsr       (A2)
       addq.w    #8,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_16:
; }
; if(BreakPointSetOrCleared[i] == 0) {
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne       SetBreakPoint_18
; // set BP here
; BreakPointSetOrCleared[i] = 1 ;                                 // mark this breakpoint as set
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    #1,0(A3,D0.L)
; BreakPointInstruction[i] = *ProgramBreakPointAddress ;          // copy the user program instruction here so we can put it back afterwards
       move.l    D4,A0
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A1
       move.w    (A0),0(A1,D0.L)
; printf("\r\nBreak Point Set at Address: [$%08x]", ProgramBreakPointAddress) ;
       move.l    D4,-(A7)
       pea       @m68kde~1_75.L
       jsr       (A2)
       addq.w    #8,A7
; *ProgramBreakPointAddress = (unsigned short int)(0x4e4e)    ;   // put a Trap14 instruction at the user specified address
       move.l    D4,A0
       move.w    #20046,(A0)
; BreakPointAddress[i] = BPAddress ;                              // record the address of this break point in the debugger
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    D3,0(A0,D0.L)
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; BreakPointDisplay() ;       // display the break points
       jsr       _BreakPointDisplay
; return ;
       bra.s     SetBreakPoint_15
SetBreakPoint_18:
       addq.l    #1,D2
       bra       SetBreakPoint_13
SetBreakPoint_15:
       movem.l   (A7)+,D2/D3/D4/A2/A3
       unlk      A6
       rts
; }
; }
; }
; void SetWatchPoint(void)
; {
       xdef      _SetWatchPoint
_SetWatchPoint:
       link      A6,#-8
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _WatchPointSetOrCleared.L,A3
; int i ;
; int WPNumber;
; int WPAddress;
; volatile unsigned short int *ProgramWatchPointAddress ;
; // see if any free break points
; for(i = 0; i < 8; i ++) {
       clr.l     D2
SetWatchPoint_1:
       cmp.l     #8,D2
       bge.s     SetWatchPoint_3
; if( WatchPointSetOrCleared[i] == 0)
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne.s     SetWatchPoint_4
; break ;         // if spare WP found allow user to set it
       bra.s     SetWatchPoint_3
SetWatchPoint_4:
       addq.l    #1,D2
       bra       SetWatchPoint_1
SetWatchPoint_3:
; }
; if(i == 8) {
       cmp.l     #8,D2
       bne.s     SetWatchPoint_6
; printf("\r\nNo FREE Watch Points.....") ;
       pea       @m68kde~1_76.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetWatchPoint_11
SetWatchPoint_6:
; }
; printf("\r\nWatch Point Address: ") ;
       pea       @m68kde~1_77.L
       jsr       (A2)
       addq.w    #4,A7
; WPAddress = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; // search for first free wp or existing same wp
; for(i = 0; i < 8; i++)  {
       clr.l     D2
SetWatchPoint_9:
       cmp.l     #8,D2
       bge       SetWatchPoint_11
; if(WatchPointAddress[i] == WPAddress && WPAddress != 0)   {     //so we can set a wp at 0
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       cmp.l     0(A0,D0.L),D3
       bne.s     SetWatchPoint_12
       tst.l     D3
       beq.s     SetWatchPoint_12
; printf("\r\nError: Watch Point Already Set at Address : %08x\r\n", WPAddress) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_78.L
       jsr       (A2)
       addq.w    #8,A7
; return ;
       bra       SetWatchPoint_11
SetWatchPoint_12:
; }
; if(WatchPointSetOrCleared[i] == 0) {
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne       SetWatchPoint_14
; WatchPointSetOrCleared[i] = 1 ;                                 // mark this watchpoint as set
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    #1,0(A3,D0.L)
; printf("\r\nWatch Point Set at Address: [$%08x]", WPAddress) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_79.L
       jsr       (A2)
       addq.w    #8,A7
; WatchPointAddress[i] = WPAddress ;                              // record the address of this watch point in the debugger
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       move.l    D3,0(A0,D0.L)
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; WatchPointDisplay() ;       // display the break points
       jsr       _WatchPointDisplay
; return ;
       bra.s     SetWatchPoint_11
SetWatchPoint_14:
       addq.l    #1,D2
       bra       SetWatchPoint_9
SetWatchPoint_11:
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; }
; }
; void HandleBreakPoint(void)
; {
       xdef      _HandleBreakPoint
_HandleBreakPoint:
       link      A6,#-4
       movem.l   A2/A3/A4,-(A7)
       lea       _i.L,A2
       lea       _printf.L,A3
       lea       _PC.L,A4
; volatile unsigned short int *ProgramBreakPointAddress ;
; // now we have to put the break point back to run the instruction
; // PC will contain the address of the TRAP instruction but advanced by two bytes so lets play with that
; PC = PC - 2 ;  // ready for user to resume after reaching breakpoint
       subq.l    #2,(A4)
; printf("\r\n\r\n\r\n\r\n@BREAKPOINT") ;
       pea       @m68kde~1_80.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nSingle Step : [ON]") ;
       pea       @m68kde~1_81.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nBreakPoints : [Enabled]") ;
       pea       @m68kde~1_82.L
       jsr       (A3)
       addq.w    #4,A7
; // now clear the break point (put original instruction back)
; ProgramBreakPointAddress = PC ;
       move.l    (A4),-4(A6)
; for(i = 0; i < 8; i ++) {
       clr.l     (A2)
HandleBreakPoint_1:
       move.l    (A2),D0
       cmp.l     #8,D0
       bhs       HandleBreakPoint_3
; if(BreakPointAddress[i] == PC) {        // if we have found the breakpoint
       move.l    (A2),D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),D1
       cmp.l     (A4),D1
       bne       HandleBreakPoint_4
; BreakPointAddress[i] = 0 ;
       move.l    (A2),D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0 ;
       move.l    (A2),D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; *ProgramBreakPointAddress = BreakPointInstruction[i] ;  // put original instruction back
       move.l    (A2),D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
; BreakPointInstruction[i] = 0 ;
       move.l    (A2),D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
HandleBreakPoint_4:
       addq.l    #1,(A2)
       bra       HandleBreakPoint_1
HandleBreakPoint_3:
; }
; }
; DumpRegisters() ;
       jsr       _DumpRegisters
; printf("\r\nPress <SPACE> to Execute Next Instruction");
       pea       @m68kde~1_44.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nPress <ESC> to Resume User Program\r\n") ;
       pea       @m68kde~1_83.L
       jsr       (A3)
       addq.w    #4,A7
; menu() ;
       jsr       _menu
       movem.l   (A7)+,A2/A3/A4
       unlk      A6
       rts
; }
; void UnknownCommand()
; {
       xdef      _UnknownCommand
_UnknownCommand:
; printf("\r\nUnknown Command.....\r\n") ;
       pea       @m68kde~1_84.L
       jsr       _printf
       addq.w    #4,A7
; Help() ;
       jsr       _Help
       rts
; }
; // system when the users program executes a TRAP #15 instruction to halt program and return to debug monitor
; void CallDebugMonitor(void)
; {
       xdef      _CallDebugMonitor
_CallDebugMonitor:
; printf("\r\nProgram Ended (TRAP #15)....") ;
       pea       @m68kde~1_85.L
       jsr       _printf
       addq.w    #4,A7
; menu();
       jsr       _menu
       rts
; }
; void Breakpoint(void)
; {
       xdef      _Breakpoint
_Breakpoint:
       move.l    D2,-(A7)
; char c;
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if( c == (char)('D'))                                      // BreakPoint Display
       cmp.b     #68,D2
       bne.s     Breakpoint_1
; BreakPointDisplay() ;
       jsr       _BreakPointDisplay
       bra       Breakpoint_10
Breakpoint_1:
; else if(c == (char)('K')) {                                 // breakpoint Kill
       cmp.b     #75,D2
       bne.s     Breakpoint_3
; printf("\r\nKill All Break Points...(y/n)?") ;
       pea       @m68kde~1_86.L
       jsr       _printf
       addq.w    #4,A7
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if(c == (char)('Y'))
       cmp.b     #89,D2
       bne.s     Breakpoint_5
; KillAllBreakPoints() ;
       jsr       _KillAllBreakPoints
Breakpoint_5:
       bra.s     Breakpoint_10
Breakpoint_3:
; }
; else if(c == (char)('S')) {
       cmp.b     #83,D2
       bne.s     Breakpoint_7
; SetBreakPoint() ;
       jsr       _SetBreakPoint
       bra.s     Breakpoint_10
Breakpoint_7:
; }
; else if(c == (char)('C')) {
       cmp.b     #67,D2
       bne.s     Breakpoint_9
; BreakPointClear() ;
       jsr       _BreakPointClear
       bra.s     Breakpoint_10
Breakpoint_9:
; }
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
Breakpoint_10:
       move.l    (A7)+,D2
       rts
; }
; void Watchpoint(void)
; {
       xdef      _Watchpoint
_Watchpoint:
       move.l    D2,-(A7)
; char c;
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if( c == (char)('D'))                                      // WatchPoint Display
       cmp.b     #68,D2
       bne.s     Watchpoint_1
; WatchPointDisplay() ;
       jsr       _WatchPointDisplay
       bra       Watchpoint_10
Watchpoint_1:
; else if(c == (char)('K')) {                                 // wtahcpoint Kill
       cmp.b     #75,D2
       bne.s     Watchpoint_3
; printf("\r\nKill All Watch Points...(y/n)?") ;
       pea       @m68kde~1_87.L
       jsr       _printf
       addq.w    #4,A7
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if(c == (char)('Y'))
       cmp.b     #89,D2
       bne.s     Watchpoint_5
; KillAllWatchPoints() ;
       jsr       _KillAllWatchPoints
Watchpoint_5:
       bra.s     Watchpoint_10
Watchpoint_3:
; }
; else if(c == (char)('S')) {
       cmp.b     #83,D2
       bne.s     Watchpoint_7
; SetWatchPoint() ;
       jsr       _SetWatchPoint
       bra.s     Watchpoint_10
Watchpoint_7:
; }
; else if(c == (char)('C')) {
       cmp.b     #67,D2
       bne.s     Watchpoint_9
; WatchPointClear() ;
       jsr       _WatchPointClear
       bra.s     Watchpoint_10
Watchpoint_9:
; }
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
Watchpoint_10:
       move.l    (A7)+,D2
       rts
; }
; void Help(void)
; {
       xdef      _Help
_Help:
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; char *banner = "\r\n----------------------------------------------------------------" ;
       lea       @m68kde~1_88.L,A0
       move.l    A0,D2
; printf(banner) ;
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  Final Project") ;
       pea       @m68kde~1_89.L
       jsr       (A2)
       addq.w    #4,A7
; printf(banner) ;
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  G            - Run Snake Game") ;
       pea       @m68kde~1_90.L
       jsr       (A2)
       addq.w    #4,A7
; printf(banner) ;
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/A2
       rts
; }
; void menu(void)
; {
       xdef      _menu
_menu:
       link      A6,#-4
; char c,c1 ;
; while(1)    {
menu_1:
; FlushKeyboard() ;               // dump unread characters from keyboard
       jsr       _FlushKeyboard
; printf("\r\n#") ;
       pea       @m68kde~1_91.L
       jsr       _printf
       addq.w    #4,A7
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,-2(A6)
; if( c == (char)('G'))  {           // go user program
       move.b    -2(A6),D0
       cmp.b     #71,D0
       bne.s     menu_4
; printf("\r\nRunning Snake Game\n") ;
       pea       @m68kde~1_92.L
       jsr       _printf
       addq.w    #4,A7
; snake_main();
       jsr       _snake_main
       bra.s     menu_5
menu_4:
; }
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
menu_5:
       bra       menu_1
; }
; }
; void PrintErrorMessageandAbort(char *string) {
       xdef      _PrintErrorMessageandAbort
_PrintErrorMessageandAbort:
       link      A6,#0
; printf("\r\n\r\nProgram ABORT !!!!!!\r\n") ;
       pea       @m68kde~1_93.L
       jsr       _printf
       addq.w    #4,A7
; printf("%s\r\n", string) ;
       move.l    8(A6),-(A7)
       pea       @m68kde~1_94.L
       jsr       _printf
       addq.w    #8,A7
; menu() ;
       jsr       _menu
       unlk      A6
       rts
; }
; void IRQMessage(int level) {
       xdef      _IRQMessage
_IRQMessage:
       link      A6,#0
; printf("\r\n\r\nProgram ABORT !!!!!");
       pea       @m68kde~1_95.L
       jsr       _printf
       addq.w    #4,A7
; printf("\r\nUnhandled Interrupt: IRQ%d !!!!!", level) ;
       move.l    8(A6),-(A7)
       pea       @m68kde~1_96.L
       jsr       _printf
       addq.w    #8,A7
; menu() ;
       jsr       _menu
       unlk      A6
       rts
; }
; void UnhandledIRQ1(void) {
       xdef      _UnhandledIRQ1
_UnhandledIRQ1:
; IRQMessage(1);
       pea       1
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ2(void) {
       xdef      _UnhandledIRQ2
_UnhandledIRQ2:
; IRQMessage(2);
       pea       2
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ3(void){
       xdef      _UnhandledIRQ3
_UnhandledIRQ3:
; IRQMessage(3);
       pea       3
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ4(void) {
       xdef      _UnhandledIRQ4
_UnhandledIRQ4:
; IRQMessage(4);
       pea       4
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ5(void) {
       xdef      _UnhandledIRQ5
_UnhandledIRQ5:
; IRQMessage(5);
       pea       5
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ6(void) {
       xdef      _UnhandledIRQ6
_UnhandledIRQ6:
; PrintErrorMessageandAbort("ADDRESS ERROR: 16 or 32 Bit Transfer to/from an ODD Address....") ;
       pea       @m68kde~1_97.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
; menu() ;
       jsr       _menu
       rts
; }
; void UnhandledIRQ7(void) {
       xdef      _UnhandledIRQ7
_UnhandledIRQ7:
; IRQMessage(7);
       pea       7
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledTrap(void) {
       xdef      _UnhandledTrap
_UnhandledTrap:
; PrintErrorMessageandAbort("Unhandled Trap !!!!!") ;
       pea       @m68kde~1_98.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void BusError() {
       xdef      _BusError
_BusError:
; PrintErrorMessageandAbort("BUS Error!") ;
       pea       @m68kde~1_99.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void AddressError() {
       xdef      _AddressError
_AddressError:
; PrintErrorMessageandAbort("ADDRESS Error!") ;
       pea       @m68kde~1_100.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void IllegalInstruction() {
       xdef      _IllegalInstruction
_IllegalInstruction:
; PrintErrorMessageandAbort("ILLEGAL INSTRUCTION") ;
       pea       @m68kde~1_101.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Dividebyzero() {
       xdef      _Dividebyzero
_Dividebyzero:
; PrintErrorMessageandAbort("DIVIDE BY ZERO") ;
       pea       @m68kde~1_102.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Check() {
       xdef      _Check
_Check:
; PrintErrorMessageandAbort("'CHK' INSTRUCTION") ;
       pea       @m68kde~1_103.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Trapv() {
       xdef      _Trapv
_Trapv:
; PrintErrorMessageandAbort("TRAPV INSTRUCTION") ;
       pea       @m68kde~1_104.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void PrivError() {
       xdef      _PrivError
_PrivError:
; PrintErrorMessageandAbort("PRIVILEGE VIOLATION") ;
       pea       @m68kde~1_105.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void UnitIRQ() {
       xdef      _UnitIRQ
_UnitIRQ:
; PrintErrorMessageandAbort("UNINITIALISED IRQ") ;
       pea       @m68kde~1_106.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Spurious() {
       xdef      _Spurious
_Spurious:
; PrintErrorMessageandAbort("SPURIOUS IRQ") ;
       pea       @m68kde~1_107.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void EnterString(void)
; {
       xdef      _EnterString
_EnterString:
       link      A6,#-4
       move.l    D2,-(A7)
; unsigned char *Start;
; unsigned char c;
; printf("\r\nStart Address in Memory: ") ;
       pea       @m68kde~1_108.L
       jsr       _printf
       addq.w    #4,A7
; Start = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; printf("\r\nEnter String (ESC to end) :") ;
       pea       @m68kde~1_109.L
       jsr       _printf
       addq.w    #4,A7
; while((c = getchar()) != 0x1b)
EnterString_1:
       jsr       _getch
       move.b    D0,-1(A6)
       cmp.b     #27,D0
       beq.s     EnterString_3
; *Start++ = c ;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    -1(A6),(A0)
       bra       EnterString_1
EnterString_3:
; *Start = 0x00;  // terminate with a null
       move.l    D2,A0
       clr.b     (A0)
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; void putcharxy(int x, int y, char ch) {
       xdef      _putcharxy
_putcharxy:
       link      A6,#-4
; //display on the VGA char ch at column x, line y
; volatile unsigned char* addr;
; addr = &vga_ram_start + NUM_VGA_COLUMNS*y + x;
       move.l    #6291456,D0
       move.l    12(A6),-(A7)
       pea       80
       jsr       LMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       add.l     8(A6),D0
       move.l    D0,-4(A6)
; *addr = ch;
       move.l    -4(A6),A0
       move.b    19(A6),(A0)
       unlk      A6
       rts
; }
; void print_at_xy(int x,
; int y,
; const char* str) {
       xdef      _print_at_xy
_print_at_xy:
       link      A6,#0
       movem.l   D2/D3/D4/D5,-(A7)
; //print a string on the VGA, starting at column x, line y. 
; //Wrap around to the next line if we reach the edge of the screen
; int end_of_str = 0;
       clr.l     D5
; int i = 0;
       clr.l     D4
; int x_coord = x;
       move.l    8(A6),D3
; int y_coord = y;
       move.l    12(A6),D2
; while (!end_of_str)
print_at_xy_1:
       tst.l     D5
       bne       print_at_xy_3
; {
; if (*(str+i) != '\0')
       move.l    16(A6),A0
       move.b    0(A0,D4.L),D0
       beq       print_at_xy_4
; {   
; if (x_coord > NUM_VGA_COLUMNS-1) { //Wrap around to the next line if we reach the edge of the screen
       cmp.l     #79,D3
       ble.s     print_at_xy_6
; x_coord = 0;
       clr.l     D3
; y_coord++;
       addq.l    #1,D2
print_at_xy_6:
; }
; if (y_coord > NUM_VGA_ROWS-1) {
       cmp.l     #39,D2
       ble.s     print_at_xy_8
; y_coord = 0;
       clr.l     D2
print_at_xy_8:
; }
; putcharxy(x_coord,y_coord, *(str+i));
       move.l    16(A6),A0
       move.b    0(A0,D4.L),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
; x_coord++;
       addq.l    #1,D3
       bra.s     print_at_xy_5
print_at_xy_4:
; }
; else
; {
; end_of_str = 1;
       moveq     #1,D5
print_at_xy_5:
; }
; i++;
       addq.l    #1,D4
       bra       print_at_xy_1
print_at_xy_3:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; }
; void cls()
; {
       xdef      _cls
_cls:
       link      A6,#-4
       movem.l   D2/D3,-(A7)
; //clear the screen
; int x;
; int y;
; char space = 0x20;
       move.b    #32,-1(A6)
; for (y=0; y<NUM_VGA_ROWS; y++) {
       clr.l     D3
cls_1:
       cmp.l     #40,D3
       bge.s     cls_3
; for (x=0; x<NUM_VGA_COLUMNS; x++) {
       clr.l     D2
cls_4:
       cmp.l     #80,D2
       bge.s     cls_6
; putcharxy(x,y,space);
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       addq.l    #1,D2
       bra       cls_4
cls_6:
       addq.l    #1,D3
       bra       cls_1
cls_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; };
; void gotoxy(int x, int y)
; {
       xdef      _gotoxy
_gotoxy:
       link      A6,#0
; //move the cursor to location column = x, row = y
; vga_x_cursor_reg = x;
       move.l    8(A6),D0
       move.b    D0,6295552
; vga_y_cursor_reg = y;
       move.l    12(A6),D0
       move.b    D0,6295554
       unlk      A6
       rts
; };
; void set_vga_control_reg(char x) {
       xdef      _set_vga_control_reg
_set_vga_control_reg:
       link      A6,#0
; //Set the VGA control (OCTL) value
; vga_ctrl_reg = x;
       move.b    11(A6),6295556
       unlk      A6
       rts
; }
; char get_vga_control_reg() {
       xdef      _get_vga_control_reg
_get_vga_control_reg:
       link      A6,#-4
; //return the VGA control (OCTL) value
; char value;
; value = vga_ctrl_reg;
       move.b    6295556,-1(A6)
; return value;
       move.b    -1(A6),D0
       unlk      A6
       rts
; }
; int clock() {
       xdef      _clock
_clock:
; //return the current value of a milliseconds counter, with a resolution of 10ms or better
; if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
       move.b    4194358,D0
       cmp.b     #1,D0
       bne.s     clock_1
; Timer2Control = 3; // reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194358
; clock_counter = clock_counter + 10;
       add.l     #10,_clock_counter.L
clock_1:
; }
; return clock_counter;
       move.l    _clock_counter.L,D0
       rts
; }
; void delay_ms(int num_ms) {
       xdef      _delay_ms
_delay_ms:
       link      A6,#-4
; //delay a certain number of milliseconds
; int initial_time;
; initial_time = clock();
       jsr       _clock
       move.l    D0,-4(A6)
; while ((clock() - initial_time) < num_ms) {}
delay_ms_1:
       jsr       _clock
       sub.l     -4(A6),D0
       cmp.l     8(A6),D0
       bge.s     delay_ms_3
       bra       delay_ms_1
delay_ms_3:
       unlk      A6
       rts
; }
; void string_cursor(int x,
; int y,
; const char* str)
; {
       xdef      _string_cursor
_string_cursor:
       link      A6,#0
       movem.l   D2/D3/D4/D5/A2/A3,-(A7)
       lea       _gotoxy.L,A2
       lea       _delay_ms.L,A3
; int end_of_str = 0;
       clr.l     D5
; int i = 0;
       clr.l     D4
; int x_coord = x;
       move.l    8(A6),D3
; int y_coord = y;
       move.l    12(A6),D2
; while (!end_of_str)
string_cursor_1:
       tst.l     D5
       bne       string_cursor_3
; {
; if (*(str+i) != '\0')
       move.l    16(A6),A0
       move.b    0(A0,D4.L),D0
       beq       string_cursor_4
; {   
; if (x_coord > NUM_VGA_COLUMNS-1) { //Wrap around to the next line if we reach the edge of the screen
       cmp.l     #79,D3
       ble.s     string_cursor_6
; x_coord = 0;
       clr.l     D3
; y_coord++;
       addq.l    #1,D2
string_cursor_6:
; }
; if (y_coord > NUM_VGA_ROWS-1) {
       cmp.l     #39,D2
       ble.s     string_cursor_8
; y_coord = 0;
       clr.l     D2
string_cursor_8:
; }
; putcharxy(x_coord,y_coord, *(str+i));
       move.l    16(A6),A0
       move.b    0(A0,D4.L),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
; delay_ms(100);
       pea       100
       jsr       (A3)
       addq.w    #4,A7
; gotoxy(x_coord,y_coord);
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; delay_ms(100);
       pea       100
       jsr       (A3)
       addq.w    #4,A7
; x_coord++;
       addq.l    #1,D3
       bra.s     string_cursor_5
string_cursor_4:
; }
; else
; {
; end_of_str = 1;
       moveq     #1,D5
string_cursor_5:
; }
; i++;
       addq.l    #1,D4
       bra       string_cursor_1
string_cursor_3:
; }
; gotoxy(x_coord,y_coord);
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; delay_ms(100);
       pea       100
       jsr       (A3)
       addq.w    #4,A7
; gotoxy(x_coord+1,y_coord);
       move.l    D2,-(A7)
       move.l    D3,D1
       addq.l    #1,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3
       unlk      A6
       rts
; }
; void int_to_str (char* str, int num)
; {   
       xdef      _int_to_str
_int_to_str:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6,-(A7)
       move.l    8(A6),D3
       move.l    12(A6),D5
; int i = 0, j, sign;
       clr.l     D4
; // handle negative numbers
; if (num < 0) {
       cmp.l     #0,D5
       bge.s     int_to_str_1
; sign = -1;
       moveq     #-1,D6
; num = -num;
       move.l    D5,D0
       neg.l     D0
       move.l    D0,D5
       bra.s     int_to_str_2
int_to_str_1:
; }
; else {
; sign = 1;
       moveq     #1,D6
int_to_str_2:
; }
; // convert each digit of the number to a character and store in the buffer
; do {
int_to_str_3:
; str[i++] = num % 10 + '0';
       move.l    D5,-(A7)
       pea       10
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       add.l     #48,D0
       move.l    D3,A0
       move.l    D4,D1
       addq.l    #1,D4
       move.b    D0,0(A0,D1.L)
       move.l    D5,-(A7)
       pea       10
       jsr       LDIV
       move.l    (A7),D5
       addq.w    #8,A7
       cmp.l     #0,D5
       bgt       int_to_str_3
; } while ((num /= 10) > 0);
; // add the negative sign if necessary
; if (sign == -1) {
       cmp.l     #-1,D6
       bne.s     int_to_str_5
; str[i++] = '-';
       move.l    D3,A0
       move.l    D4,D0
       addq.l    #1,D4
       move.b    #45,0(A0,D0.L)
int_to_str_5:
; }
; // reverse the string
; for (j = 0; j < i / 2; j++) {
       clr.l     D2
int_to_str_7:
       move.l    D4,-(A7)
       pea       2
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       cmp.l     D0,D2
       bge.s     int_to_str_9
; char temp = str[j];
       move.l    D3,A0
       move.b    0(A0,D2.L),-1(A6)
; str[j] = str[i - j - 1];
       move.l    D3,A0
       move.l    D4,D0
       sub.l     D2,D0
       subq.l    #1,D0
       move.l    D3,A1
       move.b    0(A0,D0.L),0(A1,D2.L)
; str[i - j - 1] = temp;
       move.l    D3,A0
       move.l    D4,D0
       sub.l     D2,D0
       subq.l    #1,D0
       move.b    -1(A6),0(A0,D0.L)
       addq.l    #1,D2
       bra       int_to_str_7
int_to_str_9:
; }
; // add null terminator to the end of the string
; str[i] = '\0';
       move.l    D3,A0
       clr.b     0(A0,D4.L)
       movem.l   (A7)+,D2/D3/D4/D5/D6
       unlk      A6
       rts
; }
; void gameOver()
; {
       xdef      _gameOver
_gameOver:
       link      A6,#-20
       movem.l   D2/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _string_cursor.L,A3
; //show game over screen and animation
; char score_str[20];
; unsigned int vga_color = 2;
       moveq     #2,D2
; int_to_str(score_str, score);
       move.l    _score.L,-(A7)
       pea       -20(A6)
       jsr       _int_to_str
       addq.w    #8,A7
; cls();
       jsr       _cls
; gotoxy(35,18);
       pea       18
       pea       35
       jsr       _gotoxy
       addq.w    #8,A7
; set_vga_control_reg(0xe2);
       pea       226
       jsr       _set_vga_control_reg
       addq.w    #4,A7
; putcharxy(35,18,'G');
       pea       71
       pea       18
       pea       35
       jsr       _putcharxy
       add.w     #12,A7
; delay_ms(100);
       pea       100
       jsr       _delay_ms
       addq.w    #4,A7
; string_cursor(36,18, "ame Over!");
       pea       @m68kde~1_110.L
       pea       18
       pea       36
       jsr       (A3)
       add.w     #12,A7
; string_cursor(35,20, "Score: ");
       pea       @m68kde~1_111.L
       pea       20
       pea       35
       jsr       (A3)
       add.w     #12,A7
; string_cursor(42,20, score_str);
       pea       -20(A6)
       pea       20
       pea       42
       jsr       (A3)
       add.w     #12,A7
; //gotoxy(45,20);
; printf("\r\nGame over !");
       pea       @m68kde~1_112.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nyour score was %d\n", score);
       move.l    _score.L,-(A7)
       pea       @m68kde~1_113.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\npress any key\n");
       pea       @m68kde~1_114.L
       jsr       (A2)
       addq.w    #4,A7
; FlushKeyboard() ; 
       jsr       _FlushKeyboard
; while (1)
gameOver_1:
; {   
; delay_ms(300);
       pea       300
       jsr       _delay_ms
       addq.w    #4,A7
; vga_color = (vga_color+1) & 7; // extract the color bits
       move.l    D2,D0
       addq.l    #1,D0
       and.l     #7,D0
       move.l    D0,D2
; if (vga_color == 0)
       tst.l     D2
       bne.s     gameOver_4
; {
; vga_color = 1;
       moveq     #1,D2
gameOver_4:
; }
; set_vga_control_reg((0xe0 | vga_color));
       move.w    #224,D1
       ext.l     D1
       or.l      D2,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _set_vga_control_reg
       addq.w    #4,A7
; if (kbhit()){
       jsr       _kbhit
       tst.l     D0
       beq.s     gameOver_6
; break;
       bra.s     gameOver_3
gameOver_6:
       bra       gameOver_1
gameOver_3:
       movem.l   (A7)+,D2/A2/A3
       unlk      A6
       rts
; }
; }
; }
; void updateScore()
; {
       xdef      _updateScore
_updateScore:
       link      A6,#-20
; //print the score at the bottom of the screen
; char score_str[20];
; int_to_str(score_str, score);
       move.l    _score.L,-(A7)
       pea       -20(A6)
       jsr       _int_to_str
       addq.w    #8,A7
; print_at_xy(1,NUM_VGA_ROWS-1, "Score: ");
       pea       @m68kde~1_111.L
       pea       39
       pea       1
       jsr       _print_at_xy
       add.w     #12,A7
; print_at_xy(8,NUM_VGA_ROWS-1, score_str);
       pea       -20(A6)
       pea       39
       pea       8
       jsr       _print_at_xy
       add.w     #12,A7
       unlk      A6
       rts
; }
; void drawRect(int x, int y, int x2, int y2, char ch)
; {
       xdef      _drawRect
_drawRect:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6/A2,-(A7)
       move.l    12(A6),D4
       move.b    27(A6),D5
       ext.w     D5
       ext.l     D5
       lea       _putcharxy.L,A2
       move.l    8(A6),D6
; //draws a rectangle. Left top corner: (x1,y1) length of sides = x2,y2
; int x_pos,y_pos;
; // draw horizontal edges
; for (x_pos = x; x_pos < x+x2; x_pos++)
       move.l    D6,D3
drawRect_1:
       move.l    D6,D0
       add.l     16(A6),D0
       cmp.l     D0,D3
       bge       drawRect_3
; {
; putcharxy(x_pos,y,ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,-(A7)
       move.l    D3,-(A7)
       jsr       (A2)
       add.w     #12,A7
; putcharxy(x_pos,y+y2-1,ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,D1
       add.l     20(A6),D1
       subq.l    #1,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       jsr       (A2)
       add.w     #12,A7
       addq.l    #1,D3
       bra       drawRect_1
drawRect_3:
; }
; // draw vertial edges
; for (y_pos = y; y_pos < y+y2-1; y_pos++)
       move.l    D4,D2
drawRect_4:
       move.l    D4,D0
       add.l     20(A6),D0
       subq.l    #1,D0
       cmp.l     D0,D2
       bge       drawRect_6
; {
; putcharxy(x,y_pos,ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       move.l    D6,-(A7)
       jsr       (A2)
       add.w     #12,A7
; putcharxy(x+x2-1,y_pos,ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       move.l    D6,D1
       add.l     16(A6),D1
       subq.l    #1,D1
       move.l    D1,-(A7)
       jsr       (A2)
       add.w     #12,A7
       addq.l    #1,D2
       bra       drawRect_4
drawRect_6:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2
       unlk      A6
       rts
; }
; }
; void initSnake()
; {
       xdef      _initSnake
_initSnake:
; Snake.speed          = INITIAL_SNAKE_SPEED ;         
       move.l    #2,_Snake+16390.L
; Snake.speed_increase = SNAKE_SPEED_INCREASE;
       move.l    #1,_Snake+16394.L
       rts
; }
; void drawSnake()
; {
       xdef      _drawSnake
_drawSnake:
       movem.l   D2/A2,-(A7)
       lea       _Snake.L,A2
; int i;
; for(i = 0; i < Snake.length; i++)
       clr.l     D2
drawSnake_1:
       cmp.l     16384(A2),D2
       bge.s     drawSnake_3
; {
; putcharxy(Snake.xy[i].x, Snake.xy[i].y,SNAKE);
       pea       83
       move.l    D2,D1
       lsl.l     #3,D1
       lea       0(A2,D1.L),A0
       move.l    4(A0),-(A7)
       move.l    D2,D1
       lsl.l     #3,D1
       move.l    0(A2,D1.L),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       addq.l    #1,D2
       bra       drawSnake_1
drawSnake_3:
       movem.l   (A7)+,D2/A2
       rts
; }
; }
; void drawFood()
; {
       xdef      _drawFood
_drawFood:
; putcharxy(Snake.food.x, Snake.food.y,FOOD);
       pea       64
       move.l    _Snake+16402.L,-(A7)
       move.l    _Snake+16398.L,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       rts
; }
; void moveSnake()//remove tail, move array, add new head based on direction
; {
       xdef      _moveSnake
_moveSnake:
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _Snake.L,A2
; int i;
; int x;
; int y;
; x = Snake.xy[0].x;
       move.l    (A2),D3
; y = Snake.xy[0].y;
       move.l    4(A2),D2
; //saves initial head for direction determination
; putcharxy(Snake.xy[Snake.length-1].x, Snake.xy[Snake.length-1].y,' ');
       pea       32
       move.l    16384(A2),D1
       subq.l    #1,D1
       lsl.l     #3,D1
       lea       0(A2,D1.L),A0
       move.l    4(A0),-(A7)
       move.l    16384(A2),D1
       subq.l    #1,D1
       lsl.l     #3,D1
       move.l    0(A2,D1.L),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
; for(i = Snake.length; i > 1; i--)
       move.l    16384(A2),D4
moveSnake_1:
       cmp.l     #1,D4
       ble       moveSnake_3
; {
; Snake.xy[i-1] = Snake.xy[i-2];
       move.l    A2,D0
       move.l    D4,D1
       subq.l    #1,D1
       lsl.l     #3,D1
       add.l     D1,D0
       move.l    D0,A0
       move.l    A2,D0
       move.l    D4,D1
       subq.l    #2,D1
       lsl.l     #3,D1
       add.l     D1,D0
       move.l    D0,A1
       move.l    (A1)+,(A0)+
       move.l    (A1)+,(A0)+
       subq.l    #1,D4
       bra       moveSnake_1
moveSnake_3:
; }
; //moves the snake array to the right
; switch (Snake.direction)
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #4,D0
       bhs       moveSnake_4
       asl.l     #1,D0
       move.w    moveSnake_6(PC,D0.L),D0
       jmp       moveSnake_6(PC,D0.W)
moveSnake_6:
       dc.w      moveSnake_7-moveSnake_6
       dc.w      moveSnake_8-moveSnake_6
       dc.w      moveSnake_9-moveSnake_6
       dc.w      moveSnake_10-moveSnake_6
moveSnake_7:
; {
; case north:
; if (y > 0)  { y--; }
       cmp.l     #0,D2
       ble.s     moveSnake_12
       subq.l    #1,D2
moveSnake_12:
; break;
       bra.s     moveSnake_5
moveSnake_8:
; case south:
; if (y < (NUM_VGA_ROWS-1)) { y++; }
       cmp.l     #39,D2
       bge.s     moveSnake_14
       addq.l    #1,D2
moveSnake_14:
; break;
       bra.s     moveSnake_5
moveSnake_9:
; case west:
; if (x > 0) { x--; }
       cmp.l     #0,D3
       ble.s     moveSnake_16
       subq.l    #1,D3
moveSnake_16:
; break;
       bra.s     moveSnake_5
moveSnake_10:
; case east:
; if (x < (NUM_VGA_COLUMNS-1))  { x++; }
       cmp.l     #79,D3
       bge.s     moveSnake_18
       addq.l    #1,D3
moveSnake_18:
; break;
       bra       moveSnake_5
moveSnake_4:
; default:
; break;
moveSnake_5:
; }
; //adds new snake head
; Snake.xy[0].x = x;
       move.l    D3,(A2)
; Snake.xy[0].y = y;
       move.l    D2,4(A2)
; waiting_for_direction_to_be_implemented = 0;
       clr.l     _waiting_for_direction_to_be_imp.L
; putcharxy(Snake.xy[0].x,Snake.xy[0].y,SNAKE);
       pea       83
       move.l    4(A2),-(A7)
       move.l    (A2),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       movem.l   (A7)+,D2/D3/D4/A2
       rts
; }
; /* Compute x mod y using binary long division. */
; int mod_bld(int x, int y)
; {
       xdef      _mod_bld
_mod_bld:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; int modulus = x, divisor = y;
       move.l    8(A6),D3
       move.l    12(A6),D2
; while (divisor <= modulus && divisor <= 16384)
mod_bld_1:
       cmp.l     D3,D2
       bgt.s     mod_bld_3
       cmp.l     #16384,D2
       bgt.s     mod_bld_3
; divisor <<= 1;
       asl.l     #1,D2
       bra       mod_bld_1
mod_bld_3:
; while (modulus >= y) {
mod_bld_4:
       cmp.l     12(A6),D3
       blt.s     mod_bld_6
; while (divisor > modulus)
mod_bld_7:
       cmp.l     D3,D2
       ble.s     mod_bld_9
; divisor >>= 1;
       asr.l     #1,D2
       bra       mod_bld_7
mod_bld_9:
; modulus -= divisor;
       sub.l     D2,D3
       bra       mod_bld_4
mod_bld_6:
; }
; return modulus;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; void generateFood()
; {
       xdef      _generateFood
_generateFood:
       movem.l   D2/D3/A2,-(A7)
       lea       _Snake.L,A2
; int bol;
; int i;
; static int firsttime = 1;
; //removes last food
; if (!firsttime) {
       tst.l     generateFood_firsttime.L
       bne.s     generateFood_2
; putcharxy(Snake.food.x,Snake.food.y,' ');
       pea       32
       move.l    16402(A2),-(A7)
       move.l    16398(A2),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       bra.s     generateFood_3
generateFood_2:
; } else {
; firsttime = 0;
       clr.l     generateFood_firsttime.L
generateFood_3:
; }
; do
; {
generateFood_4:
; bol = 0;
       clr.l     D3
; //pseudo-randomly set food location
; //use clock instead of random function that is
; //not implemented in ide68k
; Snake.food.x = 3+ mod_bld(((clock()& 0xFFF0) >> 4),screensize.x-6); 
       moveq     #3,D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       move.l    _screensize.L,D0
       subq.l    #6,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       _clock
       move.l    (A7)+,D1
       and.l     #65520,D0
       asr.l     #4,D0
       move.l    D0,-(A7)
       jsr       _mod_bld
       addq.w    #8,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       add.l     D1,D0
       move.l    D0,16398(A2)
; Snake.food.y = 3+ mod_bld(clock()& 0xFFFF,screensize.y-6); 
       moveq     #3,D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       move.l    D0,-(A7)
       move.l    _screensize+4.L,D0
       subq.l    #6,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       _clock
       move.l    (A7)+,D1
       and.l     #65535,D0
       move.l    D0,-(A7)
       jsr       _mod_bld
       addq.w    #8,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    (A7)+,D0
       add.l     D1,D0
       move.l    D0,16402(A2)
; for(i = 0; i < Snake.length; i++)
       clr.l     D2
generateFood_6:
       cmp.l     16384(A2),D2
       bge.s     generateFood_8
; {
; if (Snake.food.x == Snake.xy[i].x && Snake.food.y == Snake.xy[i].y) {
       move.l    D2,D0
       lsl.l     #3,D0
       move.l    16398(A2),D1
       cmp.l     0(A2,D0.L),D1
       bne.s     generateFood_9
       move.l    D2,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A0
       move.l    16402(A2),D0
       cmp.l     4(A0),D0
       bne.s     generateFood_9
; bol = 1; //resets loop if collision detected
       moveq     #1,D3
generateFood_9:
       addq.l    #1,D2
       bra       generateFood_6
generateFood_8:
       tst.l     D3
       bne       generateFood_4
; }
; }
; } while (bol);//while colliding with snake
; drawFood();
       jsr       _drawFood
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; int getKeypress()
; {
       xdef      _getKeypress
_getKeypress:
       movem.l   A2/A3,-(A7)
       lea       _Snake.L,A2
       lea       _waiting_for_direction_to_be_imp.L,A3
; if (kbhit()) {
       jsr       _kbhit
       tst.l     D0
       beq       getKeypress_4
; switch (_getch())
       jsr       __getch
       cmp.l     #113,D0
       beq       getKeypress_10
       bgt.s     getKeypress_12
       cmp.l     #100,D0
       beq       getKeypress_8
       bgt.s     getKeypress_13
       cmp.l     #97,D0
       beq       getKeypress_7
       bra       getKeypress_3
getKeypress_13:
       cmp.l     #112,D0
       beq       getKeypress_9
       bra       getKeypress_3
getKeypress_12:
       cmp.l     #119,D0
       beq.s     getKeypress_5
       bgt       getKeypress_3
       cmp.l     #115,D0
       beq.s     getKeypress_6
       bra       getKeypress_3
getKeypress_5:
; {
; case 'w':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != south)){
       tst.l     (A3)
       bne.s     getKeypress_14
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #1,D0
       beq.s     getKeypress_14
; Snake.direction = north;
       clr.w     16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_14:
; }
; break;
       bra       getKeypress_4
getKeypress_6:
; case 's':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != north)){
       tst.l     (A3)
       bne.s     getKeypress_16
       move.w    16388(A2),D0
       ext.l     D0
       tst.l     D0
       beq.s     getKeypress_16
; Snake.direction = south;
       move.w    #1,16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_16:
; }
; break;
       bra       getKeypress_4
getKeypress_7:
; case 'a':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != east)){
       tst.l     (A3)
       bne.s     getKeypress_18
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #3,D0
       beq.s     getKeypress_18
; Snake.direction = west;
       move.w    #2,16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_18:
; }
; break;
       bra.s     getKeypress_4
getKeypress_8:
; case 'd':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != west)){
       tst.l     (A3)
       bne.s     getKeypress_20
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #2,D0
       beq.s     getKeypress_20
; Snake.direction = east;
       move.w    #3,16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_20:
; }
; break;
       bra.s     getKeypress_4
getKeypress_9:
; case 'p':
; _getch();
       jsr       __getch
; break;
       bra.s     getKeypress_4
getKeypress_10:
; case 'q':
; gameOver();
       jsr       _gameOver
; return 0;
       clr.l     D0
       bra.s     getKeypress_22
getKeypress_3:
; default:
; //do nothing
; break;
getKeypress_4:
; }
; }
; return 1;
       moveq     #1,D0
getKeypress_22:
       movem.l   (A7)+,A2/A3
       rts
; }
; int detectCollision()//with self -> game over, food -> delete food add score (only head checks)
; // returns 0 for no collision, 1 for game over
; {
       xdef      _detectCollision
_detectCollision:
       movem.l   D2/D3/A2,-(A7)
       lea       _Snake.L,A2
; int i;
; int retval;
; retval = 0;
       clr.l     D3
; if (Snake.xy[0].x == Snake.food.x && Snake.xy[0].y == Snake.food.y) {
       move.l    (A2),D0
       cmp.l     16398(A2),D0
       bne       detectCollision_1
       move.l    4(A2),D0
       cmp.l     16402(A2),D0
       bne       detectCollision_1
; //detect collision with food
; Snake.length++;
       move.l    A2,D0
       add.l     #16384,D0
       move.l    D0,A0
       addq.l    #1,(A0)
; Snake.xy[Snake.length-1].x = Snake.xy[Snake.length-2].x;
       move.l    16384(A2),D0
       subq.l    #2,D0
       lsl.l     #3,D0
       move.l    16384(A2),D1
       subq.l    #1,D1
       lsl.l     #3,D1
       move.l    0(A2,D0.L),0(A2,D1.L)
; Snake.xy[Snake.length-1].y = Snake.xy[Snake.length-2].y;
       move.l    16384(A2),D0
       subq.l    #2,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A0
       move.l    16384(A2),D0
       subq.l    #1,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A1
       move.l    4(A0),4(A1)
; Snake.speed = Snake.speed + Snake.speed_increase;
       move.l    16390(A2),D0
       add.l     16394(A2),D0
       move.l    D0,16390(A2)
; generateFood();
       jsr       _generateFood
; score++;
       addq.l    #1,_score.L
; updateScore();
       jsr       _updateScore
detectCollision_1:
; }
; for(i = 2; i < Snake.length; i++)
       moveq     #2,D2
detectCollision_3:
       cmp.l     16384(A2),D2
       bge.s     detectCollision_5
; {
; //detects collision of the head
; if (Snake.xy[i].x == Snake.xy[0].x && Snake.xy[i].y == Snake.xy[0].y) {
       move.l    D2,D0
       lsl.l     #3,D0
       move.l    0(A2,D0.L),D1
       cmp.l     (A2),D1
       bne.s     detectCollision_6
       move.l    D2,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A0
       move.l    4(A0),D0
       cmp.l     4(A2),D0
       bne.s     detectCollision_6
; gameOver();
       jsr       _gameOver
; retval = 1;
       moveq     #1,D3
detectCollision_6:
       addq.l    #1,D2
       bra       detectCollision_3
detectCollision_5:
; }
; }
; if (Snake.xy[0].x == 1 || Snake.xy[0].x == (screensize.x-1) || Snake.xy[0].y == 1 || Snake.xy[0].y == (screensize.y-2)) {
       move.l    (A2),D0
       cmp.l     #1,D0
       beq.s     detectCollision_10
       move.l    _screensize.L,D0
       subq.l    #1,D0
       cmp.l     (A2),D0
       beq.s     detectCollision_10
       move.l    4(A2),D0
       cmp.l     #1,D0
       beq.s     detectCollision_10
       move.l    _screensize+4.L,D0
       subq.l    #2,D0
       cmp.l     4(A2),D0
       bne.s     detectCollision_8
detectCollision_10:
; //collision with wall
; gameOver();
       jsr       _gameOver
; retval = 1;
       moveq     #1,D3
detectCollision_8:
; }
; return retval;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; void mainloop()
; {
       xdef      _mainloop
_mainloop:
       link      A6,#-4
       move.l    D2,-(A7)
; int current_time;
; int got_game_over;
; while(1){
mainloop_1:
; if (!getKeypress()) { // getKeypress is zero when you press 'q'
       jsr       _getKeypress
       tst.l     D0
       bne.s     mainloop_4
; return;
       bra       mainloop_3
mainloop_4:
; }
; current_time = clock();
       jsr       _clock
       move.l    D0,D2
; //printf("\r\nCurrent time: %d",current_time);
; if (current_time >= ((MILLISECONDS_PER_SEC/Snake.speed) + timer)) {
       pea       1000
       move.l    _Snake+16390.L,-(A7)
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     _timer.L,D0
       cmp.l     D0,D2
       blt.s     mainloop_7
; moveSnake(); //draws new snake position
       jsr       _moveSnake
; got_game_over = detectCollision();
       jsr       _detectCollision
       move.l    D0,-4(A6)
; if (got_game_over) {
       tst.l     -4(A6)
       beq.s     mainloop_9
; break;
       bra.s     mainloop_3
mainloop_9:
; }
; timer = current_time;
       move.l    D2,_timer.L
mainloop_7:
       bra       mainloop_1
mainloop_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; void snake_main()
; {   
       xdef      _snake_main
_snake_main:
       move.l    A2,-(A7)
       lea       _Snake.L,A2
; clock_counter = 0;
       clr.l     _clock_counter.L
; score = 0;
       clr.l     _score.L
; vga_color = 2;
       move.l    #2,_vga_color.L
; waiting_for_direction_to_be_implemented = 0;
       clr.l     _waiting_for_direction_to_be_imp.L
; Snake.xy[0].x = 4;
       move.l    #4,(A2)
; Snake.xy[0].y = 3;
       move.l    #3,4(A2)
; Snake.xy[1].x = 3;
       move.l    #3,8(A2)
; Snake.xy[1].y = 3;
       move.l    #3,12(A2)
; Snake.xy[2].x = 2;
       move.l    #2,16(A2)
; Snake.xy[2].y = 3;
       move.l    #3,20(A2)
; Snake.length = INITIAL_SNAKE_LENGTH;
       move.l    #3,16384(A2)
; Snake.direction = east;
       move.w    #3,16388(A2)
; set_vga_control_reg(0x82);
       pea       130
       jsr       _set_vga_control_reg
       addq.w    #4,A7
; initSnake();
       jsr       _initSnake
; cls();
       jsr       _cls
; drawRect(1,1,screensize.x-1,screensize.y-2, BORDER);
       pea       35
       move.l    _screensize+4.L,D1
       subq.l    #2,D1
       move.l    D1,-(A7)
       move.l    _screensize.L,D1
       subq.l    #1,D1
       move.l    D1,-(A7)
       pea       1
       pea       1
       jsr       _drawRect
       add.w     #20,A7
; drawSnake();
       jsr       _drawSnake
; generateFood();
       jsr       _generateFood
; drawFood();
       jsr       _drawFood
; timer = clock();
       jsr       _clock
       move.l    D0,_timer.L
; updateScore();
       jsr       _updateScore
; mainloop();
       jsr       _mainloop
       move.l    (A7)+,A2
       rts
; }
; void main(void)
; {
       xdef      _main
_main:
       link      A6,#-12
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _InstallExceptionHandler.L,A2
       lea       _printf.L,A3
; char c ;
; int i, j ;
; char *BugMessage = "DE1-68k Bug V1.77";
       lea       @m68kde~1_115.L,A0
       move.l    A0,D3
; char *CopyrightMessage = "Copyright (C) PJ Davies 2016";
       lea       @m68kde~1_116.L,A0
       move.l    A0,-4(A6)
; KillAllBreakPoints() ;
       jsr       _KillAllBreakPoints
; i = x = y = z = PortA_Count = 0;
       clr.l     _PortA_Count.L
       clr.l     _z.L
       clr.l     _y.L
       clr.l     _x.L
       clr.l     D2
; Trace = GoFlag = 0;                       // used in tracing/single stepping
       clr.l     _GoFlag.L
       clr.l     _Trace.L
; Echo = 1 ;
       move.l    #1,_Echo.L
; d0=d1=d2=d3=d4=d5=d6=d7=0 ;
       clr.l     _d7.L
       clr.l     _d6.L
       clr.l     _d5.L
       clr.l     _d4.L
       clr.l     _d3.L
       clr.l     _d2.L
       clr.l     _d1.L
       clr.l     _d0.L
; a0=a1=a2=a3=a4=a5=a6=0 ;
       clr.l     _a6.L
       clr.l     _a5.L
       clr.l     _a4.L
       clr.l     _a3.L
       clr.l     _a2.L
       clr.l     _a1.L
       clr.l     _a0.L
; PC = ProgramStart, SSP=TopOfStack, USP = TopOfStack;
       move.l    #134217728,_PC.L
       move.l    #201326592,_SSP.L
       move.l    #201326592,_USP.L
; SR = 0x2000;                            // clear interrupts enable tracing  uses IRQ6
       move.w    #8192,_SR.L
; // Initialise Breakpoint variables
; for(i = 0; i < 8; i++)  {
       clr.l     D2
main_1:
       cmp.l     #8,D2
       bge       main_3
; BreakPointAddress[i] = 0;               //array of 8 breakpoint addresses
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; WatchPointAddress[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointInstruction[i] = 0;           // to hold the instruction at the break point
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0;          // indicates if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; WatchPointSetOrCleared[i] = 0;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
       addq.l    #1,D2
       bra       main_1
main_3:
; }
; Init_RS232() ;     // initialise the RS232 port
       jsr       _Init_RS232
; Init_LCD() ;
       jsr       _Init_LCD
; for( i = 32; i < 48; i++)
       moveq     #32,D2
main_4:
       cmp.l     #48,D2
       bge.s     main_6
; InstallExceptionHandler(UnhandledTrap, i) ;		        // install Trap exception handler on vector 32-47
       move.l    D2,-(A7)
       pea       _UnhandledTrap.L
       jsr       (A2)
       addq.w    #8,A7
       addq.l    #1,D2
       bra       main_4
main_6:
; InstallExceptionHandler(menu, 47) ;		                   // TRAP #15 call debug and end program
       pea       47
       pea       _menu.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ1, 25) ;		      // install handler for interrupts
       pea       25
       pea       _UnhandledIRQ1.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ2, 26) ;		      // install handler for interrupts
       pea       26
       pea       _UnhandledIRQ2.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ3, 27) ;		      // install handler for interrupts
       pea       27
       pea       _UnhandledIRQ3.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ4, 28) ;		      // install handler for interrupts
       pea       28
       pea       _UnhandledIRQ4.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ5, 29) ;		      // install handler for interrupts
       pea       29
       pea       _UnhandledIRQ5.L
       jsr       (A2)
       addq.w    #8,A7
; //InstallExceptionHandler(UnhandledIRQ6, 30) ;		      // install handler for interrupts
; InstallExceptionHandler(UnhandledIRQ7, 31) ;		      // install handler for interrupts
       pea       31
       pea       _UnhandledIRQ7.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(clock, 30);
       pea       30
       pea       _clock.L
       jsr       (A2)
       addq.w    #8,A7
; Timer2Data = 0x03;
       move.b    #3,4194356
; Timer2Control = 3;
       move.b    #3,4194358
; InstallExceptionHandler(HandleBreakPoint, 46) ;		           // install Trap 14 Break Point exception handler on vector 46
       pea       46
       pea       _HandleBreakPoint.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(DumpRegistersandPause, 29) ;		   // install TRACE handler for IRQ5 on vector 29
       pea       29
       pea       _DumpRegistersandPause.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(BusError,2) ;                          // install Bus error handler
       pea       2
       pea       _BusError.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(AddressError,3) ;                      // install address error handler (doesn't work on soft core 68k implementation)
       pea       3
       pea       _AddressError.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(IllegalInstruction,4) ;                // install illegal instruction exception handler
       pea       4
       pea       _IllegalInstruction.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Dividebyzero,5) ;                      // install /0 exception handler
       pea       5
       pea       _Dividebyzero.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Check,6) ;                             // install check instruction exception handler
       pea       6
       pea       _Check.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Trapv,7) ;                             // install trapv instruction exception handler
       pea       7
       pea       _Trapv.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(PrivError,8) ;                         // install Priv Violation exception handler
       pea       8
       pea       _PrivError.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnitIRQ,15) ;                          // install uninitialised IRQ exception handler
       pea       15
       pea       _UnitIRQ.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Check,24) ;                            // install spurious IRQ exception handler
       pea       24
       pea       _Check.L
       jsr       (A2)
       addq.w    #8,A7
; FlushKeyboard() ;                        // dump unread characters from keyboard
       jsr       _FlushKeyboard
; TraceException = 0 ;                     // clear trace exception port to remove any software generated single step/trace
       clr.b     4194314
; // otherwise start the debug monitor
; gotoxy(NUM_VGA_COLUMNS/2, NUM_VGA_ROWS/2);
       pea       20
       pea       40
       jsr       _gotoxy
       addq.w    #8,A7
; set_vga_control_reg(0xf2);
       pea       242
       jsr       _set_vga_control_reg
       addq.w    #4,A7
; Oline0(BugMessage) ;
       move.l    D3,-(A7)
       jsr       _Oline0
       addq.w    #4,A7
; Oline1("By: PJ Davies") ;
       pea       @m68kde~1_117.L
       jsr       _Oline1
       addq.w    #4,A7
; printf("\r\n%s", BugMessage) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_118.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\n%s", CopyrightMessage) ;
       move.l    -4(A6),-(A7)
       pea       @m68kde~1_118.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\nStudent Name: Shidi Xi") ;
       pea       @m68kde~1_119.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nStudent Number: 90506643");
       pea       @m68kde~1_120.L
       jsr       (A3)
       addq.w    #4,A7
; menu();
       jsr       _menu
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
       section   const
@m68kde~1_1:
       dc.b      13,10,0
@m68kde~1_2:
       dc.b      13,83,119,105,116,99,104,101,115,32,83,87,91
       dc.b      55,45,48,93,32,61,32,0
@m68kde~1_3:
       dc.b      48,0
@m68kde~1_4:
       dc.b      49,0
@m68kde~1_5:
       dc.b      13,10,68,117,109,112,32,77,101,109,111,114,121
       dc.b      32,66,108,111,99,107,58,32,60,69,83,67,62,32
       dc.b      116,111,32,65,98,111,114,116,44,32,60,83,80
       dc.b      65,67,69,62,32,116,111,32,67,111,110,116,105
       dc.b      110,117,101,0
@m68kde~1_6:
       dc.b      13,10,69,110,116,101,114,32,83,116,97,114,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_7:
       dc.b      13,10,37,48,56,120,32,0
@m68kde~1_8:
       dc.b      37,48,50,88,0
@m68kde~1_9:
       dc.b      32,32,0
@m68kde~1_10:
       dc.b      13,10,70,105,108,108,32,77,101,109,111,114,121
       dc.b      32,66,108,111,99,107,0
@m68kde~1_11:
       dc.b      13,10,69,110,116,101,114,32,69,110,100,32,65
       dc.b      100,100,114,101,115,115,58,32,0
@m68kde~1_12:
       dc.b      13,10,69,110,116,101,114,32,70,105,108,108,32
       dc.b      68,97,116,97,58,32,0
@m68kde~1_13:
       dc.b      13,10,70,105,108,108,105,110,103,32,65,100,100
       dc.b      114,101,115,115,101,115,32,91,36,37,48,56,88
       dc.b      32,45,32,36,37,48,56,88,93,32,119,105,116,104
       dc.b      32,36,37,48,50,88,0
@m68kde~1_14:
       dc.b      13,10,85,115,101,32,72,121,112,101,114,84,101
       dc.b      114,109,105,110,97,108,32,116,111,32,83,101
       dc.b      110,100,32,84,101,120,116,32,70,105,108,101
       dc.b      32,40,46,104,101,120,41,13,10,0
@m68kde~1_15:
       dc.b      13,10,76,111,97,100,32,70,97,105,108,101,100
       dc.b      32,97,116,32,65,100,100,114,101,115,115,32,61
       dc.b      32,91,36,37,48,56,88,93,13,10,0
@m68kde~1_16:
       dc.b      13,10,83,117,99,99,101,115,115,58,32,68,111
       dc.b      119,110,108,111,97,100,101,100,32,37,100,32
       dc.b      98,121,116,101,115,13,10,0
@m68kde~1_17:
       dc.b      13,10,69,120,97,109,105,110,101,32,97,110,100
       dc.b      32,67,104,97,110,103,101,32,77,101,109,111,114
       dc.b      121,0
@m68kde~1_18:
       dc.b      13,10,60,69,83,67,62,32,116,111,32,83,116,111
       dc.b      112,44,32,60,83,80,65,67,69,62,32,116,111,32
       dc.b      65,100,118,97,110,99,101,44,32,39,45,39,32,116
       dc.b      111,32,71,111,32,66,97,99,107,44,32,60,68,65
       dc.b      84,65,62,32,116,111,32,99,104,97,110,103,101
       dc.b      0
@m68kde~1_19:
       dc.b      13,10,69,110,116,101,114,32,65,100,100,114,101
       dc.b      115,115,58,32,0
@m68kde~1_20:
       dc.b      13,10,91,37,48,56,120,93,32,58,32,37,48,50,120
       dc.b      32,32,0
@m68kde~1_21:
       dc.b      13,10,87,97,114,110,105,110,103,32,67,104,97
       dc.b      110,103,101,32,70,97,105,108,101,100,58,32,87
       dc.b      114,111,116,101,32,91,37,48,50,120,93,44,32
       dc.b      82,101,97,100,32,91,37,48,50,120,93,0
@m68kde~1_22:
       dc.b      36,37,48,56,88,32,32,0
@m68kde~1_23:
       dc.b      32,0
@m68kde~1_24:
       dc.b      46,0
@m68kde~1_25:
       dc.b      37,99,0
@m68kde~1_26:
       dc.b      0
@m68kde~1_27:
       dc.b      13,10,13,10,32,68,48,32,61,32,36,37,48,56,88
       dc.b      32,32,65,48,32,61,32,36,37,48,56,88,0
@m68kde~1_28:
       dc.b      13,10,32,68,49,32,61,32,36,37,48,56,88,32,32
       dc.b      65,49,32,61,32,36,37,48,56,88,0
@m68kde~1_29:
       dc.b      13,10,32,68,50,32,61,32,36,37,48,56,88,32,32
       dc.b      65,50,32,61,32,36,37,48,56,88,0
@m68kde~1_30:
       dc.b      13,10,32,68,51,32,61,32,36,37,48,56,88,32,32
       dc.b      65,51,32,61,32,36,37,48,56,88,0
@m68kde~1_31:
       dc.b      13,10,32,68,52,32,61,32,36,37,48,56,88,32,32
       dc.b      65,52,32,61,32,36,37,48,56,88,0
@m68kde~1_32:
       dc.b      13,10,32,68,53,32,61,32,36,37,48,56,88,32,32
       dc.b      65,53,32,61,32,36,37,48,56,88,0
@m68kde~1_33:
       dc.b      13,10,32,68,54,32,61,32,36,37,48,56,88,32,32
       dc.b      65,54,32,61,32,36,37,48,56,88,0
@m68kde~1_34:
       dc.b      13,10,32,68,55,32,61,32,36,37,48,56,88,32,32
       dc.b      65,55,32,61,32,36,37,48,56,88,0
@m68kde~1_35:
       dc.b      13,10,13,10,85,83,80,32,61,32,36,37,48,56,88
       dc.b      32,32,40,65,55,41,32,85,115,101,114,32,83,80
       dc.b      0
@m68kde~1_36:
       dc.b      13,10,83,83,80,32,61,32,36,37,48,56,88,32,32
       dc.b      40,65,55,41,32,83,117,112,101,114,118,105,115
       dc.b      111,114,32,83,80,0
@m68kde~1_37:
       dc.b      13,10,32,83,82,32,61,32,36,37,48,52,88,32,32
       dc.b      32,0
@m68kde~1_38:
       dc.b      32,32,32,91,0
@m68kde~1_39:
       dc.b      13,10,32,80,67,32,61,32,36,37,48,56,88,32,32
       dc.b      0
@m68kde~1_40:
       dc.b      91,64,32,66,82,69,65,75,80,79,73,78,84,93,0
@m68kde~1_41:
       dc.b      13,10,87,80,37,100,32,61,32,37,115,0
@m68kde~1_42:
       dc.b      13,10,13,10,13,10,13,10,13,10,13,10,83,105,110
       dc.b      103,108,101,32,83,116,101,112,32,32,58,91,79
       dc.b      78,93,0
@m68kde~1_43:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      115,32,58,91,68,105,115,97,98,108,101,100,93
       dc.b      0
@m68kde~1_44:
       dc.b      13,10,80,114,101,115,115,32,60,83,80,65,67,69
       dc.b      62,32,116,111,32,69,120,101,99,117,116,101,32
       dc.b      78,101,120,116,32,73,110,115,116,114,117,99
       dc.b      116,105,111,110,0
@m68kde~1_45:
       dc.b      13,10,80,114,101,115,115,32,60,69,83,67,62,32
       dc.b      116,111,32,82,101,115,117,109,101,32,80,114
       dc.b      111,103,114,97,109,0
@m68kde~1_46:
       dc.b      13,10,73,108,108,101,103,97,108,32,68,97,116
       dc.b      97,32,82,101,103,105,115,116,101,114,32,58,32
       dc.b      85,115,101,32,68,48,45,68,55,46,46,46,46,46
       dc.b      13,10,0
@m68kde~1_47:
       dc.b      13,10,68,37,99,32,61,32,0
@m68kde~1_48:
       dc.b      13,10,73,108,108,101,103,97,108,32,65,100,100
       dc.b      114,101,115,115,32,82,101,103,105,115,116,101
       dc.b      114,32,58,32,85,115,101,32,65,48,45,65,55,46
       dc.b      46,46,46,46,13,10,0
@m68kde~1_49:
       dc.b      13,10,65,37,99,32,61,32,0
@m68kde~1_50:
       dc.b      13,10,85,115,101,114,32,83,80,32,61,32,0
@m68kde~1_51:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,101,103
       dc.b      105,115,116,101,114,46,46,46,46,0
@m68kde~1_52:
       dc.b      13,10,83,121,115,116,101,109,32,83,80,32,61
       dc.b      32,0
@m68kde~1_53:
       dc.b      13,10,80,67,32,61,32,0
@m68kde~1_54:
       dc.b      13,10,83,82,32,61,32,0
@m68kde~1_55:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,101,103
       dc.b      105,115,116,101,114,58,32,85,115,101,32,65,48
       dc.b      45,65,55,44,32,68,48,45,68,55,44,32,83,83,80
       dc.b      44,32,85,83,80,44,32,80,67,32,111,114,32,83
       dc.b      82,13,10,0
@m68kde~1_56:
       dc.b      13,10,13,10,78,117,109,32,32,32,32,32,65,100
       dc.b      100,114,101,115,115,32,32,32,32,32,32,73,110
       dc.b      115,116,114,117,99,116,105,111,110,0
@m68kde~1_57:
       dc.b      13,10,45,45,45,32,32,32,32,32,45,45,45,45,45
       dc.b      45,45,45,45,32,32,32,32,45,45,45,45,45,45,45
       dc.b      45,45,45,45,0
@m68kde~1_58:
       dc.b      13,10,78,111,32,66,114,101,97,107,80,111,105
       dc.b      110,116,115,32,83,101,116,0
@m68kde~1_59:
       dc.b      13,10,37,51,100,32,32,32,32,32,36,37,48,56,120
       dc.b      0
@m68kde~1_60:
       dc.b      13,10,78,117,109,32,32,32,32,32,65,100,100,114
       dc.b      101,115,115,0
@m68kde~1_61:
       dc.b      13,10,45,45,45,32,32,32,32,32,45,45,45,45,45
       dc.b      45,45,45,45,0
@m68kde~1_62:
       dc.b      13,10,78,111,32,87,97,116,99,104,80,111,105
       dc.b      110,116,115,32,83,101,116,0
@m68kde~1_63:
       dc.b      13,10,69,110,116,101,114,32,66,114,101,97,107
       dc.b      32,80,111,105,110,116,32,78,117,109,98,101,114
       dc.b      58,32,0
@m68kde~1_64:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,97,110
       dc.b      103,101,32,58,32,85,115,101,32,48,32,45,32,55
       dc.b      0
@m68kde~1_65:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,67,108,101,97,114,101,100,46,46,46,46,46
       dc.b      13,10,0
@m68kde~1_66:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,119,97,115,110,39,116,32,83,101,116,46,46
       dc.b      46,46,46,0
@m68kde~1_67:
       dc.b      13,10,69,110,116,101,114,32,87,97,116,99,104
       dc.b      32,80,111,105,110,116,32,78,117,109,98,101,114
       dc.b      58,32,0
@m68kde~1_68:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,67,108,101,97,114,101,100,46,46,46,46,46
       dc.b      13,10,0
@m68kde~1_69:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,87,97,115,32,110,111,116,32,83,101,116,46
       dc.b      46,46,46,46,0
@m68kde~1_70:
       dc.b      13,10,78,111,32,70,82,69,69,32,66,114,101,97
       dc.b      107,32,80,111,105,110,116,115,46,46,46,46,46
       dc.b      0
@m68kde~1_71:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_72:
       dc.b      13,10,69,114,114,111,114,32,58,32,66,114,101
       dc.b      97,107,32,80,111,105,110,116,115,32,67,65,78
       dc.b      78,79,84,32,98,101,32,115,101,116,32,97,116
       dc.b      32,79,68,68,32,97,100,100,114,101,115,115,101
       dc.b      115,0
@m68kde~1_73:
       dc.b      13,10,69,114,114,111,114,32,58,32,66,114,101
       dc.b      97,107,32,80,111,105,110,116,115,32,67,65,78
       dc.b      78,79,84,32,98,101,32,115,101,116,32,102,111
       dc.b      114,32,82,79,77,32,105,110,32,82,97,110,103
       dc.b      101,32,58,32,91,36,48,45,36,48,48,48,48,55,70
       dc.b      70,70,93,0
@m68kde~1_74:
       dc.b      13,10,69,114,114,111,114,58,32,66,114,101,97
       dc.b      107,32,80,111,105,110,116,32,65,108,114,101
       dc.b      97,100,121,32,69,120,105,115,116,115,32,97,116
       dc.b      32,65,100,100,114,101,115,115,32,58,32,37,48
       dc.b      56,120,13,10,0
@m68kde~1_75:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,83,101,116,32,97,116,32,65,100,100,114,101
       dc.b      115,115,58,32,91,36,37,48,56,120,93,0
@m68kde~1_76:
       dc.b      13,10,78,111,32,70,82,69,69,32,87,97,116,99
       dc.b      104,32,80,111,105,110,116,115,46,46,46,46,46
       dc.b      0
@m68kde~1_77:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_78:
       dc.b      13,10,69,114,114,111,114,58,32,87,97,116,99
       dc.b      104,32,80,111,105,110,116,32,65,108,114,101
       dc.b      97,100,121,32,83,101,116,32,97,116,32,65,100
       dc.b      100,114,101,115,115,32,58,32,37,48,56,120,13
       dc.b      10,0
@m68kde~1_79:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,83,101,116,32,97,116,32,65,100,100,114,101
       dc.b      115,115,58,32,91,36,37,48,56,120,93,0
@m68kde~1_80:
       dc.b      13,10,13,10,13,10,13,10,64,66,82,69,65,75,80
       dc.b      79,73,78,84,0
@m68kde~1_81:
       dc.b      13,10,83,105,110,103,108,101,32,83,116,101,112
       dc.b      32,58,32,91,79,78,93,0
@m68kde~1_82:
       dc.b      13,10,66,114,101,97,107,80,111,105,110,116,115
       dc.b      32,58,32,91,69,110,97,98,108,101,100,93,0
@m68kde~1_83:
       dc.b      13,10,80,114,101,115,115,32,60,69,83,67,62,32
       dc.b      116,111,32,82,101,115,117,109,101,32,85,115
       dc.b      101,114,32,80,114,111,103,114,97,109,13,10,0
@m68kde~1_84:
       dc.b      13,10,85,110,107,110,111,119,110,32,67,111,109
       dc.b      109,97,110,100,46,46,46,46,46,13,10,0
@m68kde~1_85:
       dc.b      13,10,80,114,111,103,114,97,109,32,69,110,100
       dc.b      101,100,32,40,84,82,65,80,32,35,49,53,41,46
       dc.b      46,46,46,0
@m68kde~1_86:
       dc.b      13,10,75,105,108,108,32,65,108,108,32,66,114
       dc.b      101,97,107,32,80,111,105,110,116,115,46,46,46
       dc.b      40,121,47,110,41,63,0
@m68kde~1_87:
       dc.b      13,10,75,105,108,108,32,65,108,108,32,87,97
       dc.b      116,99,104,32,80,111,105,110,116,115,46,46,46
       dc.b      40,121,47,110,41,63,0
@m68kde~1_88:
       dc.b      13,10,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,0
@m68kde~1_89:
       dc.b      13,10,32,32,70,105,110,97,108,32,80,114,111
       dc.b      106,101,99,116,0
@m68kde~1_90:
       dc.b      13,10,32,32,71,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,82,117,110,32,83,110,97,107,101
       dc.b      32,71,97,109,101,0
@m68kde~1_91:
       dc.b      13,10,35,0
@m68kde~1_92:
       dc.b      13,10,82,117,110,110,105,110,103,32,83,110,97
       dc.b      107,101,32,71,97,109,101,10,0
@m68kde~1_93:
       dc.b      13,10,13,10,80,114,111,103,114,97,109,32,65
       dc.b      66,79,82,84,32,33,33,33,33,33,33,13,10,0
@m68kde~1_94:
       dc.b      37,115,13,10,0
@m68kde~1_95:
       dc.b      13,10,13,10,80,114,111,103,114,97,109,32,65
       dc.b      66,79,82,84,32,33,33,33,33,33,0
@m68kde~1_96:
       dc.b      13,10,85,110,104,97,110,100,108,101,100,32,73
       dc.b      110,116,101,114,114,117,112,116,58,32,73,82
       dc.b      81,37,100,32,33,33,33,33,33,0
@m68kde~1_97:
       dc.b      65,68,68,82,69,83,83,32,69,82,82,79,82,58,32
       dc.b      49,54,32,111,114,32,51,50,32,66,105,116,32,84
       dc.b      114,97,110,115,102,101,114,32,116,111,47,102
       dc.b      114,111,109,32,97,110,32,79,68,68,32,65,100
       dc.b      100,114,101,115,115,46,46,46,46,0
@m68kde~1_98:
       dc.b      85,110,104,97,110,100,108,101,100,32,84,114
       dc.b      97,112,32,33,33,33,33,33,0
@m68kde~1_99:
       dc.b      66,85,83,32,69,114,114,111,114,33,0
@m68kde~1_100:
       dc.b      65,68,68,82,69,83,83,32,69,114,114,111,114,33
       dc.b      0
@m68kde~1_101:
       dc.b      73,76,76,69,71,65,76,32,73,78,83,84,82,85,67
       dc.b      84,73,79,78,0
@m68kde~1_102:
       dc.b      68,73,86,73,68,69,32,66,89,32,90,69,82,79,0
@m68kde~1_103:
       dc.b      39,67,72,75,39,32,73,78,83,84,82,85,67,84,73
       dc.b      79,78,0
@m68kde~1_104:
       dc.b      84,82,65,80,86,32,73,78,83,84,82,85,67,84,73
       dc.b      79,78,0
@m68kde~1_105:
       dc.b      80,82,73,86,73,76,69,71,69,32,86,73,79,76,65
       dc.b      84,73,79,78,0
@m68kde~1_106:
       dc.b      85,78,73,78,73,84,73,65,76,73,83,69,68,32,73
       dc.b      82,81,0
@m68kde~1_107:
       dc.b      83,80,85,82,73,79,85,83,32,73,82,81,0
@m68kde~1_108:
       dc.b      13,10,83,116,97,114,116,32,65,100,100,114,101
       dc.b      115,115,32,105,110,32,77,101,109,111,114,121
       dc.b      58,32,0
@m68kde~1_109:
       dc.b      13,10,69,110,116,101,114,32,83,116,114,105,110
       dc.b      103,32,40,69,83,67,32,116,111,32,101,110,100
       dc.b      41,32,58,0
@m68kde~1_110:
       dc.b      97,109,101,32,79,118,101,114,33,0
@m68kde~1_111:
       dc.b      83,99,111,114,101,58,32,0
@m68kde~1_112:
       dc.b      13,10,71,97,109,101,32,111,118,101,114,32,33
       dc.b      0
@m68kde~1_113:
       dc.b      13,10,121,111,117,114,32,115,99,111,114,101
       dc.b      32,119,97,115,32,37,100,10,0
@m68kde~1_114:
       dc.b      13,10,112,114,101,115,115,32,97,110,121,32,107
       dc.b      101,121,10,0
@m68kde~1_115:
       dc.b      68,69,49,45,54,56,107,32,66,117,103,32,86,49
       dc.b      46,55,55,0
@m68kde~1_116:
       dc.b      67,111,112,121,114,105,103,104,116,32,40,67
       dc.b      41,32,80,74,32,68,97,118,105,101,115,32,50,48
       dc.b      49,54,0
@m68kde~1_117:
       dc.b      66,121,58,32,80,74,32,68,97,118,105,101,115
       dc.b      0
@m68kde~1_118:
       dc.b      13,10,37,115,0
@m68kde~1_119:
       dc.b      13,10,83,116,117,100,101,110,116,32,78,97,109
       dc.b      101,58,32,83,104,105,100,105,32,88,105,0
@m68kde~1_120:
       dc.b      13,10,83,116,117,100,101,110,116,32,78,117,109
       dc.b      98,101,114,58,32,57,48,53,48,54,54,52,51,0
       xdef      _screensize
_screensize:
       dc.l      80,40
       section   data
generateFood_firsttime:
       dc.l      1
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
       xdef      _Trace
_Trace:
       ds.b      4
       xdef      _GoFlag
_GoFlag:
       ds.b      4
       xdef      _Echo
_Echo:
       ds.b      4
       xdef      _d0
_d0:
       ds.b      4
       xdef      _d1
_d1:
       ds.b      4
       xdef      _d2
_d2:
       ds.b      4
       xdef      _d3
_d3:
       ds.b      4
       xdef      _d4
_d4:
       ds.b      4
       xdef      _d5
_d5:
       ds.b      4
       xdef      _d6
_d6:
       ds.b      4
       xdef      _d7
_d7:
       ds.b      4
       xdef      _a0
_a0:
       ds.b      4
       xdef      _a1
_a1:
       ds.b      4
       xdef      _a2
_a2:
       ds.b      4
       xdef      _a3
_a3:
       ds.b      4
       xdef      _a4
_a4:
       ds.b      4
       xdef      _a5
_a5:
       ds.b      4
       xdef      _a6
_a6:
       ds.b      4
       xdef      _PC
_PC:
       ds.b      4
       xdef      _SSP
_SSP:
       ds.b      4
       xdef      _USP
_USP:
       ds.b      4
       xdef      _SR
_SR:
       ds.b      2
       xdef      _BreakPointAddress
_BreakPointAddress:
       ds.b      32
       xdef      _BreakPointInstruction
_BreakPointInstruction:
       ds.b      16
       xdef      _BreakPointSetOrCleared
_BreakPointSetOrCleared:
       ds.b      32
       xdef      _InstructionSize
_InstructionSize:
       ds.b      4
       xdef      _WatchPointAddress
_WatchPointAddress:
       ds.b      32
       xdef      _WatchPointSetOrCleared
_WatchPointSetOrCleared:
       ds.b      32
       xdef      _WatchPointString
_WatchPointString:
       ds.b      800
       xdef      _TempString
_TempString:
       ds.b      100
       xdef      _score
_score:
       ds.b      4
       xdef      _timer
_timer:
       ds.b      4
       xdef      _clock_counter
_clock_counter:
       ds.b      4
       xdef      _vga_color
_vga_color:
       ds.b      4
       xdef      _Snake
_Snake:
       ds.b      16406
       xdef      _waiting_for_direction_to_be_imp
_waiting_for_direction_to_be_imp:
       ds.b      4
       xref      _strcpy
       xref      LDIV
       xref      LMUL
       xref      _putch
       xref      _getch
       xref      _tolower
       xref      _sprintf
       xref      _strcat
       xref      _toupper
       xref      _printf
