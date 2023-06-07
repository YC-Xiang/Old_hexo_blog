# Questions

时钟？

gadget

ep0

endpoint

# Others

USB标准名称变更：

USB 1.0 -> USB 2.0 Low-Speed

USB 1.1 -> USB 2.0 Full-Speed

USB 2.0 -> USB 2.0 High-Speed

USB 3.0 -> USB 3.1 Gen1 -> USB 3.2 Gen1

USB 3.1 -> USB 3.1 Gen2 -> USB 3.2 Gen2 × 1

USB 3.2 -> USB 3.2 Gen2 × 2

# Chapter3 Background

USB 接口可用于连接多达 127 种外设。

# Chapter4 Architectural Overview

### 4.1.1 Bus Topology 总线拓扑

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230606134650.png)

* USB Host
* USB Device
  * Hub：用来扩展USB接口，最多接5层hub，如上图。
  * Function：USB设备。

### 4.2.1 Electrical

USB 2.0协议支持3种速率：

- 低速(Low Speed，1.5Mbps)，兼容USB1.0
- 全速(Full Speed, 12Mbps)，兼容USB1.1
- 高速(High Speed, 480Mbps)



USB 2.0 host controllers和hubs提供能力使**full speed和low speed的数据**能

以**high speed**的速率在**host controller和hub**之间传递，

以**full speed和low speed**的速率在**hub和device**之间传递。

# Chapter7 Electrical

## 7.1 Signaling

High Speed电路图。

Hub D+, D-信号线上有右下两个15k Rpd下拉电阻，所以默认电平为0。

device D+信号线上有1.5k Rpu上拉电阻，接上后D+被拉高。运行后会被Rpu_enable移除。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607093420.png)

Spec Table 7.1对各元器件功能有详细解释。



高速设备D+, D-各有Rs 45Ω的下拉电阻，用来消除反射信号：

当断开高速设备后，Hub发出信号，得到的反射信号无法衰减，Hub监测到这些信号后就知道高速设备已经断开。对应上图的Rs和Disconnection Envelope Detector。当差分信号线的幅值超过**625mV**，意味着断开。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607094320.png)

#### 7.1.5.1 Low-/Full-speed Device Speed Identification

Full/High-speed device D+ 上有1.5k Rpu上拉。

Low-speed device D- 上有1.5k Rpu上拉。

用于attach时区分不同速率的设备。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607101850.png)

### 7.1.7 Signaling levels

#### 7.1.7.1 Low-/Full-speed Signaling Levels

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607103019.png)

#### 7.1.7.2 High-speed Signaling Levels

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607104959.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607105059.png)

#### 7.1.7.4 Data Signaling

##### 7.1.7.4.1 Low-/Full-Speed Signaling

SOP：Start Of Packet，Hub驱动D+、D-这两条线路从Idle状态变为K状态。SOP中的K状态就是SYNC信号的第1位数据，SYNC格式为3对KJ外加2个K。

EOP：End Of Packet，由数据的发送方发出EOP，数据发送方驱动D+、D-这两条线路，先设为SE0状态并维持2位时间，再设置为J状态并维持1位时间，最后D+、D-变为高阻状态，这时由线路的上下拉电阻使得总线进入Idle状态。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607112911.png)

##### 7.1.7.4.2 High-speed Signaling

#### 7.1.7.5 Reset

#### 7.1.7.6 Suspend

#### 7.1.7.7 Resume

### 7.1.8 Data encoding 数据编码

NRZI编码，电平信号不变表示1，跳变表示0。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607112056.png)

### 7.1.9 Bit Stuffing 位填充

连续传送6个1后，会填充一个0强制翻转信号。



# Chapter8 Protocol Layer

## 8.2 SYNC field

对于低速/全速设备，SYNC信号是8位数据(从做到右是00000001)；对于高速设备，SYNC信号是32位数据(从左到右是00000000000000000000000000000001)。使用NRZI编码时，前面每个"0"都对应一个跳变。

同步域这样可以用来同步主机端和设备端的数据时钟。

## 8.3 Packet Field Formats

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607150914.png)

### 8.3.1 PID

PID表示了包的类型。

PID后四位为前四位的取反。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607150746.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607151058.png)

### 8.3.2 Address fields

#### 8.3.2.1 Address Field

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607153555.png)

#### 8.3.2.2 Endpoint Field

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607153606.png)

### 8.3.3 Frame Number Field

### 8.3.4 Data Field

## 8.4 Packet Formats

### 8.4.1 Token Packets

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607163045.png)

- OUT
  - 通知设备将要输出一个数据包。
- IN
  - 通知设备返回一个数据包。
- SETUP
  - 只用于控制传输，跟OUT令牌包作用一样，通知设备将要输出一个数据包。区别在于SETUP后只使用DATA0数据包，且只能发送到设备的endpoint，并且设备必须接收。
- SOF
  - 以广播的形式发送，所有USB全速设备和高速设备都可以收到SOF包。host在full-speed bus每ms产生一个帧，在high-speed bus每125us产生一个微帧。USB主机会对当前帧号