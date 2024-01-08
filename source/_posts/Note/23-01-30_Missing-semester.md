---
title: Missing Semester of Computer Science
date: 2023-01-30 10:02:05
tags:
- Missing semester
categories:
- Notes
---

## Ch1 shell_scripts

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

### command substitution

`$(CMD)` will execute CMD, get the output of the command and substitute it in place.
`for file in $(ls)` will first call ls and then iterate over those values.

### process substitution

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

### shell globbing

- Wildcards
  - `?`替换单个字符
  - `*`替换后面所有字符
- Curly braces `{}`

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

## Ch4 commandline_environment

### Job control

`jobs`: lists the unfinished jobs associated with the current terminal session.

`fg + %num `: `num`是`jobs`命令显示进程对应的序号。

`bg+ %num`: 让进程在后台从stopped->running。

`ctrl + z`: 让当前进程进入后台并suspend。
