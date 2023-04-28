---
layout:     post   				    
title:      Buildroot学习记录
subtitle:   
date:       2021-12-29 				
author:     YC-Xiang 						
header-img:  	img/post-bg-universe.jpg
catalog: true 						
tags:								
    - Buildroot
---

> Buildroot是一个高度可定制的嵌入式Linux镜像构建工具。

## Buildroot 目录结构

- arch: CPU架构相关的配置脚本
- board: 在构建系统时，board默认的boot和Linux kernel配置文件，以及一些板级相关脚本
- boot: uboot配置脚本目录
- configs: 板级配置文件，该目录下的配置文件记录着该机器平台或者方案使用的工具链，boot， kernel，各种应用软件包的配置
- dl: download的简写，下载一些开源包。第一次下载后，下次就不会再去从官网下载了，而是从dl/目录下拿开源包，以节约时间
- docs:
- fs: 各种文件系统的自动构建脚本
- linux: 存放Linux kernel的自动构建脚本
- package: 第三方开源包的自动编译构建脚本，用来配置编译dl目录下载的开源包
- support:
- system: 存放文件系统目录的和设备节点的模板，这些模板会被拷贝到output/目录下，用于制作根文件系统rootfs
- toolchain/ 目录中存放着各种制作工具链的脚本

## 编译出的output输出目录
- images: 存储所有映像（内核映像，引导加载程序和根文件系统映像）的位置。这些是您需要放在目标系统上的文件。
- build/: 构建所有组件的位置（包括主机上Buildroot所需的工具和针对目标编译的软件包）。该目录为每个组件包含一个子目录。
- host/: 包含为主机构建的工具和目标工具链。
- staging/: 是到内部目标工具链host/的符号链接
- target/: 它几乎包含了目标的完整根文件系统。除了设备文件/dev/（Buildroot无法创建它们，因为Buildroot不能以root身份运行并且不想以root身份运行）之外，所需的一切都存在。

## Buildroot 常用make命令
- make help
- make menuconfig: 图形化配置
- make uboot-menuconfig
- make linux-menuconfig
- make savedefconfig: 保存配置到xxx_defconfig中<br/><br/>
- make clean: 删除编译文件
- make distclean: 等于make clean + 删除配置, 可以针对某一软件包make \<pkg\> disclean(这里要用disclean)
- make show-targets: 显示本次配置编译的目标
- make \<pkg\>-target: 单独编译某个pkg
- make \<pkg\>-rebuild: 重新编译pkg
- make \<pkg\>-extract: 只下载解压pkg,不编译，pkg解压后放在output/build/对应的pkg目录下
- make \<pkg\>-source: 只下载某pkg，然后不做任何事情

## 添加自己的软件包

### 添加package/Config.in入口

```kufds
config BR2_PACKAGE_HELLOWORLD
bool "helloworld"
help
  This is a demo to add myown(fuzidage) package.
```

### 配置APP对应的Config.in和mk文件
在package中新增目录helloworld，并在里面添加Config.in和helloworld.mk
**Config.in**
```fdsf
config BR2_PACKAGE_HELLOWORLD
bool "helloworld"
help
  This is a demo to add myown(fuzidage) package.
```

**helloworld.mk**
```dfsdf
HELLOWORLD_VERSION:= 1.0.0
HELLOWORLD_SITE:= $(BR2_EXTERNAL)/source/ipcam/helloworld
HELLOWORLD_SITE_METHOD:=local
HELLOWORLD_INSTALL_TARGET:=YES

$(eval $(cmake-package))

```

### 编写APP源码和Makefile

### 通过make menuconfig选中APP

### 编译使用APP
可以和整个平台一起编译，或者`make helloworld`单独编译。

这两个文件在选中此APP之后，都会被拷贝到`output/build/helloworld-1.0.0`文件夹中。

生成的bin文件被拷贝到`output/target/bin/helloworld`

## 如何重新编译软件包

经过第一次完整编译后，如果我们需要对源码包重新配置，我们不能直接在buildroot上的根目录下直接make，buildroot是不知道你已经对源码进行重新配置，它只会将第一次编译出来的文件，再次打包成根文件系统镜像文件。

那么可以通过以下2种方式重新编译：

**1. 直接删除源码包,然后make all**

例如我们要重新编译helloworld，那么可以直接删除output/build/helloworld目录，那么当你make的时候，就会自动从dl文件夹下，解压缩源码包，并重新安装。这种效率偏低

**2. 进行xxx-rebuild,然后make all**

也是以helloworld为例子，我们直接输入make helloworld-rebuild，即可对build/helloworld/目录进行重新编译，然后还要进行make all(或者make helloworld)

## Config.in 语法
用Kconfig语言编写，用来配置packages

必须以`BR2_PACKAGE_<PACKAGE>`开头

![](https://tva1.sinaimg.cn/large/008i3skNgy1gxwbwcmsauj30i303zt8t.jpg)

Config.in 是层级结构`package/<pkg>/Config.in`都被包含在`package/Config.in`

### menu/endmenu
menuconfig中层级目录由`menu`来嵌套定义
```kbuild
menu "Base System"
source "$BR2_EXTERNAL_platform_PATH/package/example/Config.in"
source "$BR2_EXTERNAL_platform_PATH/package/fstools/Config.in"
endmenu

menu "Test Package"
source "$BR2_EXTERNAL_platform_PATH/package/foobar/Config.in"
endmenu

// Test Package在Base System下一级目录
menu "Base System"
menu "Test Package"
endmenu
endmenu
```
### if/endif

### choice/endchoice    

### select、depends on
select是一种自动依赖，如果A select B，只要A被enable，B就会被enable，而且不可unselected

depends on是一种用户定义的依赖，如果A depends on B, A只有在B被enable后才可见

- `make \<pkg\>-show-depend`: 查看pkg依赖的包
- `make \<pkg\>-show-rdepend`: 查看依赖pkg的包

## .mk文件
```
xxx_SITE_METHOD = local
xxx_SITE = 本地源码库地址

xxx_SITE_METHOD = remote
xxx_SITE = 远程URL
```

Packages可以被安装到不同目录：

- target目录：`$(TARGET_DIR)`
- staging目录：`$(STAGING_DIR)`
- images目录：`$(BINARIES_DIR)`

分别由三个变量决定：
- `<pkg>_INSTALL_TARGET` , defaults to `YES`. If `YES`, then `<pkg>_INSTALL_TARGET_CMDS` will be called 
- `<pkg>_INSTALL_STAGING` , defaults to `NO`. If `YES`, then `<pkg>_INSTALL_STAGING_CMDS` will be called 
- `<pkg>_INSTALL_IMAGES` , defaults to `NO`. If `YES`, then `<pkg>_INSTALL_IMAGES_CMDS` will be called <br/><br/>

- Application Package一般只要安装到target
- Shared library动态库必须安装到target与staging
- header-based library和static-only library静态库只安装到staging
- bootloader和linux要安装到images

Config.in文件不规定编译顺序，.mk文件中的\<pkg\>_DEPENDENCIES可以规定编译顺序，\<pkg\>_DEPENDENCIES后面的软件包先编译。

![](https://tva1.sinaimg.cn/large/008i3skNgy1gxwbwv9a45j30gq03ydg1.jpg)

## 参考
- [https://www.cnblogs.com/fuzidage/p/12049442.html](https://www.cnblogs.com/fuzidage/p/12049442.html)
<a href="1.png" download>图片1</a>