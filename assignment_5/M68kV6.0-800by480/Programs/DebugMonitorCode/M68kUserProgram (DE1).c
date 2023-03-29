#include <stdio.h>
#include <string.h>
#include <ctype.h>


//IMPORTANT
//
// Uncomment one of the two #defines below
// Define StartOfExceptionVectorTable as 08030000 if running programs from sram or
// 0B000000 for running programs from dram
//
// In your labs, you will initially start by designing a system with SRam and later move to
// Dram, so these constants will need to be changed based on the version of the system you have
// building
//
// The working 68k system SOF file posted on canvas that you can use for your pre-lab
// is based around Dram so #define accordingly before building

//SRAM
//#define StartOfExceptionVectorTable 0x08030000
//DRAM
#define StartOfExceptionVectorTable 0x0B000000

/**********************************************************************************************
**	Parallel port addresses
**********************************************************************************************/

#define PortA   *(volatile unsigned char *)(0x00400000)
#define PortB   *(volatile unsigned char *)(0x00400002)
#define PortC   *(volatile unsigned char *)(0x00400004)
#define PortD   *(volatile unsigned char *)(0x00400006)
#define PortE   *(volatile unsigned char *)(0x00400008)

/*********************************************************************************************
**	Hex 7 seg displays port addresses
*********************************************************************************************/

#define HEX_A        *(volatile unsigned char *)(0x00400010)
#define HEX_B        *(volatile unsigned char *)(0x00400012)
#define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
#define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only

/**********************************************************************************************
**	LCD display port addresses
**********************************************************************************************/

#define LCDcommand   *(volatile unsigned char *)(0x00400020)
#define LCDdata      *(volatile unsigned char *)(0x00400022)

/********************************************************************************************
**	Timer Port addresses
*********************************************************************************************/

#define Timer1Data      *(volatile unsigned char *)(0x00400030)
#define Timer1Control   *(volatile unsigned char *)(0x00400032)
#define Timer1Status    *(volatile unsigned char *)(0x00400032)

#define Timer2Data      *(volatile unsigned char *)(0x00400034)
#define Timer2Control   *(volatile unsigned char *)(0x00400036)
#define Timer2Status    *(volatile unsigned char *)(0x00400036)

#define Timer3Data      *(volatile unsigned char *)(0x00400038)
#define Timer3Control   *(volatile unsigned char *)(0x0040003A)
#define Timer3Status    *(volatile unsigned char *)(0x0040003A)

#define Timer4Data      *(volatile unsigned char *)(0x0040003C)
#define Timer4Control   *(volatile unsigned char *)(0x0040003E)
#define Timer4Status    *(volatile unsigned char *)(0x0040003E)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

/*********************************************************************************************
**	PIA 1 and 2 port addresses
*********************************************************************************************/

#define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
#define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
#define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
#define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)

#define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
#define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
#define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
#define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)

/*******************************************************************************************
** I2C address and common commands
*******************************************************************************************/

#define I2C_prescale_reg_L *(volatile unsigned char *) (0x00408000)
#define I2C_prescale_reg_H *(volatile unsigned char *) (0x00408002)
#define I2C_control_reg  *(volatile unsigned char *) (0x00408004)
#define I2C_TX_reg  *(volatile unsigned char *) (0x00408006)
#define I2C_RX_reg  *(volatile unsigned char *) (0x00408006)
#define I2C_command_reg  *(volatile unsigned char *) (0x00408008)
#define I2C_status_reg  *(volatile unsigned char *) (0x00408008)
#define start_write_cmd_I2C (char) (0x91)          // generate start signal and enable write, clear any pending interrupt
#define write_cmd_I2C (char) (0x11)            // send TX byte without generating a start signal
#define stop_write_cmd_I2C (char) (0x51)
#define stop_read_NACK_cmd_I2C (char) (0x69)
#define read_ACK_cmd_I2C (char) (0x21)

