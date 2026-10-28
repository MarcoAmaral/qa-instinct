#!/usr/bin/env bash
# Writes the git hook fixtures in this folder from what every release's installers wrote (plan 064
# item 1), and prints each file's SHA-256 with the tags that wrote it.
#
#   tests/fixtures/git-hooks/extract.sh <old-repo> <this-repo>
#
# <old-repo> is the repository the package lived in before v4.1.0 (read only: only `git tag` and
# `git show`, no checkout, no write). <this-repo> supplies v4.1.0. It is kept for the audit trail
# and is not run by CI: CI has no old repository. Needs GNU awk-compatible awk, sha256sum and, for
# the three texts of the v2.0.0 install.ps1, powershell.exe (Windows PowerShell 5.1) with wslpath.
#
# A heredoc (install.sh) or here-string (install.ps1) body is found by its opening line, per tag.
# What the installer then wrote follows from how it wrote it:
#   install.sh        cat > / cat >>      the body, every line ending in LF
#   install.ps1       WriteAllText        the here-string: no final line break (the one before the
#                                         closing '@ is not part of it); the line breaks inside
#                                         follow the script file: LF, or CRLF in a Windows clone
#                                         before .gitattributes forced LF (up to v2.7.1)
#   install.ps1       Add-Content         the same, then one CRLF
# Both a with- and a without-final-line-break file is written for every project hook, whichever
# installer wrote it: plan 064 item 3 depends on both being handled.
set -euo pipefail

[ "$#" -eq 2 ] || { echo "usage: $0 <old-repo> <this-repo>" >&2; exit 2; }
OLD="$1"
NEW="$2"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bodies" "$HERE/project" "$HERE/global-fresh" "$HERE/global-appended"

# ---- bodies of every heredoc and here-string, per tag ---------------------------------------------

ORDERED_TAGS="$(git -C "$OLD" tag | grep '^v' | LC_ALL=C sort -V | tr '\n' ' ')v4.1.0"
ARCHIVE_TAGS="$(git -C "$OLD" tag | grep '^archive/' | tr '\n' ' ')"

extract_bodies() {   # <repo> <tag>
    local REPO="$1" TAG="$2" DEST
    DEST="$WORK/bodies/$(printf '%s' "$TAG" | tr '/' '_')"
    mkdir -p "$DEST"
    git -C "$REPO" show "$TAG:install.sh" 2> /dev/null | awk -v dest="$DEST" -v q="'" '
        $0 ~ ("<< " q "[A-Z_]+" q "$") { name = $0; sub(".*<< " q, "", name); sub(q "$", "", name); inb = 1; fn = dest "/sh." name; printf "" > fn; next }
        inb && $0 == name { inb = 0; close(fn); next }
        inb { print > fn }' || true
    git -C "$REPO" show "$TAG:install.ps1" 2> /dev/null | awk -v dest="$DEST" -v q="'" '
        $0 ~ ("\\$[A-Za-z:]+ = \\(*@[" q "\"]$") {
            name = $0; sub(/ = .*/, "", name); sub(/^ */, "", name); sub(/^\$/, "", name); gsub(/:/, "_", name)
            term = ($0 ~ ("@" q "$")) ? (q "@") : "\"@"
            inb = 1; fn = dest "/ps1." name; printf "" > fn; next }
        inb && index($0, term) == 1 { inb = 0; close(fn); next }
        inb { print > fn }' || true
}

for TAG in $ORDERED_TAGS $ARCHIVE_TAGS; do
    case "$TAG" in v4.1.0) extract_bodies "$NEW" "$TAG" ;; *) extract_bodies "$OLD" "$TAG" ;; esac
done

dirof() { printf '%s/bodies/%s' "$WORK" "$(printf '%s' "$1" | tr '/' '_')"; }
bsha() { sha256sum < "$(dirof "$1")/$2" | cut -d' ' -f1; }     # <tag> <body file> -> sha of that body
body() { cat "$(dirof "$1")/$2"; }                              # <tag> <body file> -> its lines, LF
join() { awk -v e="$1" 'NR > 1 { printf "%s", e } { printf "%s", $0 }'; }   # lines joined by <eol>, none after the last

