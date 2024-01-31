---
title: Zephyr -- Device Drvier Model
date: 2023-11-30 14:17:28
tags:
- Zephyr
categories:
- Zephyr OS
---

```c
struct device {
      const char *name;
      const void *config;
      const void *api;
      void * const data;
};
```

`config`: 放地址映射，中断号等一些物理信息。
`api`: 回调函数。
`data`: 放reference counts, semaphores, scratch buffers等。

## Device-Specific API Extensions

标准driver api没法实现的功能。

## Single Driver, Multiple Instances

某个driver对应多个instances的情况，比如uart driver匹配uart0, uart1, 并且中断线不是同一个。
