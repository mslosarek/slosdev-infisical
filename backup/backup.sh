#!/bin/bash

set -e

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="/tmp/infisical_backup_${TIMESTAMP}.sql"
COMPRESSED_FILE="${BACKUP_FILE}.gz"
S3_PATH="s3://${S3_BUCKET}/backups/infisical_backup_${TIMESTAMP}.sql.gz"
ENV_S3_PATH="s3://${S3_BUCKET}/config/.env"
MAX_RETRIES=3

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to upload to S3 with retry
upload_to_s3() {
    local file=$1
    local destination=$2
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        log "Upload attempt $attempt for $destination"
        if aws s3 cp "$file" "$destination" --region "${AWS_REGION}" --sse AES256; then
            log "✓ Successfully uploaded to $destination"
            return 0
        fi
        log "Upload attempt $attempt failed"
        attempt=$((attempt + 1))
        sleep 5
    done

    log "✗ Failed to upload after $MAX_RETRIES attempts"
    return 1
}

# Start backup process
log "Starting Infisical database backup"

# Wait for postgres to be ready (useful on container startup)
until PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump -h postgres -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c >/dev/null 2>&1; do
    log "Waiting for PostgreSQL to be ready..."
    sleep 5
done

# Create database dump
log "Creating database dump..."
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
    -h postgres \
    -U "${POSTGRES_USER}" \
    -d "${POSTGRES_DB}" \
    --verbose \
    --clean \
    --no-owner \
    --no-privileges \
    --if-exists \
    > "$BACKUP_FILE"

if [ ! -s "$BACKUP_FILE" ]; then
    log "✗ Backup file is empty!"
    exit 1
fi

# Compress backup
log "Compressing backup..."
gzip "$BACKUP_FILE"

# Upload database backup to S3
log "Uploading database backup to S3..."
upload_to_s3 "$COMPRESSED_FILE" "$S3_PATH"

# Upload .env file to S3 (if it exists and is mounted)
if [ -f "/config/.env" ]; then
    log "Uploading .env file to S3..."
    upload_to_s3 "/config/.env" "$ENV_S3_PATH"
else
    log "No .env file found at /config/.env, skipping..."
fi

# Clean up local files
rm -f "$COMPRESSED_FILE"

# List recent backups in S3
log "Recent backups in S3:"
aws s3 ls "s3://${S3_BUCKET}/backups/" --region "${AWS_REGION}" | tail -5

# Optional: Delete old backups from S3 (older than 30 days)
if [ "${DELETE_OLD_BACKUPS}" = "true" ]; then
    log "Cleaning up old backups (>30 days)..."
    aws s3 ls "s3://${S3_BUCKET}/backups/" --region "${AWS_REGION}" | \
    while read -r line; do
        createDate=$(echo "$line" | awk '{print $1" "$2}')
        createDate=$(date -d "$createDate" +%s)
        olderThan=$(date -d "30 days ago" +%s)
        if [ "$createDate" -lt "$olderThan" ]; then
            fileName=$(echo "$line" | awk '{print $4}')
            if [ "$fileName" != "" ]; then
                log "Deleting old backup: $fileName"
                aws s3 rm "s3://${S3_BUCKET}/backups/$fileName" --region "${AWS_REGION}"
            fi
        fi
    done
fi

log "✓ Backup completed successfully"