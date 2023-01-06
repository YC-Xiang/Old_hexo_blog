---
title: RISC-V手册 第三章 RISC-V汇编语言
date: 2023-01-06 17:44:28
tags:
- RISC-V
categories:
- Notes
---

## 3.2 函数调用规范

![图3.2](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/%E5%9B%BE3.2.png)

## 3.3 汇编器

这类指令在巧妙配置常规指令的基础上实现，称为**伪指令**。图 3.3和 3.4列出了 RISC-V伪指令。

汇编程序的开头是一些汇编指示符，它们是汇编器的命令。图 3.9是RISC-V的汇编指示符。其中图 3.6中用到的指示符有：

- .text：进入代码段。
- .align 2：后续代码按2^2字节对齐。
- .globl main：声明全局符号 “main”
- .section .rodata：进入只读数据段
- .balign 4：数据段按4字节对齐
- .string “Hello, %s!\n": 创建空字符结尾的字符串
- .string “world": 创建空字符结尾的字符串

![图3.3](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/%E5%9B%BE3.3.png)

![图3.4](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/%E5%9B%BE3.4.png)
