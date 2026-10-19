#!/usr/bin/env bash
# Sends one orchestrator message to the Hermes herdr-events webhook route.
set -euo pipefail

kind="" run="" text=""
while [ $# -gt 0 ]; do
  case "$1" in
    --kind) kind="$2"; shift 2 ;;
    --run)  run="$2";  shift 2 ;;
    --text) text="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$kind" in
  question|event|blocked|done) ;;
  *) echo "--kind must be question, event, blocked or done" >&2; exit 2 ;;
esac
[ -n "$run" ] && [ -n "$text" ] || { echo "--run and --text are required" >&2; exit 2; }
: "${HERDR_TG_WEBHOOK_URL:?HERDR_TG_WEBHOOK_URL is not set}"
: "${HERDR_TG_SECRET_FILE:?HERDR_TG_SECRET_FILE is not set}"

text=${text:0:3500}
body=$(jq -cn --arg k "$kind" --arg r "$run" --arg t "$text" '{kind:$k, run:$r, text:$t}')
ts=$(date +%s)
sig=$(printf '%s.%s' "$ts" "$body" \
  | openssl dgst -sha256 -hmac "$(cat "$HERDR_TG_SECRET_FILE")" \
  | sed 's/^.*= //')

curl -fsS -m 10 -X POST "$HERDR_TG_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -H "X-Webhook-Timestamp: $ts" \
  -H "X-Webhook-Signature-V2: $sig" \
  --data "$body" >/dev/null