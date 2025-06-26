#!/bin/bash
set -ex

HOSTNAME=""
PASSWORD=""

if [ -z $HOSTNAME ]; then
    echo "请设置 HOSTNAME 环境变量"
    exit 1
fi

if [ -z $PASSWORD ]; then
    echo "请设置 PASSWORD 环境变量"
    exit 1
fi

Telcom_GZ=183.47.126.35 # 广州电信
Union_GZ=157.148.58.29 # 广州联通
Mobile_GZ=120.233.18.250 # 广州移动

Telcom_GZ_IPv6=240e:97c:2f:3000::44 # 广州电信 IPv6
Union_GZ_IPv6=2408:8756:f50:1001::c # 广州联通 IPv6
Mobile_GZ_IPv6=2409:8c54:871:1001::12 # 广州移动 IPv6

WORKSPACE=/opt/ServerStatus
mkdir -p ${WORKSPACE}
cd ${WORKSPACE}

# 下载, arm 机器替换 x86_64 为 aarch64
OS_ARCH="x86_64"
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/zdz/ServerStatus-Rust/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

wget --no-check-certificate -qO "client-${OS_ARCH}-unknown-linux-musl.zip"  "https://github.tbedu.top/https://github.com/zdz/ServerStatus-Rust/releases/download/${latest_version}/client-${OS_ARCH}-unknown-linux-musl.zip"

if ! command -v unzip &> /dev/null; then
    apt install -y unzip
fi

unzip -o "client-${OS_ARCH}-unknown-linux-musl.zip"

# 清理自带service文件
rm -rf stat_client.service

# 配置
cat > stat_client.service << EOF
[Unit]
Description=ServerStatus-Rust Client
After=network.target

[Service]
User=root
Group=root
Environment="RUST_BACKTRACE=1"
WorkingDirectory=/opt/ServerStatus
# EnvironmentFile=/opt/ServerStatus/.env
ExecStart=/opt/ServerStatus/stat_client -a "https://server.self-media.org/report" -u $HOSTNAME -p $PASSWORD --disable-extra
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target

# /etc/systemd/system/stat_client.service
# journalctl -u stat_client -f -n 100
EOF

# 移动服务文件
mv -v stat_client.service /etc/systemd/system/stat_client.service

systemctl daemon-reload

# 启动
systemctl start stat_client

# 开机自启
systemctl enable stat_client

# 状态查看
systemctl status stat_client

# 停止
# systemctl stop stat_client