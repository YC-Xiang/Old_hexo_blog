---
title: 电源管理
date: 2022-4-26 10:19:00
tags:
- Legacy
categories:
- Legacy
---

**This article is out of date and need to rewrite.**



http://www.wowotech.net/pm_subsystem/suspend_and_resume.html

Linux内核提供了三种Suspend: Freeze、Standby和STR(Suspend to RAM)，在用户空间向”/sys/power/state”文件分别写入”freeze”、”standby”和”mem”，即可触发它们。

```shell
echo "freeze" > /sys/power/state

echo "standby" > /sys/power/state

echo "mem" > /sys/power/state
```

参考文章：

https://www.cnblogs.com/arnoldlu/p/6253665.html



**系统睡眠模型**

- On                                                           S0 - working
- Standby                                                   S1 - CPU and RAM are powered but not executed
- Suspend to RAM                                     S3 - RAM is powered and the running content is saved to RAM
- Suspend to Disk , Hibernation(disk)       S4 - All content is saved to Disk and power down   嵌入式系统中一般没有

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609175345.png)

**Runtime电源管理模型**

在运行状态下如何省电

**Linux系统Suspend的实现**

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230609175729.png)

```c
启动 suspend to ram：

echo mem > sys/power/state

state_store (kernel/power/main.c)
pm_suspend (kernel/power/suspend.c)
enter_state (kernel/power/suspend.c)
suspend_prepare (kernel/power/suspend.c)
pm_prepare_console(kernel/power/console.c) // 将当前console切换到一个虚拟console并重定向内核的kmsg

__pm_notifier_call_chain (kernel/power/main.c) // 通知所有关系“休眠消息”的驱动程序
suspend_freeze_processes (kernel/power/power.h) // 冻结app和内核线程
suspend_devices_and_enter (kernel/power/suspend.c) // 让设备进入休眠状态
suspend_ops->begin 如果平台相关的代码有begin函数则调用它 ，**arm/arch/mach-realtek/pm.c**

suspend_console (kernel/power/suspend.c)

dpm_suspend_start (PMSG_SUSPEND) (drivers/base/power/main.c)
dpm_prepare(state) (drivers/base/power/main.c) 对于dmp_list链表中的每一个设备，都调用device_prepare(dev, state);

对于该设备调用它的dev→pm_domain→ops.prepare      或
                            dev→type→pm→prepare                或
                      dev→class→pm→prepare                或
                      dev→bus→pm→prepare                  或
                      dev→driver→pm→prepare               

dpm_suspend(state) (drivers/base/power/main.c) 让各类设备休眠，对于dpm_prepare_list链表中的每一个设备，都调用device_suspend(dev)

__device_suspend(dev, pm_transition, false) 

对于该设备，调用它的dev→pm_domain→ops.suspend 或
                         dev→type→pm→suspend           或
                         dev→class→pm→suspend           或
                         dev→bus→pm→suspend             或
                         dev→driver→pm→suspend

suspend_enter(state, &wakeup) (kernel/power/suspend.c)

suspend_ops→prepare

dpm_suspend_late(state) (drivers/base/power/main.c) 对于dpm_suspend_list链表中的每一个设备，都调用device_suspend_late(dev, state)

对于该设备，调用它的dev→pm_domain→ops.suspend_late 或
                               dev→type→pm→suspend_late           或
                         dev→class→pm→suspend_late           或
                         dev→bus→pm→suspend_late             或
                         dev→driver→pm→suspend_late

suspend_ops→prepare_late()
disable_nonboot_cpus()
arch_suspend_disable_irqs()
syscore_suspend()
suspend_ops→enter(state) 
power_attr(state);

#define power_attr(_name) \
static struct kobj_attribute _name##_attr = {	\
.attr	= {				\
.name = __stringify(_name),	\
.mode = 0644,			\
},					\
.show	= _name##_show,			\
.store	= _name##_store,		\
}
```

# **给驱动程序添加电源管理功能**

## 1. 通知notifier

在冻结APP之前，使用pm_notifier_call_chain(PM_SUSPEND_PREPARE)来通知驱动程序

在重启APP后，使用pm_notifier_call_chain(PM_POST_SUSPEND)来通知驱动程序

如果驱动程序有事情在上述时机要处理，可以使用register_pm_notifier注册一个notifier

## 添加suspend、resume函数（常用）

在platform_driver中可以定义.suspend、.resume两个函数（老方法）

```c
// pinctrl-rts3917.c

static struct platform_driver rts_pinctrl_driver = {
	.probe = rts_pinctrl_probe,
	.remove = rts_pinctrl_remove,
	.suspend = rts_pinctrl_suspend,
	.resume = rts_pinctrl_resume,
	.driver = {
		   .name = "pinctrl_rts3917",
		   .owner = THIS_MODULE,
		   .of_match_table = rts_pinctrl_match,
		   },
};
```

新的内核推荐在driver中定义一个.pm结构体，在其中实现suspend、resume，比如：

