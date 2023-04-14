# Uboot编译流程

<https://blog.csdn.net/ooonebook/article/details/53000893>

编译生成的文件：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230414152845.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230414152904.png)

具体可以参考Uboot Makefile

## u-boot Makefile

```makefile

u-boot.cfg: $(Q)$(MAKE) -f $(srctree)/scripts/Makefile.autoconf $(@)
cfg: u-boot.cfg
prepare2: prepare3 outputmakefile cfg
prepare1: prepare2$(version_h) $(timestamp_h) $(dt_h) $(env_h) include/config/auto.conf
archprepare: prepare1 scripts_basic
prepare0: archprepare
prepare:prepare0
scripts: scripts_basic scripts_dtc include/config/auto.conf

$(u-boot-dirs): prepare scripts
$(sort $(u-boot-init) $(u-boot-main)): $(u-boot-dirs)

u-boot-init := $(head-y)
u-boot-main := $(libs-y)
u-boot-keep-syms-lto := keep-syms-lto.o
u-boot.lds: $(LDSCRIPT) prepare

u-boot:	$(u-boot-init) $(u-boot-main) $(u-boot-keep-syms-lto) u-boot.lds
u-boot-dtb.bin: u-boot-nodtb.bin dts/dt.dtb
u-boot-nodtb.bin: u-boot
dts/dt.dtb: u-boot

u-boot.srec: u-boot
u-boot.bin: u-boot-dtb.bin
u-boot.sym: u-boot
System.map:	u-boot
binary_size_check: u-boot-nodtb.bin
u-boot.dtb: dts/dt.dtb

INPUTS-y += u-boot.srec u-boot.bin u-boot.sym System.map binary_size_check
INPUTS-$(CONFIG_OF_SEPARATE) += $(if $(CONFIG_OF_OMIT_DTB),dts/dt.dtb,u-boot.dtb)

.binman_stamp: $(INPUTS-y)

all: .binman_stamp

```

# Uboot 启动流程

<https://blog.csdn.net/ooonebook/article/details/53070065>

## BL0

Nor/Nand run code from **flash**.

Emmc boot/security boot run code from **ROM**.

初始化CPU、拷贝第二阶段代码到sram

```c
// board/realtek/rts3917/ram_init/boot.S
_start:
		save_boot_params
				b	save_boot_params_ret

save_boot_params_ret:
		cpu_init_cp15

		ldr	r0, =(CONFIG_SYS_FLASH_BASE + CONFIG_RAMINIT_OFFSET) // CONFIG_SYS_FLASH_BASE = 0   CONFIG_RAMINIT_OFFSET = 2048
		ldr	r1, =(CONFIG_LOAD_BASE) // 0x19000000 sram地址
		ldr	r2, =(CONFIG_SYS_FLASH_BASE + CONFIG_RAMINIT_OFFSET \ // CONFIG_RAMINIT_SIZE = stat -c %s init.bin 即uboot第二阶段代码的长度
				+ CONFIG_RAMINIT_SIZE)
		/*
		 * r0 = source address
		 * r1 = target address
		 * r2 = source end address
		 */
	1:
		ldr	r3, [r0], #4 // 拷贝第二阶段代码到sram
		str	r3, [r1], #4
		cmp	r0, r2
		bne	1b

		ldr pc,=(CONFIG_LOAD_BASE) // 0x19000000 sram地址
```

## BL1

初始化cpu，初始化ddr，ddr controller，时钟，拷贝uboot到ddr

```c
// board/realtek/rts3917/ram_init/init.S
_start:
		b	save_boot_params
				b	save_boot_params_ret

save_boot_params_ret:
		bl	cpu_init_cp15
		ldr	r0, =(CONFIG_SYS_INIT_SP_ADDR_SRAM) /// 设置堆栈为C code准备 CONFIG_SYS_INIT_SP_ADDR_SRAM = 0x19010000
		bic	r0, r0, #7	/* 8-byte alignment for ABI compliance */
		mov	sp, r0

		bl	bsp_boot_init_plat /// bsp_init.c 初始化时钟、DDR、DDR controller
		bl	fast_copy //dma_copy.c 拷贝uboot到0x82800000
		ldr pc,=(CONFIG_LOAD_BASE) /// 0x82800000
```

## BL2

初始化cpu，relocate uboot，初始化串口，flash，网卡等。

```c
// arch/arm/lib/vectors.S
_start:
		ARM_VECTORS
.macro ARM_VECTORS
		b	reset

// arch/arm/cpu/armv7/start.S
reset:
		b	save_boot_params

ENTRY(save_boot_params)
		b	save_boot_params_ret		@ back to my caller

save_boot_params_ret:
		cpu_init_cp15
		cpu_init_crit
				lowlevel_init // board/realtek/rts3917/low_level.S
		_main
```

```assembly
# arch/arm/lib/crt0.S
ENTRY(_main)
	ldr	r0, =(CONFIG_SYS_INIT_SP_ADDR)
	bl	board_init_f_alloc_reserve # board_init.c 设置global_data起始地址
	bl	board_init_f_init_reserve # board_init.c 初始化global_data，清零
	bl	board_init_f
	b	relocate_code
	bl	relocate_vectors
```

## global_data

uboot中定义了一个宏`DECLARE_GLOBAL_DATA_PTR`，使我们可以更加简单地获取global_data。

global_data的地址存放在r9中，直接从r9寄存器中获取其地址即可。

```c
//arch/arm/include/asm/global_data.h
#define DECLARE_GLOBAL_DATA_PTR		register volatile gd_t *gd asm ("r9")

// DECLARE_GLOBAL_DATA_PTR定义了gd_t *gd，并且其地址是r9中的值。
// 一旦使用了DECLARE_GLOBAL_DATA_PTR声明之后，后续就可以直接使用gd变量，也就是global_data了。
```

## u-boot relocate

```c
// board_f.c
fdtdec_setup();
	gd->fdt_blob = board_fdt_blob_setup();
		fdt_blob = (ulong *)&_end; // fdt_blob接在uboot image的末尾
	gd->fdt_blob = map_sysmem(env_get_ulong("fdtcontroladdr", 16,
			       (unsigned long)map_to_sysmem(gd->fdt_blob)), 0);//从环境变量设置设备树位置
	fdtdec_prepare_fdt();
```



# Reference

[Uboot PPT](%5B%3Chttps://xyc-1316422823.cos.ap-shanghai.myqcloud.com/uboot_introduction.ppt%3E%5D(%3Chttps://xyc-1316422823.cos.ap-shanghai.myqcloud.com/uboot_introduction.ppt%3E))