#!/usr/bin/env bash
# One automerge step for one pull request (called by .github/workflows/automerge.yml).
#
# It merges, with a merge commit, only when all of these hold:
#   - the pull request is open, not a draft, based on main, labeled `automerge` and not labeled `on-hold`;
#   - every required check below passed on its newest commit (the commit is pinned in the merge call, so a push
#     that lands meanwhile makes GitHub refuse and that push's own checks come back here).
# A conflict with main, or GitHub refusing the merge, drops the label with a comment so the owning thread finishes
# by hand. Checks still running or failed: nothing happens; the next finished check run comes back here.
# A merge made with the workflow token starts no push workflows, so after merging this starts check.yml on main
# and, when the repo variable AUTO_PUBLISH is "true", publish.yml.
#
# Needs GH_TOKEN and GITHUB_REPOSITORY, plus PR_NUMBER (label event) or HEAD_BRANCH (a finished check run).
set -euo pipefail

REPO=${GITHUB_REPOSITORY:?}
LABEL=automerge
# The job names of check.yml, which main's ruleset requires (docs/setup-guide.md step 9).
REQUIRED=("Rojo sourcemap, luau-lsp, Selene, StyLua" "Unit tests, strict types, UI gate")

PR=${PR_NUMBER:-}
if [ -z "$PR" ]; then
	PR=$(gh pr list --repo "$REPO" --head "${HEAD_BRANCH:?}" --state open --json number --jq '.[0].number // empty')
	if [ -z "$PR" ]; then
		echo "No open pull request for branch $HEAD_BRANCH."
		exit 0
	fi
fi

pr=$(gh pr view "$PR" --repo "$REPO" --json state,isDraft,baseRefName,headRefOid,mergeable,labels)
has_label() { jq -e --arg l "$1" 'any(.labels[]; .name == $l)' <<<"$pr" >/dev/null; }

if [ "$(jq -r .state <<<"$pr")" != OPEN ] || ! has_label "$LABEL"; then
	echo "PR #$PR is not open or has no $LABEL label."
	exit 0
fi
if has_label on-hold || [ "$(jq -r .isDraft <<<"$pr")" = true ] || [ "$(jq -r .baseRefName <<<"$pr")" != main ]; then
	echo "PR #$PR is on hold, a draft or not based on main; automerge leaves it."
	exit 0
fi

# REST calls for the label and the comment: `gh pr edit` also reads project cards, which the workflow token cannot.
drop() {
	gh api -X DELETE "repos/$REPO/issues/$PR/labels/$LABEL" >/dev/null || true
	gh api "repos/$REPO/issues/$PR/comments" -f body="$1

The \`$LABEL\` label is off. Put it back after fixing, and the merge goes ahead once the checks pass.

---
_Posted by the automerge workflow (.github/scripts/automerge.sh)_" >/dev/null || true
	echo "Dropped the label: $1"
}

if [ "$(jq -r .mergeable <<<"$pr")" = CONFLICTING ]; then
	drop "Automerge stopped: this branch conflicts with main. Merge main in, resolve the conflict and push."
	exit 0
fi

head=$(jq -r .headRefOid <<<"$pr")
runs=$(gh api "repos/$REPO/commits/$head/check-runs?per_page=100" --paginate --jq '.check_runs[]' | jq -s .)
for name in "${REQUIRED[@]}"; do
	# the newest run of that name wins (a re-run leaves the older one in the list)
	line=$(jq -r --arg n "$name" '[.[] | select(.name == $n)] | sort_by(.started_at) | last // empty | "\(.status) \(.conclusion // "")"' <<<"$runs")
	if [ -z "$line" ]; then
		echo "No \"$name\" run on $head yet; waiting."
		exit 0
	fi
	if [ "$line" != "completed success" ]; then
		echo "\"$name\" on $head is $line; waiting for a green run."
		exit 0
	fi
done

if gh api -X PUT "repos/$REPO/pulls/$PR/merge" -f merge_method=merge -f sha="$head" >/dev/null; then
	echo "Merged PR #$PR at $head."
	gh workflow run check.yml --repo "$REPO" --ref main || true
	if [ "${AUTO_PUBLISH:-}" = true ]; then
		gh workflow run publish.yml --repo "$REPO" --ref main -f version_type=Published ||
			echo "::warning::Could not start publish.yml; run it by hand."
	fi
	exit 0
fi

# The head moved while we looked (its own checks come back here), or another run merged it first.
now=$(gh pr view "$PR" --repo "$REPO" --json state,headRefOid)
if [ "$(jq -r .state <<<"$now")" != OPEN ] || [ "$(jq -r .headRefOid <<<"$now")" != "$head" ]; then
	echo "PR #$PR was merged elsewhere or its head moved; nothing to do."
	exit 0
fi
drop "Automerge stopped: GitHub refused the merge. A pull request that changes .github/workflows has to be merged by hand (the workflow token may not), otherwise see this job's log."
