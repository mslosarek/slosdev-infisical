#!/bin/bash

# Infisical PostgreSQL Backup Script
# Usage: ./backup.sh

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/infisical_backup_$TIMESTAMP.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting Infisical database backup..."

# Create database backup using pg_dump from the postgres container
docker-compose exec -T postgres pg_dump -U infisical infisical > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Backup completed: $BACKUP_FILE"

    # Compress the backup
    gzip "$BACKUP_FILE"
    echo "✓ Compressed to: ${BACKUP_FILE}.gz"

    # Optional: Remove backups older than 30 days
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete
    echo "✓ Cleaned up old backups (>30 days)"
else
    echo "✗ Backup failed!"
    exit 1
fi