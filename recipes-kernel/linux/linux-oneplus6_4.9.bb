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