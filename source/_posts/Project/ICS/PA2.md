---
title: ICS2022 PA2
date: 2023-01-31 14:24:23
tags:
- ICS
categories:
- Project
---

## Phase_1

mul-longlong.c中check `0xaeb1c2aa * 0xaeb1c2aa = 0x19d29ab9db1a18e4LL`

实现mulh指令遇到的一个问题：

由于`src1`和`src2`都是`unsigned int`，强制类型转换为`long`（零扩展），得到的是无符号相乘结果`0x7736200d`。

```c
  // 直接u32*u32会溢出，乘出来还是u32
u32 src1 = 0xaeb1c2aa;
u32 src2 = 0xaeb1c2aa
INSTPAT("...", mulh, R, R(dest) = (((long)src1 * (long)src2) >> 32));
```

先修改为`int`型，再改为`long`型（符号扩展）则可以顺利得到`0x19d29ab9`。

```c
INSTPAT("...", mulh, R, R(dest) = (((long)(int)src1 * (long)(int)src2) >> 32));

```
{% gi 2 2 %}
![无符号整型转换表](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/20230201173605.png)
![带符号整型转换表](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/20230201173534.png)
{% endgi %}

## Phase_2

### 通过批处理模式运行NEMU

`abstract-machine/scripts/platform/nemu.mk`中`NEMUFLAGS`加上`-b`，选择批处理模式，不用每次进入nemu都输入`c`。

## Diff test

## 输入输出

- 端口映射IO
- 内存映射IO

`nemu/src/device/`提供了设备相关的代码。

`nemu/include/device/map.h`中定义了`IOMap`结构体来抽象内存映射. 包括名字, 映射的起始地址和结束地址, 映射的目标空间, 以及一个回调函数.
`nemu/src/device/io/map.c`实现了映射的管理, 包括I/O空间的分配及其映射, 还有映射的访问接口.

```c
typedef struct {
  const char *name;
  // we treat ioaddr_t as paddr_t here
  paddr_t low;
  paddr_t high;
  void *space;
  io_callback_t callback;
} IOMap;
```

### 串口


### Notes

`[*] Devices  --->`
