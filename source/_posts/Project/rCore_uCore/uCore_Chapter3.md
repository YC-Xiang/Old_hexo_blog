---
title: uCore_Chapter3 多道程序与分时多任务
date: 2023-05-17 20:20:28
tags:
- uCore
categories:
- Project
---

# 分时多任务系统与抢占式调度

## RISC-V架构中断

以内核所在的 S 特权级为例，中断屏蔽相应的 `CSR` 有 `sstatus` 和 `sie` 。`sstatus` 的 `sie` 为 S 特权级的中断使能，能够同时控制三种中断，如果将其清零则会将它们全部屏蔽。即使 `sstatus.sie` 置 1 ，还要看 `sie` 这个 CSR，它的三个字段 `ssie/stie/seie` 分别控制 S 特权级的软件中断、时钟中断和外部中断的中断使能。

- 当 Trap 发生时，`sstatus.sie` 会被保存在 `sstatus.spie` 字段中，同时 `sstatus.sie` 置零，这也就在 Trap 处理的过程中屏蔽了所有 S 特权级的中断；
- 当 Trap 处理完毕 `sret` 的时候， `sstatus.sie` 会恢复到 `sstatus.spie` 内的值。

也就是说，如果不去手动设置 `sstatus` CSR ，在只考虑 S 特权级中断的情况下，是不会出现 **嵌套中断** (Nested Interrupt) 的。

嵌套中断可以分为两部分：在处理一个中断的过程中又被同特权级/高特权级中断所打断。默认情况下硬件会避免前一部分，也可以通过手动设置来允许前一部分的存在；而从上面介绍的规则可以知道，后一部分则是无论如何设置都不可避免的。

## 时钟中断与计时器

计数器保存在一个 64 位的 CSR `mtime`

另外一个 64 位的 CSR `mtimecmp` 的作用是：一旦计数器 `mtime` 的值超过了 `mtimecmp`，就会触发一次时钟中断。这使得我们可以方便的通过设置 `mtimecmp` 的值来决定下一次时钟中断何时触发。

# Chapter3 练习

```c
void main() {
    clean_bss();    // 清空 bss 段    
    proc_init();     // 初始化线程池
    loader_init();   // 初始化 app_info_ptr 指针
    trap_init();     // 开启中断
    	set_kerneltrap(); // 设置异常/中断入口为kerneltrap
    		w_stvec((uint64)kerneltrap & ~0x3);
    timer_init();    // 开启时钟中断，现在还没有
    run_all_app();  // 加载所有用户程序
    scheduler();    // 开始调度
    	swtch(&idle.context, &p->context);
}
// swtch执行完后，会返回p->context.ra，在allocproc中设置为usertrapret，返回应用态
usertrapret();
	set_usertrap(); // 这里设置异常、中断入口为uservec
	userret();
		sret
    //...
usertrap(); //应用程序异常/系统调用/中断入口
	set_kerneltrap();
```



首先在kernel中`proc.h`中定义`TaskStatus`和`TaskInfo`与用户态对应上。注意到这里`TaskInfo`中添加了`t0`和`count`成员，是用户态没有的，这里是自己实现lab时候hack的做法。

在`struct proc`中添加 `TaskInfo *info`成员，用来记录进程的信息。

```c
typedef enum {
	UnInit,
	Ready,
	Running,
	Exited,
} TaskStatus;

typedef struct {
	TaskStatus status;
	unsigned int syscall_times[MAX_SYSCALL_NUM];
	int time;
	int t0;
	int count;
} TaskInfo;

struct proc {
	//...
	TaskInfo *info;
};
```

`syscall_ids.h`中定义`sys_task_info`系统调用号

`#define SYS_task_info 410`



注意到`proc.c`中定义了`__attribute__((aligned(4096))) char trapframe[NPROC][PAGE_SIZE]` proc_init初始化的时候

`p->trapframe = (struct trapframe *)trapframe[p - pool];` 这个操作，看起来是先静态定义NPROC个`trapframe[PAGE_SIZE]`，在init的时候再分配，把NPROC个`trapframe[PAGE_SIZE]`转化成`(struct trapframe *)`。这里看起来是数组与指针之间的转化关系。

