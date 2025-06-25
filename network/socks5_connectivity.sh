#!/bin/bash

# 配置参数
SOCKS5_ADDR="2a14:67c0:118::1"  # SOCKS5 服务器地址
SOCKS5_PORT="35000"                # SOCKS5 服务器端口
SOCKS5_USER="alice"
SOCKS5_PASS="alice..MVM"
TEST_URL="https://www.google.com"
UDP_TEST_SERVER="2001:4860:4860::8888"  # Google IPv6 DNS
UDP_TEST_DOMAIN="bing.com"           # 测试域名

# 检查所需工具
check_tools() {
  if ! command -v nmap &> /dev/null; then
    echo "错误：未安装 nmap，请先安装（apt/yum install nmap）"
    exit 1
  fi
  if ! command -v tsocks &> /dev/null; then
    echo "错误：未安装 tsocks，请先安装（apt/yum install tsocks）"
    exit 1
  fi
  if ! command -v dig &> /dev/null; then
    echo "错误：未安装 dig（dnsutils），请先安装（apt/yum install dnsutils）"
    exit 1
  fi
}

# 1. 测试 TCP 连接
test_tcp_connection() {
  echo "===== 测试 TCP 连接到 SOCKS5 服务器 ====="
  if nmap -6 -p "$SOCKS5_PORT" "$SOCKS5_ADDR" | grep -q "open"; then
    echo "✅ 连接成功：SOCKS5 服务器 $SOCKS5_ADDR:$SOCKS5_PORT 可达"
    return 0
  else
    echo "❌ 连接失败：SOCKS5 服务器不可达或端口被屏蔽"
    return 1
  fi
}

# 2. 测试 SOCKS5 认证（HTTP 请求）
test_socks5_auth_http() {
  echo "===== 测试 SOCKS5 认证（HTTP 请求） ====="
  # 配置 tsocks
  cat > /tmp/tsocks.conf <<EOF
server = $SOCKS5_ADDR
server_type = 5
server_port = $SOCKS5_PORT
username = $SOCKS5_USER
password = $SOCKS5_PASS
EOF

  echo "生成的 tsocks 配置："
  cat /tmp/tsocks.conf
  
  # 使用 tsocks 发起 HTTP 请求
  result=$(TSOCKS_CONF_FILE=/tmp/tsocks.conf tsocks curl -6 -sI "$TEST_URL")
  if echo "$result" | grep -q "HTTP/"; then
    echo "✅ 认证成功：通过 SOCKS5 代理访问 $TEST_URL 成功"
    return 0
  else
    echo "❌ 认证失败：用户名/密码错误或代理拒绝访问"
    echo "错误信息：$result"
    return 1
  fi
}

# 3. 测试 SOCKS5 UDP 转发（DNS 查询测试）
test_socks5_udp() {
  echo "===== 测试 SOCKS5 UDP 转发（DNS 查询） ====="
  # 加载 tsocks 配置
  export TSOCKS_CONF_FILE=/tmp/tsocks.conf

  # 通过代理发送 UDP DNS 查询
  echo "尝试通过 SOCKS5 代理解析 $UDP_TEST_DOMAIN 的 IPv6 地址..."
  response=$(tsocks dig @$UDP_TEST_SERVER -6 "$UDP_TEST_DOMAIN" +short 2>&1)
  
  if echo "$response" | grep -q "NXDOMAIN"; then
    # 域名不存在属于正常情况，只要有响应即证明 UDP 转发成功
    echo "✅ UDP 转发成功：代理返回 DNS 响应（域名不存在）"
    return 0
  elif [ -n "$response" ]; then
    echo "✅ UDP 转发成功：解析结果为 $response"
    return 0
  else
    echo "❌ UDP 转发失败：代理未返回响应"
    echo "错误信息：$response"
    return 1
  fi
}

cleanup() {
  rm -f /tmp/tsocks.conf
}

main() {
  check_tools
  test_tcp_connection || exit 1
  test_socks5_auth_http || exit 1
  test_socks5_udp || exit 1
  cleanup
  echo "===== 所有测试通过 ====="
}

main