/*********************************************************************************************************************************
 * 
 * 
(( DO NOT initialise global variables here, do it main even if you want 0
(( it's a limitation of the compiler
(( YOU HAVE BEEN WARNED
*********************************************************************************************************************************/

unsigned int i, x, y, z, PortA_Count;
unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;

/*******************************************************************************************
** Function Prototypes
*******************************************************************************************/
int _getch( void );
char xtod(int c);
int Get1HexDigits(char *CheckSumPtr);
int Get2HexDigits(char *CheckSumPtr);
int Get4HexDigits(char *CheckSumPtr);
int Get6HexDigits(char *CheckSumPtr);
void Wait1ms(void);
void Wait3ms(void);
void Wait500ms (void);
void Init_LCD(void) ;
void LCDOutchar(int c);
void LCDOutMess(char *theMessage);
void LCDClearln(void);
void LCDline1Message(char *theMessage);
void LCDline2Message(char *theMessage);
int sprintf(char *out, const char *format, ...) ;
unsigned int ask_EEPROM_internal_addr(void);
unsigned char ask_EEPROM_data(void);
void EEPROM_internal_writting_polling(unsigned char slave_addr_RW);
void I2C_init(void);
void I2C_TX_command_status (char data, char command);
void I2C_byte_write (void);
void I2C_byte_read (void);
unsigned int ask_EEPROM_addr_range(void);
void I2C_multi_write (void);
void I2C_multi_read (void);
int boundry_checker (int intended_page_size, unsigned int current_addr);
void DAC(void);
unsigned char ask_ADC_channel (void);
/*******************************************************************************************
** I2C functions
*******************************************************************************************/
unsigned int ask_EEPROM_internal_addr(void){
    // ask the internal EEPROM address, return an array, storing the upper byte at location 0, and the lower byte at 1, the block select at 2
    int valid = 0;
    unsigned int addr;
    printf("\r\nWhat is the internal EEPROM address you want to access? ");
    while (!valid){
        addr = Get6HexDigits(0);
        if (addr > 0x01ffff) { // 128k byte memory
            printf("\r\nAddress cannot be greater than 0x01ffff! Input again: ");
        } else {
            valid = 1;
        }
    }
    return addr;
}

unsigned char ask_EEPROM_data(void){
    // ask the data to be written into the EEPROM
    unsigned char data;
    printf("\r\nWhat is the data you want to write into the EEPROM? ");
    data = Get2HexDigits(0);
    return data;
}

void EEPROM_internal_writting_polling(unsigned char slave_addr_RW){
    int flag = 1;
    // EEPROM acknowledge polling, wait for EEPROM's internal writting
    // send the writting control byte with a start signal
    I2C_TX_reg = slave_addr_RW;
    while (flag) {
        I2C_command_reg = start_write_cmd_I2C;
        // wait for the master core to finish transmitting
        while ((I2C_status_reg & 0x02) != 0){}
        // if we didn't get ACK bit, then EEPROM is done writting, quit polling 
        if ((I2C_status_reg & 0x80) == 0) {
            flag = 0;
        }
    }
}

void I2C_init (void) {
    // disenable the core to allow us to set the prescale registers
    I2C_control_reg = 0x00; 
    // set prescale registers to 0x0031
    I2C_prescale_reg_L = 0x31;
    I2C_prescale_reg_H = 0x00;
    // enable the core, disenable the interrupt
    I2C_control_reg = 0x80;
}

void I2C_TX_command_status (unsigned char data, unsigned char command) {
    //printf("\r\ndata: %x", data);
    //printf("\r\ncommand: %x", command);
    I2C_TX_reg = data;
    I2C_command_reg = command;
    // check the TIP bit, if it's 1, we wait here
    while ((I2C_status_reg & 0x02) != 0){}
    //printf("\r\nTIP done");
    // wait for acknowledge from slave
    while ((I2C_status_reg & 0x80) != 0){
        //printf("\r\n%x", I2C_status_reg);
    }
    //printf("\r\nACK received");
}

