#!/usr/bin/env bash
# generate-known-hashes.sh — Record the SHA-256 of every file this package shipped in each
# tagged release, so the installer can tell its own older files from the user's own work
# instead of guessing. See plans/011-release-hash-provenance.md.
#
# Output: .qa-instinct-known-hashes, one "<sha256>  <path>" per line, sorted and de-duplicated.
# The path is informational only — a file that moved between releases is still recognized by
# its hash. Format matches the manifest's portable rules: no BOM, LF endings, forward slashes.
#
# Sources: every tag in this repository, plus known-hashes-before-public.txt — the releases
# shipped before the public repository began, whose tags it does not have (plans/032). That
# file's first line is its state:
#   "# state: open"              rewritten here from the tags on every run;
#   "# state: sealed at <sha>"   written once at export, never rewritten; --check fails if it
#                                changes after the commit that sealed it.
# Its other "#" lines are comments and never reach .qa-instinct-known-hashes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_FILE="$SCRIPT_DIR/.qa-instinct-known-hashes"
FROZEN_NAME="known-hashes-before-public.txt"
FROZEN_FILE="$SCRIPT_DIR/$FROZEN_NAME"
OPEN_STATE="# state: open"
SEALED_PREFIX="# state: sealed at "

CHECK=false
if [ "${1:-}" = "--check" ]; then
    CHECK=true
elif [ $# -gt 0 ]; then
    echo "Usage: $(basename "$0") [--check]" >&2
    echo "  --check  Exit non-zero if $OUT_FILE or $FROZEN_NAME is out of date instead of writing it" >&2
    exit 1
fi

# sha256sum on Linux, shasum on macOS.
hash_stdin() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        shasum -a 256 | awk '{print $1}'
    fi
}

TMP="$(mktemp)"
TAGGED="$(mktemp)"
FROZEN_ENTRIES="$(mktemp)"
FROZEN_EXPECTED="$(mktemp)"
SORTED="$(mktemp)"
trap 'rm -f "$TMP" "$TAGGED" "$FROZEN_ENTRIES" "$FROZEN_EXPECTED" "$SORTED"' EXIT

TAG_COUNT=0
for TAG in $(git -C "$SCRIPT_DIR" tag --sort=v:refname); do
    # A tag that predates the .claude/ layout simply contributes nothing.
    # Only the folders the installer actually manages — a file it never installs could never
    # be the cause of a misattribution, and listing it would just invite adopting it later.
    FILES="$(git -C "$SCRIPT_DIR" ls-tree -r --name-only "$TAG" -- \
        .claude/commands .claude/rules .claude/skills .claude/agents .claude/hooks 2>/dev/null || true)"
    [ -n "$FILES" ] || continue
    TAG_COUNT=$((TAG_COUNT + 1))
    while IFS= read -r FILE; do
        [ -n "$FILE" ] || continue
        SHA="$(git -C "$SCRIPT_DIR" cat-file blob "$TAG:$FILE" | hash_stdin)"
        printf '%s  %s\n' "$SHA" "$FILE" >> "$TMP"
    done <<EOF
$FILES
EOF
done
sort -u "$TMP" > "$TAGGED"

# Once a commit has sealed the frozen file, it must stay exactly as that commit has it: it is
# the only record of what the earlier releases shipped, and nothing can rebuild it. This also
# refuses a file that was sealed and later reopened.
SEALED_IN=""
for COMMIT in $(git -C "$SCRIPT_DIR" log --reverse --format=%H -- "$FROZEN_NAME" 2>/dev/null); do
    case "$(git -C "$SCRIPT_DIR" show "$COMMIT:$FROZEN_NAME" 2>/dev/null | sed -n '1p')" in
        "$SEALED_PREFIX"*) SEALED_IN="$COMMIT"; break ;;
    esac
done
if [ -n "$SEALED_IN" ] && ! git -C "$SCRIPT_DIR" show "$SEALED_IN:$FROZEN_NAME" | cmp -s - "$FROZEN_FILE"; then
    echo "Error: $FROZEN_NAME was sealed in commit $SEALED_IN and has changed since." >&2
    echo "It is never rewritten. Restore it: git checkout $SEALED_IN -- $FROZEN_NAME" >&2
    exit 1
