---
title: Zephyr -- Device Drvier Model
date: 2023-11-30 14:17:28
tags:
- Zephyr
categories:
- Notes
---

## Device-Specific API Extensions

标准driver api没法实现的功能。

## Single Driver, Multiple Instances

某个driver对应多个instances的情况，比如uart driver匹配uart0, uart1, 并且中断线不是同一个。