```c
static struct dev_pm_ops xxx = 
{
							.suspend = rts_pinctrl_suspend,
							.resume = rts_pinctrl_resume,
}

static struct platform_driver rts_pinctrl_driver = {
	.probe = rts_pinctrl_probe,
	.remove = rts_pinctrl_remove,
	.driver = {
		   .name = "pinctrl_rts3917",
		   .owner = THIS_MODULE,
		   .of_match_table = rts_pinctrl_match,
			 .pm = &xxx,
		   },
};
```

# Runtime PM

runtime PM 提供辅助函数：

1. 增加计数/减少计数
2. 使能runtime PM

内核驱动示例driver/dma/rts_dmac.c

修改驱动程序和使用：

1. 在dev_pm_ops中提供3个回调函数：runtime_suspend, runtime_resume, runtime_idle
2. 在对应的系统调用接口里调用：

probe函数中：pm_runtime_enable(&pdev->dev); 使能Runtime PM 修改power.disable_depth变量

remove函数中：pm_runtime_disable(&pdev->dev); 禁止Runtime PM 修改power.disable_depth变量

pm_runtime_get_sync(&pdev->dev);  增加计数值

pm_runtime_put_sync(&pdev->dev); 减小计数值

如何使用runtime PM：

1. echo on > /sys/devices/.../power/control  // 导致control_store->pm_runtime_forbid(dev);

   ```
                                                                                  atomic_inc(&dev->power.usage_count);
   
                                                                                  rpm_resume(dev, 0);
   
   echo auto > /sys/devices/.../power/control // 导致control_store->pm_runtime_allow(dev);
   
                                                                                    atomic_dec_and_test(&dev->power.usage_count);
   
                                                                                    rpm_idle(dev, RPM_AUTO | RPM_ASYNC);
   ```

2. 在对应的系统调用接口里调用：pm_runtime_get_sync / pm_runtime_put_sync

3. autosuspend: 如果不想让设备频繁开关，可以使用autosuspend功能

   驱动里：执行pm_runtime_use_autosuspend来设置启动autosuspend功能

   ```
          put设备时，执行这两个函数：
   
    pm_runtime_mark_last_busy();
   
    pm_runtime_put_sync_autosuspend();
   ```

   用户空间：执行echo 秒数 > /sys/devices/xxx/power/autosuspend_delay_ms

   

**流程分析：**

```c
pm_runtime_get_sync(include/linux/pm_runtime.h)
__pm_runtime_resume(dev, RPM_GET_PUT) (drivers/base/runtime.c)
atomic_inc(&dev->power.usage_count);  // 增加使用计数
rpm_resume(dev, rpmflags); // resume 设备
if (dev->power.disable_depth > 0)  // 该变量初始值为1，要使用runtime PM，要先enable
retval = -EACCES;
if (!dev->power.timer_autosuspends) // 为防止设备频繁地开关，可以设置autosuspends的值
pm_runtime_deactivate_timer(dev);
if (dev->power.runtime_status == RPM_ACTIVE) {  // 如果设备已经是RPM_ACTIVE 就不用resume 直接返回

// 如果设备处于RPM_RESUMING或RPM_SUSPENDING，等待该操作完成
//Increment the parent's usage counter and resume it is necessary
//resume设备本身，前面4个函数被称为subsystem-level callback

callback = RPM_GET_CALLBACK(dev, runtime_resume);

ops = &dev->pm_domain->ops->runtime_resume; 或
ops = dev->type->pm->runtime_resume;                 或
ops = dev->class->pm->runtime_resume;                或
ops = dev->bus->pm->runtime_resume;                  或

如果都没定义，则调用我们在驱动中定义的函数

dev->driver->pm->runtime_resume

// 成功时，给父亲的child_count加1

if (parent)
atomic_inc(&parent->power.child_count);

// 唤醒其他进程

wake_up_all(&dev->power.wait_queue);

// 如果resume失败，让设备进入idle状态

if (retval >= 0)
rpm_idle(dev, RPM_ASYNC);

pm_runtime_put_sync

__pm_runtime_idle(dev, RPM_GET_PUT)

atomic_dec_and_test(&dev->power.usage_count) // 减小使用计数
rpm_idle(dev, rpmflags)                                           // 让设备进入idle状态
rpm_check_suspend_allowed(dev);                     // 检查是否允许设备进入suspend状态 
if (dev->power.disable_depth > 0)                // 失败
if (atomic_read(&dev->power.usage_count) > 0) // 当前的使用计数不是0也失败
if (!dev->power.ignore_children &&
atomic_read(&dev->power.child_count))        // 如果有子设备没suspend也失败
if (dev->power.runtime_status != RPM_ACTIVE)      // 如果设备不是RPM_ACTIVE状态，直接返回也不用suspend了

callback = RPM_GET_CALLBACK(dev, runtime_idle);

ops = &dev->pm_domain->ops->runtime_idle; 或
ops = dev->type->pm->runtime_idle;                 或
ops = dev->class->pm->runtime_idle;                或
ops = dev->bus->pm->runtime_idle;                  或

如果都没定义，则调用我们在驱动中定义的函数

dev->driver->pm->runtime_idle

__rpm_callback(callback, dev);

wake_up_all(&dev->power.wait_queue);

如果设备不提供runtime_idle，则最终会调用runtime_suspend
```

