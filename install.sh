#!/bin/sh
# =============================================================================
# Enigma2 Universal Panel — Bootstrap Installer
# =============================================================================
# Version  : 0.1.0
# License  : MIT
# Project  : https://github.com/SamoTech/Enigma2-Universal-Panel
# Compatible: Enigma2 Linux images (OpenATV, OpenVIX, DreamOS, etc.)
#             BusyBox sh / POSIX sh
# =============================================================================

PANEL_VERSION="0.1.0"
PANEL_WORK_DIR="/tmp/enigma2-universal-panel"
PANEL_REPO_URL="https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main"

# -----------------------------------------------------------------------------
# ANSI colors (safe subset supported by BusyBox)
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# -----------------------------------------------------------------------------
# Utility helpers
# -----------------------------------------------------------------------------
print_line() {
    printf '%s\n' "$1"
}

print_banner() {
    printf "${CYAN}${BOLD}"
    printf '=%.0s' $(seq 1 60) 2>/dev/null || printf '============================================================'
    printf "\n"
    printf "  ███████╗███╗   ██╗██╗ ██████╗ ███╗   ███╗ █████╗ ██████╗ \n"
    printf "  ██╔════╝████╗  ██║██║██╔════╝ ████╗ ████║██╔══██╗╚════██╗\n"
    printf "  █████╗  ██╔██╗ ██║██║██║  ███╗██╔████╔██║███████║ █████╔╝\n"
    printf "  ██╔══╝  ██║╚██╗██║██║██║   ██║██║╚██╔╝██║██╔══██║██╔═══╝ \n"
    printf "  ███████╗██║ ╚████║██║╚██████╔╝██║ ╚═╝ ██║██║  ██║███████╗\n"
    printf "  ╚══════╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝\n"
    printf "\n"
    printf "        Universal Panel for Enigma2 Receivers v%s\n" "${PANEL_VERSION}"
    printf "        https://github.com/SamoTech/Enigma2-Universal-Panel\n"
    printf '=%.0s' $(seq 1 60) 2>/dev/null || printf '============================================================'
    printf "${RESET}\n\n"
}

info()    { printf "${GREEN}[INFO]${RESET}  %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${RESET}  %s\n" "$1"; }
error()   { printf "${RED}[ERROR]${RESET} %s\n" "$1"; }
die()     { error "$1"; cleanup; exit 1; }

# -----------------------------------------------------------------------------
# Cleanup on exit
# -----------------------------------------------------------------------------
cleanup() {
    if [ -d "${PANEL_WORK_DIR}/tmp" ]; then
        rm -rf "${PANEL_WORK_DIR}/tmp" 2>/dev/null
        info "Temporary files cleaned up."
    fi
}

# Register cleanup on normal exit and interrupt
trap cleanup EXIT INT TERM

# -----------------------------------------------------------------------------
# 1. Root check
# -----------------------------------------------------------------------------
check_root() {
    info "Checking permissions..."
    if [ "$(id -u)" -ne 0 ]; then
        die "This script must be run as root. Try: sudo sh install.sh"
    fi
    info "Running as root. OK."
}

# -----------------------------------------------------------------------------
# 2. Detect package manager
# -----------------------------------------------------------------------------
detect_package_manager() {
    info "Detecting package manager..."
    PKG_MANAGER="none"

    if command -v opkg >/dev/null 2>&1; then
        PKG_MANAGER="opkg"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt-get"
    elif command -v ipkg >/dev/null 2>&1; then
        PKG_MANAGER="ipkg"
    fi

    if [ "${PKG_MANAGER}" = "none" ]; then
        warn "No supported package manager found. Some modules may not be available."
    else
        info "Package manager detected: ${PKG_MANAGER}"
    fi
}

# -----------------------------------------------------------------------------
# 3. Detect architecture
# -----------------------------------------------------------------------------
detect_architecture() {
    info "Detecting receiver architecture..."
    ARCH=$(uname -m 2>/dev/null || echo "unknown")

    case "${ARCH}" in
        mips*)   ARCH_TYPE="mips" ;;
        arm*)    ARCH_TYPE="arm" ;;
        aarch64) ARCH_TYPE="arm64" ;;
        x86_64)  ARCH_TYPE="x86_64" ;;
        i686|i386) ARCH_TYPE="x86" ;;
        *)       ARCH_TYPE="unknown" ;;
    esac

    info "Architecture: ${ARCH} (${ARCH_TYPE})"
}

