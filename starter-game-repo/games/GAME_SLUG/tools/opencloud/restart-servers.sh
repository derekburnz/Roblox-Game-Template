#!/usr/bin/env bash
# Move every running server onto the newest published version (Open Cloud's Restart Universe Servers, the same
# as Creator Hub's "Restart servers for updates"; it does nothing when every server already runs the newest).
# A publish alone only reaches new servers. Players in running servers are disconnected by a restart, so this
# runs only when the owner says so.
#
#   ROBLOX_PUBLISH_KEY   Open Cloud API key that also has universe Write on the experience
#   UNIVERSE_ID          the experience id (not secret)
set -euo pipefail

: "${ROBLOX_PUBLISH_KEY:?set ROBLOX_PUBLISH_KEY (docs/setup-guide.md step 8)}"
: "${UNIVERSE_ID:?set UNIVERSE_ID to the experience id}"

# Roblox answers 5xx or 429 now and then, so those get three more tries over about half a minute.
for wait in 5 10 20 0; do
	response=$(curl -sS -w '\n%{http_code}' -X POST \
		"https://apis.roblox.com/cloud/v2/universes/$UNIVERSE_ID:restartServers" \
		-H "x-api-key: $ROBLOX_PUBLISH_KEY" \
		-H "Content-Type: application/json" \
		--data '{}') || response=$'\n000'
	status=${response##*$'\n'}
	body=${response%$'\n'*}
	case "$status" in
	5?? | 429 | 000) ;;
	*) break ;;
	esac
	[ "$wait" = 0 ] && break
	echo "Open Cloud answered HTTP $status; trying again in ${wait}s." >&2
	sleep "$wait"
done

if [ "$status" != 200 ]; then
	echo "Open Cloud answered HTTP $status: $body" >&2
	echo "Any new version is still live; only the restart of the running servers failed." >&2
	case "$status" in
	401 | 403) echo "The key needs universe Write on universe $UNIVERSE_ID, or press Restart servers for updates in Creator Hub." >&2 ;;
	esac
	exit 1
fi

echo "Asked Roblox to move the running servers of universe $UNIVERSE_ID onto the newest version."
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
	echo "- Running servers restarted onto the newest version" >>"$GITHUB_STEP_SUMMARY"
fi
