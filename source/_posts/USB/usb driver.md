---



---

`

```c
// rts3917 endpoints

	/*
	 * ep0 - CONTROL
	 *
	 * ep1in - BULK IN
	 * ep2in - BULK IN
	 * ep3in - BULK IN
	 * ep4in - UAC ISO IN
	 * ep5in - UVC ISO IN
	 * ep6in - UVC ISO IN
	 * ep7in - INTERRUPT IN
	 * ep8in - INTERRUPT IN
	 * ep9in - INTERRUPT IN
	 * ep10in - INTERRUPT IN
	 * ep11in - INTERRUPT IN
	 * ep12in - INTERRUPT IN
	 *
	 * ep1out - BULK OUT
	 * ep2out - BULK OUT
	 * ep3out - BULK OUT
	 * ep4out - UAC ISO OUT
	 */
```



```c
// 上层usb device driver, 模拟各种usb设备
usb_composite_probe(); //或者利用封装的module_usb_composite_driver
	usb_gadget_probe_driver();
		udc_bind_to_driver();
			usb_gadget_udc_start();
				udc->gadget->ops->udc_start();
					rts_gadget_udc_start();

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



