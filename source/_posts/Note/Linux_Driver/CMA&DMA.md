---
title: CMA&DMA
date: 2023-05-10 17:40:28
tags:
- Linux driver
categories:
- Linux driver
---

# Reserved-memory

参考：http://www.wowotech.net/memory_management/cma.html

https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841683/Linux+Reserved+Memory?view=blog

/Documentation/devicetree/bindings/reserved-memory/reserved-memory.txt



定义了no-map属性的，不会自动映射到虚拟地址，需要自行在driver中映射。

```c
// dts
reserved: buffer@0x38000000 {
    no-map;
    reg = <0x38000000 0x08000000>;
};

/* Get reserved memory region from Device-tree */
np = of_parse_phandle(dev->of_node, "memory-region", 0);

rc = of_address_to_resource(np, 0, &r);

lp->paddr = r.start;
lp->vaddr = memremap(r.start, resource_size(&r), MEMREMAP_WB);
```



定义"shared-dma-pool" 就可以创建DMA memory pool，使用DMA engine API了。of_reserved_mem_device_init中会帮我们创建映射。（DMA在of_reserved_mem_device_init阶段会进行memremap同上，这个remap不是直接映射的方式）。

```c
// dts
reserved: buffer@0 {
	compatible = "shared-dma-pool";
	no-map;
	reg = <0x0 0x70000000 0x0 0x10000000>;
};

/* Initialize reserved memory resources */
rc = of_reserved_mem_device_init(dev);

/* Allocate memory */
dma_set_coherent_mask(dev, 0xFFFFFFFF);
lp->vaddr = dma_alloc_coherent(dev, ALLOC_SIZE, &lp->paddr, GFP_KERNEL);
```

log:

```shell
[    0.000000] Reserved memory: created DMA memory pool at 0x0000000070000000, size 256 MiB
[    0.000000] Reserved memory: initialized node buffer@0, compatible id shared-dma-pool
```



加上resuable属性，变成CMA pool。（CMA在dma_alloc_coherent时会通过__va宏返回直接映射的虚拟地址）

```c
reserved: buffer@0 {
	compatible = "shared-dma-pool";
	reusable;
	reg = <0x0 0x70000000 0x0 0x10000000>;
};
```

log：

```
[    0.000000] Reserved memory: created CMA memory pool at 0x0000000070000000, size 256 MiB
[    0.000000] Reserved memory: initialized node buffer@0, compatible id shared-dma-pool
```



**DMA pool是driver独有的，CMA pool在driver不使用的时候会被共享。**



# Dynamic DMA mapping Guide

https://docs.kernel.org/core-api/dma-api-howto.html

https://zhuanlan.zhihu.com/p/109919756

## CPU and DMA addresses

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230510112218.png)

有IOMMU的设备，设备device访问的地址是bus address（等同于dma address），IOMMU负责CPU physical address和bus address的映射。

嵌入式设备一般没有IOMMU，此时bus address=CPU pyhsical address。设备直接访问cpu的物理地址。

## What memory is DMA'able?

`__get_free_page*()`, `kmalloc()`, `kmem_cache_alloc()`这些分配连续空间地址的都可以dma mapping。

`vmalloc()`, `kmap()`不行。

## DMA addressing capabilities

设置设备通过DMA能驱动多少位地址，寻址能力。

同时设置streaming和coherent mapping：

`int dma_set_mask_and_coherent(struct device *dev, u64 mask)`

只设置streaming mapping：

`int dma_set_mask(struct device *dev, u64 mask);`

只设置coherent mapping：

`int dma_set_coherent_mask(struct device *dev, u64 mask);`

## Types of DMA mappings

- 一致性DMA映射（consistent DMA mappings）。driver初始化时map，shutdown时unmap。
  - 不需要考虑cache的影响，也就是说不需要软件进行cache操作，CPU和DMA controller都可以看到对方对DMA buffer的更新。CPU对memory的修改device可以立即感知到，反之亦然。
  - 一致性的DMA映射并不意味着不需要memory barrier这样的工具来保证memory order。
  - 在有些平台上，修改了DMA Consistent buffer后，你的驱动可能需要flush write buffer，以便让device侧感知到memory的变化。
- 流式DMA映射（Streaming DMA mappings）。一次性的，需要进行DMA传输的时候map，DMA传输完成，就ummap。`spi-dw-rts.c`中ssi的传输就是流式dma映射。

## 一致性DMA映射

```c
dma_addr_t dma_handle;
//cpu_addr:虚拟地址，dma_handle:总线地址，没有IOMMU相当于物理地址
cpu_addr = dma_alloc_coherent(dev, size, &dma_handle, gfp);
```

You may however need to make sure to flush the processor's write buffers before telling devices to read that memory.见下方sync的API。



如果driver需要许多小的buffer,可以使用

```c
struct dma_pool *pool;
pool = dma_pool_create(name, dev, size, align, boundary);
cpu_addr = dma_pool_alloc(pool, flags, &dma_handle);
```

## 流式DMA映射

流式DMA映射需要设置DMA direction。

```c
DMA_BIDIRECTIONAL
DMA_TO_DEVICE
DMA_FROM_DEVICE
DMA_NONE
```

接口一`dma_map_single`

