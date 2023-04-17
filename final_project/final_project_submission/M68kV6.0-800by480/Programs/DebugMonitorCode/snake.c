#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include "snake.h"

#define vga_ram_start         (*(volatile unsigned char *)(0x00600000))
#define vga_x_cursor_reg          (*(volatile unsigned char *)(0x00601000))
#define vga_y_cursor_reg            (*(volatile unsigned char *)(0x00601002))
#define vga_ctrl_reg             (*(volatile unsigned char *)(0x00601004))
#define StartOfExceptionVectorTable 0x0B000000
#define Timer2Data      *(volatile unsigned char *)(0x00400034)
#define Timer2Control   *(volatile unsigned char *)(0x00400036)
#define Timer2Status    *(volatile unsigned char *)(0x00400036)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

/**********************************************************************************************
**	LCD display port addresses
**********************************************************************************************/

#define LCDcommand   *(volatile unsigned char *)(0x00400020)
#define LCDdata      *(volatile unsigned char *)(0x00400022)

int score;
int timer;
unsigned int clock_counter;

struct
{
    coord_t xy[SNAKE_LENGTH_LIMIT];
    int length;
    dir_t direction;
    int speed;
    int speed_increase;
    coord_t food;
} Snake;

const coord_t screensize = {NUM_VGA_COLUMNS,NUM_VGA_ROWS};

int waiting_for_direction_to_be_implemented;

/*********************************************************************************************************************************
**  IMPORTANT FUNCTION
**  This function install an exception handler so you can capture and deal with any 68000 exception in your program
**  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
**  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
**  Calling this function allows you to deal with Interrupts for example
***********************************************************************************************************************************/

void InstallExceptionHandler( void (*function_ptr)(), int level)
{
    volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor

    RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
}

/************************************************************************************
**   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
************************************************************************************/
void Wait1ms(void)
{
    int  i ;
    for(i = 0; i < 1000; i ++)
        ;
}

/************************************************************************************
**  Subroutine to give the 68000 something useless to do to waste 3 mSec
**************************************************************************************/
void Wait3ms(void)
{
    int i ;
    for(i = 0; i < 3; i++)
        Wait1ms() ;
}

void Wait500ms (void) {
    int i;
    for (i = 0; i<500; i++){
        Wait1ms();
    }
}

/*********************************************************************************************
**  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
**  Sets it for parallel port and 2 line display mode (if I recall correctly)
*********************************************************************************************/
void Init_LCD(void)
{
    LCDcommand = 0x0c ;
    Wait3ms() ;
    LCDcommand = 0x38 ;
    Wait3ms() ;
}

/*********************************************************************************************
**  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
    RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

int kbhit(void)
{
    if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // wait for Rx bit in status register to be '1'
        return 1 ;
    else
        return 0 ;
}

/*********************************************************************************************************
**  Subroutine to provide a low level output function to 6850 ACIA
**  This routine provides the basic functionality to output a single character to the serial Port
**  to allow the board to communicate with HyperTerminal Program
**
**  NOTE you do not call this function directly, instead you call the normal putchar() function
**  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
**  call _putch() also
*********************************************************************************************************/

int _putch( int c)
{
    while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
        ;

    RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
    return c ;                                              // putchar() expects the character to be returned
}

/*********************************************************************************************************
**  Subroutine to provide a low level input function to 6850 ACIA
**  This routine provides the basic functionality to input a single character from the serial Port
**  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
**
**  NOTE you do not call this function directly, instead you call the normal getchar() function
**  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
**  call _getch() also
*********************************************************************************************************/
int _getch( void )
{
    char c ;
    while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;
    c = (RS232_RxData & (char)(0x7f));
    
    _putch(c);

    return c;                   // read received character, mask off top bit and return as 7 bit ASCII character
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//                        functions to implement
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////

void putcharxy(int x, int y, char ch) {
	//display on the VGA char ch at column x, line y
    volatile unsigned char* addr;
    addr = &vga_ram_start + NUM_VGA_COLUMNS*y + x;
    *addr = ch;

}

void print_at_xy(int x,
    int y,
	const char* str) {
    //print a string on the VGA, starting at column x, line y. 
    //Wrap around to the next line if we reach the edge of the screen

    int end_of_str = 0;
    int i = 0;
    int x_coord = x;
    int y_coord = y;

    while (!end_of_str)
    {
        if (*(str+i) != '\0')
        {   
            if (x_coord > NUM_VGA_COLUMNS-1) { //Wrap around to the next line if we reach the edge of the screen
                x_coord = 0;
                y_coord++;
            }
            if (y_coord > NUM_VGA_ROWS-1) {
                y_coord = 0;
            }
            putcharxy(x_coord,y_coord, *(str+i));
            x_coord++;
        }
        else
        {
            end_of_str = 1;
        }
        i++;
    }
}

void cls()
{
	//clear the screen
    int x;
    int y;
    char space = 0x20;
    for (y=0; y<NUM_VGA_ROWS; y++) {
        for (x=0; x<NUM_VGA_COLUMNS; x++) {
            putcharxy(x,y,space);
        }
    }
};

void gotoxy(int x, int y)
{
	//move the cursor to location column = x, row = y
    vga_x_cursor_reg = x;
    vga_y_cursor_reg = y;
};

void set_vga_control_reg(char x) {
	//Set the VGA control (OCTL) value
    vga_ctrl_reg = x;
}


char get_vga_control_reg() {
	//return the VGA control (OCTL) value
    char value;
    value = vga_ctrl_reg;
    return value;
}

int clock() {
	//return the current value of a milliseconds counter, with a resolution of 10ms or better
    if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
        clock_counter = clock_counter +10;
        Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	}
    return clock_counter;
}

