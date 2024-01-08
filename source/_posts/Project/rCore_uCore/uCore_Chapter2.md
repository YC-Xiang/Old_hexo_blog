---
title: uCore_Chapter2 批处理系统
date: 2023-04-25 23:11:28
tags:
- uCore
categories:
- Project
---

```makefile
make -C user clean # 在os目录，相当于cd user;make clean;cd ..
make clean # 或者在user目录
git checkout ch2
make user BASE=1 CHAPTER=2
make run
make test BASE=1 # make test 会完成　make user 和 make run 两个步骤（自动设置 CHAPTER）
```

# 流程

```c
main();
	printf("hello wrold!\n");
	trap_init(); // 设置中断/异常处理地址
		w_stvec((uint64)uservec & ~0x3); //把uservec地址传入,uservec在trampoline.S中定义
			asm volatile("csrw stvec, %0" : : "r"(x)); // 设置stvec CSR
	loader_init();
	run_next_app();
		load_app();
		usertrapret(trapframe, (uint64)boot_stack_top);
			w_sepc(trapframe->epc);
			r_sstatus();
			w_sstatus();
			userret();
				sret // 返回到sepc中的值，0x80400000第一个app

```



## 应用程序系统调用ecall进入内核异常处理过程

```c
// 进入应用程序
exit(MAGIC);
	syscall(SYS_exit, code);
		__syscall1(n, long(1234));
			__asm_syscall("r"(a7), "0"(a0));
				ecall //通过ecall 进入uservec

uservec
	usertrap(); // ld t0, 16(a0) jr t0
		r_scause();
			csrr %0, scause // 应用层调用了ecall指令，所以scause自动被设置为8
		syscall();
			//在uservec中应用层传入eid到寄存器a7,这里读a7来判断是什么system call
			id = trapframe->a7;
		usertrapret(); // 这里回到第九行一样，循环，执行第二个应用程序
```

分析下`uservec`,注意：这里只是把stvec设置为uservec地址，并不会执行uservec下的代码，要等U mode的中断/异常到来时才会从uservec开始执行。

<p class="note note-warning">uservec是U mode异常/中断的入口。</p>

```assembly
.globl uservec
uservec:
        csrrw a0, sscratch, a0 # 交换a0和sscratch

        # save the user registers in TRAPFRAME
        sd ra, 40(a0)
        sd sp, 48(a0)
		...
        sd t6, 280(a0)

	# save the user a0 in p->trapframe->a0
        csrr t0, sscratch
        sd t0, 112(a0)

        csrr t1, sepc
        sd t1, 24(a0) # BASE_ADDRESS 0x80400000

        ld sp, 8(a0) # kstack + PGSIZE
        ld tp, 32(a0)
        ld t1, 0(a0)
        # csrw satp, t1
        # sfence.vma zero, zero
        ld t0, 16(a0)
        jr t0

```

这里需要注意sscratch这个CSR寄存器的作用就是一个cache，它只负责存某一个值，这里它保存的就是trapframe结构体的位置。

# 实现批处理操作系统的细节

从Makefile中可以发现，scripts/pack.py，scripts/kernelld.py用来生成os/link_app.S和os/kernel_app.ld。link_app.S将用户程序加入kernel可执行文件中。kernel_app.ld规定了用户程序所在的段(.data.app[x])。在load_app()中将用户程序relocate到0x80400000。

需要relocate的原因：我们并不能直接跳转到 app_n_start 直接运行，因为用户程序在编译的时候，会假定程序处在虚存的特定位置，而由于我们还没有虚存机制，因此我们在运行之前还需要将用户程序加载到规定的物理内存位置。
