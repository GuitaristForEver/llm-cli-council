#!/usr/bin/env bash
# Platform Utilities for llm-cli-council
# Cross-platform compatibility layer for macOS, Linux, and Windows/WSL

set -euo pipefail

# =============================================================================
# Platform Detection
# =============================================================================

# detect_platform - Returns: macos, linux, windows, unknown
# Usage: PLATFORM=$(detect_platform)
detect_platform() {
    local uname_s
    uname_s=$(uname -s 2>/dev/null || echo "unknown")

    case "$uname_s" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            # Check if running under WSL
            if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
                echo "windows"
            else
                echo "linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# =============================================================================
# Timeout Command
# =============================================================================

# timeout_cmd - Execute command with timeout
# Usage: timeout_cmd <seconds> <command> [args...]
# Returns: Command exit code, or 124 on timeout
timeout_cmd() {
    local timeout_duration="$1"
    shift

    local platform
    platform=$(detect_platform)

    case "$platform" in
        macos)
            # Check for GNU timeout (from coreutils)
            if command -v gtimeout &>/dev/null; then
                gtimeout "$timeout_duration" "$@"
            else
                # Fallback: bash-only solution
                _timeout_bash "$timeout_duration" "$@"
            fi
            ;;
        linux|windows)
            # Standard timeout command available
            if command -v timeout &>/dev/null; then
                timeout "$timeout_duration" "$@"
            else
                _timeout_bash "$timeout_duration" "$@"
            fi
            ;;
        *)
            # Unknown platform, try bash fallback
            _timeout_bash "$timeout_duration" "$@"
            ;;
    esac
}

# _timeout_bash - Bash-only timeout implementation (fallback)
_timeout_bash() {
    local timeout_duration="$1"
    shift

    # Run command in background
    "$@" &
    local cmd_pid=$!

    # Wait with timeout
    local count=0
    while kill -0 "$cmd_pid" 2>/dev/null; do
        if [ "$count" -ge "$timeout_duration" ]; then
            kill -TERM "$cmd_pid" 2>/dev/null || true
            sleep 0.5
            kill -KILL "$cmd_pid" 2>/dev/null || true
            return 124
        fi
        sleep 1
        ((count++)) || true
    done

    # Get exit code
    wait "$cmd_pid"
}

# =============================================================================
# Process Management
# =============================================================================

# wait_for_pid - Wait for a process to complete with timeout
# Usage: wait_for_pid <pid> <timeout_seconds>
# Returns: 0 if process completed, 1 if timeout
wait_for_pid() {
    local pid="$1"
    local timeout="${2:-30}"
    local count=0

    while kill -0 "$pid" 2>/dev/null; do
        if [ "$count" -ge "$timeout" ]; then
            return 1
        fi
        sleep 1
        ((count++)) || true
    done

    return 0
}

# =============================================================================
# Temporary Files and Directories
# =============================================================================

# make_temp_file - Create temporary file
# Usage: TEMP_FILE=$(make_temp_file [prefix])
make_temp_file() {
    local prefix="${1:-tmp}"
    local platform
    platform=$(detect_platform)

    case "$platform" in
        macos)
            mktemp -t "${prefix}.XXXXXX"
            ;;
        linux|windows)
            mktemp -t "${prefix}.XXXXXX"
            ;;
        *)
            # Fallback: manual temp file creation
            local temp_file="/tmp/${prefix}.$$.$RANDOM"
            touch "$temp_file"
            echo "$temp_file"
            ;;
    esac
}

# make_temp_dir - Create temporary directory
# Usage: TEMP_DIR=$(make_temp_dir [prefix])
make_temp_dir() {
    local prefix="${1:-tmp}"
    local platform
    platform=$(detect_platform)

    case "$platform" in
        macos)
            mktemp -d -t "${prefix}.XXXXXX"
            ;;
        linux|windows)
            mktemp -d -t "${prefix}.XXXXXX"
            ;;
        *)
            # Fallback: manual temp dir creation
            local temp_dir="/tmp/${prefix}.$$.$RANDOM"
            mkdir -p "$temp_dir"
            echo "$temp_dir"
            ;;
    esac
}

# =============================================================================
# JSON Parsing
# =============================================================================