void I2C_byte_write (void) {
    unsigned char slave_addr_RW;
    unsigned char slave_write_data;
    unsigned char EEPROM_block_select;
    unsigned char EEPROM_internal_addr_H, EEPROM_internal_addr_L;
    unsigned int addr;
    int EEPROM_polling_flag = 1;

    printf("\r\nRandom EEPROM byte write");
    // get the internal address
    addr = ask_EEPROM_internal_addr();
    EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
    EEPROM_internal_addr_L = addr & 0x0000ff;
    EEPROM_block_select = (addr & 0x010000) >> 16;

    slave_write_data = ask_EEPROM_data();

    // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
    slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));

    // send the control byte and generate a start signal
    I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

    // write EEPROM internal addr (upper and lower byte), no start signal
    I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
    I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);
    
    // write the actual data, and generate a stop condition after receiving an Acknowledge from the slave
    I2C_TX_command_status(slave_write_data, stop_write_cmd_I2C);
    
    EEPROM_internal_writting_polling(slave_addr_RW);
    printf("\r\nEEPROM writting done!");
}

void I2C_byte_read (void) {
    char slave_addr_RW;
    unsigned char slave_read_data;
    unsigned char EEPROM_block_select;
    unsigned int addr;
    unsigned char EEPROM_internal_addr_H, EEPROM_internal_addr_L;

    printf("\r\nRandom EEPROM byte read");
    // get the internal address
    addr = ask_EEPROM_internal_addr();
    EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
    EEPROM_internal_addr_L = addr & 0x0000ff;
    EEPROM_block_select = (addr & 0x010000) >> 16;

    // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
    slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));

    // send the control byte and generate a start signal
    I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

    // write EEPROM internal addr (upper and lower byte), no start signal
    I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
    I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);

    // EEPROM tag (b'1010) + chip select ('b00) + block select + read (1)
    slave_addr_RW = (0xa1 | (EEPROM_block_select << 1));

    // send the control byte and generate a repeated start signal
    I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

    // set STO bit to 1, set RD bit to 1, set ACk to 1 (NACK), set IACK to 1
    I2C_command_reg = stop_read_NACK_cmd_I2C;

    // polling the IF flag in the status reg
    while ((I2C_status_reg & 0x01) != 1){}
    slave_read_data = I2C_RX_reg;
    printf("\r\nEEPROM reading done! %x",slave_read_data);

}

unsigned int ask_EEPROM_addr_range(void) {
    unsigned int size;
    int valid = 0;
    printf("\r\nWhat is the EEPROM address range size (in hex) you want to access? ");
    while (!valid) {
        size = Get6HexDigits(0);
        if (size > 0x020000) {
            printf ("\r\nSize cannot be larger than 'h020000 (128K bytes), input again: ");
        } else if (size == 0) {
            printf("\r\nSize cannot be 0, the minimum size is 'h000001 (1 byte), input again: ");
        } else {
            valid = 1;
        }
    }
    return size;
}

int boundry_checker (int intended_page_size, unsigned int current_addr) {
    // check boundry crossing, return the appropriate number of bytes we should write in a page write (page_size)

    unsigned int new_addr;
    int page_size;
    // if we write the intended page size, what's the end address we're gonna be at?
    new_addr = current_addr + intended_page_size - 1;
    if (current_addr <= 0xffff && new_addr > 0xffff) {
        // cross the middle boundry
        page_size = 0xffff - current_addr + 1;
    } else if (current_addr <= 0x1ffff && new_addr > 0x1ffff) {
        // cross the end boundry
        page_size = 0x1ffff - current_addr + 1;
    } else {
        page_size = intended_page_size;
    }
    return page_size;
}

