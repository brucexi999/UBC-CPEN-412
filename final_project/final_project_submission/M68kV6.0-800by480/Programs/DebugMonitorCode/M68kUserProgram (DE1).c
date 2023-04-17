#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "snake.h"

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

/*******************************************************************************************
** CAN bus
*******************************************************************************************/

#define CAN0_CONTROLLER(i) (*(volatile unsigned char *)(0x00500000 + (i << 1)))
#define CAN1_CONTROLLER(i) (*(volatile unsigned char *)(0x00500200 + (i << 1)))

/* Can 0 register definitions */
#define Can0_ModeControlReg      CAN0_CONTROLLER(0)
#define Can0_CommandReg          CAN0_CONTROLLER(1)
#define Can0_StatusReg           CAN0_CONTROLLER(2)
#define Can0_InterruptReg        CAN0_CONTROLLER(3)
#define Can0_InterruptEnReg      CAN0_CONTROLLER(4) /* PeliCAN mode */
#define Can0_BusTiming0Reg       CAN0_CONTROLLER(6)
#define Can0_BusTiming1Reg       CAN0_CONTROLLER(7)
#define Can0_OutControlReg       CAN0_CONTROLLER(8)

/* address definitions of Other Registers */
#define Can0_ArbLostCapReg       CAN0_CONTROLLER(11)
#define Can0_ErrCodeCapReg       CAN0_CONTROLLER(12)
#define Can0_ErrWarnLimitReg     CAN0_CONTROLLER(13)
#define Can0_RxErrCountReg       CAN0_CONTROLLER(14)
#define Can0_TxErrCountReg       CAN0_CONTROLLER(15)
#define Can0_RxMsgCountReg       CAN0_CONTROLLER(29)
#define Can0_RxBufStartAdr       CAN0_CONTROLLER(30)
#define Can0_ClockDivideReg      CAN0_CONTROLLER(31)

/* address definitions of Acceptance Code & Mask Registers - RESET MODE */
#define Can0_AcceptCode0Reg      CAN0_CONTROLLER(16)
#define Can0_AcceptCode1Reg      CAN0_CONTROLLER(17)
#define Can0_AcceptCode2Reg      CAN0_CONTROLLER(18)
#define Can0_AcceptCode3Reg      CAN0_CONTROLLER(19)
#define Can0_AcceptMask0Reg      CAN0_CONTROLLER(20)
#define Can0_AcceptMask1Reg      CAN0_CONTROLLER(21)
#define Can0_AcceptMask2Reg      CAN0_CONTROLLER(22)
#define Can0_AcceptMask3Reg      CAN0_CONTROLLER(23)

/* address definitions Rx Buffer - OPERATING MODE - Read only register*/
#define Can0_RxFrameInfo         CAN0_CONTROLLER(16)
#define Can0_RxBuffer1           CAN0_CONTROLLER(17)
#define Can0_RxBuffer2           CAN0_CONTROLLER(18)
#define Can0_RxBuffer3           CAN0_CONTROLLER(19)
#define Can0_RxBuffer4           CAN0_CONTROLLER(20)
#define Can0_RxBuffer5           CAN0_CONTROLLER(21)
#define Can0_RxBuffer6           CAN0_CONTROLLER(22)
#define Can0_RxBuffer7           CAN0_CONTROLLER(23)
#define Can0_RxBuffer8           CAN0_CONTROLLER(24)
#define Can0_RxBuffer9           CAN0_CONTROLLER(25)
#define Can0_RxBuffer10          CAN0_CONTROLLER(26)
#define Can0_RxBuffer11          CAN0_CONTROLLER(27)
#define Can0_RxBuffer12          CAN0_CONTROLLER(28)

/* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
#define Can0_TxFrameInfo         CAN0_CONTROLLER(16)
#define Can0_TxBuffer1           CAN0_CONTROLLER(17)
#define Can0_TxBuffer2           CAN0_CONTROLLER(18)
#define Can0_TxBuffer3           CAN0_CONTROLLER(19)
#define Can0_TxBuffer4           CAN0_CONTROLLER(20)
#define Can0_TxBuffer5           CAN0_CONTROLLER(21)
#define Can0_TxBuffer6           CAN0_CONTROLLER(22)
#define Can0_TxBuffer7           CAN0_CONTROLLER(23)
#define Can0_TxBuffer8           CAN0_CONTROLLER(24)
#define Can0_TxBuffer9           CAN0_CONTROLLER(25)
#define Can0_TxBuffer10          CAN0_CONTROLLER(26)
#define Can0_TxBuffer11          CAN0_CONTROLLER(27)
#define Can0_TxBuffer12          CAN0_CONTROLLER(28)

/* read only addresses */
#define Can0_TxFrameInfoRd       CAN0_CONTROLLER(96)
#define Can0_TxBufferRd1         CAN0_CONTROLLER(97)
#define Can0_TxBufferRd2         CAN0_CONTROLLER(98)
#define Can0_TxBufferRd3         CAN0_CONTROLLER(99)
#define Can0_TxBufferRd4         CAN0_CONTROLLER(100)
#define Can0_TxBufferRd5         CAN0_CONTROLLER(101)
#define Can0_TxBufferRd6         CAN0_CONTROLLER(102)
#define Can0_TxBufferRd7         CAN0_CONTROLLER(103)
#define Can0_TxBufferRd8         CAN0_CONTROLLER(104)
#define Can0_TxBufferRd9         CAN0_CONTROLLER(105)
#define Can0_TxBufferRd10        CAN0_CONTROLLER(106)
#define Can0_TxBufferRd11        CAN0_CONTROLLER(107)
#define Can0_TxBufferRd12        CAN0_CONTROLLER(108)


/* CAN1 Controller register definitions */
#define Can1_ModeControlReg      CAN1_CONTROLLER(0)
#define Can1_CommandReg          CAN1_CONTROLLER(1)
#define Can1_StatusReg           CAN1_CONTROLLER(2)
#define Can1_InterruptReg        CAN1_CONTROLLER(3)
#define Can1_InterruptEnReg      CAN1_CONTROLLER(4) /* PeliCAN mode */
#define Can1_BusTiming0Reg       CAN1_CONTROLLER(6)
#define Can1_BusTiming1Reg       CAN1_CONTROLLER(7)
#define Can1_OutControlReg       CAN1_CONTROLLER(8)

/* address definitions of Other Registers */
#define Can1_ArbLostCapReg       CAN1_CONTROLLER(11)
#define Can1_ErrCodeCapReg       CAN1_CONTROLLER(12)
#define Can1_ErrWarnLimitReg     CAN1_CONTROLLER(13)
#define Can1_RxErrCountReg       CAN1_CONTROLLER(14)
#define Can1_TxErrCountReg       CAN1_CONTROLLER(15)
#define Can1_RxMsgCountReg       CAN1_CONTROLLER(29)
#define Can1_RxBufStartAdr       CAN1_CONTROLLER(30)
#define Can1_ClockDivideReg      CAN1_CONTROLLER(31)

/* address definitions of Acceptance Code & Mask Registers - RESET MODE */
#define Can1_AcceptCode0Reg      CAN1_CONTROLLER(16)
#define Can1_AcceptCode1Reg      CAN1_CONTROLLER(17)
#define Can1_AcceptCode2Reg      CAN1_CONTROLLER(18)
#define Can1_AcceptCode3Reg      CAN1_CONTROLLER(19)
#define Can1_AcceptMask0Reg      CAN1_CONTROLLER(20)
#define Can1_AcceptMask1Reg      CAN1_CONTROLLER(21)
#define Can1_AcceptMask2Reg      CAN1_CONTROLLER(22)
#define Can1_AcceptMask3Reg      CAN1_CONTROLLER(23)

