---
title: Vim
date: 2023-01-13 17:31:28
tags:
- Vim
- Missing semester
categories:
- Notes
---

# Modal editing

- **Normal**: for moving around a file and making edits
- **Insert**: `i` for inserting text
- **Replace**: `R` for replacing text
- **Visual**: (plain`v`, line`V`, or block`Ctrl+v`): for selecting blocks of text(use movement keys).
- **Command-line**: `:` for running a command

`<ESC>`  switch from any mode back to **Normal mode**.

# Basic

## Command-line

- `:q` quit (close window)
- `:w` save (“write”)
- `:wq` save and quit
- `:e {name of file}` open file for editing
- `:ls` show open buffers
- `:help {topic}` open help
  - `:help :w` opens help for the `:w` command
  - `:help w` opens help for the `w` movement

# Vim’s interface is a programming language

## Movement

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

## Edits

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

## Counts

You can combine **nouns** and **verbs** with a **count**, which will perform a given action a number of times.

- `3w` move 3 words forward
- `5j` move 5 lines down
- `7dw` delete 7 words

## Modifiers

You can use modifiers to change the meaning of a noun. Some modifiers are `i`, which means “inner” or “inside”, and `a`, which means “around”.

> 光标在括号中，`ci(`可以把括号内的内容替换并进入insert，类似`di(`也一样，相当于删除。`da(`连带括号一起删除。
>
> 这里的`i`和`a`不是edit中的含义，而是**inner**和**around**的意思。

- `ci(` change the contents inside the current pair of parentheses
- `ci[` change the contents inside the current pair of square brackets
- `da'` delete a single-quoted string, including the surrounding single quotes

# Customizing Vim

[my vim config](https://github.com/YC-Xiang/dotfiles/blob/main/vim/.vimrc)

# Extending Vim

Vim 8.0 之后自带插件管理工具，只要create the directory `~/.vim/pack/vendor/start/`, and put plugins in there (e.g. via `git clone`). `vendor`目录名好像可以替换。

# Advanced Vim

## Search and replace

`:s` (substitute) command

- `%s/foo/bar/g`
  - replace foo with bar globally in file
  - `%s/\[.*\](\(.*\))/\1/g`
  - replace named Markdown links with plain URL

## Multiple windows

- `:sp` / `:vsp` to split windows
- Can have multiple views of the same buffer.

## Macros

to do

# Vimtutor

## Lesson 1

`hjkl` 移动

`x` 删除一个字符

`i` 输入

`a` append输入

## Lesson 2

`dw` 删除一个单词

`d$` 输出到行尾

`2w` `3b` `2e` 移动单词

`d2w` 删除两个单词

`dd` `2dd` 删除两行

`u` 撤销 `U` 返回一行的原始状态 `Ctrl r` 复原

## Lesson 3

`dd` 之后的一行可以 `p` 粘贴

`rx` 替换某个字符为`x`

`ce` 删除光标后单词部分，并进入insert mode `c$` 输出光标到行尾，并进入insert mode


## Lesson 4

`Ctrl g` 显示当前行状态 `G` 文件末尾 `gg` 文件开头

`/` 向后搜索 `?`向前搜索 `ctrl o` 返回 `ctrl i` 前进

`%` 跳转到对应匹配的`) ] }`

`s/thee/the/g` 替换一个`thee`成`the`

`s/thee/the/g` 一行中`thee`替换成`the`

`:%s/thee/the/g` 整个文件的`thee`替换成`the`

`:%s/thee/the/gc` 整个文件的`thee`替换成`the`，每个替换会有命令提示

`:#,#s/thee/the/g` `#` 是替换的行范围

## Lesson 5

`! + command` 执行外部命令

`:w FILENAME` 文件另存为

`v` 进入visual模式选中再 `:w FILENAME` 保存部分内容

`:r FILENAME` 将文件内容追加到光标下

`:r !ls` 将ls内容加到光标下

## Lesson 6

`o` 光标下插入新行 `O`光标上插入新行

`R` replace mode

`2y` 复制两行

`:set ic` 接下来搜索大小写都会包括

## Lesson 7

`:`接`ctrl d`可以自动显示命令

``
# Resources

[Vim Adventures](https://vim-adventures.com/) is a game to learn Vim
