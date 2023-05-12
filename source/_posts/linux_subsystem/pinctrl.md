---
title: Pinctrl subsystem
date: 2023-05-10 09:26:47
tags:
- Linux driver
categories:
- Notes
---

```c
devm_pinctrl_get(struct device *dev) //返回一个pinctrl句柄
	pinctrl_get(struct device *dev)
		find_pinctrl(struct device *dev) // 查看是否device core已经创建了该pinctrl句柄
		create_pinctrl(struct device *dev, struct pinctrl_dev *pctldev)
			pinctrl_dt_to_map(struct pinctrl *p, struct pinctrl_dev *pctldev) //从设备树中获取信息保存到pinctrl_map结构体中
				for (state = 0; ; state++) {
					propname = kasprintf(GFP_KERNEL, "pinctrl-%d", state); //查找pinctrl-0,1,2属性
                    //size保存了pinctrl-0中phandle的个数，比如有的节点pinctrl-0 = <&x1, &x2>
					prop = of_find_property(np, propname, &size);
					list = prop->value; //list保存了phandle列表
                    //保存pinctrl-names index为state的name,比如pinctrl-names = "default"
					ret = of_property_read_string_index(np, "pinctrl-names", state, &statename);
					if (ret < 0)
                        // 如果没有定义pinctrl-names属性，那么我们将pinctrl-0 pinctrl-1 pinctrl-2……中的那个ID取出来作为state name
						statename = prop->name + strlen("pinctrl-");
					for (config = 0; config < size; config++) {
						phandle = be32_to_cpup(list++);
						np_config = of_find_node_by_phandle(phandle); // 找到pinctrl-x=<&x1, &x2>中的config节点
						dt_to_map_one_config(p, pctldev, statename, np_config);
							np_pctldev = of_node_get(np_config);
							np_pctldev = of_get_next_parent(np_pctldev); // 找到pinctrl controller节点
							pctldev = get_pinctrl_dev_from_of_node(np_pctldev); //找到pinctrl_dev
                        	//调用底层的callback函数处理pin configuration node。
							ops->dt_node_to_map(pctldev, np_config, &map, &num_maps);
								.dt_node_to_map = pinconf_generic_dt_node_to_map_all //rts pinctrl 用的框架通用函数
										pinconf_generic_dt_node_to_map()
											ret = pinconf_generic_dt_subnode_to_map();
											for_each_available_child_of_node(np_config, np)
                                                //rts pinctrl每一个config节点下都有子节点 逐个分析子节点
												ret = pinconf_generic_dt_subnode_to_map();
											pinconf_generic_parse_dt_config(np, pctldev, &configs, &num_configs);
                        	//将该pin configuration node的mapping entry信息注册到系统中
							dt_remember_or_free_map(p, statename, pctldev, map, num_maps);
					}
				}
			add_setting(p, pctldev, map); // 将pinctrl_map信息传递给pinctrl_mapping, 把这个setting的代码加入到holder中
				setting->type = map->type;
				setting->pctldev = get_pinctrl_dev_from_devname(map->ctrl_dev_name);
				setting->dev_name = map->dev_name;
				pinmux_map_to_setting(map, setting);
				pinconf_map_to_setting(map, setting);
```

```c
pinctrl_lookup_state(struct pinctrl *p, const char *name)
	find_state(p, name);
```

```c
pinctrl_select_state()
	pinctrl_commit_state(p, state);
		case PIN_MAP_TYPE_MUX_GROUP:
			pinmux_enable_setting(setting);
				ops->set_mux(pctldev, setting->data.mux.func, setting->data.mux.group);
		case PIN_MAP_TYPE_CONFIGS_PIN:
		case PIN_MAP_TYPE_CONFIGS_GROUP:
			pinconf_apply_setting(setting);
				switch (setting->type)
					ops->pin_config_set()
					ops->pin_config_group_set()
```



统一驱动设备模型会处理pin control：

```c
platform_driver_register()
	driver_register();
		bus_add_driver();
			driver_attach();
				__driver_attach();
					device_driver_attach(drv, dev);
						driver_probe_device(drv, dev);
							really_probe(dev, drv);

	really_probe(struct device *dev, struct device_driver *drv)
		pinctrl_bind_pins(dev);
			devm_pinctrl_get(dev);
				pinctrl_lookup_state(dev->pins->p, PINCTRL_STATE_DEFAULT);
				pinctrl_lookup_state(dev->pins->p, PINCTRL_STATE_INIT);
				pinctrl_select_state(dev->pins->p, dev->pins->default_state);
```
