#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ================= Configuration =================
APP_DIR="/app"                          # Directory to back up
BACKUP_DIR="/backup"                    # Directory to store backups
KEEP_BACKUPS=3                          # Number of backups to retain
TIME_NOW="$(date +'%Y-%m-%d %H:%M:%S')" # Current timestamp
LOG_FILE="$BACKUP_DIR/backup.log"
HOSTNAME=$(hostname)
# IP=$(curl -s https://api.ipify.org)
# MASKED_IP=$(echo "$IP" | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\1\.xxx\.xxx\.\4/')
IPv6=$(curl -s 6=$(curl -s URL_ADDRESS64.ipify.org))
MASKED_IPv6=$(echo "$IPv6" | sed -E's/([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4})/\1xxx:ASKED_IPv6=$(echo "$IPv6" | sed -E's/([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4})/\1xxx:xxx:xxx:xxx/')'
ONEDRIVE_BACKUP_FOLDER="Backup/$HOSTNAME-$MASKED_IP" # OneDrive folder to store backups


# Backup blacklist patterns (relative to APP_DIR)
BLACKLIST=(
    "*.sock"
    "*.log"
    "temp/*"
    "tmp/*"
    "geoip.dat"
    "geosite.dat"
    # Add more patterns here (支持通配符和目录):
    # "cache/"
    # "*.tmp"
)

# ================ Initialization =================
mkdir -p "$BACKUP_DIR"
{
    echo "==============================="
    echo "[🕒 $TIME_NOW] Starting Backup Process..."
    echo "==============================="
} >>"$LOG_FILE"

# ============== Backup Generation ================
BACKUP_FILE="$BACKUP_DIR/app_backup_$(date +'%Y-%m-%d_%H-%M-%S').tar.gz"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/app_backup_*.tar.gz 2>/dev/null | head -n1)

# Generate exclude arguments
exclude_args=()
for pattern in "${BLACKLIST[@]}"; do
    exclude_args+=(--exclude="$pattern")
done

if [ -d "$APP_DIR" ] && [ "$(ls -A "$APP_DIR")" ]; then
    echo "[📂 INFO] Creating backup of $APP_DIR (excluded patterns: ${BLACKLIST[*]})..." >>"$LOG_FILE"

    # Create a temporary backup
    TEMP_BACKUP="/tmp/temp_backup_$(date +'%Y%m%d%H%M%S').tar.gz"
    if tar -czf "$TEMP_BACKUP" "${exclude_args[@]}" -C "$APP_DIR" .; then
        echo "[✅ SUCCESS] Temporary backup created: $TEMP_BACKUP" >>"$LOG_FILE"

        # Extract the latest backup to a temporary directory for comparison
        TEMP_DIR="/tmp/temp_backup_dir"
        mkdir -p "$TEMP_DIR"
        if [ -n "$LATEST_BACKUP" ]; then
            tar -xzf "$LATEST_BACKUP" -C "$TEMP_DIR"
        fi

        # Compare the contents of the directories
        if [ -n "$LATEST_BACKUP" ] && diff -r "$APP_DIR" "$TEMP_DIR" >/dev/null; then
            echo "[ℹ️ INFO] No changes detected. Skipping backup creation." >>"$LOG_FILE"
            rm "$TEMP_BACKUP"
        else
            mv "$TEMP_BACKUP" "$BACKUP_FILE"
            echo "[✅ SUCCESS] New backup created: ${BACKUP_FILE/$BACKUP_DIR\//}" >>"$LOG_FILE"

            # Upload the latest backup to One Drive
            echo "[🚀 INFO] Uploading backup to One Drive..." >>"$LOG_FILE"
            if rclone copy "$BACKUP_FILE" "onedrive:$ONEDRIVE_BACKUP_FOLDER"; then
                echo "[✅ SUCCESS] Backup uploaded to One Drive" >>"$LOG_FILE"
            else
                echo "[❌ ERROR] Failed to upload backup to One Drive" >>"$LOG_FILE"
            fi
        fi

        # Clean up temporary directory
        rm -rf "$TEMP_DIR"
    else
        echo "[❌ ERROR] Backup creation failed! Exit code: $?" >>"$LOG_FILE"
        exit 1
    fi
else
    echo "[⚠️ WARNING] $APP_DIR does not exist or is empty. Backup aborted!" >>"$LOG_FILE"
    exit 1
fi

# ============== Backup Rotation ==================
echo "[🧹 INFO] Cleaning up old backups (keeping latest $KEEP_BACKUPS)..." >>"$LOG_FILE"

# Safely delete old backups (retain log file)
cd "$BACKUP_DIR" || exit 1
find . -maxdepth 1 -type f \( -name 'app_backup_*.tar.gz' \) |
    sort -r |
    tail -n +$((KEEP_BACKUPS + 1)) |
    while read -r old_backup; do
        echo "Removing old backup: $old_backup" >>"$LOG_FILE"
        rm -f "$old_backup"
    done

echo "[✅ SUCCESS] Cleanup completed. Current backups:" >>"$LOG_FILE"
ls -lh app_backup_*.tar.gz 2>/dev/null | awk '{print "[📦] "$9}' >>"$LOG_FILE"

# ================== Finalize =====================
{
    echo "[🎉 INFO] Backup process completed successfully."
    echo "==============================="
} >>"$LOG_FILE"