void delay_ms(int num_ms) {
	//delay a certain number of milliseconds
    int initial_time;
    initial_time = clock();
    while ((clock() - initial_time) < num_ms) {}
}

void string_cursor(int x,
    int y,
	const char* str)
{
    int end_of_str = 0;
    int i = 0;
    int x_coord = x;
    int y_coord = y;

    while (!end_of_str)
    {
        if (*(str+i) != '\0')
        {   
            if (x_coord > NUM_VGA_COLUMNS-1) { //Wrap around to the next line if we reach the edge of the screen
                x_coord = 0;
                y_coord++;
            }
            if (y_coord > NUM_VGA_ROWS-1) {
                y_coord = 0;
            }
            putcharxy(x_coord,y_coord, *(str+i));
            delay_ms(100);
            gotoxy(x_coord,y_coord);
            delay_ms(100);
            x_coord++;
        }
        else
        {
            end_of_str = 1;
        }
        i++;
    }
    gotoxy(x_coord,y_coord);
    delay_ms(100);
    gotoxy(x_coord+1,y_coord);
}

void int_to_str (char* str, int num)
{   
    int i = 0, j, sign;

    // handle negative numbers
    if (num < 0) {
        sign = -1;
        num = -num;
    }
    else {
        sign = 1;
    }

    // convert each digit of the number to a character and store in the buffer
    do {
        str[i++] = num % 10 + '0';
    } while ((num /= 10) > 0);

    // add the negative sign if necessary
    if (sign == -1) {
        str[i++] = '-';
    }

    // reverse the string
    for (j = 0; j < i / 2; j++) {
        char temp = str[j];
        str[j] = str[i - j - 1];
        str[i - j - 1] = temp;
    }

    // add null terminator to the end of the string
    str[i] = '\0';
}

void gameOver()
{
    //show game over screen and animation
    char score_str[20];
    unsigned int color = 2;
    int_to_str(score_str, score);
    cls();
    gotoxy(35,18);
    set_vga_control_reg(0xe2);
    delay_ms(500);
    putcharxy(35,18,'G');
    delay_ms(100);
    string_cursor(36,18, "ame Over!");
    string_cursor(35,20, "Score: ");
    string_cursor(42,20, score_str);
    //gotoxy(45,20);
    
    while (1)
    {   
        delay_ms(1500);
        color = (color+1) & 7; // extract the color bits
        if (color == 0)
        {
            color = 1;
        }
        set_vga_control_reg((0xe0 | color));
    }
}

void updateScore()
{
	//print the score at the bottom of the screen
    char score_str[20];
    int_to_str(score_str, score);
    print_at_xy(0,NUM_VGA_ROWS-1, "Score: ");
    print_at_xy(7,NUM_VGA_ROWS-1, score_str);
}
void drawRect(int x, int y, int x2, int y2, char ch)
{
    //draws a rectangle. Left top corner: (x1,y1) length of sides = x2,y2
    int x_pos,y_pos;
    // draw horizontal edges
    for (x_pos = x; x_pos < x+x2; x_pos++)
    {
        putcharxy(x_pos,y,ch);
        putcharxy(x_pos,y+y2-1,ch);
    }
    // draw vertial edges
    for (y_pos = y; y_pos < y+y2-1; y_pos++)
    {
        putcharxy(x,y_pos,ch);
        putcharxy(x+x2-1,y_pos,ch);
    }
}

void initSnake()
{
    Snake.speed          = INITIAL_SNAKE_SPEED ;         
    Snake.speed_increase = SNAKE_SPEED_INCREASE;
}

void drawSnake()
{
    int i;
    for(i = 0; i < Snake.length; i++)
    {
       	putcharxy(Snake.xy[i].x, Snake.xy[i].y,SNAKE);
    }

}

void drawFood()
{
    putcharxy(Snake.food.x, Snake.food.y,FOOD);
}

void moveSnake()//remove tail, move array, add new head based on direction
{
int i;
int x;
int y;
    x = Snake.xy[0].x;
    y = Snake.xy[0].y;
    //saves initial head for direction determination

    putcharxy(Snake.xy[Snake.length-1].x, Snake.xy[Snake.length-1].y,' ');

    for(i = Snake.length; i > 1; i--)
    {
        Snake.xy[i-1] = Snake.xy[i-2];
    }
    //moves the snake array to the right

    switch (Snake.direction)
    {
        case north:
            if (y > 0)  { y--; }
            break;
        case south:
            if (y < (NUM_VGA_ROWS-1)) { y++; }
            break;
        case west:
            if (x > 0) { x--; }
            break;
        case east:
            if (x < (NUM_VGA_COLUMNS-1))  { x++; }
            break;
        default:
            break;
    }
    //adds new snake head
    Snake.xy[0].x = x;
    Snake.xy[0].y = y;

    waiting_for_direction_to_be_implemented = 0;
    putcharxy(Snake.xy[0].x,Snake.xy[0].y,SNAKE);
}

