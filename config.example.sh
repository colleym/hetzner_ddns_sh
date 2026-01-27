# hetzner-ddns configuration
# Copy this file to config.sh and edit it

# =============================================================================
# REQUIRED: Hetzner Cloud DNS API
# =============================================================================

# API Token from Hetzner Cloud Console (https://console.hetzner.cloud/)
# Go to: Project -> Security -> API Tokens -> Generate API Token
HETZNER_TOKEN=""

# Zone ID (found via Hetzner Cloud API: GET /v1/zones)
ZONE_ID=""

# Records to update - format: "name:type" (space-separated for multiple)
# Examples:
#   "dyndns:A"                     - Single IPv4 record
#   "dyndns:AAAA"                  - Single IPv6 record
#   "dyndns:A dyndns:AAAA"         - Dual-stack (IPv4 + IPv6)
#   "home:A vpn:A nas:A"           - Multiple subdomains
#   "@:A"                          - Root domain
RECORDS="dyndns:A"

# =============================================================================
# OPTIONAL: Uptime Kuma Push Monitor
# =============================================================================

UPTIME_KUMA_ENABLED="false"
UPTIME_KUMA_URL=""

# =============================================================================
# OPTIONAL: Notifications
# =============================================================================

# Provider: none | brevo | smtp | mailgun
NOTIFY_PROVIDER="none"

# Recipient email(s) - comma-separated for multiple
NOTIFY_RECIPIENTS=""

# --- Brevo (formerly Sendinblue) ---
BREVO_API_KEY=""
BREVO_SENDER_EMAIL=""
BREVO_SENDER_NAME="Hetzner DynDNS"

# --- SMTP ---
SMTP_HOST=""
SMTP_PORT="587"
SMTP_USER=""
SMTP_PASS=""
SMTP_FROM=""
SMTP_STARTTLS="true"

# --- Mailgun ---
MAILGUN_API_KEY=""
MAILGUN_DOMAIN=""
MAILGUN_FROM=""
MAILGUN_REGION="us"  # us | eu

# =============================================================================
# OPTIONAL: Paths (auto-detected if empty)
# =============================================================================

# Data directory for cache and logs
DATA_DIR=""

# Log file path
LOG_FILE=""

# Maximum log file size in bytes before rotation (default: 512KB)
MAX_LOG_SIZE=512000

# Full path to curl (useful for restricted environments like Synology)
# Leave empty for auto-detection
CURL=""