# tags_with <body file> <sha> [crlf|lf]: the tags whose body file has that sha, as runs of tags.
# crlf: only tags up to v2.7.1 (a Windows clone then held install.ps1 with CRLF); lf: from v2.7.2.
tags_with() {
    local FILE="$1" SHA="$2" WHICH="${3:-}" TAG PAST=0 RUN="" LAST="" OUT="" IN
    for TAG in $ORDERED_TAGS; do
        IN=0
        if [ -f "$(dirof "$TAG")/$FILE" ] && [ "$(bsha "$TAG" "$FILE")" = "$SHA" ]; then IN=1; fi
        if [ "$WHICH" = crlf ] && [ "$PAST" = 1 ]; then IN=0; fi
        if [ "$WHICH" = lf ] && [ "$PAST" = 0 ]; then IN=0; fi
        if [ "$IN" = 1 ]; then
            [ -n "$RUN" ] || RUN="$TAG"
            LAST="$TAG"
        elif [ -n "$RUN" ]; then
            if [ "$RUN" = "$LAST" ]; then OUT="$OUT $RUN"; else OUT="$OUT $RUN-$LAST"; fi
            RUN=""
        fi
        [ "$TAG" = v2.7.1 ] && PAST=1
    done
    if [ -n "$RUN" ]; then
        if [ "$RUN" = "$LAST" ]; then OUT="$OUT $RUN"; else OUT="$OUT $RUN-$LAST"; fi
    fi
    printf '%s' "${OUT# }"
}

TABLE="$WORK/table"
: > "$TABLE"
KNOWN="$WORK/known"     # <body file> <sha>: every body that has a fixture
: > "$KNOWN"
known() { printf '%s %s\n' "$1" "$2" >> "$KNOWN"; }
record() {   # <fixture path relative to this folder> <written by>
    printf '%s  %s  %s\n' "$(sha256sum < "$HERE/$1" | cut -d' ' -f1)" "$1" "$2" >> "$TABLE"
}
same() { [ "$1" = "$2" ] || { echo "extract.sh: expected two bodies to be the same text: $3" >&2; exit 1; }; }

LF=$'\n'
CRLF=$'\r\n'

# ---- project hooks --------------------------------------------------------------------------------

# project_texts <name> <sh tag> <ps1 tag or ->: the with/without final line break files of one text.
project_texts() {
    local NAME="$1" SHTAG="$2" PSTAG="$3" SHA SHTAGS="" PSLF="" PSCRLF=""
    SHA="$(bsha "$SHTAG" sh.PRECOMMIT)"
    known sh.PRECOMMIT "$SHA"
    SHTAGS="$(tags_with sh.PRECOMMIT "$SHA")"
    if [ "$PSTAG" != - ]; then
        same "$SHA" "$(bsha "$PSTAG" ps1.hookContent)" "$NAME (install.sh and install.ps1)"
        known ps1.hookContent "$SHA"
        PSLF="$(tags_with ps1.hookContent "$SHA" lf)"
        PSCRLF="$(tags_with ps1.hookContent "$SHA" crlf)"
    fi
    body "$SHTAG" sh.PRECOMMIT > "$HERE/project/$NAME.lf.nl"
    body "$SHTAG" sh.PRECOMMIT | join "$LF" > "$HERE/project/$NAME.lf.nonl"
    record "project/$NAME.lf.nl" "install.sh $SHTAGS"
    if [ -n "$PSLF" ]; then
        record "project/$NAME.lf.nonl" "install.ps1 $PSLF"
    else
        record "project/$NAME.lf.nonl" "no release wrote this (install.ps1 never wrote it, derived for plan 064 item 3)"
    fi
    if [ -n "$PSCRLF" ]; then
        body "$SHTAG" sh.PRECOMMIT | join "$CRLF" > "$HERE/project/$NAME.crlf.nonl"
        { body "$SHTAG" sh.PRECOMMIT | join "$CRLF"; printf '\r\n'; } > "$HERE/project/$NAME.crlf.nl"
        record "project/$NAME.crlf.nonl" "install.ps1 $PSCRLF, in a Windows clone with CRLF line endings"
        record "project/$NAME.crlf.nl" "no release wrote this (derived for plan 064 item 3)"
    fi
}
project_texts echo-e v2.1.0 v2.1.0
project_texts printf-split v2.7.0 -
# Written as project/current.* until plan 066 renamed the marker; current.* now holds the new
# text, written from it by hand, and fenced-qa-instinct.lf.nl the new fresh global hook.
project_texts qa-skills-marker v4.1.0 v4.1.0
same "$(bsha v4.0.1 sh.PRECOMMIT)" "$(bsha v4.1.0 sh.PRECOMMIT)" "the project hook at v4.0.1 and v4.1.0"
same "$(bsha v2.0.0 sh.PRECOMMIT)" "$(bsha v2.1.0 sh.PRECOMMIT)" "the project hook at v2.0.0 and v2.1.0"

