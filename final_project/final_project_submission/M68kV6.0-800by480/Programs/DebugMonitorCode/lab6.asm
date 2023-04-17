; C:\IDE68K\UCOSII\LAB6.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; #include "Bios.h"
; #include "ucos_ii.h"
; #define STACKSIZE  256
; /*********************************************************************************************
; **	Hex 7 seg displays port addresses
; *********************************************************************************************/
; #define HEX_A        *(volatile unsigned char *)(0x00400010)
; #define HEX_B        *(volatile unsigned char *)(0x00400012)
; //#define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
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
; /* 
; ** Stacks for each task are allocated here in the application in this case = 256 bytes
; ** but you can change size if required
; */
; OS_STK Task1Stk[STACKSIZE];
; OS_STK Task2Stk[STACKSIZE];
; OS_STK Task3Stk[STACKSIZE];
; OS_STK Task4Stk[STACKSIZE];
; // Define a global mutex
; OS_EVENT *g_mutex;
; int err = OS_ERR_NONE;
; /* Prototypes for our tasks/threads*/
; void Task1(void *);	/* (void *) means the child task expects no data from parent*/
; void Task2(void *);
; void Task3(void *);
; void Task4(void *);
; int TestForSPITransmitDataComplete(void);
; void SPI_Init(void);
; void WaitForSPITransmitComplete(void);
; int WriteSPIChar(int c);
; void send_spi_cmd(int c);
; void wait_for_flash_status_done(void);
; unsigned char flash_read(unsigned char addr);
; void I2C_init (void);
; void I2C_TX_command_status (unsigned char data, unsigned char command);
; unsigned char EEPROM_read (unsigned char addr);
; void Init_CanBus_Controller0(void);
; void Init_CanBus_Controller1(void);
; void CanBus0_Transmit(unsigned char data);
; void CanBus1_Receive(void);
; /* 
; ** Our main application which has to
; ** 1) Initialise any peripherals on the board, e.g. RS232 for hyperterminal + LCD
; ** 2) Call OSInit() to initialise the OS
; ** 3) Create our application task/threads
; ** 4) Call OSStart()
; */
; void main(void)
; {
       section   code
       xdef      _main
_main:
       move.l    A2,-(A7)
       lea       _OSTaskCreate.L,A2
; // initialise board hardware by calling our routines from the BIOS.C source file
; Init_RS232();
       jsr       _Init_RS232
; Init_LCD();
       jsr       _Init_LCD
; SPI_Init();
       jsr       _SPI_Init
; I2C_init ();
       jsr       _I2C_init
; Init_CanBus_Controller0();
       jsr       _Init_CanBus_Controller0
; Init_CanBus_Controller1();
       jsr       _Init_CanBus_Controller1
; /* display welcome message on LCD display */
; Oline0("Altera DE1/68K");
       pea       @lab6_1.L
       jsr       _Oline0
       addq.w    #4,A7
; Oline1("Micrium uC/OS-II RTOS");
       pea       @lab6_2.L
       jsr       _Oline1
       addq.w    #4,A7
; OSInit();		// call to initialise the OS
       jsr       _OSInit
; g_mutex = OSMutexCreate(0, &err);
       pea       _err.L
       clr.l     -(A7)
       jsr       _OSMutexCreate
       addq.w    #8,A7
       move.l    D0,_g_mutex.L
; /* 
; ** Now create the 4 child tasks and pass them no data.
; ** the smaller the numerical priority value, the higher the task priority 
; */
; OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 12);     
       pea       12
       lea       _Task1Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task1.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 11);     // highest priority task
       pea       11
       lea       _Task2Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task2.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
       pea       13
       lea       _Task3Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task3.L
       jsr       (A2)
       add.w     #16,A7
; //OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14);	    // lowest priority task
; OSStart();  // call to start the OS scheduler, (never returns from this function)
       jsr       _OSStart
       move.l    (A7)+,A2
       rts
