---
title: xv6_chapter3 Page tables
date: 2024-1-11 22:30:28
tags:
- xv6 OS
categories:
- Project
---

## 3.1 Paging hardware

xv6 runs on Sv39 RISC-V, 使用低39位来表示虚拟内存, 高25位没有使用。

39位中27位用作index来寻找PTE(Page table entry), 低12位表示在某个页表中的偏移地址, 正好对应4KB。每个PTE包含44bits的PPN(physical page number)和一些控制位。

![Page table](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240118220902.png)

实际的RISC-V CPU翻译虚拟地址到物理地址使用了三层。每层存储512个PTE，分别使用9个bit来索引。上一层的一个PTE对应下一层包含512个PTE的Page table。所以总共有512\*512\*512=2^27 PTE。

![ RISC-V address translation details](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240118221141.png)

每个CPU需要把顶层的page directory物理地址加载到 `satp` 寄存器中, 第一个Page Directory的地址是已知的。

然后通过L2索引到第一个Page directory的PTE，读出PTE的PPN, 即第二个Page directory的起始物理地址。再根据L1索引到第二个Page directory的PTE, 以此类推。

## 3.2 Kernel address space

![Kernel address space](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240118224444.png)

QEMU模拟RAM从0x80000000物理地址开始，至多到0x86400000，xv6称这个地址为`PHYSTOP`。

Kernel使用RAM和device registers是直接映射的，虚拟地址和物理地址相等。

不过有一部分kernel虚拟地址不是直接映射的：

- Trampoline page. 在虚拟地址的最顶部。这边有意思的是物理内存中的trampoline code被映射到了两个地方，一个对应直接映射的虚拟内存中的kernel text，另一个是虚拟地址最顶部地址的一个page size。有关Trampoline page请参考第四章。
- Kernel stack pages. 每个进程都有自己的kernel stack。如果访问超过了自己的kernel stack。会有guard page保护，guard page的PTE valid位置为0，导致访问异常。

## 3.3 Code: creating an address space

TLB. 每个进程有自己的页表，切换进程时需要flush TLB, 因为之前VA-PA对应已经不成立了。通过RISC-V指令`sfence.vma`可以flush TLB。

## 3.5 Code: Physical memory allocator

分析下`kalloc.c`中的`kfree`和`kalloc`函数：

main中初始化内存free memory的时候会调用`kinit`函数，该函数对free memory区域调用`kfree`函数。

`kmem.freelist`是全局变量的未初始化的指针，为NULL。

调用kfree：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240125144343.png)

调用kalloc：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240125144830.png)
