# 资源受限环境构建指南

针对磁盘空间和内存有限的本地环境，提供优化构建方案。

## 方案一：GitHub Actions云端构建（推荐）

### 优势
- ✅ 完全免费（每月2000分钟）
- ✅ 无需本地资源
- ✅ 自动发布镜像
- ✅ 并行构建加速

### 实施步骤

1. **创建GitHub仓库并推送代码**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/[用户名]/luneos-oneplus6-lxc.git
   git push -u origin main
   ```

2. **启用GitHub Actions**
   - 仓库设置 → Actions → 启用Workflows
   - 推送代码后自动开始构建

3. **下载构建成果**
   - 在GitHub Releases页面下载预构建镜像
   - 或从Actions artifacts下载构建文件

## 方案二：最小化本地构建

### 环境要求（大幅降低）
- **磁盘空间**: 30GB（使用增量构建）
- **内存**: 8GB
- **系统**: Ubuntu 20.04+

### 优化构建步骤

1. **最小化依赖安装**
   ```bash
   sudo apt update
   sudo apt install -y git build-essential python3 python3-pip
   ```

2. **使用Docker容器构建（隔离环境）**
   ```bash
   # 创建Docker构建环境
   docker run -it --name luneos-build -v $(pwd):/workspace ubuntu:22.04
   
   # 在容器内安装最小依赖
   apt update && apt install -y git build-essential python3
   ```

3. **增量构建配置**
   ```bash
   # 在build/conf/local.conf中添加优化配置
   cat >> build/conf/local.conf << 'EOF'
   
   # 构建优化 - 减少磁盘使用
   INHERIT += "rm_work"
   
   # 并行构建加速
   BB_NUMBER_THREADS = "4"
   PARALLEL_MAKE = "-j 4"
   
   # 禁用不必要的包
   NO_RECOMMENDATIONS = "1"
   
   # 最小化镜像大小
   IMAGE_FEATURES = ""
   EOF
   ```

4. **分阶段构建**
   ```bash
   # 第一阶段：只构建内核（资源需求最低）
   bitbake linux-oneplus6
   
   # 第二阶段：构建根文件系统
   bitbake luneos-image
   
   # 第三阶段：生成刷机镜像
   bitbake luneos-image-sdimg
   ```

## 方案三：使用现有预构建组件

### 利用现有的LuneOS基础
1. **下载官方LuneOS镜像**作为基础
2. **只编译内核和LXC包**
3. **替换原有内核**

### 具体步骤
```bash
# 1. 下载官方LuneOS镜像
wget https://github.com/webOS-ports/luneos-releases/releases/download/xxx/luneos-image-xxx.wic

# 2. 提取内核
wic cp luneos-image-xxx.wic:1/boot/Image.gz-dtb ./extracted-kernel

# 3. 编译带LXC支持的内核
bitbake linux-oneplus6

# 4. 替换内核
wic cp new-kernel luneos-image-xxx.wic:1/boot/Image.gz-dtb
```

## 磁盘空间优化技巧

### 1. 定期清理构建缓存
```bash
# 清理临时文件
bitbake -c cleanall linux-oneplus6

# 删除下载缓存
rm -rf downloads/*

# 清理构建缓存
rm -rf tmp/cache
```

### 2. 使用外部存储
```bash
# 将downloads目录挂载到外部存储
mkdir -p /external/downloads
ln -s /external/downloads downloads

# 或将整个构建目录放在外部硬盘
mv ~/luneos-build /external/luneos-build
cd /external/luneos-build
```

### 3. 压缩存储
```bash
# 使用压缩文件系统
sudo mkfs.btrfs -L luneos-build /dev/sdb1
sudo mount -o compress=zstd /dev/sdb1 ~/luneos-build
```

## 内存优化技巧

### 1. 增加交换空间
```bash
# 创建交换文件
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 2. 调整构建参数
```bash
# 减少并行任务数
BB_NUMBER_THREADS = "2"
PARALLEL_MAKE = "-j 2"
```

## 推荐的实施顺序

1. **首选**: GitHub Actions云端构建
   - 零本地资源消耗
   - 自动化和可重复

2. **备选**: 最小化本地Docker构建
   - 环境隔离
   - 资源可控

3. **最后**: 完整本地构建
   - 需要较多资源
   - 调试方便

## 故障排除

### 磁盘空间不足
```bash
# 检查磁盘使用
df -h

# 清理系统缓存
sudo apt autoclean
sudo apt autoremove

# 删除大型临时文件
find ~/luneos-build -name "*.tar" -size +100M -delete
```

### 内存不足
```bash
# 检查内存使用
free -h

# 终止不必要的进程
sudo pkill -f chromium
sudo pkill -f firefox

# 增加交换空间
sudo swapon --show
```

## 结论

对于资源受限的环境，**强烈推荐使用GitHub Actions云端构建**。这种方式：
- 完全免费
- 无需本地资源
- 自动化程度高
- 成果可直接下载使用

如果你坚持本地构建，请按照最小化配置方案实施。