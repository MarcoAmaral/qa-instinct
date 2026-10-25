#!/usr/bin/env bash
# Global pre-commit hook to validate test cases in qa-skills

GLOBAL_VALIDATOR="$HOME/.claude/hooks/validate-tc-format.sh"
if [ -f "$GLOBAL_VALIDATOR" ]; then
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$' || true)
    if [ -n "$STAGED_FILES" ]; then
        for FILE in $STAGED_FILES; do
            if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$FILE" 2>/dev/null; then
                if ! "$GLOBAL_VALIDATOR" "$FILE"; then
                    echo -e "\033[0;31mError: Test case validation failed for $FILE. Commit aborted.\033[0m"
                    exit 1
                fi
            fi
        done
    fi
fi
