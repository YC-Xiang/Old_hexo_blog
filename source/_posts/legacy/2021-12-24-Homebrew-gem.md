---
layout:     post   				    # 使用的布局（不需要改）
title:      mac Homebrew和gem下载源修改 				# 标题
subtitle:    #副标题
date:       2021-12-24 				# 时间
author:     YC-Xiang 						# 作者
header-img:  	#这篇文章标题背景图片
catalog: true 						# 是否归档
tags:								#标签
    - Legacy
categories:
- Legacy
---

## Homebrew下载源修改

https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/

```shell
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
```

# Gem下载源修改：
```shell
# 移除gem默认源，改成ruby-china源
$ gem sources -r https://rubygems.org/ -a https://gems.ruby-china.com/
# 使用Gemfile和Bundle的项目，可以做下面修改，就不用修改Gemfile的source
$ bundle config mirror.https://rubygems.org https://gems.ruby-china.com
# 删除Bundle的一个镜像源
$ bundle config --delete 'mirror.https://rubygems.org'
```