/* Compute x mod y using binary long division. */
int mod_bld(int x, int y)
{
    int modulus = x, divisor = y;

    while (divisor <= modulus && divisor <= 16384)
        divisor <<= 1;

    while (modulus >= y) {
        while (divisor > modulus)
            divisor >>= 1;
        modulus -= divisor;
    }

    return modulus;
}

void generateFood()
{
    int bol;
    int i;
	static int firsttime = 1;

	//removes last food
    if (!firsttime) {
         putcharxy(Snake.food.x,Snake.food.y,' ');
	} else {
	     firsttime = 0;
	}

    do
    {
        bol = 0;
		
		//pseudo-randomly set food location
		//use clock instead of random function that is
		//not implemented in ide68k
		
        Snake.food.x = 3+ mod_bld(((clock()& 0xFFF0) >> 4),screensize.x-6); 
        Snake.food.y = 3+ mod_bld(clock()& 0xFFFF,screensize.y-6); 
        for(i = 0; i < Snake.length; i++)
        {
            if (Snake.food.x == Snake.xy[i].x && Snake.food.y == Snake.xy[i].y) {
                bol = 1; //resets loop if collision detected
            }

        }

    } while (bol);//while colliding with snake
    drawFood();

}

int getKeypress()
{
    if (kbhit()) {
        switch (_getch())
        {
            case 'w':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != south)){
				Snake.direction = north;
				waiting_for_direction_to_be_implemented = 1;
				}
                break;
            case 's':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != north)){
				Snake.direction = south;
				waiting_for_direction_to_be_implemented = 1;
				}
                break;
            case 'a':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != east)){
				Snake.direction = west;
				waiting_for_direction_to_be_implemented = 1;
                }
                break;
            case 'd':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != west)){
				 Snake.direction = east;
				 waiting_for_direction_to_be_implemented = 1;
                }
                break;
            case 'p':
                _getch();
                break;
            case 'q':
                gameOver();
                return 0;
            default:
                //do nothing
                break;
        }
    }
    return 1;
}

int detectCollision()//with self -> game over, food -> delete food add score (only head checks)
                     // returns 0 for no collision, 1 for game over
{
    int i;
	int retval;
	retval = 0;
    if (Snake.xy[0].x == Snake.food.x && Snake.xy[0].y == Snake.food.y) {
	    //detect collision with food
        Snake.length++;
		Snake.xy[Snake.length-1].x = Snake.xy[Snake.length-2].x;
		Snake.xy[Snake.length-1].y = Snake.xy[Snake.length-2].y;
        Snake.speed = Snake.speed + Snake.speed_increase;
        generateFood();
        score++;
        updateScore();
    }

    for(i = 2; i < Snake.length; i++)
    {
	    //detects collision of the head
        if (Snake.xy[i].x == Snake.xy[0].x && Snake.xy[i].y == Snake.xy[0].y) {
            gameOver();
			retval = 1;
        }

    }

    if (Snake.xy[0].x == 1 || Snake.xy[0].x == (screensize.x-1) || Snake.xy[0].y == 1 || Snake.xy[0].y == (screensize.y-2)) {
	    //collision with wall
        gameOver();
		retval = 1;
    }
	return retval;
}



void mainloop()
{
	int current_time;
	int got_game_over;
    while(1){
        if (!getKeypress()) {
          return;
        }
		current_time = clock();
        //printf("\r\nCurrent time: %d",current_time);

        if (current_time >= ((MILLISECONDS_PER_SEC/Snake.speed) + timer)) {
            moveSnake(); //draws new snake position
            got_game_over = detectCollision();
			if (got_game_over) {
			   break;
			}

            timer = current_time;
        }

    }
}

void snake_main()
{   
    clock_counter = 0;
	score = 0;
	waiting_for_direction_to_be_implemented = 0;
   	Snake.xy[0].x = 4;
    Snake.xy[0].y = 3;
    Snake.xy[1].x = 3;
    Snake.xy[1].y = 3;
    Snake.xy[2].x = 2;
    Snake.xy[2].y = 3;
    Snake.length = INITIAL_SNAKE_LENGTH;
    Snake.direction = east;
    initSnake();
	cls();
    drawRect(1,1,screensize.x-1,screensize.y-2, BORDER);
    drawSnake();
    generateFood();
    drawFood();
    timer = clock();
	updateScore();
    mainloop();
}

void main ()
{   
    InstallExceptionHandler(clock, 30);
    Timer2Data = 0x03;
    Timer2Control = 3;
    Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
    Init_RS232() ;          // initialise the RS232 port for use with hyper terminal

    set_vga_control_reg(0x82);
    snake_main();
}