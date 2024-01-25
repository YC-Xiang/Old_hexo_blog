---
title: CS61A Week1
date: 2024-1-22 21:33:28
tags:
- CS61A
categories:
- Project
---

## Lab0

`python3 ok --help`: 查看ok提示。

`python3 ok -q python-basics -u`

`python3 ok`: 运行全部测试。

`python3 ok --score`:查看分数。

`python3 ok ... --local`:本地运行测试。

`python3 -m doctest lab00.py`: 运行doctest。

## Hw1 Functions, Control

`python3 ok -q a_plus_abs_b`

`python3 ok -q two_of_three`

返回三个数中最小的两个数。先取min(i, j)得到较小的一个数，在从min(max(i, j), k)中得到第二小的数。

```python
def two_of_three(i, j, k):
    return min(i, j)**2 + min(max(i, j), k)**2
```

`python3 ok -q largest_factor`

返回能被整除的最大数。从1到n遍历，如果n%i==0即能够整除，返回最大值。

```python
def largest_factor(n):
    res = 1;
    for i in range(2, n):
        if n % i == 0:
            res = i
    return res
```

`python3 ok -q hailstone`

按照题意，偶数除以2，奇数*3+1操作，返回操作的次数。

```python
def hailstone(n):
    count = 1
    while (n != 1):
        print(n)
        if (n % 2 == 0):
            n = n // 2
        else:
            n = n * 3 + 1
        count += 1
    print(n)
    return count
```
