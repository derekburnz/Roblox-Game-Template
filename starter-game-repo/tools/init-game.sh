#!/usr/bin/env bash
# Fill in this starter repo for a new game. Run once, from the repo root, right after copying the starter in.
#
#   tools/init-game.sh <game-slug> <GamePrefix> "<Game Name>" <owner>/<game-repo>
#   example: tools/init-game.sh sky-farm SkyFarm "Sky Farm" someuser/sky-farm
#
#   game-slug    lower case with hyphens; becomes the folder games/<game-slug>/ and assets/<game-slug>/
#   GamePrefix   PascalCase code name; prefixes asset names and the DataStore names
#   Game Name    the name players see (a working title is fine; change it later in the docs)
#   owner/repo   the GitHub repo this game lives in
#
# It renames games/GAME_SLUG, moves dot-claude/ to .claude/ and replaces the placeholder tokens in every text file. Third-party skill
# folders hold none of the tokens, so they are left exactly as shipped. Safe to read before running:
# it only renames one folder and edits text inside this repo.
set -euo pipefail

SLUG=${1:?game slug, for example sky-farm}
PREFIX=${2:?code prefix, for example SkyFarm}
NAME=${3:?game name, for example "Sky Farm"}
REPO=${4:?owner/repo, for example someuser/sky-farm}

case "$SLUG" in *[!a-z0-9-]* | "") echo "slug must be lower case letters, digits and hyphens" >&2; exit 2 ;; esac
case "$PREFIX" in *[!A-Za-z0-9]* | "") echo "prefix must be letters and digits only" >&2; exit 2 ;; esac
case "$REPO" in */*) ;; *) echo "repo must look like owner/name" >&2; exit 2 ;; esac
[ -d games/GAME_SLUG ] || { echo "games/GAME_SLUG not found: run from the repo root, once" >&2; exit 1; }

git_mv() { if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then git mv "$1" "$2"; else mv "$1" "$2"; fi; }
git_mv games/GAME_SLUG "games/$SLUG"
# The skills and agent definitions ship in dot-claude/ so the template can be edited freely. Claude reads
# them from .claude/, so they move there now.
if [ -d dot-claude ] && [ ! -e .claude ]; then git_mv dot-claude .claude; fi

esc() { printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'; }
S=$(esc "$SLUG") P=$(esc "$PREFIX") N=$(esc "$NAME") R=$(esc "$REPO")

grep -rIlE 'GAME_SLUG|GAME_PREFIX|<game-slug>|<GamePrefix>|<Game Name>|<owner>/<game-repo>' . \
	--exclude-dir=.git --exclude=init-game.sh | while IFS= read -r file; do
	sed -i \
		-e "s|GAME_SLUG|$S|g" -e "s|<game-slug>|$S|g" \
		-e "s|GAME_PREFIX|$P|g" -e "s|<GamePrefix>|$P|g" \
		-e "s|<Game Name>|$N|g" \
		-e "s|<owner>/<game-repo>|$R|g" "$file"
done

echo "Done: games/$SLUG, prefix $PREFIX, name \"$NAME\", repo $REPO."
echo "Next: cd games/$SLUG && ./check.sh, then commit. You may delete tools/init-game.sh."
