---
title: linux usb driver
date: 2023-06-15 17:39:28
tags:
- usb
categories:
- usb
---



# USB function driver

f_loopback.c

# USB composite driver

zero.c usb_composite_driver

```c
struct usb_composite_driver {
	const char				*name; // "zero"
	const struct usb_device_descriptor	*dev; // device_desc
	struct usb_gadget_strings		**strings; // dev_strings
	enum usb_device_speed			max_speed; // USB_SPEED_SUPER
	unsigned		needs_serial:1;

	int			(*bind)(struct usb_composite_dev *cdev); // zero_bind
	int			(*unbind)(struct usb_composite_dev *); // zero_unbind

	void			(*disconnect)(struct usb_composite_dev *);

	/* global suspend hooks */
	void			(*suspend)(struct usb_composite_dev *); // zero_suspend
	void			(*resume)(struct usb_composite_dev *); // zero_resume
	struct usb_gadget_driver		gadget_driver; // composite_driver_template
};
```

提供usb_configuration usb_device_descriptor

创建usb_composite_dev

```c
usb_add_gadget_udc();


// 上层usb device driver, 模拟各种usb设备
module_usb_composite_driver();
    usb_composite_probe(); // composite.c
        usb_gadget_probe_driver(); //gadget/udc/core.c
            udc_bind_to_driver();
				driver->bind(); // 调用到composite.c 的.bind = composite_bind
					composite_bind();
						composite->bind(); //调用到zero.c 的.bind = zero_bind
                usb_gadget_udc_start();
                    udc->gadget->ops->udc_start();
                        rts_gadget_udc_start();

```



# USB gadget driver

composite.c

struct usb_gadget_driver

```c
struct usb_gadget_driver {
	char			*function; // "zero"
	enum usb_device_speed	max_speed; // USB_SPEED_SUPER
	int			(*bind)(struct usb_gadget *gadget, // composite_driver_template
					struct usb_gadget_driver *driver);
	void			(*unbind)(struct usb_gadget *);
	int			(*setup)(struct usb_gadget *,
					const struct usb_ctrlrequest *);
	void			(*disconnect)(struct usb_gadget *);
	void			(*suspend)(struct usb_gadget *);
	void			(*resume)(struct usb_gadget *);
	void			(*reset)(struct usb_gadget *);
	int			(*filteroutdata)(struct usb_gadget *,
					const struct usb_ctrlrequest *,
					u8 *, int);

	/* FIXME support safe rmmod */
	struct device_driver	driver; // driver->name = "zero"

	char			*udc_name;
	struct list_head	pending;
	unsigned                match_existing_only:1;
};
```



# UDC driver

设置struct usb_gadget

usb_add_gadget_udc 会创建一个usb_udc结构体

```c
struct usb_udc {
	struct usb_gadget_driver	*driver; // composite_driver_template
	struct usb_gadget		*gadget; // rtsusb->gadget
	struct device			dev;
	struct list_head		list;
	bool				vbus; // true
};
```

```c
struct usb_gadget {
	struct work_struct		work; // usb_gadget_state_work
	struct usb_udc			*udc; // udc
	/* readonly to gadget driver */
	const struct usb_gadget_ops	*ops; // rts_gadget_ops
	struct usb_ep			*ep0;
	struct list_head		ep_list; // eps链表
	enum usb_device_speed		speed; // USB_SPEED_UNKNOWN
	enum usb_device_speed		max_speed; // USB_SPEED_HIGH
	enum usb_device_state		state; // USB_STATE_NOTATTACHED
	const char			*name; // "rts_gadget"
	struct device			dev; // dev.driver = &gadget_driver->driver;
    							// dev.parent = dev;
	unsigned			isoch_delay;
	unsigned			out_epnum;
	unsigned			in_epnum;
	unsigned			mA;
	struct usb_otg_caps		*otg_caps;

	unsigned			sg_supported:1;
	unsigned			is_otg:1;
	unsigned			is_a_peripheral:1;
	unsigned			b_hnp_enable:1;
	unsigned			a_hnp_support:1;
	unsigned			a_alt_hnp_support:1;
	unsigned			hnp_polling_support:1;
	unsigned			host_request_flag:1;
	unsigned			quirk_ep_out_aligned_size:1;
	unsigned			quirk_altset_not_supp:1;
	unsigned			quirk_stall_not_supp:1;
	unsigned			quirk_zlp_not_supp:1;
	unsigned			quirk_avoids_skb_reserve:1;
	unsigned			is_selfpowered:1;
	unsigned			deactivated:1;
	unsigned			connected:1;
	unsigned			lpm_capable:1;
	int				irq;
};
```



```c
// rts_usb_driver_probe
rtsusb->gadget.ops = &rts_gadget_ops;
rtsusb->gadget.name = "rts_gadget";
rtsusb->gadget.max_speed = USB_SPEED_HIGH;
rtsusb->gadget.dev.parent = dev;
rtsusb->gadget.speed = USB_SPEED_UNKNOWN;

rts_gadget_init_endpoints(); // 初始化endpoints
rts_usb_init(rtsusb); // 写一些寄存器
usb_add_gadget_udc(dev, &rtsusb->gadget); // 注册udc
```



```c
rts_usb_common_irq();
	rts_usb_ep_irq();
		rts_usb_se0_irq(); /// root port reset irq
			usb_gadget_udc_reset();
				driver->reset(); /// 进入composite.c中composite_driver_template .reset
		rts_usb_ep0_irq();
		rts_usb_intrep_irq();
		rts_usb_bulkinep_irq();
		rts_usb_bulkoutep_irq();
		rts_usb_uacinep_irq();
		rts_usb_uacoutep_irq();
		rts_usb_uvcinep_irq();
    
```



```c
// setup irq
rts_usb_ep0_irq();
	usb_read_reg(USB_EP0_SETUP_DATA0) & 0xff;
	//... 读setup事务的data
	rts_usb_setup_process();
		rts_usb_ep0_standard_request();
			rts_usb_req_ep0_get_status();
				rts_ep_queue();
					rts_ep0_queue();	
						rts_start_ep0_transfer();
			rts_usb_req_ep0_clear_feature();
			rts_usb_req_ep0_set_feature();
			rts_usb_req_ep0_set_address();
			rts_usb_req_ep0_set_configuration();
```



```c
rts_usb_intrep_irq();
	rts_usb_intr_in_process();
		rts_intr_transfer_process();
```



