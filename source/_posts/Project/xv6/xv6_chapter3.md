---
title: xv6_chapter3 Page tables
date: 2023-1-11 22:30:28
tags:
- xv6
categories:
- Project
---

## 3.1 Paging hardware

xv6 runs on Sv39 RISC-V, 使用低39位来表示虚拟内存, 高25位没有使用。

39位中27位用作index来寻找PTE(Page table entry), 低12位表示在某个页表中的偏移地址, 正好对应4KB。每个PTE包含44bits的PPN(physical page number)和一些控制位。

![Page table](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240118220902.png)

实际的RISC-V CPU翻译虚拟地址到物理地址使用了三层。每层存储512个PTE，分别使用9个bit来索引。

![ RISC-V address translation details](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240118221141.png)

每个CPU需要把顶层的page directory物理地址加载到 `satp` 寄存器中。

然后通过L2索引到第一个Page directory的PTE，读出PTE的PPN, 根据PPN找到第二个Page directory的物理地址。

## 3.2 Kernel address space

![Kernel address space](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240118224444.png)

QEMU模拟RAM从0x80000000物理地址开始，至少到0x86400000，xv6称这个地址为`PHYSTOP`。

Kernel使用RAM和device registers是直接映射的，虚拟地址和物理地址相等。

不过有一部分kernel虚拟地址不是直接映射的：

- Trampoline page.
- Kernel stack pages. 每个进程都有自己的kernel stack。如果访问超过了自己的kernel stack。会有guard page保护，guard page的PTE valid位置为0，导致访问异常。


## 3.3

TLB. 每个进程有自己的页表，切换进程时需要flush TLB, 因为之前VA-PA对应已经不成立了。
