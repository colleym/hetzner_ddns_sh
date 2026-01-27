# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dynamic DNS updater for Hetzner DNS API. Pure shell script, supports IPv4/IPv6, multiple records, and pluggable notification providers.

## Architecture

```
hetzner-ddns/
├── hetzner-ddns.sh      # Main script
├── config.example.sh    # Config template
└── providers/           # Notification providers
    ├── notify_none.sh   # No-op (default)
    ├── notify_brevo.sh  # Brevo API
    ├── notify_smtp.sh   # Generic SMTP
    └── notify_mailgun.sh# Mailgun API
```

### Flow
1. Load config.sh
2. Send Uptime Kuma heartbeat (if enabled)
3. Detect IPv4/IPv6 via ipify.org
4. Compare against cached IPs
5. Update changed records via Hetzner API
6. Send notifications via selected provider

### Provider Interface
Providers receive these env vars: `$OLD_IP`, `$CURRENT_IP`, `$RECORD_NAME`, `$RECORD_TYPE`, `$CURL`, plus provider-specific config. Return exit code 0 on success.

## Testing

```bash
# Syntax check
sh -n hetzner-ddns.sh

# Dry run (no actual changes)
./hetzner-ddns.sh --dry-run

# Check logs
cat hetzner-ddns.log
```

## Synology Compatibility

- Use full curl path: `CURL="/usr/bin/curl"`
- File size check uses `ls -l | awk` instead of `stat -c%s`
- All file operations are POSIX-compliant
