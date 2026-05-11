#!/usr/bin/env sh
set -eu

if ! command -v markdownlint-cli2 >/dev/null 2>&1; then
    echo "ERROR: markdownlint-cli2 is not installed. Install it before running docs checks." >&2
    exit 127
fi

markdownlint-cli2 "docs/**/*.md" ".github/**/*.md" "*.md"