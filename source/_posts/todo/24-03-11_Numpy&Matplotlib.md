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

[官网教程](https://numpy.org/doc/stable/)

```py
pip install numpy # install numpy
import numpy as np
```

## How to create a basic array

```py
np.array([1,2,3])
np.zeros(2) # array([0., 0.])
np.ones(2) # array([1., 1.])
np.empty(2) # random memory values
np.arange(4) # array([0, 1, 2, 3])
np.arange(2, 9, 2) # first_num, last_num, step. array([2, 4, 6, 8])
np.linspace(0, 10, num=5) # 0 to 10, divided by 5 numbers. array([ 0. ,  2.5,  5. ,  7.5, 10. ])
# 指定数据格式，默认的为float型
np.ones(2, dtype=np.int64) # array([1, 1])
```

## Adding, removing, sorting

```py

```

// todo:

# Matplotlib

## Reference

[官网](https://matplotlib.org/stable/)
[API参考](https://matplotlib.org/3.8.3/api/index.html)
[Tutorial](https://matplotlib.org/stable/tutorials/pyplot.html#sphx-glr-tutorials-pyplot-py)
[Tutorial中示例ipynb文件](https://matplotlib.org/stable/_downloads/0e5d53c90d360a55082257e36bfaa2c2/pyplot.ipynb)

</br>

```py
pip install matplotlib #install matplotlib
import matplitlib.plot as plt
```

Figure对应的API设置如图：

![Parts of a Figure](https://matplotlib.org/stable/_images/anatomy.png)

常用的API:

[markers, line sytles, colors](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.plot.html#matplotlib.pyplot.plot)

```py
plt.plot([1, 2, 3, 4], [1, 4, 9, 16], 'ro')
plt.axis((0, 6, 0, 20))
plt.ylabel('some numbers') # x,y坐标轴名称
plt.title('title') # 标题
plt.xlim(0, 6) #x轴坐标轴刻度范围
plt.ylim((0, 3))#y轴坐标轴刻度范围
plt.text(2, 4, r'$\mu=100,\ \sigma=15$') # 在某个点加入text
plt.annotate('local max', xy=(3, 9), xytext=(3, 9),
             arrowprops=dict(facecolor='black', shrink=0.05),
             ) # 注释，比text功能更强大
plt.grid(True) # 开启网格
plt.yscale('linear') # x,y轴刻度分布规则，linear/log/symlog/logit...
plt.plot(2, 3, label="123")#第一个label
plt.plot(2, 3* 2, label="456")#第二个label
plt.legend(loc='best')#图列位置，可选best，center等
plt.show()

# 如果需要将数字设为负数，也可能出现乱码的情况
plt.rcParams['axes.unicode_minus']=False
# 如果title是中文，matplotlib会乱码
plt.rcParams['font.sans-serif']=['SimHei']

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
