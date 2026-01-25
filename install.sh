#!/usr/bin/env bash
# LLM CLI Council - Installation Script
# Cross-platform installer for macOS, Linux, and Windows/WSL

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

VERSION="1.0.0"
REPO_NAME="llm-cli-council"
MIN_BASH_VERSION="3.2"

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# =============================================================================
# Global Variables
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
VERBOSE=false
AUTO_YES=false
CUSTOM_SKILLS_DIR=""
PLATFORM=""

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

print_header() {
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  LLM CLI Council - Installation${NC}"
    echo -e "${BOLD}  Version: $VERSION${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo
}

print_section() {
    echo
    echo -e "${BOLD}$*${NC}"
    echo "────────────────────────────────────────────────────────────"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"

    if [ "$AUTO_YES" = true ]; then
        log_verbose "Auto-confirming: $prompt"
        return 0
    fi

    local response
    if [ "$default" = "y" ]; then
        read -r -p "$prompt [Y/n] " response
        response=${response:-y}
    else
        read -r -p "$prompt [y/N] " response
        response=${response:-n}
    fi

    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# =============================================================================
# Platform Detection
# =============================================================================

detect_platform() {
    local uname_s
    uname_s=$(uname -s 2>/dev/null || echo "unknown")

    case "$uname_s" in
        Darwin*)
            PLATFORM="macos"
            log_verbose "Detected platform: macOS"
            ;;
        Linux*)
            if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
                PLATFORM="windows"
                log_verbose "Detected platform: Windows (WSL)"
            else
                PLATFORM="linux"
                log_verbose "Detected platform: Linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            PLATFORM="windows"
            log_verbose "Detected platform: Windows (Git Bash/MSYS)"
            ;;
        *)
            PLATFORM="unknown"
            log_warning "Unknown platform: $uname_s"
            ;;
    esac
}

# =============================================================================
# Prerequisites Check
# =============================================================================

check_bash_version() {
    local current_version="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
    local required_major required_minor current_major current_minor

    required_major=$(echo "$MIN_BASH_VERSION" | cut -d. -f1)
    required_minor=$(echo "$MIN_BASH_VERSION" | cut -d. -f2)
    current_major="${BASH_VERSINFO[0]}"
    current_minor="${BASH_VERSINFO[1]}"

    log_verbose "Bash version: $current_version (required: $MIN_BASH_VERSION)"

    if [ "$current_major" -gt "$required_major" ] || \
       { [ "$current_major" -eq "$required_major" ] && [ "$current_minor" -ge "$required_minor" ]; }; then
        return 0
    else
        return 1
    fi
}

