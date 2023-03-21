---
title: PWM子系统
date: 2023-03-21 16:00:00
tags:
- PWM
categories:
- Linux内核分析
---

# PWM 子系统

# PWM原理

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/RISC-V%E4%B8%AD%E6%96%87%E6%89%8B%E5%86%8C/Untitled.png)

利用微处理器的数字输出来对模拟电路进行控制的一种非常有效的技术，其本质是一种对模拟信号电平进行数字编码的方法。在嵌入式设备中，PWM多用于控制马达、LED、振动器等模拟器件。

- 脉冲周期（T），单位是时间，ns, us ,ms。
- 脉冲频率（f），单位是赫兹（Hz），与脉冲周期成倒数关系，f=1/T。
- 脉冲宽度（W），简称“脉宽”，是脉冲高电平持续的时间。单位是时间，ns, us, ms。
- 占空比（D），脉宽除以脉冲周期的值。

W = ton

T = ton + toff = 1/f

D = ton / (ton+ toff) = ton / T

# PWM consumer

```c
/* include/linux/pwm.h */
int pwm_config(struct pwm_device *pwm, int duty_ns, int period_ns);
int pwm_enable(struct pwm_device *pwm);
void pwm_disable(struct pwm_device *pwm);
int pwm_set_polarity(struct pwm_device *pwm, enum pwm_polarity polarity);
```

pwm_config，用于控制PWM输出信号的频率和占空比，其中频率是以周期（period_ns）的形式配置的，占空比是以有效时间（duty_ns）的形式配置的。

pwm_enable/pwm_disable，用于控制PWM信号输出与否。

pwm_set_polarity，可以更改pwm信号的极性，可选参数包括normal（PWM_POLARITY_NORMAL）和inversed（极性翻转，PWM_POLARITY_INVERSED）两种。

上面的API都以struct pwm_device类型的指针为操作句柄，该指针抽象了一个PWM设备，那么怎么获得PWM句柄呢？使用如下的API：

```c
 /* include/linux/pwm.h */
struct pwm_device *pwm_get(struct device *dev, const char *con_id);
struct pwm_device *of_pwm_get(struct device_node *np, const char *con_id);
void pwm_put(struct pwm_device *pwm);
struct pwm_device *devm_pwm_get(struct device *dev, const char *con_id);
struct pwm_device *devm_of_pwm_get(struct device *dev, struct device_node *np, const char *con_id);
void devm_pwm_put(struct device *dev, struct pwm_device *pwm);
```

pwm_get/devm_pwm_get，从指定设备（dev）的DTS节点中，获得对应的PWM句柄。可以通过con_id指定一个名称，或者会获取和该设备绑定的第一个PWM句柄。设备的DTS文件需要用这样的格式指定所使用的PWM device：

```c
bl: backlight {       
pwms = <&pwm 0 5000000 PWM_POLARITY_INVERTED>;       
pwm-names = "backlight";
};
```

如果“con_id”为NULL，则返回DTS中“pwms”字段所指定的第一个PWM device；如果“con_id”不为空，如是“backlight”，则返回和“pwm-names ”字段所指定的name对应的PWM device。

上面“pwms”字段各个域的含义如下：
1）&pwm，对DTS中pwm节点的引用；
2）0，pwm device的设备号，具体需要参考SOC以及pwm driver的实际情况；
3）5000000，PWM信号默认的周期，单位是纳秒（ns）；
4）PWM_POLARITY_INVERTED，可选字段，是否提供由pwm driver决定，表示pwm信号的极性，若为0，则正常极性，若为PWM_POLARITY_INVERTED，则反转极性。

of_pwm_get/devm_of_pwm_get，和pwm_get/devm_pwm_get类似，区别是可以指定需要从中解析PWM信息的device node，而不是直接指定device指针。

# PWM provider

### 2.1 pwm_chip

抽象PWM控制器

在一个SOC中，可以同时支持多路PWM输出，以便同时控制多个PWM设备。这样每一路PWM输出，可以看做一个PWM设备（由上面struct pwm_device抽象）

```c
/**
 * struct pwm_chip - abstract a PWM controller
 * @dev: device providing the PWMs
 * @ops: callbacks for this PWM controller
 * @base: number of first PWM controlled by this chip
 * @npwm: number of PWMs controlled by this chip
 * @of_xlate: request a PWM device given a device tree PWM specifier
 * @of_pwm_n_cells: number of cells expected in the device tree PWM specifier
 * @list: list node for internal use
 * @pwms: array of PWM devices allocated by the framework
 */
struct pwm_chip {
	struct device *dev;
	const struct pwm_ops *ops;
	int base;
	unsigned int npwm;

	struct pwm_device * (*of_xlate)(struct pwm_chip *pc,
					const struct of_phandle_args *args);
	unsigned int of_pwm_n_cells;

	/* only used internally by the PWM framework */
	struct list_head list;
	struct pwm_device *pwms;
};
```

**dev**，该pwm chip对应的设备，一般由pwm driver对应的platform驱动指定。必须提供！

**ops**，操作PWM设备的回调函数，后面会详细介绍。必须提供！

**npwm**，该pwm chip可以支持的pwm channel（也可以称作pwm device由struct pwm_device表示）个数，kernel会根据该number，分配相应个数的struct pwm_device结构，保存在pwms指针中。必须提供！

**pwms**，保存所有pwm device的数组，kernel会自行分配，不需要driver关心。