# ---- global hooks, fresh --------------------------------------------------------------------------

HEADER='# Global pre-commit hook to validate test cases in qa-skills'

H="$(bsha v2.0.0 sh.GLOBAL_PRECOMMIT)"
same "$H" "$(bsha v2.1.0 ps1.globalHookContent)" "the header-only global hook (install.sh v2.0.0, install.ps1 v2.1.0)"
known sh.GLOBAL_PRECOMMIT "$H"; known ps1.globalHookContent "$H"
body v2.0.0 sh.GLOBAL_PRECOMMIT > "$HERE/global-fresh/header-only.lf.nl"
body v2.0.0 sh.GLOBAL_PRECOMMIT | join "$LF" > "$HERE/global-fresh/header-only.lf.nonl"
body v2.0.0 sh.GLOBAL_PRECOMMIT | join "$CRLF" > "$HERE/global-fresh/header-only.crlf.nonl"
record global-fresh/header-only.lf.nl "install.sh $(tags_with sh.GLOBAL_PRECOMMIT "$H")"
record global-fresh/header-only.lf.nonl "install.ps1 $(tags_with ps1.globalHookContent "$H" lf)"
record global-fresh/header-only.crlf.nonl "install.ps1 $(tags_with ps1.globalHookContent "$H" crlf), in a Windows clone with CRLF line endings"

H="$(bsha v2.1.0 sh.GLOBAL_PRECOMMIT)"; known sh.GLOBAL_PRECOMMIT "$H"
body v2.1.0 sh.GLOBAL_PRECOMMIT > "$HERE/global-fresh/added-by-echo-e.lf.nl"
record global-fresh/added-by-echo-e.lf.nl "install.sh $(tags_with sh.GLOBAL_PRECOMMIT "$H")"

H="$(bsha v2.7.0 sh.GLOBAL_PRECOMMIT)"; known sh.GLOBAL_PRECOMMIT "$H"
body v2.7.0 sh.GLOBAL_PRECOMMIT > "$HERE/global-fresh/added-by-printf.lf.nl"
record global-fresh/added-by-printf.lf.nl "install.sh $(tags_with sh.GLOBAL_PRECOMMIT "$H")"

# v4.0.1 on: the fresh hook is the shebang, the header, a blank line and the fenced block, in both.
H="$(bsha v4.1.0 sh.GLOBAL_PRECOMMIT_BLOCK)"
same "$H" "$(bsha v4.1.0 ps1.Script_GlobalHookBlock)" "the fenced global block (install.sh and install.ps1)"
same "$H" "$(bsha v4.0.1 sh.GLOBAL_PRECOMMIT_BLOCK)" "the fenced global block at v4.0.1 and v4.1.0"
known sh.GLOBAL_PRECOMMIT_BLOCK "$H"; known ps1.Script_GlobalHookBlock "$H"
{ printf '#!/usr/bin/env bash\n%s\n\n' "$HEADER"; body v4.1.0 sh.GLOBAL_PRECOMMIT_BLOCK; } > "$HERE/global-fresh/fenced.lf.nl"
record global-fresh/fenced.lf.nl "install.sh $(tags_with sh.GLOBAL_PRECOMMIT_BLOCK "$H"); install.ps1 $(tags_with ps1.Script_GlobalHookBlock "$H")"

# ---- global hooks, appended to a user's hook --------------------------------------------------------

