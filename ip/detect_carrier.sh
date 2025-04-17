#!/bin/bash
# filepath: ip_carrier_check.sh

# Get the current public IP address
IP=$(curl -s https://api.ipify.org)

# Query the free IP-API service for ISP information
RESULT=$(curl -s "http://ip-api.com/json/$IP")

# Extract the ISP information from the JSON response
ISP=$(echo $RESULT | grep -o '"isp":"[^"]*"' | cut -d'"' -f4)

# Determine which Chinese carrier the IP belongs to
if echo "$ISP" | grep -q "China Mobile"; then
    echo "China Mobile"
    exit 0
elif echo "$ISP" | grep -q "China Telecom"; then
    echo "China Telecom"
    exit 0
elif echo "$ISP" | grep -q "China Unicom"; then
    echo "China Unicom"
    exit 0
else
    echo "$ISP"
    exit 0
fi