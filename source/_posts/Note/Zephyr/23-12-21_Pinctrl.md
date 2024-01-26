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

支持的属性可以查阅`/dts/bindings/pinctrl/pincfg-node.yaml`，支持配置上下拉，驱动能力等等。
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
`pinctrl_soc_pin_t` 对应一个pin。
![Pinctrl 结构体](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/pinctrl.png)

## Provider

Pinctrl Driver实现:
主要需要实现回调函数`pinctrl_configure_pins()`

添加`pinctrl_soc.h`, 一般路径为`soc/<arch>/<vendor>/<board>/...`
在其中定义`pinctrl_soc_pin_t` 结构体，`Z_PINCTRL_STATE_PINS_INIT`宏，该宏接收两个参数，设备树node identifier和property name(pinctrl-N)。
