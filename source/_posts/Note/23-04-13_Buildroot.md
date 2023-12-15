---
title: Buildroot
date: 2023-04-13 17:39:28
tags:
- Buildroot
categories:
- Notes
---

# Notes

`./lanuch` 最终的操作是

```shell
cd sdk_3921/buildroot-dist # 进入buildroot目录
make BR2_EXTERNAL=sdk_3921/platform/ O=sdk3921/out/rts3923_fpga/ rts3923_fpga_defconfig
```



```makefile
local.mk # BR2_PACKAGE_OVERRIDE_FILE 在platform/configs中定义
external.mk
    include common.mk
    	include package/*/*/*.mk
    	include package/*/*.mk
    include package/*/*/src.mki
    include package/*/*/gen.mki
    include post_pkg.mk
```





`platform/local.mk`: 指定自定义源码位置

在`local.mk`中还定义了：

`make rr`: Reconstruct rootfs

`make rp`: Rebuild external packages



## Managing the build and the configuration

### Out of tree build

在`buildroot Makefile`中有

```makefile
ifeq ($(O),$(CURDIR)/output)
CONFIG_DIR := $(CURDIR)
NEED_WRAPPER =
else
CONFIG_DIR := $(O)
NEED_WRAPPER = y
endif
```

可以看出，如果`O != buildroot_dist/output`, `CONFIG_DIR = sdk3921/out/rts3923_fpga/ `

在`CONFIG_DIR`目录下，保存着`.config`配置文件。

### Other building tips

Cleaning all the build output, but keeping the configuration file(删除build/):

`make clean`

Cleaning everything, including the configuration file, and downloaded file if at the
default location (相当于删除了build/和.config一系列配置文件，需要重新make menuconfig):

`make distclean`

## Buildroot source and build trees

### Build tree

- `output/`对应`BASE_DIR`
- `output/build/`对应`BUILD_DIR`
- `output/host/`对应`HOST_DIR`
  - Contains both the tools built for the host (cross-compiler, etc.) and the sysroot of
    the toolchain
  - Host tools are directly in `host/`
  - The sysroot is in `host/<tuple>/sysroot/usr`E.g: `arm-unknown-linux-gnueabihf`
  - Variable for the sysroot: `STAGING_DIR`. `ouput`目录下的`staging`目录也是软连接到这的
- `output/target/`对应`TARGET_DIR`
  - Used to generate the final root filesystem images in` images/`
- `output/image/`对应`BINARIES_DIR`

## Managing the Linux kernel configuration

- `make linux-update-config`, to save a full config file
- `make linux-update-defconfig`, to save a minimal defconfig

## Root filesystem in Buildroot

copy rootfs overlays->execute post-build scripts->execute post-image scripts

`platform/board/rts3923/rootfs_overlay`

`platform/board/rts3923/post_build.sh`

`platform/board/rts3923/post_image.sh`

![](https://xyc-1316422823.cos.ap-shanghai.myqcloud.com/20230412162924.png)

## Advanced topics

### BR2_EXTERNAL

Ipcam sdk在make的时候指定

`make BR2_EXTERNAL=sdk_3921/platform/ O=sdk3921/out/rts3923_fpga/ rts3923_fpga_defconfig`

Each external directory must contain:

- `external.desc`, which provides a name and description. The `$BR2_EXTERNAL_<NAME>_PATH` variable is available, where NAME is defined in `external.desc`.
- `Config.in`, configuration options that will be included in menuconfig（在menuconfig external options里）
- `external.mk`, will be included in the make logic



`make <pkg>-dirclean`, completely remove the package source code directory. The next make invocation will fully rebuild this package. 相当于直接删除`build/<pkg>`

`make <pkg>-rebuild`, force to re-execute the build and installation steps of the package.

`make <pkg>-reconfigure`, force to re-execute the configure, build and installation steps of the package.

# legacy

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

## 参考

- [https://www.cnblogs.com/fuzidage/p/12049442.html](https://www.cnblogs.com/fuzidage/p/12049442.html)