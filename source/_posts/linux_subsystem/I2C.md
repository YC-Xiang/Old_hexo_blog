---
title: I2C subsystem
date: 2023-04-13 17:40:28
tags:
- Linux driver
categories:
- Notes
---

# I2C 基础知识

## 写操作

- 主芯片要发出一个start信号
- 然后发出一个设备地址(用来确定是往哪一个芯片写数据)，方向(读/写，0表示写，1表示读)
- 从设备回应(用来确定这个设备是否存在)，然后就可以传输数据
- 主设备发送一个字节数据给从设备，并等待回应
- 每传输一字节数据，接收方要有一个回应信号（确定数据是否接受完成)，然后再传输下一个数据。
- 数据发送完之后，主芯片就会发送一个停止信号。

下图：白色背景表示"主→从"，灰色背景表示"从→主"

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230414143312.png)

## 读操作

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230414143336.png)

## I2C信号

I2C协议中数据传输的单位是字节，也就是8位。但是要用到9个时钟：前面8个时钟用来传输8数据，第9个时钟用来传输回应信号。传输时，先传输最高位(MSB)。

- 开始信号（S）：SCL为高电平时，SDA山高电平向低电平跳变，开始传送数据。
- 结束信号（P）：SCL为高电平时，SDA由低电平向高电平跳变，结束传送数据。
- 响应信号(ACK)：接收器在接收到8位数据后，在第9个时钟周期，拉低SDA
- SDA上传输的数据必须在SCL为高电平期间保持稳定，SDA上的数据只能在SCL为低电平期间变化

I2C协议信号如下：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230414143408.png)

## SMBus协议

System Management Bus，系统管理总线。**是I2C协议的一个子集**

- VDD的极限值不一样

  - I2C协议：范围很广，甚至讨论了高达12V的情况
  - SMBus：1.8V~5V

- 最小时钟频率、最大的Clock Stretching

  - Clock Stretching含义：某个设备需要更多时间进行内部的处理时，它可以把SCL拉低占住I2C总线
  - I2C协议：时钟频率最小值无限制，Clock Stretching时长也没有限制
  - SMBus：时钟频率最小值是10KHz，Clock Stretching的最大时间值也有限制

- 地址回应(Address Acknowledge)

  - 一个I2C设备接收到它的设备地址后，是否必须发出回应信号？
  - I2C协议：没有强制要求必须发出回应信号
  - SMBus：强制要求必须发出回应信号，这样对方才知道该设备的状态：busy，failed，或是被移除了

- SMBus协议明确了数据的传输格式

  - I2C协议：它只定义了怎么传输数据，但是并没有定义数据的格式，这完全由设备来定义
  - SMBus：定义了几种数据格式(后面分析)

- REPEATED START Condition(重复发出S信号)

  - 比如读EEPROM时，涉及2个操作：

    - 把存储地址发给设备
    - 读数据

  - 在写、读之间，可以不发出P信号，而是直接发出S信号：这个S信号就是`REPEATED START`

  - 如下图所示

    ![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230414143735.png)

- SMBus Low Power Version

  - SMBus也有低功耗的版本



# I2C provider

http://www.wowotech.net/comm/i2c_provider.html

`i2c_adapter`抽象I2C控制器

```c
struct i2c_adapter {
	struct module *owner;
	unsigned int class;		  /* classes to allow probing for */
	const struct i2c_algorithm *algo; /* the algorithm to access the bus */
	void *algo_data;

	/* data fields that are valid for all devices	*/
	const struct i2c_lock_operations *lock_ops;
	struct rt_mutex bus_lock;
	struct rt_mutex mux_lock;

	int timeout;			/* in jiffies */
	int retries;
	struct device dev;		/* the adapter device */
	unsigned long locked_flags;	/* owned by the I2C core */
#define I2C_ALF_IS_SUSPENDED		0
#define I2C_ALF_SUSPEND_REPORTED	1

	int nr;
	char name[48];
	struct completion dev_released;

	struct mutex userspace_clients_lock;
	struct list_head userspace_clients;

	struct i2c_bus_recovery_info *bus_recovery_info;
	const struct i2c_adapter_quirks *quirks;

	struct irq_domain *host_notify_domain;
};
```

