---
title: Zephyr -- Build and Configuration Systems
date: 2023-12-05 14:06:28
tags:
- Zephyr
categories:
- Zephyr OS
---

### Build System(CMake)

### Devicetree

`build/zephyr/zephyr.dts`: final devicetree

### Configuration System(Kconfig)

生成的配置文件:
`zephyr/build/.config`: for CMake use.
`zephyr/build/zephyr/include/generated/autoconf.h`: for c file use.

默认的Kconfig配置：
`prj.conf`文件。

`west build -t menuconfig`: 打开menuconfig。
