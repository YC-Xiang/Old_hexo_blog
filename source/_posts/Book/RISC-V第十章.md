---
title: RISC-V手册 第十章 RISC-V特权架构
date: 2023-01-09 17:13:28
tags:
- RISC-V
categories:
- Book
---

## 10.1 导言

到目前为止，本书主要关注RISC-V 对通用计算的支持：我们引入的所有指令都在用户模式（User mode 应用程序的代码在此模式下运行）下可用。本章介绍两种新的权限模式：运行最可信的代码的机器模式（machine mode），以及为Linux，FreeBSD 和Windows 等操作系统提供支持的监管者模式（supervisor mode）。

图10.1是RISC-V 特权指令的图形表示，图10.2列出了这些指令的操作码。显然，特权架构添加的指令非常少。作为替代，几个新的控制状态寄存器（CSR）显示了附加的功能。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/10.1.png)

## 10.2 简单嵌入式系统的机器模式

机器模式（缩写为M模式， M-mode）是 RISC-V中（hart hardware thread，硬件线程）可以执行的最高权限模式。程）可以执行的最高权限模式。在M模式下运行的hart对内存，I/O和一些对于启动和配置系统来说必要的底层功能有着完全的使用权。因此它是唯一所有标准RISC-V处理器都必须实现的权限模式。实际上简单的 RISC-V微控制器仅支持 M模式。

机器模式最重要的特性是拦截和处理异常的能力。RISC-V将异常分为两类。一类是同步异常。另一类是中断，它是与指令流异步的外部事件，比如鼠标的单击。

在 M模式运行期间可能发生的同步异常有五种：

- 访问错误异常：当物理内存的地址不支持访问类型时发生（例如尝试写入 ROM）。


- 断点异常：在执行 ebreak指令，或者地址或数据与调试触发器匹配时发生。
- 环境调用异常：在执行 ecall指令时发生。
- 非法指令异常：在译码阶段发现无效操作码时发生。
- 非对齐地址异常：在有效地址不能被访问大小整除时发生，例如地址为0x12的amoadd.w。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/10.3.png)

有三种标准的中断源：软件、时钟和外部来源。软件中断通过向内存映射寄存器中存数来触发。

## 10.3 机器模式下的异常处理

八个控制状态寄存器（CSR）是机器模式下异常处理的必要部分：

- mtvec (Machine Trap Vector) 它保存发生异常时处理器需要跳转到的地址。
- mepc (Machine Exception PC) 它指向发生异常的指令。
- mcause (Machine Exception Cause) 它指示发生异常的种类。
- mie (Machine Interrupt Enable) 它指出处理器目前能处理和必须忽略的中断。
- mip (Machine Interrupt Pending) 它列出目前正准备处理的中断。
- mtval (Machine Trap Value) 它保存了陷入 trap 的附加信息：地址例外中出错的地址、发生非法指令例外的指令本身，对于其他异常，它的值为 0。
- mscratch (Machine Scratch) 它暂时存放一个字大小的数据。
- mstatus (Machine Status) 它保存全局中断使能，以及许多其他的状态，如图10.4所示。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/10.4.png)

处理器在M模式下运行时，只有在全局中断使能位mstatus.MIE置1时才会产生中断。此外，每个中断在控制状态寄存器mie中都有自己的使能位。这些位在mie中的位置对应于图10.3中的中断代码。例如，mie[7]对应于M模式中的时钟中断。控制状态寄存器mip具有相同的布局，并且它指示当前待处理的中断。。将所有三个控制状态寄存器合在一起考虑，如果 mstatus.MIE = 1，mie[7] = 1，且 mip[7] = 1，则可以处理机器的时钟中断。

当一个hart发生异常时，硬件自动经历如下的状态转换：

{% note info %}

hart是硬件线程 (hardware thread) 的缩略形式 。我们用该术语将它们与大多数程序员熟悉的软件线程区分开来。软件线程在 harts上进行分时复用。大多数处理器核都只有一个hart。
{% endnote %}

- 异常指令的PC被保存在mepc中，PC被设置为 mtvec。（对于同步异常， mepc指向导致异常的指令；对于中断，它指向中断处理后应该恢复执行的位置。）


