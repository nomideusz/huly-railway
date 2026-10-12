#!/bin/bash
# Starts Huly's processes on localhost plus Caddy on $PORT. If any of them exits,
# the container exits and Railway restarts the lot.
set -euo pipefail

for v in SERVER_SECRET PUBLIC_URL DB_URL FULLTEXT_DB_URL QUEUE_CONFIG; do
	[[ -n "${!v:-}" ]] || { echo "run.sh: $v is not set" >&2; exit 1; }
done
PUBLIC_URL=${PUBLIC_URL%/}
WS_URL=${PUBLIC_URL/#http/ws} # https -> wss, http -> ws

# One Railway bucket holds every workspace (Huly's rootBucket mode puts each workspace
# under its own prefix). Credentials are URL-encoded since STORAGE_CONFIG is a URL.
if [[ -z "${STORAGE_CONFIG:-}" ]]; then
	STORAGE_CONFIG=$(node -e '
		const e = encodeURIComponent, v = process.env
		for (const k of ["S3_ENDPOINT", "S3_ACCESS_KEY", "S3_SECRET_KEY", "S3_BUCKET"])
			if (!v[k]) { console.error(`run.sh: ${k} is not set`); process.exit(1) }
		console.log(`s3|${v.S3_ENDPOINT}?accessKey=${e(v.S3_ACCESS_KEY)}&secretKey=${e(v.S3_SECRET_KEY)}` +
			`&region=${e(v.S3_REGION || "auto")}&rootBucket=${e(v.S3_BUCKET)}`)')
fi

ACCOUNTS=http://127.0.0.1:3000
STATS=http://127.0.0.1:4900
TRANSACTOR_URL="ws://127.0.0.1:3333;$WS_URL/_transactor" # internal;public
COMMON=(
	SERVER_SECRET="$SERVER_SECRET" STATS_URL=$STATS STORAGE_CONFIG="$STORAGE_CONFIG"
	DB_URL="$DB_URL" QUEUE_CONFIG="$QUEUE_CONFIG" FRONT_URL="$PUBLIC_URL"
)

start() { # name, then env assignments and the node command
	local name=$1; shift
	(cd /opt/huly/$name && exec env -u PORT "${COMMON[@]}" "$@" 2>&1 | sed -u "s/^/[$name] /") &
}

start stats PORT=4900 node bundle.js
start account ACCOUNT_PORT=3000 ACCOUNTS_URL="$PUBLIC_URL/_accounts" \
	TRANSACTOR_URL="$TRANSACTOR_URL" MODEL_ENABLED='*' \
	DISABLE_SIGNUP="${DISABLE_SIGNUP:-false}" ADMIN_EMAILS="${ADMIN_EMAILS:-}" node bundle.js
start transactor SERVER_PORT=3333 ACCOUNTS_URL=$ACCOUNTS \
	FULLTEXT_URL=http://127.0.0.1:4700 LAST_NAME_FIRST="${LAST_NAME_FIRST:-true}" node bundle.js
start workspace ACCOUNTS_URL=$ACCOUNTS ACCOUNTS_DB_URL="$DB_URL" FULLTEXT_URL=http://127.0.0.1:4700 TRANSACTOR_URL="$TRANSACTOR_URL" \
	MODEL_ENABLED='*' ADMIN_EMAILS="${ADMIN_EMAILS:-}" node bundle.js
start collaborator COLLABORATOR_PORT=3078 SECRET="$SERVER_SECRET" ACCOUNTS_URL=$ACCOUNTS node bundle.js
start fulltext PORT=4700 FULLTEXT_DB_URL="$FULLTEXT_DB_URL" ELASTIC_INDEX_NAME=huly_storage_index \
	REKONI_URL=http://127.0.0.1:4004 ACCOUNTS_URL=$ACCOUNTS node --expose-gc bundle.js
start rekoni SECRET="$SERVER_SECRET" node bundle.js
start front SERVER_PORT=8080 ACCOUNTS_URL="$PUBLIC_URL/_accounts" ACCOUNTS_URL_INTERNAL=$ACCOUNTS \
	REKONI_URL="$PUBLIC_URL/_rekoni" STATS_URL="$PUBLIC_URL/_stats" COLLABORATOR_URL="$WS_URL/_collaborator" \
	CALENDAR_URL="$PUBLIC_URL/_calendar" GMAIL_URL="$PUBLIC_URL/_gmail" TELEGRAM_URL="$PUBLIC_URL/_telegram" \
	UPLOAD_URL=/files TITLE="${TITLE:-Huly}" DEFAULT_LANGUAGE="${DEFAULT_LANGUAGE:-en}" \
	LAST_NAME_FIRST="${LAST_NAME_FIRST:-true}" DESKTOP_UPDATES_CHANNEL="$HULY_VERSION" \
	DISABLED_FEATURES=auto-translate,mailboxes DISABLE_SIGNUP="${DISABLE_SIGNUP:-false}" node bundle.js
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

trap 'exit 0' TERM INT # PID 1 exiting stops the container and every child with it
wait -n || true
echo "run.sh: a Huly process exited, restarting the container" >&2
exit 1
