# Mailgun notification provider
# Required env vars: MAILGUN_API_KEY, MAILGUN_DOMAIN, MAILGUN_FROM
# Required env vars: NOTIFY_RECIPIENTS, OLD_IP, CURRENT_IP, RECORD_NAME, RECORD_TYPE

[ -z "$MAILGUN_API_KEY" ] && { echo "MAILGUN_API_KEY not set"; exit 1; }
[ -z "$MAILGUN_DOMAIN" ] && { echo "MAILGUN_DOMAIN not set"; exit 1; }
[ -z "$MAILGUN_FROM" ] && { echo "MAILGUN_FROM not set"; exit 1; }
[ -z "$NOTIFY_RECIPIENTS" ] && { echo "NOTIFY_RECIPIENTS not set"; exit 1; }

# Select API endpoint based on region
case "${MAILGUN_REGION:-us}" in
    eu) API_BASE="https://api.eu.mailgun.net" ;;
    *)  API_BASE="https://api.mailgun.net" ;;
esac

SUBJECT="IP Change: ${RECORD_NAME} (${RECORD_TYPE}) -> ${CURRENT_IP}"
TEXT_CONTENT="Dynamic DNS Update

Record: ${RECORD_NAME} (${RECORD_TYPE})
Old IP: ${OLD_IP:-unknown}
New IP: ${CURRENT_IP}

Updated by hetzner-ddns"

RESPONSE=$($CURL -s -X POST \
    "${API_BASE}/v3/${MAILGUN_DOMAIN}/messages" \
    -u "api:${MAILGUN_API_KEY}" \
    -F from="${MAILGUN_FROM}" \
    -F to="${NOTIFY_RECIPIENTS}" \
    -F subject="${SUBJECT}" \
    -F text="${TEXT_CONTENT}" 2>&1)

if echo "$RESPONSE" | grep -q "Queued\|id"; then
    exit 0
else
    echo "Mailgun error: $RESPONSE" >&2
    exit 1
fi
