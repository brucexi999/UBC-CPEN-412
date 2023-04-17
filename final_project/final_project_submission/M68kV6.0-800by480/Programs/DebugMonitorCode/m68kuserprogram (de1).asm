; C:\M68KV6.0-800BY480\PROGRAMS\DEBUGMONITORCODE\M68KUSERPROGRAM (DE1).C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; #include "snake.h"
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
; /*******************************************************************************************
; ** CAN bus
; *******************************************************************************************/
; #define CAN0_CONTROLLER(i) (*(volatile unsigned char *)(0x00500000 + (i << 1)))
; #define CAN1_CONTROLLER(i) (*(volatile unsigned char *)(0x00500200 + (i << 1)))
; /* Can 0 register definitions */
; #define Can0_ModeControlReg      CAN0_CONTROLLER(0)
; #define Can0_CommandReg          CAN0_CONTROLLER(1)
; #define Can0_StatusReg           CAN0_CONTROLLER(2)
; #define Can0_InterruptReg        CAN0_CONTROLLER(3)
; #define Can0_InterruptEnReg      CAN0_CONTROLLER(4) /* PeliCAN mode */
; #define Can0_BusTiming0Reg       CAN0_CONTROLLER(6)
; #define Can0_BusTiming1Reg       CAN0_CONTROLLER(7)
; #define Can0_OutControlReg       CAN0_CONTROLLER(8)
; /* address definitions of Other Registers */
; #define Can0_ArbLostCapReg       CAN0_CONTROLLER(11)
; #define Can0_ErrCodeCapReg       CAN0_CONTROLLER(12)
; #define Can0_ErrWarnLimitReg     CAN0_CONTROLLER(13)
; #define Can0_RxErrCountReg       CAN0_CONTROLLER(14)
; #define Can0_TxErrCountReg       CAN0_CONTROLLER(15)
; #define Can0_RxMsgCountReg       CAN0_CONTROLLER(29)
; #define Can0_RxBufStartAdr       CAN0_CONTROLLER(30)
; #define Can0_ClockDivideReg      CAN0_CONTROLLER(31)
; /* address definitions of Acceptance Code & Mask Registers - RESET MODE */
; #define Can0_AcceptCode0Reg      CAN0_CONTROLLER(16)
; #define Can0_AcceptCode1Reg      CAN0_CONTROLLER(17)
; #define Can0_AcceptCode2Reg      CAN0_CONTROLLER(18)
; #define Can0_AcceptCode3Reg      CAN0_CONTROLLER(19)
; #define Can0_AcceptMask0Reg      CAN0_CONTROLLER(20)
; #define Can0_AcceptMask1Reg      CAN0_CONTROLLER(21)
; #define Can0_AcceptMask2Reg      CAN0_CONTROLLER(22)
; #define Can0_AcceptMask3Reg      CAN0_CONTROLLER(23)
; /* address definitions Rx Buffer - OPERATING MODE - Read only register*/
; #define Can0_RxFrameInfo         CAN0_CONTROLLER(16)
; #define Can0_RxBuffer1           CAN0_CONTROLLER(17)
; #define Can0_RxBuffer2           CAN0_CONTROLLER(18)
; #define Can0_RxBuffer3           CAN0_CONTROLLER(19)
; #define Can0_RxBuffer4           CAN0_CONTROLLER(20)
; #define Can0_RxBuffer5           CAN0_CONTROLLER(21)
; #define Can0_RxBuffer6           CAN0_CONTROLLER(22)
; #define Can0_RxBuffer7           CAN0_CONTROLLER(23)
; #define Can0_RxBuffer8           CAN0_CONTROLLER(24)
; #define Can0_RxBuffer9           CAN0_CONTROLLER(25)
; #define Can0_RxBuffer10          CAN0_CONTROLLER(26)
; #define Can0_RxBuffer11          CAN0_CONTROLLER(27)
; #define Can0_RxBuffer12          CAN0_CONTROLLER(28)
; /* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
; #define Can0_TxFrameInfo         CAN0_CONTROLLER(16)
; #define Can0_TxBuffer1           CAN0_CONTROLLER(17)
; #define Can0_TxBuffer2           CAN0_CONTROLLER(18)
; #define Can0_TxBuffer3           CAN0_CONTROLLER(19)
; #define Can0_TxBuffer4           CAN0_CONTROLLER(20)
; #define Can0_TxBuffer5           CAN0_CONTROLLER(21)
; #define Can0_TxBuffer6           CAN0_CONTROLLER(22)
; #define Can0_TxBuffer7           CAN0_CONTROLLER(23)
; #define Can0_TxBuffer8           CAN0_CONTROLLER(24)
; #define Can0_TxBuffer9           CAN0_CONTROLLER(25)
; #define Can0_TxBuffer10          CAN0_CONTROLLER(26)
; #define Can0_TxBuffer11          CAN0_CONTROLLER(27)
; #define Can0_TxBuffer12          CAN0_CONTROLLER(28)
; /* read only addresses */
; #define Can0_TxFrameInfoRd       CAN0_CONTROLLER(96)
; #define Can0_TxBufferRd1         CAN0_CONTROLLER(97)
; #define Can0_TxBufferRd2         CAN0_CONTROLLER(98)
; #define Can0_TxBufferRd3         CAN0_CONTROLLER(99)
; #define Can0_TxBufferRd4         CAN0_CONTROLLER(100)
; #define Can0_TxBufferRd5         CAN0_CONTROLLER(101)
; #define Can0_TxBufferRd6         CAN0_CONTROLLER(102)
; #define Can0_TxBufferRd7         CAN0_CONTROLLER(103)
; #define Can0_TxBufferRd8         CAN0_CONTROLLER(104)
; #define Can0_TxBufferRd9         CAN0_CONTROLLER(105)
; #define Can0_TxBufferRd10        CAN0_CONTROLLER(106)
; #define Can0_TxBufferRd11        CAN0_CONTROLLER(107)
; #define Can0_TxBufferRd12        CAN0_CONTROLLER(108)
; /* CAN1 Controller register definitions */
; #define Can1_ModeControlReg      CAN1_CONTROLLER(0)
; #define Can1_CommandReg          CAN1_CONTROLLER(1)
; #define Can1_StatusReg           CAN1_CONTROLLER(2)
; #define Can1_InterruptReg        CAN1_CONTROLLER(3)
; #define Can1_InterruptEnReg      CAN1_CONTROLLER(4) /* PeliCAN mode */
; #define Can1_BusTiming0Reg       CAN1_CONTROLLER(6)
; #define Can1_BusTiming1Reg       CAN1_CONTROLLER(7)
; #define Can1_OutControlReg       CAN1_CONTROLLER(8)
; /* address definitions of Other Registers */
; #define Can1_ArbLostCapReg       CAN1_CONTROLLER(11)
; #define Can1_ErrCodeCapReg       CAN1_CONTROLLER(12)
; #define Can1_ErrWarnLimitReg     CAN1_CONTROLLER(13)
; #define Can1_RxErrCountReg       CAN1_CONTROLLER(14)
; #define Can1_TxErrCountReg       CAN1_CONTROLLER(15)
; #define Can1_RxMsgCountReg       CAN1_CONTROLLER(29)
; #define Can1_RxBufStartAdr       CAN1_CONTROLLER(30)
; #define Can1_ClockDivideReg      CAN1_CONTROLLER(31)
; /* address definitions of Acceptance Code & Mask Registers - RESET MODE */
; #define Can1_AcceptCode0Reg      CAN1_CONTROLLER(16)
; #define Can1_AcceptCode1Reg      CAN1_CONTROLLER(17)
; #define Can1_AcceptCode2Reg      CAN1_CONTROLLER(18)
; #define Can1_AcceptCode3Reg      CAN1_CONTROLLER(19)
; #define Can1_AcceptMask0Reg      CAN1_CONTROLLER(20)
; #define Can1_AcceptMask1Reg      CAN1_CONTROLLER(21)
; #define Can1_AcceptMask2Reg      CAN1_CONTROLLER(22)
; #define Can1_AcceptMask3Reg      CAN1_CONTROLLER(23)
; /* address definitions Rx Buffer - OPERATING MODE - Read only register*/
; #define Can1_RxFrameInfo         CAN1_CONTROLLER(16)
; #define Can1_RxBuffer1           CAN1_CONTROLLER(17)
; #define Can1_RxBuffer2           CAN1_CONTROLLER(18)
; #define Can1_RxBuffer3           CAN1_CONTROLLER(19)
; #define Can1_RxBuffer4           CAN1_CONTROLLER(20)
; #define Can1_RxBuffer5           CAN1_CONTROLLER(21)
; #define Can1_RxBuffer6           CAN1_CONTROLLER(22)
; #define Can1_RxBuffer7           CAN1_CONTROLLER(23)
; #define Can1_RxBuffer8           CAN1_CONTROLLER(24)
; #define Can1_RxBuffer9           CAN1_CONTROLLER(25)
; #define Can1_RxBuffer10          CAN1_CONTROLLER(26)
; #define Can1_RxBuffer11          CAN1_CONTROLLER(27)
; #define Can1_RxBuffer12          CAN1_CONTROLLER(28)
; /* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
; #define Can1_TxFrameInfo         CAN1_CONTROLLER(16)
; #define Can1_TxBuffer1           CAN1_CONTROLLER(17)
; #define Can1_TxBuffer2           CAN1_CONTROLLER(18)
; #define Can1_TxBuffer3           CAN1_CONTROLLER(19)
; #define Can1_TxBuffer4           CAN1_CONTROLLER(20)
; #define Can1_TxBuffer5           CAN1_CONTROLLER(21)
; #define Can1_TxBuffer6           CAN1_CONTROLLER(22)
; #define Can1_TxBuffer7           CAN1_CONTROLLER(23)
; #define Can1_TxBuffer8           CAN1_CONTROLLER(24)
; #define Can1_TxBuffer9           CAN1_CONTROLLER(25)
; #define Can1_TxBuffer10          CAN1_CONTROLLER(26)
; #define Can1_TxBuffer11          CAN1_CONTROLLER(27)
; #define Can1_TxBuffer12          CAN1_CONTROLLER(28)
; /* read only addresses */
; #define Can1_TxFrameInfoRd       CAN1_CONTROLLER(96)
; #define Can1_TxBufferRd1         CAN1_CONTROLLER(97)
; #define Can1_TxBufferRd2         CAN1_CONTROLLER(98)
; #define Can1_TxBufferRd3         CAN1_CONTROLLER(99)
; #define Can1_TxBufferRd4         CAN1_CONTROLLER(100)
; #define Can1_TxBufferRd5         CAN1_CONTROLLER(101)
; #define Can1_TxBufferRd6         CAN1_CONTROLLER(102)
; #define Can1_TxBufferRd7         CAN1_CONTROLLER(103)
; #define Can1_TxBufferRd8         CAN1_CONTROLLER(104)
; #define Can1_TxBufferRd9         CAN1_CONTROLLER(105)
; #define Can1_TxBufferRd10        CAN1_CONTROLLER(106)
; #define Can1_TxBufferRd11        CAN1_CONTROLLER(107)
; #define Can1_TxBufferRd12        CAN1_CONTROLLER(108)
; /* bit definitions for the Mode & Control Register */
; #define RM_RR_Bit 0x01 /* reset mode (request) bit */
; #define LOM_Bit 0x02 /* listen only mode bit */
; #define STM_Bit 0x04 /* self test mode bit */
; #define AFM_Bit 0x08 /* acceptance filter mode bit */
; #define SM_Bit  0x10 /* enter sleep mode bit */
; /* bit definitions for the Interrupt Enable & Control Register */
; #define RIE_Bit 0x01 /* receive interrupt enable bit */
; #define TIE_Bit 0x02 /* transmit interrupt enable bit */
; #define EIE_Bit 0x04 /* error warning interrupt enable bit */
; #define DOIE_Bit 0x08 /* data overrun interrupt enable bit */
; #define WUIE_Bit 0x10 /* wake-up interrupt enable bit */
; #define EPIE_Bit 0x20 /* error passive interrupt enable bit */
; #define ALIE_Bit 0x40 /* arbitration lost interr. enable bit*/
; #define BEIE_Bit 0x80 /* bus error interrupt enable bit */
; /* bit definitions for the Command Register */
; #define TR_Bit 0x01 /* transmission request bit */
; #define AT_Bit 0x02 /* abort transmission bit */
; #define RRB_Bit 0x04 /* release receive buffer bit */
; #define CDO_Bit 0x08 /* clear data overrun bit */
; #define SRR_Bit 0x10 /* self reception request bit */
; /* bit definitions for the Status Register */
; #define RBS_Bit 0x01 /* receive buffer status bit */
; #define DOS_Bit 0x02 /* data overrun status bit */
; #define TBS_Bit 0x04 /* transmit buffer status bit */
; #define TCS_Bit 0x08 /* transmission complete status bit */
; #define RS_Bit 0x10 /* receive status bit */
; #define TS_Bit 0x20 /* transmit status bit */
; #define ES_Bit 0x40 /* error status bit */
; #define BS_Bit 0x80 /* bus status bit */
; /* bit definitions for the Interrupt Register */
; #define RI_Bit 0x01 /* receive interrupt bit */
; #define TI_Bit 0x02 /* transmit interrupt bit */
; #define EI_Bit 0x04 /* error warning interrupt bit */
; #define DOI_Bit 0x08 /* data overrun interrupt bit */
; #define WUI_Bit 0x10 /* wake-up interrupt bit */
; #define EPI_Bit 0x20 /* error passive interrupt bit */
; #define ALI_Bit 0x40 /* arbitration lost interrupt bit */
; #define BEI_Bit 0x80 /* bus error interrupt bit */
; /* bit definitions for the Bus Timing Registers */
; #define SAM_Bit 0x80                        /* sample mode bit 1 == the bus is sampled 3 times, 0 == the bus is sampled once */
; /* bit definitions for the Output Control Register OCMODE1, OCMODE0 */
; #define BiPhaseMode 0x00 /* bi-phase output mode */
; #define NormalMode 0x02 /* normal output mode */
; #define ClkOutMode 0x03 /* clock output mode */
; /* output pin configuration for TX1 */
; #define OCPOL1_Bit 0x20 /* output polarity control bit */
; #define Tx1Float 0x00 /* configured as float */
; #define Tx1PullDn 0x40 /* configured as pull-down */
; #define Tx1PullUp 0x80 /* configured as pull-up */
; #define Tx1PshPull 0xC0 /* configured as push/pull */
; /* output pin configuration for TX0 */
; #define OCPOL0_Bit 0x04 /* output polarity control bit */
; #define Tx0Float 0x00 /* configured as float */
; #define Tx0PullDn 0x08 /* configured as pull-down */
; #define Tx0PullUp 0x10 /* configured as pull-up */
; #define Tx0PshPull 0x18 /* configured as push/pull */
; /* bit definitions for the Clock Divider Register */
; #define DivBy1 0x07 /* CLKOUT = oscillator frequency */
; #define DivBy2 0x00 /* CLKOUT = 1/2 oscillator frequency */
; #define ClkOff_Bit 0x08 /* clock off bit, control of the CLK OUT pin */
; #define RXINTEN_Bit 0x20 /* pin TX1 used for receive interrupt */
; #define CBP_Bit 0x40 /* CAN comparator bypass control bit */
; #define CANMode_Bit 0x80 /* CAN mode definition bit */
; /*- definition of used constants ---------------------------------------*/
; #define YES 1
; #define NO 0
; #define ENABLE 1
; #define DISABLE 0
; #define ENABLE_N 0
; #define DISABLE_N 1
; #define INTLEVELACT 0
; #define INTEDGEACT 1
; #define PRIORITY_LOW 0
; #define PRIORITY_HIGH 1
; /* default (reset) value for register content, clear register */
; #define ClrByte 0x00
; /* constant: clear Interrupt Enable Register */
; #define ClrIntEnSJA ClrByte
; /* definitions for the acceptance code and mask register */
; #define DontCare 0xFF
; /*  bus timing values for
; **  bit-rate : 100 kBit/s
; **  oscillator frequency : 25 MHz, 1 sample per bit, 0 tolerance %
; **  maximum tolerated propagation delay : 4450 ns
; **  minimum requested propagation delay : 500 ns
; **
; **  https://www.kvaser.com/support/calculators/bit-timing-calculator/
; **  T1 	T2 	BTQ 	SP% 	SJW 	BIT RATE 	ERR% 	BTR0 	BTR1
; **  17	8	25	    68	     1	      100	    0	      04	7f
; */
; /*************************************************************
; ** SPI Controller registers
; **************************************************************/
; // SPI Registers
; #define SPI_Control         (*(volatile unsigned char *)(0x00408020))
; #define SPI_Status          (*(volatile unsigned char *)(0x00408022))
; #define SPI_Data            (*(volatile unsigned char *)(0x00408024))
; #define SPI_Ext             (*(volatile unsigned char *)(0x00408026))
; #define SPI_CS              (*(volatile unsigned char *)(0x00408028))
; // these two macros enable or disable the flash memory chip enable off SSN_O[7..0]
; // in this case we assume there is only 1 device connected to SSN_O[0] so we can
; // write hex FE to the SPI_CS to enable it (the enable on the flash chip is active low)
; // and write FF to disable it
; #define   Enable_SPI_CS()             SPI_CS = 0xFE
; #define   Disable_SPI_CS()            SPI_CS = 0xFF
; // SPI flash chip commands
; #define write_enable_cmd 0x06
; #define erasing_cmd  0xc7
; #define read_cmd  0x03
; #define write_cmd  0x02
; #define check_status_cmd 0x05
; /*************************************************************
; ** final project VGA
; **************************************************************/
; #define vga_ram_start         (*(volatile unsigned char *)(0x00600000))
; #define vga_x_cursor_reg          (*(volatile unsigned char *)(0x00601000))
; #define vga_y_cursor_reg            (*(volatile unsigned char *)(0x00601002))
; #define vga_ctrl_reg             (*(volatile unsigned char *)(0x00601004))
; /*********************************************************************************************************************************
; * 
; * 
; (( DO NOT initialise global variables here, do it main even if you want 0
; (( it's a limitation of the compiler
; (( YOU HAVE BEEN WARNED
; *********************************************************************************************************************************/
; unsigned int i, x, y, z, PortA_Count;
; unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;
; unsigned char switch_counter, eeprom_counter, flash_counter;
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
; ** CAN bus functions
; *******************************************************************************************/
; // initialisation for Can controller 0
; void Init_CanBus_Controller0(void)
; {
       section   code
       xdef      _Init_CanBus_Controller0
_Init_CanBus_Controller0:
; // TODO - put your Canbus initialisation code for CanController 0 here
; // See section 4.2.1 in the application note for details (PELICAN MODE)
; //printf("\r\nInitializing Can controller 0");
; while((Can0_ModeControlReg & RM_RR_Bit ) == ClrByte)
Init_CanBus_Controller0_1:
       move.b    5242880,D0
       and.b     #1,D0
       bne.s     Init_CanBus_Controller0_3
; {
; Can0_ModeControlReg = Can0_ModeControlReg | RM_RR_Bit;
       move.b    5242880,D0
       or.b      #1,D0
       move.b    D0,5242880
       bra       Init_CanBus_Controller0_1
Init_CanBus_Controller0_3:
; }
; Can0_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy1;
       move.b    #199,5242942
; Can0_InterruptEnReg = ClrIntEnSJA;
       clr.b     5242888
; Can0_AcceptCode0Reg = ClrByte;
       clr.b     5242912
; Can0_AcceptCode1Reg = ClrByte;
       clr.b     5242914
; Can0_AcceptCode2Reg = ClrByte;
       clr.b     5242916
; Can0_AcceptCode3Reg = ClrByte;
       clr.b     5242918
; Can0_AcceptMask0Reg = DontCare;
       move.b    #255,5242920
; Can0_AcceptMask1Reg = DontCare;
       move.b    #255,5242922
; Can0_AcceptMask2Reg = DontCare;
       move.b    #255,5242924
; Can0_AcceptMask3Reg = DontCare;
       move.b    #255,5242926
; // see the comment on line 275
; Can0_BusTiming0Reg = 0x04;
       move.b    #4,5242892
; Can0_BusTiming1Reg = 0x7f;
       move.b    #127,5242894
; Can0_OutControlReg = Tx0Float | Tx0PshPull | NormalMode;
       move.b    #26,5242896
; while ((Can0_ModeControlReg & RM_RR_Bit) != ClrByte)
Init_CanBus_Controller0_4:
       move.b    5242880,D0
       and.b     #1,D0
       beq.s     Init_CanBus_Controller0_6
; {
; Can0_ModeControlReg = ClrByte;
       clr.b     5242880
       bra       Init_CanBus_Controller0_4
Init_CanBus_Controller0_6:
       rts
; }
; }
; // initialisation for Can controller 1
; void Init_CanBus_Controller1(void)
; {
       xdef      _Init_CanBus_Controller1
_Init_CanBus_Controller1:
; // TODO - put your Canbus initialisation code for CanController 1 here
; // See section 4.2.1 in the application note for details (PELICAN MODE)
; //printf("\r\nInitializing Can controller 1");
; while((Can1_ModeControlReg & RM_RR_Bit ) == ClrByte)
Init_CanBus_Controller1_1:
       move.b    5243392,D0
       and.b     #1,D0
       bne.s     Init_CanBus_Controller1_3
; {
; Can1_ModeControlReg = Can1_ModeControlReg | RM_RR_Bit;
       move.b    5243392,D0
       or.b      #1,D0
       move.b    D0,5243392
       bra       Init_CanBus_Controller1_1
Init_CanBus_Controller1_3:
; }
; Can1_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy1;
       move.b    #199,5243454
; Can1_InterruptEnReg = ClrIntEnSJA;
       clr.b     5243400
; Can1_AcceptCode0Reg = ClrByte;
       clr.b     5243424
; Can1_AcceptCode1Reg = ClrByte;
       clr.b     5243426
; Can1_AcceptCode2Reg = ClrByte;
       clr.b     5243428
; Can1_AcceptCode3Reg = ClrByte;
       clr.b     5243430
; Can1_AcceptMask0Reg = DontCare;
       move.b    #255,5243432
; Can1_AcceptMask1Reg = DontCare;
       move.b    #255,5243434
; Can1_AcceptMask2Reg = DontCare;
       move.b    #255,5243436
; Can1_AcceptMask3Reg = DontCare;
       move.b    #255,5243438
; // see the comment on line 275
; Can1_BusTiming0Reg = 0x04;
       move.b    #4,5243404
; Can1_BusTiming1Reg = 0x7f;
       move.b    #127,5243406
; Can1_OutControlReg = Tx1Float | Tx1PshPull | NormalMode;
       move.b    #194,5243408
; while ((Can1_ModeControlReg & RM_RR_Bit) != ClrByte)
Init_CanBus_Controller1_4:
       move.b    5243392,D0
       and.b     #1,D0
       beq.s     Init_CanBus_Controller1_6
; {
; Can1_ModeControlReg = ClrByte;
       clr.b     5243392
       bra       Init_CanBus_Controller1_4
Init_CanBus_Controller1_6:
       rts
; }
; }
; // Transmit for sending a message via Can controller 0
; void CanBus0_Transmit(unsigned char data)
; {
       xdef      _CanBus0_Transmit
_CanBus0_Transmit:
       link      A6,#0
; // TODO - put your Canbus transmit code for CanController 0 here
; // See section 4.2.2 in the application note for details (PELICAN MODE)
; //printf("\r\nTransmitting Can controller 0");
; while((Can0_StatusReg & TBS_Bit ) != TBS_Bit ) {}
CanBus0_Transmit_1:
       move.b    5242884,D0
       and.b     #4,D0
       cmp.b     #4,D0
       beq.s     CanBus0_Transmit_3
       bra       CanBus0_Transmit_1
CanBus0_Transmit_3:
; // frame format = 0 (standard), RTR = 0 (data framee), DLC = b'1000 (8 bytes), see data sheet page 40-41
; Can0_TxFrameInfo = 0x08;
       move.b    #8,5242912
; // 11 bits identifier, don't care, since we don't have filtering
; Can0_TxBuffer1 = 0x00;
       clr.b     5242914
; Can0_TxBuffer2 = 0x00;
       clr.b     5242916
; // 8 bytes data;
; Can0_TxBuffer3 = data;
       move.b    11(A6),5242918
; /*Can0_TxBuffer4 = 0x01;
; Can0_TxBuffer5 = 0x02;
; Can0_TxBuffer6 = 0x03;
; Can0_TxBuffer7 = 0x04;
; Can0_TxBuffer8 = 0x05;
; Can0_TxBuffer9 = 0x06;
; Can0_TxBuffer10 = 0x07;*/
; Can0_CommandReg = TR_Bit;
       move.b    #1,5242882
; // wait for the transmission to complete
; while((Can0_StatusReg & TCS_Bit ) != TCS_Bit ) {}
CanBus0_Transmit_4:
       move.b    5242884,D0
       and.b     #8,D0
       cmp.b     #8,D0
       beq.s     CanBus0_Transmit_6
       bra       CanBus0_Transmit_4
CanBus0_Transmit_6:
       unlk      A6
       rts
; }
; // Transmit for sending a message via Can controller 1
; void CanBus1_Transmit(void)
; {
       xdef      _CanBus1_Transmit
_CanBus1_Transmit:
; // TODO - put your Canbus transmit code for CanController 1 here
; // See section 4.2.2 in the application note for details (PELICAN MODE)
; //printf("\r\nTransmitting Can controller 1");
; while((Can1_StatusReg & TBS_Bit ) != TBS_Bit ) {}
CanBus1_Transmit_1:
       move.b    5243396,D0
       and.b     #4,D0
       cmp.b     #4,D0
       beq.s     CanBus1_Transmit_3
       bra       CanBus1_Transmit_1
CanBus1_Transmit_3:
; // frame format = 0 (standard), RTR = 0 (data framee), DLC = b'1000 (8 bytes), see data sheet page 40-41
; Can1_TxFrameInfo = 0x08;
       move.b    #8,5243424
; // 11 bits identifier, don't care, since we don't have filtering
; Can1_TxBuffer1 = 0x00;
       clr.b     5243426
; Can1_TxBuffer2 = 0x00;
       clr.b     5243428
; // 8 bytes data;
; Can1_TxBuffer3 = 0x07;
       move.b    #7,5243430
; Can1_TxBuffer4 = 0x06;
       move.b    #6,5243432
; Can1_TxBuffer5 = 0x05;
       move.b    #5,5243434
; Can1_TxBuffer6 = 0x04;
       move.b    #4,5243436
; Can1_TxBuffer7 = 0x03;
       move.b    #3,5243438
; Can1_TxBuffer8 = 0x02;
       move.b    #2,5243440
; Can1_TxBuffer9 = 0x01;
       move.b    #1,5243442
; Can1_TxBuffer10 = 0x00;
       clr.b     5243444
; Can1_CommandReg = TR_Bit;
       move.b    #1,5243394
; // wait for the transmission to complete
; while((Can1_StatusReg & TCS_Bit ) != TCS_Bit ) {}
CanBus1_Transmit_4:
       move.b    5243396,D0
       and.b     #8,D0
       cmp.b     #8,D0
       beq.s     CanBus1_Transmit_6
       bra       CanBus1_Transmit_4
CanBus1_Transmit_6:
       rts
; }
; // Receive for reading a received message via Can controller 0
; void CanBus0_Receive(void)
; {
       xdef      _CanBus0_Receive
_CanBus0_Receive:
       move.l    A2,-(A7)
       lea       _printf.L,A2
; // TODO - put your Canbus receive code for CanController 0 here
; // See section 4.2.4 in the application note for details (PELICAN MODE)
; // wait for the receiver buffer to be full
; //printf("\r\nReading Can controller 0");
; while ((Can0_StatusReg & RBS_Bit) != RBS_Bit) {}
CanBus0_Receive_1:
       move.b    5242884,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     CanBus0_Receive_3
       bra       CanBus0_Receive_1
CanBus0_Receive_3:
; printf("\r\n%x",Can0_RxBuffer3);
       move.b    5242918,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n%x",Can0_RxBuffer4);
       move.b    5242920,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n%x",Can0_RxBuffer5);
       move.b    5242922,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n%x",Can0_RxBuffer6);
       move.b    5242924,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n%x",Can0_RxBuffer7);
       move.b    5242926,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n%x",Can0_RxBuffer8);
       move.b    5242928,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n%x",Can0_RxBuffer9);
       move.b    5242930,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n%x",Can0_RxBuffer10);
       move.b    5242932,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
; Can0_CommandReg = RRB_Bit;
       move.b    #4,5242882
       move.l    (A7)+,A2
       rts
; }
; // Receive for reading a received message via Can controller 1
; void CanBus1_Receive(void)
; {
       xdef      _CanBus1_Receive
_CanBus1_Receive:
; // TODO - put your Canbus receive code for CanController 1 here
; // See section 4.2.4 in the application note for details (PELICAN MODE)
; //printf("\r\nReading Can controller 1");
; while ((Can1_StatusReg & RBS_Bit) != RBS_Bit) {}
CanBus1_Receive_1:
       move.b    5243396,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     CanBus1_Receive_3
       bra       CanBus1_Receive_1
CanBus1_Receive_3:
; printf("\r\n%x",Can1_RxBuffer3);
       move.b    5243430,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_1.L
       jsr       _printf
       addq.w    #8,A7
; /*printf("\r\n%x",Can1_RxBuffer4);
; printf("\r\n%x",Can1_RxBuffer5);
; printf("\r\n%x",Can1_RxBuffer6);
; printf("\r\n%x",Can1_RxBuffer7);
; printf("\r\n%x",Can1_RxBuffer8);
; printf("\r\n%x",Can1_RxBuffer9);
; printf("\r\n%x",Can1_RxBuffer10);*/
; Can1_CommandReg = RRB_Bit;
       move.b    #4,5243394
       rts
; }
; void CanBusTest(void)
; {
       xdef      _CanBusTest
_CanBusTest:
       move.l    A2,-(A7)
       lea       _printf.L,A2
; // initialise the two Can controllers
; Init_CanBus_Controller0();
       jsr       _Init_CanBus_Controller0
; Init_CanBus_Controller1();
       jsr       _Init_CanBus_Controller1
; printf("\r\n\r\n---- CANBUS Test ----\r\n") ;
       pea       @m68kus~1_2.L
       jsr       (A2)
       addq.w    #4,A7
; // simple application to alternately transmit and receive messages from each of two nodes
; Wait500ms ();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly
       jsr       _Wait500ms
; //CanBus0_Transmit() ;       // transmit a message via Controller 0
; CanBus1_Receive() ;        // receive a message via Controller 1 (and display it)
       jsr       _CanBus1_Receive
; printf("\r\n") ;
       pea       @m68kus~1_3.L
       jsr       (A2)
       addq.w    #4,A7
; Wait500ms ();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly
       jsr       _Wait500ms
; CanBus1_Transmit() ;        // transmit a message via Controller 1
       jsr       _CanBus1_Transmit
; CanBus0_Receive() ;         // receive a message via Controller 0 (and display it)
       jsr       _CanBus0_Receive
; printf("\r\n") ;
       pea       @m68kus~1_3.L
       jsr       (A2)
       addq.w    #4,A7
       move.l    (A7)+,A2
       rts
; }
; /*******************************************************************************************
; ** I2C functions
; *******************************************************************************************/
; unsigned int ask_EEPROM_internal_addr(void){
       xdef      _ask_EEPROM_internal_addr
_ask_EEPROM_internal_addr:
       movem.l   D2/D3,-(A7)
; // ask the internal EEPROM address, return an array, storing the upper byte at location 0, and the lower byte at 1, the block select at 2
; int valid = 0;
       clr.l     D3
; unsigned int addr;
; printf("\r\nWhat is the internal EEPROM address you want to access? ");
       pea       @m68kus~1_4.L
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
       pea       @m68kus~1_5.L
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
       pea       @m68kus~1_6.L
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
       pea       @m68kus~1_7.L
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
       pea       @m68kus~1_8.L
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
       pea       @m68kus~1_9.L
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
       pea       @m68kus~1_10.L
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
       pea       @m68kus~1_11.L
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
       pea       @m68kus~1_12.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     ask_EEPROM_addr_range_7
ask_EEPROM_addr_range_4:
; } else if (size == 0) {
       tst.l     D2
       bne.s     ask_EEPROM_addr_range_6
; printf("\r\nSize cannot be 0, the minimum size is 'h000001 (1 byte), input again: ");
       pea       @m68kus~1_13.L
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
       pea       @m68kus~1_14.L
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
       pea       @m68kus~1_15.L
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
       pea       @m68kus~1_16.L
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
       pea       @m68kus~1_17.L
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
       pea       @m68kus~1_18.L
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
       pea       @m68kus~1_19.L
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
       pea       @m68kus~1_20.L
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
       pea       @m68kus~1_21.L
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
       pea       @m68kus~1_22.L
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
       pea       @m68kus~1_23.L
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
; /******************************************************************************************
; ** The following code is for the SPI controller
; *******************************************************************************************/
; // return true if the SPI has finished transmitting a byte (to say the Flash chip) return false otherwise
; // this can be used in a polling algorithm to know when the controller is busy or idle.
; int TestForSPITransmitDataComplete(void)    {
       xdef      _TestForSPITransmitDataComplete
_TestForSPITransmitDataComplete:
       link      A6,#-8
; /* TODO replace 0 below with a test for status register SPIF bit and if set, return true */
; int result; 
; int status;
; status = SPI_Status;
       move.b    4227106,D0
       and.l     #255,D0
       move.l    D0,-4(A6)
; //printf("\r\nSPI status reg: %d",status); 
; result = status & 0x80; // get the SPIF bit, if SPIF == 1, then transmit is completed, if 0, then not completed. 
       move.l    -4(A6),D0
       and.l     #128,D0
       move.l    D0,-8(A6)
; return result;
       move.l    -8(A6),D0
       unlk      A6
       rts
; }
; /************************************************************************************
; ** initialises the SPI controller chip to set speed, interrupt capability etc.
; ************************************************************************************/
; void SPI_Init(void)
; {
       xdef      _SPI_Init
_SPI_Init:
; //TODO
; //
; // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
; // Don't forget to call this routine from main() before you do anything else with SPI
; //
; // Here are some settings we want to create
; //
; // Control Reg     - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed =  divide by 32 = approx 700Khz
; // Ext Reg         - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
; // SPI_CS Reg      - control selection of slave SPI chips via their CS# signals
; // Status Reg      - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag
; SPI_Control = 0x53;
       move.b    #83,4227104
; SPI_Ext = 0x00;
       clr.b     4227110
; Disable_SPI_CS(); // Disable the flash chip during initialisation 
       move.b    #255,4227112
; SPI_Status = 0xc0;
       move.b    #192,4227106
       rts
; }
; /************************************************************************************
; ** return ONLY when the SPI controller has finished transmitting a byte
; ************************************************************************************/
; void WaitForSPITransmitComplete(void)
; {
       xdef      _WaitForSPITransmitComplete
_WaitForSPITransmitComplete:
       move.l    D2,-(A7)
; // TODO : poll the status register SPIF bit looking for completion of transmission
; // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
; // just in case they were set
; int SPITransmitComplete = 0;
       clr.l     D2
; while (!SPITransmitComplete)
WaitForSPITransmitComplete_1:
       tst.l     D2
       bne.s     WaitForSPITransmitComplete_3
; {
; SPITransmitComplete = TestForSPITransmitDataComplete();
       jsr       _TestForSPITransmitDataComplete
       move.l    D0,D2
       bra       WaitForSPITransmitComplete_1
WaitForSPITransmitComplete_3:
; //printf("\r\nSPI data transmit complete: %d", SPITransmitComplete);
; }
; SPI_Status = 0xc0;
       move.b    #192,4227106
       move.l    (A7)+,D2
       rts
; }
; /************************************************************************************
; ** Write a byte to the SPI flash chip via the controller and returns (reads) whatever was
; ** given back by SPI device at the same time (removes the read byte from the FIFO)
; ************************************************************************************/
; int WriteSPIChar(int c)
; {
       xdef      _WriteSPIChar
_WriteSPIChar:
       link      A6,#0
       move.l    D2,-(A7)
; // todo - write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
; // wait for completion of transmission
; // return the received data from Flash chip (which may not be relevent depending upon what we are doing)
; // by reading fom the SPI controller Data Register.
; // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
; //
; // modify '0' below to return back read byte from data register
; //
; int read_data = 0; 
       clr.l     D2
; SPI_Data = c; 
       move.l    8(A6),D0
       move.b    D0,4227108
; WaitForSPITransmitComplete();
       jsr       _WaitForSPITransmitComplete
; read_data = SPI_Data;
       move.b    4227108,D0
       and.l     #255,D0
       move.l    D0,D2
; return read_data;                   
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; // send a command to the flash chip 
; void send_spi_cmd(int c){
       xdef      _send_spi_cmd
_send_spi_cmd:
       link      A6,#-4
; int read_data;
; Enable_SPI_CS();
       move.b    #254,4227112
; read_data = WriteSPIChar(c);
       move.l    8(A6),-(A7)
       jsr       _WriteSPIChar
       addq.w    #4,A7
       move.l    D0,-4(A6)
; Disable_SPI_CS();
       move.b    #255,4227112
       unlk      A6
       rts
; }
; /*Check the flash chip's status register*/
; void wait_for_flash_status_done(void)
; {
       xdef      _wait_for_flash_status_done
_wait_for_flash_status_done:
       link      A6,#-4
; int dummy_byte = 0x00;
       clr.l     -4(A6)
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(check_status_cmd); // send the check flash status register cmd
       pea       5
       jsr       _WriteSPIChar
       addq.w    #4,A7
; while(WriteSPIChar(dummy_byte) & 0x01){
wait_for_flash_status_done_1:
       move.l    -4(A6),-(A7)
       jsr       _WriteSPIChar
       addq.w    #4,A7
       and.l     #1,D0
       beq.s     wait_for_flash_status_done_3
; }
       bra       wait_for_flash_status_done_1
wait_for_flash_status_done_3:
; Disable_SPI_CS();
       move.b    #255,4227112
       unlk      A6
       rts
; }
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; unsigned char flash_read(unsigned char addr){
       xdef      _flash_read
_flash_read:
       link      A6,#-16
       move.l    A2,-(A7)
       lea       _WriteSPIChar.L,A2
; int i;
; unsigned char dram_data;
; int flash_data;
; int dummy_byte = 0x00;
       clr.l     -4(A6)
; //volatile unsigned char* current_address;
; //volatile unsigned char* dram_start_address = (volatile unsigned char*) (start_of_dram);
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(read_cmd); // read cmd
       pea       3
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(0x00);
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(0x00);
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(addr);
       move.b    11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; flash_data = WriteSPIChar(dummy_byte);
       move.l    -4(A6),-(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,-8(A6)
; Disable_SPI_CS();
       move.b    #255,4227112
; return flash_data;
       move.l    -8(A6),D0
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; unsigned char EEPROM_read (unsigned char addr) {
       xdef      _EEPROM_read
_EEPROM_read:
       link      A6,#-4
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _I2C_TX_command_status.L,A2
       move.b    11(A6),D4
       and.w     #255,D4
; char slave_addr_RW;
; unsigned char slave_read_data;
; unsigned char EEPROM_block_select;
; unsigned char EEPROM_internal_addr_H, EEPROM_internal_addr_L;
; EEPROM_internal_addr_H = (addr & 0x00ff00) >> 8;
       move.b    D4,D0
       and.w     #255,D0
       and.w     #65280,D0
       lsr.w     #8,D0
       move.b    D0,-2(A6)
; EEPROM_internal_addr_L = addr & 0x0000ff;
       move.b    D4,D0
       and.w     #255,D0
       and.w     #255,D0
       move.b    D0,-1(A6)
; EEPROM_block_select = (addr & 0x010000) >> 16;
       move.b    D4,D0
       and.l     #255,D0
       and.l     #65536,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.b    D0,D3
; // EEPROM tag (b'1010) + chip select ('b00) + block select + write (0)
; slave_addr_RW = (0xa0 | (EEPROM_block_select << 1));
       move.w    #160,D0
       move.b    D3,D1
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
       move.b    D3,D1
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
EEPROM_read_1:
       move.b    4227080,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     EEPROM_read_3
       bra       EEPROM_read_1
EEPROM_read_3:
; slave_read_data = I2C_RX_reg;
       move.b    4227078,-3(A6)
; return slave_read_data;
       move.b    -3(A6),D0
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; void Timer_ISR(void)
; {
       xdef      _Timer_ISR
_Timer_ISR:
       movem.l   A2/A3/A4,-(A7)
       lea       _CanBus1_Receive.L,A2
       lea       _CanBus0_Transmit.L,A3
       lea       _printf.L,A4
; if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
       move.b    4194358,D0
       cmp.b     #1,D0
       bne       Timer_ISR_7
; Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194358
; switch_counter ++;
       addq.b    #1,_switch_counter.L
; eeprom_counter ++;
       addq.b    #1,_eeprom_counter.L
; flash_counter ++;
       addq.b    #1,_flash_counter.L
; if (switch_counter == 1)
       move.b    _switch_counter.L,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_3
; {   
; printf("\r\nReading switches");
       pea       @m68kus~1_24.L
       jsr       (A4)
       addq.w    #4,A7
; CanBus0_Transmit(PortA);     // read the value from the switches and broadcast using CANBUS controller 0
       move.b    4194304,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; CanBus1_Receive();
       jsr       (A2)
; switch_counter = 0;
       clr.b     _switch_counter.L
Timer_ISR_3:
; }
; if (eeprom_counter == 5)
       move.b    _eeprom_counter.L,D0
       cmp.b     #5,D0
       bne       Timer_ISR_5
; {
; printf("\r\nReading from address %x of EEPROM", PortA);
       move.b    4194304,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_25.L
       jsr       (A4)
       addq.w    #8,A7
; CanBus0_Transmit(EEPROM_read(PortA));
       move.l    D0,-(A7)
       move.b    4194304,D0
       and.l     #255,D0
       move.l    D0,-(A7)
       jsr       _EEPROM_read
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; CanBus1_Receive();
       jsr       (A2)
; eeprom_counter = 0;
       clr.b     _eeprom_counter.L
Timer_ISR_5:
; }
; if (flash_counter == 20)
       move.b    _flash_counter.L,D0
       cmp.b     #20,D0
       bne       Timer_ISR_7
; {
; printf("\r\nReading from address %x of flash", PortA);
       move.b    4194304,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_26.L
       jsr       (A4)
       addq.w    #8,A7
; CanBus0_Transmit(flash_read(PortA));
       move.l    D0,-(A7)
       move.b    4194304,D0
       and.l     #255,D0
       move.l    D0,-(A7)
       jsr       _flash_read
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; CanBus1_Receive();
       jsr       (A2)
; flash_counter = 0;
       clr.b     _flash_counter.L
Timer_ISR_7:
       movem.l   (A7)+,A2/A3/A4
       rts
; }
; }
; /*	if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
; Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
; HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
; }
; if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
; Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
; HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
; }*/
; }
; /*
; void read_switch_timer8_ISR(void)
; {   
; printf("\r\nRead switch");
; if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
; Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
; CanBus0_Transmit(PortA);     // read the value from the switches and broadcast using CANBUS controller 0
; CanBus1_Receive();
; }
; }*/
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
; * VGA functions
; ******************************************************************************************************************************/
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
       pea       @m68kus~1_27.L
       pea       18
       pea       36
       jsr       (A2)
       add.w     #12,A7
; string_cursor(35,20, "Score: ");
       pea       @m68kus~1_28.L
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
       pea       @m68kus~1_28.L
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
; int bol = 1;
       moveq     #1,D3
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
; while (bol)
generateFood_4:
       tst.l     D3
       beq       generateFood_6
; {
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
generateFood_7:
       cmp.l     16384(A2),D2
       bge.s     generateFood_9
; {
; if (Snake.food.x == Snake.xy[i].x && Snake.food.y == Snake.xy[i].y) {
       move.l    D2,D0
       lsl.l     #3,D0
       move.l    16398(A2),D1
       cmp.l     0(A2,D0.L),D1
       bne.s     generateFood_10
       move.l    D2,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A0
       move.l    16402(A2),D0
       cmp.l     4(A0),D0
       bne.s     generateFood_10
; bol = 1; //resets loop if collision detected
       moveq     #1,D3
generateFood_10:
       addq.l    #1,D2
       bra       generateFood_7
generateFood_9:
       bra       generateFood_4
generateFood_6:
; }
; }
; }//while colliding with snake
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
; /******************************************************************************************************************************
; * Start of user program
; ******************************************************************************************************************************/
; void main()
; {   
       xdef      _main
_main:
       link      A6,#-180
       move.l    A2,-(A7)
       lea       _InstallExceptionHandler.L,A2
; unsigned int row, i=0, count=0, counter1=1;
       clr.l     -176(A6)
       clr.l     -172(A6)
       move.l    #1,-168(A6)
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
       clr.l     -176(A6)
; Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;
       clr.b     _Timer4Count.L
       clr.b     _Timer3Count.L
       clr.b     _Timer2Count.L
       clr.b     _Timer1Count.L
; switch_counter = 0;
       clr.b     _switch_counter.L
; eeprom_counter = 0;
       clr.b     _eeprom_counter.L
; flash_counter = 0;
       clr.b     _flash_counter.L
; //Init_CanBus_Controller0();
; //Init_CanBus_Controller1();
; //I2C_init (); // initialise the I2C controller
; //SPI_Init(); // initialise the SPI controller
; //I2C_multi_write();
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
; //InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
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
; InstallExceptionHandler(clock, 30); // install interruot handler for Timer 2 on level 6 IRQ
       pea       30
       pea       _clock.L
       jsr       (A2)
       addq.w    #8,A7
; //Timer1Data = 0x10;		// program time delay into timers 1-4
; //Timer2Data = 0x25; // 100ms
; //Timer3Data = 0xbd; // 500ms
; //Timer4Data = 0x25; //
; Timer2Data = 0x03; // 10ms
       move.b    #3,4194356
; //Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
; Timer2Control = 3;
       move.b    #3,4194358
; //Timer3Control = 3;
; //Timer4Control = 3;
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
       move.l    (A7)+,A2
       unlk      A6
       rts
; //vga_x_cursor_reg = 0x28;
; //vga_y_cursor_reg = 0x14;
; /*gotoxy(79,39);
; //putcharxy(0,0, 0x24);
; cls();
; print_at_xy(0,0,"Luyao, I love you 10000 years");
; drawRect(1,1,79,38,'#');
; for (score=0;score<70;score++){
; updateScore();
; delay_ms(50);
; }
; gameOver();*/
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
; /*while(1) {
; valid = 0;
; while (!valid) {
; printf("\r\nWhich function you want to run?\n1.EEPROM single byte write\n2.EEPROM single byte read\n3.EEPROM page write\n4.EEPROM page read\n5.DAC->LED\n6.ADC<-sensors ");
; f = Get1HexDigits(0);
; if (f >= 1 && f <= 6) {
; valid = 1;
; } else {
; printf("\r\nInvalid selection! ");
; valid = 0;
; }
; }
; if (f == 1){
; I2C_byte_write();
; } else if (f == 2){
; I2C_byte_read();
; } else if (f == 3){
; I2C_multi_write();
; } else if (f == 4){
; I2C_multi_read();
; } else if (f == 5){
; DAC();
; } else if (f == 6){
; ADC();
; }
; }*/
; //while (1){}
; // programs should NOT exit as there is nothing to Exit TO !!!!!!
; // There is no OS - just press the reset button to end program and call debug
; }
       section   const
@m68kus~1_1:
       dc.b      13,10,37,120,0
@m68kus~1_2:
       dc.b      13,10,13,10,45,45,45,45,32,67,65,78,66,85,83
       dc.b      32,84,101,115,116,32,45,45,45,45,13,10,0
@m68kus~1_3:
       dc.b      13,10,0
@m68kus~1_4:
       dc.b      13,10,87,104,97,116,32,105,115,32,116,104,101
       dc.b      32,105,110,116,101,114,110,97,108,32,69,69,80
       dc.b      82,79,77,32,97,100,100,114,101,115,115,32,121
       dc.b      111,117,32,119,97,110,116,32,116,111,32,97,99
       dc.b      99,101,115,115,63,32,0
@m68kus~1_5:
       dc.b      13,10,65,100,100,114,101,115,115,32,99,97,110
       dc.b      110,111,116,32,98,101,32,103,114,101,97,116
       dc.b      101,114,32,116,104,97,110,32,48,120,48,49,102
       dc.b      102,102,102,33,32,73,110,112,117,116,32,97,103
       dc.b      97,105,110,58,32,0
@m68kus~1_6:
       dc.b      13,10,87,104,97,116,32,105,115,32,116,104,101
       dc.b      32,100,97,116,97,32,121,111,117,32,119,97,110
       dc.b      116,32,116,111,32,119,114,105,116,101,32,105
       dc.b      110,116,111,32,116,104,101,32,69,69,80,82,79
       dc.b      77,63,32,0
@m68kus~1_7:
       dc.b      13,10,82,97,110,100,111,109,32,69,69,80,82,79
       dc.b      77,32,98,121,116,101,32,119,114,105,116,101
       dc.b      0
@m68kus~1_8:
       dc.b      13,10,69,69,80,82,79,77,32,119,114,105,116,116
       dc.b      105,110,103,32,100,111,110,101,33,0
@m68kus~1_9:
       dc.b      13,10,82,97,110,100,111,109,32,69,69,80,82,79
       dc.b      77,32,98,121,116,101,32,114,101,97,100,0
@m68kus~1_10:
       dc.b      13,10,69,69,80,82,79,77,32,114,101,97,100,105
       dc.b      110,103,32,100,111,110,101,33,32,37,120,0
@m68kus~1_11:
       dc.b      13,10,87,104,97,116,32,105,115,32,116,104,101
       dc.b      32,69,69,80,82,79,77,32,97,100,100,114,101,115
       dc.b      115,32,114,97,110,103,101,32,115,105,122,101
       dc.b      32,40,105,110,32,104,101,120,41,32,121,111,117
       dc.b      32,119,97,110,116,32,116,111,32,97,99,99,101
       dc.b      115,115,63,32,0
@m68kus~1_12:
       dc.b      13,10,83,105,122,101,32,99,97,110,110,111,116
       dc.b      32,98,101,32,108,97,114,103,101,114,32,116,104
       dc.b      97,110,32,39,104,48,50,48,48,48,48,32,40,49
       dc.b      50,56,75,32,98,121,116,101,115,41,44,32,105
       dc.b      110,112,117,116,32,97,103,97,105,110,58,32,0
@m68kus~1_13:
       dc.b      13,10,83,105,122,101,32,99,97,110,110,111,116
       dc.b      32,98,101,32,48,44,32,116,104,101,32,109,105
       dc.b      110,105,109,117,109,32,115,105,122,101,32,105
       dc.b      115,32,39,104,48,48,48,48,48,49,32,40,49,32
       dc.b      98,121,116,101,41,44,32,105,110,112,117,116
       dc.b      32,97,103,97,105,110,58,32,0
@m68kus~1_14:
       dc.b      13,10,77,117,108,116,105,112,101,32,98,121,116
       dc.b      101,115,32,69,69,80,82,79,77,32,119,114,105
       dc.b      116,101,0
@m68kus~1_15:
       dc.b      13,10,87,114,105,116,116,105,110,103,46,46,46
       dc.b      0
@m68kus~1_16:
       dc.b      13,10,77,117,108,116,105,112,108,101,32,98,121
       dc.b      116,101,115,32,119,114,105,116,116,105,110,103
       dc.b      32,100,111,110,101,0
@m68kus~1_17:
       dc.b      13,10,77,117,108,116,105,112,108,101,32,98,121
       dc.b      116,101,115,32,69,69,80,82,79,77,32,114,101
       dc.b      97,100,0
@m68kus~1_18:
       dc.b      13,10,65,100,100,114,101,115,115,58,32,37,120
       dc.b      44,32,82,101,97,100,32,100,97,116,97,58,32,37
       dc.b      120,0
@m68kus~1_19:
       dc.b      13,10,85,115,105,110,103,32,68,65,67,32,116
       dc.b      111,32,99,111,110,116,114,111,108,32,76,69,68
       dc.b      0
@m68kus~1_20:
       dc.b      13,10,82,101,97,100,105,110,103,32,118,97,108
       dc.b      117,101,115,32,102,114,111,109,32,116,104,101
       dc.b      32,65,68,67,0
@m68kus~1_21:
       dc.b      13,10,82,101,97,100,32,100,97,116,97,58,32,37
       dc.b      120,0
@m68kus~1_22:
       dc.b      13,10,87,104,105,99,104,32,99,104,97,110,110
       dc.b      101,108,32,121,111,117,32,119,97,110,116,32
       dc.b      116,111,32,114,101,97,100,63,32,49,46,32,80
       dc.b      111,116,101,110,116,105,111,109,101,116,101
       dc.b      114,32,50,46,80,104,111,116,111,114,101,115
       dc.b      105,115,116,111,114,32,51,46,84,104,101,114
       dc.b      109,105,115,116,111,114,32,0
@m68kus~1_23:
       dc.b      13,10,73,110,118,97,108,105,100,32,115,101,108
       dc.b      101,99,116,105,111,110,33,0
@m68kus~1_24:
       dc.b      13,10,82,101,97,100,105,110,103,32,115,119,105
       dc.b      116,99,104,101,115,0
@m68kus~1_25:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,114,111
       dc.b      109,32,97,100,100,114,101,115,115,32,37,120
       dc.b      32,111,102,32,69,69,80,82,79,77,0
@m68kus~1_26:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,114,111
       dc.b      109,32,97,100,100,114,101,115,115,32,37,120
       dc.b      32,111,102,32,102,108,97,115,104,0
@m68kus~1_27:
       dc.b      97,109,101,32,79,118,101,114,33,0
@m68kus~1_28:
       dc.b      83,99,111,114,101,58,32,0
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
       xdef      _switch_counter
_switch_counter:
       ds.b      1
       xdef      _eeprom_counter
_eeprom_counter:
       ds.b      1
       xdef      _flash_counter
_flash_counter:
       ds.b      1
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
       xref      ULDIV
       xref      _printf