void I2C_multi_write (void) {
    unsigned int size, addr, page_index;
    unsigned char slave_addr_RW;
    unsigned char EEPROM_block_select, EEPROM_internal_addr_H, EEPROM_internal_addr_L;
    char command;
    int page_size;
    int page_limit = 128;
    unsigned char write_data = 0;

    printf("\r\nMultipe bytes EEPROM write");
    // ask the range of the writting
    size = ask_EEPROM_addr_range();
    // ask the start address
    addr = ask_EEPROM_internal_addr();
    printf("\r\nWritting...");

    while (size > 0){
        command = write_cmd_I2C;
        if (size <= page_limit) {
            page_size = boundry_checker(size, addr);
        } else if (size > page_limit) {
            page_size = boundry_checker(page_limit, addr);
        }

        EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
        EEPROM_internal_addr_L = addr & 0x0000ff;
        EEPROM_block_select = (addr & 0x010000) >> 16;

        // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
        slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));

        // send the control byte and generate a start signal
        I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

        // write EEPROM internal addr (upper and lower byte), no start signal
        I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
        I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);

        for (page_index = 0; page_index < page_size; page_index++) {
            // write the actual data (128 bytes), generate a stop signal at the 128th byte
            if (page_index == page_size - 1) {
                command = stop_write_cmd_I2C;
            }
            I2C_TX_command_status(write_data, command);
            write_data ++;
        }

        EEPROM_internal_writting_polling(slave_addr_RW);

        addr = addr + page_size;
        size = size - page_size;
        // refresh the writting command to exclude stop signal
        
    }

    printf("\r\nMultiple bytes writting done");
}

void I2C_multi_read (void) {
    unsigned int size, addr, page_index;
    unsigned char slave_addr_RW;
    unsigned char EEPROM_block_select, EEPROM_internal_addr_H, EEPROM_internal_addr_L;
    char command;
    int page_size;
    unsigned char read_data;
    unsigned int counter = 0;
    unsigned printing_step_size = 1;

    printf("\r\nMultiple bytes EEPROM read");
    // ask the range of the writting
    size = ask_EEPROM_addr_range();
    // ask the start address
    addr = ask_EEPROM_internal_addr();

    // if we have more than 10 items to read, we only print out 10 lines.
    if (size > 10){
        printing_step_size = size/10;
    }
    
    while (size > 0){
        command = read_ACK_cmd_I2C;
        
        page_size = boundry_checker(size, addr);

        EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
        EEPROM_internal_addr_L = addr & 0x0000ff;
        EEPROM_block_select = (addr & 0x010000) >> 16;

        // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
        slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));

        // send the control byte and generate a start signal
        I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

        // write EEPROM internal addr (upper and lower byte), no start signal
        I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
        I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);

        // EEPROM tag (b'1010) + chip select ('b00) + block select + read (1)
        slave_addr_RW = (0xa1 | (EEPROM_block_select << 1));

        // send the control byte and generate a repeated start signal
        I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

        for (page_index = 0; page_index < page_size; page_index++) {
            
            if (page_index == page_size - 1) {
                command = stop_read_NACK_cmd_I2C;
            }
            I2C_command_reg = command;
            
            // polling the IF flag in the status reg
            while ((I2C_status_reg & 0x01) != 1){}
            
            if (counter % printing_step_size == 0){
                read_data = I2C_RX_reg;
                printf("\r\nAddress: %x, Read data: %x",counter & 0x01ffff, read_data);
            }
            counter ++;
        }
        
        addr = addr + page_size;
        size = size - page_size;        
    }

}

