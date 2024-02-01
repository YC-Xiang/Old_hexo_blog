---
title: xv6_lab3 pgtbl
date: 2024-2-1 22:57:28
tags:
- xv6
categories:
- Project
---

## Speed up system call

这个实验的目的是将用户程序的虚拟地址`USYSCALL`映射到保存有进程`pid`的物理地址。
这样不用通过系统调用`getpid()`的方式，直接通过`ugetpid()`访问虚拟地址就可以直接得到映射的进程pid。