/* address definitions Rx Buffer - OPERATING MODE - Read only register*/
#define Can1_RxFrameInfo         CAN1_CONTROLLER(16)
#define Can1_RxBuffer1           CAN1_CONTROLLER(17)
#define Can1_RxBuffer2           CAN1_CONTROLLER(18)
#define Can1_RxBuffer3           CAN1_CONTROLLER(19)
#define Can1_RxBuffer4           CAN1_CONTROLLER(20)
#define Can1_RxBuffer5           CAN1_CONTROLLER(21)
#define Can1_RxBuffer6           CAN1_CONTROLLER(22)
#define Can1_RxBuffer7           CAN1_CONTROLLER(23)
#define Can1_RxBuffer8           CAN1_CONTROLLER(24)
#define Can1_RxBuffer9           CAN1_CONTROLLER(25)
#define Can1_RxBuffer10          CAN1_CONTROLLER(26)
#define Can1_RxBuffer11          CAN1_CONTROLLER(27)
#define Can1_RxBuffer12          CAN1_CONTROLLER(28)

/* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
#define Can1_TxFrameInfo         CAN1_CONTROLLER(16)
#define Can1_TxBuffer1           CAN1_CONTROLLER(17)
#define Can1_TxBuffer2           CAN1_CONTROLLER(18)
#define Can1_TxBuffer3           CAN1_CONTROLLER(19)
#define Can1_TxBuffer4           CAN1_CONTROLLER(20)
#define Can1_TxBuffer5           CAN1_CONTROLLER(21)
#define Can1_TxBuffer6           CAN1_CONTROLLER(22)
#define Can1_TxBuffer7           CAN1_CONTROLLER(23)
#define Can1_TxBuffer8           CAN1_CONTROLLER(24)
#define Can1_TxBuffer9           CAN1_CONTROLLER(25)
#define Can1_TxBuffer10          CAN1_CONTROLLER(26)
#define Can1_TxBuffer11          CAN1_CONTROLLER(27)
#define Can1_TxBuffer12          CAN1_CONTROLLER(28)

/* read only addresses */
#define Can1_TxFrameInfoRd       CAN1_CONTROLLER(96)
#define Can1_TxBufferRd1         CAN1_CONTROLLER(97)
#define Can1_TxBufferRd2         CAN1_CONTROLLER(98)
#define Can1_TxBufferRd3         CAN1_CONTROLLER(99)
#define Can1_TxBufferRd4         CAN1_CONTROLLER(100)
#define Can1_TxBufferRd5         CAN1_CONTROLLER(101)
#define Can1_TxBufferRd6         CAN1_CONTROLLER(102)
#define Can1_TxBufferRd7         CAN1_CONTROLLER(103)
#define Can1_TxBufferRd8         CAN1_CONTROLLER(104)
#define Can1_TxBufferRd9         CAN1_CONTROLLER(105)
#define Can1_TxBufferRd10        CAN1_CONTROLLER(106)
#define Can1_TxBufferRd11        CAN1_CONTROLLER(107)
#define Can1_TxBufferRd12        CAN1_CONTROLLER(108)


/* bit definitions for the Mode & Control Register */
#define RM_RR_Bit 0x01 /* reset mode (request) bit */
#define LOM_Bit 0x02 /* listen only mode bit */
#define STM_Bit 0x04 /* self test mode bit */
#define AFM_Bit 0x08 /* acceptance filter mode bit */
#define SM_Bit  0x10 /* enter sleep mode bit */

/* bit definitions for the Interrupt Enable & Control Register */
#define RIE_Bit 0x01 /* receive interrupt enable bit */
#define TIE_Bit 0x02 /* transmit interrupt enable bit */
#define EIE_Bit 0x04 /* error warning interrupt enable bit */
#define DOIE_Bit 0x08 /* data overrun interrupt enable bit */
#define WUIE_Bit 0x10 /* wake-up interrupt enable bit */
#define EPIE_Bit 0x20 /* error passive interrupt enable bit */
#define ALIE_Bit 0x40 /* arbitration lost interr. enable bit*/
#define BEIE_Bit 0x80 /* bus error interrupt enable bit */

/* bit definitions for the Command Register */
#define TR_Bit 0x01 /* transmission request bit */
#define AT_Bit 0x02 /* abort transmission bit */
#define RRB_Bit 0x04 /* release receive buffer bit */
#define CDO_Bit 0x08 /* clear data overrun bit */
#define SRR_Bit 0x10 /* self reception request bit */

