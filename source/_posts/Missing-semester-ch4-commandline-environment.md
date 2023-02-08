---
title: Missing-semester_ch4_commandline_environment
date: 2023-02-07 15:02:48
tags:
- tmux
- Missing semester
---

# Job control

`jobs`: lists the unfinished jobs associated with the current terminal session.

`fg + %num `: `num`是`jobs`命令显示进程对应的序号。

`bg+ %num`: 让进程在后台从stopped->running。

`ctrl + z`: 让当前进程进入后台并suspend。

# Tmux

`tmux`: open a new session.

`C-b %`: 左右分屏。

`C-b "`: 上下分屏。

`C-b <arrow key>`:在panes间移动。

`exit` or hit `Ctrl-d`：退出当前pane。

`C-b c`: new window.

`C-b p`: previous window.

`C-b n`: next window.

`C-b <number>` : move to window n.

`tmux ls`: list sessions.

`tmux attach -t 0`: attach to 0 session.

`C-b ?`: help message.

`C-b z`: make a pane go full screen. Hit `C-b z` again to shrink it back to its previous size

`C-b C-<arrow key>`: Resize pane in direction of <arrow key>

`C-b ,`: Rename the current window

`<C-b> [` Start scrollback. You can then press `<space>` to start a selection and `<enter>` to copy that selection.

## my configs

`C-b` -> `C-a`

`C-b %` -> `C-a |`

`C-b "` -> `C-a -`

`C-b <arrow key>` -> `alt <arrow key>`

[more commands click this](https://missing.csail.mit.edu/2020/command-line/)