# json_get - Simple JSON value extraction
# Usage: json_get <json_file> <key>
# Example: json_get config.json ".providers[0].name"
# Note: Requires jq if available, otherwise uses grep/sed fallback
json_get() {
    local json_file="$1"
    local key="$2"

    if ! [ -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi

    # Try jq first (most reliable)
    if command -v jq &>/dev/null; then
        jq -r "$key // empty" "$json_file" 2>/dev/null || echo ""
        return 0
    fi

    # Fallback: grep + sed (limited, but works for simple keys)
    # This only handles simple cases like: {"key": "value"}
    # Does NOT handle nested objects or arrays reliably
    local simple_key
    simple_key=$(echo "$key" | sed 's/^\.//; s/\[.*\]//g')

    grep -o "\"$simple_key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$json_file" 2>/dev/null \
        | head -1 \
        | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' \
        || echo ""
}

# json_has_key - Check if JSON file contains a key
# Usage: json_has_key <json_file> <key>
# Returns: 0 if key exists, 1 otherwise
json_has_key() {
    local json_file="$1"
    local key="$2"

    if ! [ -f "$json_file" ]; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        jq -e "$key" "$json_file" &>/dev/null
        return $?
    fi

    # Fallback: simple grep
    local simple_key
    simple_key=$(echo "$key" | sed 's/^\.//; s/\[.*\]//g')
    grep -q "\"$simple_key\"" "$json_file" 2>/dev/null
}

# =============================================================================
# Path Resolution
# =============================================================================

# path_resolve - Resolve path with tilde expansion and environment variables
# Usage: RESOLVED=$(path_resolve "~/path/to/file")
path_resolve() {
    local path="$1"

    # Expand tilde
    if [[ "$path" =~ ^~ ]]; then
        path="${path/#\~/$HOME}"
    fi

    # Expand environment variables
    # Handle both $VAR and ${VAR} syntax
    path=$(eval echo "$path")

    echo "$path"
}

# path_exists - Check if path exists (after resolution)
# Usage: if path_exists "~/file"; then ...
path_exists() {
    local path
    path=$(path_resolve "$1")
    [ -e "$path" ]
}

# =============================================================================
# Shell Detection and Version
# =============================================================================

# get_shell_version - Get bash version
# Usage: VERSION=$(get_shell_version)
get_shell_version() {
    echo "${BASH_VERSION:-unknown}"
}

# check_bash_version - Check if bash version meets minimum requirement
# Usage: check_bash_version "4.0"
# Returns: 0 if meets requirement, 1 otherwise
check_bash_version() {
    local required="$1"
    local current="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"

    # Simple version comparison (assumes major.minor format)
    local req_major req_minor cur_major cur_minor
    req_major=$(echo "$required" | cut -d. -f1)
    req_minor=$(echo "$required" | cut -d. -f2)
    cur_major="${BASH_VERSINFO[0]}"
    cur_minor="${BASH_VERSINFO[1]}"

    if [ "$cur_major" -gt "$req_major" ]; then
        return 0
    elif [ "$cur_major" -eq "$req_major" ] && [ "$cur_minor" -ge "$req_minor" ]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# Utility Functions
# =============================================================================

# command_exists - Check if command is available
# Usage: if command_exists "jq"; then ...
command_exists() {
    command -v "$1" &>/dev/null
}

# get_config_dir - Get platform-appropriate config directory
# Usage: CONFIG_DIR=$(get_config_dir)
get_config_dir() {
    local platform
    platform=$(detect_platform)

    case "$platform" in
        macos)
            echo "${HOME}/Library/Application Support"
            ;;
        linux|windows)
            echo "${XDG_CONFIG_HOME:-${HOME}/.config}"
            ;;
        *)
            echo "${HOME}/.config"
            ;;
    esac
}

# ensure_dir - Ensure directory exists
# Usage: ensure_dir "/path/to/dir"
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# =============================================================================
# Export Functions (for sourcing)
# =============================================================================

# When sourced, make functions available
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f detect_platform
    export -f timeout_cmd
    export -f wait_for_pid
    export -f make_temp_file
    export -f make_temp_dir
    export -f json_get
    export -f json_has_key
    export -f path_resolve
    export -f path_exists
    export -f get_shell_version
    export -f check_bash_version
    export -f command_exists
    export -f get_config_dir
    export -f ensure_dir
fi
