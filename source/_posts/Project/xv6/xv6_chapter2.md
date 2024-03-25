---
title: xv6_chapter2 Operating system organization
date: 2024-1-4 20:57:28
tags:
- xv6 OS
categories:
- Project
---

## 2.6 Code: starting xv6, the first process and system call

启动代码:
`entry.S` 为每个CPU设置堆栈，然后跳进`start.c`的start函数。

```makefile
	# qemu -kernel loads the kernel at 0x80000000
        # and causes each CPU to jump there.
        # kernel.ld causes the following code to
        # be placed at 0x80000000.
.section .text
.global _entry
_entry:
	# set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        la sp, stack0
        li a0, 1024*4
	csrr a1, mhartid # CPUs 0~7 has hartid from 0~7
        addi a1, a1, 1
        mul a0, a0, a1
        add sp, sp, a0
	# jump to start() in start.c
        call start
spin:
        j spin
```

</br>

`start.c` 调用`mret`, 从machine mode进入supervisor mode。跳转至`mepc`中存入的main函数地址。

```c
void start()
{
	unsigned long x = r_mstatus();
	x &= ~MSTATUS_MPP_MASK;
	x |= MSTATUS_MPP_S;
	w_mstatus(x);

	w_mepc((uint64)main);
	// ...
	asm volatile("mret");
}
```

</br>

`main.c` userinit()中创建第一个进程。

```c
void main()
{
	// ...
	userinit();
}
```

</br>

`userinit.c` `uvminit`把`uchar initcode[]` 即`user/initcode.S`编译出来的`initcode`可执行程序加载进进程的页表中。

```c
void userinit(void)
{
	struct proc *p;
	p = allocproc();

	uvminit(p->pagetable, initcode, sizeof(initcode));
}

```

</br>

接着`initcode`会执行系统调用`exec`执行`/init`用户程序。

`initcode.S`

```makefile
# exec(init, argv)
.globl start
start:
        la a0, init
        la a1, argv
        li a7, SYS_exec
        ecall

```

最终在`init.c`中调用`fork()`在子进程中执行shell进程`exec("sh", argv);`,父进程则进入死循环。

## 4.3 Code: Calling system calls

`initcode.S` 把执行`exec`的参数存放在`a0`,`a1`寄存器中, 把system call编号存在`a7`寄存器中。随后`ecall`指令会trap into kernel, 导致进入`uservec`和`usertrap`函数, 最后调用到`sys_exec`函数。

## 4.4 Code: System call arguments

User space通过系统调用进入kernel space, 参数保存在current process当前进程的trap frame中。
比如`exit(0)`, 0会被保存到`a0`寄存器，随后会被kernel保存到`p->trapframe->a0`。

`argint`, `argaddr`, `argfd`函数从当前进程的trap frame中读取传入的参数。

</br>

如果user space传入指针，会有两个问题。

1. user space可能传入invalid address或者是企图访问kernel memory的恶意指针。
2. xv6 kernel page table和user space的page table mapping不同，所以同一个虚拟地址对应的物理地址是不同的。

这时候需要用`copyinstr`函数。
