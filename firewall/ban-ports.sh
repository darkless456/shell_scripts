#!/bin/bash

# Script to block all TCP/UDP ports except specified ones
# Must be run with root privileges

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to set up firewall rules
setup_firewall() {
    # Flush existing rules and set default policies
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X

    # Set default policies to ACCEPT
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    # Allow loopback interface
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established and related connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Define blocked TCP ports (modify as needed)
    BLOCKED_TCP_PORTS="21,23,25,110,111,135,139,445,631,3306,1433,1521,3389,631,9100,6667" 

    # Define blocked UDP ports (modify as needed)
    BLOCKED_UDP_PORTS="21,23,25,110,111,135,139,445,631,3306,1433,1521,3389,631,9100,6667"

    # Block specific TCP ports
    if [ ! -z "$BLOCKED_TCP_PORTS" ]; then
        iptables -A INPUT -p tcp -m multiport --dports $BLOCKED_TCP_PORTS -j DROP
    fi

    # Block specific UDP ports
    if [ ! -z "$BLOCKED_UDP_PORTS" ]; then
        iptables -A INPUT -p udp -m multiport --dports $BLOCKED_UDP_PORTS -j DROP
    fi

    # # Save rules
    # if command -v netfilter-persistent &> /dev/null; then
    #     netfilter-persistent save
    # elif [ -x /etc/init.d/iptables-persistent ]; then
    #     /etc/init.d/iptables-persistent save
    # else
    #     echo "Warning: Could not find a method to save iptables rules permanently."
    #     echo "Consider installing iptables-persistent package:"
    #     echo "apt-get install iptables-persistent"
    # fi

    echo "Firewall rules have been set up. All ports are allowed except for:"
    echo "TCP ports: $BLOCKED_TCP_PORTS"
    echo "UDP ports: $BLOCKED_UDP_PORTS"
}

# Function to display current iptables rules
show_iptables_rules() {
    echo "Current iptables rules:"
    iptables -L -n -v
}

# Set up the firewall rules
setup_firewall
show_iptables_rules

# Create a systemd service file to run at boot
create_systemd_service() {
    cat > /etc/systemd/system/firewall.service << EOF
[Unit]
Description=Custom Firewall Rules
After=network.target

[Service]
Type=oneshot
ExecStart=$(readlink -f "$0")
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Enable the service
    systemctl daemon-reload
    systemctl enable firewall.service
    echo "Systemd service created and enabled. Firewall will run at boot."
}

# Check if this script is being run for setup
if [ "$1" != "--setup-only" ]; then
    # Create the systemd service
    create_systemd_service
fi

exit 0