/* bit definitions for the Status Register */
#define RBS_Bit 0x01 /* receive buffer status bit */
#define DOS_Bit 0x02 /* data overrun status bit */
#define TBS_Bit 0x04 /* transmit buffer status bit */
#define TCS_Bit 0x08 /* transmission complete status bit */
#define RS_Bit 0x10 /* receive status bit */
#define TS_Bit 0x20 /* transmit status bit */
#define ES_Bit 0x40 /* error status bit */
#define BS_Bit 0x80 /* bus status bit */

/* bit definitions for the Interrupt Register */
#define RI_Bit 0x01 /* receive interrupt bit */
#define TI_Bit 0x02 /* transmit interrupt bit */
#define EI_Bit 0x04 /* error warning interrupt bit */
#define DOI_Bit 0x08 /* data overrun interrupt bit */
#define WUI_Bit 0x10 /* wake-up interrupt bit */
#define EPI_Bit 0x20 /* error passive interrupt bit */
#define ALI_Bit 0x40 /* arbitration lost interrupt bit */
#define BEI_Bit 0x80 /* bus error interrupt bit */


/* bit definitions for the Bus Timing Registers */
#define SAM_Bit 0x80                        /* sample mode bit 1 == the bus is sampled 3 times, 0 == the bus is sampled once */

/* bit definitions for the Output Control Register OCMODE1, OCMODE0 */
#define BiPhaseMode 0x00 /* bi-phase output mode */
#define NormalMode 0x02 /* normal output mode */
#define ClkOutMode 0x03 /* clock output mode */

/* output pin configuration for TX1 */
#define OCPOL1_Bit 0x20 /* output polarity control bit */
#define Tx1Float 0x00 /* configured as float */
#define Tx1PullDn 0x40 /* configured as pull-down */
#define Tx1PullUp 0x80 /* configured as pull-up */
#define Tx1PshPull 0xC0 /* configured as push/pull */

/* output pin configuration for TX0 */
#define OCPOL0_Bit 0x04 /* output polarity control bit */
#define Tx0Float 0x00 /* configured as float */
#define Tx0PullDn 0x08 /* configured as pull-down */
#define Tx0PullUp 0x10 /* configured as pull-up */
#define Tx0PshPull 0x18 /* configured as push/pull */

/* bit definitions for the Clock Divider Register */
#define DivBy1 0x07 /* CLKOUT = oscillator frequency */
#define DivBy2 0x00 /* CLKOUT = 1/2 oscillator frequency */
#define ClkOff_Bit 0x08 /* clock off bit, control of the CLK OUT pin */
#define RXINTEN_Bit 0x20 /* pin TX1 used for receive interrupt */
#define CBP_Bit 0x40 /* CAN comparator bypass control bit */
#define CANMode_Bit 0x80 /* CAN mode definition bit */

/*- definition of used constants ---------------------------------------*/
#define YES 1
#define NO 0
#define ENABLE 1
#define DISABLE 0
#define ENABLE_N 0
#define DISABLE_N 1
#define INTLEVELACT 0
#define INTEDGEACT 1
#define PRIORITY_LOW 0
#define PRIORITY_HIGH 1

/* default (reset) value for register content, clear register */
#define ClrByte 0x00

/* constant: clear Interrupt Enable Register */
#define ClrIntEnSJA ClrByte

/* definitions for the acceptance code and mask register */
#define DontCare 0xFF


/*  bus timing values for
**  bit-rate : 100 kBit/s
**  oscillator frequency : 25 MHz, 1 sample per bit, 0 tolerance %
**  maximum tolerated propagation delay : 4450 ns
**  minimum requested propagation delay : 500 ns
**
**  https://www.kvaser.com/support/calculators/bit-timing-calculator/
**  T1 	T2 	BTQ 	SP% 	SJW 	BIT RATE 	ERR% 	BTR0 	BTR1
**  17	8	25	    68	     1	      100	    0	      04	7f
*/

/*************************************************************
** SPI Controller registers
**************************************************************/
// SPI Registers
#define SPI_Control         (*(volatile unsigned char *)(0x00408020))
#define SPI_Status          (*(volatile unsigned char *)(0x00408022))
#define SPI_Data            (*(volatile unsigned char *)(0x00408024))
#define SPI_Ext             (*(volatile unsigned char *)(0x00408026))
#define SPI_CS              (*(volatile unsigned char *)(0x00408028))