# -----------------------------------------------------------------------------
# 4. Collect system information
# -----------------------------------------------------------------------------
detect_system_info() {
    info "Gathering system information..."

    KERNEL=$(uname -r 2>/dev/null || echo "unknown")
    HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
    UPTIME=$(uptime 2>/dev/null | sed 's/^ *//' || echo "unknown")

    # Try to detect Enigma2 image/distro
    IMAGE_NAME="unknown"
    if [ -f /etc/issue ]; then
        IMAGE_NAME=$(head -1 /etc/issue 2>/dev/null | sed 's/\\.*//;s/ *$//')
    elif [ -f /etc/opkg/arch.conf ]; then
        IMAGE_NAME="Enigma2 (opkg-based)"
    elif [ -f /etc/debian_version ]; then
        IMAGE_NAME="Debian-based"
    fi

    info "Hostname  : ${HOSTNAME}"
    info "Kernel    : ${KERNEL}"
    info "Image     : ${IMAGE_NAME}"
}

# -----------------------------------------------------------------------------
# 5. Detect download tool
# -----------------------------------------------------------------------------
detect_download_tool() {
    info "Detecting available download tool..."
    DOWNLOAD_TOOL="none"

    if command -v wget >/dev/null 2>&1; then
        DOWNLOAD_TOOL="wget"
    elif command -v curl >/dev/null 2>&1; then
        DOWNLOAD_TOOL="curl"
    fi

    if [ "${DOWNLOAD_TOOL}" = "none" ]; then
        die "Neither wget nor curl is available. Cannot continue without a download tool."
    fi

    info "Download tool: ${DOWNLOAD_TOOL}"
}

# -----------------------------------------------------------------------------
# 6. Create working directory
# -----------------------------------------------------------------------------
create_work_dir() {
    info "Creating working directory at ${PANEL_WORK_DIR}..."

    mkdir -p "${PANEL_WORK_DIR}/tmp" || die "Failed to create working directory at ${PANEL_WORK_DIR}."
    mkdir -p "${PANEL_WORK_DIR}/modules"
    mkdir -p "${PANEL_WORK_DIR}/cache"
    mkdir -p "${PANEL_WORK_DIR}/logs"

    info "Working directory ready: ${PANEL_WORK_DIR}"
}

# -----------------------------------------------------------------------------
# 7. Write environment file
# -----------------------------------------------------------------------------
write_env() {
    ENV_FILE="${PANEL_WORK_DIR}/env.sh"
    info "Writing environment file to ${ENV_FILE}..."

    cat > "${ENV_FILE}" << EOF
# Enigma2 Universal Panel — Environment
# Auto-generated by install.sh v${PANEL_VERSION}
# $(date 2>/dev/null || echo '')

PANEL_VERSION="${PANEL_VERSION}"
PANEL_WORK_DIR="${PANEL_WORK_DIR}"
PANEL_REPO_URL="${PANEL_REPO_URL}"
ARCH="${ARCH}"
ARCH_TYPE="${ARCH_TYPE}"
PKG_MANAGER="${PKG_MANAGER}"
DOWNLOAD_TOOL="${DOWNLOAD_TOOL}"
KERNEL="${KERNEL}"
HOSTNAME_VAL="${HOSTNAME}"
IMAGE_NAME="${IMAGE_NAME}"
EOF

    info "Environment file written."
}

# -----------------------------------------------------------------------------
# 8. Print summary
# -----------------------------------------------------------------------------
print_summary() {
    printf "\n${CYAN}${BOLD}--- System Detection Summary ----------------------------------${RESET}\n"
    printf "  %-20s %s\n" "Panel Version:"   "${PANEL_VERSION}"
    printf "  %-20s %s\n" "Hostname:"        "${HOSTNAME}"
    printf "  %-20s %s\n" "Kernel:"          "${KERNEL}"
    printf "  %-20s %s\n" "Image:"           "${IMAGE_NAME}"
    printf "  %-20s %s (%s)\n" "Architecture:" "${ARCH}" "${ARCH_TYPE}"
    printf "  %-20s %s\n" "Package Manager:" "${PKG_MANAGER}"
    printf "  %-20s %s\n" "Download Tool:"   "${DOWNLOAD_TOOL}"
    printf "  %-20s %s\n" "Work Dir:"        "${PANEL_WORK_DIR}"
    printf "${CYAN}${BOLD}---------------------------------------------------------------${RESET}\n\n"
    printf "${GREEN}${BOLD}Bootstrap complete! Enigma2 Universal Panel environment is ready.${RESET}\n"
    printf "Next steps will be available in future module releases.\n\n"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    print_banner
    check_root
    detect_package_manager
    detect_architecture
    detect_system_info
    detect_download_tool
    create_work_dir
    write_env
    print_summary
}

main
