---
title: Interrupt Subsystem
date: 2023-05-08 16:00:00
tags:
- Linux driver
categories:
- Notes
---

# IRQ domain

http://www.wowotech.net/linux_kenrel/irq-domain.html

## 1. 向系统注册irq domain

interrupt controller初始化的过程中，注册irq domain

`irq_domain_add_linear(struct device_node *of_node, unsigned int size, const struct irq_domain_ops *ops, void *host_data)`



## 2. 为irq domain创建映射

在各个硬件外设的驱动初始化过程中，创建HW interrupt ID和IRQ number的映射关系。

**方法1**：`irq_create_mapping(struct irq_domain *host, irq_hw_number_t hwirq);`

比如`drivers/clocksource/timer-riscv.c`中`irq_create_mapping(domain, RV_IRQ_TIMER);`直接将hw id(RV_IRQ_TIMER)传入, 创建hw id和irq number的映射。

```c
irq_create_mapping(domain, hwirq);
	irq_create_mapping_affinity();
		irq_domain_alloc_descs(); // 创建hw id和irq number的映射
		irq_domain_associate();
			domain->ops->map(); //调用到interrupt controller的map函数
```

**方法2**：`irq_of_parse_and_map`. 需要在设备树中指定hw id。

比如`drivers/irqchip/irq-realtek-plic.c`中`irq_of_parse_and_map`

```c
irq_of_parse_and_map(struct device_node *dev, int index);
	of_irq_parse_one(dev, index, &oirq); // 解析设备树
	irq_create_of_mapping(&oirq);
		irq_create_fwspec_mapping();
			irq_create_mapping(domain, hwirq); // 最终还是调用到irq_create_mapping
```

**方法3**：外设driver中直接`platform_get_irq`

```c
platform_get_irq();
	platform_get_irq_optional();
		of_irq_get();
			of_irq_parse_one();
			irq_create_of_mapping(); // 到这里和上面一样了
```



`struct irq_domain_ops`抽象了一个`irq domain`的callback函数。

`(*map)`函数在irq domain创建映射`irq_create_mapping`时会调用到。

`(*xlate)`用来翻译设备树。

如果定义了`CONFIG_IRQ_DOMAIN_HIERARCHY`，`(*map)`函数对应到`*(alloc)`, `(*xlate)`对应到`(*translate)`。

参考`irq_create_of_mapping->irq_create_fwspec_mapping`如下部分：

```c
if (irq_domain_is_hierarchy(domain)) {
    virq = irq_domain_alloc_irqs(domain, 1, NUMA_NO_NODE, fwspec); // 往下追会调用到domain->ops->alloc
    if (virq <= 0)
        return 0;
} else {
    /* Create mapping */
    virq = irq_create_mapping(domain, hwirq); // 往下追会调用到domain->ops->map
    if (!virq)
        return virq;
}
```

在map/alloc函数中需要做的有：

（1）设定该IRQ number对应的中断描述符（struct irq_desc）的irq chip

（2）设定该IRQ number对应的中断描述符的highlevel irq-events handler

（3）设定该IRQ number对应的中断描述符的 irq chip data

有一个API，`irq_domain_set_info`

# 重要的数据结构

http://www.wowotech.net/irq_subsystem/interrupt_descriptor.html

### irq_desc

每个外设驱动调用platform_get_irq就会调用到irq_domain中的.map/.alloc函数，填充irq_desc结构体。

```c
struct irq_desc irq_desc[NR_IRQS] // 全局irq_desc数组，每个外设的中断对应一个irq_desc

// init/main.c
early_irq_init();
	desc_set_defaults(); // 对每个irq_desc都初始化赋值
```

```c
struct irq_desc {
    struct irq_data        irq_data;
    irq_flow_handler_t    handle_irq;
    struct irqaction    *action;
	//...
}
```

handle_irq就是highlevel irq-events handler。irq_set_chip_and_handlerz等接口中会设置。

highlevel irq-events handler可以分成：

（a）处理电平触发类型的中断handler（handle_level_irq）

（b）处理边缘触发类型的中断handler（handle_edge_irq）

（c）处理简单类型的中断handler（handle_simple_irq）

（d）处理EOI类型的中断handler（handle_fasteoi_irq）

### irq_data

irq_desc中包含irq_data，irq_data中保存了irq_chip, irq_domain等数据结构。

```c
struct irq_data {
    unsigned int        irq; // IRQ number
    unsigned long        hwirq; //HW interrupt ID
    struct irq_chip        *chip; //该中断描述符对应的irq chip数据结构
    struct irq_domain    *domain; //该中断描述符对应的irq domain数据结构
    void            *handler_data; //和外设specific handler相关的私有数据
    void            *chip_data; //和中断控制器相关的私有数据 e.g.irq_set_chip_data(gpioirq, rtspc);
};
```

### irq_chip

提供回调函数，在request_irq过程中会被调用。

```c
struct irq_chip {
	const char	*name;
	unsigned int	(*irq_startup)(struct irq_data *data); // start up the interrupt (defaults to ->irq_enable if NULL)
	void		(*irq_shutdown)(struct irq_data *data);
	void		(*irq_enable)(struct irq_data *data); // enable the interrupt (defaults to ->irq_unmask if NULL)
	void		(*irq_disable)(struct irq_data *data);
	void		(*irq_mask)(struct irq_data *data);
	void		(*irq_unmask)(struct irq_data *data);
	int		(*irq_set_type)(struct irq_data *data, unsigned int flow_type); // 指定触发方式，电平触发还是边缘触发
```

