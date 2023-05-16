---
title: Uart subsystem
date: 2023-05-15 22:25:00
tags:
- Linux driver
categories:
- Notes
---

# Uart子系统

波特率115200，bps每秒传输的bit数。

每一位1/115200秒，传输1byte需要10位（start, data, stop）,那么每秒能传11520byte。

115200，8n1。8:data，n:校验位不用，1：停止位。

## TTY体系中设备节点的差别

不关心终端是真实的还是虚拟的，都可以通过/dev/tty找到当前终端。

**/dev/console** 

内核的打印信息可以通过cmdline来选择打印到哪个设备。

console=ttyS0 console=tty

console=ttyS0时，/dev/console就是ttyS0

console=ttyN时，/dev/console就是/dev/ttyN

console=tty时，/dev/console就是前台程序的虚拟终端

console=tty0时，/dev/console就是前台程序的虚拟终端

console有多个取值时，使用最后一个取值来判断。

**/dev/tty 和/dev/tty0区别**

`/dev/tty`表示当前进程的控制终端，也就是当前进程与用户交互的终端。

`/dev/tty0`则是当前所使用虚拟终端的一个别名

## Linux串口应用编程

https://digilander.libero.it/robang/rubrica/serial.htm

```c

struct termios options;

open("/dev/ttyS1", O_RDWR | O_NOCTTY | O_NDELAY)// O_NOCTTY: 不用作控制终端 O_NDELAY: 使I/O变成非阻塞模式


fcntl(fd, F_SETFL, 0): //读数据时，没有数据则阻塞等待
fcntl(fd, F_SETFL, FNDELAY): //读数据时不等待，没有数据就返回0


/* c_cflag: Control Options */
options.c_cflag |= (CLOCAL | CREAD); // 必须打开 Enable the receiver and set local mode

options.c_cflag &= ~CSIZE; /* Mask the character size bits */
options.c_cflag |= CS8;    /* Select 8 data bits */

cfsetispeed(&options, B19200); //设置input output波特率
cfsetospeed(&options, B19200);

options.c_cflag &= ~PARENB // no parity
options.c_cflag &= ~CSTOPB

options.c_cflag &= ~CNEW_RTSCTS; // RTS CTS


/* c_lflag: Local Options */
options.c_lflag |= (ICANON | ECHO | ECHOE); // 选择规范输入 Canonical Input
options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // 选择原始输入 Raw Input

/* c_iflag: Input Options*/
opt.c_iflag &= ~INPCK;

/* c_oflag: Input Options*/
options.c_oflag &= ~OPOST; // raw output. When the OPOST option is disabled, all other option bits in c_oflag are ignored.

tcsetattr(fd, TCSANOW, &options);
```

VMIN: 读数据时的最小字节数，没读到这些数据就不返回

VTIME: 等待第一个数据的时间，比如VTIME=1，表示10秒内一个数据都没有的话就返回，如果10秒内至少读到一个字节，就继续等待，完全读到VMIN个数据返回。 VTIME=0表示一直等待。

**Timeouts are ignored in canonical input mode or when the \*NDELAY\* option is set on the file via \*open\* or \*fcntl\*.**

raw mode可以设置VMIN和VTIME，canonical input mode不用设置。

## Uart driver

```c
// 8250_dw.c
serial8250_register_8250_port();

//8250_core.c
serial8250_register_8250_port();


```



