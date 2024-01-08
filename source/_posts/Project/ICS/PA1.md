---
title: ICS2022 PA1
date: 2023-01-10 16:47:28
tags:
- ICS
categories:
- Project
---

## RTFSC

```makefile
# nemu/scripts/native.mk

compile_git:
	$(call git_commit, "compile NEMU")
$(BINARY): compile_git

override ARGS ?= --log=$(BUILD_DIR)/nemu-log.txt
override ARGS += $(ARGS_DIFF) # nemu/tools/difftest.mk中CONFIG_DIFFTEST未定义，所以ARGS_DIFF不存在

IMG ?=

NEMU_EXEC := $(BINARY) $(ARGS) $(IMG)

run: run-env
	$(call git_commit, "run NEMU")
	$(NEMU_EXEC)

```

由makefile可知，输入`make run`启动nemu时，传递给`monitor.c parse_args(argc, argv)`的参数为
`--log=$(BUILD_DIR)/nemu-log.txt`

## 配置系统和项目构建

在`nemu`目录下执行`make menuconfig`,结果会保存至`nemu/.config`

生成

可以被包含到C代码中的宏定义：`nemu/include/generated/autoconf.h`

可以被包含到Makefile中的变量定义：`nemu/include/config/auto.conf`

- `SRCS-y` - 参与编译的源文件的候选集合
- `SRCS-BLACKLIST-y` - 不参与编译的源文件的黑名单集合
- `DIRS-y` - 参与编译的目录集合, 该目录下的所有文件都会被加入到SRCS-y中
- `DIRS-BLACKLIST-y` - 不参与编译的目录集合, 该目录下的所有文件都会被加入到SRCS-BLACKLIST-y中

Makefile的编译规则在`nemu/scripts/build.mk`中定义。

# 基础设施


# 表达式求值

[regcomp() regexec() regfree()详解](https://blog.csdn.net/derkampf/article/details/70661551)
`int regcomp (regex_t *compiled, const char *pattern, int cflags)`
`int regexec (regex_t *compiled, char *string, size_t nmatch, regmatch_t matchptr [], int eflags)`

字符串中的转义需要两个`\\`,比如转义+号，`"\\+"`
[转义，特殊字符](https://zh.javascript.info/regexp-escaping#newregexp)

## 一些字符串处理函数

`strcat`
`strcmp`
`strstr`
`strtol`

`char *strtok(char *str, const char *delim)` 分解字符串 str 为一组字符串，delim 为分隔符。

`atoi`函数：十进制字符串数字转为int类型。

`long int strtol(const char *str, char **endptr, int base)`：可以根据字符串数字为10进制/16进制...，转化为`long int`。如`strtol(0xabc, NULL, 16)`。
base表示输入数字的进制，base为0表示自动判断输入的数字为8/10/16进制。
