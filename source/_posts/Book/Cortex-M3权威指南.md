---
title: Cortex-M3权威指南
date: 2023-09-06 09:43:28
tags:
- Book
categories:
- Book
---
## Reference

- 《Cortex-M3技术参考手册》（Cortex-M3 Technical Reference Manual, 简称Cortex-M3 TRM）
- 《ARMv7-M应用程序级架构参考手册》（ARMv7-M Application Level Architecture Reference Manual）
- 《ARMv7-M指令集手册》（ARMv7-M Architecture Application Level Reference Manual(Ref2)）

## Chapter1 介绍

Cortex－M3处理器（CM3）采用ARMv7-M架构，它包括**所有的**16位Thumb指令集和**基本的**32位Thumb-2指令集架构，Cortex-M3处理器**不能**执行ARM指令集。

CM3的出现，还在ARM处理器中破天荒地支持了“非对齐数据访问支持”。

## Chapter2 CM3概览

CM3采用了哈佛结构，拥有独立的指令总线和数据总线，可以让取指与数据访问并行不悖。

### 2.2 Registers

CM3有R0-R15，16个registers。R13作为堆栈指针SP。SP有两个，但在同一时刻只能有一个可以看到，这也就是所谓的“banked”寄存器。

![CM3 Registers](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230906101830.png)

绝大多数16位Thumb指令只能访问R0-R7，而32位Thumb-2指令可以访问所有寄存器。

Cortex-M3拥有两个堆栈指针，然而它们是banked，因此任一时刻只能使用其中的一个。

- 主堆栈指针（MSP）：复位后缺省使用的堆栈指针，用于操作系统内核以及异常处理例程（包括中断服务例程）
- 进程堆栈指针（PSP）：由用户的应用程序代码使用。

R14 LR：当调用一个子程序时，由R14存储返回地址。

R15 PC: 指向当前的程序地址。如果修改它的值，就能改变程序的执行流。

### 2.3 操作模式和特权级别

两种操作模式：handler mode（异常服务程序代码），thread mode（应用程序代码）。

两种特权级别：特权级，用户级。

![操作模式和特权级别](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230906104733.png)
在CM3运行主应用程序时（线程模式），既可以使用特权级，也可以使用用户级；但是异常服务例程必须在特权级下执行。复位后，处理器默认进入线程模式，特权极访问。

![操作模式转换图](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230906104934.png)
用户级的程序不能简简单单地试图改写CONTROL寄存器就回到特权级，它必须先“申诉”：执行一条系统调用指令(SVC)。这会触发SVC异常，然后由异常服务例程（通常是操作系统的一部分）接管，如果批准了进入，则异常服务例程修改CONTROL寄存器，才能在用户级的线程模式下重新进入特权级。

### 2.5 存储器映射

总体来说，Cortex-M3支持4GB存储空间，如图2.6所示地被划分成若干区域。

![CM3存储器映射](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230906110236.png)
从图中可见，不像其它的ARM架构，它们的存储器映射由半导体厂家说了算，Cortex-M3预先定义好了“粗线条的”存储器映射。

### 2.6 总线接口

Cortex-M3内部有若干个总线接口，以使CM3能同时取址和访内（访问内存），它们是：

- 指令存储区总线（两条）Icode，Dcode。
- 系统总线。
- 私有外设总线。

有两条代码存储区总线负责对代码存储区的访问，分别是I-Code总线和D-Code总线。前者用于取指，后者用于查表等操作。
系统总线用于访问内存和外设，覆盖的区域包括SRAM，片上外设，片外RAM，片外扩展设备，以及系统级存储区的部分空间。
私有外设总线负责一部分私有外设的访问，主要就是访问调试组件。它们也在系统级存储区。

### 2.9 中断和异常

11种系统异常+5个保留档位+240个外部中断。
| 编号  | 类型  |优先级 |简介|
|---|---|---|---|
| 0  | N/A  | N/A |没有异常在运行|
| 1  | 复位  | -3（最高） |复位|
| 2  | NMI  | -2 |不可屏蔽中断（来自外部NMI输入脚）|
| 3  | 硬(hard) fault  | -1 |所有被disable的fault，都将“上访”成硬fault|
| 4  | MemManage fault  | 可编程 |存储器管理fault，MPU访问犯规以及访问非法位置|
| 5  | 总线fault  | 可编程 |总线错误（预取流产（Abort）或数据流产）|
| 6  | 用法(usage)Fault  | 可编程 |由于程序错误导致的异常|
| 7-10  | 保留  | N/A |N/A|
| 11  | SVCall  | 可编程 |系统服务调用|
| 12  | 调试监视器  | 可编程 |调试监视器（断点，数据观察点，或者是外部调试请求|
| 13  | 保留  | N/A |N/A|
| 14  | PendSV  | 可编程 |为系统设备而设的“可悬挂请求”（pendable request）|
| 15  | SysTick  | 可编程 |系统滴答定时器|
| 16-255  | IRQ #0~239  | 可编程 |外中断#0~#239|

### 2.10 调试支持

Cortex-M3的调试系统基于ARM最新的CoreSight架构。不同于以往的ARM处理器，内核本身不再含有JTAG接口。取而代之的，是CPU提供称为“调试访问接口(DAP)”的总线接口。

目前可用的DPs包括**SWJ-DP**(既支持传统的JTAG调试，也支持新的串行线调试协议SWD)，另一个**SW-DP**则去掉了对JTAG的支持。另外，也可以使用ARM CoreSignt产品家族的**JTAG-DP**模块。这下就有3个DPs可以选了，芯片制造商可以从中选择一个，以提供具体的调试接口（通常都是选SWJ-DP）。

## Chpater3 CM3基础

PC: 读PC时返回的值是当前指令的地址+4。在分支时，无论是直接写PC的值还是使用分支指令，都必须保证加载到PC的数值是奇数（即LSB=1），用以表明这是在Thumb状态下执行。

### 3.2 特殊功能寄存器

Cortex-M3还在内核水平上搭载了若干特殊功能寄存器，包括
![Special function registers](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230906104300.png)

它们只能被专用的MSR/MRS指令访问

```asm
MRS <gp_reg>, <special_reg>; 读特殊功能寄存器的值到通用寄存器
MSR <special_reg>, <gp_reg> ;写通用寄存器的值到特殊功能寄存器
```

#### 3.2.1 程序状态寄存器

- 应用程序PSR（APSR）
- 中断号PSR（IPSR）
- 执行PSR（EPSR）

通过MRS/MSR指令，这3个PSRs即可以单独访问，也可以组合访问（2个组合，3个组合都可以）。当使用三合一的方式访问时，应使用名字“xPSR”或者“PSR”。
![PSR](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230906154110.png)