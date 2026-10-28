#!/usr/bin/env bash
# Pre-commit hook to validate test cases in qa-skills

SCRIPT_DIR="\"
VALIDATOR="\/.claude/hooks/validate-tc-format.sh"

if [ -f "\" ]; then
    # Find all staged files matching *.md
    STAGED_FILES=\
    
    if [ -n "\" ]; then
        for FILE in \; do
            # Only validate if the file contains test cases
            if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "\/\" 2>/dev/null; then
                if ! "\" "\/\"; then
                    echo -e "\033[0;31mError: Test case validation failed for \. Commit aborted.\033[0m"
                    exit 1
                fi
            fi
        done
    fi
fi
