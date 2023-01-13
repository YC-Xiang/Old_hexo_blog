---
title: Vim
date: 2023-01-13 17:31:28
tags:
- Vim
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

# Resources

[Vim Adventures](https://vim-adventures.com/) is a game to learn Vim
