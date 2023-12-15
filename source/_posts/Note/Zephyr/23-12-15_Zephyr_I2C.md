---
title: Zephyr -- I2C framework
date: 2023-12-15 14:06:28
tags:
- Zephyr
categories:
- Zephyr OS
---

## 应用层

首先看看Zephyr给应用层提供了哪些重要的接口。

```c
// drivers/i2c.h
__syscall int i2c_configure(const struct device *dev, uint32_t dev_config);
__syscall int i2c_get_config(const struct device *dev, uint32_t *dev_config);

static inline int i2c_write(const struct device *dev, const uint8_t *buf,
			 uint32_t num_bytes, uint16_t addr)
static inline int i2c_read(const struct device *dev, uint8_t *buf,
			   uint32_t num_bytes, uint16_t addr)
static inline int i2c_write_read(const struct device *dev, uint16_t addr,
				 const void *write_buf, size_t num_write,
				 void *read_buf, size_t num_read)
__syscall int i2c_transfer(const struct device *dev,
			   struct i2c_msg *msgs, uint8_t num_msgs,
			   uint16_t addr);
```

参考`zephyr/tests/drivers/i2c/i2c_api/src/test_i2c.c`中的流程:

```c
// 首先调用i2c_configure, 配置i2c controller。
i2c_configure(i2c_dev, i2c_cfg);
// 接着调用get_config, 判断配置是否下对。
i2c_get_config(i2c_dev, &i2c_cfg_tmp);
// 可以发送i2c数据了。
i2c_write(i2c_dev, datas, 2, 0x1E);
// i2c read读回。
i2c_read(i2c_dev, datas, 6, 0x1E);
```

### Shell I2C 传输

## 驱动层

`i2c_configure`会调用到driver的`api->configure`。以`i2c_dw.c` dwsignware i2c ip为例，会进入`i2c_dw_runtime_configure`配置函数。

主要做的事情有：

1. 保存好传入的配置到dw->app_config。
2. 根据传入的i2c speed配置i2c的lcnt,hcnt。
3. 清中断。

<p class="note note-warning">注意这边.configure函数并没有真正把配置写到寄存器中, 而是在.transfer函数中的set_up函数才会写入</p>

```c
static int i2c_dw_runtime_configure(const struct device *dev, uint32_t config)
{
	//...
	dw->lcnt = value;
	dw->hcnt = value;
	//...
	read_clr_intr(reg_base);
	//...
}
```

`i2c_get_config`类似，调用`api->get_config()`，这里`i2c_dw.c`未实现该回调函数。

接下来看I2C的read，write函数。这两个函数传入设备`dev`, 数据`buffer`，`buffer length`, `slave address`即可传输i2c数据。
`i2c_read/i2c_write`->`i2c_transfer`->`api->transfer`->`i2c_dw_transfer`

看下底层的`i2c_dw_transfer`函数，调用了`i2c_dw_setup`做的事情有：

1. 先关闭i2c controller。
2. 屏蔽+清中断。
3. 将之前存入`dw->app_data`写入`IC_CON`寄存器。
4. 配置`IC_TAR`寄存器。
5. 配置`dw->lcnt`, `dw->hcnt` 等等参数，都写入寄存器。

配置完成后enable controller。`set_bit_enable_en(reg_base)`
接着就是一系列的发送i2c message配置流程。打开中断后因为`tx_empty`会进入ISR，发送/接收数据。
