---
title: Missing Semester of Computer Science
date: 2023-01-30 10:02:05
tags:
- Missing semester
categories:
- Notes
---

# Ch1 shell_scripts

`foo=bar` 变量定义`=`左右不能加空格。

用`'`分隔的字符串是字面值字符串，不会替换变量值，而用`"`分隔的字符串会。

```bash
foo=bar
echo "$foo"
# prints bar
echo '$foo'
# prints $foo
```

`$0`- Name of the script
`$1`- to $9 - Arguments to the script. $1 is the first argument and so on.
`$@`- All the arguments
`$#`- Number of arguments
`$?`- Return code of the previous command
`$$`- Process identification number (PID) for the current script
`!!`- Entire last command, including arguments. A common pattern is to execute a command only for it to fail due to missing permissions; you can quickly re-execute the command with sudo by doing `sudo !!`
`$_`- Last argument from the last command. If you are in an interactive shell, you can also quickly get this value by typing Esc followed by `.` or `Alt+.`


The `true` program will always have a 0 return code and the `false` command will always have a 1 return code.

`Command1 && Command2` 如果Command1命令运行成功，则继续运行Command2命令。
`Command1 || Command2` 如果Command1命令运行失败，则继续运行Command2命令。

```bash
false || echo "Oops, fail"
# Oops, fail

true || echo "Will not be printed"
#

true && echo "Things went well"
# Things went well

false && echo "Will not be printed"
#

true ; echo "This will always run"
# This will always run

false ; echo "This will always run"
# This will always run
```

**command substitution**
`$(CMD)` will execute CMD, get the output of the command and substitute it in place.
`for file in $(ls)` will first call ls and then iterate over those values.

**process substitution**
`<(CMD)` will execute CMD and place the output in a temporary file and substitute the <() with that file’s name.
`diff <(ls foo) <(ls bar)` will show differences between files in dirs foo and bar.

Example:

```bash
#!/bin/bash

echo "Starting program at $(date)" # Date will be substituted

echo "Running program $0 with $# arguments with pid $$"

for file in "$@"; do
    grep foobar "$file" > /dev/null 2> /dev/null # 标准输出和标准错误都重定向到/dev/null
    # When pattern is not found, grep has exit status 1
    # We redirect STDOUT and STDERR to a null register since we do not care about them
    if [[ $? -ne 0 ]]; then
        echo "File $file does not have any foobar, adding one"
        echo "# foobar" >> "$file"
    fi
done
```
{% note info %}
try to use double brackets [[ ]] in favor of simple brackets [ ]
{% endnote %}

**shell globbing**
- Wildcards
  - `?`替换单个字符
  - `*`替换后面所有字符
- Curly braces `{}`
-
```bash
convert image.{png,jpg}
# Will expand to
convert image.png image.jpg

cp /path/to/project/{foo,bar,baz}.sh /newpath
# Will expand to
cp /path/to/project/foo.sh /path/to/project/bar.sh /path/to/project/baz.sh /newpath

# Globbing techniques can also be combined
mv *{.py,.sh} folder
# Will move all *.py and *.sh files
```

# Ch2 Vim

## Modal editing

- **Normal**: for moving around a file and making edits
- **Insert**: `i` for inserting text
- **Replace**: `R` for replacing text
- **Visual**: (plain`v`, line`V`, or block`Ctrl+v`): for selecting blocks of text(use movement keys).
- **Command-line**: `:` for running a command

`<ESC>`  switch from any mode back to **Normal mode**.

## Basic

### Command-line

- `:q` quit (close window)
- `:w` save (“write”)
- `:wq` save and quit
- `:e {name of file}` open file for editing
- `:ls` show open buffers
- `:help {topic}` open help
  - `:help :w` opens help for the `:w` command
  - `:help w` opens help for the `w` movement

## Vim’s interface is a programming language

### Movement

**Movements in Vim are also called “nouns”.**

- Basic movement: `hjkl` (left, down, up, right)
- Words: `w` (next word), `b` (beginning of word), `e` (end of word)
- Lines: `0` (beginning of line), `^` (first non-blank character), `$` (end of line)
- Screen: `H` (top of screen), `M` (middle of screen), `L` (bottom of screen)
- Scroll: `Ctrl-u` (up), `Ctrl-d` (down)
- File: `gg` (beginning of file), `G` (end of file)
- Line numbers: `:{number}<CR>` or `{number}G` (line {number})
- Misc: `%` (corresponding item)
- Find: `f{character}`, `t{character}`, `F{character}`, `T{character}`
  - find/to forward/backward {character} on the current line
  - `,` / `;` for navigating matches
- Search: `/{regex}`, `n` / `N` for navigating matches

