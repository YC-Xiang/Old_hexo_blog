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
InitUart();
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
```





```c
writel(UART_INT_EN, 0); // 禁止中断

writel_mask(UART_LINE_CTRL, DIV_LATCH_ACCESS, BIT_7);
writel(UART_DIV_LATCH_L, BYTE0(wDiv));
writel(UART_DIV_LATCH_H, BYTE1(wDiv));
writel_mask(UART_LINE_CTRL, DIV_LATCH_RELEASE, BIT_7);

writel_mask(UART_LINE_CTRL, data_len|stop_bits|parity, BIT_0|BIT_1|BIT_2|BIT_3);

clearl_bits(UART_LINE_CTRL, BREAK_CONTROL);
setl_bits(UART_FIFO_CTRL, FIFO_ENABLE);
setl_bits(UART_FIFO_CTRL, RCVR_FIFO_RESET|XMIT_FIFO_RESET);
writel_mask(UART_FIFO_CTRL, (tTxTrigLevel<<4)|(tRxTrigLevel<<6), TX_EMPTY_TRIGGER|RCVR_TRIGGER);

setl_bits(UART_INT_EN, byIntMask);
```





# SPI

# I2C

