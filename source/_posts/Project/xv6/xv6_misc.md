---
title: xv6 Misc
date: 2024-2-1 22:12:28
tags:
- xv6 OS
categories:
- Project
---

# xv6运行

`make qemu`
`make clean`

`Ctrl-p` 打印进程。
`Ctrl-a x` 退出qemu。

`make grade` 检查所有lab得分。
`./grade-lab-util sleep` or `make GRADEFLAGS=sleep grade` 检查某一项作业得分。

## GDB 调试

`sudo aptitude install gdb-multiarch`: 解决ubuntu22.04 gdb版本不匹配的问题。

一个shell运行`make qemu-gdb`， 另一个shell运行`gdb-multiarch`，会自动加载`.gdbinit`。如果出现如下错误：

```shell
warning: File "/home/xyc/MIT-6.S081-Operation-System/.gdbinit" auto-loading has been declined by your `auto-load safe-path' set to "$debugdir:$datadir/auto-load".
To enable execution of this file add
        add-auto-load-safe-path /home/xyc/MIT-6.S081-Operation-System/.gdbinit
line to your configuration file "/home/xyc/.config/gdb/gdbinit".
```

按照提示操作，将`add-auto-load-safe-path /home/xyc/MIT-6.S081-Operation-System/.gdbinit`加到`/home/xyc/.config/gdb/gdbinit`即可。
