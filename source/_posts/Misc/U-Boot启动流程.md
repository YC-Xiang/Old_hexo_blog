---
title: U-Boot启动流程
date: 2023-04-19 14:10:28
tags:
- U-Boot
categories:
- Misc
---

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
	# 对gd成员赋值，对relocate进行空间规划；计算relocate后的偏移；relocate旧的gd到新的gd空间上
	bl	board_init_f
	b	relocate_code # 重定位u-boot
	bl	relocate_vectors #重定位异常向量表
	SPL_CLEAR_BSS
	board_init_r
		run_main_loop
			main_loop
			s = bootdelay_process # s = "bootcmd"
			autoboot_command(s) # 自动执行bootcmd
			cli_loop # 获取命令
```

经过`board_init_f_init_reserve`后

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230417154543.png)

经过`board_init_f`规划后新的u-boot分布：

调用`bd_info`命令可以查看relocate后各gd成员的地址。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230417142657.png)



env初始化

```c
// nor flash为例
env_init(); // board_f.c
	drv->init();

env_sf_init(); // CONFIG_ENV_IS_IN_SPI_FLAH sf.c drv->init();
    gd->env_addr = (ulong)&default_environment[0]; /// 加载默认的环境变量
    gd->env_valid = 1;


initr_env(); // board_r.c
	env_relocate();
		env_load();
			drv->load();

env_sf_load(); // sf.c drv->load();
	get_rst_mode();
	setup_flash_device(); // 初始化nor flash
		spi_flash_probe();
	spi_flash_read(flash, CONFIG_ENV_OFFSET, CONFIG_ENV_SIZE, buf); // 从flash上读环境变量
	env_import(buf, 1);
		crc32(0, ep->data, ENV_SIZE)； // check crc
		himport_r(); // 将环境变量存入一个hash table


env_get()
  if (gd->flags & GD_FLG_ENV_READY) { // board_r.c 初始化完环境变量后GD_FLG_ENV_READY
  ...
  }；
  env_get_f() // 在初始化环境变量前，会从default_environment[]中读取匹配变量，存入gd->env_buf
      env_match()
```

fdt初始化

```c
fdtdec_setup();
	board_fdt_blob_setup()
reserve_fdt();
reloc_fdt();
initr_get_fdt_offset();
	_do_get_offset("kernel");
		dma_copy_dtb_to_ddr("dtb_offset"); /// 拷贝dtb
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

# Uboot启动kernel

uboot用image_header来表示Legacy-uImage的头部

```c
typedef struct image_header {
	uint32_t	ih_magic;	/* Image Header Magic Number	*/
	uint32_t	ih_hcrc;	/* Image Header CRC Checksum	*/
	uint32_t	ih_time;	/* Image Creation Timestamp	*/
	uint32_t	ih_size;	/* Image Data Size		*/
	uint32_t	ih_load;	/* Data	 Load  Address		*/
	uint32_t	ih_ep;		/* Entry Point Address		*/
	uint32_t	ih_dcrc;	/* Image Data CRC Checksum	*/
	uint8_t		ih_os;		/* Operating System		*/
	uint8_t		ih_arch;	/* CPU architecture		*/
	uint8_t		ih_type;	/* Image Type			*/
	uint8_t		ih_comp;	/* Compression Type		*/
	uint8_t		ih_name[IH_NMLEN];	/* Image Name		*/
} image_header_t;
```

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230419101548.png)

`ih_magic=0x27051956`表示是一个`Legacy-uImage`

`ih_load=81000000`

`ih_ep=81000000`

`ih_os, ih_arch, ih_type, ih_comp=05, 02, 02, 00` 具体定义在uboot` image.h`中

```c
// cmd/bootm.c
bootm();
	do_bootm();
		do_bootm_states(BOOTM_STATE_START |
		BOOTM_STATE_FINDOS | BOOTM_STATE_FINDOTHER |
		BOOTM_STATE_LOADOS | BOOTM_STATE_OS_PREP |
         BOOTM_STATE_OS_FAKE_GO | BOOTM_STATE_OS_GO);

// common/bootm.c
bootm_start();
	images.verify = env_get_yesno("verify"); /// 不存在verify，return -1，默认为true
bootm_find_os(); // 填充bootm_headers_t images
	// 获取kernel image的data起始地址和长度
	os_hdr = boot_get_kernel(&images.os.image_start, &images.os.image_len);
		img_addr = genimg_get_kernel_addr_fit(); // 获取kernel地址
		genimg_get_image(img_addr);
		image_get_kernel(img_addr, images->verify);
         	image_print_contents(); // 打印信息
			image_check_dcrc(); // check crc
    images.os.type = image_get_type(os_hdr); /// Kernel Image
    images.os.comp = image_get_comp(os_hdr); /// uncompressed
    images.os.os = image_get_os(os_hdr); /// Linux
    images.os.end = image_get_image_end(os_hdr);
    images.os.load = image_get_load(os_hdr); /// 0x81000000
    images.os.arch = image_get_arch(os_hdr); /// ARM
	images.ep = image_get_ep(&images.legacy_hdr_os_copy); /// 0x81000000
	images.os.start = map_to_sysmem(os_hdr); // 0xC0000
bootm_find_other();
	bootm_find_images();
		boot_get_fdt(&images.ft_addr, &images.ft_len); // 获取fdt地址和长度
bootm_disable_interrupts();
bootm_load_os(images, 0);
	image_decomp(); // 这里会拷贝kernel image从flash到load address
boot_fn = bootm_os_get_boot_func(images->os.os);
boot_fn(BOOTM_STATE_OS_PREP, argc, argv, images);
	do_bootm_linux(); //arch/arm/lib/bootm.c
		boot_prep_linux(); //arch/arm/lib/bootm.c
			image_setup_linux(); // common/image.c
				boot_relocate_fdt();
				image_setup_libfdt();
			board_prep_linux(); // skip
boot_selected_os(argc, argv, BOOTM_STATE_OS_GO, images, boot_fn);
		boot_fn(state, argc, argv, images);
			do_bootm_linux();
				boot_jump_linux();
					kernel_entry = (void (*)(int, int, uint))images->ep;
					kernel_entry(0, machid, r2); // 进入kernel entry point
```



# Reference

[U-boot专栏](https://blog.csdn.net/ooonebook/category_6484145.html)

[Uboot PPT](%5B%3Chttps://xyc-1316422823.cos.ap-shanghai.myqcloud.com/uboot_introduction.ppt%3E%5D(%3Chttps://xyc-1316422823.cos.ap-shanghai.myqcloud.com/uboot_introduction.ppt%3E))
