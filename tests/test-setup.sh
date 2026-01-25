#!/usr/bin/env bash
# LLM CLI Council - Setup Tests
# Tests installation, path resolution, and platform utilities

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
    assert_file_exists "$PROJECT_ROOT/install.sh" "install.sh exists"
    assert_executable "$PROJECT_ROOT/install.sh" "install.sh is executable"

    test_start "Source directory structure"
    assert_dir_exists "$PROJECT_ROOT/src" "src/ exists"
    assert_dir_exists "$PROJECT_ROOT/src/commands" "src/commands/ exists"
    assert_dir_exists "$PROJECT_ROOT/src/prompts" "src/prompts/ exists"
    assert_dir_exists "$PROJECT_ROOT/src/rules" "src/rules/ exists"
    assert_dir_exists "$PROJECT_ROOT/src/config" "src/config/ exists"
    assert_dir_exists "$PROJECT_ROOT/src/lib" "src/lib/ exists"
    assert_dir_exists "$PROJECT_ROOT/src/wrappers" "src/wrappers/ exists"

    test_start "Required source files"
    assert_file_exists "$PROJECT_ROOT/src/SKILL.md" "Main SKILL.md exists"
    assert_file_exists "$PROJECT_ROOT/src/lib/platform-utils.sh" "platform-utils.sh exists"
    assert_file_exists "$PROJECT_ROOT/src/config/providers.json" "providers.json exists"

    test_start "Command files"
    for cmd in setup status review-plan review-code uninstall; do
        assert_file_exists "$PROJECT_ROOT/src/commands/${cmd}.md" "Command: ${cmd}.md"
    done

    test_start "Wrapper files"
    for wrapper in setup status review-plan review-code uninstall; do
        assert_file_exists "$PROJECT_ROOT/src/wrappers/${wrapper}-wrapper.md" "Wrapper: ${wrapper}-wrapper.md"
    done
}

test_suite_platform_utilities() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Platform Utilities${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    local utils_file="$PROJECT_ROOT/src/lib/platform-utils.sh"

    test_start "Platform utilities file"
    assert_file_exists "$utils_file" "platform-utils.sh exists"
    assert_executable "$utils_file" "platform-utils.sh is executable"

    # Source the utilities
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

    test_start "No hardcoded user paths"
    local hardcoded_paths
    hardcoded_paths=$(grep -r "/Users/[^/]*\|/home/[^/]*" "$PROJECT_ROOT/src" 2>/dev/null | grep -v "Binary file" || true)

    if [ -z "$hardcoded_paths" ]; then
        test_pass "No hardcoded user paths found"
    else
        test_fail "Found hardcoded user paths: $hardcoded_paths"
    fi

    test_start "Environment variable usage"
    local env_var_usage
    env_var_usage=$(grep -r '\$COUNCIL_CONFIG_FILE\|\$COUNCIL_CONFIG_DIR\|\$COUNCIL_LOG_DIR\|\$SKILLS_DIR' "$PROJECT_ROOT/src" | wc -l | tr -d ' ')

    if [ "$env_var_usage" -gt 10 ]; then
        test_pass "Environment variables used ($env_var_usage occurrences)"
    else
        test_fail "Insufficient environment variable usage ($env_var_usage occurrences)"
    fi

    test_start "Generic version placeholders"
    local specific_versions
    specific_versions=$(grep -r 'version.*[0-9]\+\.[0-9]\+\.[0-9]\+' "$PROJECT_ROOT/src" 2>/dev/null | grep -v "x.y.z" | grep -v "version\": \"1.0.0" | grep -v "version: 1.0.0" | grep -v "providers.json" || true)

    if [ -z "$specific_versions" ]; then
        test_pass "No specific version numbers in examples"
    else
        test_fail "Found specific version numbers: $specific_versions"
    fi
}

