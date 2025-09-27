#!/bin/bash

# Infisical PostgreSQL Restore Script
# Usage: ./restore.sh backup_file.sql.gz

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    echo "Example: $0 backups/infisical_backup_20240115_120000.sql.gz"
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will replace ALL data in the Infisical database!"
read -p "Are you sure you want to restore from $BACKUP_FILE? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo "Starting restore..."

# Decompress if needed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Decompressing backup..."
    gunzip -c "$BACKUP_FILE" | docker-compose exec -T postgres psql -U infisical infisical
else
    docker-compose exec -T postgres psql -U infisical infisical < "$BACKUP_FILE"
fi

if [ $? -eq 0 ]; then
    echo "✓ Restore completed successfully"
    echo "Please restart the Infisical container: docker-compose restart infisical"
else
    echo "✗ Restore failed!"
    exit 1
fi