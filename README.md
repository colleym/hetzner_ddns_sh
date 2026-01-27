# hetzner-ddns

A lightweight Dynamic DNS updater for [Hetzner DNS](https://dns.hetzner.com/). Pure shell script, no dependencies beyond `curl`.

## Features

- **Hetzner DNS API** - Updates A and AAAA records via the official API
- **IPv4 + IPv6** - Dual-stack support with automatic detection
- **Multiple Records** - Update multiple subdomains in one run
- **Uptime Kuma** - Optional push monitor integration
- **Notifications** - Pluggable providers: Brevo, SMTP, Mailgun
- **Portable** - Runs on Linux, Synology NAS, OpenWrt, FreeBSD, macOS

## Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/hetzner-ddns.git
cd hetzner-ddns

# Create your configuration
cp config.example.sh config.sh

# Edit config.sh with your Hetzner API token and zone ID
nano config.sh

# Make executable and run
chmod +x hetzner-ddns.sh
./hetzner-ddns.sh
```

## Configuration

Edit `config.sh` with your settings:

```sh
# Required
HETZNER_TOKEN="your-api-token"
ZONE_ID="your-zone-id"
RECORDS="dyndns:A"

# Optional: Dual-stack
RECORDS="dyndns:A dyndns:AAAA"

# Optional: Multiple subdomains
RECORDS="home:A vpn:A nas:A"
```

### Getting Your Zone ID

1. Go to [Hetzner DNS Console](https://dns.hetzner.com/)
2. Click on your domain
3. The Zone ID is in the URL: `https://dns.hetzner.com/zone/ZONE_ID_HERE`

Or via API:
```bash
curl -H "Auth-API-Token: YOUR_TOKEN" https://dns.hetzner.com/api/v1/zones
```

## Notification Providers

Set `NOTIFY_PROVIDER` in config.sh to enable notifications on IP change.

### Brevo (formerly Sendinblue)

```sh
NOTIFY_PROVIDER="brevo"
NOTIFY_RECIPIENTS="admin@example.com"
BREVO_API_KEY="your-api-key"
BREVO_SENDER_EMAIL="alerts@yourdomain.com"
```

### SMTP

```sh
NOTIFY_PROVIDER="smtp"
NOTIFY_RECIPIENTS="admin@example.com"
SMTP_HOST="smtp.example.com"
SMTP_PORT="587"
SMTP_USER="your-username"
SMTP_PASS="your-password"
SMTP_FROM="alerts@yourdomain.com"
```

### Mailgun

```sh
NOTIFY_PROVIDER="mailgun"
NOTIFY_RECIPIENTS="admin@example.com"
MAILGUN_API_KEY="your-api-key"
MAILGUN_DOMAIN="mg.yourdomain.com"
MAILGUN_FROM="alerts@yourdomain.com"
MAILGUN_REGION="eu"  # or "us"
```

## Uptime Kuma Integration

```sh
UPTIME_KUMA_ENABLED="true"
UPTIME_KUMA_URL="https://your-kuma-instance/api/push/YOUR_TOKEN?status=up&msg=OK"
```

## Deployment

### Cron (Linux)

```bash
# Edit crontab
crontab -e

# Run every 5 minutes
*/5 * * * * /path/to/hetzner-ddns/hetzner-ddns.sh
```

### Synology Task Scheduler

1. Control Panel → Task Scheduler → Create → Scheduled Task → User-defined script
2. Schedule: Every 5 minutes
3. Task Settings → Run command:
   ```
   /volume1/tools/hetzner-ddns/hetzner-ddns.sh
   ```

**Note for Synology:** If you have PATH issues, set `CURL="/usr/bin/curl"` in config.sh.

### systemd Timer (Linux)

Create `/etc/systemd/system/hetzner-ddns.service`:
```ini
[Unit]
Description=Hetzner Dynamic DNS Updater

[Service]
Type=oneshot
ExecStart=/opt/hetzner-ddns/hetzner-ddns.sh
```

Create `/etc/systemd/system/hetzner-ddns.timer`:
```ini
[Unit]
Description=Run Hetzner DDNS every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Enable:
```bash
systemctl enable --now hetzner-ddns.timer
```

## Dry Run

Test your configuration without making changes:

```bash
./hetzner-ddns.sh --dry-run
```

## Troubleshooting

### Check the log file

```bash
cat hetzner-ddns.log
```

### Test API connectivity

```bash
curl -H "Auth-API-Token: YOUR_TOKEN" https://dns.hetzner.com/api/v1/zones
```

### Synology: curl not found

Set the full path in config.sh:
```sh
CURL="/usr/bin/curl"
```

## License

MIT License - see [LICENSE](LICENSE)
