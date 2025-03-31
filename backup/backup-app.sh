#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ================= Configuration =================
APP_DIR="/app"                # Directory to back up
BACKUP_DIR="/backup"          # Directory to store backups
KEEP_BACKUPS=3                # Number of backups to retain
TIME_NOW="$(date +'%Y-%m-%d %H:%M:%S')"  # Current timestamp
LOG_FILE="$BACKUP_DIR/backup.log"

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

# 生成排除参数
exclude_args=()
for pattern in "${BLACKLIST[@]}"; do
    exclude_args+=(--exclude="$pattern")
done

if [ -d "$APP_DIR" ] && [ "$(ls -A "$APP_DIR")" ]; then
    echo "[📂 INFO] Creating backup of $APP_DIR (excluded patterns: ${BLACKLIST[*]})..." >> "$LOG_FILE"
    
    # 执行备份命令
    if tar -czf "$BACKUP_FILE" "${exclude_args[@]}" -C "$APP_DIR" . ; then
        echo "[✅ SUCCESS] Backup created: ${BACKUP_FILE/$BACKUP_DIR\//}" >> "$LOG_FILE"
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

# 安全删除旧备份（保留日志文件）
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