BEFORE_LF='#!/bin/sh\necho before\n'
BEFORE_CRLF='#!/bin/sh\r\necho before\r\n'
AFTER_LF='echo after\n'
AFTER_CRLF='echo after\r\n'
expected() {   # <name> <lf|crlf>
    if [ "$2" = lf ]; then printf '%b' "${BEFORE_LF}${AFTER_LF}"; else printf '%b' "${BEFORE_CRLF}${AFTER_CRLF}"; fi > "$HERE/global-appended/$1.expected"
}

H="$(bsha v2.1.0 sh.GLOBAL_PRECOMMIT_APPEND)"
same "$H" "$(bsha v2.1.0 ps1.appendContent)" "the echo -e appended block (install.sh and install.ps1)"
known sh.GLOBAL_PRECOMMIT_APPEND "$H"; known ps1.appendContent "$H"
{ printf '%b' "$BEFORE_LF"; body v2.1.0 sh.GLOBAL_PRECOMMIT_APPEND; printf '%b' "$AFTER_LF"; } > "$HERE/global-appended/echo-e.sh.lf"
{ printf '%b' "$BEFORE_LF"; body v2.1.0 ps1.appendContent | join "$LF"; printf '\r\n'; printf '%b' "$AFTER_LF"; } > "$HERE/global-appended/echo-e.ps1.lf"
{ printf '%b' "$BEFORE_CRLF"; body v2.1.0 ps1.appendContent | join "$CRLF"; printf '\r\n'; printf '%b' "$AFTER_CRLF"; } > "$HERE/global-appended/echo-e.ps1.crlf"
expected echo-e.sh.lf lf; expected echo-e.ps1.lf lf; expected echo-e.ps1.crlf crlf
record global-appended/echo-e.sh.lf "install.sh $(tags_with sh.GLOBAL_PRECOMMIT_APPEND "$H")"
record global-appended/echo-e.ps1.lf "install.ps1 $(tags_with ps1.appendContent "$H" lf)"
record global-appended/echo-e.ps1.crlf "install.ps1 $(tags_with ps1.appendContent "$H" crlf), in a Windows clone with CRLF line endings"

H="$(bsha v2.7.0 sh.GLOBAL_PRECOMMIT_APPEND)"; known sh.GLOBAL_PRECOMMIT_APPEND "$H"
{ printf '%b' "$BEFORE_LF"; body v2.7.0 sh.GLOBAL_PRECOMMIT_APPEND; printf '%b' "$AFTER_LF"; } > "$HERE/global-appended/printf.sh.lf"
expected printf.sh.lf lf
record global-appended/printf.sh.lf "install.sh $(tags_with sh.GLOBAL_PRECOMMIT_APPEND "$H")"

# v4.0.1 on: a blank line, then the fenced block, in both.
{ printf '%b' "$BEFORE_LF"; printf '\n'; body v4.1.0 sh.GLOBAL_PRECOMMIT_BLOCK; printf '%b' "$AFTER_LF"; } > "$HERE/global-appended/fenced.lf"
expected fenced.lf lf
record global-appended/fenced.lf "install.sh $(tags_with sh.GLOBAL_PRECOMMIT_BLOCK "$(bsha v4.1.0 sh.GLOBAL_PRECOMMIT_BLOCK)"); install.ps1 $(tags_with ps1.Script_GlobalHookBlock "$(bsha v4.1.0 ps1.Script_GlobalHookBlock)")"

