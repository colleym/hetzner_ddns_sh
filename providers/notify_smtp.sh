# Generic SMTP notification provider (via curl)
# Required env vars: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
# Required env vars: NOTIFY_RECIPIENTS, OLD_IP, CURRENT_IP, RECORD_NAME, RECORD_TYPE

[ -z "$SMTP_HOST" ] && { echo "SMTP_HOST not set"; exit 1; }
[ -z "$SMTP_FROM" ] && { echo "SMTP_FROM not set"; exit 1; }
[ -z "$NOTIFY_RECIPIENTS" ] && { echo "NOTIFY_RECIPIENTS not set"; exit 1; }

SMTP_PORT="${SMTP_PORT:-587}"
SMTP_STARTTLS="${SMTP_STARTTLS:-true}"

# Build recipient list for curl
RCPT_ARGS=""
IFS=','
for email in $NOTIFY_RECIPIENTS; do
    email=$(echo "$email" | tr -d ' ')
    [ -z "$email" ] && continue
    RCPT_ARGS="${RCPT_ARGS} --mail-rcpt ${email}"
done
unset IFS

SUBJECT="IP Change: ${RECORD_NAME} (${RECORD_TYPE}) -> ${CURRENT_IP}"
DATE=$(date -R 2>/dev/null || date)

# Create email content
EMAIL_CONTENT="From: ${SMTP_FROM}
To: ${NOTIFY_RECIPIENTS}
Subject: ${SUBJECT}
Date: ${DATE}
Content-Type: text/plain; charset=utf-8

Dynamic DNS Update
==================

Record: ${RECORD_NAME} (${RECORD_TYPE})
Old IP: ${OLD_IP:-unknown}
New IP: ${CURRENT_IP}

Updated by hetzner-ddns
"

# Build curl command
CURL_ARGS="--url smtp://${SMTP_HOST}:${SMTP_PORT}"
[ "$SMTP_STARTTLS" = "true" ] && CURL_ARGS="${CURL_ARGS} --ssl-reqd"
[ -n "$SMTP_USER" ] && CURL_ARGS="${CURL_ARGS} --user ${SMTP_USER}:${SMTP_PASS}"

# Send email
echo "$EMAIL_CONTENT" | $CURL -s $CURL_ARGS \
    --mail-from "$SMTP_FROM" \
    $RCPT_ARGS \
    -T - 2>&1

if [ $? -eq 0 ]; then
    exit 0
else
    echo "SMTP error" >&2
    exit 1
fi
