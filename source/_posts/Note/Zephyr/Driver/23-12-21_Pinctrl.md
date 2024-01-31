---
title: Zephyr -- Pinctrl Subsystem
date: 2023-12-25 09:45:28
tags:
- Zephyr
categories:
- Zephyr OS
---

## Device Tree

Pinctrl controller节点：

所有可选的支持属性可以查阅`/dts/bindings/pinctrl/pincfg-node.yaml`，支持配置上下拉，驱动能力等等。具体支持属性要参考soc的yaml文件`/dts/bindings/pinctrl/xxx.yaml`

当设备节点调用`perip0_default`的时候，`group1~N`都会被apply。

```c
/* board-pinctrl.dtsi */
#include <vnd-soc-pkgxx.h>

&pinctrl {
    /* Node with pin configuration for default state */
    periph0_default: periph0_default {
        group1 {
            /* Mappings: PERIPH0_SIGA -> PX0, PERIPH0_SIGC -> PZ1 */
            pinmux = <PERIPH0_SIGA_PX0>, <PERIPH0_SIGC_PZ1>;
            /* Pins PX0 and PZ1 have pull-up enabled */
            bias-pull-up;
        };
        ...
        groupN {
            /* Mappings: PERIPH0_SIGB -> PY7 */
            pinmux = <PERIPH0_SIGB_PY7>;
        };
    };
};
```

使用pinctrl的设备节点：

```c

&periph0 {
    pinctrl-0 = <&periph0_default>;
    pinctrl-names = "default";
};
```

可以在pinctrl controller下面的pinctrl配置节点前加上`/omit-if-no-ref/`，表示这个节点没被引用的话会被丢弃，不会被解析到C头文件中。

```c
&pinctrl {
    /omit-if-no-ref/ periph0_siga_px0_default: periph0_siga_px0_default {
        pinmux = <VNDSOC_PIN(X, 0, MUX0)>;
    };
};
```

## Consumer

Device driver如何使用pinctrl配置引脚function:

以`i2c_dw.c`为例，
通过`PINCTRL_DT_INST_DEFINE(n)`, 创建该device对应的`pinctrl_dev_config`结构体。
通过`PINCTRL_DT_INST_DEV_CONFIG_GET(n)` 得到该`pinctrl_dev_config`结构体。

随后在init函数中调用`pinctrl_apply_state(rom->pcfg, PINCTRL_STATE_DEFAULT);`选择apply default的pinctrl配置。

如下：

```c
#define DT_DRV_COMPAT mydev
...
#include <zephyr/drivers/pinctrl.h>
...
struct mydev_config {
    ...
    /* Reference to mydev pinctrl configuration */
    const struct pinctrl_dev_config *pcfg;
    ...
};
...
static int mydev_init(const struct device *dev)
{
    const struct mydev_config *config = dev->config;
    int ret;
    ...
    /* Select "default" state at initialization time */
    ret = pinctrl_apply_state(config->pcfg, PINCTRL_STATE_DEFAULT);
    if (ret < 0) {
        return ret;
    }
    ...
}

#define MYDEV_DEFINE(i)                                                    \
    /* Define all pinctrl configuration for instance "i" */                \
    PINCTRL_DT_INST_DEFINE(i);                                             \
    ...                                                                    \
    static const struct mydev_config mydev_config_##i = {                  \
        ...                                                                \
        /* Keep a ref. to the pinctrl configuration for instance "i" */    \
        .pcfg = PINCTRL_DT_INST_DEV_CONFIG_GET(i),                         \
        ...                                                                \
    };                                                                     \
    ...                                                                    \
                                                                           \
    DEVICE_DT_INST_DEFINE(i, mydev_init, NULL, &mydev_data##i,             \
                          &mydev_config##i, ...);

DT_INST_FOREACH_STATUS_OKAY(MYDEV_DEFINE)
```

分析下`PINCTRL_DT_DEFINE`这个宏，