check_prerequisites() {
    print_section "Checking Prerequisites"

    local missing_deps=()

    # Check bash version
    if ! check_bash_version; then
        log_error "Bash version ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} is too old (need $MIN_BASH_VERSION+)"
        return 1
    fi
    log_success "Bash version: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"

    # Check for curl or wget
    if command -v curl &>/dev/null; then
        log_success "curl found"
    elif command -v wget &>/dev/null; then
        log_success "wget found"
    else
        log_error "Neither curl nor wget found"
        missing_deps+=("curl or wget")
    fi

    # Check for Claude CLI (optional but recommended)
    if command -v claude &>/dev/null; then
        log_success "Claude CLI found"
    else
        log_warning "Claude CLI not found (optional, but recommended)"
        log_info "Install from: https://github.com/anthropics/claude-code"
    fi

    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# =============================================================================
# Directory Detection
# =============================================================================

detect_skills_directory() {
    local skills_dir=""

    # Priority order for skills directory detection
    if [ -n "$CUSTOM_SKILLS_DIR" ]; then
        skills_dir="$CUSTOM_SKILLS_DIR"
        log_verbose "Using custom skills directory: $skills_dir"
    elif [ -n "${CLAUDE_SKILLS_DIR:-}" ]; then
        skills_dir="$CLAUDE_SKILLS_DIR"
        log_verbose "Using CLAUDE_SKILLS_DIR: $skills_dir"
    elif [ -n "${CLAUDE_CONFIG_DIR:-}" ] && [ -d "${CLAUDE_CONFIG_DIR}/skills" ]; then
        skills_dir="${CLAUDE_CONFIG_DIR}/skills"
        log_verbose "Using CLAUDE_CONFIG_DIR/skills: $skills_dir"
    elif [ -d "$HOME/.claude/skills" ]; then
        skills_dir="$HOME/.claude/skills"
        log_verbose "Using default skills directory: $skills_dir"
    else
        # Fallback: create default directory
        skills_dir="$HOME/.claude/skills"
        log_verbose "Will create default skills directory: $skills_dir"
    fi

    echo "$skills_dir"
}

detect_config_directory() {
    local config_dir=""

    # Priority order for config directory
    if [ -n "${CLAUDE_COUNCIL_CONFIG_DIR:-}" ]; then
        config_dir="$CLAUDE_COUNCIL_CONFIG_DIR"
    elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
        config_dir="${CLAUDE_CONFIG_DIR}/council"
    elif [ -n "${XDG_CONFIG_HOME:-}" ]; then
        config_dir="${XDG_CONFIG_HOME}/claude/council"
    else
        config_dir="$HOME/.config/claude/council"
    fi

    log_verbose "Config directory: $config_dir"
    echo "$config_dir"
}

# =============================================================================
# Installation
# =============================================================================

create_directory_structure() {
    local skills_dir="$1"
    local config_dir="$2"

    print_section "Creating Directory Structure"

    # Create skills directory
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$skills_dir"
        log_success "Skills directory: $skills_dir"
    else
        log_info "[DRY RUN] Would create: $skills_dir"
    fi

    # Create config directory
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$config_dir"
        mkdir -p "$config_dir/logs"
        log_success "Config directory: $config_dir"
        log_success "Logs directory: $config_dir/logs"
    else
        log_info "[DRY RUN] Would create: $config_dir"
        log_info "[DRY RUN] Would create: $config_dir/logs"
    fi
}

install_main_skill() {
    local skills_dir="$1"
    local target="$skills_dir/$REPO_NAME"

    log_info "Installing main skill to: $target"

    if [ "$DRY_RUN" = false ]; then
        # Remove existing installation if present
        if [ -d "$target" ]; then
            log_warning "Existing installation found, removing..."
            rm -rf "$target"
        fi

        # Copy source files
        mkdir -p "$target"
        cp -r "$SCRIPT_DIR/src/"* "$target/"

        log_success "Main skill installed"
    else
        log_info "[DRY RUN] Would install main skill to: $target"
    fi
}

install_wrapper_skills() {
    local skills_dir="$1"

    log_info "Installing wrapper skills..."

    local wrappers=("setup" "status" "review-plan" "review-code" "uninstall")

    for wrapper in "${wrappers[@]}"; do
        local wrapper_dir="$skills_dir/${REPO_NAME}-${wrapper}"
        local wrapper_file="$SCRIPT_DIR/src/wrappers/${wrapper}-wrapper.md"

        if [ ! -f "$wrapper_file" ]; then
            log_error "Wrapper file not found: $wrapper_file"
            return 1
        fi

        if [ "$DRY_RUN" = false ]; then
            # Remove existing wrapper if present
            if [ -d "$wrapper_dir" ]; then
                rm -rf "$wrapper_dir"
            fi

            # Create wrapper directory and copy file
            mkdir -p "$wrapper_dir"
            cp "$wrapper_file" "$wrapper_dir/SKILL.md"

            log_success "Wrapper installed: ${REPO_NAME}-${wrapper}"
        else
            log_info "[DRY RUN] Would install wrapper: ${REPO_NAME}-${wrapper}"
        fi
    done
}

set_permissions() {
    local skills_dir="$1"

    log_verbose "Setting permissions..."

    if [ "$DRY_RUN" = false ]; then
        # Make platform-utils.sh executable
        local utils_file="$skills_dir/$REPO_NAME/lib/platform-utils.sh"
        if [ -f "$utils_file" ]; then
            chmod +x "$utils_file"
            log_verbose "Made executable: platform-utils.sh"
        fi
    fi
}

# =============================================================================
# Validation
# =============================================================================

validate_installation() {
    local skills_dir="$1"

    print_section "Validating Installation"

    local errors=0

    # Check main skill directory
    if [ ! -d "$skills_dir/$REPO_NAME" ]; then
        log_error "Main skill directory not found"
        ((errors++))
    else
        log_success "Main skill directory exists"
    fi

    # Check for key files
    local required_files=(
        "SKILL.md"
        "lib/platform-utils.sh"
        "config/providers.json"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$skills_dir/$REPO_NAME/$file" ]; then
            log_error "Missing file: $file"
            ((errors++))
        else
            log_verbose "Found: $file"
        fi
    done

    # Check wrapper skills
    local wrappers=("setup" "status" "review-plan" "review-code" "uninstall")
    for wrapper in "${wrappers[@]}"; do
        local wrapper_dir="$skills_dir/${REPO_NAME}-${wrapper}"
        if [ ! -d "$wrapper_dir" ]; then
            log_error "Wrapper directory not found: ${REPO_NAME}-${wrapper}"
            ((errors++))
        elif [ ! -f "$wrapper_dir/SKILL.md" ]; then
            log_error "SKILL.md not found in: ${REPO_NAME}-${wrapper}"
            ((errors++))
        else
            log_verbose "Wrapper OK: ${REPO_NAME}-${wrapper}"
        fi
    done

    if [ $errors -eq 0 ]; then
        log_success "All files validated successfully"
        return 0
    else
        log_error "Validation failed with $errors error(s)"
        return 1
    fi
}

# =============================================================================
# Post-Install
# =============================================================================

print_post_install() {
    local config_dir="$1"

    echo
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Installation Complete!${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${BOLD}Next Steps:${NC}"
    echo
    echo "  1. Run setup to detect your LLM CLI tools:"
    echo -e "     ${BLUE}/llm-cli-council:setup${NC}"
    echo
    echo "  2. Check status:"
    echo -e "     ${BLUE}/llm-cli-council:status${NC}"
    echo
    echo "  3. Try reviewing a plan:"
    echo -e "     ${BLUE}/llm-cli-council:review-plan PLAN.md${NC}"
    echo
    echo -e "${BOLD}Configuration:${NC}"
    echo "  Config directory: $config_dir"
    echo "  Environment variables: See README for customization"
    echo
    echo -e "${BOLD}Documentation:${NC}"
    echo "  README: https://github.com/username/llm-cli-council"
    echo
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main() {
    print_header

    # Detect platform
    detect_platform
    log_success "Platform: $PLATFORM"

    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    fi

    # Detect directories
    local skills_dir
    local config_dir
    skills_dir=$(detect_skills_directory)
    config_dir=$(detect_config_directory)

    print_section "Installation Plan"
    echo "Skills directory: $skills_dir"
    echo "Config directory: $config_dir"
    echo

    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo
    fi

    # Confirm installation
    if ! confirm "Proceed with installation?" "y"; then
        log_info "Installation cancelled"
        exit 0
    fi

    # Create directory structure
    create_directory_structure "$skills_dir" "$config_dir"

    # Install main skill
    install_main_skill "$skills_dir"

    # Install wrapper skills
    install_wrapper_skills "$skills_dir"

    # Set permissions
    set_permissions "$skills_dir"

    # Validate installation
    if [ "$DRY_RUN" = false ]; then
        if ! validate_installation "$skills_dir"; then
            log_error "Installation validation failed"
            exit 1
        fi
    fi

    # Print post-install instructions
    if [ "$DRY_RUN" = false ]; then
        print_post_install "$config_dir"
    else
        echo
        log_info "[DRY RUN] Installation simulation complete"
    fi
}

# =============================================================================
# Argument Parsing
# =============================================================================

show_help() {
    cat << EOF
LLM CLI Council - Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --yes, -y              Auto-confirm all prompts
    --skills-dir DIR       Install to custom skills directory
    --dry-run             Simulate installation without making changes
    --verbose, -v          Enable verbose output
    --help, -h            Show this help message

EXAMPLES:
    # Standard installation
    $0

    # Auto-confirm with verbose output
    $0 --yes --verbose

    # Custom skills directory
    $0 --skills-dir ~/.local/share/claude/skills

    # Dry run to preview changes
    $0 --dry-run

For more information, visit:
https://github.com/username/llm-cli-council
EOF
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        --skills-dir)
            CUSTOM_SKILLS_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# Run Installation
# =============================================================================

main
