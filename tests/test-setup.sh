#!/usr/bin/env bash
# LLM CLI Council - Setup Tests
# Tests repository structure, platform utilities, and configuration

set -uo pipefail

# =============================================================================
# Test Framework
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results
declare -a FAILED_TESTS=()

# =============================================================================
# Test Framework Functions
# =============================================================================

test_start() {
    echo -e "\n${BLUE}▶${NC} Testing: $1"
    ((TESTS_RUN++))
}

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"

    if [ "$expected" = "$actual" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"

    if [ -n "$value" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    if [ -f "$file" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist: $dir}"

    if [ -d "$dir" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_executable() {
    local file="$1"
    local message="${2:-File should be executable: $file}"

    if [ -x "$file" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain '$needle'}"

    if echo "$haystack" | grep -qFe "$needle"; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# =============================================================================
# Test Suites
# =============================================================================

test_suite_repository_structure() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Repository Structure${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    test_start "Repository root files exist"
    assert_file_exists "$PROJECT_ROOT/README.md" "README.md exists"
    assert_file_exists "$PROJECT_ROOT/LICENSE" "LICENSE exists"
    assert_file_exists "$PROJECT_ROOT/CONTRIBUTING.md" "CONTRIBUTING.md exists"
    assert_file_exists "$PROJECT_ROOT/CHANGELOG.md" "CHANGELOG.md exists"

    test_start "Plugin manifest"
    assert_file_exists "$PROJECT_ROOT/.claude-plugin/plugin.json" "plugin.json exists"

    test_start "Top-level directory structure"
    assert_dir_exists "$PROJECT_ROOT/skills" "skills/ exists"
    assert_dir_exists "$PROJECT_ROOT/prompts" "prompts/ exists"
    assert_dir_exists "$PROJECT_ROOT/rules" "rules/ exists"
    assert_dir_exists "$PROJECT_ROOT/config" "config/ exists"
    assert_dir_exists "$PROJECT_ROOT/lib" "lib/ exists"
    assert_dir_exists "$PROJECT_ROOT/examples" "examples/ exists"
    assert_dir_exists "$PROJECT_ROOT/tests" "tests/ exists"

    test_start "Skill files"
    for skill in llm-cli-council setup status review-plan review-code uninstall; do
        assert_file_exists "$PROJECT_ROOT/skills/${skill}.md" "Skill: ${skill}.md"
    done

    test_start "Prompt files"
    for prompt in chairman-synthesis code-review plan-review; do
        assert_file_exists "$PROJECT_ROOT/prompts/${prompt}.md" "Prompt: ${prompt}.md"
    done

    test_start "Rules files"
    for rule in council-orchestration synthesis-strategy triggers; do
        assert_file_exists "$PROJECT_ROOT/rules/${rule}.md" "Rule: ${rule}.md"
    done

    test_start "Library and config files"
    assert_file_exists "$PROJECT_ROOT/lib/platform-utils.sh" "platform-utils.sh exists"
    assert_executable "$PROJECT_ROOT/lib/platform-utils.sh" "platform-utils.sh is executable"
    assert_file_exists "$PROJECT_ROOT/config/providers.json" "providers.json exists"
}

test_suite_plugin_manifest() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Plugin Manifest${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    local manifest="$PROJECT_ROOT/.claude-plugin/plugin.json"

    test_start "plugin.json is valid JSON"
    if command -v jq &>/dev/null; then
        if jq . "$manifest" &>/dev/null; then
            test_pass "plugin.json is valid JSON"
        else
            test_fail "plugin.json has invalid JSON syntax"
        fi

        test_start "plugin.json required fields"
        for field in .name .version .description; do
            local value
            value=$(jq -r "$field // empty" "$manifest")
            assert_not_empty "$value" "Field present: $field"
        done

        test_start "plugin.json skill registrations"
        local skill_count
        skill_count=$(jq '.skills | length' "$manifest")
        if [ "$skill_count" -ge 5 ]; then
            test_pass "At least 5 skills registered ($skill_count)"
        else
            test_fail "Too few skills registered (expected >=5, got $skill_count)"
        fi

        # Verify each skill path resolves to an actual file
        test_start "Skill paths in plugin.json resolve to real files"
        local skill_paths
        skill_paths=$(jq -r '.skills[].path' "$manifest")
        while IFS= read -r path; do
            local full_path="$PROJECT_ROOT/.claude-plugin/$path"
            # paths are relative to .claude-plugin/, strip leading ./
            local rel="${path#./}"
            local resolved="$PROJECT_ROOT/.claude-plugin/$rel"
            if [ ! -f "$resolved" ]; then
                # try relative to project root
                resolved="$PROJECT_ROOT/$rel"
            fi
            if [ -f "$resolved" ]; then
                test_pass "Skill path resolves: $path"
            else
                test_fail "Skill path not found: $path"
            fi
        done <<< "$skill_paths"
    else
        echo -e "${YELLOW}⚠${NC} jq not found, skipping JSON validation tests"
    fi
}

test_suite_platform_utilities() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Platform Utilities${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    local utils_file="$PROJECT_ROOT/lib/platform-utils.sh"

    test_start "Platform utilities file"
    assert_file_exists "$utils_file" "platform-utils.sh exists"
    assert_executable "$utils_file" "platform-utils.sh is executable"

    # Source the utilities
    # shellcheck source=/dev/null
    source "$utils_file"

    test_start "Platform detection"
    local platform
    platform=$(detect_platform)
    assert_not_empty "$platform" "Platform detected"

    case "$platform" in
        macos|linux|windows)
            test_pass "Platform is valid: $platform"
            ;;
        *)
            test_fail "Platform is invalid: $platform"
            ;;
    esac

    test_start "Utility functions exist"
    local functions=(
        "detect_platform"
        "timeout_cmd"
        "wait_for_pid"
        "make_temp_file"
        "make_temp_dir"
        "json_get"
        "json_has_key"
        "path_resolve"
        "path_exists"
        "command_exists"
        "get_config_dir"
        "ensure_dir"
    )

    for func in "${functions[@]}"; do
        if declare -f "$func" &>/dev/null; then
            test_pass "Function exists: $func"
        else
            test_fail "Function missing: $func"
        fi
    done

    test_start "Path resolution"
    local resolved
    resolved=$(path_resolve "~/test")
    assert_contains "$resolved" "$HOME" "Tilde expansion works"

    test_start "Temp file creation"
    local temp_file
    temp_file=$(make_temp_file "test")
    if [ -f "$temp_file" ]; then
        test_pass "Temp file created: $temp_file"
        rm "$temp_file"
    else
        test_fail "Temp file not created"
    fi

    test_start "Temp directory creation"
    local temp_dir
    temp_dir=$(make_temp_dir "test")
    if [ -d "$temp_dir" ]; then
        test_pass "Temp directory created: $temp_dir"
        rmdir "$temp_dir"
    else
        test_fail "Temp directory not created"
    fi

    test_start "Command existence check"
    if command_exists "bash"; then
        test_pass "command_exists works (bash found)"
    else
        test_fail "command_exists failed (bash should exist)"
    fi

    if ! command_exists "nonexistent_command_xyz"; then
        test_pass "command_exists correctly returns false for missing command"
    else
        test_fail "command_exists incorrectly found nonexistent command"
    fi
}

test_suite_path_abstraction() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Path Abstraction${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    test_start "No hardcoded user paths in skills"
    local hardcoded_paths
    hardcoded_paths=$(grep -r "/Users/[^/]*\|/home/[^/]*" "$PROJECT_ROOT/skills" 2>/dev/null | grep -v "Binary file" || true)

    if [ -z "$hardcoded_paths" ]; then
        test_pass "No hardcoded user paths in skills/"
    else
        test_fail "Found hardcoded user paths in skills/: $hardcoded_paths"
    fi

    test_start "No hardcoded user paths in lib"
    local lib_hardcoded
    lib_hardcoded=$(grep -r "/Users/[^/]*\|/home/[^/]*" "$PROJECT_ROOT/lib" 2>/dev/null | grep -v "Binary file" || true)

    if [ -z "$lib_hardcoded" ]; then
        test_pass "No hardcoded user paths in lib/"
    else
        test_fail "Found hardcoded user paths in lib/: $lib_hardcoded"
    fi

    test_start "No hardcoded user paths in config"
    local config_hardcoded
    config_hardcoded=$(grep -r "/Users/[^/]*\|/home/[^/]*" "$PROJECT_ROOT/config" 2>/dev/null | grep -v "Binary file" || true)

    if [ -z "$config_hardcoded" ]; then
        test_pass "No hardcoded user paths in config/"
    else
        test_fail "Found hardcoded user paths in config/: $config_hardcoded"
    fi
}

test_suite_configuration() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Configuration${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    test_start "Providers configuration"
    local providers_json="$PROJECT_ROOT/config/providers.json"

    assert_file_exists "$providers_json" "providers.json exists"

    if command -v jq &>/dev/null; then
        if jq . "$providers_json" &>/dev/null; then
            test_pass "providers.json is valid JSON"
        else
            test_fail "providers.json has invalid JSON syntax"
        fi

        test_start "Required providers configured"
        local providers=("claude" "copilot" "codex" "gemini" "ollama")
        for provider in "${providers[@]}"; do
            if jq -e ".providers.$provider" "$providers_json" &>/dev/null; then
                test_pass "Provider configured: $provider"
            else
                test_fail "Provider missing: $provider"
            fi
        done

        test_start "Provider required fields"
        for provider in "${providers[@]}"; do
            for field in command invocation detectCommand authCheck; do
                if jq -e ".providers.$provider.$field" "$providers_json" &>/dev/null; then
                    test_pass "$provider.$field present"
                else
                    test_fail "$provider.$field missing"
                fi
            done
        done

        test_start "Required modes configured"
        local modes=("quick" "full" "privacy")
        for mode in "${modes[@]}"; do
            if jq -e ".modes.$mode" "$providers_json" &>/dev/null; then
                test_pass "Mode configured: $mode"
            else
                test_fail "Mode missing: $mode"
            fi
        done

        test_start "Task routing configured"
        local tasks=("plan-review" "code-review")
        for task in "${tasks[@]}"; do
            if jq -e ".taskRouting[\"$task\"]" "$providers_json" &>/dev/null; then
                test_pass "Task routing configured: $task"
            else
                test_fail "Task routing missing: $task"
            fi
        done

        test_start "Defaults block present"
        for field in mode minQuorum timeoutMs; do
            if jq -e ".defaults.$field" "$providers_json" &>/dev/null; then
                test_pass "Default configured: $field"
            else
                test_fail "Default missing: $field"
            fi
        done
    else
        echo -e "${YELLOW}⚠${NC} jq not found, skipping JSON validation tests"
    fi
}

test_suite_documentation() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Documentation${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    test_start "README.md content"
    local readme="$PROJECT_ROOT/README.md"

    assert_contains "$(cat "$readme")" "# LLM CLI Council" "Has title"
    assert_contains "$(cat "$readme")" "Installation" "Has installation section"
    assert_contains "$(cat "$readme")" "Quick Start" "Has quick start section"
    assert_contains "$(cat "$readme")" "Usage" "Has usage section"
    assert_contains "$(cat "$readme")" "Configuration" "Has configuration section"
    assert_contains "$(cat "$readme")" "Troubleshooting" "Has troubleshooting section"

    test_start "README.md length"
    local readme_lines
    readme_lines=$(wc -l < "$readme" | tr -d ' ')

    if [ "$readme_lines" -gt 400 ]; then
        test_pass "README is comprehensive ($readme_lines lines)"
    else
        test_fail "README too short ($readme_lines lines)"
    fi

    test_start "License file"
    local license="$PROJECT_ROOT/LICENSE"

    assert_file_exists "$license" "LICENSE exists"
    assert_contains "$(cat "$license")" "MIT License" "Is MIT License"
    assert_contains "$(cat "$license")" "2025" "Has copyright year"
}

test_suite_installer() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Installer${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    local TEST_INSTALL_DIR
    TEST_INSTALL_DIR=$(mktemp -d)

    # Test --help flag
    test_start "--help flag"
    local help_output
    local help_exit
    help_output=$(node "$PROJECT_ROOT/bin/install.js" --help 2>&1)
    help_exit=$?
    if [ "$help_exit" -eq 0 ]; then
        test_pass "installer --help exits 0"
    else
        test_fail "installer --help exits 0 (got $help_exit)"
    fi
    assert_contains "$help_output" "npx llm-cli-council" "installer --help shows usage"

    # Test --dry-run (must not create any files)
    test_start "--dry-run flag"
    local dry_dir="$TEST_INSTALL_DIR/dry-run-test"
    CLAUDE_DIR="$dry_dir" node "$PROJECT_ROOT/bin/install.js" --dry-run >/dev/null 2>&1
    if [ ! -d "$dry_dir" ]; then
        test_pass "installer --dry-run does not create target dir"
    else
        test_fail "installer --dry-run does not create target dir (dir was created)"
    fi

    # Test actual install (--skip-detect avoids real LLM API calls in tests)
    test_start "--yes install"
    local install_dir="$TEST_INSTALL_DIR/real-install"
    CLAUDE_DIR="$install_dir" node "$PROJECT_ROOT/bin/install.js" --yes --skip-detect >/dev/null 2>&1
    assert_dir_exists "$install_dir/skills" "installer --yes creates skills dir"
    assert_dir_exists "$install_dir/lib" "installer --yes creates lib dir"
    assert_dir_exists "$install_dir/config" "installer --yes creates config dir"
    assert_file_exists "$install_dir/skills/llm-cli-council.md" "installer copies skills/llm-cli-council.md"
    assert_file_exists "$install_dir/config/providers.json" "installer copies config/providers.json"
    assert_executable "$install_dir/lib/platform-utils.sh" "installer sets lib/platform-utils.sh executable"

    # Cleanup
    rm -rf "$TEST_INSTALL_DIR"
}

test_suite_installed_system() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Installed System${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    # Locate the skills directory
    local skills_dir
    skills_dir="${CLAUDE_SKILLS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills}"

    if [ ! -d "$skills_dir/llm-cli-council" ]; then
        echo -e "${YELLOW}⚠${NC} Skill not installed at $skills_dir, skipping installed system tests"
        return 0
    fi

    test_start "Installed skill directories"
    assert_dir_exists "$skills_dir/llm-cli-council" "Main skill installed"

    test_start "Config directory and file"
    local config_dir
    config_dir="${CLAUDE_COUNCIL_CONFIG_DIR:-${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}/council}"

    if [ -d "$config_dir" ]; then
        test_pass "Config directory exists: $config_dir"

        if [ -f "$config_dir/config.json" ]; then
            test_pass "Config file exists"

            if command -v jq &>/dev/null; then
                if jq . "$config_dir/config.json" &>/dev/null; then
                    test_pass "Config file is valid JSON"
                else
                    test_fail "Config file has invalid JSON"
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} Config file not found (run /llm-cli-council:setup)"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Config directory not found (run /llm-cli-council:setup)"
    fi
}

# =============================================================================
# Main Test Runner
# =============================================================================

print_header() {
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  LLM CLI Council - Test Suite${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo
}

print_summary() {
    echo -e "\n${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Summary${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo
    echo "Total tests: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "\n${RED}${BOLD}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
    fi

    echo
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✅ ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}❌ SOME TESTS FAILED${NC}"
        return 1
    fi
}

main() {
    print_header

    # Run test suites
    test_suite_repository_structure
    test_suite_plugin_manifest
    test_suite_platform_utilities
    test_suite_path_abstraction
    test_suite_configuration
    test_suite_documentation
    test_suite_installer
    test_suite_installed_system

    # Print summary
    print_summary
}

# Run tests
main
