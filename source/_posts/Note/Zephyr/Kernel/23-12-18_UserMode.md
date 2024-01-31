---
title: Zephyr -- System  Call
date: 2023-12-18 14:18:28
tags:
- Zephyr
categories:
- Zephyr OS
---

## C Prototype

系统调用函数必须以`__syscall`开头，在`include/`或`SYSCALL_INCLUDE_DIRS`目录下被声明。

`scripts/build/parse_syscalls.py`会parse`__syscall`这个标记，并且函数有以下限制：

- 参数不能传入数组，比如`int foo[]` or `int foo[12]`, 必须用`int *foo`代替。
- 函数指针不能正常解析，需要先对函数指针`typedef`，再传入。

定义了系统调用的`xxx.h`头文件必须要文件末尾加上同名的`#include <syscall/xxx.h>`。

### Invocation Context 调用上下文

- 如果定义了`CONFIG_USERSPACE`，所有的system call APIs都会直接调用对应的implementation function。
- 如果定义了`__ZEPHYR_SUPERVISOR__`，表示所有code都在supervisor mode下运行，直接调用对应的implementation function。
- 如果定义了`__ZEPHYR_USER__`

### Implementation Detail 实现细节

`scripts/build/gencalls.py`会把parse到的system calls放进`/build/include/generated/syscall_list.h`中。以`K_SYSCALL_`前缀加上API。

所有可以调用的system calls被保存在`syscall_dispatch.c`中的`_k_syscall_table`中。

system calls的API实现被保存在了`/build/include/generated/syscalls/xxx.h` 这些文件被`/include/xxx.h`文件最后include进去，完成函数的定义。e.g

```c
// include/i2c.h
__syscall int i2c_configure(const struct device *dev, uint32_t dev_config); //声明

static inline int z_impl_i2c_configure(const struct device *dev,
				       uint32_t dev_config)
{
	const struct i2c_driver_api *api =
		(const struct i2c_driver_api *)dev->api;

	return api->configure(dev, dev_config);
}
//...
#include <syscalls/i2c.h>

// build/include/generated/syscalls/i2c.h
extern int z_impl_i2c_configure(const struct device * dev, uint32_t dev_config);

__pinned_func
static inline int i2c_configure(const struct device * dev, uint32_t dev_config)
{
#ifdef CONFIG_USERSPACE
        if (z_syscall_trap()) {
                union { uintptr_t x; const struct device * val; } parm0 = { .val = dev };
                union { uintptr_t x; uint32_t val; } parm1 = { .val = dev_config };
                return (int) arch_syscall_invoke2(parm0.x, parm1.x, K_SYSCALL_I2C_CONFIGURE);
        }
#endif
        compiler_barrier();
        return z_impl_i2c_configure(dev, dev_config);
}

```
