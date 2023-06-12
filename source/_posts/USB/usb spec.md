# Questions

USB-IF

# Others

USB标准名称变更：

USB 1.0 -> USB 2.0 Low-Speed

USB 1.1 -> USB 2.0 Full-Speed

USB 2.0 -> USB 2.0 High-Speed

USB 3.0 -> USB 3.1 Gen1 -> USB 3.2 Gen1

USB 3.1 -> USB 3.1 Gen2 -> USB 3.2 Gen2 × 1

USB 3.2 -> USB 3.2 Gen2 × 2



USB OTG中增加了一种MINI USB接头，使用5条线，比标准USB多一条身份识别线。

USB协议规定，设备在未配置前，可以从Vbus最多获取100mA电流，配置之后，最多可以获得500mA电流。Vbus是5V的电压。



枚举就是从设备读取各种描述符信息。



Control transfer：低速8字节，高速64字节，全速8/16/32/64字节。

Isochronous Transfer：全速1023字节，高速1024字节，低速不支持。

Interrupt Transfer：低速上限8字节，全速上限64字节，高速上限1024字节。

Bulk transfer：高速512字节，全速8/16/32/64字节，低速不支持。

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

# Chapter5 USB Data Flow Model

### 5.3.1 Device Endpoints

Endpoint 只支持一种方向的数据流通，input or output。除endpoint0，input+output。

endpoint 描述的内容有：

- 总线访问频率/延迟要求
- 带宽要求
- endpoint number
- Error handling
- 最大的packet size
- 数据传输方向

### 5.3.2 Pipes

- Stream

  传输的data没有USB-defined structure

- Message

  传输的data有USB-defined structure

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

- OUT
  - 通知设备将要输出一个数据包。
- IN
  - 通知设备返回一个数据包。
- SETUP
  - 只用于控制传输，跟OUT令牌包作用一样，通知设备将要输出一个数据包。区别在于SETUP后只使用DATA0数据包，且只能发送到设备的endpoint，并且设备必须接收。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230607163045.png)

### 8.4.3 SOF packets

- SOF
  - 以广播的形式发送，所有USB全速设备和高速设备都可以收到SOF包。host在full-speed bus每ms产生一个帧，在high-speed bus每125us产生一个微帧。USB主机会对当前帧号进行计数，在每次帧开始时（或者微帧开始时，每毫秒有8个微帧，这8个微帧的帧号是相同的，即相同的SOF）。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608111151.png)

### 8.4.4 Data Packets

low-speed 最大8bytes。

full-speed 最大1023bytes。

high-speed 最大1024bytes。

### 8.4.5 Handshake Packets

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608112219.png)

- ACK

  表示正确接受数据，并且有足够空间来容纳数据。主机和设备都可以用ACK来确认。而NAK, STALL, NYET只有设备能够返回。

- NAK

  表示设备无法从主机端接收数据，或者设备没有数据返回给主机。

- STALL

  表示设备无法执行这个请求，或者端点已经被挂起了，表示一种错误的状态。如果端点的Halt feature被设置了，会返回STALL。

- NYET

  只在high-speed输出事务中使用，表示设备本次数据成功接收，但是没有足够空间来接收下一次数据。主机在下一次输出数据时，将先使用PING令牌包来试探设备是否有足够空间接收数据。

### 8.4.6 Handshake Response

#### 8.4.6.1 Function Response to IN Transactions

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608113546.png)

#### 8.4.6.2 Host Response to IN Transactions

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608114127.png)

#### 8.4.6.3 Function Response to an OUT Transaction

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608114206.png)

第三行对应If the transaction is maintaining sequence bit synchronization and a mismatch is detected (refer to Section 8.6 for details), then the function returns ACK and discards the data。

### 8.5.2 Bulk Transactions

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608135656.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608142617.png)

数据包类型在DATA0和DATA1之间切换。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608141406.png)

### 8.5.3 Control Transfer

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608142906.png)

对应下图的Setup Stage。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608145713.png)

Setup Stage必须是DATA0。

Data Stage是可选的。

### 8.5.4 Interrupt Transactions

没有PING和NYET两个包。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608145003.png)

### 8.5.5 Isochronous Transactions

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608145252.png)

# Chapter9 Device Framework

USB的状态切换图：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609174140.png)

## 9.3 USB Device Requests

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612145851.png)

- bmRequestType：区分方向，type，device/interface/endpoint。

- bRequest: 具体的事件，只定义了bmRequestType D[6:5]为Standard的情况。

- wValue: 传递一些需要的值。

- wIndex: 分为endpoint和interface，两种的wIndex不同。

**endpoint:**

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612152356.png)

D7: 0:OUT 1:IN 在control pipe中direction应该被设为0，即OUT事件。但device可以接收0或1。

**interface:**

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612152452.png)

- wLength: control transfer第二段传递data0的字节数。如果wLength为0, 不需要传递数据，没有数据传输的阶段（注意这里的数据传输阶段是control transfer 中data0那段，是SETUP stage中那段）。

  INPUT request wLength不能超过wLength字节数，可以比wLength少。

  OUTPUT request wLength正确表示host传递给device的字节数。

## 9.4 Standard Device Requests

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230608170120.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612110946.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612111010.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612155242.png)

### 9.4.1 Clear Feature

在Address state下合法。Recipient为device or ep0合法，看Table9-6。

Test_Mode feature 不能被ClearFeature()清除。

### 9.4.5 Get Status

bmRequestType为Device，device返回的信息。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612160419.png)

bmRequestType为Interface，status为0。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612160437.png)

bmRequestType为endpoint，返回是否halt。

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230612160446.png)

所有interrupt和bulk endpoints都要实现Halt feature。

Default control pipe，即ep0 in and ep0 out，不需要也不推荐实现Halt feature。

### 9.4.6 Set Address

Default stage: 传递的地址不为0则进入Address stage， 为0则保持在Default stage。

Address stage: 传递的地址为0则进入Default stage，不为0则保持在Address stage，并更换新的地址。

地址不能超过127。

## 9.6 Standard USB Descriptor Definitions

### 9.6.1 Device 设备描述符

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609173233.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609173252.png)

### 9.6.2 Device_qualifer

### 9.6.3 Configuration 配置描述符

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609173911.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609173929.png)

### 9.6.5 Interface 接口描述符

接口对应一种function。

![image-20230609174005424](C:\Users\yucheng_xiang\AppData\Roaming\Typora\typora-user-images\image-20230609174005424.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609174012.png)

### 9.6.6 Endpoint 端点描述符

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609174035.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609174043.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609174055.png)

### 9.6.7 String 字符串描述符







