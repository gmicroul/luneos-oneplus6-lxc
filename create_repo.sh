#!/bin/bash

# GitHub仓库创建脚本
# 需要先设置GITHUB_TOKEN环境变量

set -e

if [ -z "$GITHUB_TOKEN" ]; then
    echo "错误: 请先设置GITHUB_TOKEN环境变量"
    echo "获取方法: https://github.com/settings/tokens"
    exit 1
fi

REPO_NAME="luneos-oneplus6-lxc"
REPO_DESC="LuneOS for OnePlus 6 with LXC container support"

# 创建GitHub仓库
echo "创建GitHub仓库: $REPO_NAME..."

response=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{
    \"name\": \"$REPO_NAME\",
    \"description\": \"$REPO_DESC\",
    \"private\": false,
    \"has_issues\": true,
    \"has_projects\": true,
    \"has_wiki\": true,
    \"auto_init\": false
  }" \
  https://api.github.com/user/repos)

# 检查是否创建成功
if echo "$response" | grep -q '"html_url"'; then
    repo_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
    echo "✅ 仓库创建成功: $repo_url"
else
    echo "❌ 仓库创建失败"
    echo "响应: $response"
    exit 1
fi

# 添加远程仓库并推送
echo "添加远程仓库并推送代码..."

cd /home/user/luneos-oneplus6-lxc

git remote add origin "https://$GITHUB_TOKEN@github.com/$(echo "$response" | grep -o '"full_name":"[^"]*"' | cut -d'"' -f4).git"

git push -u origin main

echo "✅ 代码推送完成"
echo "仓库地址: $repo_url"