// these two macros enable or disable the flash memory chip enable off SSN_O[7..0]
// in this case we assume there is only 1 device connected to SSN_O[0] so we can
// write hex FE to the SPI_CS to enable it (the enable on the flash chip is active low)
// and write FF to disable it

#define   Enable_SPI_CS()             SPI_CS = 0xFE
#define   Disable_SPI_CS()            SPI_CS = 0xFF

// SPI flash chip commands
#define write_enable_cmd 0x06
#define erasing_cmd  0xc7
#define read_cmd  0x03
#define write_cmd  0x02
#define check_status_cmd 0x05

/*************************************************************
** final project VGA
**************************************************************/
#define vga_ram_start         (*(volatile unsigned char *)(0x00600000))
#define vga_x_cursor_reg          (*(volatile unsigned char *)(0x00601000))
#define vga_y_cursor_reg            (*(volatile unsigned char *)(0x00601002))
#define vga_ctrl_reg             (*(volatile unsigned char *)(0x00601004))

/*********************************************************************************************************************************
 * 
 * 
(( DO NOT initialise global variables here, do it main even if you want 0
(( it's a limitation of the compiler
(( YOU HAVE BEEN WARNED
*********************************************************************************************************************************/

unsigned int i, x, y, z, PortA_Count;
unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;
unsigned char switch_counter, eeprom_counter, flash_counter;

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
** CAN bus functions
*******************************************************************************************/

// initialisation for Can controller 0
void Init_CanBus_Controller0(void)
{
    // TODO - put your Canbus initialisation code for CanController 0 here
    // See section 4.2.1 in the application note for details (PELICAN MODE)
    //printf("\r\nInitializing Can controller 0");
    while((Can0_ModeControlReg & RM_RR_Bit ) == ClrByte)
    {
        Can0_ModeControlReg = Can0_ModeControlReg | RM_RR_Bit;
    }
    Can0_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy1;
    Can0_InterruptEnReg = ClrIntEnSJA;

    Can0_AcceptCode0Reg = ClrByte;
    Can0_AcceptCode1Reg = ClrByte;
    Can0_AcceptCode2Reg = ClrByte;
    Can0_AcceptCode3Reg = ClrByte;
    Can0_AcceptMask0Reg = DontCare;
    Can0_AcceptMask1Reg = DontCare;
    Can0_AcceptMask2Reg = DontCare;
    Can0_AcceptMask3Reg = DontCare;

    // see the comment on line 275
    Can0_BusTiming0Reg = 0x04;
    Can0_BusTiming1Reg = 0x7f;

    Can0_OutControlReg = Tx0Float | Tx0PshPull | NormalMode;

    while ((Can0_ModeControlReg & RM_RR_Bit) != ClrByte)
    {
        Can0_ModeControlReg = ClrByte;
    }
}

// initialisation for Can controller 1
void Init_CanBus_Controller1(void)
{
    // TODO - put your Canbus initialisation code for CanController 1 here
    // See section 4.2.1 in the application note for details (PELICAN MODE)
    //printf("\r\nInitializing Can controller 1");
    while((Can1_ModeControlReg & RM_RR_Bit ) == ClrByte)
    {
        Can1_ModeControlReg = Can1_ModeControlReg | RM_RR_Bit;
    }
    Can1_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy1;
    Can1_InterruptEnReg = ClrIntEnSJA;
    Can1_AcceptCode0Reg = ClrByte;
    Can1_AcceptCode1Reg = ClrByte;
    Can1_AcceptCode2Reg = ClrByte;
    Can1_AcceptCode3Reg = ClrByte;
    Can1_AcceptMask0Reg = DontCare;
    Can1_AcceptMask1Reg = DontCare;
    Can1_AcceptMask2Reg = DontCare;
    Can1_AcceptMask3Reg = DontCare;

    // see the comment on line 275
    Can1_BusTiming0Reg = 0x04;
    Can1_BusTiming1Reg = 0x7f;

    Can1_OutControlReg = Tx1Float | Tx1PshPull | NormalMode;

    while ((Can1_ModeControlReg & RM_RR_Bit) != ClrByte)
    {
        Can1_ModeControlReg = ClrByte;
    }
}

