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

mac环境
# Homebrew下载源修改:
```shell
# 替换brew.git:
$ cd "$(brew --repo)"
# 中国科大:
$ git remote set-url origin https://mirrors.ustc.edu.cn/brew.git

# 替换homebrew-core.git:
$ cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
# 中国科大:
$ git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git

# 替换homebrew-bottles:
# 中国科大:
$ echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles' >> ~/.zshrc
$ source ~/.zshrc

# 应用生效:
$ brew update
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