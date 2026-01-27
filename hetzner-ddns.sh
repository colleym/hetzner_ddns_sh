#!/bin/sh
#
# hetzner-ddns - Dynamic DNS updater for Hetzner DNS API
# https://github.com/YOUR_USERNAME/hetzner-ddns
#

set -e
trap 'log "ERROR at line $LINENO: exit code $?"' ERR

# --- SCRIPT DIRECTORY ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- LOAD CONFIG ---
CONFIG_FILE="${SCRIPT_DIR}/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.sh not found. Copy config.example.sh to config.sh and edit it."
    exit 1
fi
. "$CONFIG_FILE"
# Note: "Config loaded" is logged in main() after log function is defined

# --- DEFAULTS ---
DATA_DIR="${DATA_DIR:-$SCRIPT_DIR}"
LOG_FILE="${LOG_FILE:-$DATA_DIR/hetzner-ddns.log}"
IP_CACHE_FILE="${DATA_DIR}/.ip_cache"
MAX_LOG_SIZE="${MAX_LOG_SIZE:-512000}"
CURL="${CURL:-/usr/bin/curl}"
DRY_RUN="${DRY_RUN:-false}"

# --- PARSE ARGUMENTS ---
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN="true" ;;
        --help|-h)
            echo "Usage: $0 [--dry-run]"
            echo "  --dry-run  Show what would be done without making changes"
            exit 0
            ;;
    esac
done

# --- LOGGING ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
    [ "$DRY_RUN" = "true" ] && echo "[DRY-RUN] $1"
}

log_rotate() {
    if [ -f "$LOG_FILE" ]; then
        FILE_SIZE=$(ls -l "$LOG_FILE" 2>/dev/null | awk '{print $5}')
        if [ "${FILE_SIZE:-0}" -ge "$MAX_LOG_SIZE" ]; then
            mv "$LOG_FILE" "$LOG_FILE.old"
            log "Log rotated (limit: $MAX_LOG_SIZE bytes)"
        fi
    fi
}

# --- IP DETECTION ---
get_ipv4() {
    $CURL -4 -s --max-time 10 https://api.ipify.org 2>/dev/null || \
    $CURL -4 -s --max-time 10 https://ipv4.icanhazip.com 2>/dev/null || \
    echo ""
}

get_ipv6() {
    $CURL -6 -s --max-time 10 https://api64.ipify.org 2>/dev/null || \
    $CURL -6 -s --max-time 10 https://ipv6.icanhazip.com 2>/dev/null || \
    echo ""
}

# --- CACHE MANAGEMENT ---
get_cached_ip() {
    local record_key="$1"
    if [ -f "$IP_CACHE_FILE" ]; then
        grep "^${record_key}=" "$IP_CACHE_FILE" 2>/dev/null | cut -d= -f2
    fi
}

set_cached_ip() {
    local record_key="$1"
    local ip="$2"

    # Remove old entry and add new one
    if [ -f "$IP_CACHE_FILE" ]; then
        grep -v "^${record_key}=" "$IP_CACHE_FILE" > "$IP_CACHE_FILE.tmp" 2>/dev/null || true
        mv "$IP_CACHE_FILE.tmp" "$IP_CACHE_FILE"
    fi
    echo "${record_key}=${ip}" >> "$IP_CACHE_FILE"
}

# --- HETZNER DNS UPDATE ---
update_hetzner_dns() {
    local record_name="$1"
    local record_type="$2"
    local ip="$3"

    if [ "$DRY_RUN" = "true" ]; then
        log "Would update ${record_name} (${record_type}) to ${ip}"
        return 0
    fi

    local response
    local comment="Updated by hetzner-ddns at $(date '+%Y-%m-%d %H:%M:%S')"

    response=$($CURL -s -X POST \
        "https://api.hetzner.cloud/v1/zones/${ZONE_ID}/rrsets/${record_name}/${record_type}/actions/set_records" \
        -H "Authorization: Bearer ${HETZNER_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"records\": [
                {
                    \"value\": \"${ip}\",
                    \"comment\": \"${comment}\"
                }
            ]
        }" 2>&1)

    if echo "$response" | grep -q "\"records\":"; then
        log "DNS updated: ${record_name} (${record_type}) -> ${ip}"
        return 0
    else
        log "DNS update failed: ${record_name} (${record_type}) - Response: ${response}"
        return 1
    fi
}

