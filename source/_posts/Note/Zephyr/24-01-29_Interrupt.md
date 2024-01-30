---
title: Zephyr -- Interrupt Subsystem
date: 2024-01-26 09:30:28
tags:
- Zephyr
categories:
- Zephyr OS
---

# Overview

https://docs.zephyrproject.org/latest/kernel/services/interrupts.html

## Multi-level Interrupt Handling

如果要支持中断嵌套，需要打开`CONFIG_MULTI_LEVEL_INTERRUPTS`。`CONFIG_2ND_LEVEL_INTERRUPTS`, `CONFIG_3RD_LEVEL_INTERRUPTS`也需要根据硬件架构来选择是否打开。

```c
          9         4   2   0
    _ _ _ _ _ _ _ _ _ _ _ _ _         (LEVEL 1)
  5   3   |         A   |     2
_ _ _ _ _ _ _         _ _ _ _ _ _ _   (LEVEL 2)
  |   C                       B
_ _ _ _ _ _ _                         (LEVEL 3)
        D
```

Level 1第一级中断控制器有12条interrupt lines, 其中第2条和第9条接到了Level2优先级更高的中断控制器。第4条上接了设备A。
Level 2有两个中断控制器，左边的第3条interrupt line接了设备C, 第5条接到Level3中断控制器。
右边的第二条接了设备B。
Level 3中断控制器上第2条interrupt line接到了设备D。

因此各设备对应的interrupt numbers如下。其中Level 2之后的offset会+1, 因为0表示该级别不存在中断号。
设备A直接就是0x4对应Level 1 interrupt controller的第4条interrupt line。
设备B首先从Level 1 interrupt controller的第2条interrupt line找到level 2 interrupt controller, 再对应到Level 2 interrupt controller的第3条interrupt line。
设备C/D同理。

```c
A -> 0x00000004
B -> 0x00000302
C -> 0x00000409
D -> 0x00030609
```

# Implementation

## Regular ISR

Define irq: `IRQ_CONNECT(irq_p, priority_p, isr_p, isr_param_p, flags_p)`
其中`irq_p`是中断号，`priority_p`是中断优先级，`isr_param_p`是传递给中断处理函数的参数，`flags_p`是中断flags。

e.g.

```c
#define GPIO_CFG_IRQ(idx, n)
	IRQ_CONNECT(DT_INST_IRQ_BY_IDX(n, idx, irq),
		COND_CODE_1(DT_INST_IRQ_HAS_CELL(n, priority),
		DT_INST_IRQ(n, priority), (0)), gpio_altera_irq_handler,
		DEVICE_DT_INST_GET(n), 0);
```

Enable irq: `irq_enable(irq)`
其中`irq`是中断号。

## Direct ISR

`IRQ_DIRECT_CONNECT(irq_p, priority_p, isr_p, flags_p)`

开销更少的ISR定义。如果打开了power management, 大部分时间设备处于idle状态，如果来了一个中断，所有的hardware需要resume，再进中断处理函数，这个耗时很长。可以通过Direct ISR解决。

## Sharing an interrupt line

打开`CONFIG_SHARED_INTERRUPTS`

一个中断号对应两个中断处理函数，两个函数都会进入，根据`IRQ_CONNECT`中传入isr的参数不同，通过软件处理来选择执行哪个函数（不需要的另一个函数，可以通过参数判断提前return）。

```c
#define MY_DEV_IRQ 24               /* device uses INTID 24 */
#define MY_DEV_IRQ_PRIO 2           /* device uses interrupt priority 2 */
/*  this argument may be anything */
#define MY_FST_ISR_ARG INT_TO_POINTER(1)
/*  this argument may be anything */
#define MY_SND_ISR_ARG INT_TO_POINTER(2)
#define MY_IRQ_FLAGS 0              /* IRQ flags */

void my_first_isr(void *arg)
{
   ... /* some magic happens here */
}

void my_second_isr(void *arg)
{
   ... /* even more magic happens here */
}

void my_isr_installer(void)
{
   ...
   IRQ_CONNECT(MY_DEV_IRQ, MY_DEV_IRQ_PRIO, my_first_isr, MY_FST_ISR_ARG, MY_IRQ_FLAGS);
   IRQ_CONNECT(MY_DEV_IRQ, MY_DEV_IRQ_PRIO, my_second_isr, MY_SND_ISR_ARG, MY_IRQ_FLAGS);
   ...
}
```
