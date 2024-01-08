---
title: 数字设计和计算机体系结构笔记
date: 2023-08-17 17:39:28
tags:
- Books
categories:
- Books
hide: true
---

PNP

NPN

## P5

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230827204939.png)


![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230827210915.png)

System总线用来读取寄存器。

AHB总线挂载了SDIO, RCC。

### 6.3.1 ICode总线

### 6.3.2 驱动单元

#### 6.3.2.1 DCode总线

常量就是固定不变的，用C语言中的const关键字修饰，是放到内部的FLASH当中的。变量是可变的，不管是全局变量还是局部变量都放在内部的SRAM。

> 有内存的系统中，常量放在.rodata，全局变量.data，局部变量栈。

 因为数据可以被Dcode总线和DMA总线访问，所以为了避免访问冲突，在取数的时候需要经过一个总线矩阵来仲裁，决定哪个总线在取数。

#### 6.3.2.2 系统总线

主要是访问外设的寄存器，读写寄存器都是通过这根系统总线来完成的。

#### 6.3.2.3 DMA总线

主要是用来传输数据，这个数据可以是在某个外设的数据寄存器，可以在SRAM，可以在内部的FLASH。 因为数据可以被Dcode总线和DMA总线访问，所以为了避免访问冲突，在取数的时候需要经过一个总线矩阵来仲裁，决定哪个总线在取数。

## P10

推挽和开漏输出

![image-20230829221101699](C:\Users\yucheng_xiang\AppData\Roaming\Typora\typora-user-images\image-20230829221101699.png)

![image-20230829221147263](C:\Users\yucheng_xiang\AppData\Roaming\Typora\typora-user-images\image-20230829221147263.png)

推挽输出：

开漏输出：

## P16

1.启动文件
startup_stm32f10x_hd.s:

2.时钟配置文件
system_stm32f10x.c: 把外部时钟HSE=8M，经过PLL倍频为72M

3.外设相关的
stm32f10x.h: 内核之外的外设寄存器映射
xxx: GPIO, USART, I2C, SPI...
stm32f10x_xxx.c: 外设的驱动函数库文件
stm32f10x_xxx.h: 外设的初始化结构体，外设初始化结构体成员的参数列表，外设固件库函数的声明

4.内核相关的
CMSIS - Cortex 微控制器软件接口标准
core_cm3.h: 内核里的外设寄存器映射
core_cm3.c:

NVIC(嵌套向量中断控制器)、SysTick(系统滴答定时器) ：
misc.h
misc.c

5.头文件的配置文件
stm32f10x_conf.h：头文件的头文件，include了stm32f10x_xxx.h

6.专门存放中断服务函数的C文件
stm32f10x_it.c
stm32f10x_it.h

## P22

```asm
Stack_Size      EQU     0x00000400    ; 1KB

                AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem       SPACE   Stack_Size
__initial_sp
```

EQU: 定义Stack_Size常量为0x400
AREA: 告诉汇编器一个新的代码段或者数据段。STACK表示段名；NOINIT表示不初始化；READWRITE可读可写；ALIGN=3 8字节对齐。
SPACE: 分配一定大小的内存空间。这里大小为Stack_Size。
标号_intial_sp紧挨着SPACE, 表示栈的结束地址，即栈顶地址。

## P23 RCC时钟树

![Alt text](stm32clock.png)
HSE: High speed external clock。4~16MHz。
HSI: high speed internal clock。8MHz。
LSE: Low speed External clock。32.768KHZ。
LSI: Low speed internal clock。30~60KHz。
Independent Watchdog
MCO引脚可以选择输出如图所示的，PLLCLK/2, HSI, HSE, SYSCLK信号。
