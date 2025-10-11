#!/bin/bash

# DockyDEB Update Detection Script
# This script checks for updates to base image, packages, and git repositories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSIONS_FILE="$PROJECT_ROOT/package-versions.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Global variables
UPDATES_FOUND=false
UPDATE_SUMMARY=""

# Function to check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq."
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed. Please install curl."
        exit 1
    fi
}

# Function to update package versions file
update_versions_file() {
    local key="$1"
    local value="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create backup
    cp "$VERSIONS_FILE" "${VERSIONS_FILE}.backup"

    # Update the file
    jq --arg key "$key" --arg value "$value" --arg timestamp "$timestamp" \
        'setpath($key | split("."); $value) | .last_updated = $timestamp' \
        "$VERSIONS_FILE" > "${VERSIONS_FILE}.tmp" && mv "${VERSIONS_FILE}.tmp" "$VERSIONS_FILE"
}

# Function to get current value from versions file
get_current_version() {
    local key="$1"
    jq -r "getpath(\"$key\" | split(\".\")) // \"\"" "$VERSIONS_FILE"
}

# Function to check base image updates
check_base_image_updates() {
    log_info "Checking base image updates..."

    local image="debian:bookworm-slim"
    local current_digest=$(get_current_version "base_image.digest")

    # Get latest digest from Docker Hub
    local latest_digest
    latest_digest=$(curl -s "https://registry-1.docker.io/v2/library/debian/manifests/bookworm-slim" \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        | jq -r '.config.digest // empty' 2>/dev/null || echo "")

    if [[ -z "$latest_digest" ]]; then
        log_warning "Could not fetch base image digest, skipping base image check"
        return 0
    fi

    if [[ "$current_digest" != "$latest_digest" ]]; then
        log_success "Base image update found: $image"
        UPDATE_SUMMARY="${UPDATE_SUMMARY}\n- Base image: debian:bookworm-slim (new digest)"
        update_versions_file "base_image.digest" "$latest_digest"
        update_versions_file "base_image.last_checked" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        UPDATES_FOUND=true
    else
        log_info "Base image is up to date"
    fi
}

# Function to check package updates
check_package_updates() {
    log_info "Checking package updates..."

    # List of packages from Dockerfile
    local packages=(
        "curl" "dnsutils" "git" "iputils-ping" "gnupg"
        "htop" "btop" "jq" "net-tools" "ncdu" "telnet"
        "unzip" "vim" "wget" "zsh" "zip"
    )

    # Create a temporary container to check package versions
    local temp_container="dockydeb-update-check-$$"

    log_info "Creating temporary container to check package versions..."
    docker run -d --name "$temp_container" debian:bookworm-slim sleep 300 >/dev/null

    # Update package lists in container
    docker exec "$temp_container" apt-get update >/dev/null 2>&1

    local package_updates_found=false

    for package in "${packages[@]}"; do
        local current_version=$(get_current_version "packages.$package")

        # Get available version
        local available_version
        available_version=$(docker exec "$temp_container" apt-cache policy "$package" 2>/dev/null | \
            grep "Candidate:" | awk '{print $2}' || echo "")

        if [[ -z "$available_version" ]]; then
            log_warning "Could not check version for package: $package"
            continue
        fi

        if [[ "$current_version" != "$available_version" ]]; then
            log_success "Package update found: $package ($current_version -> $available_version)"
            UPDATE_SUMMARY="${UPDATE_SUMMARY}\n- Package: $package ($current_version -> $available_version)"
            update_versions_file "packages.$package" "$available_version"
            package_updates_found=true
            UPDATES_FOUND=true
        fi
    done

    # Cleanup
    docker rm -f "$temp_container" >/dev/null 2>&1

    if [[ "$package_updates_found" == false ]]; then
        log_info "All packages are up to date"
    fi
}

# Function to check git repository updates
check_git_repository_updates() {
    log_info "Checking git repository updates..."

    local repos=(
        "ohmyzsh:https://github.com/ohmyzsh/ohmyzsh.git"
        "powerlevel10k:https://github.com/romkatv/powerlevel10k.git"
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
    )

    local git_updates_found=false

    for repo_info in "${repos[@]}"; do
        local repo_name="${repo_info%%:*}"
        local repo_url="${repo_info#*:}"

        local current_sha=$(get_current_version "git_repositories.$repo_name.commit_sha")

        # Get latest commit SHA from GitHub API
        local api_url="https://api.github.com/repos/${repo_url#https://github.com/}"
        api_url="${api_url%.git}/commits/HEAD"

        local latest_sha
        latest_sha=$(curl -s "$api_url" | jq -r '.sha // empty' 2>/dev/null || echo "")

        if [[ -z "$latest_sha" ]]; then
            log_warning "Could not fetch latest commit for: $repo_name"
            continue
        fi

        if [[ "$current_sha" != "$latest_sha" ]]; then
            log_success "Git repository update found: $repo_name"
            UPDATE_SUMMARY="${UPDATE_SUMMARY}\n- Git repo: $repo_name (new commits available)"
            update_versions_file "git_repositories.$repo_name.commit_sha" "$latest_sha"
            update_versions_file "git_repositories.$repo_name.last_checked" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
            git_updates_found=true
            UPDATES_FOUND=true
        fi
    done

    if [[ "$git_updates_found" == false ]]; then
        log_info "All git repositories are up to date"
    fi
}

# Main function
main() {
    log_info "Starting DockyDEB update check..."

    check_dependencies

    # Initialize versions file if it doesn't exist
    if [[ ! -f "$VERSIONS_FILE" ]]; then
        log_warning "Versions file not found, creating initial version..."
        # This will be populated during first run
    fi

    # Check for updates
    check_base_image_updates
    check_package_updates
    check_git_repository_updates

    # Output results
    echo ""
    if [[ "$UPDATES_FOUND" == true ]]; then
        log_success "Updates found! Summary:"
        echo -e "$UPDATE_SUMMARY"
        echo ""
        echo "updates_available=true" >> "$GITHUB_OUTPUT"
        echo "update_summary<<EOF" >> "$GITHUB_OUTPUT"
        echo -e "$UPDATE_SUMMARY" >> "$GITHUB_OUTPUT"
        echo "EOF" >> "$GITHUB_OUTPUT"
    else
        log_info "No updates found. Container is up to date."
        echo "updates_available=false" >> "$GITHUB_OUTPUT"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
