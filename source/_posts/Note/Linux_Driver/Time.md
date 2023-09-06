---
title: Time Subsystem
date: 2023-05-08 17:00:00
tags:
- Linux driver
categories:
- Notes
---

CONFIG_GENERIC_CLOCKEVENTS：新的时间子系统



以下选项三选一：

CONFIG_HZ_PERIODIC：无论何时，都启用用周期性的tick，即便是在系统idle的时候。

CONFIG_NO_HZ_IDLE：在系统idle的时候，停掉周期性tick。会同时enable NO_HZ_COMMON。

CONFIG_NO_HZ_FULL：即便在非idle的状态下，也就是说cpu上还运行在task，也可能会停掉tick。会同时enable NO_HZ_COMMON。



CONFIG_HIGH_RES_TIMERS：高精度timer。

如果配置了高精度timer，或者配置了NO_HZ_COMMON的选项，那么一定需要配置CONFIG_TICK_ONESHOT，表示系统支持支持one-shot类型的tick device。

# sysfs接口

cd /sys/bus/clocksource/devices/clocksource0

cat current_clocksource: 查看当前的clocksource

cat available_clocksource: 查看可用的clocksource

echo xxx > current_clocksource: 设置clocksource



cd /sys/bus/clockevents/devices/clockevent0

cat current_device: 查看当前的clockevent

# Clocksource

# Clockevent
