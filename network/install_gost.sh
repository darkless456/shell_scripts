#!/bin/bash

# 定义下载链接和文件名
DOWNLOAD_URL="https://github.com/go-gost/gost/releases/download/v3.0.0/gost_3.0.0_linux_amd64.tar.gz"
TAR_FILE="gost_3.0.0_linux_amd64.tar.gz"
GOST_BINARY="gost"

# 检查是否为root用户
if [[ "$EUID" -ne 0 ]]; then
    echo "$(tput setaf 1)Error: You must run this script as root!$(tput sgr0)"
    exit 1
fi

# 下载gost二进制文件
echo "Downloading gost binary file..."
curl -fsSL -o "$TAR_FILE" "$DOWNLOAD_URL"

# 检查下载是否成功
if [ $? -ne 0 ]; then
    echo "Failed to download gost binary file."
    exit 1
fi

# 解压文件
echo "Extracting the binary file..."
tar -xzf "$TAR_FILE"

# 检查解压是否成功
if [ $? -ne 0 ]; then
    echo "Failed to extract the binary file."
    rm "$TAR_FILE"
    exit 1
fi

# 移动二进制文件到系统路径
echo "Installing gost..."
chmod +x "$GOST_BINARY"
mv "$GOST_BINARY" /usr/local/bin/

# 检查安装是否成功
if [ $? -ne 0 ]; then
    echo "Failed to install gost."
    rm "$TAR_FILE"
    exit 1
fi

# 删除下载的压缩文件
rm "$TAR_FILE"

# 创建systemd服务文件
echo "Creating systemd service file..."
cat << EOF > /etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target

[Service]
ExecStart=/usr/local/bin/gost -C /app/gost/config.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd管理器配置
systemctl daemon-reload

# 启动gost服务
echo "Starting gost service..."
systemctl start gost

# 检查服务是否启动成功
if [ $? -ne 0 ]; then
    echo "Failed to start gost service."
    exit 1
fi

# 设置开机自启动
echo "Enabling gost service to start on boot..."
systemctl enable gost

echo "Gost installation and configuration completed successfully!"