`__attribute__((aligned(4096))) char ustack[NPROC][PAGE_SIZE];`则进行这样的转化：`p->kstack = (uint64)kstack[p - pool];`把NPROC个`char ustack[PAGE_SIZE]`转化成`uint64`了。



`proc.c` `proc_init()`中添加初始化`proc`中`TaskInfo`的部分

```c
__attribute__((aligned(4096))) char info[NPROC][PAGE_SIZE];

void proc_init(void)
{
	struct proc *p;
	for (p = pool; p < &pool[NPROC]; p++) {
		//...
		p->info = (TaskInfo *)info[p - pool];
	}
}
```

`proc.c` 在`scheduler()`在进程被调度后，proc->TaskInfo的t0变量记录刚被调度的时间点。并初始化proc->TaskInfo->status为Running。

```c
void scheduler(void)
{
    if (p->info->count == 0) {
        p->info->t0 = get_cycle() / CPU_FREQ * 1000 + (get_cycle() % CPU_FREQ) * 1000 / CPU_FREQ; //前面是s转化成ms，后面是余下的ms
        p->info->count++;
    }
    p->info->status = Running;
}
```

当应用程序调用sys_task_info后，流程为：

```c
// ch3_taskinfo.c
sys_task_info(&info);
// user/lib/syscall.c
int sys_task_info(TaskInfo *ti)
    syscall(SYS_task_info, ti);
// os/syscall.c
void syscall();
	case SYS_task_info:
		sys_task_info();
```

在`os/syscall.c`中添加sys_task_info系统调用。

```c
uint64 sys_task_info(TaskInfo *info)
{
	uint64 t1 = get_cycle() / CPU_FREQ * 1000 + (get_cycle() % CPU_FREQ) * 1000 / CPU_FREQ; // s + ms
	struct proc *proc = curr_proc();
	info->status = proc->info->status;
	info->time = t1 - proc->info->t0;
	for (int i = 0; i < MAX_SYSCALL_NUM; i++)
		info->syscall_times[i] = curr_proc()->info->syscall_times[i];

	return 0;
}
```





## 问答作业

**1**



**2.1** L79:刚进入 userret 时，a0、a1 分别代表了什么值。

a0代表了trameframe的地址。从userret((uint64)trapframe)可以发现。

a1代表了



**2.2** L87-L88: sfence 指令有何作用？为什么要执行该指令，当前章节中，删掉该指令会导致错误吗？

**清除TLB缓存**
所有现代的处理器都用TLB来减少开销。为了降低这个缓存本身的开销，大多数处理器不会让它时刻与页表保持一致。这意味着如果操作系统修改了页表，那么这个缓存会变得陈旧而不可用。S 模式添加了另一条指令来解决这个问题。这条`sfence.vma` 会通知处理器，软件可能已经修改了页表，于是处理器可以相应地刷新转换缓存。它需要两个可选的参数，这样可以缩小缓存刷新的范围。一个位于 rs1，它指示了页表哪个虚址对应的转换被修改了；另一个位于 rs2，它给出了被修改页表的进程的地址空间标识符（ASID）。如果两者都是 x0，便会刷新整个转换缓存。

本章中还没引入页表，不会导致错误。



**2.3** L96-L125: 为何注释中说要除去 a0？哪一个地址代表 a0？现在 a0 的值存在何处？

因为a0保存着trameframe的地址，其他寄存器的值都保存在trameframe中。a0的值存入sscratch寄存器。



**2.4** userret：中发生状态切换在哪一条指令？为何执行之后会进入用户态？

sret。sret指令会返回spec寄存器中保存的返回地址。在w_sepc(trapframe->epc)中设置为trapframe->epc。



**2.5 **L29：执行之后，a0 和 sscratch 中各是什么值，为什么？

执行之后，a0为trapframe地址，sscrach为用户态传进来的第一个参数。



**2.6** L32-L61: 从 trapframe 第几项开始保存？为什么？是否从该项开始保存了所有的值，如果不是，为什么？

第六项trapframe->ra开始保存。



**2.7** 进入 S 态是哪一条指令发生的？

ecall



**2.8** L75-L76: ld t0, 16(a0) 执行之后，t0中的值是什么，解释该值的由来？

usertrap()的地址，  usertrapret中设置了trapframe->kernel_trap = (uint64)usertrap。

# Question

