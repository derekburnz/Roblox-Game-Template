#!/usr/bin/env bash
# Read or change the live switches (src/shared/LiveFlags.luau) in their DataStore, so a feature can be turned on
# or off in every running server within about a minute, with no publish and no restart.
# Run by .github/workflows/flags.yml; also works from Git Bash with the same variables. Needs curl and jq.
#
#   ROBLOX_PUBLISH_KEY   Open Cloud key with universe-datastores.objects:read, :create and :update
#   UNIVERSE_ID          the experience id (not secret)
#
# Usage:  flags.sh show | set <switch> true|false | clear <switch>
#   clear deletes the entry, which puts the switch back at its default.
set -euo pipefail

: "${ROBLOX_PUBLISH_KEY:?set ROBLOX_PUBLISH_KEY (docs/setup-guide.md step 8)}"
: "${UNIVERSE_ID:?set UNIVERSE_ID to the experience id}"

LIVEFLAGS=${LIVEFLAGS:-$(dirname "$0")/../../src/shared/LiveFlags.luau}
[ -f "$LIVEFLAGS" ] || { echo "LiveFlags.luau not found at $LIVEFLAGS" >&2; exit 1; }
STORE=$(grep -oE '^LiveFlags\.STORE = "[A-Za-z0-9_]+"' "$LIVEFLAGS" | grep -oE '"[A-Za-z0-9_]+"' | tr -d '"')
[ -n "$STORE" ] || { echo "LiveFlags.STORE not found in $LIVEFLAGS" >&2; exit 1; }
mapfile -t KEYS < <(awk '/^LiveFlags.KEYS = \{/{on=1;next} on&&/^\}/{exit} on' "$LIVEFLAGS" | grep -o '^[[:space:]]*"[A-Za-z0-9]*"' | tr -d ' \t"')
mapfile -t OFF_KEYS < <(awk '/^LiveFlags.OFF_BY_DEFAULT = \{/{on=1;next} on&&/^\}/{exit} on' "$LIVEFLAGS" | grep -o '^[[:space:]]*[A-Za-z0-9]* = true' | awk '{print $1}')
[ "${#KEYS[@]}" -gt 0 ] || { echo "no switches read from $LIVEFLAGS" >&2; exit 1; }
entries=https://apis.roblox.com/cloud/v2/universes/$UNIVERSE_ID/data-stores/$STORE/entries

usage() {
	echo "usage: flags.sh show | set <switch> true|false | clear <switch>" >&2
	echo "switches (src/shared/LiveFlags.luau KEYS): ${KEYS[*]}" >&2
	exit 2
}
is_key() {
	local k
	for k in "${KEYS[@]}"; do [ "$k" = "$1" ] && return 0; done
	return 1
}
starts_off() {
	local k
	for k in "${OFF_KEYS[@]}"; do [ "$k" = "$1" ] && return 0; done
	return 1
}

reply=$(mktemp)
trap 'rm -f "$reply"' EXIT
call() {
	local method=$1 url=$2 wait
	shift 2
	for wait in 5 10 20 0; do
		status=$(curl -sS -o "$reply" -w '%{http_code}' -X "$method" "$url" -H "x-api-key: $ROBLOX_PUBLISH_KEY" "$@") ||
			status=000
		case "$status" in
		5?? | 429 | 000) ;;
		*) break ;;
		esac
		[ "$wait" = 0 ] && break
		echo "Open Cloud answered HTTP $status; trying again in ${wait}s." >&2
		sleep "$wait"
	done
	body=$(cat "$reply")
}
fail() {
	echo "Open Cloud answered HTTP $status: $body" >&2
	case "$status" in
	401 | 403) echo "The key needs universe-datastores.objects:read, :create and :update on universe $UNIVERSE_ID (docs/setup-guide.md step 8)." >&2 ;;
	esac
	exit 1
}

show_key() {
	local key=$1 raw meaning
	call GET "$entries/$key"
	if [ "$status" = 404 ]; then
		raw="(no entry)"
	elif [ "$status" = 200 ]; then
		raw=$(jq -c '.value' <<<"$body")
	else
		fail
	fi
	if starts_off "$key"; then
		if [ "$raw" = true ]; then meaning="ON in every server"; else meaning="off (its default)"; fi
	elif [ "$raw" = false ]; then
		meaning="OFF in every server"
	else
		meaning="on (its default)"
	fi
	echo "$key = $raw ($meaning)"
	[ -z "${GITHUB_STEP_SUMMARY:-}" ] || echo "- \`$key\` = \`$raw\`: $meaning" >>"$GITHUB_STEP_SUMMARY"
}

case "${1:-}" in
show)
	echo "== $STORE (servers pick a change up within about 60 s)"
	for key in "${KEYS[@]}"; do show_key "$key"; done
	;;
set)
	key=${2:-} value=${3:-}
	is_key "$key" || usage
	case "$value" in true | false) ;; *) usage ;; esac
	call PATCH "$entries/$key?allowMissing=true" -H "Content-Type: application/json" \
		--data "$(jq -cn --argjson v "$value" '{value: $v}')"
	[ "$status" = 200 ] || fail
	echo "Wrote $key = $value"
	show_key "$key"
	;;
clear)
	key=${2:-}
	is_key "$key" || usage
	call DELETE "$entries/$key"
	case "$status" in 200 | 204 | 404) ;; *) fail ;; esac
	echo "Cleared $key"
	show_key "$key"
	;;
*) usage ;;
esac
