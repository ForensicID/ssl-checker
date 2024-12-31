#!/bin/bash

# Bot Telegram Token && Chat ID
TELEGRAM_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
# Domain or SubDomain List
DOMAIN_LIST_FILE="domains.txt"

send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$message"
}
get_ssl_expiry_date() {
    local domain="$1"
    local expiry_date
    expiry_date=$(curl -vI "https://$domain" 2>&1 | grep -i "expire date" | sed -E 's/.*expire date: (.*)$/\1/' | tr -d '\r')
    echo "$expiry_date"
}
check_ssl_expiry() {
    local domain="$1"
    local expiry_date
    expiry_date=$(get_ssl_expiry_date "$domain")
    if [ -z "$expiry_date" ]; then
        send_telegram_message "Cannot find the SSL certificate / expiration date not found from $domain"
        return
    fi
    local expiry_epoch
    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
    local current_epoch
    current_epoch=$(date +%s)
    local days_left
    days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
    if [[ "$days_left" =~ ^[0-9]+$ ]]; then
        if [ "$days_left" -eq 1 ]; then
            local message="🔥Danger🔥%0ASSL Certificate for $domain%0Awill be expired tomorrow!!!%0A($expiry_date)"
            send_telegram_message "$message"
        elif [ "$days_left" -eq 30 ]; then
            local message="⚠️Warning⚠️%0ASSL Certificate for $domain%0Awill expire in 30 days!%0A($expiry_date)"
            send_telegram_message "$message"
        fi
    fi
}
if [ -f "$DOMAIN_LIST_FILE" ]; then
    while IFS= read -r domain; do
        if [[ -n "$domain" && "$domain" != \#* ]]; then
            check_ssl_expiry "$domain"
        fi
    done < "$DOMAIN_LIST_FILE"
else
    send_telegram_message "File $DOMAIN_LIST_FILE not found!"
fi