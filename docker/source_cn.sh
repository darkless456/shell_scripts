tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
      "https://hub.ifamily.work"
    ],
    "ipv6": true,
    "fixed-cidr-v6": "2001:db8:1::/64"
}
EOF

systemctl daemon-reload 
systemctl restart docker