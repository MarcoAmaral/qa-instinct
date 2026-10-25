#!/usr/bin/env bash
# Pre-commit hook to validate test cases in qa-skills

SCRIPT_DIR="$(git rev-parse --show-toplevel)"
VALIDATOR="$SCRIPT_DIR/.claude/hooks/validate-tc-format.sh"

if [ -f "$VALIDATOR" ]; then
    # Find all staged files matching *.md
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$' || true)
    
    if [ -n "$STAGED_FILES" ]; then
        for FILE in $STAGED_FILES; do
            # Only validate if the file contains test cases
            if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$SCRIPT_DIR/$FILE" 2>/dev/null; then
                if ! "$VALIDATOR" "$SCRIPT_DIR/$FILE"; then
                    echo -e "\033[0;31mError: Test case validation failed for $FILE. Commit aborted.\033[0m"
                    exit 1
                fi
            fi
        done
    fi
fi