// Transmit for sending a message via Can controller 0
void CanBus0_Transmit(unsigned char data)
{
    // TODO - put your Canbus transmit code for CanController 0 here
    // See section 4.2.2 in the application note for details (PELICAN MODE)
    //printf("\r\nTransmitting Can controller 0");
    while((Can0_StatusReg & TBS_Bit ) != TBS_Bit ) {}

    // frame format = 0 (standard), RTR = 0 (data framee), DLC = b'1000 (8 bytes), see data sheet page 40-41
    Can0_TxFrameInfo = 0x08;
    // 11 bits identifier, don't care, since we don't have filtering
    Can0_TxBuffer1 = 0x00;
    Can0_TxBuffer2 = 0x00;
    // 8 bytes data;
    Can0_TxBuffer3 = data;
    /*Can0_TxBuffer4 = 0x01;
    Can0_TxBuffer5 = 0x02;
    Can0_TxBuffer6 = 0x03;
    Can0_TxBuffer7 = 0x04;
    Can0_TxBuffer8 = 0x05;
    Can0_TxBuffer9 = 0x06;
    Can0_TxBuffer10 = 0x07;*/

    Can0_CommandReg = TR_Bit;

    // wait for the transmission to complete
    while((Can0_StatusReg & TCS_Bit ) != TCS_Bit ) {}

}

// Transmit for sending a message via Can controller 1
void CanBus1_Transmit(void)
{
    // TODO - put your Canbus transmit code for CanController 1 here
    // See section 4.2.2 in the application note for details (PELICAN MODE)
    //printf("\r\nTransmitting Can controller 1");
    while((Can1_StatusReg & TBS_Bit ) != TBS_Bit ) {}

    // frame format = 0 (standard), RTR = 0 (data framee), DLC = b'1000 (8 bytes), see data sheet page 40-41
    Can1_TxFrameInfo = 0x08;
    // 11 bits identifier, don't care, since we don't have filtering
    Can1_TxBuffer1 = 0x00;
    Can1_TxBuffer2 = 0x00;
    // 8 bytes data;
    Can1_TxBuffer3 = 0x07;
    Can1_TxBuffer4 = 0x06;
    Can1_TxBuffer5 = 0x05;
    Can1_TxBuffer6 = 0x04;
    Can1_TxBuffer7 = 0x03;
    Can1_TxBuffer8 = 0x02;
    Can1_TxBuffer9 = 0x01;
    Can1_TxBuffer10 = 0x00;

    Can1_CommandReg = TR_Bit;

    // wait for the transmission to complete
    while((Can1_StatusReg & TCS_Bit ) != TCS_Bit ) {}
}

// Receive for reading a received message via Can controller 0
void CanBus0_Receive(void)
{
    // TODO - put your Canbus receive code for CanController 0 here
    // See section 4.2.4 in the application note for details (PELICAN MODE)
    // wait for the receiver buffer to be full
    //printf("\r\nReading Can controller 0");
    while ((Can0_StatusReg & RBS_Bit) != RBS_Bit) {}

    printf("\r\n%x",Can0_RxBuffer3);
    printf("\r\n%x",Can0_RxBuffer4);
    printf("\r\n%x",Can0_RxBuffer5);
    printf("\r\n%x",Can0_RxBuffer6);
    printf("\r\n%x",Can0_RxBuffer7);
    printf("\r\n%x",Can0_RxBuffer8);
    printf("\r\n%x",Can0_RxBuffer9);
    printf("\r\n%x",Can0_RxBuffer10);


    Can0_CommandReg = RRB_Bit;

}