test_suite_installation_script() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Installation Script${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    test_start "Installation script structure"
    local install_script="$PROJECT_ROOT/install.sh"

    assert_contains "$(cat "$install_script")" "detect_platform" "Has platform detection"
    assert_contains "$(cat "$install_script")" "check_prerequisites" "Has prerequisites check"
    assert_contains "$(cat "$install_script")" "detect_skills_directory" "Has skills directory detection"
    assert_contains "$(cat "$install_script")" "install_main_skill" "Has main skill installation"
    assert_contains "$(cat "$install_script")" "install_wrapper_skills" "Has wrapper skills installation"
    assert_contains "$(cat "$install_script")" "validate_installation" "Has validation"

    test_start "Installation script flags"
    assert_contains "$(cat "$install_script")" "--dry-run" "Supports dry-run"
    assert_contains "$(cat "$install_script")" "--verbose" "Supports verbose"
    assert_contains "$(cat "$install_script")" "--yes" "Supports auto-confirm"
    assert_contains "$(cat "$install_script")" "--skills-dir" "Supports custom skills directory"

    test_start "Installation script help"
    local help_output
    help_output=$("$install_script" --help 2>&1)
    assert_contains "$help_output" "USAGE" "Help shows usage"
    assert_contains "$help_output" "OPTIONS" "Help shows options"
}

test_suite_configuration() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Configuration${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    test_start "Providers configuration"
    local providers_json="$PROJECT_ROOT/src/config/providers.json"

    assert_file_exists "$providers_json" "providers.json exists"

    # Validate JSON syntax
    if command -v jq &>/dev/null; then
        if jq . "$providers_json" &>/dev/null; then
            test_pass "providers.json is valid JSON"
        else
            test_fail "providers.json has invalid JSON syntax"
        fi

        # Check for required providers
        local providers=("claude" "copilot" "codex" "gemini" "ollama")
        for provider in "${providers[@]}"; do
            if jq -e ".providers.$provider" "$providers_json" &>/dev/null; then
                test_pass "Provider configured: $provider"
            else
                test_fail "Provider missing: $provider"
            fi
        done

        # Check for required modes
        local modes=("quick" "full" "privacy")
        for mode in "${modes[@]}"; do
            if jq -e ".modes.$mode" "$providers_json" &>/dev/null; then
                test_pass "Mode configured: $mode"
            else
                test_fail "Mode missing: $mode"
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
    assert_contains "$(cat "$license")" "2025" "Has current year"
}

test_suite_installed_system() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Test Suite: Installed System${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

    # Only run if installation exists
    local skills_dir="$HOME/.claude/skills"

    if [ ! -d "$skills_dir/llm-cli-council" ]; then
        echo -e "${YELLOW}⚠${NC} Skill not installed, skipping installed system tests"
        return 0
    fi

    test_start "Installed skill directories"
    assert_dir_exists "$skills_dir/llm-cli-council" "Main skill installed"
    assert_dir_exists "$skills_dir/llm-cli-council-setup" "Setup wrapper installed"
    assert_dir_exists "$skills_dir/llm-cli-council-status" "Status wrapper installed"
    assert_dir_exists "$skills_dir/llm-cli-council-review-plan" "Review-plan wrapper installed"
    assert_dir_exists "$skills_dir/llm-cli-council-review-code" "Review-code wrapper installed"
    assert_dir_exists "$skills_dir/llm-cli-council-uninstall" "Uninstall wrapper installed"

    test_start "Installed file count"
    local file_count
    file_count=$(find "$skills_dir/llm-cli-council" -type f | wc -l | tr -d ' ')

    if [ "$file_count" -eq 19 ]; then
        test_pass "Correct number of files installed ($file_count)"
    else
        test_fail "Incorrect file count (expected 19, got $file_count)"
    fi

    test_start "Config directory"
    local config_dir="${CLAUDE_COUNCIL_CONFIG_DIR:-${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}/council}"

    if [ -d "$config_dir" ]; then
        test_pass "Config directory exists: $config_dir"

        if [ -f "$config_dir/config.json" ]; then
            test_pass "Config file exists"

            # Validate config JSON if jq available
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
        echo -e "${YELLOW}⚠${NC} Config directory not found"
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
    test_suite_platform_utilities
    test_suite_path_abstraction
    test_suite_installation_script
    test_suite_configuration
    test_suite_documentation
    test_suite_installed_system

    # Print summary
    print_summary
}

# Run tests
main
