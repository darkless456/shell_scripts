#!/bin/bash

set -e

# Nezha Agent 安装与自动更新禁用脚本
# 适用于 Linux 系统，支持禁用 Agent 自动更新功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 恢复默认颜色

echo -e "${YELLOW}===== Nezha Agent 安装脚本开始执行 =====${NC}"

# 1. 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 root 权限运行此脚本${NC}"
    exit 1
fi

# 2. 安装必要工具
echo -e "${YELLOW}正在安装必要工具...${NC}"
if command -v curl &> /dev/null; then
    echo -e "${GREEN}curl 已安装${NC}"
else
    if [ -f /etc/debian_version ]; then
        apt-get update && apt-get install -y curl unzip
    elif [ -f /etc/redhat-release ]; then
        yum install -y curl unzip
    else
        echo -e "${RED}不支持的操作系统，请手动安装 curl 和 unzip${NC}"
        exit 1
    fi
fi

# 检查并安装 unzip
if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}正在安装 unzip...${NC}"
    if [ -f /etc/debian_version ]; then
        apt-get install -y unzip
    elif [ -f /etc/redhat-release ]; then
        yum install -y unzip
    fi
fi

# 3. 下载 Nezha Agent 二进制文件
AGENT_URL="https://github.com/nezhahq/agent/releases/download/v0.20.5/nezha-agent_linux_amd64.zip"
echo -e "${YELLOW}正在从 ${AGENT_URL} 下载...${NC}"

mkdir -p /opt/nezha-agent
cd /opt/nezha-agent

# 下载 zip 文件
curl -L -o nezha-agent.zip "$AGENT_URL"
if [ $? -ne 0 ]; then
    echo -e "${RED}下载失败，请检查网络连接${NC}"
    exit 1
fi

# 解压 zip 文件
unzip -o nezha-agent.zip
if [ $? -ne 0 ]; then
    echo -e "${RED}解压失败，请检查下载的文件${NC}"
    exit 1
fi

# 清理下载的 zip 文件
rm -f nezha-agent.zip

# 给执行权限
chmod +x /opt/nezha-agent/nezha-agent
echo -e "${GREEN}Nezha Agent 下载并解压完成${NC}"

# 4. 提示用户配置
echo -e "${YELLOW}请配置服务器信息：${NC}"
read -p "请输入服务器地址 (例如: monitor.example.com:5555): " SERVER_ADDRESS
read -p "请输入密钥: " SECRET_KEY

# 5. 配置 Systemd 服务
echo -e "${YELLOW}正在配置 Systemd 服务...${NC}"
cat > /etc/systemd/system/nezha-agent.service << EOF
[Unit]
Description=Nezha Agent
After=network.target

[Service]
Type=simple
ExecStart=/opt/nezha-agent/nezha-agent -s $SERVER_ADDRESS -p $SECRET_KEY --tls --disable-auto-update --disable-force-update --disable-command-execute
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 5. 重载 Systemd 配置并启动服务
echo -e "${YELLOW}正在启动 Nezha Agent...${NC}"
systemctl daemon-reload
systemctl start nezha-agent
systemctl enable nezha-agent
systemctl status nezha-agent