fi

STATE=""
[ ! -f "$FROZEN_FILE" ] || STATE="$(sed -n '1p' "$FROZEN_FILE")"

case "$STATE" in
    "$OPEN_STATE"|"")
        # Open (or not created yet): the file is exactly this repository's tags. Refuse to drop
        # an entry: a repository missing the tags it was built from (the public one, before the
        # export sealed the file) would otherwise erase the only record of those releases.
        DROPPED="$( (grep -v '^#' "$FROZEN_FILE" 2>/dev/null || true) | sort -u | comm -23 - "$TAGGED" | wc -l | tr -d ' ')"
        if [ "$DROPPED" -gt 0 ]; then
            echo "Error: $FROZEN_NAME is open, but $DROPPED of its entries are in no tag of this repository." >&2
            echo "Rewriting it would lose them. Without those tags, it must be sealed (plans/032, plan 020 part B)." >&2
            exit 1
        fi
        if [ ! -s "$TAGGED" ]; then
            echo "Error: no tag contains a .claude/ tree; refusing to write an empty hash list." >&2
            exit 1
        fi
        {
            echo "$OPEN_STATE"
            echo "# The SHA-256 of every file shipped by a tagged release of this package before its public"
            echo "# repository began, which has none of those tags. generate-known-hashes.sh merges these"
            echo "# entries into .qa-instinct-known-hashes, the only list the installers read. While the state"
            echo "# is open, the script rewrites this file from the tags; once sealed, never. See plans/032."
            cat "$TAGGED"
        } > "$FROZEN_EXPECTED"
        cp "$TAGGED" "$FROZEN_ENTRIES"
        ;;
    "$SEALED_PREFIX"*)
        grep -v '^#' "$FROZEN_FILE" > "$FROZEN_ENTRIES" || true
        BAD="$(grep -Ev '^[0-9a-f]{64}  [^ ].*$' "$FROZEN_ENTRIES" | head -n 1 || true)"
        if [ -n "$BAD" ] || grep -q "$(printf '\r')" "$FROZEN_FILE"; then
            echo "Error: $FROZEN_NAME has a line that is not \"<sha256>  <path>\": ${BAD:-a CR line ending}" >&2
            exit 1
        fi
        if [ ! -s "$FROZEN_ENTRIES" ]; then
            echo "Error: $FROZEN_NAME is sealed but lists no hashes." >&2
            exit 1
        fi
        ;;
    *)
        echo "Error: $FROZEN_NAME must start with \"$OPEN_STATE\" or \"${SEALED_PREFIX}<commit>\", not: $STATE" >&2
        exit 1
        ;;
esac

cat "$TAGGED" "$FROZEN_ENTRIES" | sort -u > "$SORTED"
SUMMARY="$(wc -l < "$SORTED" | tr -d ' ') entries from $TAG_COUNT release tag(s) and $(wc -l < "$FROZEN_ENTRIES" | tr -d ' ') in $FROZEN_NAME, ${STATE:-$OPEN_STATE}"

if [ "$CHECK" = true ]; then
    STALE=false
    # check_current <file> <expected content>; an empty expectation (a sealed frozen file) has
    # nothing to compare against here, the seal check above covers it.
    check_current() {
        [ -s "$2" ] || return 0
        if [ ! -f "$1" ]; then
            echo "Error: $1 is missing." >&2
            STALE=true
        elif ! diff -u "$1" "$2"; then
            echo "Error: $1 is out of date." >&2
            STALE=true
        fi
    }
    check_current "$OUT_FILE" "$SORTED"
    check_current "$FROZEN_FILE" "$FROZEN_EXPECTED"
    if [ "$STALE" = true ]; then
        echo "Run ./generate-known-hashes.sh and commit .qa-instinct-known-hashes and $FROZEN_NAME." >&2
        exit 1
    fi
    echo "Known-hash list is up to date ($SUMMARY)."
    exit 0
fi

[ ! -s "$FROZEN_EXPECTED" ] || cp "$FROZEN_EXPECTED" "$FROZEN_FILE"
cp "$SORTED" "$OUT_FILE"
echo "Wrote $(basename "$OUT_FILE"): $SUMMARY."
