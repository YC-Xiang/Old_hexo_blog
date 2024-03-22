---
title: Operating Systems Three Easy Pieces(OSTEP)
date: 2024-03-21 14:22:28
tags:
- OS
categories:
- Book
---

# Chapter 4 Process

## 4.2 Process API

一般OS会提供以下的进程API来操作进程：

- **Create**: 创建进程。
- **Destory**: 结束进程。
- **Wait**: Wait a process to stop running. 等待进程结束。
- **Miscellaneous Control**: Suspend/Resume... 休眠，唤醒等等。
- **Status**: 查看进程状态。

## 4.3 Process Creation

1. 首先OS将存储在disk or SSD的program程序加载进memory内存。
这边有两种方式，一种是在运行前把code和static data全部加载进内存。现代操作系统一般会使用第二种方式，**懒加载**，只加载即将使用的code和data。
2. 分配栈。
3. 分配堆。
4. 分配三个文件描述符，标准输入0，标准输出1，错误2。

## 4.4 Process Status

进程的状态有：

- **Running**: 正在使用CPU执行指令。
- **Ready**: 进程就绪态。
- **Blocked**: 比如进程在和disk IO交互，这时会把CPU让出给其他进程使用，进入阻塞态。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240321160042.png)

## 4.5 Data Struct

PCB, Process Control Block 用来描述进程的数据结构。

参考xv6中描述进程的数据结构：

```c
struct proc {
	char *mem; // Start of process memory
	uint sz; // Size of process memory
	char *kstack; // Bottom of kernel stack
	// for this process
	enum proc_state state; // Process state
	int pid; // Process ID
	struct proc *parent; // Parent process
	void *chan; // If !zero, sleeping on chan
	int killed; // If !zero, has been killed
	struct file *ofile[NOFILE]; // Open files
	struct inode *cwd; // Current directory
	struct context context; // Switch here to run process
	struct trapframe *tf; // Trap frame for the current interrupt
};
```

# Chapter 5 Process API

## 5.1 fork() system call

`pid_t fork(void)`

fork系统调用用来创建进程。子进程返回0，父进程返回子进程PID。

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
	printf("hello (pid:%d)\n", (int) getpid());
	int rc = fork();
	if (rc < 0) {
		// fork failed
		fprintf(stderr, "fork failed\n");
		exit(1);
	} else if (rc == 0) {
		// child (new process)
		printf("child (pid:%d)\n", (int) getpid());
	} else {
		// parent goes down this path (main)
		printf("parent of %d (pid:%d)\n", rc, (int) getpid());
}
return 0;
}
```

```shell
prompt> ./p1
hello (pid:29146)
parent of 29147 (pid:29146) # 这条和下面一条出现顺序随机
child (pid:29147)
prompt>
```

## 5.2 wait() system call

`pid_t wait(int *wstatus)`

wait系统调用会block等待子进程结束。`wstatus`可以传入NULL，也可以传入一个指针，通过进一步其他的API来获取子进程状态。

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
int main(int argc, char *argv[]) {
	printf("hello (pid:%d)\n", (int) getpid());
	int rc = fork();
	if (rc < 0) { // fork failed; exit
		fprintf(stderr, "fork failed\n");
		exit(1);
	} else if (rc == 0) { // child (new process)
		printf("child (pid:%d)\n", (int) getpid());
	} else { // parent goes down this path
		int rc_wait = wait(NULL);
		printf("parent of %d (rc_wait:%d) (pid:%d)\n", rc, rc_wait, (int) getpid());
	}
return 0;
}
```

```sh
prompt> ./p2
hello (pid:29266)
child (pid:29267) # 这条和吓一条顺序是确定的
parent of 29267 (rc_wait:29267) (pid:29266)
prompt>
```

## 5.3 exec() system call

`exec()`系列系统调用，直接在当前进程加载另一个program, 运行另一个进程，不返回。

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
	printf("hello (pid:%d)\n", (int) getpid());
	int rc = fork();
	if (rc < 0) { // fork failed; exit
		fprintf(stderr, "fork failed\n");
		exit(1);
	} else if (rc == 0) { // child (new process)
		printf("child (pid:%d)\n", (int) getpid());
		char *myargs[3];
		myargs[0] = strdup("wc"); // program: "wc"
		myargs[1] = strdup("p3.c"); // arg: input file
		myargs[2] = NULL; // mark end of array
		execvp(myargs[0], myargs); // runs word count
		printf("this shouldn’t print out");
	} else { // parent goes down this path
		int rc_wait = wait(NULL);
		printf("parent of %d (rc_wait:%d) (pid:%d)\n", rc, rc_wait, (int) getpid());
	}
	return 0;
}

```

```sh
prompt> ./p3
hello (pid:29383)
child (pid:29384)
29 107 1030 p3.c
parent of 29384 (rc_wait:29384) (pid:29383)
prompt>
```

## Others

`kill()`, `signal()`, `pipe()`

# Chapter 6 Limited Direct Execution

## 6.1 Problem#1 Restricted Operations

User space要与kernel space隔离，通过system call的方式来访问硬件。

OS启动，以及user程序system call与kernel交互流程：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240321175447.png)

## 6.2 Problem#2 Switching Between Processes

- Cooperative Approach：协作式，等process自己主动交出CPU控制权。
- Non-cooperative Approach: 抢占式，OS通过timer interrupt，给每个process一定的时间片执行，到了timer的时间就要交出CPU控制权。

**Context Switch**

进程A和进程B进行切换的上下文交换过程：

> 注意每个进程都有自己的kernel stack。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322113305.png)

## Summary

1. CPU跑OS需要支持**user mode**和**kernel mode**。
2. user mode使用**system call** trap into kernel。
3. kernel启动过程中准备好了**trap table**。
4. OS完成system call后，通过**return-from-trap**指令返回user code。
5. kernel利用**timer interrupt**来防止一个用户进程一直占用CPU。
6. 进程间交换需要**context switch**。

# Chapter 7 Scheduling

几个衡量性能的指标：

转换时间=完成时间-到达时间
$T_{turnaround}=T_{completion}-T_{arrival}$

响应时间=开始执行时间-到达时间
$T_{response}=T_{firstrun}-T_{arrival}$


## 7.3 FIFO

先进先出原则，如果进程一起到来，按先后顺序执行。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322170741.png)

存在的问题是，如果前面的进程运行时间长，平均的turnaround时间就会变得很长：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322170605.png)

## 7.4 Shortest Job first(SJF)

先执行时间短的进程。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322170759.png)

存在的问题是，如果几个进程不是同时到来，先执行到时间长的进程，仍然有和FIFO调度一样的问题：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322170536.png)

## 7.5 Shortest Time-to-Completion First(STCF)

在SJF调度上加入抢占式机制。当有新进程到来时，调度器会判断谁的执行时间更短，来执行时间更短的进程。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322170714.png)

## 7.7 Round Robin

Response time比前面的调度算法都好。

每个进程执行一段时间后切换。要考虑context switch的消耗，选择合适的时间片。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322171956.png)

## 7.8 Incorporating I/O

执行IO的时候，调度别的进程。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20240322174407.png)
