---



---



# USB function driver

f_loopback.c

# USB composite driver

zero.c

```c
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



# UDC driver

设置usb_gadget

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



