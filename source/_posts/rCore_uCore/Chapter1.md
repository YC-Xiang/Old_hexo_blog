---
title: uCore_chapter1
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



