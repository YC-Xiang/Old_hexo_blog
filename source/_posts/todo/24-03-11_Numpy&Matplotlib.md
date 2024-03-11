---
title: Python Numpy&Matplotlib笔记
date: 2024-03-11 14:52:28
tags:
- Python
categories:
- Notes
hide: true
---

# Numpy

todo:

# Matplotlib

## Reference

[官网](https://matplotlib.org/stable/)
[API参考](https://matplotlib.org/3.8.3/api/index.html)
[Tutorial](https://matplotlib.org/stable/tutorials/pyplot.html#sphx-glr-tutorials-pyplot-py)
[Tutorial中示例ipynb文件](https://matplotlib.org/stable/_downloads/0e5d53c90d360a55082257e36bfaa2c2/pyplot.ipynb)

</br>

安装Matplotlib：`pip install matplotlib`

Figure对应的API设置如图：

![Parts of a Figure](https://matplotlib.org/stable/_images/anatomy.png)

常用的API:

[markers, line sytles, colors](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.plot.html#matplotlib.pyplot.plot)

```py
plt.plot([1, 2, 3, 4], [1, 4, 9, 16], 'ro')
plt.axis((0, 6, 0, 20))
plt.ylabel('some numbers') # x,y坐标轴名称
plt.title('title') # 标题
plt.text(2, 4, r'$\mu=100,\ \sigma=15$') # 在某个点加入text
plt.annotate('local max', xy=(3, 9), xytext=(3, 9),
             arrowprops=dict(facecolor='black', shrink=0.05),
             ) # 注释，比text功能更强大
plt.grid(True) # 开启网格
plt.yscale('linear') # x,y轴刻度分布规则，linear/log/symlog/logit...
plt.show()
```

利用numpy输入数据：

```py
import numpy as np

# evenly sampled time at 200ms intervals
t = np.arange(0., 5., 0.2)

# red dashes, blue squares and green triangles
plt.plot(t, t, 'r--', t, t**2, 'bs', t, t**3, 'g^')
plt.show()
```

绘制子图：

```py
def f(t):
    return np.exp(-t) * np.cos(2*np.pi*t)

t1 = np.arange(0.0, 5.0, 0.1)
t2 = np.arange(0.0, 5.0, 0.02)

plt.figure()
plt.subplot(211)
plt.plot(t1, f(t1), 'bo', t2, f(t2), 'k')

plt.subplot(212)
plt.plot(t2, np.cos(2*np.pi*t2), 'r--')
plt.show()
```

## cheatsheet

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/cheatsheet1.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/cheatsheet2.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/beginer.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/intermediate.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/tips.png)
