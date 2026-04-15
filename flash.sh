#!/bin/bash
# LuneOS for OnePlus 6 - 刷机脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查ADB和Fastboot
check_tools() {
    log_info "检查ADB和Fastboot工具..."
    
    if ! command -v adb &> /dev/null; then
        log_error "未找到ADB工具，请安装Android SDK"
        exit 1
    fi
    
    if ! command -v fastboot &> /dev/null; then
        log_error "未找到Fastboot工具，请安装Android SDK"
        exit 1
    fi
    
    log_info "工具检查通过"
}

# 检查设备连接
check_device() {
    log_info "检查设备连接..."
    
    # 检查设备是否在ADB模式
    if adb devices | grep -q "device$"; then
        log_info "设备已通过ADB连接"
        return 0
    fi
    
    # 检查设备是否在Fastboot模式
    if fastboot devices | grep -q "fastboot$"; then
        log_info "设备已通过Fastboot连接"
        return 1
    fi
    
    log_error "未检测到设备连接"
    log_warn "请确保："
    log_warn "1. 已启用USB调试"
    log_warn "2. 已授权此电脑"
    log_warn "3. 使用原装数据线"
    exit 1
}

# 解锁Bootloader
unlock_bootloader() {
    log_info "检查Bootloader状态..."
    
    # 重启到Bootloader
    adb reboot bootloader
    sleep 5
    
    # 检查是否已解锁
    if fastboot getvar unlocked 2>&1 | grep -q "unlocked: yes"; then
        log_info "Bootloader已解锁"
        return 0
    fi
    
    log_warn "Bootloader未解锁，需要解锁操作"
    log_warn "警告：解锁会清除所有数据！"
    
    read -p "是否继续解锁？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "用户取消操作"
        exit 1
    fi
    
    log_info "开始解锁Bootloader..."
    fastboot oem unlock
    
    log_info "等待设备重启..."
    sleep 10
    
    # 重新进入Bootloader
    adb reboot bootloader
    sleep 5
    
    log_info "Bootloader解锁完成"
}

# 刷入LuneOS
flash_luneos() {
    local image_dir="${1:-.}"
    
    log_info "开始刷入LuneOS..."
    
    # 检查镜像文件
    if [ ! -f "$image_dir/boot.img" ]; then
        log_error "未找到boot.img文件"
        exit 1
    fi
    
    if [ ! -f "$image_dir/system.img" ]; then
        log_error "未找到system.img文件"
        exit 1
    fi
    
    # 刷入Boot分区
    log_info "刷入Boot分区..."
    fastboot flash boot "$image_dir/boot.img"
    
    # 刷入System分区
    log_info "刷入System分区..."
    fastboot flash system "$image_dir/system.img"
    
    # 刷入Vendor分区（如果有）
    if [ -f "$image_dir/vendor.img" ]; then
        log_info "刷入Vendor分区..."
        fastboot flash vendor "$image_dir/vendor.img"
    fi
    
    log_info "刷机完成"
}

# 验证LXC功能
verify_lxc() {
    log_info "等待设备启动..."
    sleep 30
    
    log_info "验证LXC功能..."
    
    # 等待ADB连接
    adb wait-for-device
    sleep 10
    
    # 检查LXC命令
    if adb shell "which lxc-ls" | grep -q "/usr/bin/lxc-ls"; then
        log_info "✓ LXC工具已安装"
    else
        log_error "✗ LXC工具未找到"
        return 1
    fi
    
    # 检查内核支持
    if adb shell "zcat /proc/config.gz | grep -q CONFIG_NAMESPACES" 2>/dev/null; then
        log_info "✓ 内核命名空间支持已启用"
    else
        log_error "✗ 内核命名空间支持未启用"
        return 1
    fi
    
    # 创建测试容器
    log_info "创建测试容器..."
    if adb shell "lxc-create -t busybox -n test-container" 2>/dev/null; then
        log_info "✓ 测试容器创建成功"
    else
        log_warn "⚠ 容器创建失败（可能需要网络下载）"
    fi
    
    log_info "LXC功能验证完成"
}

# 主函数
main() {
    local image_dir="${1:-.}"
    
    log_info "=== LuneOS for OnePlus 6 刷机工具 ==="
    log_info "版本: 1.0"
    log_info "设备: OnePlus 6 (enchilada)"
    echo
    
    # 警告信息
    log_warn "重要警告："
    log_warn "1. 此操作会清除所有数据"
    log_warn "2. 请备份重要文件"
    log_warn "3. 刷机有风险，操作需谨慎"
    echo
    
    read -p "我已了解风险并确认继续 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "用户取消操作"
        exit 1
    fi
    
    # 执行刷机流程
    check_tools
    check_device
    unlock_bootloader
    flash_luneos "$image_dir"
    
    # 重启设备
    log_info "重启设备..."
    fastboot reboot
    
    # 验证功能
    verify_lxc
    
    log_info "=== 刷机完成 ==="
    log_info "设备将在30秒后启动"
    log_info "首次启动可能需要较长时间"
}

# 脚本入口
if [[ $# -eq 0 ]]; then
    main
else
    main "$1"
fi