# --- NOTIFICATION ---
send_notification() {
    local old_ip="$1"
    local new_ip="$2"
    local record_name="$3"
    local record_type="$4"

    [ "$NOTIFY_PROVIDER" = "none" ] && return 0
    [ -z "$NOTIFY_PROVIDER" ] && return 0

    local provider_script="${SCRIPT_DIR}/providers/notify_${NOTIFY_PROVIDER}.sh"
    if [ ! -f "$provider_script" ]; then
        log "Warning: Notification provider '${NOTIFY_PROVIDER}' not found"
        return 1
    fi

    # Export variables for provider
    export OLD_IP="$old_ip"
    export CURRENT_IP="$new_ip"
    export RECORD_NAME="$record_name"
    export RECORD_TYPE="$record_type"
    export CURL

    if [ "$DRY_RUN" = "true" ]; then
        log "Would send notification via ${NOTIFY_PROVIDER}"
        return 0
    fi

    if . "$provider_script"; then
        log "Notification sent via ${NOTIFY_PROVIDER}"
        return 0
    else
        log "Notification failed via ${NOTIFY_PROVIDER}"
        return 1
    fi
}

# --- UPTIME KUMA HEARTBEAT ---
send_heartbeat() {
    [ "$UPTIME_KUMA_ENABLED" != "true" ] && return 0
    [ -z "$UPTIME_KUMA_URL" ] && return 0

    if [ "$DRY_RUN" = "true" ]; then
        log "Would send Uptime Kuma heartbeat"
        return 0
    fi

    $CURL -s -o /dev/null --max-time 10 "$UPTIME_KUMA_URL" 2>/dev/null && \
        log "Uptime Kuma heartbeat sent" || \
        log "Uptime Kuma heartbeat failed"
}

# --- MAIN ---
main() {
    log "Script started"
    log_rotate
    log "Config loaded"

    # Send heartbeat first (proves script is running)
    send_heartbeat

    # Validate config
    if [ -z "$HETZNER_TOKEN" ] || [ -z "$ZONE_ID" ] || [ -z "$RECORDS" ]; then
        log "Error: HETZNER_TOKEN, ZONE_ID, and RECORDS must be set"
        exit 1
    fi

    # Get current IPs
    log "Detecting IP addresses..."
    local ipv4 ipv6
    ipv4=$(get_ipv4)
    ipv6=$(get_ipv6)

    [ -z "$ipv4" ] && [ -z "$ipv6" ] && {
        log "Error: Could not detect any IP address"
        exit 1
    }

    [ -n "$ipv4" ] && log "Detected IPv4: $ipv4"
    [ -n "$ipv6" ] && log "Detected IPv6: $ipv6"

    # Process each record
    local updates_made=0
    for record in $RECORDS; do
        local name type ip cache_key cached_ip
        name=$(echo "$record" | cut -d: -f1)
        type=$(echo "$record" | cut -d: -f2)

        # Select IP based on record type
        case "$type" in
            A|a)     ip="$ipv4"; type="A" ;;
            AAAA|aaaa) ip="$ipv6"; type="AAAA" ;;
            *)
                log "Warning: Unknown record type '$type' for '$name', skipping"
                continue
                ;;
        esac

        [ -z "$ip" ] && {
            log "Warning: No ${type} address available for ${name}, skipping"
            continue
        }

        cache_key="${name}_${type}"
        cached_ip=$(get_cached_ip "$cache_key")

        if [ "$ip" = "$cached_ip" ]; then
            log "No change for ${name} (${type}): ${ip}"
            continue
        fi

        log "IP change detected for ${name} (${type}): ${cached_ip:-unknown} -> ${ip}"

        if update_hetzner_dns "$name" "$type" "$ip"; then
            set_cached_ip "$cache_key" "$ip"
            send_notification "$cached_ip" "$ip" "$name" "$type"
            updates_made=$((updates_made + 1))
        fi
    done

    [ $updates_made -eq 0 ] && log "No updates needed"
    log "Script finished"
}

main "$@"
