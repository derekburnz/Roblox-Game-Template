#!/usr/bin/env bash
# Upload one picture or sound to Roblox (Open Cloud Assets API) and print its asset id, so a thread can put
# rbxassetid://<id> in the code without Studio's Asset Manager. Every run makes a new asset (they cannot be
# updated), so upload a file once and commit its id. Roblox moderates each upload; until it is approved a picture
# draws blank and a sound is silent.
# Run by .github/workflows/upload-asset.yml; also works from Git Bash on a PC with the same variables set.
#
#   ROBLOX_UPLOAD_KEY       Open Cloud API key with asset:read and asset:write, created by the account or group that
#                           will own the asset (docs/setup-guide.md step 8)
#   ROBLOX_CREATOR_USER_ID  the user that owns the asset, or
#   ROBLOX_CREATOR_GROUP_ID the group that owns it (wins when both are set). When a group owns the game, use the
#                           group: a sound a user owns does not play in a group's game unless it is shared with it
#                           (asset-permissions.sh).
#   ASSET_TYPE              Image (default: ImageLabel.Image, textures), Decal (a part via the Toolbox) or Audio
#
# Usage:  upload-asset.sh <file> [name on Roblox, default the file name without extension]
# Pictures: .png .jpg .jpeg .bmp .tga, 20 MB at most. Sounds: .mp3 .ogg .wav .flac, 20 MB and 7 minutes at most;
# audio uploads count against the owner's monthly allowance.
# Needs curl and jq (both on GitHub's ubuntu runners).
set -euo pipefail

FILE=${1:?asset file}
NAME=${2:-}
NAME=${NAME:-$(basename "${FILE%.*}")}
TYPE=${ASSET_TYPE:-Image}
: "${ROBLOX_UPLOAD_KEY:?set ROBLOX_UPLOAD_KEY (docs/setup-guide.md step 8)}"
if [ -z "${ROBLOX_CREATOR_GROUP_ID:-}" ] && [ -z "${ROBLOX_CREATOR_USER_ID:-}" ]; then
	echo "set ROBLOX_CREATOR_GROUP_ID or ROBLOX_CREATOR_USER_ID (who owns the upload)" >&2
	exit 2
fi
CREATOR=${ROBLOX_CREATOR_GROUP_ID:-${ROBLOX_CREATOR_USER_ID:-}}
API=https://apis.roblox.com/assets/v1

ext=$(printf '%s' "${FILE##*.}" | tr '[:upper:]' '[:lower:]')
case "$TYPE" in
Image | Decal)
	case "$ext" in
	png) ctype=image/png ;;
	jpg | jpeg) ctype=image/jpeg ;;
	bmp) ctype=image/bmp ;;
	tga) ctype=image/tga ;;
	*)
		echo "Pictures must be .png, .jpg, .bmp or .tga, got: $FILE" >&2
		exit 2
		;;
	esac
	;;
Audio)
	case "$ext" in
	mp3) ctype=audio/mpeg ;;
	ogg) ctype=audio/ogg ;;
	wav) ctype=audio/wav ;;
	flac) ctype=audio/flac ;;
	*)
		echo "Sounds must be .mp3, .ogg, .wav or .flac, got: $FILE" >&2
		exit 2
		;;
	esac
	;;
*)
	echo "ASSET_TYPE must be Image, Decal or Audio, got: $TYPE" >&2
	exit 2
	;;
esac

[ -f "$FILE" ] || {
	echo "no such file: $FILE" >&2
	exit 2
}
[ "$(wc -c <"$FILE")" -le $((20 * 1024 * 1024)) ] || {
	echo "$FILE is over Open Cloud's 20 MB limit" >&2
	exit 2
}

reply=$(mktemp)
trap 'rm -f "$reply"' EXIT
# call url [curl args...] -> sets $status and $body. Roblox answers 5xx or 429 now and then, so those get three
# more tries over about half a minute. A retried upload that went through anyway leaves one unused asset behind.
call() {
	local url=$1 wait
	shift
	for wait in 5 10 20 0; do
		status=$(curl -sS -o "$reply" -w '%{http_code}' "$url" -H "x-api-key: $ROBLOX_UPLOAD_KEY" "$@") || status=000
		case "$status" in
		5?? | 429 | 000) ;;
		*) break ;;
		esac
		[ "$wait" = 0 ] && break
		echo "Open Cloud answered HTTP $status; trying again in ${wait}s." >&2
		sleep "$wait"
	done
	body=$(cat "$reply")
	if [ "$status" != 200 ]; then
		echo "Open Cloud answered HTTP $status: $body" >&2
		case "$status" in
		401 | 403) echo "The key needs asset:read and asset:write, created by the owner $CREATOR (docs/setup-guide.md step 8)." >&2 ;;
		esac
		exit 1
	fi
}

if [ -n "${ROBLOX_CREATOR_GROUP_ID:-}" ]; then
	request=$(jq -cn --arg type "$TYPE" --arg name "$NAME" --arg group "$ROBLOX_CREATOR_GROUP_ID" \
		'{assetType: $type, displayName: $name, description: $name, creationContext: {creator: {groupId: $group}}}')
else
	request=$(jq -cn --arg type "$TYPE" --arg name "$NAME" --arg creator "$CREATOR" \
		'{assetType: $type, displayName: $name, description: $name, creationContext: {creator: {userId: $creator}}}')
fi
call "$API/assets" -X POST --form-string "request=$request" -F "fileContent=@\"$FILE\";type=$ctype"
operation=$(jq -r '.operationId // (.path // "" | sub("^operations/"; ""))' <<<"$body")
[ -n "$operation" ] || {
	echo "Open Cloud gave no operation for the upload: $body" >&2
	exit 1
}

# The upload finishes in the background; Roblox's pattern is to poll with growing waits.
deadline=$((SECONDS + 300))
wait=1
while :; do
	call "$API/operations/$operation"
	[ "$(jq -r '.done // false' <<<"$body")" = true ] && break
	if [ "$SECONDS" -gt "$deadline" ]; then
		echo "Gave up waiting for operation $operation; check it again later." >&2
		exit 1
	fi
	sleep "$wait"
	[ "$wait" -ge 16 ] || wait=$((wait * 2))
done
if [ "$(jq -r 'has("error")' <<<"$body")" = true ]; then
	echo "Roblox refused the upload: $(jq -c .error <<<"$body")" >&2
	exit 1
fi

id=$(jq -r '.response.assetId' <<<"$body")
moderation=$(jq -r '.response.moderationResult.moderationState // "unknown"' <<<"$body")
echo "Uploaded $FILE as $TYPE $id: rbxassetid://$id (moderation: $moderation)"
case "$moderation" in
*Rejected* | *REJECTED*)
	echo "Roblox moderation rejected it." >&2
	exit 1
	;;
*Approved* | *APPROVED*) ;;
*) echo "It draws blank (or plays silent) until moderation approves it, usually within minutes." ;;
esac
if [ -n "${GITHUB_OUTPUT:-}" ]; then
	echo "asset_id=$id" >>"$GITHUB_OUTPUT"
fi
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
	echo "- \`$FILE\` uploaded as $TYPE **$id**: \`rbxassetid://$id\` (moderation: $moderation)" >>"$GITHUB_STEP_SUMMARY"
fi
