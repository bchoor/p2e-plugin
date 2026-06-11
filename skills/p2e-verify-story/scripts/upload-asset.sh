#!/usr/bin/env bash
# upload-asset.sh — Vercel Blob signed-URL PUT helper for P2E UAT evidence uploads.
#
# USAGE:
#   upload-asset.sh <ticket.json> <local-file> [content_type]
#
# ARGUMENTS:
#   ticket.json   Path to the JSON file written from story_assets op=upload_url response.
#                 Must contain: client_token, upload_url, pathname.
#   local-file    Path to the file to upload (e.g. a PNG screenshot).
#   content_type  MIME type override (default: image/png). Pass e.g. image/jpeg, application/pdf.
#
# DESIGN — TOKEN-CARRY DISCIPLINE (P-07-L14):
#   The client_token in the ticket JSON is HMAC-signed. This script is the ONLY safe way to
#   use it: it reads token/url/pathname from the file via a JSON parser, never via shell
#   string interpolation of the token value by the model. The browser/evidence subagent
#   (sonnet/haiku) runs this script so bytes + token bypass the orchestrator/model context.
#
# This script does NOT call MCP and needs no p2e auth — the blob client_token authorises the PUT.
# Exits non-zero on any non-2xx HTTP response or missing input.

set -euo pipefail

TICKET_JSON="${1:-}"
LOCAL_FILE="${2:-}"
CONTENT_TYPE="${3:-image/png}"

# --- Validate inputs ---
if [[ -z "$TICKET_JSON" || -z "$LOCAL_FILE" ]]; then
  echo "ERROR: usage: upload-asset.sh <ticket.json> <local-file> [content_type]" >&2
  exit 1
fi
if [[ ! -f "$TICKET_JSON" ]]; then
  echo "ERROR: ticket JSON file not found: $TICKET_JSON" >&2
  exit 1
fi
if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "ERROR: local file not found: $LOCAL_FILE" >&2
  exit 1
fi

# --- Parse ticket JSON using python3 (never shell interpolation of the token) ---
# python3 is required; jq is used as fallback if python3 is unavailable.
if command -v python3 &>/dev/null; then
  CLIENT_TOKEN=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['client_token'])" "$TICKET_JSON")
  UPLOAD_URL=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['upload_url'])" "$TICKET_JSON")
  PATHNAME=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['pathname'])" "$TICKET_JSON")
elif command -v jq &>/dev/null; then
  CLIENT_TOKEN=$(jq -r '.client_token' "$TICKET_JSON")
  UPLOAD_URL=$(jq -r '.upload_url' "$TICKET_JSON")
  PATHNAME=$(jq -r '.pathname' "$TICKET_JSON")
else
  echo "ERROR: neither python3 nor jq is available — cannot parse ticket JSON safely" >&2
  exit 1
fi

if [[ -z "$CLIENT_TOKEN" || "$CLIENT_TOKEN" == "null" ]]; then
  echo "ERROR: client_token missing or null in $TICKET_JSON" >&2
  exit 1
fi
if [[ -z "$UPLOAD_URL" || "$UPLOAD_URL" == "null" ]]; then
  echo "ERROR: upload_url missing or null in $TICKET_JSON" >&2
  exit 1
fi
if [[ -z "$PATHNAME" || "$PATHNAME" == "null" ]]; then
  echo "ERROR: pathname missing or null in $TICKET_JSON" >&2
  exit 1
fi

# --- URL-encode pathname (slashes → %2F, spaces → %20, etc.) ---
if command -v python3 &>/dev/null; then
  ENCODED_PATHNAME=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$PATHNAME")
else
  # Minimal fallback: encode only forward slashes
  ENCODED_PATHNAME="${PATHNAME//\//%2F}"
fi

# --- Compute file size ---
FILE_SIZE=$(wc -c < "$LOCAL_FILE" | tr -d ' ')

# --- Write client_token to a temp file so it never appears as a shell argument ---
TOKEN_FILE=$(mktemp /tmp/upload-token-XXXXXX)
trap 'rm -f "$TOKEN_FILE"' EXIT
printf '%s' "$CLIENT_TOKEN" > "$TOKEN_FILE"

# --- Build the PUT URL ---
# Vercel Blob requires a trailing slash before the query string: /api/blob/?pathname=...
# Without the slash, the PUT returns 400 "Invalid client token" despite a valid token.
PUT_URL="${UPLOAD_URL}/?pathname=${ENCODED_PATHNAME}"

echo "Uploading: $LOCAL_FILE ($FILE_SIZE bytes) → $PATHNAME"
echo "PUT: $PUT_URL"

# --- Execute the verified 5-header PUT ---
# Authorization token is read via $(cat "$TOKEN_FILE") — value is in a file, not a model-generated arg.
HTTP_STATUS=$(curl -s -o /dev/null -w '%{http_code}' \
  -X PUT "$PUT_URL" \
  -H "Authorization: Bearer $(cat "$TOKEN_FILE")" \
  -H "x-api-version: 12" \
  -H "x-content-type: $CONTENT_TYPE" \
  -H "x-vercel-blob-access: private" \
  -H "x-content-length: $FILE_SIZE" \
  --upload-file "$LOCAL_FILE")

echo "HTTP status: $HTTP_STATUS"

if [[ "$HTTP_STATUS" =~ ^2 ]]; then
  echo "SUCCESS: asset uploaded — confirm with: story_assets op=list"
  exit 0
else
  echo "ERROR: upload failed with HTTP $HTTP_STATUS" >&2
  exit 1
fi
