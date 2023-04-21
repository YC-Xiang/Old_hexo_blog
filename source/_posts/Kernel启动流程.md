---
title: Kernel启动流程
date: 2023-04-19 14:10:28
tags:
- Kernel
categories:
- Notes
---

`System.map`：编译内核会生成的内核符号表

`arch/arm/kernel/vmlinux.lds.S `生成链接文件，指定了kernel的entry point为`ENTRY(stext)`

所以kernel代码的入口是`head.S` 中的`ENTRY(stext)`