void DAC(void) {
    unsigned char slave_addr_RW;
    unsigned char control_byte;
    unsigned char command = write_cmd_I2C;
    printf("\r\nUsing DAC to control LED");

    // PCF8591 tag (b'1001) + chip select (b'000) + write (0)
    slave_addr_RW = 0x90;
    // only enable the analog bit
    control_byte = 0x40;

    // send the slave address byte and generate a start signal
    I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
    //printf("\r\nslave address sent");

    // send the control byte to PCF8591
    I2C_TX_command_status(control_byte, write_cmd_I2C);
    //printf("\r\ncontrol byte sent");
    /*
    for (i = 0; i <2560; i++) {
        // keep writting digital signal
        if (i == 2559) {
            // generate a stop signal at the last byte
            command = stop_write_cmd_I2C;
        }
        I2C_TX_command_status(digital_write_data, command);
        digital_write_data ++;
    }
    */
    while (1){
        I2C_TX_command_status(0xff,command);
        Wait500ms ();
        I2C_TX_command_status(0x00,command);
        Wait500ms ();
    }
    
}

void ADC(void) {
    unsigned char slave_addr_RW;
    unsigned char control_byte;
    unsigned char command = read_ACK_cmd_I2C;
    unsigned char read_data;
    printf("\r\nReading values from the ADC");

    // PCF8591 tag (b'1001) + chip select (b'000) + write (0)
    slave_addr_RW = 0x90;
    // generate the control byte based on the channel user selected
    control_byte = ask_ADC_channel();

    // send the slave address byte and generate a start signal
    I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);
    // send the control byte to PCF8591
    I2C_TX_command_status(control_byte, write_cmd_I2C);

    // PCF8591 tag (b'1001) + chip select (b'000) + read (1)
    slave_addr_RW = 0x91;
    // repeated start
    I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

    // send the slave address byte and generate a repeated start signal
    //I2C_TX_command_status(slave_addr_RW, start_write_cmd_I2C);

    while (1) {
        I2C_command_reg = command;
            
        // polling the IF flag in the status reg
        while ((I2C_status_reg & 0x01) != 1){}
        read_data = I2C_RX_reg;
        printf("\r\nRead data: %x", read_data);
    }
}

unsigned char ask_ADC_channel (void){
    unsigned char channel;
    unsigned char control_byte;
    int valid = 0;
    while (!valid){
        printf("\r\nWhich channel you want to read? 1. Potentiometer 2.Photoresistor 3.Thermistor ");
        channel = Get1HexDigits(0);

        if (channel == 1) {
            control_byte = 0x01;
            valid = 1;
        } else if (channel == 2) {
            control_byte = 0x02;
            valid = 1;
        } else if (channel == 3) {
            control_byte = 0x03;
            valid = 1;
        } else {
            printf("\r\nInvalid selection!");
            valid = 0;
        }
    }
    return control_byte;
}


/*****************************************************************************************
**	Interrupt service routine for Timers
**
**  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
**  out which timer is producing the interrupt
**
*****************************************************************************************/

void Timer_ISR()
{
   	if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
   	    Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
   	}

  	if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
   	    Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
   	}

   	if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
   	    Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
   	}

   	if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
   	    Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
   	}
}

/*****************************************************************************************
**	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void ACIA_ISR()
{}

/***************************************************************************************
**	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void PIA_ISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 2 on DE1 board. Add your own response here
************************************************************************************/
void Key2PressISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 1 on DE1 board. Add your own response here
************************************************************************************/
void Key1PressISR()
{}

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

char xtod(int c)
{
    if ((char)(c) <= (char)('9'))
        return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
    else if((char)(c) > (char)('F'))    // assume lower case
        return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
    else
        return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
}

int Get1HexDigits(char *CheckSumPtr)
{
    register int i = xtod(_getch());

    if(CheckSumPtr)
        *CheckSumPtr += i ;

    return i; 
}

int Get2HexDigits(char *CheckSumPtr)
{
    register int i = (xtod(_getch()) << 4) | (xtod(_getch()));

    if(CheckSumPtr)
        *CheckSumPtr += i ;

    return i ;
}

