# Secrets and ids

Names and places only. A value is never written in a file, in memory or in chat. The owner creates each one and pastes it once into GitHub. The full click-by-click steps are in the game repo's `docs/setup-guide.md` step 8.

## GitHub Actions secrets (game repo > Settings > Secrets and variables > Actions > Secrets)
| Name | What it is | Used by |
|---|---|---|
| `ROBLOX_PUBLISH_KEY` | Open Cloud API key for this experience | `publish`, `restart-servers`, `flags`, and `upload-asset` and `asset-permissions` when there is no group key |
| `ROBLOX_GROUP_KEY` | Optional. Open Cloud key created under the group, with `asset:read`, `asset:write` and `asset-permissions:write` only | `upload-asset` and `asset-permissions` for a group-owned game |

## Repo variables (same page, Variables tab; not secret)
| Name | Value | What it does |
|---|---|---|
| `ROBLOX_UNIVERSE_ID` | the experience id | tells the workflows which game |
| `ROBLOX_PLACE_ID` | the start place id | tells publish which place |
| `AUTO_PUBLISH` | `true` once wanted | every passing merge to main publishes itself to new servers |
| `ROBLOX_GROUP_ID` | the group id, when a group owns the game | `upload-asset` makes the group the owner of each upload |
| `ROBLOX_OWNER_USER_ID` | the owner's Roblox user id, when no group owns the game | `upload-asset` makes that user the owner |
| `AUTO_RESTART` | leave unset | set to `true`, every automatic publish also restarts servers, which disconnects players |

## Scopes for the publish key
Give the key only what the workflows use: `universe-places` Write (publish), `universe:write` (restart), and `universe-datastores.objects` read, create, update and delete (live switches), plus `universe-messaging-service:publish` for the in-game restart countdown. Accepted IPs `0.0.0.0/0`, because GitHub runners have no fixed address. Add a scope only when a new workflow needs it. Why: a leaked key can do only what it was given.

## The owner holds these themselves
Roblox, Creator Hub, ads, Buffer and social logins. Threads use the owner's signed-in browser only when the owner says so, and never type a password or a code.

## Ids that are not secret
Universe id, place id and group id can be written in memory and in the project instructions. If the game repo is public, player names, user ids and money numbers still stay out of it.

## If a secret leaks
Tell the owner at once in one line. The owner deletes the key in Creator Hub, makes a new one and replaces the GitHub secret. Then find how it leaked and remove the copy.