```c {.line-numbers}
#define PINCTRL_DT_DEFINE(node_id)					       \
	LISTIFY(DT_NUM_PINCTRL_STATES(node_id),				       \
		     Z_PINCTRL_STATE_PINS_DEFINE, (;), node_id);	       \
	Z_PINCTRL_STATES_DEFINE(node_id)				       \
	Z_PINCTRL_DEV_CONFIG_STATIC Z_PINCTRL_DEV_CONFIG_CONST		       \
	struct pinctrl_dev_config Z_PINCTRL_DEV_CONFIG_NAME(node_id) =	       \
	Z_PINCTRL_DEV_CONFIG_INIT(node_id)
```

</br>

2~3行针对dts某个device节点，有N个`pinctrl-<N>`就调用`Z_PINCTRL_STATE_PINS_DEFINE`函数，创建包含N个`pinctrl_soc_pin_t`结构体的数组, 每个结构体包含该`pinctrl-<N>`对应pinctrl controller节点所需要的pins。该结构体数组的具体创建过程由`Z_PINCTRL_STATE_PINS_INIT`决定，该宏需要不同厂商在`pinctrl_soc.h`中定义。

```c
struct pinctrl_soc_pin_t
{
	// need to define in `pinctrl_soc.h`
}
```

</br>

第4行，根据N个`pinctrl-<N>`创建`pinctrl_state`结构体数组，从`devicetree_generated.h`中获取结构体信息。

每个`pinctrl_state`结构体：

```c
struct pinctrl_state {
	const pinctrl_soc_pin_t *pins; // 对应上面2~3行创建的`pinctrl_soc_pin_t`结构体数组。
	uint8_t pin_cnt; // 该state包含多少个pin。
	uint8_t id = PINCTRL_STATE_XXX; // XXX可以是DEFAULT,SLEEP或自定义属性。
};
```

</br>

第5~7行，初始化一个`pinctrl_dev_config`结构体。

```c
struct pinctrl_dev_config {
#if defined(CONFIG_PINCTRL_STORE_REG) || defined(__DOXYGEN__)
	uintptr_t reg; // 该device的reg地址
#endif
	const struct pinctrl_state *states; // 即上面的`pinctrl_state`结构体数组。
	uint8_t state_cnt; // 包含的state数量。
};
```

</br>

结构体关系如下, 其中
`pinctrl_dev_config` 是每个device拥有一个。
`pinctrl_state` 对应每个device的一个pinctrl state, 即dts中的`pinctrl-<N>`。
`pinctrl_soc_pin_t` 对应一个pin，包含了pin number, config配置信息等。
![Pinctrl 结构体](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/pinctrl.png)

## Provider

Pinctrl Driver实现:
主要需要实现回调函数`pinctrl_configure_pins(const pinctrl_soc_pin_t *pins, uint8_t pin_cnt, uintptr_t reg)`。
`pinctrl_soc_pin_t *pins`：某个pinctrl state包含的pins链表。
`pin_cnt`：该state包含的pins数量。
`reg`: pinctrl controller的地址。

添加`pinctrl_soc.h`, 一般路径为`soc/<arch>/<vendor>/<board>/...`
在其中定义`pinctrl_soc_pin_t` 结构体。`Z_PINCTRL_STATE_PINS_INIT`宏，该宏接收两个参数，设备树node identifier和property name(pinctrl-N)，用来解析设备树属性。

参考ti-cc32xx pinctrl的实现，参考文件有：
`dts/bindings/pinctrl/ti,cc32xx-pinctrl.yaml`：描述设备树属性。
`soc/arm/ti_simplelink/cc32xx/pinctrl_soc.h`: 具体实现。
`include/zephyr/dt-bindings/pinctrl/ti-cc32xx-pinctrl.h`：头文件。
`boards/arm/cc3220sf_launchxl/cc3220sf_launchxl-pinctrl.dtsi`: pinctrl设备树。
`drivers/pinctrl/pinctrl_ti_cc32xx.cpinctrl_nrf.c`: pinctrl driver。

</br>

`pinctrl.dtsi`:

```c
&pinctrl {
	uart0_default: uart0_default {
		group1 {
			pinmux = <UART0_TX_P55>, <UART0_RX_P57>;
		};
	};

	i2c0_default: i2c0_default {
		group1 {
			pinmux = <I2C_SCL_P1>, <I2C_SDA_P2>;
		};
	};
};

&uart0 {
	pinctrl-0 = <&uart0_default>;
	pinctrl-names = "default";
};

&i2c0 {
	pinctrl-0 = <&i2c0_default>;
	pinctrl-names = "default";
};
```

</br>

`pinctrl_soc.h`:

```c
#define Z_PINCTRL_STATE_PINS_INIT(node_id, prop)                                                   \
	{                                                                                          \
		DT_FOREACH_CHILD_VARGS(DT_PHANDLE(node_id, prop), DT_FOREACH_PROP_ELEM, pinmux,    \
				       Z_PINCTRL_STATE_PIN_INIT)                                   \
	}
```

上层调用传入的`node_id`对应使用pinctrl的设备节点，`prop`对应`pinctrl-0,1...`

`DT_FOREACH_CHILD_VARGS`会遍历`pinctrl-X`引用的phandle下的`group1~n`，这里这个名称可以是任意值，因为会遍历所有子节点，对`pinmux`属性调用`Z_PINCTRL_STATE_PIN_INIT`函数，每个pin创建一个`pinctrl_soc_pin_t`结构体。

</br>

```c
typedef uint32_t pinctrl_soc_pin_t;

#define Z_PINCTRL_STATE_PIN_INIT(node_id, prop, idx)                                               \
	(DT_PROP_BY_IDX(node_id, prop, idx) |                                                      \
	 (TI_CC32XX_OPEN_DRAIN * DT_PROP(node_id, drive_open_drain)) |                             \
	 (TI_CC32XX_PULL_UP * DT_PROP(node_id, bias_pull_down)) |                                  \
	 (TI_CC32XX_PULL_DOWN * DT_PROP(node_id, bias_pull_up)) |                                  \
	 ((DT_ENUM_IDX(node_id, drive_strength) & TI_CC32XX_DRIVE_STRENGTH_MSK)                    \
	  << TI_CC32XX_DRIVE_STRENGTH_POS) |                                                       \
	 TI_CC32XX_PAD_OUT_OVERRIDE | TI_CC32XX_PAD_OUT_BUF_OVERRIDE),
```

`DT_PROP_BY_IDX(node_id, prop, idx)`: 从设备树pinmux prop中获取值，比如`<UART0_TX_P55>`, `<UART0_RX_P57>`，这些宏定义在`ti-cc32xx-pinctrl.h`中，前面`UART0_TX`表示mux function，后面`P55`表示第55个pin。mux function保存在bit0~3, pin offset保存在bit16~21。

`(TI_CC32XX_OPEN_DRAIN * DT_PROP(node_id, drive_open_drain))` 判断设备中某个group中是否有属性`drive_open_drain`, 保存在`TI_CC32XX_OPEN_DRAIN`, bit4中。

其他几个属性同理，一样保存进`pinctrl_soc_pin_t`的bitmap中。

排列顺序如下图，这里的位置应该对应的ti pinctrol寄存器。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240131145556.png)

</br>

```c
static int pinctrl_configure_pin(pinctrl_soc_pin_t pincfg)
{
	uint8_t pin;

	pin = (pincfg >> TI_CC32XX_PIN_POS) & TI_CC32XX_PIN_MSK;
	if ((pin >= ARRAY_SIZE(pin2pad)) || (pin2pad[pin] == 255U)) {
		return -EINVAL;
	}

	sys_write32(pincfg & MEM_GPIO_PAD_CONFIG_MSK, DT_INST_REG_ADDR(0) + (pin2pad[pin] << 2U));

	return 0;
}
```

接着在`pinctrl_ti_cs32xx.c`中，`pinctrl_configure_pin`函数，根据pin offset将其他配置写进对应的寄存器中。

对应的fingerprint项目的pad register，可以实现的`pinctrl_soc_pin_t`可以参考：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240131150328.png)
