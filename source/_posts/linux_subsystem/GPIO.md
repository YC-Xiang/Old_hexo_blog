---
title: GPIO subsystem
date: 2023-05-012 10:19:00
tags:
- Linux driver
categories:
- Notes
---

https://zhuanlan.zhihu.com/p/41942876

**push pull推挽输出**

推挽输出的最大特点是可以真正能真正的输出高电平和低电平，在两种电平下都具有驱动能力。

**open drain开漏输出**

**open source开集输出**

这两种输出的原理和特性基本是类似的，区别在于一个是使用MOS管，其中的"漏"指的就是MOS管的漏极；另一个使用三极管，其中的"集"指的就是MOS三极管的集电极。这两者其实都是和推挽输出相对应的输出模式，由于使用MOS管的情况较多，很多时候就用"开漏输出"这个词代替了开漏输出和开集输出。



开漏、开集输出最主要的特性就是高电平没有驱动能力，需要借助外部上拉电阻才能真正输出高电平。

# Kernel doc: General Purpose Input/Output (GPIO)

## GPIO Driver Interface

### Controller Drivers: gpio_chip

`struct gpio_chip` 抽象gpio controller。

`gpiochip_add_data()` or `devm_gpiochip_add_data()`接口用来注册gpio controller。`gpiochip_remove()`释放gpio controller。

`gpiochip_is_request()`在gpio controller driver中用于检测某个gpio是否被其他chip占用，没占用返回NULL，占用返回request时传入的string。



### GPIO electrical configuration

gpio_chip的`.set_config`回调用于设置：

- Debouncing
- Single-ended modes (open drain/open source)
- Pull up and pull down resistor enablement

这些属性可以在dts中指定，`include/dt-bindings/gpio/gpio.h` `GPIO_PUSH_PULL` `GPIO_LINE_OPEN_SOURCE` `GPIO_OPEN_DRAIN `...

可以设置为`gpiochip_generic_config()`会调用到`pinctrl_gpio_set_config()`->`ops->pin_config_set`



### GPIO drivers providing IRQs

```c
gpiod_to_irq(); // 传入gpio_desc，返回gpio的irq number(软件映射的，不是irq hw id)
	gpio_chip_hwgpio();
		gc->to_irq();
			rts_gpio_to_irq();
				irq_linear_revmap();

```

#### Cascaded GPIO irqchips

- CHAINED CASCADED GPIO IRQCHIPS：挺多soc上是这种做法，打开`CONFIG_GPIOLIB_IRQCHIP`设置girq->parent_handler。gpio controller注册过程中通过**irq_set_chained_handler**设置中断处理函数，因此在中断处理函数中需要chained_irq_enter，chained_irq_exit。

  - ```c
    static irqreturn_t foo_gpio_irq(int irq, void *data) /// 中断处理函数
        chained_irq_enter(...);
        generic_handle_irq(...);
        chained_irq_exit(...);
    ```

- GENERIC CHAINED GPIO IRQCHIPS：rts3917是这种做法，通过**reuqest_irq**进入的rts_irq_handler中断处理函数。发现的每一个gpio都进入generic_handle_irq，最后会到各自irq_desc中通过request_irq的中断处理函数。

  - ```c
    static irqreturn_t rts_irq_handler(int irq, void *dev_id)
        for each detected GPIO IRQ
            generic_handle_irq(...);
    ```

- NESTED THREADED GPIO IRQCHIPS：gpio expander的做法，不深究。



### Infrastructure helpers for GPIO irqchips

GPIO子系统有针对中断的一套框架，Kconfig为`GPIOLIB_IRQCHIP`，rts没有用到就不分析了。可以看文档中具体的解释。

注意一点，方法一：如果parent_handler赋值了`girq->parent_handler = ftgpio_gpio_irq_handler`应该就是上面`CHAINED CASCADED GPIO IRQCHIPS`的做法。

```c
gpiochip_add_data();
    gpiochip_add_data_with_key();
    	gpiochip_add_irqchip();
    		irq_set_chained_handler_and_data(gc->irq.parents[i], gc->irq.parent_handler, data);
```

方法二：`girq->parent_handler = NULL`，直接在driver中`devm_request_threaded_irq`对应`GENERIC CHAINED GPIO IRQCHIPS`的做法。



## GPIO Descriptor Consumer Interface

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/gpio.png)



```c
struct gpio_desc *gpiod_get(struct device *dev, const char *con_id, enum gpiod_flags flags);
struct gpio_desc *gpiod_get_index(struct device *dev, const char *con_id, unsigned int idx, enum gpiod_flags flags);
// return NULL 如果没有request到GPIO
struct gpio_desc *gpiod_get_optional(struct device *dev, const char *con_id, enum gpiod_flags flags);
```

## GPIO Mappings

### device tree

```c
foo_device {
        compatible = "acme,foo";
        ...
        led-gpios = <&gpio 15 GPIO_ACTIVE_HIGH>, /* red */
                    <&gpio 16 GPIO_ACTIVE_HIGH>, /* green */
                    <&gpio 17 GPIO_ACTIVE_HIGH>; /* blue */

        power-gpios = <&gpio 1 GPIO_ACTIVE_LOW>;
};
```

对应

```c
struct gpio_desc *red, *green, *blue, *power;

red = gpiod_get_index(dev, "led", 0, GPIOD_OUT_HIGH);
green = gpiod_get_index(dev, "led", 1, GPIOD_OUT_HIGH);
blue = gpiod_get_index(dev, "led", 2, GPIOD_OUT_HIGH);

power = gpiod_get(dev, "power", GPIOD_OUT_HIGH);
```

gpiod_set_value设置的值是“逻辑值”，不一定等于物理值。

## Sysfs接口

/sys/class/gpio/

echo 19 > export

/sys/class/gpio/gpioN/