`i2c_algorithm`抽象了通过I2C总线发送和接收数据的方法

```c
struct i2c_algorithm {
	int (*master_xfer)(struct i2c_adapter *adap, struct i2c_msg *msgs,
			   int num);
  	// 功能跟master_xfer一样，在atomic context环境下使用
	int (*master_xfer_atomic)(struct i2c_adapter *adap,
				   struct i2c_msg *msgs, int num);
    // 实现SMBus传输，如果不提供这个函数，SMBus传输会使用master_xfer来模拟
	int (*smbus_xfer)(struct i2c_adapter *adap, u16 addr,
			  unsigned short flags, char read_write,
			  u8 command, int size, union i2c_smbus_data *data);
	int (*smbus_xfer_atomic)(struct i2c_adapter *adap, u16 addr,
				 unsigned short flags, char read_write,
				 u8 command, int size, union i2c_smbus_data *data);

	/* To determine what the adapter supports */
	u32 (*functionality)(struct i2c_adapter *adap);

#if IS_ENABLED(CONFIG_I2C_SLAVE)
  	// reg_slave就是把一个i2c_client注册到I2C Adapter，就是让这个I2C Adapter模拟该i2c_client
	int (*reg_slave)(struct i2c_client *client);
	int (*unreg_slave)(struct i2c_client *client);
#endif
};
```

I2C传输以`i2c_msg`为单位

```c
struct i2c_msg {
	__u16 addr;	/* slave address*/
	__u16 flags;
#define I2C_M_RD		0x0001	/* read data, from slave to master */
					/* I2C_M_RD is guaranteed to be 0x0001! */
#define I2C_M_TEN		0x0010	/* this is a ten bit chip address */
#define I2C_M_DMA_SAFE		0x0200	/* the buffer of this message is DMA safe */
					/* makes only sense in kernelspace */
					/* userspace buffers are copied anyway */
#define I2C_M_RECV_LEN		0x0400	/* length will be first received byte */
#define I2C_M_NO_RD_ACK		0x0800	/* if I2C_FUNC_PROTOCOL_MANGLING */
#define I2C_M_IGNORE_NAK	0x1000	/* if I2C_FUNC_PROTOCOL_MANGLING */
#define I2C_M_REV_DIR_ADDR	0x2000	/* if I2C_FUNC_PROTOCOL_MANGLING */
#define I2C_M_NOSTART		0x4000	/* if I2C_FUNC_NOSTART */
#define I2C_M_STOP		0x8000	/* if I2C_FUNC_PROTOCOL_MANGLING */
	__u16 len;		/* msg length				*/
	__u8 *buf;		/* pointer to msg data			*/
};
```

# I2C consumer

http://www.wowotech.net/comm/i2c_consumer.html

**形态1**：CPU和设备之间的所有数据交互，都是通过I2C总线进行。

**形态2**：I2C只是CPU和设备之间进行数据交互的一种，例如HDMI，图像以及音频数据通过TDMS接口传输，EDID等信息的交互通过I2C总线。



**形态1**：直接在device tree中i2c设备节点下加一个子节点。

```c
&i2c1 {
        clock-frequency = <100000>;
        pinctrl-names = "default";
        pinctrl-0 = <&pinctrl_i2c1>;
        status = "okay";
        …
        pmic: pf0100@08 {
                compatible = "fsl,pfuze100";
                …
        };
```

**形态2**：在自己的设备节点下引用i2c节点。

```c
&hdmi {
       ddc-i2c-bus = <&i2c2>;
        status = "okay";
};
```

## 驱动编写步骤

**形态1**：需要编写一个`i2c driver`。定义一个`struct i2c_driver`类型的变量，并调用`module_i2c_driver`接口将其注册到`I2C core`中。

以`struct i2c_client`指针为参数，可以调用`i2c_master_send/i2c_master_recv`接口进行简单的I2C传输，同时，也可以通过该指针获得所属的`I2C adapter`指针，然后通过`i2c_transfer`接口，进行更为复杂的read、write操作。

