---
title: xv6_lab2 System calls
date: 2024-1-4 22:51:28
tags:
- xv6
categories:
- Project
---

## Trace

实现系统调用`int trace(int mask);`, 当调用mask中包含的系统调用号，打印出来。

在Makefile中增加trace用户程序的编译

```Makefile
UPROGS=\
	...
	$U/_trace
```

在`user/user.h`中增加函数声明

```c
int trace(int);
```

在`usys.pl`中增加user space `trace`函数的入口。可以看到user space调用的系统调用, 是由这个脚本生成的函数。
以trace为例, 提供了trace函数的入口`.global trace`, 随后将定义在`syscall.h`中的`SYS_trace`编号存入寄存器`a7`, 通过`ecall`命令进入内核态。


```perl
sub entry {
    my $name = shift;
    print ".global $name\n";
    print "${name}:\n";
    print " li a7, SYS_${name}\n";
    print " ecall\n";
    print " ret\n";
}
entry("trace");
```

在`syscall.c`的`syscall`函数中通过获取`a6`寄存器中的编号，找到我们添加的系统调用函数，`sys_trace`。

函数具体实现如下:

```c
// 在proc结构体中增加mask成员
struct proc {
	//...
	int mask;
}

// 将user space传入的mask，传递给当前进程的mask变量
uint64 sys_trace(void)
{
  if(argint(0, &myproc()->mask) < 0)
    return -1;
  return 0;
}

// 随后执行的系统调用number如果 (1 << num == mask), 则打印
syscall(void)
{
    // ...
    if ((1 << num) & p->mask)
	printf("%d: syscall %s -> %d\n", p->pid, syscalls_name[num - 1], p->trapframe->a0);
}
```

## Sysinfo

实现系统调用`int sysinfo(struct sysinfo *);`，返回free memory bytes和状态不是`UNUSED`的进程。

其中：

```c
struct sysinfo {
  uint64 freemem;   // amount of free memory (bytes)
  uint64 nproc;     // number of process
};
```
