---
title: Zephyr -- Board Porting Guide
date: 2024-02-01 11:09:28
tags:
- Zephyr
categories:
- Zephyr OS
---

## Board/

添加自定义的board：`boards/<arch>/<board>/`

```c
boards/<ARCH>/plank
├── board.cmake
├── CMakeLists.txt
├── doc
│   ├── plank.png
│   └── index.rst
├── Kconfig.board
├── Kconfig.defconfig
├── plank_defconfig
├── plank.dts
└── plank.yaml
```

必须要有的文件：

1. `plank.dts`：设备树。
2. `Kconfig.board`, `Kconfig.defconfig`, `plank_defconfig`: Kconfig文件。

可选文件：

1. `board.cmake`: 用于`west flash`和`west debug`。
2. `CMakeLists.txt`: 如果在`board/`下加其他`*.c`的话需要。
3. `doc/`: 文档。
4. `plank.yaml`: Test Runner(Twister)需要使用。

</br>

`Kconfig.board`: 至少需要`config BOARD_PLANK`选项。

```java
config BOARD_PLANK
   bool "Plank board"
   depends on SOC_SERIES_YOUR_SOC_SERIES_HERE
   select SOC_PART_NUMBER_ABCDEFGH
```

`Kconfig.defconfig`: 板子的一些固定Kconfig选项，需要包括在 `if BOARD_PLANK/endif`中间。通常是invisible Kconfig Symbol，没有prompt。需要依赖default值或者其他Kconfig依赖，无法在配置菜单中选择。

```java
if BOARD_PLANK
# Always set CONFIG_BOARD here. This isn't meant to be customized,
# but is set as a "default" due to Kconfig language restrictions.
config BOARD
   default "plank"

# Other options you want enabled by default go next. Examples:

config FOO
   default y

if NETWORKING
config SOC_ETHERNET_DRIVER
   default y
endif # NETWORKING

endif # BOARD_PLANK
```

`plank_defconfig`: 选择soc，时钟，串口等等CONFIG_开关。

```java
CONFIG_SOC_${VENDOR_XYZ3000}=y                # select your SoC
CONFIG_SYS_CLOCK_HW_CYCLES_PER_SEC=120000000  # set up your clock, etc
CONFIG_SERIAL=y
```