// Receive for reading a received message via Can controller 1
void CanBus1_Receive(void)
{
    // TODO - put your Canbus receive code for CanController 1 here
    // See section 4.2.4 in the application note for details (PELICAN MODE)
    //printf("\r\nReading Can controller 1");
    while ((Can1_StatusReg & RBS_Bit) != RBS_Bit) {}

    printf("\r\n%x",Can1_RxBuffer3);
    /*printf("\r\n%x",Can1_RxBuffer4);
    printf("\r\n%x",Can1_RxBuffer5);
    printf("\r\n%x",Can1_RxBuffer6);
    printf("\r\n%x",Can1_RxBuffer7);
    printf("\r\n%x",Can1_RxBuffer8);
    printf("\r\n%x",Can1_RxBuffer9);
    printf("\r\n%x",Can1_RxBuffer10);*/

    Can1_CommandReg = RRB_Bit;
}


void CanBusTest(void)
{
    // initialise the two Can controllers

    Init_CanBus_Controller0();
    Init_CanBus_Controller1();

    printf("\r\n\r\n---- CANBUS Test ----\r\n") ;

    // simple application to alternately transmit and receive messages from each of two nodes

    
        Wait500ms ();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly

        //CanBus0_Transmit() ;       // transmit a message via Controller 0
        CanBus1_Receive() ;        // receive a message via Controller 1 (and display it)

        printf("\r\n") ;

        Wait500ms ();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly

        CanBus1_Transmit() ;        // transmit a message via Controller 1
        CanBus0_Receive() ;         // receive a message via Controller 0 (and display it)
        printf("\r\n") ;

}


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

/******************************************************************************************
** The following code is for the SPI controller
*******************************************************************************************/
// return true if the SPI has finished transmitting a byte (to say the Flash chip) return false otherwise
// this can be used in a polling algorithm to know when the controller is busy or idle.

int TestForSPITransmitDataComplete(void)    {

    /* TODO replace 0 below with a test for status register SPIF bit and if set, return true */
    int result; 
    int status;
    status = SPI_Status;
    //printf("\r\nSPI status reg: %d",status); 
    result = status & 0x80; // get the SPIF bit, if SPIF == 1, then transmit is completed, if 0, then not completed. 
    return result;
}

/************************************************************************************
** initialises the SPI controller chip to set speed, interrupt capability etc.
************************************************************************************/
void SPI_Init(void)
{
    //TODO
    //
    // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
    // Don't forget to call this routine from main() before you do anything else with SPI
    //
    // Here are some settings we want to create
    //
    // Control Reg     - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed =  divide by 32 = approx 700Khz
    // Ext Reg         - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
    // SPI_CS Reg      - control selection of slave SPI chips via their CS# signals
    // Status Reg      - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag

    SPI_Control = 0x53;
    SPI_Ext = 0x00;
    Disable_SPI_CS(); // Disable the flash chip during initialisation 
    SPI_Status = 0xc0;
}

/************************************************************************************
** return ONLY when the SPI controller has finished transmitting a byte
************************************************************************************/
void WaitForSPITransmitComplete(void)
{
    // TODO : poll the status register SPIF bit looking for completion of transmission
    // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
    // just in case they were set
    int SPITransmitComplete = 0;
    while (!SPITransmitComplete)
    {
        SPITransmitComplete = TestForSPITransmitDataComplete();
        //printf("\r\nSPI data transmit complete: %d", SPITransmitComplete);
    }
    SPI_Status = 0xc0;
    
}

/************************************************************************************
** Write a byte to the SPI flash chip via the controller and returns (reads) whatever was
** given back by SPI device at the same time (removes the read byte from the FIFO)
************************************************************************************/
int WriteSPIChar(int c)
{
    // todo - write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
    // wait for completion of transmission
    // return the received data from Flash chip (which may not be relevent depending upon what we are doing)
    // by reading fom the SPI controller Data Register.
    // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
    //
    // modify '0' below to return back read byte from data register
    //
    int read_data = 0; 
    SPI_Data = c; 
    WaitForSPITransmitComplete();
    read_data = SPI_Data;
    return read_data;                   
}

// send a command to the flash chip 
void send_spi_cmd(int c){
    int read_data;

    Enable_SPI_CS();
    read_data = WriteSPIChar(c);
    Disable_SPI_CS();
}

