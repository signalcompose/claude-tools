#!/usr/bin/env bats
# Structural validation tests for code plugin skills
# TDD: These tests define the contract that all skills must satisfy.

PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# ============================================================================
# Helper functions
# ============================================================================

# Extract frontmatter field value from a SKILL.md file
extract_frontmatter_field() {
    local file="$1"
    local field="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${field}:" | head -1 | sed "s/^${field}: *//"
}

# Check if frontmatter field exists (including multi-line values)
has_frontmatter_field() {
    local file="$1"
    local field="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep -q "^${field}:"
}

# Extract all ${CLAUDE_PLUGIN_ROOT} references from a file
extract_plugin_root_refs() {
    local file="$1"
    grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/[^ `"'"'"']+' "$file" 2>/dev/null | sed 's/[.,;:)]*$//' || true
}

# ============================================================================
# 1. Frontmatter Validation
# ============================================================================

@test "all SKILL.md files have valid frontmatter with required fields" {
    for skill_dir in "$PLUGIN_ROOT"/skills/*/; do
        local skill_file="${skill_dir}SKILL.md"
        [ -f "$skill_file" ] || continue

        local skill_name
        skill_name=$(basename "$skill_dir")

        # Check frontmatter delimiters exist
        local delimiter_count
        delimiter_count=$(grep -c '^---$' "$skill_file")
        [ "$delimiter_count" -ge 2 ] || {
            echo "FAIL: $skill_name/SKILL.md missing frontmatter delimiters (found $delimiter_count, need >= 2)"
            return 1
        }

        # Check required fields
        for field in name description user-invocable; do
            has_frontmatter_field "$skill_file" "$field" || {
                echo "FAIL: $skill_name/SKILL.md missing required field: $field"
                return 1
            }
        done
    done
}

# ============================================================================
# 2. Name-Directory Consistency
# ============================================================================

@test "frontmatter name matches directory name for all skills" {
    for skill_dir in "$PLUGIN_ROOT"/skills/*/; do
        local skill_file="${skill_dir}SKILL.md"
        [ -f "$skill_file" ] || continue

        local dir_name
        dir_name=$(basename "$skill_dir")

        local fm_name
        fm_name=$(extract_frontmatter_field "$skill_file" "name")

        [ "$fm_name" = "$dir_name" ] || {
            echo "FAIL: directory '$dir_name' != frontmatter name '$fm_name'"
            return 1
        }
    done
}

# ============================================================================
# 3. Reference File Existence
# ============================================================================

@test "all CLAUDE_PLUGIN_ROOT references point to existing files" {
    for skill_dir in "$PLUGIN_ROOT"/skills/*/; do
        local skill_file="${skill_dir}SKILL.md"
        [ -f "$skill_file" ] || continue

        local skill_name
        skill_name=$(basename "$skill_dir")

        while IFS= read -r ref; do
            [ -z "$ref" ] && continue

            # Convert ${CLAUDE_PLUGIN_ROOT}/path to absolute path
            local rel_path
            rel_path=$(echo "$ref" | sed 's|\${CLAUDE_PLUGIN_ROOT}/||')
            local abs_path="${PLUGIN_ROOT}/${rel_path}"

            [ -f "$abs_path" ] || {
                echo "FAIL: $skill_name/SKILL.md references non-existent file: $rel_path"
                return 1
            }
        done < <(extract_plugin_root_refs "$skill_file")
    done
}

# ============================================================================
# 4. No Markdown Relative Links
# ============================================================================

@test "SKILL.md files do not contain markdown relative links" {
    for skill_dir in "$PLUGIN_ROOT"/skills/*/; do
        local skill_file="${skill_dir}SKILL.md"
        [ -f "$skill_file" ] || continue

        local skill_name
        skill_name=$(basename "$skill_dir")

        # Extract body (after frontmatter) — uses awk for consistency with Test 5
        local body
        body=$(awk '/^---$/{n++; next} n>=2{print}' "$skill_file")

        # Check for markdown links like [text](relative/path)
        # Exclude http/https URLs and ${CLAUDE_PLUGIN_ROOT} references
        # Note: Uses grep -E pipeline instead of grep -P (Perl regex unavailable on macOS BSD grep)
        if echo "$body" | grep -E '\[.+\]\([^)]+\)' | grep -Ev '\]\(https?://' | grep -Ev '\]\(\$\{CLAUDE_PLUGIN_ROOT\}' | grep -q .; then
            echo "FAIL: $skill_name/SKILL.md contains markdown relative links (use \${CLAUDE_PLUGIN_ROOT} instead)"
            return 1
        fi
    done
}

# ============================================================================
# 5. SKILL.md Body Line Count
# ============================================================================

@test "SKILL.md body is within 120 lines" {
    for skill_dir in "$PLUGIN_ROOT"/skills/*/; do
        local skill_file="${skill_dir}SKILL.md"
        [ -f "$skill_file" ] || continue

        local skill_name
        skill_name=$(basename "$skill_dir")

        # Count lines after frontmatter
        local body_lines
        body_lines=$(awk '/^---$/{n++; next} n>=2{print}' "$skill_file" | wc -l | tr -d ' ')

        [ "$body_lines" -le 120 ] || {
            echo "FAIL: $skill_name/SKILL.md body has $body_lines lines (max 120)"
            return 1
        }
    done
}
