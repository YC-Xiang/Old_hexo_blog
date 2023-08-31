---
title: C语言解引用未对齐的指针引发硬件HardFault
date: 2023-08-31 22:01:28
tags:
- Misc
categories:
- Misc
---

工作中在ARMv8-M架构内核遇到如下问题：

首先定义了一个Char型数组,

```c
unsigned char buffer[1024];
```

调用了memcpy, 想把另一块数据拷贝到这块buffer**第五个Bytes**开始位置，即

```c
unsigned char buf[256];

memcpy(buffer+5, buf, 256); // Hardfault，芯片reset
```

这时发生了硬件HardFault，另外发现如果拷贝到buffer第四个Bytes开始位置就不会出现HardFault。

```c
memcpy(buffer+4, buf, 256); // 正常运行
```

这时候猜测这个版本的memcpy会使用机器字长对齐(32位4 bytes)的方式来拷贝，而不是一个字节一个字节地拷贝。这样导致解引用不是4字节对齐的unsigned int指针，发生了C语言未定义的行为，导致HardFault。

但也应该一开始判断是否为4字节对齐，如果没对齐，先拷贝字节到4字对齐，再开始4字节拷贝啊。。要确认下公司使用的memcpy实现了。。



附上找到的memcpy实现，https://blog.popkx.com/%E4%B8%BA%E4%BB%80%E4%B9%88%E9%80%90%E5%AD%97%E8%8A%82%E6%8B%B7%E8%B4%9D%E6%B2%A1%E6%9C%89memcpy%E5%87%BD%E6%95%B0%E5%BF%AB-%E5%AE%83%E4%BD%BF%E7%94%A8%E4%BA%86%E5%93%AA%E4%BA%9B%E6%8A%80/

```c
void aligned_memory_copy(void* dst, void* src, unsigned int bytes)
{
  unsigned char* b_dst = (unsigned char*)dst;
  unsigned char* b_src = (unsigned char*)src;

  // Copy bytes to align source pointer
  while ((b_src & 0x3) != 0)
  {
    *b_dst++ = *b_src++;
    bytes--;
  }

  unsigned int* w_dst = (unsigned int*)b_dst;
  unsigned int* w_src = (unsigned int*)b_src;
  while (bytes >= 4)
  {
    *w_dst++ = *w_src++;
    bytes -= 4;
  }

  // Copy trailing bytes
  if (bytes > 0)
  {
    b_dst = (unsigned char*)w_dst;
    b_src = (unsigned char*)w_src;
    while (bytes > 0)
    {
      *b_dst++ = *b_src++;
      bytes--;
    }
  }
}
```

# Reference

https://www.zhihu.com/question/320732761

https://stackoverflow.com/questions/98650/what-is-the-strict-aliasing-rule