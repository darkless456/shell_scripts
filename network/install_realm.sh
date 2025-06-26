#!/bin/bash

# 检查是否以root身份运行
if [ "$EUID" -ne 0 ]
  then echo "请以root身份运行脚本"
  exit 1
fi

# 下载最新的realm压缩包
wget https://gh.ifamily.work/https://github.com/zhboner/realm/releases/download/v2.7.0/realm-x86_64-unknown-linux-gnu.tar.gz

# 检查下载是否成功
if [ $? -ne 0 ]; then
    echo "下载失败，请检查网络连接或URL是否正确。"
    exit 1
fi

# 创建临时目录
tmp_dir=$(mktemp -d)

# 解压压缩包到临时目录
tar -xzf realm-x86_64-unknown-linux-gnu.tar.gz -C $tmp_dir

# 查找解压后的realm二进制文件
realm_binary=$(find $tmp_dir -name "realm" -type f)

# 检查是否找到realm二进制文件
if [ -z "$realm_binary" ]; then
    echo "未找到realm二进制文件，请检查压缩包内容。"
    rm -rf $tmp_dir
    rm realm-x86_64-unknown-linux-gnu.tar.gz
    exit 1
fi

# 将realm二进制文件移动到/usr/bin
mv $realm_binary /usr/bin/realm

# 检查移动是否成功
if [ $? -eq 0 ]; then
    echo "realm已成功安装到 /usr/bin。"
else
    echo "移动realm二进制文件到 /usr/bin 失败，请检查权限。"
fi

# 删除临时目录和下载的压缩包
rm -rf $tmp_dir
rm realm-x86_64-unknown-linux-gnu.tar.gz

# 定义服务内容
SERVICE_CONTENT="[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
DynamicUser=true
WorkingDirectory=/etc/realm
ExecStart=/usr/bin/realm -c /app/realm/config.toml

[Install]
WantedBy=multi-user.target"

# 创建服务文件
SERVICE_FILE="/etc/systemd/system/realm.service"
echo "$SERVICE_CONTENT" > "$SERVICE_FILE"
chmod 644 "$SERVICE_FILE"

# 确保相关目录存在
mkdir -p /etc/realm /app/realm

# 重载systemd配置
systemctl daemon-reload

# 启用并启动服务
systemctl enable --now realm.service

echo "服务已安装并启动："
systemctl status realm.service