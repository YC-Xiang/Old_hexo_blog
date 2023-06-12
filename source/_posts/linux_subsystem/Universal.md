---
title: Linux Driver Common Essentials
date: 2023-05-19 22:25:00
tags:
- Linux driver
categories:
- Notes
sticky: 99
---

# NOT indexed

include <asm/xxx.h> 先找arch/xxx/include/xxx.h，没有的话就找/include/asm-generic/xxx.h



从dts中获取regs地址并映射到virtual address:

linux5.10: void __iomem *devm_platform_get_and_ioremap_resource(struct platform_device *pdev, unsigned int index, struct resource **res)

linux5.4: void __iomem *devm_platform_ioremap_resource(struct platform_device *pdev, unsigned int index)

相当于platform_get_resource + devm_request_mem_region **+** devm_ioremap



container_of: 

```c
#define list_entry(ptr, type, member) \ /// list_entry作用和container_of相同
	container_of(ptr, type, member)

container_of(ptr, type, member)

// ptr:表示结构体中member的地址 h
// type:表示结构体类型 struct xxx
// member:表示结构体中的成员 yyy
// 返回结构体的首地址
```



# Initcalls

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230524150950.png)

- 图中initcalls优先级从上到下。这些都是只能用于builtin的modules。loadable的modules使用module_init()。

- 使用initcalls会在目标文件object file中创建ELF sections。

**module_init()**

本质是device_initcall。

```c
#define module_init(x)	__initcall(x);
#define __initcall(fn) device_initcall(fn)
```

kernel的`System.map`可以查看符号文件，其中`__initcall6_start`后的顺序就对应`device_initcall`的驱动加载顺序。

```c
#define pure_initcall(fn)		__define_initcall(fn, 0)

#define core_initcall(fn)		__define_initcall(fn, 1)
#define postcore_initcall(fn)		__define_initcall(fn, 2)
#define arch_initcall(fn)		__define_initcall(fn, 3)
#define subsys_initcall(fn)		__define_initcall(fn, 4)
#define fs_initcall(fn)			__define_initcall(fn, 5)
#define rootfs_initcall(fn)		__define_initcall(fn, rootfs)
#define device_initcall(fn)		__define_initcall(fn, 6)
#define late_initcall(fn)		__define_initcall(fn, 7)
```
