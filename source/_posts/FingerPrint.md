---
title: FingerPrint
date: 2023-06-19 17:00:28
tags:
- FingerPrint
categories:
- FingerPrint
---

# Normal world Enroll



# GPIO

# Uart

```c
// FpUart.c
InitUart();
	// FpUartHal.c
	Uart_EnableTX();
	Uart_EnableRX();
	Uart_Init(); 
		SetUartBaudRate();
		CfgUartDataFormat();
		Clock_SwtichUart0();
	Uart_InitFifoMode();
    Uart_SetIntEn();
```

```c
UART232_Handler();
	Uart232ProInterrupt();
		Uart_GetIntSts(DATA_AVAILABLE_INT)&&Uart_GetIntEn(UART_ERBFI_EN);
		Uart_GetMulc();
```

```c
uart_printf();
	uart_puts();
		Uart_Putc();
			UartTbufEmpty();
```



InitUart();

```c
/* Uart_Init */
writel(UART_INT_EN, 0); // 禁止中断

writel_mask(UART_LINE_CTRL, DIV_LATCH_ACCESS, BIT_7);
writel(UART_DIV_LATCH_L, BYTE0(wDiv));
writel(UART_DIV_LATCH_H, BYTE1(wDiv));
writel_mask(UART_LINE_CTRL, DIV_LATCH_RELEASE, BIT_7);

writel_mask(UART_LINE_CTRL, data_len|stop_bits|parity, BIT_0|BIT_1|BIT_2|BIT_3);

/* Uart_InitFifoMode */
clearl_bits(UART_LINE_CTRL, BREAK_CONTROL);
setl_bits(UART_FIFO_CTRL, FIFO_ENABLE);
setl_bits(UART_FIFO_CTRL, RCVR_FIFO_RESET|XMIT_FIFO_RESET);
writel_mask(UART_FIFO_CTRL, (tTxTrigLevel<<4)|(tRxTrigLevel<<6), TX_EMPTY_TRIGGER|RCVR_TRIGGER);

/* Uart_SetIntEn */
setl_bits(UART_INT_EN, byIntMask);
```

UART232_Handler();

```c
readl(UART_INT_EN) & byIntMask;
readl(UART_INT_EN) & byIntMask;
testl_bit(UART_LINE_STAT, DATA_READY_FLAG);
buffer[i] = readb(UART_RBUF);
```

uart_printf();

```c
testl_bit(UART_LINE_STAT, BIT_5);
writel(UART_TBUF, byChar);
```



# SPI

cache spi
data spi
ssor spi
ssi spi

```c
DataSpi_FlashInit();
	DataSpiInit();
	DataSpiFlashJudge();
		DataSpiReadID();
			SCB_CleanInvalidateDCache_by_Addr();
			DataSpiStartTransfer();
				DataSpiDmaStart();
				DataSpiDmaCheckEnd();
	DataSpi_WriteWP();
		DataSpiWriteStatus();
	DataSpi_SetAutoMode();
```



# I2C

```c
I2C0_Init();
	I2C0Disable();
	I2C0_ClkPadEn();

/*i2c master 读写*/
I2C0_MasterWrite();
	writel( I2C0_TAR, address );
	WaitTimeOut( I2C0_RAW_INTR_STAT, TX_EMPTY, 1, 20);
    writel_mask( I2C0_DATA_CMD, *data_p, I2C_STOP|I2C_DATA_MASK|I2C_WRITE_CMD_MASK);
	WaitTimeOut( I2C0_RAW_INTR_STAT, TX_EMPTY, 1, 50);
I2C0_MasterRead();
	writel( I2C0_TAR, address );
	writel_mask( I2C0_DATA_CMD, I2C_READ_CMD, I2C_READ_CMD);
	WaitTimeOut( I2C0_RAW_INTR_STAT, RX_FULL, 1, 20);
    (readl(I2C0_DATA_CMD))& I2C_DATA_MASK;

/*i2c slave 读写*/
I2C0ProInterrupt0();
	I2C0_SlaveGetIntEn(I2C_SLAVE_READ_REQ) && I2C0_SlaveGetIntSts(I2C_SLAVE_READ_REQ);
	I2C0_SlaveReceive();
		return ((readl( I2C0_DATA_CMD))&I2C_DATA_MASK);
	I2C0_SlaveClrIntSts(I2C_SLAVE_READ_REQ);

	I2C0_SlaveGetIntEn(I2C_SLAVE_WRITE_REQ) && I2C0_SlaveGetIntSts(I2C_SLAVE_WRITE_REQ);
	I2C0_SlaveSend();
		readl(I2C0_CLR_TX_ABRT);
		writel_mask( I2C0_DATA_CMD, value, I2C_DATA_MASK);
	
```

```c
/* I2C0_Init */
writel(I2C0_ENABLE, 0)
writel(I2C0_INTR_MASK, 0);

writel( I2C0_CON, IC_SLAVE_DISABLE | IC_RESTART_EN | MASTER_MODE | I2C_FAST_SPEED );
writel( I2C0_INTR_MASK, M_GEN_CALL);

writel(I2C0_RX_TL, 0);
writel(I2C0_TX_TL, 0);

/*  change frequency */
writel(I2C0_FS_SCL_HCNT, (U16)((float)((dwI2cSpeed>>16)&0xffff)/fMul));
writel(I2C0_FS_SCL_LCNT, (U16)((float)(dwI2cSpeed&0xffff)/fMul));

/* change SDA Hold Time */
writel(I2C0_SDA_HOLD, (U16)((float)(dwI2cSpeed&0xffff)/(fMul*3)));

writel(I2C0_ENABLE, 1 )
```