int Get4HexDigits(char *CheckSumPtr)
{
    return (Get2HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
}

int Get6HexDigits(char *CheckSumPtr)
{
    return (Get4HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
}

int Get8HexDigits(char *CheckSumPtr)
{
    return (Get4HexDigits(CheckSumPtr) << 16) | (Get4HexDigits(CheckSumPtr));
}

/******************************************************************************
**  Subroutine to output a single character to the 2 row LCD display
**  It is assumed the character is an ASCII code and it will be displayed at the
**  current cursor position
*******************************************************************************/
void LCDOutchar(int c)
{
    LCDdata = (char)(c);
    Wait1ms() ;
}

/**********************************************************************************
*subroutine to output a message at the current cursor position of the LCD display
************************************************************************************/
void LCDOutMessage(char *theMessage)
{
    char c ;
    while((c = *theMessage++) != 0)     // output characters from the string until NULL
        LCDOutchar(c) ;
}

/******************************************************************************
*subroutine to clear the line by issuing 24 space characters
*******************************************************************************/
void LCDClearln(void)
{
    int i ;
    for(i = 0; i < 24; i ++)
        LCDOutchar(' ') ;       // write a space char to the LCD display
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 1 and clear that line
*******************************************************************************/
void LCDLine1Message(char *theMessage)
{
    LCDcommand = 0x80 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0x80 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 2 and clear that line
*******************************************************************************/
void LCDLine2Message(char *theMessage)
{
    LCDcommand = 0xC0 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0xC0 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

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

/******************************************************************************************************************************
* Start of user program
******************************************************************************************************************************/

void main()
{   
    unsigned int row, i=0, count=0, counter1=1;
    char c, text[150] ;
    int f;
    int valid;

	int PassFailFlag = 1 ;

    i = x = y = z = PortA_Count =0;
    Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;

    InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
    InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
    InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
    InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
    InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ

    Timer1Data = 0x10;		// program time delay into timers 1-4
    Timer2Data = 0x20;
    Timer3Data = 0x15;
    Timer4Data = 0x25;

    Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
    Timer2Control = 3;
    Timer3Control = 3;
    Timer4Control = 3;

    Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
    Init_RS232() ;          // initialise the RS232 port for use with hyper terminal

/************************************************************************************************
**  Test of scanf function
************************************************************************************************/

    /*scanflush() ;                       // flush any text that may have been typed ahead
    printf("\r\nEnter Integer: ") ;
    scanf("%d", &i) ;
    printf("You entered %d", i) ;

    sprintf(text, "Hello CPEN 412 Student") ;
    LCDLine1Message(text) ;

    printf("\r\nHello CPEN 412 Student\r\nYour LEDs should be Flashing") ;
    printf("\r\nYour LCD should be displaying") ;

    while(1)
        ;*/
    //printf("\r\nBig Brother is watching you");
    I2C_init ();
    //I2C_byte_write();
    //I2C_byte_write();
    //I2C_multi_write();
    //I2C_byte_read();
    /*I2C_byte_read();
    I2C_byte_read();
    I2C_byte_read();
    I2C_byte_read();*/
    //I2C_multi_read();
    //DAC();
    //ADC();
    while(1) {
        valid = 0;
        while (!valid) {
            printf("\r\nWhich function you want to run?\n1.EEPROM single byte write\n2.EEPROM single byte read\n3.EEPROM page write\n4.EEPROM page read\n5.DAC->LED\n6.ADC<-sensors ");
            f = Get1HexDigits(0);
            if (f >= 1 && f <= 6) {
                valid = 1;
            } else {
                printf("\r\nInvalid selection! ");
                valid = 0;
            }
        }

        if (f == 1){
            I2C_byte_write();
        } else if (f == 2){
            I2C_byte_read();
        } else if (f == 3){
            I2C_multi_write();
        } else if (f == 4){
            I2C_multi_read();
        } else if (f == 5){
            DAC();
        } else if (f == 6){
            ADC();
        }

    }
   // programs should NOT exit as there is nothing to Exit TO !!!!!!
   // There is no OS - just press the reset button to end program and call debug
}