---
title: Zephyr -- Develop with Zephyr
date: 2023-11-30 14:17:28
tags:
- Zephyr
categories:
- Zephyr OS
---

## Getting Started Guide

设置Python虚拟环境

`python3 -m venv ~/zephyrproject/.venv`

`source ~/zephyrproject/.venv/bin/activate`

`deactive` 退出虚拟环境。

<p class="note note-info">Remember to activate the virtual environment every time you start working.</p>

```shell
cd ~/zephyrproject/zephyr
west build -p always -b <your_board_name> sample/basic/blinky
```

`-p always`表示a pristine build，也可以使用`-p auto`来自动判断是否需要pristine build.

## Environment Variables

创建zephyr专属的环境变量，`touch ~/.zephyrrc`, `export MY_VARIABLE=foo`。
进入zephyr repository，执行`source zephyr-env.sh`

`source zephyr-env.sh`:

- set `ZEPHYR_BASE` 为zephyr repository(内核目录).
- 增加一些环境变量到系统`PATH`.
- load `.zephyrrc` 中的配置.

## Application Development

app目录的结构通常为：

```c
<app>
├── CMakeLists.txt
├── app.overlay
├── prj.conf
├── VERSION
└── src
    └── main.c
```

`CMakeLists.txt`: 编译APP的入口。
`app.overlay`: 设备树overlay。
`prj.conf`: Kconfig overlay。
`VERSION`: Version信息。
`src`: 源码目录。

### Application types

根据app位置，分为三种类型：
**Zephyr repository application**

```c
zephyrproject/
├─── .west/
│    └─── config
└─── zephyr/
     ├── arch/
     ├── boards/
     ├── cmake/
     ├── samples/
     │    ├── hello_world/
     │    └── ...
     ├── tests/
     └── ...
```

**Zephyr workspace application**

```c
zephyrproject/
├─── .west/
│    └─── config
├─── zephyr/
├─── bootloader/
├─── modules/
├─── tools/
├─── <vendor/private-repositories>/
└─── applications/
     └── app/
```

**Zephyr freestanding application**

```c
<home>/
├─── zephyrproject/
│     ├─── .west/
│     │    └─── config
│     ├── zephyr/
│     ├── bootloader/
│     ├── modules/
│     └── ...
│
└─── app/
     ├── CMakeLists.txt
     ├── prj.conf
     └── src/
         └── main.c
```

参考：[example-application](https://github.com/zephyrproject-rtos/example-application)

### Important Build System Variables

变量`BOARD` `CONF_FILE` `DTC_OVERLAY_FILE`，有三种传入方法：

- `west build` 或 `cmake` 传入 `-D`，有多个overlay文件可以用分号隔开`file1.overlay;file2_overlay`。
- 环境变量`.zephyrrc` `.bashrc`
- `set (<VARIABLE> <VALUE>)` in `CMakeLists.txt`

`ZEPHYR_BASE`: `find_package(Zephyr)` 会自动设置为一个Cmake variable。或者通过环境变量设置。
`BOARD`: 选择开发板。
`CONF_FILE`: Kconfig配置文件。没配置的话默认使用`prj.conf`。
`EXTRA_CONF_FILE`: 覆盖的Kconfig配置文件。
`DTC_OVERLAY_FILE`:dts设备树文件，没配置的话默认使用`app.overlay`。
`EXTRA_DTC_OVERLAY_FILE`
`SHIELD`:
`ZEPHYR_MODULES`:
`EXTRA_ZEPHYR_MODULES`:

### Building an Application

`west build -b <board> samples/hello_world`: 编译。
`west build -b <board>@<revision>`: 指定版本。
`west build -t clean`：build clean, `.config`不会删除。
`west build -t pristine`: build目录下全部清空。
`west flash`: 将可执行文件烧进主板。每次执行west flash，app都会rebuild and flash again。
`west build -t run`: 当选择的board是qemu_x86/qemu_cortex_m3，可以直接在qemu中run。每次执行west run，app都会rebuild and run again。

<p class="note note-info">Linux下run target will use the SDK’s QEMU binary by default.通过修改`QEMU_BIN_PATH`可以替换为自己下载的QEMU版本</p>

### Custom Board, Devicetree and SOC Definitions

可以将`board/`, `soc/` 放在application目录下。

west build的时候需要``

## Optimization

检查ram，rom使用空间：

```shell
west build -b reel_board samples/hello_world
west build -t ram_report
west build -t rom_report
```