一些设置的API:

```c
irq_set_chip
irq_set_irq_type
irq_set_chip_data
__irq_set_handler
irq_set_chip_and_handler
irq_set_chip_and_handler_name
irq_domain_set_info
```



# 第一级IRQ Domain cpu-intc

 `irq-riscv-intc.c`

irq初始化

```c
// init/main.c
init_IRQ();
//arch/riscv/kernel/irq.c
init_IRQ();
	irqchip_init();
// drivers/irqchip/irqchip.c
irqchip_init();
	of_irq_init();
		IRQCHIP_DECLARE(riscv, "riscv,cpu-intc", riscv_intc_init); // 进入riscv_intc_init

riscv_intc_init();
intc_domain = irq_domain_add_linear(node, BITS_PER_LONG, &riscv_intc_domain_ops, NULL /// 注册irq_domain
set_handle_irq(&riscv_intc_irq); /// 设置中断handler
```



```c
// 每个cpu int都会调用到cpu interrupt controller的map函数，会填充irq_desc。
irq_create_mapping();
domain->ops->map;
.map = riscv_intc_domain_map();
	irq_domain_set_info();
		irq_set_chip_and_handler_name(virq, chip, handler, handler_name);
			irq_set_chip();
				desc->irq_data.chip = chip;
			__irq_set_handler();
				desc->handle_irq = handle; // handle是handle_percpu_devid_irq
		irq_set_chip_data(virq, chip_data); // d->host_data irq_domain_add_linear最后一个参数
			desc->irq_data.chip_data = data; // irq chip的私有数据
		irq_set_handler_data(virq, handler_data);
			desc->irq_common_data.handler_data = data; // data=NULL
```

# 第二级 IRQ Domain Plic

`irq-realtek-plic.c`

```c
irq_domain_add_linear(node, nr_irqs + 1, &plic_irqdomain_ops, priv);
irq_of_parse_and_map(node, i);
irq_set_chained_handler(plic_parent_irq, plic_handle_irq); //发生9号外部中断(plic_parent_irq)，会进plic_handle_irq
```

级联的第二级interrupt controller调用`irq_set_chained_handler`设置 interrupt handler

# IRQ Domain GPIO interrupt controller

`pinctrl-rts3917.c` 做法不像plic的级联中断处理。

```c
rtspc->irq_domain = irq_domain_add_linear();
int gpioirq = irq_create_mapping();
irq_set_chip_and_handler();
// 中断来了会先进handle_simple_irq，再进rts_irq_handler
request_irq();
```







外设调用platform_get_irq：

```c
platform_get_irq();
...
irq_create_of_mapping
	irq_create_fwspec_mapping
		irq_domain_alloc_irqs
			__irq_domain_alloc_irqs
				irq_domain_alloc_irqs_hierarchy
					domain->ops->alloc
						irq_domain_translate_onecell
						plic_irqdomain_map
							irq_domain_set_info
								...
  								desc->handle_irq = handle; // handle: handle_fasteoi_irq
```

# risc-v中断处理流程

```c
// head.S
setup_trap_vector:
	la a0, handle_exception
	csrw CSR_TVEC, a0     // handle_exception地址传入CSR_TVEC
	csrw CSR_SCRATCH, zero   // CSR_SCRATCH清零

// entry.S
ENTRY(handle_exception)
	handle_arch_irq();
		set_handle_irq();
			riscv_intc_irq();
				handle_domain_irq();
					__handle_domain_irq();
						generic_handle_irq();
							generic_handle_irq_desc();
								// 不同的中断控制器在一开始初始化会设置
								desc->handle_irq(desc);
	handle_syscall(); //处理系统调用
	excp_vect_table(); //处理异常

// 这里cpu int会进入handle_percpu_devid_irq, 在irq-riscv-intc.c irq_domain_set_info中设定
handle_percpu_devid_irq();
	action->handler(); // timer-riscv.c 中request_irq会把中断处理函数赋值给action->handler();

// external int 会进入plic_handle_irq, 在irq-realtek-plic.c irq_set_chained_handler中设定
plic_handle_irq();
	generic_handle_irq();
		generic_handle_irq_desc();
			desc->handle_irq(desc);
				handle_fasteoi_irq();
					...
                    // request_irq中会把自定义的handler function赋值给action->handler
                  	action->handler();
```



***是否所有的irq_domain的irq number是按顺序排列下去，每个irq_number设置一个interrupt handler，不会重复？***

# Bottom half

softirq，tasklet，workqueue。

workqueue运行在**process context**，而softirq和tasklet运行在**interrupt context**。

在有sleep需求的场景中，defering task必须延迟到kernel thread中执行，也就是说必须使用workqueue机制。

softirq更倾向于性能，而tasklet更倾向于易用性。软中断可以在多个CPU上并行运行，因此需要考虑可重入问题，而tasklet会绑定在某个cpu上运行，不要求重入问题，因此性能会下降一些。