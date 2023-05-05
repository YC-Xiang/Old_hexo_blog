# IRQ domain

1、向系统注册irq domain

interrupt controller初始化的过程中，注册irq domain

`irq_domain_add_linear`



2、为irq domain创建映射

在各个硬件外设的驱动初始化过程中，创建HW interrupt ID和IRQ number的映射关系。

***Interrupt controller初始化的时候会mapping hw id和irq number吗？***



方法1：

`irq_create_mapping(struct irq_domain *host, irq_hw_number_t hwirq);`

比如`drivers/clocksource/timer-riscv.c`中`irq_create_mapping(domain, RV_IRQ_TIMER);`直接将hw id(RV_IRQ_TIMER)传入, 创建hw id和irq number的映射。

```c
irq_create_mapping(domain, hwirq);
	irq_create_mapping_affinity();
		irq_domain_alloc_descs(); // 创建hw id和irq number的映射
		irq_domain_associate();
			domain->ops->map(); //调用到interrupt controller的map函数
```



方法2：

`irq_of_parse_and_map`

比如`drivers/irqchip/irq-realtek-plic.c`中`irq_of_parse_and_map`

```c
irq_of_parse_and_map(struct device_node *dev, int index);
	of_irq_parse_one(dev, index, &oirq); // 解析设备树
	irq_create_of_mapping(&oirq);
		irq_create_fwspec_mapping();
			irq_create_mapping(domain, hwirq); // 最终还是调用到irq_create_mapping
```



方法3：

外设driver中直接`platform_get_irq`

```c
platform_get_irq();
	platform_get_irq_optional();
		of_irq_get();
			of_irq_parse_one();
			irq_create_of_mapping(); // 到这里和上面一样了
```



级联的第二级interrupt controller调用`irq_set_chained_handler`设置 interrupt handler



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

```





risc-v 中断处理流程

```c

```

# IRQ desc

```c
struct irq_desc irq_desc[NR_IRQS] // 全局irq_desc数组，每个外设的中断对应一个irq_desc

early_irq_init();
	desc_set_defaults(); // 对每个irq_desc都初始化赋值
```

```c
// irq-riscv-intc.c 
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



irq_to_desc的定义 irq_desc + irq 是什么意思？数组加上irq number？

```c
struct irq_desc *irq_to_desc(unsigned int irq)
{
	return (irq < NR_IRQS) ? irq_desc + irq : NULL;
}
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
								desc->handle_irq(desc);
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