# ---- the v2.0.0 install.ps1: double-quoted here-strings --------------------------------------------
# $hookContent, $appendContent and $globalHookContent were @"..."@, so PowerShell expanded them: a
# backslash stays, and the $ after it starts a variable or a $(...) command. The script does not
# parse in Windows PowerShell 5.1 at all (the `|| true` inside $(...) is a syntax error there), so
# no release of it could write these on 5.1; the text below is what PowerShell 7 would write, with
# no repository, no staged files and no grep on PATH, and $HOME = C:\Users\user. Every other
# variable in the text is undefined. Expanded here, in 5.1, after removing ` || true`, which
# changes nothing when the command in front of it prints nothing.
expand() {   # <body file> <lf|crlf> -> the expanded text, no final line break
    local EOL="$LF"
    [ "$2" = crlf ] && EOL="$CRLF"
    body v2.0.0 "$1" | join "$EOL" > "$WORK/in.txt"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$WORK/expand.ps1")" \
        -In "$(wslpath -w "$WORK/in.txt")" -Out "$(wslpath -w "$WORK/out.txt")" > /dev/null
    cat "$WORK/out.txt"
}
cat > "$WORK/expand.ps1" << 'EXPAND_PS1'
param($In, $Out)
$ErrorActionPreference = 'Stop'
function git { }
function grep { }
Set-Variable -Name HOME -Value 'C:\Users\user' -Force
$body = [System.IO.File]::ReadAllText($In) -replace ' \|\| true', ''
$text = $ExecutionContext.InvokeCommand.ExpandString($body)
[System.IO.File]::WriteAllText($Out, $text, (New-Object System.Text.UTF8Encoding($false)))
EXPAND_PS1

if command -v powershell.exe > /dev/null 2>&1 && command -v wslpath > /dev/null 2>&1; then
    known ps1.hookContent "$(bsha v2.0.0 ps1.hookContent)"
    known ps1.appendContent "$(bsha v2.0.0 ps1.appendContent)"
    known ps1.globalHookContent "$(bsha v2.0.0 ps1.globalHookContent)"
    for EOL in lf crlf; do
        E="$LF"; BEFORE="$BEFORE_LF"; AFTER="$AFTER_LF"; NOTE="LF"
        if [ "$EOL" = crlf ]; then E="$CRLF"; BEFORE="$BEFORE_CRLF"; AFTER="$AFTER_CRLF"; NOTE="CRLF"; fi
        expand ps1.hookContent "$EOL" > "$WORK/p.txt"
        cp "$WORK/p.txt" "$HERE/project/ps1-v2.0.0-expanded.$EOL.nonl"
        { cat "$WORK/p.txt"; printf '%s' "$E"; } > "$HERE/project/ps1-v2.0.0-expanded.$EOL.nl"
        expand ps1.globalHookContent "$EOL" > "$HERE/global-fresh/ps1-v2.0.0-expanded.$EOL.nonl"
        { printf '%b' "$BEFORE"; expand ps1.appendContent "$EOL"; printf '\r\n'; printf '%b' "$AFTER"; } > "$HERE/global-appended/ps1-v2.0.0-expanded.$EOL"
        expected "ps1-v2.0.0-expanded.$EOL" "$EOL"
        W="install.ps1 v2.0.0, $NOTE script file; does not parse in 5.1, so no 5.1 install ever wrote it"
        record "project/ps1-v2.0.0-expanded.$EOL.nonl" "$W"
        record "project/ps1-v2.0.0-expanded.$EOL.nl" "no release wrote this (derived for plan 064 item 3)"
        record "global-fresh/ps1-v2.0.0-expanded.$EOL.nonl" "$W"
        record "global-appended/ps1-v2.0.0-expanded.$EOL" "$W"
    done
else
    echo "extract.sh: powershell.exe or wslpath not found; the ps1-v2.0.0-expanded fixtures were not rewritten" >&2
fi

# ---- every body found must have a fixture ------------------------------------------------------------

STATUS=0
for DIR in "$WORK"/bodies/*; do
    for FILE in sh.PRECOMMIT sh.GLOBAL_PRECOMMIT sh.GLOBAL_PRECOMMIT_APPEND sh.GLOBAL_PRECOMMIT_BLOCK \
        ps1.hookContent ps1.appendContent ps1.globalHookContent ps1.Script_GlobalHookBlock; do
        [ -f "$DIR/$FILE" ] || continue
        SHA="$(sha256sum < "$DIR/$FILE" | cut -d' ' -f1)"
        if ! grep -qx "$FILE $SHA" "$KNOWN"; then
            echo "UNLISTED: $(basename "$DIR") $FILE $SHA has no fixture" >&2
            STATUS=1
        fi
    done
done

LC_ALL=C sort -k2 "$TABLE"
echo "archive/* tags checked for unlisted hook texts: ${ARCHIVE_TAGS:-none}"
exit "$STATUS"