/*Check the flash chip's status register*/
void wait_for_flash_status_done(void)
{
    int dummy_byte = 0x00;

    Enable_SPI_CS();
    WriteSPIChar(check_status_cmd); // send the check flash status register cmd
    while(WriteSPIChar(dummy_byte) & 0x01){
    }
    Disable_SPI_CS();
}



/*****************************************************************************************
**	Interrupt service routine for Timers
**
**  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
**  out which timer is producing the interrupt
**
*****************************************************************************************/

unsigned char flash_read(unsigned char addr){
    int i;
    unsigned char dram_data;
    int flash_data;
    int dummy_byte = 0x00;
    //volatile unsigned char* current_address;
    //volatile unsigned char* dram_start_address = (volatile unsigned char*) (start_of_dram);
    
    Enable_SPI_CS();
    WriteSPIChar(read_cmd); // read cmd
    WriteSPIChar(0x00);
    WriteSPIChar(0x00);
    WriteSPIChar(addr);
    flash_data = WriteSPIChar(dummy_byte);
    Disable_SPI_CS();
    return flash_data;
}

unsigned char EEPROM_read (unsigned char addr) {
    char slave_addr_RW;
    unsigned char slave_read_data;
    unsigned char EEPROM_block_select;
    unsigned char EEPROM_internal_addr_H, EEPROM_internal_addr_L;

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
    return slave_read_data;

}

void Timer_ISR(void)
{
    if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
        Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    switch_counter ++;
        eeprom_counter ++;
        flash_counter ++;
        if (switch_counter == 1)
        {   
            printf("\r\nReading switches");
            CanBus0_Transmit(PortA);     // read the value from the switches and broadcast using CANBUS controller 0
            CanBus1_Receive();
            switch_counter = 0;
        }
        if (eeprom_counter == 5)
        {
            printf("\r\nReading from address %x of EEPROM", PortA);
            CanBus0_Transmit(EEPROM_read(PortA));
            CanBus1_Receive();
            eeprom_counter = 0;
        }
        if (flash_counter == 20)
        {
            printf("\r\nReading from address %x of flash", PortA);
            CanBus0_Transmit(flash_read(PortA));
            CanBus1_Receive();
            flash_counter = 0;
        }
        
        
        
   	}

   /*	if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
   	    Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
   	}

   	if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
   	    Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
   	}*/
}
/*
void read_switch_timer8_ISR(void)
{   
    printf("\r\nRead switch");
    if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
   	    Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        CanBus0_Transmit(PortA);     // read the value from the switches and broadcast using CANBUS controller 0
        CanBus1_Receive();
   	}
}*/

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
* VGA functions
******************************************************************************************************************************/
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
        delay_ms(300);
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
    switch_counter = 0;
    eeprom_counter = 0;
    flash_counter = 0;

    //Init_CanBus_Controller0();
    //Init_CanBus_Controller1();
    //I2C_init (); // initialise the I2C controller
    //SPI_Init(); // initialise the SPI controller
    //I2C_multi_write();
    
    InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
    InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
    //InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
    InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
    InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ
    InstallExceptionHandler(clock, 30); // install interruot handler for Timer 2 on level 6 IRQ

    //Timer1Data = 0x10;		// program time delay into timers 1-4
    //Timer2Data = 0x25; // 100ms
    //Timer3Data = 0xbd; // 500ms
    //Timer4Data = 0x25; //
    Timer2Data = 0x03; // 10ms

    //Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
    Timer2Control = 3;
    //Timer3Control = 3;
    //Timer4Control = 3;

    Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
    Init_RS232() ;          // initialise the RS232 port for use with hyper terminal

    set_vga_control_reg(0x82);
    snake_main();
    //vga_x_cursor_reg = 0x28;
    //vga_y_cursor_reg = 0x14;
    /*gotoxy(79,39);
    //putcharxy(0,0, 0x24);
    cls();
    print_at_xy(0,0,"Luyao, I love you 10000 years");
    drawRect(1,1,79,38,'#');
    for (score=0;score<70;score++){
        updateScore();
        delay_ms(50);
    }
    
    gameOver();*/
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
    /*while(1) {
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

    }*/
    //while (1){}
    

   // programs should NOT exit as there is nothing to Exit TO !!!!!!
   // There is no OS - just press the reset button to end program and call debug
}