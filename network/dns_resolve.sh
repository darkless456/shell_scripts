#!/bin/bash

echo "正在解锁 DNS 解析..."
chattr -i /etc/resolv.conf

echo "正在添加 DNS 解析..."
tee /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 2001:4860:4860::8844
nameserver 2606:4700:4700::1111
EOF

echo "解锁 DNS 解析完成。"
chattr +i /etc/resolv.conf
echo "重新锁定 DNS 解析。"
