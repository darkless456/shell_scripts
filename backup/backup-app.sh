#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ================= Configuration =================
APP_DIR="/app"                # Directory to back up
BACKUP_DIR="/backup"          # Directory to store backups
KEEP_BACKUPS=3                # Number of backups to retain
TIME_NOW="$(date +'%Y-%m-%d %H:%M:%S')"  # Current timestamp
LOG_FILE="$BACKUP_DIR/backup.log"
HOSTNAME=$(hostname)
IP=$(curl -s https://api.ipify.org)
MASKED_IP=$(echo "$IP" | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\1\.xxx\.xxx\.\4/')
ONEDRIVE_TOKEN='{"access_token":"EwBIBMl6BAAUBKgm8k1UswUNwklmy2v7U/S+1fEAAaJ0E1tbDc3cQpvArYjm4Ucpsirci8eMFpnlVwlWV2f+DlQkogQuAQ91tLw3jCfak75blnesUjytsP4l1JPSGyo3s+IrQTiVKdWBGsHAOSCvtGUK+13BVKpIqZJkTZXtx3orGvkOytozLgBXIi7tsUQUDl/PkZ75u4JzNKxBK/kxYmb65lqQux1GO0Z219pGSObNn4vlijBTe1ABOMqg4IDkM07iiBWqdMDWioFbo2gOtpahx6bz1ACm/a6LQyZ3+igkCreMvvHj+fT7ydHV8z+BANdhRXBj+npsvdtzPfQouaXWE31eyKzcbsrCyUkZgENYOqYD3M+riXNU0YkO/2QQZgAAEHVPhUytpfE0iK3eKHk48O8QA5/Y5AbWl5codzjxvdZXMYwKekWuEhxsQAsrugP8ynvd1jbghmNtVe2++mb9O3uCYsG8rKYwO7IkF8AF8+JANQ+B3qr6SMVchP5cr+oPVTploql+UgyT3/IZl+BbOKGfx4fyPNAsN9FYZnLooBGpvXMPLBWdTi1Rfi18341+Ez/Xp9nCVFE2LNThei3SVIJCtGU/0aQd+SgrsRr99MbHzFdiSLjSignJw7K3qtTSujjnGi1k6/Das/F21xXNUYugvVkcF2mK5BLNDWnOigkHIgfk2up8mTrPf8e4XwYYSw8viIxdNDgLy624X//B5+paPJIy10eRGUTOxpniW3prxp5ZyFNRqig7nmHJUO0ppyaWloNXvEz9jBxsE4x4ajJ52a9GeuFXEEai7q+j6KuNowF7GS5RytvhoWQWDQKMOQtAYslmXCU1YZ1x8RUiNroZVkZOE3GWHGJqagzAlz5xbClMyX6bGfJ7F9iH1k97owUpN8FctI5lFZNG4t6WojYSqURWmhyn198IfyUzNlTwXR/B5n5bTL0C1EVduTMrP3cHlQmCXlncuFoFy3YQCEv0vWoJ8Jd5E7bCgQELXZ0lDM4Xx+SijaC6Flo1DBMnwSejt/O1cM+7nzTdBIqSlTOY905LAQuFbiKP2fMR9QkmZ/omNhTWU8UVsaSR2BDSsyXzJrC/5yPU7rkwjLE4y83OsPFqfP/9AaBImfQtA86fc2KIhksx6Lwhe7g2CFZN+EJLtCQ+PG4eLi779EwVQqXmEjGrOZga3AXS8AA0lAtAY+Gma5AcE4VjYSgNs1OoibAiCwzoEwlbqVPWMZX+AeMiOND/YcsgAW9f0ZQT22LsqS3YPWaIIqFpIxQFRlJ4lKGecjAfhSBYT+7VRnlZ9xRCn01KZMP5btFZEVpcl83ky3SQKH8P0tMOmmnPF041iAA5B2wGNEw+Eid4DCcbhIvW9bLbGYgWYPvNfOKscDCYCKYTuZHy4DjsnW9r+QvWju1LB6XdpR6l1eLEa/AzN07qlr8DmxQoCHkGHKIFNGsMx9VIAw==","token_type":"Bearer","refresh_token":"M.C551_BAY.0.U.-ClV1Lvg54HjDZHXVnN9J51PukplNV*CGJliPlB!seg3r6qUqvms8OfiM13XoMf7zvZ9Qvs9XesN3MpzOQadGzU!x!du6JPQL1ltRwfg1jmuXlcZznHOs3oFICgHSHjanmwU89kHHwAGUQQ6cB0IaO*3Yxr34d1SZQP*rG5h!o9TFmBwKlaSZuPskOJ8Y9B4S4bGILYfe0o2yay6lBLXYnSCw83sJiwiMF0r00svYrNPsTyBIXQGXHEKNW3cLERZuitl0LisQgA1zXzL2gLE!nctAAaPZn*WHlWfJizd8Hhemvv6PRmGFwmovk5VeEExPYzu9AOklrTEi50hvZCcXyTqSrmOj9OUI9yRwX1uSg2jb","expiry":"2025-04-21T16:06:32.206503+08:00"}'
ONEDRIVE_BACKUP_FOLDER="Backup/$HOSTNAME-$MASKED_IP"  # OneDrive folder to store backups

if command -v rclone &> /dev/null; then
    echo "[✅ SUCCESS] rclone is installed." >> "$LOG_FILE"
else
    echo "[⚠️ WARNING] rclone is not installed. It will install rclone automatically!" >> "$LOG_FILE"
    curl https://rclone.org/install.sh | bash
    if command -v rclone &> /dev/null; then
        echo "[✅ SUCCESS] rclone installed successfully." >> "$LOG_FILE"
    else
        echo "[❌ ERROR] Failed to install rclone. Please install it manually." >> "$LOG_FILE"
        exit 1
    fi
fi

if rclone config show onedrive &> /dev/null; then
    echo "[✅ SUCCESS] rclone OneDrive configuration exists." >> "$LOG_FILE"
else
    echo "[⚠️ WARNING] rclone OneDrive configuration does not exist. It will add rclone onedrive configration" >> "$LOG_FILE"
    rclone config create onedrive onedrive \
        client_id="" \
        client_secret="" \
        region="global" \
        drive_type="personal" \
        token="$ONEDRIVE_TOKEN"
fi

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
} >> "$LOG_FILE"

# ============== Backup Generation ================
BACKUP_FILE="$BACKUP_DIR/app_backup_$(date +'%Y-%m-%d_%H-%M-%S').tar.gz"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/app_backup_*.tar.gz 2>/dev/null | head -n1)