**形态2**：通过设备树API接口获得`struct i2c_adapter`指针，通过`i2c_transfer`接口，进行read、write操作。

```c
adap = of_parse_phandle(dev->of_node, "ddc-i2c-bus", 0);
if (adap) {
        panel->adap = of_find_i2c_adapter_by_node(adap); //获取i2c adapter指针
        of_node_put(adap);
}
```



`i2c client`抽象i2c设备

```c
struct i2c_client {
	unsigned short flags;		/* flags，指示该I2C slave device一些特性 */
#define I2C_CLIENT_PEC		0x04	/* Use Packet Error Checking */
#define I2C_CLIENT_TEN		0x10	/* we have a ten bit chip address */
					/* Must equal I2C_M_TEN below */
#define I2C_CLIENT_SLAVE	0x20	/* we are the slave */
#define I2C_CLIENT_HOST_NOTIFY	0x40	/* We want to use I2C host notify */
#define I2C_CLIENT_WAKE		0x80	/* for board_info; true iff can wake */
#define I2C_CLIENT_SCCB		0x9000	/* Use Omnivision SCCB protocol */
					/* Must match I2C_M_STOP|IGNORE_NAK */

	unsigned short addr;		/* 该设备的7-bit的slave地址。	*/
					/* addresses are stored in the	*/
					/* _LOWER_ 7 bits		*/
	char name[I2C_NAME_SIZE];
	struct i2c_adapter *adapter;	/* 该设备所在的I2C controller	*/
	struct device dev;		/* the device structure		*/
	int init_irq;			/* irq set at initialization	*/
	int irq;			/* irq issued by device		*/
	struct list_head detected;
#if IS_ENABLED(CONFIG_I2C_SLAVE)
	i2c_slave_cb_t slave_cb;	/* callback for slave mode	*/
#endif
};
```

通常情况下，`struct i2c_client`变量是由I2C core在register adapter的时候，解析adapter的child node自行创建的。该数据结构中的有些信息，可通过DTS配置。

```c
xxx:xxx@08 {
        reg = <0x08>;                               /* 对应struct i2c_client中的‘addr’*/
        interrupts = <16 8>;                       /* 对应struct i2c_client中的‘irq’*/
        wakeup-source;                             /* 对应flags中的I2C_CLIENT_WAKE */
};
```



# Synopsys DesignWare I2C driver

i2c 传输的频率可以通过设备树`"clock-frequency"`来设置`t->bus_freq_hz`。不设置则为默认的400kHz

```c
dw_i2c_plat_probe()
  	struct dw_i2c_dev *dev;
  	dw_i2c_plat_request_regs(dev);
		dev->base = devm_platform_ioremap_resource(pdev, 0);
	i2c_parse_fw_timings(&pdev->dev, t, false);
	i2c_dw_configure();
          i2c_dw_configure_slave();
          i2c_dw_configure_master(); // 设置一些dev->func dev->master_cfg等属性后续使用
     i2c_dw_probe()
          i2c_dw_probe_slave();
		 i2c_dw_probe_master();

i2c_dw_probe_master(struct dw_i2c_dev *dev)
  	dev->init = i2c_dw_init_master;
	dev->disable = i2c_dw_disable;
	dev->disable_int = i2c_dw_disable_int;
	i2c_dw_init_regmap();
    i2c_dw_set_timings_master(); //设置standard/fast h/lcnt
		i2c_dw_set_sda_hold(); // 设置sda_hold,不过rts直接在dev->init中设置为20
    i2c_dw_set_fifo_size(); //设置tx/rx_fifo_depth
	dev->init(); // 写之前设置好配置的寄存器
		__i2c_dw_disable(); // disable adapter
			__i2c_dw_disable_nowait();
		i2c_dw_configure_fifo_master();	//写tx/rx_fifo寄存器,根据dev->master_cfg写con寄存器
	i2c_dw_disable_int(); // 先把中断mask全部置1，禁止中断
	devm_request_irq();
	i2c_dw_init_recovery_info();
	i2c_add_numbered_adapter();
```
