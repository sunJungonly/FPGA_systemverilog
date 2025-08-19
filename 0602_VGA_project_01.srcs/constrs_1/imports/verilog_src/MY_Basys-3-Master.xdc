## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_34 ,Sch=CLK100MHZ
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]


## Switches
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports sw]; #IO_L19N_T3_A09_D25_VREF_14 ,Sch=SW0
#set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports { GPIOA[1]}]; #IO_L19P_T3_A10_D26_14      ,Sch=SW1
#set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports { GPIOA[2]}]; #IO_L20P_T3_A08_D24_14      ,Sch=SW2
#set_property -dict { PACKAGE_PIN W17  IOSTANDARD LVCMOS33 } [get_ports { GPIOA[3]}]; #IO_L20N_T3_A07_D23_14      ,Sch=SW3
#set_property -dict { PACKAGE_PIN W15  IOSTANDARD LVCMOS33 } [get_ports { GPIOA[4]}]; #IO_L21N_T3_DQS_A06_D22_14  ,Sch=SW4
#set_property -dict { PACKAGE_PIN V15  IOSTANDARD LVCMOS33 } [get_ports { GPIOA[5]}]; #IO_L21P_T3_DQS_14          ,Sch=SW5
#set_property -dict { PACKAGE_PIN W14  IOSTANDARD LVCMOS33 } [get_ports { GPIOA[6]}]; #IO_L22N_T3_A04_D20_14      ,Sch=SW6
#set_property -dict { PACKAGE_PIN W13  IOSTANDARD LVCMOS33 } [get_ports { GPIOA[7]}]; #IO_L22P_T3_A05_D21_14      ,Sch=SW7
#set_property -dict { PACKAGE_PIN V2   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[0] }]; #IO_L5P_T0_34               ,Sch=SW8
#set_property -dict { PACKAGE_PIN T3   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[1] }]; #IO_L2N_T0_34               ,Sch=SW9
#set_property -dict { PACKAGE_PIN T2   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[2] }]; #IO_L1N_T0_34               ,Sch=SW10
#set_property -dict { PACKAGE_PIN R3   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[3] }]; #IO_L2P_T0_34               ,Sch=SW11
#set_property -dict { PACKAGE_PIN W2   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[4] }]; #IO_L5N_T0_34               ,Sch=SW12
#set_property -dict { PACKAGE_PIN U1   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[5] }]; #IO_L3N_T0_DQS_34           ,Sch=SW13
#set_property -dict { PACKAGE_PIN T1   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[6] }]; #IO_L3P_T0_DQS_34           ,Sch=SW14
#set_property -dict { PACKAGE_PIN R2   IOSTANDARD LVCMOS33 } [get_ports { GPIOB[7] }]; #IO_L1P_T0_34               ,Sch=SW15


## LEDs

#set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[0]  }]; #IO_L23N_T3_A02_D18_14        ,Sch=LED0
#set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[1]  }]; #IO_L3N_T0_DQS_EMCCLK_14      ,Sch=LED1
#set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[2]  }]; #IO_L15P_T2_DQS_RDWR_B_14     ,Sch=LED2
#set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[3]  }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 ,Sch=LED3
#set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[4]  }]; #IO_L16P_T2_CSI_B_14          ,Sch=LED4
#set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[5]  }]; #IO_L23P_T3_A03_D19_14        ,Sch=LED5
#set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[6]  }]; #IO_25_14                     ,Sch=LED6
#set_property -dict { PACKAGE_PIN V14  IOSTANDARD LVCMOS33 } [get_ports { GPIOC[7]  }]; #IO_L24N_T3_A00_D16_14        ,Sch=LED7
#set_property -dict { PACKAGE_PIN V13  IOSTANDARD LVCMOS33 } [get_ports { GPIOD[0] }]; #IO_L24P_T3_A01_D17_14        ,Sch=LED8
#set_property -dict { PACKAGE_PIN V3   IOSTANDARD LVCMOS33 } [get_ports { GPIOD[1] }]; #IO_L6P_T0_34                 ,Sch=LED9
#set_property -dict { PACKAGE_PIN W3   IOSTANDARD LVCMOS33 } [get_ports { GPIOD[2] }]; #IO_L6N_T0_VREF_34            ,Sch=LED10
#set_property -dict { PACKAGE_PIN U3   IOSTANDARD LVCMOS33 } [get_ports { GPIOD[3] }]; #IO_L9P_T1_DQS_34             ,Sch=LED11
#set_property -dict { PACKAGE_PIN P3   IOSTANDARD LVCMOS33 } [get_ports { GPIOD[4] }]; #IO_L12N_T1_MRCC_35           ,Sch=LED12
#set_property -dict { PACKAGE_PIN N3   IOSTANDARD LVCMOS33 } [get_ports { GPIOD[5] }]; #IO_L12P_T1_MRCC_35           ,Sch=LED13
#set_property -dict { PACKAGE_PIN P1   IOSTANDARD LVCMOS33 } [get_ports { GPIOD[6] }]; #IO_L19N_T3_VREF_35           ,Sch=LED14
#set_property -dict { PACKAGE_PIN L1   IOSTANDARD LVCMOS33 } [get_ports { GPIOD[7] }]; #IO_L6N_T0_VREF_35            ,Sch=LED15


