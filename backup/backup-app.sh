#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Directory paths
APP_DIR="/app"                # Directory to back up
BACKUP_DIR="/backup"          # Directory to store backups
TIME_NOW="$(date +'%Y-%m-%d %H:%M:%S')"  # Current timestamp formatted for logs
LOG_FILE="$BACKUP_DIR/backup.log"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"
echo "===============================" >> "$LOG_FILE"
echo "[🕒 $TIME_NOW] Starting Backup Process..." >> "$LOG_FILE"
echo "===============================" >> "$LOG_FILE"

# Step 1: Create a backup of the /app directory
BACKUP_FILE="$BACKUP_DIR/app_backup_$(date +'%Y-%m-%d_%H-%M-%S').tar.gz"
if [ -d "$APP_DIR" ] && [ "$(ls -A "$APP_DIR")" ]; then
    echo "[📂 INFO] Creating a backup of the /app directory..." >> "$LOG_FILE"
    tar -czf "$BACKUP_FILE" --exclude=*.sock -C "$APP_DIR" . || { echo "[❌ ERROR] Backup creation failed!" >> "$LOG_FILE"; exit 1; }
    echo "[✅ SUCCESS] Backup created successfully: $BACKUP_FILE" >> "$LOG_FILE"
else
    echo "[⚠️ WARNING] The /app directory does not exist or is empty. Backup aborted!" >> "$LOG_FILE"
    exit 1
fi

# Step 2: Delete all but the latest 3 backups from the /backup directory
echo "[🧹 INFO] Cleaning up old backups (keeping only the latest 3)..." >> "$LOG_FILE"
cd "$BACKUP_DIR"
KEEP_LOGS_AND_FILES="$(ls -tp | grep -E 'app_backup_|backup.log' | head -n 3)"  # Ensure `backup.log` is not deleted
ls -tp | grep -v '/$' | grep -v 'backup.log' | tail -n +4 | xargs -I {} rm -f {} || { echo "[❌ ERROR] Error during cleanup!" >> "$LOG_FILE"; exit 1; }
echo "[✅ SUCCESS] Cleanup of old backups complete." >> "$LOG_FILE"

echo "[🎉 INFO] Backup process completed successfully." >> "$LOG_FILE"
echo "===============================" >> "$LOG_FILE"