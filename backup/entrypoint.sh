#!/bin/bash

# Set timezone if provided
if [ ! -z "$TZ" ]; then
    cp /usr/share/zoneinfo/$TZ /etc/localtime
    echo "$TZ" > /etc/timezone
fi

# Run initial backup on startup
echo "Running initial backup..."
/usr/local/bin/backup.sh

# Start cron daemon in foreground
echo "Starting cron daemon..."
crond -f -l 2