##7 segment display

#set_property -dict { PACKAGE_PIN W7  IOSTANDARD LVCMOS33 } [get_ports { fndFont[0] }]; #IO_L13P_T2_MRCC_34 ,Sch=seg[0]
#set_property -dict { PACKAGE_PIN W6  IOSTANDARD LVCMOS33 } [get_ports { fndFont[1] }]; #IO_L13N_T2_MRCC_34 ,Sch=seg[1]
#set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS33 } [get_ports { fndFont[2] }]; #IO_L14P_T2_SRCC_34 ,Sch=seg[2]
#set_property -dict { PACKAGE_PIN V8  IOSTANDARD LVCMOS33 } [get_ports { fndFont[3] }]; #IO_L14N_T2_SRCC_34 ,Sch=seg[3]
#set_property -dict { PACKAGE_PIN U5  IOSTANDARD LVCMOS33 } [get_ports { fndFont[4] }]; #IO_L16P_T2_34      ,Sch=seg[4]
#set_property -dict { PACKAGE_PIN V5  IOSTANDARD LVCMOS33 } [get_ports { fndFont[5] }]; #IO_L16N_T2_34      ,Sch=seg[5]
#set_property -dict { PACKAGE_PIN U7  IOSTANDARD LVCMOS33 } [get_ports { fndFont[6] }]; #IO_L19P_T3_34      ,Sch=seg[6]
#set_property -dict { PACKAGE_PIN V7  IOSTANDARD LVCMOS33 } [get_ports { fndFont[7] }]; #IO_L19N_T3_VREF_34 ,Sch=seg[7]
#
#set_property -dict { PACKAGE_PIN U2  IOSTANDARD LVCMOS33 } [get_ports { fndCom[0]  }]; #IO_L9N_T1_DQS_34   ,Sch=an[0]
#set_property -dict { PACKAGE_PIN U4  IOSTANDARD LVCMOS33 } [get_ports { fndCom[1]  }]; #IO_L11P_T1_SRCC_34 ,Sch=an[1]
#set_property -dict { PACKAGE_PIN V4  IOSTANDARD LVCMOS33 } [get_ports { fndCom[2]  }]; #IO_L11N_T1_SRCC_34 ,Sch=an[2]
#set_property -dict { PACKAGE_PIN W4  IOSTANDARD LVCMOS33 } [get_ports { fndCom[3]  }]; #IO_L12N_T1_MRCC_34 ,Sch=an[3]


##Buttons

set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L18N_T2_A11_D27_14 ,Sch=BTNC
#set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports { GPIOE[0] }]; #IO_L17N_T2_A13_D29_14 ,Sch=BTNU
#set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports { GPIOE[1] }]; #IO_L16N_T2_A15_D31_14 ,Sch=BTNL
#set_property -dict { PACKAGE_PIN T17  IOSTANDARD LVCMOS33 } [get_ports { GPIOE[2] }]; #IO_L17P_T2_A14_D30_14 ,Sch=BTNR
#set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports { GPIOE[3] }]; #IO_L18P_T2_A12_D28_14 ,Sch=BTND


##Pmod Header JA

#set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports { MISO_0 }]; #IO_L3N_T0_DQS_AD5N_35 ,Sch=JA1
#set_property -dict { PACKAGE_PIN L2  IOSTANDARD LVCMOS33 } [get_ports { MOSI_0 }]; #IO_L5N_T0_AD13N_35    ,Sch=JA2
#set_property -dict { PACKAGE_PIN J2  IOSTANDARD LVCMOS33 } [get_ports { SCLK_0 }]; #IO_L2N_T0_AD12N_35    ,Sch=JA3
#set_property -dict { PACKAGE_PIN G2  IOSTANDARD LVCMOS33 } [get_ports { JA[3] }]; #IO_L1N_T0_AD4N_35     ,Sch=JA4
#set_property -dict { PACKAGE_PIN H1  IOSTANDARD LVCMOS33 } [get_ports { JA[4] }]; #IO_L3P_T0_DQS_AD5P_35 ,Sch=JA7
#set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { JA[5] }]; #IO_L5P_T0_AD13P_35    ,Sch=JA8
#set_property -dict { PACKAGE_PIN H2  IOSTANDARD LVCMOS33 } [get_ports { JA[6] }]; #IO_L2P_T0_AD12P_35    ,Sch=JA9
#set_property -dict { PACKAGE_PIN G3  IOSTANDARD LVCMOS33 } [get_ports { JA[7] }]; #IO_L1P_T0_AD4P_35     ,Sch=JA10


