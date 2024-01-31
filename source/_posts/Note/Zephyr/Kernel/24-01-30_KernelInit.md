---
title: Zephyr -- Kernel Init
date: 2024-01-30 14:14:28
tags:
- Zephyr
categories:
- Zephyr OS
---

## Vector_table.S

以arm cortex-M系列的启动流程为例，`arch/arm/core/cortex_m`:

`vector_table.S`: 定义了中断向量表`_vector_table`。其中arm cortex-M规定0x0地址存放栈的起始地址（栈顶）。0x4开始存放reset handler,...
![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240130152631.png)

> 没看到定义外部中断的地址

上电后跳转至`z_arm_reset`函数，进入`reset.S`。

## Reset.S

目前大部分的宏定义都没打开。这里关注下通用的一些流程：

```c
    movs.n r0, #_EXC_IRQ_DEFAULT_PRIO
    msr BASEPRI, r0
```

设置BASEPRI寄存器, 中断的base prioriity, 低于或等于该优先级的中断都会被屏蔽。
这里`#_EXC_IRQ_DEFAULT_PRIO`宏展开为3，说明中断优先级只能配置为0/1/2。

</br>

```c
    ldr r0, =z_interrupt_stacks
    ldr r1, =CONFIG_ISR_STACK_SIZE + MPU_GUARD_ALIGN_AND_SIZE
    adds r0, r0, r1
    msr PSP, r0 // write r0 to PSP
    mrs r0, CONTROL // read CONTROL to r0
    movs r1, #2
    orrs r0, r1 /* CONTROL_SPSEL_Msk */
    msr CONTROL, r0 // write 0x2 to CONTROL
    isb
    bl z_arm_prep_c
```

1.设置进程堆栈指针PSP, process stack pointer。
2.写CONTROL寄存器bit1，使用PSP作为当前的stack。
3.跳转至`z_arm_prep_c`

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240130155822.png)

## Prep_c.c

```c
void z_arm_prep_c(void)
{
	relocate_vector_table();
#if defined(CONFIG_CPU_HAS_FPU)
	z_arm_floating_point_init();
#endif
	z_bss_zero();
	z_data_copy();
	z_arm_interrupt_init();
	z_cstart();
	CODE_UNREACHABLE;
}
```

`z_bss_zero()`: 清bss段。
`z_data_copy()`: 把data段数据从ROM拷贝到RAM。
`z_arm_interrupt_init()`: 设置外部中断优先级先都为1。
`z_cstart()`: 跳转至`init.c`。

# Init.c

```c
void z_cstart(void)
{
	/* initialize early init calls */
	z_sys_init_run_level(INIT_LEVEL_EARLY);
	/* perform any architecture-specific initialization */
	arch_kernel_init();
	LOG_CORE_INIT();
#if defined(CONFIG_MULTITHREADING)
	/* Note: The z_ready_thread() call in prepare_multithreading() requires
	 * a dummy thread even if CONFIG_ARCH_HAS_CUSTOM_SWAP_TO_MAIN=y
	 */
	struct k_thread dummy_thread;
	z_dummy_thread_init(&dummy_thread);
#endif
	/* do any necessary initialization of static devices */
	z_device_state_init();
	/* perform basic hardware initialization */
	z_sys_init_run_level(INIT_LEVEL_PRE_KERNEL_1);
	z_sys_init_run_level(INIT_LEVEL_PRE_KERNEL_2);

#ifdef CONFIG_MULTITHREADING
	switch_to_main_thread(prepare_multithreading());
	while (true) {
	}
#endif /* CONFIG_MULTITHREADING */
}
```

删掉了一些没打开的宏相关代码。

`z_sys_init_run_level(INIT_LEVEL_EARLY)`
`z_sys_init_run_level(INIT_LEVEL_PRE_KERNEL_1)`
`z_sys_init_run_level(INIT_LEVEL_PRE_KERNEL_2)`
根据优先级，初始化系统中所有driver的init函数和通过`SYS_INIT()`定义的init函数。
参考`DEVICE_DT_DEFINE`->`Z_DEVICE_INIT_ENTRY_DEFINE`宏定义的driver,会在`z_sys_init_run_level`函数中调用`.init_fn->.dev(dev)`。
而`SYS_INIT()`会调用到`.init_fn->sys()`

初始化完成后进入死循环。

</br>

其中`arch_kernel_init`函数：

```c
static ALWAYS_INLINE void arch_kernel_init(void)
{
	z_arm_interrupt_stack_setup();
	z_arm_exc_setup();
	z_arm_fault_init();
	z_arm_cpu_idle_init();
	z_arm_clear_faults();
#if defined(CONFIG_ARM_MPU)
	z_arm_mpu_init();
	z_arm_configure_static_mpu_regions();
#endif /* CONFIG_ARM_MPU */
}
```

`z_arm_interrupt_stack_setup()`: 设置msp, interrupt使用的stack。
`z_arm_exc_setup()`: 设置好系统异常的中断优先级。
`z_arm_fault_init()`: 设置CPU CCR寄存器，打开除0异常。非对齐访问异常由宏开关控制是否打开，默认不打开。
`z_arm_cpu_idle_init()`: 设置CPU SCR寄存器，设置中断可以唤醒CPU idle状态。
`z_arm_clear_faults()`: reset all faults，清除所有异常。

</br>

`switch_to_main_thread(prepare_multithreading())`: 创建一个kernel线程，接着会跑进`bg_thread_main`:

```c
static void bg_thread_main(void *unused1, void *unused2, void *unused3)
{
	ARG_UNUSED(unused1);
	ARG_UNUSED(unused2);
	ARG_UNUSED(unused3);

#ifdef CONFIG_MMU
	z_mem_manage_init();
#endif /* CONFIG_MMU */
	z_sys_post_kernel = true;
	z_sys_init_run_level(INIT_LEVEL_POST_KERNEL);
	boot_banner();
	/* Final init level before app starts */
	z_sys_init_run_level(INIT_LEVEL_APPLICATION);
	z_init_static_threads();

#ifdef CONFIG_MMU
	z_mem_manage_boot_finish();
#endif /* CONFIG_MMU */

	extern int main(void);

	(void)main();
}
```

包括一些低优先级的driver, `SYS_INIT()`初始化，MMU初始化，`boot_banner`会打印LOGO。这时kernel已经初始化完毕，之后跳转进应用程序的`main()`函数。

# linker.ld

`include/zephyr/arch/arm/cortex_m/scripts/linker.ld`链接脚本。