### Edits

**Vim’s editing commands are also called “verbs”**

- `i` enter Insert mode
- `o` / `O` insert line below / above
- `d{motion}` delete {motion}
  - e.g. `dw` is delete word, `d$` is delete to end of line, `d0` is delete to beginning of line
- `c{motion}` change {motion}
  - e.g. `cw` is change word. like `d{motion}` followed by `i`
- `x` delete character (equal do `dl`)
- `s` substitute character (equal to `cl`)
- Visual mode + manipulation
  - select text, `d` to delete it or `c` to change it
- `u` to undo, `<Ctrl+r>` to redo
- `y` to copy / “yank” (some other commands like `d` also copy)
- `p` to paste
- Lots more to learn: e.g. `~` flips the case of a character

### Counts

You can combine **nouns** and **verbs** with a **count**, which will perform a given action a number of times.

- `3w` move 3 words forward
- `5j` move 5 lines down
- `7dw` delete 7 words

### Modifiers

You can use modifiers to change the meaning of a noun. Some modifiers are `i`, which means “inner” or “inside”, and `a`, which means “around”.

> 光标在括号中，`ci(`可以把括号内的内容替换并进入insert，类似`di(`也一样，相当于删除。`da(`连带括号一起删除。
>
> 这里的`i`和`a`不是edit中的含义，而是**inner**和**around**的意思。

- `ci(` change the contents inside the current pair of parentheses
- `ci[` change the contents inside the current pair of square brackets
- `da'` delete a single-quoted string, including the surrounding single quotes

## Customizing Vim

[my vim config](https://github.com/YC-Xiang/dotfiles/blob/main/vim/.vimrc)

## Extending Vim

Vim 8.0 之后自带插件管理工具，只要create the directory `~/.vim/pack/vendor/start/`, and put plugins in there (e.g. via `git clone`). `vendor`目录名好像可以替换。

## Advanced Vim

### Search and replace

`:s` (substitute) command

- `%s/foo/bar/g`
  - replace foo with bar globally in file
  - `%s/\[.*\](\(.*\))/\1/g`
  - replace named Markdown links with plain URL

### Multiple windows

- `:sp` / `:vsp` to split windows
- Can have multiple views of the same buffer.

### Macros

to do

## Vimtutor

### Lesson 1

`hjkl` 移动

`x` 删除一个字符

`i` 输入

`a` append输入

### Lesson 2

`dw` 删除一个单词

`d$` 输出到行尾

`2w` `3b` `2e` 移动单词

`d2w` 删除两个单词

`dd` `2dd` 删除两行

`u` 撤销 `U` 返回一行的原始状态 `Ctrl r` 复原

### Lesson 3

`dd` 之后的一行可以 `p` 粘贴

`rx` 替换某个字符为`x`

`ce` 删除光标后单词部分，并进入insert mode `c$` 输出光标到行尾，并进入insert mode


### Lesson 4

`Ctrl g` 显示当前行状态 `G` 文件末尾 `gg` 文件开头

`/` 向后搜索 `?`向前搜索 `ctrl o` 返回 `ctrl i` 前进

`%` 跳转到对应匹配的`) ] }`

`s/thee/the/g` 替换一个`thee`成`the`

`s/thee/the/g` 一行中`thee`替换成`the`

`:%s/thee/the/g` 整个文件的`thee`替换成`the`

`:%s/thee/the/gc` 整个文件的`thee`替换成`the`，每个替换会有命令提示

`:#,#s/thee/the/g` `#` 是替换的行范围

### Lesson 5

`! + command` 执行外部命令

`:w FILENAME` 文件另存为

`v` 进入visual模式选中再 `:w FILENAME` 保存部分内容

`:r FILENAME` 将文件内容追加到光标下

`:r !ls` 将ls内容加到光标下

### Lesson 6

`o` 光标下插入新行 `O`光标上插入新行

`R` replace mode

`2y` 复制两行

`:set ic` 接下来搜索大小写都会包括

### Lesson 7

`:`接`ctrl d`可以自动显示命令

``

## Resources

[Vim Adventures](https://vim-adventures.com/) is a game to learn Vim

# Ch4 commandline_environment

## Job control

`jobs`: lists the unfinished jobs associated with the current terminal session.

`fg + %num `: `num`是`jobs`命令显示进程对应的序号。

`bg+ %num`: 让进程在后台从stopped->running。

`ctrl + z`: 让当前进程进入后台并suspend。

## Tmux

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

### my configs

`C-b` -> `C-a`

`C-b %` -> `C-a |`

`C-b "` -> `C-a -`

`C-b <arrow key>` -> `alt <arrow key>`

[more commands click this](