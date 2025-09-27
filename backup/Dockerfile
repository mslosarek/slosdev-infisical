FROM alpine:3.19

# Install required packages
RUN apk add --no-cache \
    postgresql16-client \
    aws-cli \
    bash \
    gzip \
    dcron \
    tzdata

# Create backup directory
RUN mkdir -p /backup /var/log

# Copy backup script
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Copy crontab file
COPY crontab /etc/crontabs/root

# Create entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]