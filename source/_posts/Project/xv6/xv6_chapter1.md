---
title: xv6_chapter1 Operating system interfaces
date: 2023-12-30 15:12:28
tags:
- xv6 OS
categories:
- Project
---

XV6 实现的所有系统调用：

```c
int fork() //Create a process, return child’s PID.
void exit(int status) //Terminate the current process; status reported to wait(). No return.
int wait(int *status) //Wait for a child to exit; exit status in *status; returns child PID.
int kill(int pid) //Terminate process PID. Returns 0, or -1 for error.
int getpid() //Return the current process’s PID.
int sleep(int n) //Pause for n clock ticks.
int exec(char *file, char *argv[]) //Load a file and execute it with arguments; only returns if error.
char *sbrk(int n) //Grow process’s memory by n bytes. Returns start of new memory.
int open(char *file, int flags) //Open a file; flags indicate read/write; returns an fd (file descriptor).
int write(int fd, char *buf, int n) //Write n bytes from buf to file descriptor fd; returns n.
int read(int fd, char *buf, int n) //Read n bytes into buf; returns number read; or 0 if end of file.
int close(int fd) //Release open file fd.
int dup(int fd) //Return a new file descriptor referring to the same file as fd.
int pipe(int p[]) //Create a pipe, put read/write file descriptors in p[0] and p[1].
int chdir(char *dir) //Change the current directory.
int mkdir(char *dir) //Create a new directory.
int mknod(char *file, int, int) //Create a device file.
int fstat(int fd, struct stat *st) //Place info about an open file into *st.
int stat(char *file, struct stat *st) //Place info about a named file into *st.
int link(char *file1, char *file2) //Create another name (file2) for the file file1.
int unlink(char *file) //Remove a file.
```

`pid_t fork(void)`
创建一个新进程，拥有相同的memory内容(包括instruction和data)。Parent进程返回child进程的PID, Child进程返回0。

`void exit(int status)`
停止当前进程，通常成功返回0，失败返回1。

`pid_t wait(int *status)`
Block等待子进程退出。返回退出的子进程PID, 并把子进程exit()的status写入int *status。
没有没有子进程立即返回-1。如果不关心退出的状态可以传入0的地址`wait((int *)0)`。

`int exec(char *file, char *argv[])`
file为传入的ELF可执行文件, argv为传入的参数，通常argv[0]为可执行文件名，argv[last]为0，表示字符串结束。

`read()`
`write()`

`dup()`
`pipe()`

## 1.2 I/O and File descriptors

file descriptor:

- 0: 标准输入
- 1: 标准输出
- 2: 标准错误

`read(fd, buf, n)`, `write(fd, buf, n)` 会维护一个偏移地址，下次R/W会从偏移地址开始。

read函数返回读取的bytes数，如果没有bytes可读了就返回0。
write函数返回写入的bytes数，如果写入的bytes小于n，只会是错误发生了。

A newly allocated file descriptor is always the lowestnumbered unused descriptor of the current process。
最新打开的文件描述符一定是最小的未被使用的文件描述符。

这段代码会把输入给cat的内容传入input.txt，此时input.txt的文件描述符对应标准输入0。

```c
char *argv[2];
argv[0] = "cat";
argv[1] = 0;

if(fork() == 0) {
	close(0);
	open("input.txt", O_RDONLY);
	exec("cat", argv);
}
```

`fork`后，read/write函数仍然共享文件偏移地址。

```c
if(fork() == 0) {
	write(1, "hello ", 6);
	exit(0);
} else {
	wait(0);
	write(1, "world\n", 6);
}
```

`int dup(int fd)`函数会返回一个该文件新的描述符，通过两个文件描述符都能访问，也共享文件offset。

## 1.3 Pipes

`int pipe(int filedes[2])`

返回两个文件描述符保存在filedes数组中，filedes[0]为管道的读取端，filedes[1]为管道的写入端。

如果数据没有准备好，那么对管道执行的read会一直等待，直到有数据了或者其他绑定在这个管道写端口的描述符都已经关闭了。在后一种情况中，read 会返回 0。
这就是为什么我们在执行 wc 之前要关闭子进程的写端口。如果 wc 指向了一个管道的写端口，那么 wc 就永远看不到 eof 了。

```c
int p[2];
char *argv[2];
argv[0] = "wc";
argv[1] = 0;
pipe(p);

if(fork() == 0) {
	close(0);
	dup(p[0]); // 副本文件描述符p[0]（管道的读端）到文件描述符0的位置（因为0已经被关闭了，dup默认会使用最低的未用文件描述符，即0）。
	close(p[0]); // 关闭读写管道，这两个管道不再需要了，下面wc会使用dup出来的fd0。
	close(p[1]);
	exec("/bin/wc", argv);
} else {
	close(p[0]);
	write(p[1], "hello world\n", 12);
	close(p[1]);
}
```

## 1.4 File system

`chdir`函数可以改变当前目录。

将当前目录切换到 `/a/b`:

```c
chdir("/a");
chdir("b");
```

`fstat(int fildes, struct stat *buf)`函数可以获取一个文件描述符指向的inode信息。

```c
#define T_DIR 1 // Directory
#define T_FILE 2 // File
#define T_DEVICE 3 // Device

struct stat {
	int dev; // File system’s disk device
	uint ino; // Inode number
	short type; // Type of file
	short nlink; // Number of links to file
	uint64 size; // Size of file in bytes
};
```

一个文件可以有多个名字，但inode只有一个。可以调用`link`函数创建多个文件名指向同一个文件inode。

```c
open("a", O_CREATE|O_WRONLY);
link("a", "b");

unlink("a"); // nlink -= 1, 等于0时
```
