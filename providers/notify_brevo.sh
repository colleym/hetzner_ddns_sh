# Brevo (formerly Sendinblue) notification provider
# Required env vars: BREVO_API_KEY, BREVO_SENDER_EMAIL, BREVO_SENDER_NAME
# Required env vars: NOTIFY_RECIPIENTS, OLD_IP, CURRENT_IP, RECORD_NAME, RECORD_TYPE

[ -z "$BREVO_API_KEY" ] && { echo "BREVO_API_KEY not set"; exit 1; }
[ -z "$BREVO_SENDER_EMAIL" ] && { echo "BREVO_SENDER_EMAIL not set"; exit 1; }
[ -z "$NOTIFY_RECIPIENTS" ] && { echo "NOTIFY_RECIPIENTS not set"; exit 1; }

# Build recipients JSON array
RECIPIENTS_JSON="["
first=true
IFS=','
for email in $NOTIFY_RECIPIENTS; do
    email=$(echo "$email" | tr -d ' ')
    [ -z "$email" ] && continue
    [ "$first" = "true" ] && first=false || RECIPIENTS_JSON="${RECIPIENTS_JSON},"
    RECIPIENTS_JSON="${RECIPIENTS_JSON}{\"email\":\"${email}\"}"
done
unset IFS
RECIPIENTS_JSON="${RECIPIENTS_JSON}]"

SUBJECT="IP Change: ${RECORD_NAME} (${RECORD_TYPE}) -> ${CURRENT_IP}"
HTML_CONTENT="<html><body>
<h3>Dynamic DNS Update</h3>
<p><strong>Record:</strong> ${RECORD_NAME} (${RECORD_TYPE})</p>
<p><strong>Old IP:</strong> ${OLD_IP:-unknown}</p>
<p><strong>New IP:</strong> ${CURRENT_IP}</p>
<p><em>Updated by hetzner-ddns</em></p>
</body></html>"

RESPONSE=$($CURL -s -X POST "https://api.brevo.com/v3/smtp/email" \
    -H "accept: application/json" \
    -H "api-key: $BREVO_API_KEY" \
    -H "content-type: application/json" \
    -d "{
        \"sender\": {
            \"name\": \"${BREVO_SENDER_NAME:-Hetzner DynDNS}\",
            \"email\": \"${BREVO_SENDER_EMAIL}\"
        },
        \"to\": ${RECIPIENTS_JSON},
        \"subject\": \"${SUBJECT}\",
        \"htmlContent\": \"${HTML_CONTENT}\"
    }" 2>&1)

if echo "$RESPONSE" | grep -q "messageId"; then
    exit 0
else
    echo "Brevo error: $RESPONSE" >&2
    exit 1
fi
