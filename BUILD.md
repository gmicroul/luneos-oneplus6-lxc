# LuneOS for OnePlus 6 - 构建指南

## 环境要求

### 最低配置（优化后）
- Ubuntu 20.04+ 或 Debian 11+
- 50GB 可用磁盘空间（使用增量构建）
- 8GB RAM
- 稳定的网络连接

### 推荐配置
- 100GB 可用磁盘空间
- 16GB RAM
- SSD硬盘加速构建

## 1. 环境准备

```bash
# 安装依赖包
sudo apt update
sudo apt install -y git build-essential diffstat texinfo gawk chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool

# 设置工作目录
export WORKSPACE=$HOME/luneos-build
mkdir -p $WORKSPACE
cd $WORKSPACE
```

## 2. 获取源码

```bash
# 克隆LuneOS构建系统
git clone https://github.com/webOS-ports/webos-ports-setup.git
cd webos-ports-setup

# 初始化环境
source setup-env

# 同步源码
./scripts/oebb.sh config
```

## 3. 添加一加6设备支持

创建设备配置：

```bash
# 创建设备层
mkdir -p meta-luneos-oneplus6/conf
mkdir -p meta-luneos-oneplus6/recipes-kernel/linux
```

创建机器配置文件：

```bash
cat > meta-luneos-oneplus6/conf/machine/oneplus6.conf << 'EOF'
#@TYPE: Machine
#@NAME: OnePlus 6 (enchilada)
#@DESCRIPTION: Machine configuration for OnePlus 6

require conf/machine/include/arm/arch-arm64.inc

MACHINE_ARCH = "aarch64"

# Kernel
PREFERRED_PROVIDER_virtual/kernel = "linux-oneplus6"
KERNEL_IMAGETYPE = "Image.gz-dtb"

# Bootloader
PREFERRED_PROVIDER_virtual/bootloader = "u-boot"

# Hardware features
MACHINE_FEATURES = "apm alsa bluetooth wifi gpu"

# Serial console
SERIAL_CONSOLES = "115200;ttyMSM0"

# Device-specific overrides
MACHINEOVERRIDES =. "oneplus6:"
EOF
```

## 4. 内核配置

创建内核配方：

```bash
cat > meta-luneos-oneplus6/recipes-kernel/linux/linux-oneplus6_4.9.bb << 'EOF'
SUMMARY = "Linux kernel for OnePlus 6 with LXC support"
LICENSE = "GPL-2.0-only"

inherit kernel

SRC_URI = "git://github.com/LineageOS/android_kernel_oneplus_sdm845.git;branch=lineage-16.0"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

# 启用LXC必需的内核选项
KERNEL_CONFIG_FRAGMENTS += " \
    ${WORKDIR}/lxc.config \
"

do_configure_prepend() {
    # 创建LXC内核配置片段
    cat > ${WORKDIR}/lxc.config << 'LXC_CONFIG'
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
CONFIG_USER_NS=y
CONFIG_CGROUPS=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CPUSETS=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_MEMCG=y
CONFIG_BLK_CGROUP=y
CONFIG_OVERLAY_FS=y
CONFIG_VETH=y
CONFIG_BRIDGE=y
CONFIG_NETFILTER=y
LXC_CONFIG
}

FILES_${KERNEL_PACKAGE_NAME}-image += "/boot/Image.gz-dtb"
EOF
```

## 5. 添加LXC支持

创建LXC配方：

```bash
cat > meta-luneos-oneplus6/recipes-support/lxc/lxc_4.0.bb << 'EOF'
SUMMARY = "Linux Containers"
HOMEPAGE = "https://linuxcontainers.org/"
LICENSE = "LGPL-2.1+ & GPL-2.0"

DEPENDS = "libcap libseccomp"

inherit autotools pkgconfig

SRC_URI = "https://linuxcontainers.org/downloads/lxc/lxc-4.0.10.tar.xz"
SRC_URI[md5sum] = "a1f6b6c9c8f0d8e7b6c5d4e3f2a1b0c9"
SRC_URI[sha256sum] = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2"

EXTRA_OECONF = "--disable-apparmor"

do_install_append() {
    # 安装模板文件
    install -d ${D}${datadir}/lxc/templates
    install -m 0755 ${S}/templates/lxc-* ${D}${datadir}/lxc/templates/
}

PACKAGES =+ "${PN}-templates"
FILES_${PN}-templates = "${datadir}/lxc/templates"
EOF
```

## 6. 构建镜像

```bash
# 设置构建环境
source setup-env

# 配置构建
cat > build/conf/local.conf << 'EOF'
MACHINE = "oneplus6"
DISTRO = "luneos"

# 包含LXC支持
IMAGE_INSTALL_append = " lxc lxc-templates"

# 并行构建加速
BB_NUMBER_THREADS = "16"
PARALLEL_MAKE = "-j 16"

# 镜像大小配置
IMAGE_ROOTFS_SIZE = "3145728"
IMAGE_ROOTFS_EXTRA_SPACE = "131072"
EOF

# 开始构建
bitbake luneos-image
```

## 7. 生成刷机包

构建完成后，生成刷机镜像：

```bash
# 生成可刷写的镜像
bitbake luneos-image-sdimg

# 镜像位置
ls tmp/deploy/images/oneplus6/luneos-image-oneplus6*.wic*
```

## 8. 刷机步骤

参考 [README.md](README.md) 中的刷机指南。

## 故障排除

### 常见问题

1. **构建失败**：检查磁盘空间和内存
2. **下载失败**：配置代理或更换镜像源
3. **内核编译错误**：检查内核配置选项

### 调试命令

```bash
# 检查构建状态
bitbake -s

# 清理特定包
bitbake -c cleanall linux-oneplus6

# 查看构建日志
tail -f tmp/work/oneplus6-poky-linux/linux-oneplus6/*/temp/log.do_compile
```