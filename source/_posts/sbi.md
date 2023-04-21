---
title: RISC-V SBI
date: 2023-04-21 15:51:28
tags:
- RISC-V
- OpenSBI
categories:
- Notes
---

# 1. Introduction

SBI implementation/SEE(Supervisor Execution Environment), 比如opensbi，运行在Figure 1的M-mode。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230421093859.png)



Figure 2提供了另一种架构，linux kernel运行在VS-mode，opensbi运行在HS-mode和M-mode。**（不确定）**

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230421093917.png)

# 4. Base Extension(EID #0x10)

- ECALL指令从supervisor转移到SEE。
- a7保存SBI extension ID(EID)。
- a6保存SBI function ID (FID)。
- 除了a0和a1，其他寄存器都需要由SEE保存好。
- SBI functions返回error保存在a0，value保存在a1。

## Linux中调用sbi function

比如Function: Get SBI specification version (FID #0, EID #0x10):

在linux `arch/riscv/kernel/sbi.c`中定义了`struct sbiret sbi_get_spec_version(void);`

```c
//arch/riscv/include/asm/sbi.h arch/riscv/kernel/sbi.c
static inline long sbi_get_spec_version(void)
  	__sbi_base_ecall(SBI_EXT_BASE_GET_SPEC_VERSION); // SBI_EXT_BASE_GET_SPEC_VERSION 0 (fid)
        struct sbiret ret;
        ret = sbi_ecall(SBI_EXT_BASE, fid, 0, 0, 0, 0, 0, 0);// SBI_EXT_BASE 0x10 (eid)
            register uintptr_t a0 asm ("a0") = (uintptr_t)(arg0);
            register uintptr_t a1 asm ("a1") = (uintptr_t)(arg1);
            register uintptr_t a2 asm ("a2") = (uintptr_t)(arg2);
            register uintptr_t a3 asm ("a3") = (uintptr_t)(arg3);
            register uintptr_t a4 asm ("a4") = (uintptr_t)(arg4);
            register uintptr_t a5 asm ("a5") = (uintptr_t)(arg5);
            register uintptr_t a6 asm ("a6") = (uintptr_t)(fid); // fid a6保存fid
            register uintptr_t a7 asm ("a7") = (uintptr_t)(ext); // SBI_EXT_BASE a7保存eid
            asm volatile ("ecall"
                      : "+r" (a0), "+r" (a1)
                      : "r" (a2), "r" (a3), "r" (a4), "r" (a5), "r" (a6), "r" (a7)
                      : "memory");
```

执行`ecall`指令，a7保存eid, a6保存fid, a0-a5保存参数值。

Ecall是一种异常, 对应下图Interrupt 0 Exception Code 9.

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230421113527.png)

当一个hart发生中断/异常时，硬件自动经历如下转换：

- 异常指令的PC被保存在 mepc中，PC被设置为mtvec。（对于同步异常，mepc指向导致异常的指令；对于中断，它指向中断处理后应该恢复执行的位置。）
- 根据异常来源设置mcause，并将mtval设置为出错的地址或者其它适用于特定异常的信息字。
- 把控制状态寄存器mstatus中的MIE位置零以禁用中断，并把先前的MIE值保留到MPIE中。
- 发生异常之前的权限模式保留在 mstatus的MPP域中，再把权限模式更改为M。

## SSE(opensbi)处理Ecall过程

还是以Function: Get SBI specification version (FID #0, EID #0x10)为例

```c
_trap_handler
TRAP_CALL_C_ROUTINE
	void sbi_trap_handler(struct sbi_trap_regs *regs)
		sbi_ecall_handler(regs); // sbi_ecall.c
			sbi_ecall_find_extension(extension_id);
			ext->handle(extension_id, func_id, regs, &out_val, &trap);
			sbi_ecall_base_handler(); //根据不同的eid找到不同的handle函数
				case SBI_EXT_BASE_GET_SPEC_VERSION:
                      *out_val = (SBI_ECALL_VERSION_MAJOR << //SBI_ECALL_VERSION_MAJOR 0
                             SBI_SPEC_VERSION_MAJOR_OFFSET) &
                             (SBI_SPEC_VERSION_MAJOR_MASK <<
                              SBI_SPEC_VERSION_MAJOR_OFFSET);
							//SBI_ECALL_VERSION_MINOR 2 可以看出sbi version为0.2
                      *out_val = *out_val | SBI_ECALL_VERSION_MINOR;
```

# 5. Legacy Extensions(EIDs #0x00 - 0x0F)

需要在kernel中打开`CONFIG_RISCV_SBI_V01`0.1版本的sbi spec支持这些函数

# OpenSBI

```c
# fw_base.S
# relocate code 使load address==link address
call	fw_platform_init # platform/generic/platform.c
	extern struct sbi_platform platform; // 在platform/realtek/sheipa/platform.c中定义
		
call	sbi_init // lib/sbi/sbi_init.c
	init_coldboot();
		sbi_scratch_init();
		sbi_domain_init();
```

