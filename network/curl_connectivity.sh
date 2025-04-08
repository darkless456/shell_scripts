#!/bin/bash

# Check if a URL is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

URL=$1

# Function to convert time to milliseconds
to_ms() {
    echo $(printf "%.2f" $(echo "$1 * 1000" | awk '{print $1}'))
}

# Perform the curl request and capture the output
output=$(curl -o /dev/null -s -w \
    "DNS_LOOKUP:%{time_namelookup}
    TCP_CONNECT:%{time_connect}
    SSL_HANDSHAKE:%{time_appconnect}
    SERVER_PROCESSING:%{time_starttransfer}
    TOTAL_TIME:%{time_total}
    DOWNLOAD_SPEED:%{speed_download}" \
    "$URL")

# Process and display the results
echo "Connection metrics for $URL:"
echo "-------------------------------------------"
while IFS=':' read -r key value; do
    key=$(echo $key | tr '[:lower:]' '[:upper:]' | tr '_' ' ')
    if [[ $key == *"SPEED"* ]]; then
        speed_kb=$(printf "%.2f" $(echo "$value / 1024" | awk '{print $1}'))
        printf "%-20s : %s KB/s\n" "$key" "$speed_kb"
    else
        printf "%-20s : %s ms\n" "$key" "$(to_ms $value)"
    fi
done <<< "$output"