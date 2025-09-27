# Infisical Server Setup Guide

This guide will help you set up your Infisical server on `infisical.slosdev.com` (via Cloudflare Tunnel) and `infisical.ts.slosdev.com`.

## Prerequisites

- Docker and Docker Compose installed
- Cloudflare account with tunnel configured
- Domain names configured in DNS

## Setup Instructions

### 1. Configure Environment Variables

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Generate secure random keys for all the required secrets:

```bash
# Generate encryption keys (run for each key)
openssl rand -hex 32
```

Required keys to generate:
- `ENCRYPTION_KEY`
- `JWT_SIGNUP_SECRET`
- `JWT_REFRESH_SECRET`
- `JWT_AUTH_SECRET`
- `JWT_SERVICE_SECRET`
- `JWT_PROVIDER_AUTH_SECRET`
- `AUTH_SECRET`

### 2. Set Database Password

Set a strong password for `POSTGRES_PASSWORD` in your `.env` file.

### 3. Start the Services

```bash
docker-compose up -d
```

Check that all services are running:

```bash
docker-compose ps
```

View logs if needed:

```bash
docker-compose logs -f
```

### 4. Configure Cloudflare Tunnel

For `infisical.slosdev.com`:

1. Create a Cloudflare Tunnel in your Cloudflare dashboard
2. Configure the tunnel to point to:
   - Service: `http://localhost:8080` (or your server's IP:8080)
   - Domain: `infisical.slosdev.com`

If you want to manage the tunnel via Docker Compose:
1. Uncomment the `cloudflared` service in `docker-compose.yml`
2. Add your `CLOUDFLARE_TUNNEL_TOKEN` to the `.env` file
3. Restart the stack

### 5. Direct Access Configuration

For `infisical.ts.slosdev.com`:

1. Configure your DNS to point to your server's IP
2. Set up a reverse proxy (nginx/caddy) with SSL certificate
3. Proxy to `localhost:8080`

Example nginx configuration:

```nginx
server {
    listen 443 ssl http2;
    server_name infisical.ts.slosdev.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 6. Initial Setup

1. Access Infisical at `https://infisical.slosdev.com`
2. Create your first admin account
3. Configure organization settings

## Maintenance

### Backup Database

```bash
docker-compose exec postgres pg_dump -U infisical infisical > backup.sql
```

### Restore Database

```bash
docker-compose exec -T postgres psql -U infisical infisical < backup.sql
```

### Update Infisical

```bash
docker-compose pull infisical
docker-compose up -d infisical
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f infisical
```

## Troubleshooting

### Check Service Health

```bash
# Check PostgreSQL
docker-compose exec postgres pg_isready -U infisical

# Check Redis
docker-compose exec redis redis-cli ping
```

### Reset Everything

```bash
docker-compose down -v
docker-compose up -d
```

**Warning**: This will delete all data!

## Security Recommendations

1. Use strong, unique passwords for all secrets
2. Regularly backup your database
3. Keep Docker images updated
4. Monitor logs for suspicious activity
5. Consider implementing rate limiting at the reverse proxy level
6. Enable 2FA for all admin accounts

## Additional Configuration

See the [official Infisical documentation](https://infisical.com/docs/self-hosting/deployment-options/docker-compose) for more configuration options.