-  根据异常来源设置 mcause（如图 10.3所示），并将 mtval设置为出错的地址或者其它适用于特定异常的信息字。
-  把控制状态寄存器 mstatus中的 MIE位置零以禁用中断，并把先前的 MIE值保留到 MPIE中。
- 发生异常之前的权限模式保留在mstatus的MPP域中，再把权限模式更改为M。图 10.5显示了MPP域的编码（如果处理器仅实现M模式，则有效地跳过这个步骤）。

![img](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/10.5.png)

为避免覆盖整数寄存器中的内容，中断处理程序先在最开始用mscratch和整数寄存器（例如 a0）中的值交换。通常，软件会让 mscratch包含指向附加临时内存空间的指针，处理程序用该指针来保存其主体中将会用到的整数寄存器。在主体执行之后，中断程序会恢复它保存到内存中的寄存器，然后再次使用 mscratch和 a0交换，将两个寄存器恢复到它们在发生异常之前的值。最后，处理程序用 mret指令（ M模式特有的指令）返回。 mret将 PC设置为mepc，通过将mstatus的 MPIE域复制到MIE来恢复之前的中断使能设置，并将权限模式设置为 mstatus的MPP域中的值。这基本是前一段中描述的逆操作。

图10.6展示了遵循此模式的基本时钟中断处理程序的 RISC-V汇编代码。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/10.6.png)

除了上面介绍的mret指令之外，M模式还提供了另外一条指令：wfi (Wait For Interrupt)。 wfi通 知处理器目前没有任何有用的工作，所有它应该进入低功耗模式，直到任何使能有效的中断等待处理，即 mie&mip≠0。

{% note info %}

操作 CSR 的指令在 RISC-V 的 `Zicsr` 扩展模块中定义。包括伪指令在内，共有以下 7 种操作类型：

1. `csrr`，读取一个 CSR 的值到通用寄存器。如：`csrr t0, mstatus`，读取 `mstatus` 的值到 `t0` 中。
2. `csrw`，把一个通用寄存器中的值写入 CSR 中。如：`csrw mstatus, t0`，将 `t0` 的值写入 `mstatus`。
3. `csrs`，把 CSR 中指定的 bit 置 1。如：`csrsi mstatus, (1 << 2)`，将 `mstatus` 的右起第 3 位置 1。
4. `csrc`，把 CSR 中指定的 bit 置 0。如：`csrci mstatus, (1 << 2)`，将 `mstatus` 的右起第 3 位置 0。
5. `csrrw`，读取一个 CSR 的值到通用寄存器，然后把另一个值写入该 CSR。如：`csrrw t0, mstatus, t0`，将 `mstatus` 的值与 `t0` 的值交换。
6. `csrrs`，读取一个 CSR 的值到通用寄存器，然后把该 CSR 中指定的 bit 置 1。
7. `csrrc`，读取一个 CSR 的值到通用寄存器，然后把该 CSR 中指定的 bit 置 0。

{% endnote %}

## 10.5 现代操作系统的监管者模式

更复杂的 RISC-V处理器用和几乎所有通用架构相同的方式处理这些问题：使用基于页面的虚拟内存。这个功能构成了监管者模式（S模式）的核心，这是一种可选的权限模式，旨在支持现代类Unix操作系统，如Linux。S模式比 U模式权限更高，但比M模式低。与U模式一样，S模式下运行的软件不能使用M模式的CSR和指令，并且受到PMP的限制。

mideleg（Machine Interrupt Delegation），机器中断委托 CSR控制将哪些中断委托给S模式。与mip和mie一样，mideleg中的每个位对应于图10.3中相同的异常。例如，mideleg[5]对应于S模式的时钟中断，如果把它置位，S模式的时钟中断将会移交S模式的异常处理程序，而不是M模式的异常处理程序。

委托给S模式的任何中断都可以被S模式的软件屏蔽。sie (Supervisor Interrupt enable) 和sip (Superivisor Interrupt pending) CSR是S模式的控制状态寄存器。他们是mie和mip的子集。它们有着和M模式下相同的布局，但在sie和sip中只有与由mideleg委托的中断对应的位才能读写。那些没有被委派的中断对应的位始终为零。
