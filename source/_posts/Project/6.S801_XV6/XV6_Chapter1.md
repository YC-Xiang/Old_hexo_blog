---
title: XV6 Book notes
date: 2023-12-28 09:28:28
tags:
- XV6
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
