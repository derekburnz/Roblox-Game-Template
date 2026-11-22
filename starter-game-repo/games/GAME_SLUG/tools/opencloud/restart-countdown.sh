#!/usr/bin/env bash
# Warn everyone in game before the running servers restart: one cross-server message at each mark of the countdown
# (default 10 and 2 minutes, 30 seconds, then now), through Open Cloud MessagingService publishMessage on topic TOPIC.
# Every server subscribes to the topic (src/server/Services/RestartNoticeService.luau) and shows the line to its
# players as a toast, so nobody is cut off without notice. restart-servers.yml runs it before its restart; it also
# works from Git Bash with the same variables.
#
#   ROBLOX_PUBLISH_KEY   Open Cloud API key that also has universe-messaging-service:publish on the experience
#                        (docs/setup-guide.md step 8)
#   UNIVERSE_ID          the experience id
#   WARNINGS             seconds before the restart to warn at, largest first (default "600 120 30 0"). Fewer, calmer
#                        warnings are better: each one nudges some players to leave early.
#
# Each message is JSON text: {"kind":"restart","seconds":120}. The server writes the words players see
# (src/shared/RestartNotice.luau). Without the permission the first message is refused; the script then says so
# and returns at once, so a restart is never held up by a countdown nobody can hear.
set -euo pipefail

: "${UNIVERSE_ID:?set UNIVERSE_ID to the experience id}"
WARNINGS=${WARNINGS:-600 120 30 0}
TOPIC=GAME_PREFIX_Announce # must match RestartNotice.TOPIC in src/shared/RestartNotice.luau
: "${ROBLOX_PUBLISH_KEY:?set ROBLOX_PUBLISH_KEY (docs/setup-guide.md step 8)}"

read -ra marks <<<"$WARNINGS"
for mark in "${marks[@]}"; do
	[[ $mark =~ ^[0-9]+$ ]] || {
		echo "WARNINGS must be whole seconds, largest first, got: $WARNINGS" >&2
		exit 2
	}
done

# send seconds -> 0 when Roblox took it. Roblox answers 5xx or 429 now and then, so those get two more tries.
send() {
	local message status body wait response
	message=$(jq -nc --argjson s "$1" '{kind: "restart", seconds: $s}')
	for wait in 3 6 0; do
		response=$(curl -sS -w '\n%{http_code}' -X POST \
			"https://apis.roblox.com/cloud/v2/universes/$UNIVERSE_ID:publishMessage" \
			-H "x-api-key: $ROBLOX_PUBLISH_KEY" \
			-H "Content-Type: application/json" \
			--data "$(jq -nc --arg topic "$TOPIC" --arg message "$message" '{topic: $topic, message: $message}')") ||
			response=$'\n000'
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
	if [ "$status" = 200 ]; then
		echo "Warned every server: restart in $1 s."
		return 0
	fi
	echo "Open Cloud answered HTTP $status: $body" >&2
	case "$status" in
	401 | 403) echo "The key needs universe-messaging-service:publish on universe $UNIVERSE_ID (docs/setup-guide.md step 8)." >&2 ;;
	esac
	return 1
}

summary() { [ -z "${GITHUB_STEP_SUMMARY:-}" ] || echo "$1" >>"$GITHUB_STEP_SUMMARY"; }

previous=
for mark in "${marks[@]}"; do
	if [ -n "$previous" ] && [ "$previous" -gt "$mark" ]; then
		sleep $((previous - mark))
	fi
	if ! send "$mark"; then
		if [ -z "$previous" ]; then
			# Nobody was warned, so waiting out the countdown would only delay the update.
			echo "::warning::Players were not warned before the restart (see the log); restarting without the countdown."
			summary "- Restart countdown skipped: the key cannot send in-game messages yet (docs/setup-guide.md step 8)"
			exit 0
		fi
		echo "::warning::The $mark s warning did not go out; the countdown keeps its time."
	fi
	previous=$mark
done
summary "- Players warned at ${WARNINGS// /, } seconds before the restart"