```c
struct device *dev = &my_dev->dev;
dma_addr_t dma_handle;
void *addr = buffer->ptr;
size_t size = buffer->len;

dma_handle = dma_map_single(dev, addr, size, direction);
if (dma_mapping_error(dev, dma_handle)) {
        /*
         * reduce current DMA mapping usage,
         * delay and try again later or
         * reset driver.
         */
        goto map_error_handling;
}
```

接口二`dma_map_page`

因为dma_map_single函数在进行DMA mapping的时候使用的是CPU指针（虚拟地址），导致该函数有一个弊端：不能使用HIGHMEM memory进行mapping。因为HIGHMEM memory没有进行线性映射，所以没有虚拟地址。

接口三`dma_map_sg`

用于scatterlist情况，映射的对象是分散的若干段DMA buffer。具体不分析了。

## Sync

如果你需要多次访问同一个streaming DMA buffer，并且在DMA传输之间读写DMA Buffer上的数据，这时候你需要小心进行DMA buffer的sync操作，以便CPU和设备（DMA controller）可以看到最新的、正确的数据。

`dma_sync_single_for_cpu(dev, dma_handle, size, direction)`

如果，CPU操作了DMA buffer的数据，然后你又想把控制权交给设备上的DMA控制器，让DMA controller访问DMA buffer，这时候，在真正让HW（指DMA控制器）去访问DMA buffer之前，需要：

`dma_sync_single_for_device(dev, dma_handle, size, direction)`



# Other

<https://blog.csdn.net/wangyunqian6/article/details/6670110>

DMA是直接操作总线地址的，这里先当作物理地址来看待吧。如果cache缓存的内存区域不包括DMA分配到的区域，那么就没有一致性的问题。但是如果cache缓存包括了DMA目的地址的话，会出现什么什么问题呢？

问题出在，经过DMA操作，cache缓存对应的内存数据已经被修改了，而CPU本身不知道（DMA传输是不通过CPU的），它仍然认为cache中的数据就是内存中的数据，以后访问Cache映射的内存时，它仍然使用旧的Cache数据。这样就发生Cache与内存的数据“不一致性”错误。

顺便提一下，总线地址是从设备角度上看到的内存，物理地址是CPU的角度看到的未经过转换的内存（经过转换的是虚拟地址）

由上面可以看出，DMA如果使用cache，那么一定要考虑cache的一致性。解决DMA导致的一致性的方法最简单的就是禁止DMA目标地址范围内的cache功能。但是这样就会牺牲性能。

因此在DMA是否使用cache的问题上，可以根据DMA缓冲区期望保留的的时间长短来决策。DAM的映射就分为：**一致性DMA映射**和**流式DMA映射**。

因为LCD随时都在使用，因此在Frame buffer驱动中，使用一致性DMA映射上面的代码中用到 **dma_alloc_wc**（**non-cache, buffered**）函数，另外还有一个一致性DMA映射函数**dma_alloc_coherent**（**non-cache，non-buffer**）

```c
static inline void *dma_alloc_coherent(struct device *dev, size_t size,
		dma_addr_t *dma_handle, gfp_t gfp)
{
	return dma_alloc_attrs(dev, size, dma_handle, gfp,
			(gfp & __GFP_NOWARN) ? DMA_ATTR_NO_WARN : 0);
}

static inline void *dma_alloc_wc(struct device *dev, size_t size,
				 dma_addr_t *dma_addr, gfp_t gfp)
{
	unsigned long attrs = DMA_ATTR_WRITE_COMBINE;

	if (gfp & __GFP_NOWARN)
		attrs |= DMA_ATTR_NO_WARN;

	return dma_alloc_attrs(dev, size, dma_addr, gfp, attrs);
}
```

```c
dma_alloc_attrs();
	dma_alloc_from_dev_coherent(); // 如果dts有reserved memory会走这个函数
		dev_get_coherent_memory();
			return dev->dma_mem // 直接返回reserved-memory中分配的地址了
	return cpu_addr;

// dev->mem的分配：
dma_init_reserved_memory();
	ops->device_init(dma_reserved_default_memory, NULL);
static const struct reserved_mem_ops rmem_dma_ops = {
	.device_init	= rmem_dma_device_init,
};
rmem_dma_device_init();
	dma_init_coherent_memory();
	dma_assign_coherent_memory();
		dev->dma_mem = mem;

```

看起来如果在dts中分配了reserved-memory，`dma_alloc_coherent`和`dma_alloc_wc`流程是一样的，都会走`dma_alloc_from_dev_coherent`从reserved-memory中分配空间（**这块区域是cached？buffer？**，rts3917启动中有打印：`Memory policy: Data cache writeback`是否与reserved memory有关系）

**所以rts_fb.c中有`dma_sync_single_for_device`?**

| 是否启用cache | 是否启用 buffer | 说明                                       |
| --------- | ----------- | ---------------------------------------- |
| 0         | 0           | 无cache，无写缓冲<br />读、写都直达外设硬件              |
| 0         | 1           | 无cache，有写缓冲<br />读操作直达外设硬件；写操作，CPU将数据写入到写缓冲后继续运行，由写缓冲进行写回操作。 |
| 1         | 0           | 有cache，写通模式write through。<br />数据要同时写入cache和内存，所以cache和内存中的数据保持一致。 |
| 1         | 1           | 有cache，写回模式write back<br />新数据只是写入cache ，不会立刻写入内存。 |
