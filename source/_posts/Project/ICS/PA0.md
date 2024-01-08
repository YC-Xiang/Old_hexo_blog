---
title: ICS2022 PA0
date: 2023-10-17 16:47:28
tags:
- ICS
categories:
- Project
---

## 1. 环境配置

### 1.1 虚拟机安装

网络选择桥接网络，复制物理状态

### 1.2 软件安装

```shell
apt-get install vim # vim
apt-get install openssh-server # ssh

apt-get install build-essential    # build-essential packages, include binary utilities, gcc, make, and so on
apt-get install man                # on-line reference manual
apt-get install gcc-doc            # on-line reference manual for gcc
apt-get install gdb                # GNU debugger
apt-get install git                # revision control system
apt-get install libreadline-dev    # a library used later
apt-get install libsdl2-dev        # a library used later
apt-get install llvm llvm-dev      # llvm project, which contains libraries used later
```

安装`build essential`会出现`g++-11 : Depends: gcc-11-base (= 11.2.0-19ubuntu1) but 11.4.0-1ubuntu1~22.04 is to be installed`错误。可能是ubuntu版本问题。

解决方法:使用aptitude来处理版本依赖问题。

```shell
apt-get install aptitude
aptitude install build-essential
...
```

安装完成后，进入`nemu`目录，执行`make menuconfig` -> `make`又报错:
`make[1]: bison: No such file or directory`
直接安装`sudo apt-get install bison` -> `make clean` -> `make` 又又报错：
`make[1]: flex: No such file or directory`
继续安装`sudo apt-get install flex`，终于成功运行。

## 1.3 配置git

```shell
git config --global user.name "221220000-Zhang San" # your student ID and name
git config --global user.email "zhangsan@foo.com"   # your email
git config --global core.editor vim                 # your favorite editor
git config --global color.ui true
```

## 1.4 配置ssh

[生成ssh密钥](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)，并上传公钥至github setting:

## More Exploration

熟悉一些常用的命令行工具, 并强迫自己在日常操作中使用它们
文件检索 - `cat`, `more`, `less`, `head`, `tail`, `file`, `find`
输入输出控制 - 重定向, 管道, `tee`, `xargs`
文本处理 - `grep`, `awk`, `sed`, `sort`, `wc`, `uniq`, `cut`, `tr`
正则表达式
系统监控 - `jobs`, `ps`, `top`, `kill`, `free`, `dmesg`, `lsof`
上述工具覆盖了程序员绝大部分的需求
可以先从简单的尝试开始, 用得多就记住了, 记不住就man