##Pmod Header JB

##Pmod Header JB
set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports {scl}];#Sch name = JB1
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports {ov7670_pclk}];#Sch name = JB2
set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports {ov7670_v_sync}];#Sch name = JB3
set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports {sda}];#Sch name = JB4
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports {JB[4]}];#Sch name = JB7
#set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports {JB[5]}];#Sch name = JB8
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports {ov7670_href}];#Sch name = JB9
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports {ov7670_xclk}];#Sch name = JB10

##Pmod Header JC
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[7]}];#Sch name = JC1
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[5]}];#Sch name = JC2
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[3]}];#Sch name = JC3
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[1]}];#Sch name = JC4
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[6]}];#Sch name = JC7
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[4]}];#Sch name = JC8
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[2]}];#Sch name = JC9
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {ov7670_data[0]}];#Sch name = JC10



##Pmod Header JXADC

#set_property -dict { PACKAGE_PIN J3  IOSTANDARD LVCMOS33 } [get_ports { JXADC[0] }]; #IO_L7P_T1_AD6P_35     ,Sch=XA1_P
#set_property -dict { PACKAGE_PIN L3  IOSTANDARD LVCMOS33 } [get_ports { JXADC[1] }]; #IO_L7N_T1_AD6N_35     ,Sch=XA2_P
#set_property -dict { PACKAGE_PIN M2  IOSTANDARD LVCMOS33 } [get_ports { JXADC[2] }]; #IO_L8P_T1_AD14P_35    ,Sch=XA3_P
#set_property -dict { PACKAGE_PIN N2  IOSTANDARD LVCMOS33 } [get_ports { JXADC[3] }]; #IO_L8N_T1_AD14N_35    ,Sch=XA4_P
#set_property -dict { PACKAGE_PIN K3  IOSTANDARD LVCMOS33 } [get_ports { JXADC[4] }]; #IO_L9P_T1_DQS_AD7P_35 ,Sch=XA1_N
#set_property -dict { PACKAGE_PIN M3  IOSTANDARD LVCMOS33 } [get_ports { JXADC[5] }]; #IO_L9N_T1_DQS_AD7N_35 ,Sch=XA2_N
#set_property -dict { PACKAGE_PIN M1  IOSTANDARD LVCMOS33 } [get_ports { JXADC[6] }]; #IO_L10P_T1_AD15P_35   ,Sch=XA3_N
#set_property -dict { PACKAGE_PIN N1  IOSTANDARD LVCMOS33 } [get_ports { JXADC[7] }]; #IO_L10N_T1_AD15N_35   ,Sch=XA4_N


##VGA Connector
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports {red_port[0]}]
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports {red_port[1]}]
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports {red_port[2]}]
set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports {red_port[3]}]
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports {blue_port[0]}]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {blue_port[1]}]
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports {blue_port[2]}]
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {blue_port[3]}]
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {green_port[0]}]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {green_port[1]}]
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports {green_port[2]}]
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports {green_port[3]}]
set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports h_sync]
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports v_sync]



##USB-RS232 Interface

#set_property -dict { PACKAGE_PIN B18  IOSTANDARD LVCMOS33 } [get_ports { usb_uart_rxd }]; #IO_L19P_T3_16      ,Sch=UART_TXD_IN
#set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVCMOS33 } [get_ports { usb_uart_txd }]; #IO_L19N_T3_VREF_16 ,Sch=UART_RXD_OUT


##USB HID (PS/2)

#set_property -dict { PACKAGE_PIN C17  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { PS2Clk  }]; #IO_L14P_T2_SRCC_16 ,Sch=PS2_CLK
#set_property -dict { PACKAGE_PIN B17  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { PS2Data }]; #IO_L14N_T2_SRCC_16 ,Sch=PS2_DATA


##Quad SPI Flash
##Note that CCLK_0 cannot be placed in 7 series devices. You can access it using the
##STARTUPE2 primitive.

#set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { QspiDB[0] }]; #IO_L1P_T0_D00_MOSI_14 ,Sch=QSPI_DQ0
#set_property -dict { PACKAGE_PIN D19  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { QspiDB[1] }]; #IO_L1N_T0_D01_DIN_14  ,Sch=QSPI_DQ1
#set_property -dict { PACKAGE_PIN G18  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { QspiDB[2] }]; #IO_L6P_T0_FCS_B_14    ,Sch=QSPI_DQ2
#set_property -dict { PACKAGE_PIN F18  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { QspiDB[3] }]; #IO_L2P_T0_D02_14      ,Sch=QSPI_DQ3
#set_property -dict { PACKAGE_PIN K19  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { QspiCSn   }]; #IO_L2N_T0_D03_14      ,Sch=QSPI_CS



## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
