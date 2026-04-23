#!/usr/bin/env bats
# Tests for check-gitignore-security.sh REF_FILE path resolution

PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "gitignore-security-patterns.md reference file exists" {
    local ref_file="${PLUGIN_ROOT}/references/gitignore-security-patterns.md"
    [ -f "$ref_file" ]
}

@test "check-gitignore-security.sh REF_FILE resolves to an existing path" {
    local script_dir="${PLUGIN_ROOT}/scripts"
    local ref_file="${script_dir}/../references/gitignore-security-patterns.md"
    [ -f "$ref_file" ]
}

@test "gitignore-security-patterns.md contains the code:security-patterns marker" {
    local ref_file="${PLUGIN_ROOT}/references/gitignore-security-patterns.md"
    grep -q "code:security-patterns:" "$ref_file"
}
