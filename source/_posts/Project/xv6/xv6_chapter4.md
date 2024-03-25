---
title: xv6_chapter4 traps
date: 2024-2-26 22:39:28
tags:
- xv6
categories:
- Project
---

# Lecture

gdb调试shell write函数的syscall过程：

```shell
(gdb) b *0xdec # 在0xde8地址设置断点
(gdb) c
(gdb) delete 1 # 删除断点
(gdb) print $pc
$1 = (void (*)()) 0xdec
(gdb) info r
(gdb) x/3i 0xde8 # 打印0xdfe开始的三条指令
0xdfe: li a7,16
0xe00: ecall
0xe04: ret
(gdb) p/x $stvec
$2 = 0x3ffffff000 # user space virtual address顶部一个page，trampoline page对应kernel trap handler.
(gdb) stepi
```

<p class="这边gdb调试进不去kernel，ecall之后stepi直接到了ret">warning</p>

# Book

Traps：

- system call. 通过ecall进入kernel
- exception. 除0，invalid virtual address.
- interrupt. 进入kernel device driver.

根据处理代码不同，可分为三种traps：

- traps from user space
- traps from kernel space
- timer interrupts

## 4.1 RISC-V trap machinery

一些重要的CPU控制寄存器：

- `stvec`: 保存trap handler的地址。
- `sepc`: trap发生时，保存pc指针。接着pc指针被改写成`stvec`中保存的trap handler地址。`sret`指令把`sepc`的值拷贝回pc指针。
- `scause`: 保存发生trap的原因。
- `sscratch`:
- `sstatus`: `SIE` bit控制设备中断使能。`SPP`表示trap来自user mode还是supervisor mode。

RISC-V硬件处理traps流程(除timer中断)：

1. 如果是设备中断，而且`sstatus`的`SIE`bit没有被开启，下面都不会执行。
2. 禁止掉`SIE` in `sstatus`。
3. 拷贝`pc`到`sepc`。
4. 保存当前mode(user/supervisor)到`sstatus`的`SPP`。
5. 设置`scause`发生异常的原因。
6. 进入supervisor mode。
7. 拷贝`stvec`到pc。
8. 开始在新pc执行代码。

## 4.2 Trap from user space

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240227224055.png)

user space trap流程：`trampoline.S`
`uservec`->`usertrap`
返回的时候：`usertrapret`->`userret`

为什么user space能执行到kernel的trap处理代码呢？user space调用`ecall`, 会进入`stvec`设置的trap handler，此时CPU使用的还是user space的page table，还没有切换到kernel space的page table。所以`stvec`中存储的是user space的virtual address`TRAPPOLINE`。user space实现了`trampoline page`。把virtual address的最后一个page`TRAPPOLINE`映射到了kernel trap handler。

进入`uservec`的时候，需要保存user space所有32个寄存器到某个memory地址，这时候没有一个空闲的寄存器，怎么办呢？RISC-V提供了`scratch`寄存器，在之前保存了某个地址`p->trapframe`。但这是kernel的结构体，此时`satp`还保存着user space的page table，所以user space还映射了一个page`TRAPFRAME`，在`TRAPOLINE`下面。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240227220131.png)

接着可以将`sccrach`与a0交换值：

`csrrw a0, sscratch, a0`

这样我们就可以使用a0了，将其他31个寄存器的值保存到此时a0(p->trapframe)对应的offset，最后再将`sscratch`中保存的旧a0值加载进对应的内存地址。

```c
csrr t0, sscratch
sd t0, 112(a0)
```

接着将之前就设置好的
kernel栈指针`p->trapframe->kernel_sp`加载到`sp`。
cpu id`p->trapframe->kernel_haltid`加载到`tp`。
kernel trap入口`p->trapframe->kernel_trap`加载到`t0`。
kernel page table`p->trapframe->kernel_satp`加载到`satp`。
> 这边加载了kernel的page table后还能继续执行代码，因为kernel也将相同的virtual address(trampoline page)映射到了与user space trampoline page相同的物理地址。

## 4.3-4.4 Code: Calling system calls

见xv_chapter2.md。

## 4.5 Traps from kernel code

user space发生trap进入kernel space后，`stvec`会被设置为`kernelvec`，接着kernel中发生的设备中断和异常会进入`kernelvec`。

## 4.6 Page-fault exceptions

RISC-V区分三种page faults:

- load page fault: load指令中的虚拟地址不能正确翻译
- store page fault: store指令中的虚拟地址不能正确翻译
- instruction page fault: pc指针的虚拟地址不能正确翻译

`scause`中展示了page fault的种类，`stval`保存了不能翻译的地址。