# Generate exclude arguments
exclude_args=()
for pattern in "${BLACKLIST[@]}"; do
    exclude_args+=(--exclude="$pattern")
done

if [ -d "$APP_DIR" ] && [ "$(ls -A "$APP_DIR")" ]; then
    echo "[📂 INFO] Creating backup of $APP_DIR (excluded patterns: ${BLACKLIST[*]})..." >> "$LOG_FILE"
    
    # Create a temporary backup
    TEMP_BACKUP="/tmp/temp_backup_$(date +'%Y%m%d%H%M%S').tar.gz"
    if tar -czf "$TEMP_BACKUP" "${exclude_args[@]}" -C "$APP_DIR" . ; then
        echo "[✅ SUCCESS] Temporary backup created: $TEMP_BACKUP" >> "$LOG_FILE"
        
        # Extract the latest backup to a temporary directory for comparison
        TEMP_DIR="/tmp/temp_backup_dir"
        mkdir -p "$TEMP_DIR"
        if [ -n "$LATEST_BACKUP" ]; then
            tar -xzf "$LATEST_BACKUP" -C "$TEMP_DIR"
        fi
        
        # Compare the contents of the directories
        if [ -n "$LATEST_BACKUP" ] && diff -r "$APP_DIR" "$TEMP_DIR" >/dev/null; then
            echo "[ℹ️ INFO] No changes detected. Skipping backup creation." >> "$LOG_FILE"
            rm "$TEMP_BACKUP"
        else
            mv "$TEMP_BACKUP" "$BACKUP_FILE"
            echo "[✅ SUCCESS] New backup created: ${BACKUP_FILE/$BACKUP_DIR\//}" >> "$LOG_FILE"
            
            # Upload the latest backup to One Drive
            echo "[🚀 INFO] Uploading backup to One Drive..." >> "$LOG_FILE"
            if rclone copy "$BACKUP_FILE" "onedrive:$ONEDRIVE_BACKUP_FOLDER"; then
                echo "[✅ SUCCESS] Backup uploaded to One Drive" >> "$LOG_FILE"
            else
                echo "[❌ ERROR] Failed to upload backup to One Drive" >> "$LOG_FILE"
            fi
        fi
        
        # Clean up temporary directory
        rm -rf "$TEMP_DIR"
    else
        echo "[❌ ERROR] Backup creation failed! Exit code: $?" >> "$LOG_FILE"
        exit 1
    fi
else
    echo "[⚠️ WARNING] $APP_DIR does not exist or is empty. Backup aborted!" >> "$LOG_FILE"
    exit 1
fi

# ============== Backup Rotation ==================
echo "[🧹 INFO] Cleaning up old backups (keeping latest $KEEP_BACKUPS)..." >> "$LOG_FILE"

# Safely delete old backups (retain log file)
cd "$BACKUP_DIR" || exit 1
find . -maxdepth 1 -type f \( -name 'app_backup_*.tar.gz' \) | \
sort -r | \
tail -n +$((KEEP_BACKUPS + 1)) | \
while read -r old_backup; do
    echo "Removing old backup: $old_backup" >> "$LOG_FILE"
    rm -f "$old_backup"
done

echo "[✅ SUCCESS] Cleanup completed. Current backups:" >> "$LOG_FILE"
ls -lh app_backup_*.tar.gz 2>/dev/null | awk '{print "[📦] "$9}' >> "$LOG_FILE"

# ================== Finalize =====================
{
echo "[🎉 INFO] Backup process completed successfully."
echo "==============================="
} >> "$LOG_FILE"