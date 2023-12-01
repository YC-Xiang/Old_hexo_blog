---
title: Zephyr -- Develop with Zephyr
date: 2023-11-30 14:17:28
tags:
- Zephyr
categories:
- Notes
---

## Developing with Zephyr

### Getting Started Guide

设置Python虚拟环境

`python3 -m venv ~/zephyrproject/.venv`

`source ~/zephyrproject/.venv/bin/activate`

`deactive` 退出虚拟环境。

<p class="note note-info">Remember to activate the virtual environment every time you start working.</p>

### Environment Variables

创建zephyr专属的环境变量，`touch ~/.zephyrrc`, `export MY_VARIABLE=foo`。
进入zephyr repository，执行`source zephyr-env.sh`

### Application Development

#### Important Build System Variables

变量`BOARD` `CONF_FILE` `DTC_OVERLAY_FILE`，有三种传入方法：

- `west build` 或 `cmake` 传入 `-D`，有多个overlay文件可以用分号隔开`file1.overlay;file2_overlay`。
- 环境变量`.zephyrrc` `.bashrc`
- `set (<VARIABLE> <VALUE>)` in `CMakeLists.txt`

`ZEPHYR_BASE`: `find_package(Zephyr)` 会自动设置为一个Cmake variable。或者通过环境变量设置。
`BOARD`: 选择开发板。
`CONF_FILE`: Kconfig配置文件。
`EXTRA_CONF_FILE`: 覆盖的Kconfig配置文件。
`SHIELD`:
`ZEPHYR_MODULES`:
`EXTRA_ZEPHYR_MODULES`:

#### Building an Application

`west build -b <board> samples/hello_world`: 编译。
`west build -b <board>@<revision>`: 指定版本。
`west build -t clean`：build clean, `.config`不会删除。
`west build -t pristine`: build目录下全部清空。
`west flash`: 将可执行文件烧进主板。每次执行west flash，app都会rebuild and flash again。
`west build -t run`: 当选择的board是qemu_x86/qemu_cortex_m3，可以直接在qemu中run。每次执行west run，app都会rebuild and run again。

<p class="note note-info">Linux下run target will use the SDK’s QEMU binary by default.通过修改`QEMU_BIN_PATH`可以替换为自己下载的QEMU版本</p>

### Optimization

检查ram，rom使用空间：
```shell
west build -b reel_board samples/hello_world
west build -t ram_report
west build -t rom_report
```