**base**，在将该chip下所有pwm device组成radix tree时使用，只有旧的pwm_request接口会使用，因此忽略它吧，编写pwm driver不需要关心。

**of_pwm_n_cells**，该PWM chip所提供的DTS node的cell，一般是2或者3，例如：为3时，consumer需要在DTS指定pwm number、pwm period和pwm flag三种信息（如2.1中的介绍）；为2时，没有flag信息。

**of_xlate**，用于解析consumer中指定的、pwm信息的DTS node的回调函数（如2.1中介绍的，pwms = <&pwm 0 5000000 PWM_POLARITY_INVERTED>）。

注2：一般情况下，of_pwm_n_cells取值为3，或者2（不关心极性），of_xlate则可以使用kernel提供的of_pwm_xlate_with_flags（解析of_pwm_n_cells为3的chip）或者of_pwm_simple_xlate（解析of_pwm_n_cells为2的情况）。具体的driver可以根据实际情况修改上述规则，但不到万不得已的时候，不要做这种非标准的、掏力不讨好的事情！（有关of_xlate的流程，会在下一篇流程分析的文章中介绍。）

### 2.2 pwm_ops

```c
struct pwm_ops {
	int (*request)(struct pwm_chip *chip, struct pwm_device *pwm);
	void (*free)(struct pwm_chip *chip, struct pwm_device *pwm);
	int (*capture)(struct pwm_chip *chip, struct pwm_device *pwm,
		       struct pwm_capture *result, unsigned long timeout);
	int (*apply)(struct pwm_chip *chip, struct pwm_device *pwm,
		     const struct pwm_state *state);
	void (*get_state)(struct pwm_chip *chip, struct pwm_device *pwm,
			  struct pwm_state *state);
	struct module *owner;

	/* Only used by legacy drivers */
	int (*config)(struct pwm_chip *chip, struct pwm_device *pwm,
		      int duty_ns, int period_ns);
	int (*set_polarity)(struct pwm_chip *chip, struct pwm_device *pwm,
			    enum pwm_polarity polarity);
	int (*enable)(struct pwm_chip *chip, struct pwm_device *pwm);
	void (*disable)(struct pwm_chip *chip, struct pwm_device *pwm);
};
```

这些回调函数的操作对象是具体的pwm device（由struct pwm_device类型的指针表示），包括：

config，配置pwm device的频率、占空比。必须提供！

enable/disable，使能/禁止pwm信号输出。必须提供！

request/free，不再使用。

set_polarity，设置pwm信号的极性。可选，具体需要参考of_pwm_n_cells的定义。

### 2.3 pwm device

```c
struct pwm_device {
	const char *label;
	unsigned long flags;
	unsigned int hwpwm;
	unsigned int pwm;
	struct pwm_chip *chip;
	void *chip_data;

	struct pwm_args args;
	struct pwm_state state;
};
```

pwm driver比较关心的字段是：

hwpwm，该pwm device对应的hardware pwm number，可用于寄存器的寻址操作。

period、duty_cycle、polarity，pwm信号的周期、占空比、极性等信息。

### 2.4 **pwmchip_add/pwmchip_remove**

初始化完成后的pwm chip可以通过pwmchip_add接口注册到kernel中，之后的事情，pwm driver就不用操心了。该接口的原型如下：

```c
  1: int pwmchip_add(struct pwm_chip *chip);
  2: int pwmchip_remove(struct pwm_chip *chip);
```

# API使用指南

### 3.2 provider编写PWM driver的步骤

1）创建代表该pwm driver的DTS节点，并提供platform device有关的资源信息，例如：

2）定义一个**pwm chip**变量。

3）注册相应的platform driver，并在driver的.probe()接口中，初始化pwm chip变量，至少要包括如下字段：

dev，使用platform device中的dev指针即可；npwm；ops，至少包括config、enable、disable三个回调函数。

**如果该pwm chip支持额外的flag（如PWM极性，或者自定义的flag），将PWM cell指定为3（of_pwm_n_cells），of_xlate指定为of_pwm_xlate_with_flags。**

4）每当consumer有API调用时，kernel会以pwm device为参数，调用pwm driver提供的pwm ops，相应的回调函数可以从pwm device中取出pwm number（该number的意义driver自行解释），并操作对应的寄存器即可。

### 3.3 **consumer使用PWM的步骤**

1）查看pwm provider所提供的pwm dts binding信息（一般会在“Documentation/devicetree/bindings/pwm”目录中），并以此在该device所在的dts node中添加“pwms ”以及“pwm-names ”相关的配置。例如：

```c
/* arch\arm\boot\dts\imx23-evk.dts */

backlight {       
compatible = "pwm-backlight";        
pwms = <&pwm 2 5000000>;       
brightness-levels = <0 4 8 16 32 64 128 255>;       
default-brightness-level = <6>;
};
```

2）在driver的probe接口中，调用**devm_pwm_get**接口，获取**pwm device**句柄，并保存起来。

3）devm_pwm_get成功后，该pwm信号已经具备初始的周期和极性。后续根据需要，可以调用**pwm_config**和**pwm_set_polarity**更改该pwm信号的周期、占空比和极性。

4）driver可以根据需要，调用**pwm_enable/pwm_disable**接口，打开或者关闭pwm信号的输出。

# Reference

原理介绍：[https://zhuanlan.zhihu.com/p/374083276](https://zhuanlan.zhihu.com/p/374083276)

Driver解析：[http://www.wowotech.net/comm/pwm_overview.html](http://www.wowotech.net/comm/pwm_overview.html)
