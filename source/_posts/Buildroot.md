---
title: Buildroot
date: 2023-04-13 17:39:28
tags:
- Buildroot
categories:
- Notes
---

`./lanuch` 最终的操作是

```shell
cd sdk_3921/buildroot-dist # 进入buildroot目录
make BR2_EXTERNAL=sdk_3921/platform/ O=sdk3921/out/rts3923_fpga/ rts3923_fpga_defconfig
```

## Managing the build andthe configuration

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



If you remove a package from the configuration, and run make:
Nothing happens. The files installed by this package are not removed from the target filesystem. 需要重新rebuild all
