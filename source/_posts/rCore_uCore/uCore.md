---
title: uCore
date: 2023-04-25 23:11:28
tags:
- uCore
categories:
- Project
---

# Notes

```shell
make build # 仅编译
make run # 编译+运行qemu
make run LOG=LOG_LEVEL_TRACE # 其他选项可以看Makefile
make clean # rm build/
make debug # 编译+运行gdb调试
```

每次在make run之前，尽量先执行make clean以删除缓存，特别是在切换ch分支之后。

# ch1

## 流程

```c
// entry.S
_entry
    la sp, boot_stack_top //设置堆栈
    call main
// main.c
	clean_bss();
	printf("hello wrold!\n");
		consputc();
			console_putchar(int c);
				sbi_call(SBI_CONSOLE_PUTCHAR, c, 0, 0);
```

<p class="note note-danger">怎么用gdb调试？`file kernel`然后？</p>

## Makefile流程分析

根据`make run `打印的信息：

```shell
riscv64-unknown-elf-gcc -Wall -Werror -O -fno-omit-frame-pointer -ggdb -MD -mcmodel=medany -ffreestanding -fno-common -nostdlib -mno-relax -Ios -fno-stack-protector -D LOG_LEVEL_ERROR  -fno-pie -no-pie -c os/console.c -o build/os/console.o
... # 编译所有的.c文件成.o文件
riscv64-unknown-elf-ld -z max-page-size=4096 -T os/kernel.ld -o build/kernel build/os/console.o build/os/main.o build/os/sbi.o build/os/printf.o  build/os/entry.o build/os/link_app.o # 链接
riscv64-unknown-elf-objdump -S build/kernel > build/kernel.asm
riscv64-unknown-elf-objdump -t build/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$/d' > build/kernel.sym
Build kernel done
```

比较熟悉的是`objdump -d` `objdump -D`将所有段都反汇编，而`-d`应该仅反汇编代码段。

`objdump -S`是在-d的基础上，代码段反汇编的同时，将反汇编代码与源代码交替显示，编译时需要使用`-g`参数，即需要调试信息。

`objdump -t`打印符号表。

# ch2

```makefile
make -C user clean # 在os目录，相当于cd user;make clean;cd ..
make clean # 或者在user目录
git checkout ch2
make user BASE=1 CHAPTER=2
make run 
make test BASE=1 # make test 会完成　make user 和 make run 两个步骤（自动设置 CHAPTER）
```

## 流程

```c
main();
	printf("hello wrold!\n");
	trap_init(); // 设置中断/异常处理地址
		w_stvec((uint64)uservec & ~0x3); //把uservec地址传入,uservec在trampoline.S中定义
			asm volatile("csrw stvec, %0" : : "r"(x)); // 设置stvec CSR
	loader_init();
	run_next_app();
		struct trapframe *trapframe = (struct trapframe *)trap_page;
		trapframe->epc = BASE_ADDRESS;
		trapframe->sp = (uint64)user_stack + USER_STACK_SIZE;
		usertrapret(trapframe, (uint64)boot_stack_top);
			trapframe->kernel_satp = r_satp(); // kernel page table
			trapframe->kernel_sp = kstack + PGSIZE; // process's kernel stack
			trapframe->kernel_trap = (uint64)usertrap;
			trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
			w_sepc(trapframe->epc);
				asm volatile("csrw sepc, %0" : : "r"(x));
			uint64 x = r_sstatus();
			w_sstatus(x);
			userret((uint64)trapframe);
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





