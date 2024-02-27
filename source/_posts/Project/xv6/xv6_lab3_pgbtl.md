---
title: xv6_lab3 pgtbl
date: 2024-2-1 22:57:28
tags:
- xv6 OS
categories:
- Project
---

## Q1 Speed up system call

这个实验的目的是将用户程序的虚拟地址`USYSCALL`映射到保存有进程`pid`的物理地址。
这样不用通过系统调用`getpid()`的方式，直接通过`ugetpid()`访问虚拟地址就可以直接得到映射的进程pid。

```c
#define USYSCALL (TRAPFRAME - PGSIZE) // USYSCALL位于虚拟地址顶部Trapframe下面一个page

int ugetpid(void)
{
	struct usyscall *u = (struct usyscall *)USYSCALL; // 直接访问虚拟地址
	return u->pid;
}
```

在`struct proc`进程结构体中增加`struct usyscall *usyscall`, 在分配进程函数`allocproc`中初始化, 分配`p->pid`给`p->usyscall->pid`：

```c
if ((p->usyscall = (struct usyscall *)kalloc()) == 0)
{
	freeproc(p);
	release(&p->lock);
	return 0;
}
p->usyscall->pid = p->pid;
```

在给进程分配页表的函数`proc_pagetable()`中映射指定的虚拟地址。
> 注意要加上PTE_U

```c
p->pagetable = proc_pagetable(p);

pagetable_t proc_pagetable(struct proc *p)
{
  // ...
  // map the USYSCALL just below trapframe.
  if(mappages(pagetable, USYSCALL, PGSIZE,
              (uint64)(p->usyscall), PTE_R | PTE_U) < 0){
    uvmunmap(pagetable, USYSCALL, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }
  // ...
}
```

## Q2 Print a page table

实现`vmprint`函数，打印进程`pid==1`的page table。

```c
void vmprint(pagetable_t pagetable)
{
  static uint8 level;
  static uint8 once = 0;
  if (once == 0)
  {
  	printf("page table %p\n", pagetable);
	once = 1;
  }

  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      for (int i = 0; i < level; i++)
      {
	printf(".. ");
      }
      printf("..%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
      // this PTE points to a lower-level page table.
      level++;
      uint64 child = PTE2PA(pte);
      vmprint((pagetable_t)child);
    } else if(pte & PTE_V){ // 肯定是最后的根节点
      printf(".. .. ..%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    }
  }
  level = 0;
}
```

首先打印页表的物理地址`printf("page table %p\n", pagetable);`。

valid位为1，R/W/X为0的pte，不是叶节点，需要进一步索引到下一级页表。
valid位为1，R/W/X有为1的pte，是叶节点。

`%p`打印pte的内容和pte对应的物理地址。
%p对变量进行的格式化是将变量值以16进制打印，并在前面添加0x
不是所谓的打印变量地址！

```shell
page table 0x0000000087f6e000
..0: pte 0x0000000021fda801 pa 0x0000000087f6a000 # 此pte不是叶节点，pa指向下一级页表的起始地址
.. ..0: pte 0x0000000021fda401 pa 0x0000000087f69000
.. .. ..0: pte 0x0000000021fdac1f pa 0x0000000087f6b000
.. .. ..1: pte 0x0000000021fda00f pa 0x0000000087f68000
.. .. ..2: pte 0x0000000021fd9c1f pa 0x0000000087f67000
..255: pte 0x0000000021fdb401 pa 0x0000000087f6d000
.. ..511: pte 0x0000000021fdb001 pa 0x0000000087f6c000
.. .. ..509: pte 0x0000000021fdd813 pa 0x0000000087f76000
.. .. ..510: pte 0x0000000021fddc07 pa 0x0000000087f77000
.. .. ..511: pte 0x0000000020001c0b pa 0x0000000080007000
```

## Q3 Detecting which pages have been accessed

实现系统调用`pgaccess`, 传入要检查pages的起始虚拟地址`void *base`，要检查pages的数量`int len`，返回的bitmask`void *mask`，保存是否含有`PTE_A`标志的pages，根据`len`从LSB位开始按顺序保存：
`int pgaccess(void *base, int len, void *mask);`

```c
sys_pgaccess(void)
{
  // lab pgtbl: your code here.
  return 0;
  int num;
  uint64 p;
  uint64 user_bitmap_addr;

  if (argaddr(0, &p) < 0) // 获取user space传入的虚拟地址
    return -1;
  if (argint(1, &num) < 0) // 获取要检查pages的数量
    return -1;
  if (argaddr(2, &user_bitmap_addr) < 0) // 获取需要返回的bitmap地址
    return -1;

  return pgaccess(p, num, user_bitmap_addr);
}

int pgaccess(uint64 va, int num, uint64 user_bitmap_addr)
{
	struct proc *p = myproc();
	pte_t *pte;
	int ret;
	uint32 bitmap;

	for (int i = 0; i < num; i++)
	{
		pte = walk(p->pagetable, va + i * PGSIZE, 0); // 根据传入的virtual address找到对应的最后一层pte
		if (*pte & PTE_A)
		{
			*pte &= ~PTE_A; // 需要这一步清除，不然会一直置起。RISC-V硬件会在访问到该页的时候自动置起PTE_A
			bitmap |= (1 << i);
		}
	}

	ret = copyout(p->pagetable, user_bitmap_addr, (char *)&bitmap, 8); // 拷贝bitmap回user space，即user_bitmap_addr地址。

	return ret;
}
```
