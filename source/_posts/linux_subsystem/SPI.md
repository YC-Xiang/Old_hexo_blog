---
title: Spi Subsystem
date: 2023-05-22 17:40:28
tags:
- Linux driver
categories:
- Notes
---

# 1. SPI协议介绍

CPOL:表示SPICLK的初始电平，0为低电平，1为高电平

CPHA:表示相位，即第一个还是第二个时钟沿采样数据，0为第一个时钟沿，1为第二个时钟沿

| CPOL | CPHA | 模式 | 含义                                           |
| ---- | ---- | ---- | ---------------------------------------------- |
| 0    | 0    | 0    | SPICLK初始电平为低电平，在第一个时钟沿采样数据 |
| 0    | 1    | 1    | SPICLK初始电平为低电平，在第二个时钟沿采样数据 |
| 1    | 0    | 2    | SPICLK初始电平为高电平，在第一个时钟沿采样数据 |
| 1    | 1    | 3    | SPICLK初始电平为高电平，在第二个时钟沿采样数据 |

我们常用的是模式0和模式3，因为它们都是在上升沿采样数据，不用去在乎时钟的初始电平是什么，只要在上升沿采集数据就行。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230522180216.png)

# 2. SPI driver

## 2.2 spi_controller

include/linux/spi.h

## 2.3 spi_device

include/linux/spi.h

## 2.4 spi_transfer、spi_message

在SPI子系统中，用spi_transfer结构体描述一个传输，用spi_message管理整个传输。可以构造多个spi_transfer结构体，把它们放入一个spi_message里面。

SPI传输时，发出N个字节，就可以同时得到N个字节。

- 即使只想读N个字节，也必须发出N个字节：可以发出0xff
- 即使只想发出N个字节，也会读到N个字节：可以忽略读到的数据。

# 3. SPI 设备树处理

**SPI Master**

必须的属性如下：

- address-cells：这个SPI Master下的SPI设备，需要多少个cell来表述它的片选引脚
- size-cells：必须设置为0
- compatible：根据它找到SPI Master驱动

可选的属性如下：

- cs-gpios：SPI Master可以使用多个GPIO当做片选，可以在这个属性列出那些GPIO
- num-cs：片选引脚总数

**SPI Device**

必须的属性如下：

- compatible：根据它找到SPI Device驱动
- reg：用来表示它使用哪个片选引脚
- spi-max-frequency：必选，该SPI设备支持的最大SPI时钟

可选的属性如下：

- spi-cpol：这是一个空属性(没有值)，表示CPOL为1，即平时SPI时钟为低电平
- spi-cpha：这是一个空属性(没有值)，表示CPHA为1)，即在时钟的第2个边沿采样数据
- spi-cs-high：这是一个空属性(没有值)，表示片选引脚高电平有效
- spi-3wire：这是一个空属性(没有值)，表示使用SPI 三线模式
- spi-lsb-first：这是一个空属性(没有值)，表示使用SPI传输数据时先传输最低位(LSB)
- spi-tx-bus-width：表示有几条MOSI引脚；没有这个属性时默认只有1条MOSI引脚
- spi-rx-bus-width：表示有几条MISO引脚；没有这个属性时默认只有1条MISO引脚
- spi-rx-delay-us：单位是毫秒，表示每次读传输后要延时多久
- spi-tx-delay-us：单位是毫秒，表示每次写传输后要延时多久

示例：

```c
spi@f00 {
		#address-cells = <1>;
		#size-cells = <0>;
		compatible = "fsl,mpc5200b-spi","fsl,mpc5200-spi";
		reg = <0xf00 0x20>;
		interrupts = <2 13 0 2 14 0>;
		interrupt-parent = <&mpc5200_pic>;

		ethernet-switch@0 {
			compatible = "micrel,ks8995m";
			spi-max-frequency = <1000000>;
			reg = <0>;
		};

		codec@1 {
			compatible = "ti,tlv320aic26";
			spi-max-frequency = <100000>;
			reg = <1>;
		};
	};
```

# 4. spidev的使用(SPI用户态API)

- 内核驱动：`drivers\spi\spidev.c`
- 内核提供的测试程序：`tools\spi\spidev_fdx.c`
- 内核文档：`Documentation\spi\spidev`

## 4.1 spidev驱动程序分析

内核驱动：`drivers\spi\spidev.c`

```c
spidev_write();
	spidev_sync_write();
		spidev_sync();

spidev_read();
	spidev_sync_read();
		spidev_sync();

spidev_ioctl();
// 在应用层通过ioctl(fd, SPI_IOC_MESSAGE(x), xfer) 来调用，进行spi传输. 参考spidev_fdx.c
```

## 4.2 spidev应用程序分析

内核提供的测试程序：`tools\spi\spidev_fdx.c`

使用方法：

spidev_fdx [-h] [-m N] [-r N] /dev/spidevB.D

h: 打印用法

m N：先写1个字节0xaa，再读N个字节，**注意：**不是同时写同时读

r N：读N个字节

## 4.3 spidev缺点

使用read、write函数时，只能读、写，这是半双工方式。

使用ioctl可以达到全双工的读写。

但是spidev有2个缺点：

- 不支持中断
- 只支持同步操作，不支持异步操作：就是read/write/ioctl这些函数只能执行完毕才可返回

### 5.1 SPI传输接口函数

```c
/include/linux/spi/spi.h
// 简易函数
static inline int spi_write(struct spi_device *spi, const void *buf, size_t len);
static inline int spi_read(struct spi_device *spi, void *buf, size_t len);
extern int spi_write_then_read(struct spi_device *spi, const void *txbuf, unsigned n_tx, void *rxbuf, unsigned n_rx);
static inline ssize_t spi_w8r8(struct spi_device *spi, u8 cmd);
static inline ssize_t spi_w8r16(struct spi_device *spi, u8 cmd);
static inline ssize_t spi_w8r16be(struct spi_device *spi, u8 cmd);

// 复杂函数
extern int spi_async(struct spi_device *spi, struct spi_message *message);
extern int spi_sync(struct spi_device *spi, struct spi_message *message);
static inline int spi_sync_transfer(struct spi_device *spi, struct spi_transfer *xfers, unsigned int num_xfers);
```