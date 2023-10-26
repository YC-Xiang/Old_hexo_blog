---
title: ICS2022 PA0
date: 2023-10-17 16:47:28
tags:
- ICS
categories:
- Project
---

# 命令行工具

# Vim

## Ctags
[Ctags使用方法](https://kulkarniamit.github.io/whatwhyhow/howto/use-vim-ctags.html)

Ubuntu:
`$ sudo apt-get update && sudo apt-get install -y exuberant-ctags`

创建~/.ctags，描述要忽略的文件/文件夹。
进入source code根目录，运行`ctags`, 生成文件tags。

`vim -t <tags>` 从shell命令行跳转到tag的定义位置。
`Ctrl ]` 跳转。
`Ctrl T` 返回。
`:tn` 跳转到下一个定义(如果有多个定义的话)。
`:tp` 跳转到上一个定义(如果有多个定义的话)。
`:tags` 列出tag stack。
`:tags main` 跳转到指定tag，main。
`:tags /^get` jumps to the tag that starts with “get”
`:tag /Final$` jumps to the tag that ends with “Final”
`:tag /norm` lists all the tags that contain “norm”, including “id_norm”
