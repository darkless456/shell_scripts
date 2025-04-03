tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
      "https://hub.ifamily.work"
    ]
}
EOF

systemctl daemon-reload 
systemctl restart docker