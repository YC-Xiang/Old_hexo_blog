---
title: Uart subsystem
date: 2023-05-15 22:25:00
tags:
- Linux driver
categories:
- Notes
---

波特率115200，bps每秒传输的bit数。

每一位1/115200秒，传输1byte需要10位（start, data, stop）,那么每秒能传11520byte。

115200，8n1。8:data，n:校验位不用，1：停止位。

# TTY体系中设备节点的差别

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

# Linux串口应用编程

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

# 8250 Uart driver

## 几个重要的结构体

**uart_driver**：通过`int uart_register_driver(struct uart_driver *drv)`注册进内核。

```c
static struct uart_driver serial8250_reg = {
	.owner			= THIS_MODULE, ///拥有该uart_driver的模块,一般为THIS_MODULE
	.driver_name	= "serial", ///串口驱动名，串口设备文件名以驱动名为基础
	.dev_name		= "ttyS", /// 串口设备名
	.major			= TTY_MAJOR,
	.minor			= 64,
	.cons			= SERIAL8250_CONSOLE, /// 其对应的console.若该uart_driver支持serial console,否则为NULL
};

serial8250_reg.nr = UART_NR; /// 支持最大的串口数量 UART_NR == 3
```

**uart_port**：对应一个串口设备，通过`int uart_add_one_port(struct uart_driver *drv,struct uart_port *port)`向该驱动添加`uart_port`

**uart_ops**：串口操作函数，为uart_port的成员。

**uart_8250_port**：8250 serial driver抽象出来的结构体，包含了**uart_port**以及别的8250需要的成员。

**dw8250_data**：dw 820 serial driver抽象出来的结构体

注意到`uart_port`和`uart_ops`中有相同的回调函数，这里的调用顺序为：首先`uart_ops`会检查`uart_port`是否实现了相同的回调函数，如果实现了则调用`uart_port`，否则调用`uart_ops`。具体可以参考`8250_dw.c`中的`p->set_termios = dw8250_set_termios`和`8250_port.c`中的`.set_termios  = serial8250_set_termios`



## 8250_core.c

- 注册uart_driver

- 注册uart_port（后面更底层的8250_dw.c会注册uart_port替换）

```c
//8250_core.c
struct uart_8250_port *up = &serial8250_ports[i];
struct uart_port *port = &up->port;

port->line = i;
port->ops = &serial8250_pops;
port->has_sysrq = IS_ENABLED(CONFIG_SERIAL_8250_CONSOLE);
up->cur_iotype = 0xFF;
port->ops = &univ8250_port_ops;

up->dl_read = default_serial_dl_read;
up->dl_write = default_serial_dl_write;
port->serial_in = io_serial_in;
port->serial_out = io_serial_out;
up->cur_iotype = p->iotype; /// p->iotype=0
univ8250_port_ops = *base_ops; /// 相当于又赋值回来port->ops = &serial8250_pops;


serial8250_init(); /// 内核打印: Serial: 8250/16550 driver, 3 ports, IRQ sharing disabled
	serial8250_isa_init_ports();
    	serial8250_init_port(); // 8250_port.c
		serial8250_set_defaults();
    		set_io_from_upio();
    uart_register_driver();
    	tty_register_driver();
    serial8250_register_ports(); /// 注册三个uart_port(serial8250_ports)进uart_driver.
		uart_add_one_port(drv, &up->port);
			uart_configure_port(); // 会直接返回 因为port->iobase没初始化	
	serial8250_probe();


console_initcall(univ8250_console_init);
	serial8250_isa_init_ports
    register_console

   
```

##  8250_dw.c

在8250_core之后注册。

```c
// 8250_dw.c
struct uart_8250_port uart = {}, *up = &uart;
struct uart_port *p = &up->port;

p->type		= PORT_8250;
p->flags	= UPF_SHARE_IRQ | UPF_FIXED_PORT;
p->dev		= dev;	
p->iotype	= UPIO_MEM;
p->serial_in	= dw8250_serial_in;
p->serial_out	= dw8250_serial_out;
p->set_ldisc	= dw8250_set_ldisc;
p->set_termios	= dw8250_set_termios; /// 在dw8250_quirks中又p->set_termios=NULL
p->membase = devm_ioremap(dev, regs->start, resource_size(regs));
p->private_data = &data->data;
p->iotype = UPIO_MEM32;
p->serial_in = dw8250_serial_in32;
p->serial_out = dw8250_serial_out32;
p->line = id;
p->set_termios = NULL;
port->type = PORT_16550A;

dw8250_probe();
	dw8250_quirks();
    serial8250_register_8250_port();
		serial8250_find_match_or_unused();
        uart_remove_one_port();
            unregister_console(); // 内核打印:printk: console [ttyS1] disabled
		serial8250_set_defaults();
        uart_add_one_port(); 
			uart_configure_port();
				port->ops->config_port(port, flags); // 调用到8250_port.c中uart_ops的config_port
				uart_report_port();// 打印: ...ttyS1 at MMIO 0x18810100 (irq = 13, base_baud = 1500000) is a 16550A
				register_console();// 内核打印:printk: console [ttyS1] enabled 
					try_enable_new_console();
						newcon->setup(); // 这里调用到8250_core.c中univ8250_console.setup创建console
					unregister_console();//内核打印:bootconsole [earlycon0] disabled
				
                            
```



# Printk

以linux5.10为例。（注意到最新的linux6.3 printk流程不一样了）

```c
//kernel/printk/printk.c
printk;
	vprintk_func // printk_safe.c
		vprintk_default
			vprintk_emit
				vprintk_store // 把要打印的信息保存在log_buf中
        			log_output
        		console_unlock
        			call_console_drivers
        				con->write(con, text, len); // 调用console driver的write函数

// 8250 consle
static struct console univ8250_console = {
	.name		= "ttyS",
	.write		= univ8250_console_write,
	.device		= uart_console_device,
	.setup		= univ8250_console_setup,
	.match		= univ8250_console_match,
	.flags		= CON_PRINTBUFFER | CON_ANYTIME,
	.index		= -1,
	.data		= &serial8250_reg,
};

univ8250_console_write();
	serial8250_console_write();
		uart_console_write();
			putchar();//即serial8250_console_putchar();
				serial_port_out();
					up->serial_out(up, offset, value); // 最后调用到8250_dw.c中最底层的.serial_out函数
```



# Early printk

打开CONFIG_EARLY_PRINTK

如果在设备树cmdline中添加了`earlyprintk`，会进入`/arch/arm/kernel/early_printk.c` 中`early_param(" earlyprintk", setup_early_printk);`指定的setup_early_printk函数。可以看到这个earlyprintk是在arch arm上实现的，比如其他risc-v是没有的(通过earlycon实现)。

```c
setup_early_printk();
	register_console(&early_console_dev); // 注册了一个console，printk会调用console的.write回调函数

early_console_write();
	early_write();
		printascii(); // arch/arm/kernel/debug.S
			addruart_current
                addruart
                	ldr	\rp, =CONFIG_DEBUG_UART_PHYS // 需要在linux menuconfig中手动设定earlyprink的Uart串口地址
                	ldr	\rv, =CONFIG_DEBUG_UART_VIRT
            waituarttxrdy
            senduart
            busyuart
```



```c
register_console
    	pr_info("%sconsole [%s%d] enabled\n",
		(newcon->flags & CON_BOOT) ? "boot" : "" ,
		newcon->name, newcon->index);
```



# Question

两个串口对接，一个串口tx发送16bytes 0x55给另一个串口，为什么另一个串口会回16bytes 0x55回来到rx？