#!/bin/bash
set -euo pipefail

################################################################################
# Pterodactyl Full Auto-Migration Script (PRO Edition)
# Author: Craftnode.eu / ItzKubass
# GitHub: https://github.com/ItzKubass
#
# Features:
#  - Full automated migration of Pterodactyl Panel + Wings
#  - Logging system
#  - Automatic rollback on failure
#  - Safe file transfer and permission rebuild
################################################################################

### ========================================
### CONFIGURATION
### ========================================
NEW_SERVER="1.2.3.4"
SSH_USER="root"
DB_NAME="panel"

PANEL_DIR="/var/www/pterodactyl"
VOLUMES_DIR="/var/lib/pterodactyl/volumes"

ARCHIVE="/root/pterodactyl_migration.tar.gz"
REMOTE_ARCHIVE="/root/pterodactyl_migration.tar.gz"

LOGFILE="/root/ptero_migration.log"
ROLLBACK_MARKER="/root/ptero_migration.rollback"

### ========================================
### LOGGING
### ========================================
exec > >(tee -a "$LOGFILE") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

### ========================================
### ROLLBACK (executed automatically on failure)
### ========================================
rollback() {
    log "❗ ERROR DETECTED — STARTING ROLLBACK PROCEDURE"

    ssh "$SSH_USER@$NEW_SERVER" "
        if [ -f $ROLLBACK_MARKER ]; then
            echo 'Rollback: Removing transferred files...'
            rm -f /var/www/pterodactyl/.env
            rm -f /var/www/pterodactyl/panel.sql
            rm -rf /var/lib/pterodactyl/volumes/*
            echo 'Rollback: Completed.'
        else
            echo 'Rollback marker not found — skipping rollback.'
        fi
    "

    log "Rollback completed."
}

trap rollback ERR

### ========================================
### START
### ========================================
log "==============================================="
log "   PTERODACTYL FULL AUTO MIGRATION (PRO MODE)"
log "   Script by: https://github.com/ItzKubass"
log "==============================================="

### ========================================
### 1) EXPORT DATABASE
### ========================================
log "[1/8] Exporting database..."

mysqldump -u root -p --opt "$DB_NAME" > "$PANEL_DIR/panel.sql"

### ========================================
### 2) CREATE ARCHIVE
### ========================================
log "[2/8] Creating archive..."

tar -czf "$ARCHIVE" \
    -C "$PANEL_DIR" .env panel.sql \
    -C "$VOLUMES_DIR" .

### ========================================
### 3) TRANSFER TO NEW SERVER
### ========================================
log "[3/8] Transferring archive to new server..."

scp "$ARCHIVE" "$SSH_USER@$NEW_SERVER:$REMOTE_ARCHIVE"

### ========================================
### 4) ENABLE ROLLBACK ON NEW SERVER
### ========================================
log "[4/8] Creating rollback marker on target server..."

ssh "$SSH_USER@$NEW_SERVER" "
    echo 'rollback-enabled' > $ROLLBACK_MARKER
"

### ========================================
### 5) EXTRACT ON NEW SERVER
### ========================================
log "[5/8] Extracting migration archive on target server..."

ssh "$SSH_USER@$NEW_SERVER" "
    mkdir -p /var/www/pterodactyl /var/lib/pterodactyl/volumes
    tar -xzf $REMOTE_ARCHIVE -C /
    mv /panel.sql /var/www/pterodactyl/panel.sql
    mv /.env /var/www/pterodactyl/.env
    mv /* /var/lib/pterodactyl/volumes/ 2>/dev/null || true
"

### ========================================
### 6) IMPORT DATABASE
### ========================================
log "[6/8] Importing database on new server..."

ssh "$SSH_USER@$NEW_SERVER" "
    mysql -u root -p $DB_NAME < /var/www/pterodactyl/panel.sql
"

### ========================================
### 7) FIX PERMISSIONS + RESTART SERVICES
### ========================================
log "[7/8] Fixing permissions and restarting services..."

ssh "$SSH_USER@$NEW_SERVER" "
    chown -R www-data:www-data /var/www/pterodactyl
    chmod 600 /var/www/pterodactyl/.env
    systemctl restart nginx 2>/dev/null || systemctl restart httpd 2>/dev/null || true
    systemctl restart wings 2>/dev/null || true
"

### ========================================
### 8) REMOVE ROLLBACK MARKER (SUCCESS)
### ========================================
log "[8/8] Migration successful — removing rollback marker..."

ssh "$SSH_USER@$NEW_SERVER" "
    rm -f $ROLLBACK_MARKER
"

log "==============================================="
log "   MIGRATION COMPLETED SUCCESSFULLY 🎉"
log "   Log file: $LOGFILE"
log "   Script by: https://github.com/ItzKubass"
log "==============================================="
