; C:\M68KV6.0-800BY480\PROGRAMS\DEBUGMONITORCODE\SNAKE.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <stdlib.h>
; #include <limits.h>
; #include "snake.h"
; #define vga_ram_start         (*(volatile unsigned char *)(0x00600000))
; #define vga_x_cursor_reg          (*(volatile unsigned char *)(0x00601000))
; #define vga_y_cursor_reg            (*(volatile unsigned char *)(0x00601002))
; #define vga_ctrl_reg             (*(volatile unsigned char *)(0x00601004))
; #define StartOfExceptionVectorTable 0x0B000000
; #define Timer2Data      *(volatile unsigned char *)(0x00400034)
; #define Timer2Control   *(volatile unsigned char *)(0x00400036)
; #define Timer2Status    *(volatile unsigned char *)(0x00400036)
; /*********************************************************************************************
; **	RS232 port addresses
; *********************************************************************************************/
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; /**********************************************************************************************
; **	LCD display port addresses
; **********************************************************************************************/
; #define LCDcommand   *(volatile unsigned char *)(0x00400020)
; #define LCDdata      *(volatile unsigned char *)(0x00400022)
; int score;
; int timer;
; unsigned int clock_counter;
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
; /*********************************************************************************************************************************
; **  IMPORTANT FUNCTION
; **  This function install an exception handler so you can capture and deal with any 68000 exception in your program
; **  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
; **  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
; **  Calling this function allows you to deal with Interrupts for example
; ***********************************************************************************************************************************/
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       section   code
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
; /////////////////////////////////////////////////////////////////////////////////////////////////////
; //
; //
; //                        functions to implement
; //
; //
; /////////////////////////////////////////////////////////////////////////////////////////////////////
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
; clock_counter = clock_counter +10;
       add.l     #10,_clock_counter.L
; Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194358
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
       lea       _string_cursor.L,A2
       lea       _delay_ms.L,A3
; //show game over screen and animation
; char score_str[20];
; unsigned int color = 2;
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
; delay_ms(500);
       pea       500
       jsr       (A3)
       addq.w    #4,A7
; putcharxy(35,18,'G');
       pea       71
       pea       18
       pea       35
       jsr       _putcharxy
       add.w     #12,A7
; delay_ms(100);
       pea       100
       jsr       (A3)
       addq.w    #4,A7
; string_cursor(36,18, "ame Over!");
       pea       @snake_1.L
       pea       18
       pea       36
       jsr       (A2)
       add.w     #12,A7
; string_cursor(35,20, "Score: ");
       pea       @snake_2.L
       pea       20
       pea       35
       jsr       (A2)
       add.w     #12,A7
; string_cursor(42,20, score_str);
       pea       -20(A6)
       pea       20
       pea       42
       jsr       (A2)
       add.w     #12,A7
; //gotoxy(45,20);
; while (1)
gameOver_1:
; {   
; delay_ms(1500);
       pea       1500
       jsr       (A3)
       addq.w    #4,A7
; color = (color+1) & 7; // extract the color bits
       move.l    D2,D0
       addq.l    #1,D0
       and.l     #7,D0
       move.l    D0,D2
; if (color == 0)
       tst.l     D2
       bne.s     gameOver_4
; {
; color = 1;
       moveq     #1,D2
gameOver_4:
; }
; set_vga_control_reg((0xe0 | color));
       move.w    #224,D1
       ext.l     D1
       or.l      D2,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _set_vga_control_reg
       addq.w    #4,A7
       bra       gameOver_1
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
; print_at_xy(0,NUM_VGA_ROWS-1, "Score: ");
       pea       @snake_2.L
       pea       39
       clr.l     -(A7)
       jsr       _print_at_xy
       add.w     #12,A7
; print_at_xy(7,NUM_VGA_ROWS-1, score_str);
       pea       -20(A6)
       pea       39
       pea       7
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
; if (!getKeypress()) {
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
; void main ()
; {   
       xdef      _main
_main:
; InstallExceptionHandler(clock, 30);
       pea       30
       pea       _clock.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; Timer2Data = 0x03;
       move.b    #3,4194356
; Timer2Control = 3;
       move.b    #3,4194358
; Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
       jsr       _Init_LCD
; Init_RS232() ;          // initialise the RS232 port for use with hyper terminal
       jsr       _Init_RS232
; set_vga_control_reg(0x82);
       pea       130
       jsr       _set_vga_control_reg
       addq.w    #4,A7
; snake_main();
       jsr       _snake_main
       rts
; }
       section   const
@snake_1:
       dc.b      97,109,101,32,79,118,101,114,33,0
@snake_2:
       dc.b      83,99,111,114,101,58,32,0
       xdef      _screensize
_screensize:
       dc.l      80,40
       section   data
generateFood_firsttime:
       dc.l      1
       section   bss
       xdef      _score
_score:
       ds.b      4
       xdef      _timer
_timer:
       ds.b      4
       xdef      _clock_counter
_clock_counter:
       ds.b      4
       xdef      _Snake
_Snake:
       ds.b      16406
       xdef      _waiting_for_direction_to_be_imp
_waiting_for_direction_to_be_imp:
       ds.b      4
       xref      LDIV
       xref      LMUL