; }
; /*
; ** IMPORTANT : Timer 1 interrupts must be started by the highest priority task 
; ** that runs first which is Task2
; */
; void Task1(void *pdata)
; {   
       xdef      _Task1
_Task1:
       link      A6,#0
; for (;;) {
Task1_1:
; OSTimeDly(10); // 10 ticks = 100ms, given OS_TICKS_PER_SEC = 100
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
; OSMutexPend(g_mutex, 0, &err);
       pea       _err.L
       clr.l     -(A7)
       move.l    _g_mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; printf("\r\nReading switches");
       pea       @lab6_3.L
       jsr       _printf
       addq.w    #4,A7
; CanBus0_Transmit(PortA);     // read the value from the switches and broadcast using CANBUS controller 0
       move.b    4194304,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _CanBus0_Transmit
       addq.w    #4,A7
; CanBus1_Receive();
       jsr       _CanBus1_Receive
; OSMutexPost(g_mutex);
       move.l    _g_mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       bra       Task1_1
; }
; }
; /*
; ** Task 2 below was created with the highest priority so it must start timer1
; ** so that it produces interrupts for the 100hz context switches
; */
; void Task2(void *pdata)
; {
       xdef      _Task2
_Task2:
       link      A6,#0
; // must start timer ticker here 
; Timer1_Init() ;      // this function is in BIOS.C and written by us to start timer      
       jsr       _Timer1_Init
; for (;;) {
Task2_1:
; OSTimeDly(50);
       pea       50
       jsr       _OSTimeDly
       addq.w    #4,A7
; OSMutexPend(g_mutex, 0, &err);
       pea       _err.L
       clr.l     -(A7)
       move.l    _g_mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; printf("\r\nReading from address %x of EEPROM", PortA);
       move.b    4194304,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab6_4.L
       jsr       _printf
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
       jsr       _CanBus0_Transmit
       addq.w    #4,A7
; CanBus1_Receive();
       jsr       _CanBus1_Receive
; OSMutexPost(g_mutex);
       move.l    _g_mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       bra       Task2_1
; }
; }
; void Task3(void *pdata)
; {
       xdef      _Task3
_Task3:
       link      A6,#0
; for (;;) {
Task3_1:
; OSTimeDly(200);
       pea       200
       jsr       _OSTimeDly
       addq.w    #4,A7
; OSMutexPend(g_mutex, 0, &err);
       pea       _err.L
       clr.l     -(A7)
       move.l    _g_mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; printf("\r\nReading from address %x of flash", PortA);
       move.b    4194304,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab6_5.L
       jsr       _printf
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
       jsr       _CanBus0_Transmit
       addq.w    #4,A7
; CanBus1_Receive();
       jsr       _CanBus1_Receive
; OSMutexPost(g_mutex);
       move.l    _g_mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       bra       Task3_1
; }
; }
; /*
; void Task4(void *pdata)
; {
; unsigned char hexc = 0;
; for (;;) {
; //printf("............This is Task #4\n");
; HEX_C = hexc;
; hexc ++;
; OSTimeDly(60);
; }
; }*/
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
; void send_spi_cmd(int c)
; {
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
; unsigned char flash_read(unsigned char addr)
; {
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
; /*******************************************************************************************
; ** I2C functions
; *******************************************************************************************/
; void I2C_init (void) 
; {
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
; void I2C_TX_command_status (unsigned char data, unsigned char command) 
; {
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
; unsigned char EEPROM_read (unsigned char addr) 
; {
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
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; // write EEPROM internal addr (upper and lower byte), no start signal
; I2C_TX_command_status(EEPROM_internal_addr_H, write_cmd_I2C);
       pea       17
       move.b    -2(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_TX_command_status(EEPROM_internal_addr_L, write_cmd_I2C);
       pea       17
       move.b    -1(A6),D1
       and.l     #255,D1
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
       and.l     #255,D2
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
; /*******************************************************************************************
; ** CAN bus functions
; *******************************************************************************************/
; // initialisation for Can controller 0
; void Init_CanBus_Controller0(void)
; {
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
       pea       @lab6_6.L
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
       section   const
@lab6_1:
       dc.b      65,108,116,101,114,97,32,68,69,49,47,54,56,75
       dc.b      0
@lab6_2:
       dc.b      77,105,99,114,105,117,109,32,117,67,47,79,83
       dc.b      45,73,73,32,82,84,79,83,0
@lab6_3:
       dc.b      13,10,82,101,97,100,105,110,103,32,115,119,105
       dc.b      116,99,104,101,115,0
@lab6_4:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,114,111
       dc.b      109,32,97,100,100,114,101,115,115,32,37,120
       dc.b      32,111,102,32,69,69,80,82,79,77,0
@lab6_5:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,114,111
       dc.b      109,32,97,100,100,114,101,115,115,32,37,120
       dc.b      32,111,102,32,102,108,97,115,104,0
@lab6_6:
       dc.b      13,10,37,120,0
       section   data
       xdef      _err
_err:
       dc.l      0
       section   bss
       xdef      _Task1Stk
_Task1Stk:
       ds.b      512
       xdef      _Task2Stk
_Task2Stk:
       ds.b      512
       xdef      _Task3Stk
_Task3Stk:
       ds.b      512
       xdef      _Task4Stk
_Task4Stk:
       ds.b      512
       xdef      _g_mutex
_g_mutex:
       ds.b      4
       xref      _Init_LCD
       xref      _Timer1_Init
       xref      _Init_RS232
       xref      _OSMutexCreate
       xref      _OSInit
       xref      _OSStart
       xref      _OSTaskCreate
       xref      _OSMutexPost
       xref      _Oline0
       xref      _OSMutexPend
       xref      _Oline1
       xref      _OSTimeDly
       xref      _printf
