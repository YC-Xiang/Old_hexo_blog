---
title: DFU(Device Firmware Upgrade)
date: 2023-08-15 17:39:28
tags:
- usb
categories:
- usb
---
# 2. Overview

四个阶段：

- Enumeration
  - device告知host具备的能力。通过Run-Time Descriptor中增加的DFU class-interface descriptor和functional descriptor实现。
- Reconfiguration
  - host和device同意初始固件升级。host会发送一次USB reset，设备会exports DFU descriptors出来。
- Transfer
- Manifestation
  - device告知设备完成升级，host会再次发送USB reset, 重新枚举设备，运行新固件。

总体流程：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802161808.png)

# 3. Requests

bRequest分别从DFU_DETACH: 0 ~ DFU_ABORT: 6

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802161942.png)

# 4. Enumeration Phase

## 4.1 Run-Time Descriptor Set

支持DFU的设备，在**run-time**时需要额外增加两个描述符：

- **A single DFU class interface descriptor**
- **A single functional descriptor**

因此Configuration descriptor的*bNumInterfaces*域需要加1。



### **Run-time DFU Interface Descriptor**

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802163107.png)

### **DFU Functional Descriptor**

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802163409.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802163417.png)

```c
static void PrepareDFUFunDesc(DFUFunDesc_t *pDFUFunDesc)
{
	pDFUFunDesc->bLength         = sizeof(DFUFunDesc_t);
	pDFUFunDesc->bDescriptorType = 0x21;
	pDFUFunDesc->bmAttributes    = g_DFUVar.bmAttributes; /// BIT0 | BIT1 | BIT2 | BIT3
	pDFUFunDesc->wDetachTimeOut  = 200;
	pDFUFunDesc->wTransferSize   = g_DFUVar.wTransferSize; // 4096
	pDFUFunDesc->bcdDFUVersion   = 0x0110;

	if(IsDFUMode())
	{
		pDFUFunDesc->wDetachTimeOut = 2000;
	}
}
```



## 4.2 DFU Mode Descriptor Set

host和device一致同意执行DFU操作后，host会重新枚举设备。这时候设备会export出DFU descriptor set包括：

- A DFU device descriptor
- A single configuration descriptor
- A single interface descriptor (including descriptors for alternate settings, if present)
- A single functional descriptor

### **DFU Device Descriptor**

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802164728.png)

![image-20230802164737635](C:\Users\yucheng_xiang\AppData\Roaming\Typora\typora-user-images\image-20230802164737635.png)

```c
// rom code UsbDescCore_Rom.c
USBDevDesc_t USBDevDesc =
	{
		sizeof(USBDevDesc),		// bLength:
		0x01,					// USB_DEVICE_DESCRIPTOR_TYPE,bDescriptorType:
		0x0201,					// bcdUSB version:NORM:0200H
		DEV_CLS_MULTI,			// bDeviceClass:-> This is a Multi-interface Function Code Device
		DEV_SUBCLS_COMMON,		// bDeviceSubClass: -> This is the Common Class Sub Class
		DEV_PROTOCOL_IAD,		// bDeviceProtocol: -> This is the Interface Association Descriptor protocol
		0x40,					// bMaxPacketSize0: = (64) Bytes
		ROM_RT_VID,				// idVendor:    = Realtek Corp.
		ROM_RT_FP_PID,			// idProduct:
		0x0001,					// FW_TRUNK_VERSION, //bcdDevice:1.00
		I_MANUFACTURER,			// iManufacturer:
		I_PRODUCT,				// iProduct:
		I_SERIALNUMBER,			// iSerialNumber:
		0x01					// bNumConfigurations:
	};

	if(IsDFUMode())
	{
		// USBDevDesc.bcdUSB = 0x0200;
		USBDevDesc.bDeviceClass    = 0x00;
		USBDevDesc.bDeviceSubClass = 0x00;
		USBDevDesc.bDeviceProtocol = 0x00;
		USBDevDesc.idProduct = 0x5800;
		if(DevIdcfg.cfgDevId_en==1)
		{
			USBDevDesc.idVendor = DevIdcfg.dfu_idVendor;
			USBDevDesc.idProduct = DevIdcfg.dfu_idProduct;
			USBDevDesc.bcdDevice = DevIdcfg.dfu_bcdDevice;
		}
	}
```



### DFU Mode Configuration Descriptor

与USB1.0 spec中标准配置描述符相同，除了*bNumInterfaces*域为01h

### DFU Mode Interface Descriptor

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802165234.png)

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802165243.png)

### DFU Functional Descriptor

与4.1中的相同。

# 5. Reconfiguration Phase

- host发送DFU_DETACH request on EP0
- host发送USB reset
- device枚举DFU descriptor

## 5.1 DFU_DETACH

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230802170347.png)

# 6. Transfer Phase

## 6.1 Downloading

把固件文件分为N pieces。

$N = ((F - S) / O) + 1$

F: 传输固件大小，S: 固件文件suffix大小，O:每次传输的size



如果传输过程中发生error，device会返回STALL给host，随后host会发送DFU_GETSTATUS来判断错误的原因。



device有三种方式从host接收firmware image：

1. 把image数据全读进一个buffer, 在下一阶段Manifestation phase中执行真正的programming

2. erase一块memory，把image写进去

3. 方法2的变种，erase一大块memory，然后分次把image block传进去，这是用于要写的内存大于buffer size的情况。

### 6.1.1 DFU_DNLOAD

每次最大的传输长度为functional descriptor的**wTransferSize**域。

host一次control-write transfer传输长度位于**bMaxPacketSize0** and **wTransferSize** bytes。

当最后一个block传输完成，host还会发送一次DFU_DNLOAD，其中*wLength*为0。

### 6.1.2 DFU_GETSTATUS

host发送DFU_GETSTATUS，device返回

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230803095303.png)

其中，

bStatus：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230803095636.png)

bState：

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230803095751.png)

### 6.1.3 DFU_CLRSTATUS

清除dfuERROR状态，进入dfuIDLE

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230803095539.png)

### 6.1.4 DFU_ABORT

强行进入dfuIDLE状态

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230803095811.png)

### 6.1.5 DFU_GETSTATE

相当于只返回DFU_GETSTATUS中的bState域

## 6.2 Uploading

### 6.2.1 DFU_UPLOAD

# 7. Manifestation Phase

# A. Interface State Summary

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230803101116.png)

## B. DFU File Suffix

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230803101542.png)