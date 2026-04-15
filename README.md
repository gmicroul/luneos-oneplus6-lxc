# LuneOS for OnePlus 6 with LXC Support

为 OnePlus 6 (enchilada) 定制的 LuneOS 系统，包含完整的 LXC 容器支持。

## 特性

- ✅ 基于 LuneOS 最新版本
- ✅ 完整的 LXC 容器支持
- ✅ 一加6硬件完全驱动
- ✅ Docker替代方案（更适合移动设备）
- ✅ 开源构建，可自定义

## 硬件要求

- OnePlus 6 (enchilada)
- 解锁的 bootloader
- 至少 2GB 可用存储空间
- USB数据线

## 快速开始

### 1. 下载刷机包

从 [Releases](https://github.com/[你的用户名]/luneos-oneplus6-lxc/releases) 页面下载最新镜像：

```bash
# 最新稳定版
wget https://github.com/[你的用户名]/luneos-oneplus6-lxc/releases/download/v1.0/luneos-oneplus6-lxc-v1.0.zip
```

### 2. 刷机步骤

```bash
# 进入fastboot模式
adb reboot bootloader

# 刷入系统
fastboot flash boot boot.img
fastboot flash system system.img
fastboot flash vendor vendor.img

# 重启设备
fastboot reboot
```

### 3. 验证LXC功能

首次启动后，在终端中运行：

```bash
# 检查LXC安装
lxc-ls --fancy

# 创建测试容器
lxc-create -t busybox -n test-container
lxc-start -n test-container
```

## 构建指南

如果你想自定义构建，请参考 [BUILD.md](BUILD.md)。

## 问题反馈

遇到问题请提交 [Issue](https://github.com/[你的用户名]/luneos-oneplus6-lxc/issues)。

## 许可证

本项目基于 [GPL-3.0](LICENSE) 许可证。